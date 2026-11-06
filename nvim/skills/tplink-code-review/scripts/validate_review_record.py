#!/usr/bin/env python3
"""Validate a session-local full-source review record without executing source."""

import argparse
import json
from pathlib import Path
import re
import sys

from discover_risk_sites import verify_sources

CHECKS = ("functional_paths", "call_interface", "resource_lifetime",
          "shared_state_context")
SEVERITIES = ("Critical", "High", "Medium", "Low")
STATUSES = ("pending", "confirmed", "dismissed", "blocked", "merged")
PHASES = ("initial", "integrating", "integration")
RISK_CHECKS = {
    "string_boundary": ("input_max", "destination_capacity", "termination", "length_handling"),
    "scan_conversion": ("input_max", "destinations", "field_widths",
                        "conversion_count", "failure_handling"),
    "structured_input": ("producer", "required_fields", "type_checks", "failure_handling"),
    "allocation_io": ("size_validation", "allocation_result", "read_result", "cleanup"),
}
RULES_PATH = (Path(__file__).resolve().parent.parent
              / "references" / "tplink-c-review-rules.md")
TPL_ID_RE = re.compile(r"`(TPL-C-[A-Z]+-\d{3})`")
CLAUSE_RE = re.compile(r"§[0-9]+(\.[0-9]+)*")
PROJECT_RE = re.compile(r"项目契约（[^）]+:[0-9]+(?:-[0-9]+)?）")


class RecordError(ValueError):
    def __init__(self, message, *, kind=None, items=None):
        super().__init__(message)
        self.kind = kind
        self.items = items


def require(condition, message):
    if not condition:
        raise RecordError(message)


def require_closed(items, label, kind):
    if items:
        preview = ", ".join(items[:3])
        omitted = len(items) - 3
        if omitted > 0:
            preview += f" (+{omitted} more; query paginated gate diagnostics)"
        raise RecordError(f"{label}: {preview}", kind=kind, items=items)


def compact_summary(summary):
    return {**{key: value for key, value in summary.items()
               if not key.startswith("remaining")},
            "next_file": next(iter(summary["remaining_files"]), None),
            "pending_files": len(summary["remaining_files"]),
            "pending_state_groups": len(summary["remaining_state_groups"])}


def text(value):
    return isinstance(value, str) and bool(value.strip())


def evidence(value):
    return isinstance(value, list) and bool(value) and all(text(item) for item in value)


def source_evidence(value):
    return evidence(value) and any(re.search(r"[^\s:]+:[1-9][0-9]*(?:-[1-9][0-9]*)?", item)
                                   for item in value)


def rule_id_index():
    if not RULES_PATH.is_file():
        return None
    return set(re.findall(r"`(TPL-C-[A-Z]+-\d{3})`", RULES_PATH.read_text(encoding="utf-8")))


def validate_rule_basis(basis):
    known = rule_id_index()
    for entry in basis:
        require(CLAUSE_RE.search(entry) or PROJECT_RE.search(entry),
                f"rule_basis entry lacks §clause or 项目契约 citation: {entry}")
        for tpl in TPL_ID_RE.findall(entry):
            require(not PROJECT_RE.search(entry),
                    f"TP-LINK ID and 项目契约 mixed in one entry: {entry}")
            if known is not None:
                require(tpl in known, f"unknown TP-LINK rule id {tpl}")


def validate_event(event, previous=None):
    require(isinstance(event, dict), "Issue event must be an object")
    issue_id = event.get("id")
    require(text(issue_id), "Issue event requires id")
    require(event.get("seq") == (previous["seq"] + 1 if previous else 1),
            f"{issue_id}: event sequence must be consecutive")
    require(event.get("status") in STATUSES, f"{issue_id}: invalid status")
    for key in ("origin", "summary", "disposition", "updated_at"):
        require(text(event.get(key)), f"{issue_id}: missing {key}")
    for key in ("evidence", "dependencies", "open_questions", "trace_ids"):
        require(isinstance(event.get(key), list), f"{issue_id}: {key} must be a list")
    require(event["evidence"], f"{issue_id}: evidence references required")
    if event["status"] in ("pending", "blocked"):
        require(text(event.get("next_check")), f"{issue_id}: next_check required")
    if previous and previous["status"] in ("confirmed", "dismissed"):
        require(event["status"] in (previous["status"], "pending", "merged"),
                f"{issue_id}: reopen as pending before changing disposition")
    if event["status"] == "confirmed":
        for key in ("location", "cause", "recommendation"):
            require(text(event.get(key)), f"{issue_id}: missing report field {key}")
        if "rule_tags" in event or "rule_basis" in event:
            require(isinstance(event.get("rule_tags"), list),
                    f"{issue_id}: rule_tags must be a list")
            require(all(text(tag) for tag in event["rule_tags"]),
                    f"{issue_id}: rule_tags must contain nonempty strings")
            require(isinstance(event.get("rule_basis"), list)
                    and event["rule_basis"]
                    and all(text(basis) for basis in event["rule_basis"]),
                    f"{issue_id}: rule_basis must contain nonempty strings")
            validate_rule_basis(event["rule_basis"])
        else:
            require(text(event.get("rule")),
                    f"{issue_id}: missing report field rule_basis")
        require(event.get("severity") in SEVERITIES, f"{issue_id}: invalid severity")
        require(event.get("axis") in ("Standards", "Spec"), f"{issue_id}: invalid axis")
        require(not event["open_questions"], f"{issue_id}: confirmed with open questions")


def evidence_references(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key.endswith("evidence") and isinstance(child, list):
                for item in child:
                    if isinstance(item, str) and item.startswith("@"):
                        yield item[1:]
            yield from evidence_references(child)
    elif isinstance(value, list):
        for child in value:
            yield from evidence_references(child)


def validate_evidence_catalog(record, issues):
    catalog = record.get("evidence_catalog", {})
    require(isinstance(catalog, dict), "evidence_catalog must be an object")
    for key, entry in catalog.items():
        require(text(key) and not key.startswith("@") and isinstance(entry, dict),
                "Invalid evidence catalog entry")
        require(text(entry.get("summary")) and evidence(entry.get("evidence")),
                f"{key}: summary and source evidence required")
        require(not any(item.startswith("@") for item in entry["evidence"]),
                f"{key}: catalog evidence must contain source locations, not references")
    for key in evidence_references([record, list(issues.values())]):
        require(key in catalog, f"Unknown evidence reference @{key}")


def scan_fields(format_string):
    fields = []
    pattern = re.compile(r"%(?P<skip>\*)?(?P<width>[0-9]+)?"
                         r"(?:hh|ll|[hljztL])?(?P<kind>\[\^?\]?[^\]]*\]|[%A-Za-z])")
    index = 0
    for match in pattern.finditer(format_string):
        kind = match["kind"]
        if kind == "%" or match["skip"]:
            continue
        index += 1
        if kind.startswith("[") or kind in ("s", "c"):
            fields.append({"index": index, "conversion": "[" if kind.startswith("[") else kind,
                           "width": int(match["width"]) if match["width"] else
                           (1 if kind == "c" else None),
                           "nul_bytes": 0 if kind == "c" else 1})
    return fields


def validate_site_proof(site, anchor, issues):
    trace_id = site["id"]
    category = site["category"]
    scenarios = site.get("scenarios")
    require(isinstance(scenarios, dict), f"{trace_id}: scenarios required")
    required = {
        "string_boundary": ("bounds", "termination", "result_handling"),
        "scan_conversion": ("bounds", "conversion_count", "failure_handling"),
        "structured_input": ("presence", "types", "failure_handling"),
        "allocation_io": ("size", "operation_failure", "cleanup", "caller_failure"),
    }[category]
    require(not set(required) - scenarios.keys(), f"{trace_id}: missing applicable scenarios")
    findings = set()
    for name, scenario in scenarios.items():
        require(isinstance(scenario, dict), f"{trace_id}/{name}: invalid scenario")
        status = scenario.get("status")
        require(status in ("safe", "finding", "excluded", "pending", "blocked"),
                f"{trace_id}/{name}: invalid scenario status")
        if status in ("pending", "blocked"):
            require(text(scenario.get("next_check")), f"{trace_id}/{name}: next_check required")
            require(site["status"] in ("pending", "blocked"),
                    f"{trace_id}: unresolved scenario cannot close site")
            continue
        require(evidence(scenario.get("evidence")) and text(scenario.get("reason")),
                f"{trace_id}/{name}: scenario evidence and reason required")
        ids = scenario.get("issue_ids", [])
        require(isinstance(ids, list) and all(text(key) for key in ids),
                f"{trace_id}/{name}: issue_ids must be a list")
        if status == "finding":
            require(ids and all(key in site["issue_ids"] and key in issues
                                and issues[key]["status"] == "confirmed" for key in ids),
                    f"{trace_id}/{name}: finding needs directly linked confirmed issues")
            findings.update(ids)
        else:
            require(not ids, f"{trace_id}/{name}: non-finding scenario cannot claim issues")
    if site["status"] in ("pending", "blocked"):
        return
    require(findings == set(site["issue_ids"]),
            f"{trace_id}: each linked issue needs its own scenario disposition")
    require(bool(findings) == (site["status"] == "finding"),
            f"{trace_id}: scenario findings contradict site status")
    if site["disposition"] == "excluded":
        require(all(item["status"] == "excluded" for item in scenarios.values()),
                f"{trace_id}: excluded site has active scenarios")
        return
    facts = site.get("facts")
    require(isinstance(facts, dict), f"{trace_id}: structured facts required")
    if category == "string_boundary":
        buffers = facts.get("buffers")
        require(isinstance(buffers, list) and buffers, f"{trace_id}: buffer facts required")
        for item in buffers:
            require(isinstance(item, dict) and source_evidence(item.get("evidence")),
                    f"{trace_id}: buffer bound evidence required")
            for key in ("capacity", "suffix_bytes", "nul_bytes"):
                require(type(item.get(key)) is int and item[key] >= 0,
                        f"{trace_id}: numeric {key} required")
            require(item["capacity"] > 0 and item["nul_bytes"] in (0, 1),
                    f"{trace_id}: invalid buffer capacity/terminator")
            if item.get("bound_basis") == "producer":
                require(source_evidence(item.get("producer_evidence")),
                        f"{trace_id}: producer limit needs enforcement evidence")
            elif item.get("bound_basis") == "unknown":
                require(scenarios["bounds"]["status"] != "safe"
                        and item.get("max_bytes") is None and text(item.get("reason")),
                        f"{trace_id}: unknown bound cannot establish safety")
            else:
                require(item.get("bound_basis") in ("target_guard", "bounded_operation"),
                        f"{trace_id}: explicit bound_basis required")
            if scenarios["bounds"]["status"] == "safe":
                require(type(item.get("max_bytes")) is int and item["max_bytes"] >= 0,
                        f"{trace_id}: safe bound needs numeric maximum")
                require(item["max_bytes"] + item["suffix_bytes"] + item["nul_bytes"]
                        <= item["capacity"], f"{trace_id}: safe bound exceeds capacity")
    elif category == "scan_conversion":
        fmt = facts.get("format_string")
        require(text(fmt), f"{trace_id}: format_string required")
        if anchor.get("format_string") is not None:
            require(fmt == anchor["format_string"], f"{trace_id}: format differs from source")
        else:
            require(evidence(facts.get("format_evidence")),
                    f"{trace_id}: nonliteral format needs source evidence")
        fields = facts.get("conversions")
        expected = scan_fields(fmt)
        require(isinstance(fields, list) and len(fields) == len(expected),
                f"{trace_id}: each string conversion needs facts")
        for item, actual in zip(fields, expected):
            require(isinstance(item, dict) and all(item.get(key) == value
                    for key, value in actual.items()),
                    f"{trace_id}: conversion width/type differs from format")
            require(type(item.get("capacity")) is int and item["capacity"] > 0
                    and evidence(item.get("evidence")), f"{trace_id}: conversion capacity required")
            if scenarios["bounds"]["status"] == "safe":
                maximum = actual["width"]
                if maximum is None:
                    maximum = item.get("producer_max")
                    require(type(maximum) is int and maximum >= 0
                            and source_evidence(item.get("producer_evidence")),
                            f"{trace_id}: unbounded scan needs enforced producer bound")
                require(maximum + actual["nul_bytes"] <= item["capacity"],
                        f"{trace_id}: safe scan exceeds capacity")
    elif category == "structured_input":
        fields = facts.get("fields")
        require(isinstance(fields, list) and fields, f"{trace_id}: required field facts missing")
        for item in fields:
            require(isinstance(item, dict) and text(item.get("name")),
                    f"{trace_id}: exact field name required")
            for scenario, key in (("presence", "presence_evidence"), ("types", "type_evidence")):
                if scenarios[scenario]["status"] == "safe":
                    require(evidence(item.get(key)), f"{trace_id}: field {key} required")
    else:
        size = facts.get("size")
        require(isinstance(size, dict) and type(size.get("applicable")) is bool
                and evidence(size.get("evidence")), f"{trace_id}: size facts required")
        if size["applicable"]:
            require(all(type(size.get(key)) is int for key in ("minimum", "maximum", "limit")),
                    f"{trace_id}: numeric size bounds required")
            if scenarios["size"]["status"] == "safe":
                require(0 <= size["minimum"] <= size["maximum"] <= size["limit"],
                        f"{trace_id}: unsafe size bounds")
        else:
            require(text(size.get("reason")), f"{trace_id}: explain inapplicable size bound")


def validate_risk_sites(checks, traces, issues):
    sites = {key: value for key, value in traces.items() if value.get("kind") == "risk_site"}
    linked = set()
    incomplete_files = []
    unresolved = []
    for path, check in checks.items():
        scan = check["functional_paths"].get("candidate_scan")
        require(scan is None or isinstance(scan, dict), f"{path}: candidate_scan must be an object")
        candidates = scan.get("candidates", []) if isinstance(scan, dict) else []
        require(isinstance(candidates, list)
                and all(isinstance(item, dict) and text(item.get("id"))
                        and item.get("category") in RISK_CHECKS for item in candidates),
                f"{path}: invalid candidate scan")
        scan_current = (isinstance(scan, dict) and scan.get("version") == 1
                        and scan.get("source_identity") == check["identity"])
        candidate_ids = [item["id"] for item in candidates]
        require(len(candidate_ids) == len(set(candidate_ids)), f"{path}: duplicate candidate IDs")
        inventory = check["functional_paths"].get("risk_inventory", {})
        require(isinstance(inventory, dict), f"{path}: risk_inventory must be an object")
        require(not inventory.keys() - RISK_CHECKS.keys(),
                f"{path}: unknown risk_inventory category")
        complete = scan_current
        for category in RISK_CHECKS:
            entry = inventory.get(category, {"status": "pending", "trace_ids": []})
            require(isinstance(entry, dict), f"{path}/{category}: invalid risk inventory")
            status = entry.get("status")
            require(status in ("pending", "complete", "not_applicable"),
                    f"{path}/{category}: invalid risk inventory status")
            ids = entry.get("trace_ids")
            require(isinstance(ids, list) and all(text(key) for key in ids)
                    and len(ids) == len(set(ids)),
                    f"{path}/{category}: unique trace_ids required")
            for trace_id in ids:
                require(trace_id in sites and sites[trace_id].get("file") == path
                        and sites[trace_id].get("category") == category,
                        f"{path}/{category}/{trace_id}: dedicated risk_site trace required")
                require(trace_id not in linked, f"{trace_id}: duplicate risk inventory link")
                linked.add(trace_id)
            if status == "pending":
                complete = False
            else:
                require(evidence(entry.get("evidence")),
                        f"{path}/{category}: discovery/search evidence required")
                if status == "not_applicable":
                    require(not ids and text(entry.get("reason")),
                            f"{path}/{category}: not_applicable needs a reason and no sites")
                elif not ids:
                    require(text(entry.get("no_sites_reason")),
                            f"{path}/{category}: empty inventory needs no_sites_reason")
                if scan_current:
                    expected = {item["id"] for item in candidates if item["category"] == category}
                    mapped = [sites[key].get("candidate_id") for key in ids
                              if sites[key].get("candidate_id") is not None]
                    require(len(mapped) == len(set(mapped)),
                            f"{path}/{category}: candidate mapped more than once")
                    require(set(mapped) == expected,
                            f"{path}/{category}: extracted candidates missing or wrongly mapped")
        if not complete:
            incomplete_files.append(path)
    require(set(sites) == linked,
            "Risk site missing reverse inventory link: " + ", ".join(sorted(set(sites) - linked)))
    for trace_id, site in sites.items():
        for field in ("file", "location", "function", "operation"):
            require(text(site.get(field)), f"{trace_id}: risk site {field} required")
        location = re.fullmatch(re.escape(site["file"]) + r":([1-9][0-9]*)(?:-([1-9][0-9]*))?",
                                site["location"])
        require(location and (location[2] is None or int(location[2]) >= int(location[1])),
                f"{trace_id}: risk location must identify its target file and valid lines")
        require(site["file"] in checks, f"{trace_id}: risk site outside target inventory")
        category = site.get("category")
        require(category in RISK_CHECKS, f"{trace_id}: invalid risk category")
        status = site["status"]
        scan = checks[site["file"]]["functional_paths"].get("candidate_scan", {})
        if not scan:
            unresolved.append(trace_id)
            continue
        anchor = next((item for item in scan.get("candidates", [])
                       if item["id"] == site.get("candidate_id")), None)
        if anchor is None:
            anchor = site.get("manual_anchor")
            if anchor is not None:
                require(evidence(site.get("discovery_evidence")),
                        f"{trace_id}: manual wrapper needs discovery evidence")
        if status not in ("pending", "blocked"):
            require(isinstance(anchor, dict), f"{trace_id}: exact source anchor required")
            require(anchor.get("source_identity") == checks[site["file"]]["identity"],
                    f"{trace_id}: stale source anchor")
            expected_location = f"{site['file']}:{anchor['line']}"
            if anchor["end_line"] != anchor["line"]:
                expected_location += f"-{anchor['end_line']}"
            require(site["location"] == expected_location
                    and site["operation"] == anchor["callee"]
                    and site["function"] == anchor["function"],
                    f"{trace_id}: site must identify one exact call and enclosing function")
        if status in ("pending", "blocked"):
            unresolved.append(trace_id)
            require(text(site.get("next_check")), f"{trace_id}: next_check required")
            continue
        disposition = site.get("disposition")
        if status == "finding":
            require(disposition == "confirmed_defect",
                    f"{trace_id}: finding requires confirmed_defect disposition")
            require(any(issues[key]["status"] == "confirmed" for key in site["issue_ids"]),
                    f"{trace_id}: risk finding needs a directly linked confirmed issue")
        else:
            require(disposition in ("safe", "excluded"),
                    f"{trace_id}: verified risk site needs safe or excluded disposition")
        if disposition == "excluded":
            require(text(site.get("exclusion_reason")) and
                    evidence(site.get("exclusion_evidence")),
                    f"{trace_id}: exclusion needs build/reachability evidence")
            require(not any(issues[key]["status"] == "confirmed" for key in site["issue_ids"]),
                    f"{trace_id}: excluded site still linked to a confirmed issue")
        else:
            proof = site.get("checks", {})
            require(isinstance(proof, dict) and
                    all(text(proof.get(key)) for key in RISK_CHECKS[category]),
                    f"{trace_id}: {category} needs checks: " + ", ".join(RISK_CHECKS[category]))
            if disposition == "safe":
                require(not any(issues[key]["status"] == "confirmed"
                                for key in site["issue_ids"]),
                        f"{trace_id}: safe site still linked to a confirmed issue")
        validate_site_proof(site, anchor, issues)
    return {
        "risk_inventory_total": len(checks),
        "risk_inventory_completed": len(checks) - len(incomplete_files),
        "remaining_risk_files": incomplete_files,
        "risk_total": len(sites), "risk_completed": len(sites) - len(unresolved),
        "remaining_risk_sites": unresolved,
    }


def validate_prior_findings(record, issues, gate):
    remaining = []
    prior = record.get("prior_findings", [])
    require(isinstance(prior, list), "prior_findings must be a list")
    ids = []
    for item in prior:
        require(isinstance(item, dict) and text(item.get("id")), "Invalid prior finding")
        key = item["id"]
        ids.append(key)
        status = item.get("status")
        require(status in ("pending", "retained", "merged", "withdrawn", "excluded"),
                f"{key}: invalid prior disposition")
        require(text(item.get("summary")) and text(item.get("location")),
                f"{key}: original finding required")
        if status == "pending":
            require(text(item.get("next_check")), f"{key}: prior next_check required")
            remaining.append(key)
            continue
        require(text(item.get("reason")) and evidence(item.get("evidence")),
                f"{key}: prior disposition requires reason and evidence")
        linked = item.get("issue_ids", [])
        require(isinstance(linked, list), f"{key}: prior issue_ids required")
        if status in ("retained", "merged"):
            require(linked and all(key in issues and issues[key]["status"] == "confirmed"
                                   for key in linked), f"{key}: retained finding needs confirmed issue")
            if any(issues[issue_id]["severity"] != item["severity"] for issue_id in linked):
                require(text(item.get("severity_change_reason")),
                        f"{key}: severity change requires explanation")
        else:
            require(not linked, f"{key}: withdrawn/excluded prior cannot link confirmed issue")
    require(len(ids) == len(set(ids)), "Duplicate prior finding IDs")
    if gate in ("integration", "final"):
        require_closed(remaining, "Unreconciled prior findings", "prior")
    return {"prior_total": len(prior), "prior_completed": len(prior) - len(remaining),
            "remaining_prior_findings": remaining}


def validate_state_groups(record, checks, traces, issues, gate):
    groups = record.get("state_groups")
    require(isinstance(groups, list), "state_groups must be a list")
    by_id = {}
    unresolved = []
    for group in groups:
        require(isinstance(group, dict) and text(group.get("id")), "Invalid state group")
        group_id = group["id"]
        require(group_id not in by_id, "Duplicate state group IDs")
        by_id[group_id] = group
        for field in ("symbols", "files", "trace_ids"):
            require(evidence(group.get(field)), f"{group_id}: {field} required")
            require(len(group[field]) == len(set(group[field])),
                    f"{group_id}: duplicate {field}")
        require(group.get("status") in ("pending", "verified", "finding", "blocked"),
                f"{group_id}: invalid state status")
        for path in group["files"]:
            require(path in checks and group_id in
                    checks[path]["shared_state_context"].get("state_group_ids", []),
                    f"{group_id}/{path}: missing reverse file link")
        linked = []
        for trace_id in group["trace_ids"]:
            trace = traces.get(trace_id, {})
            require(trace.get("kind") == "shared_state" and
                    group_id in trace.get("state_group_ids", []),
                    f"{group_id}/{trace_id}: dedicated shared_state trace required")
            linked.append(trace)
        inventory = group.get("access_inventory", {})
        require(isinstance(inventory, dict) and
                inventory.get("status") in ("pending", "complete"),
                f"{group_id}: access_inventory required")
        accesses = []
        for role in ("writers", "readers"):
            require(isinstance(group.get(role), list), f"{group_id}: {role} must be a list")
            for access in group[role]:
                require(isinstance(access, dict), f"{group_id}: invalid access")
                for field in ("id", "location", "function", "context"):
                    require(text(access.get(field)), f"{group_id}: access {field} required")
                require(access.get("phase") in ("startup", "runtime", "unknown"),
                        f"{group_id}: invalid access phase")
                require(access.get("kind") in
                        ("direct", "callback", "worker", "thread", "interrupt"),
                        f"{group_id}: invalid access kind")
                require(evidence(access.get("evidence")),
                        f"{group_id}: access evidence required")
                accesses.append(access)
        access_ids = [access["id"] for access in accesses]
        require(len(access_ids) == len(set(access_ids)),
                f"{group_id}: duplicate access IDs")
        resolved = group["status"] in ("verified", "finding")
        if not resolved:
            unresolved.append(group_id)
            require(text(group.get("next_check")), f"{group_id}: next_check required")
            if group["status"] == "blocked":
                require(text(group.get("reason")), f"{group_id}: blocker reason required")
            continue
        require(inventory["status"] == "complete" and evidence(inventory.get("evidence")),
                f"{group_id}: access inventory incomplete")
        require(group["writers"], f"{group_id}: resolved group requires writers")
        if not group["readers"]:
            require(text(group.get("no_readers_reason")),
                    f"{group_id}: no_readers_reason required")
        for access in accesses:
            require(access["phase"] != "unknown", f"{group_id}: unresolved access context")
            if access["kind"] != "direct":
                require(evidence(access.get("dispatch_evidence")),
                        f"{group_id}: callback/worker registration and dispatch evidence required")
        require(evidence(group.get("evidence")), f"{group_id}: conclusion evidence required")
        require(all(trace["status"] == group["status"] for trace in linked),
                f"{group_id}: state and dedicated trace dispositions disagree")
        if group["status"] == "finding":
            require(len(accesses) >= 2, f"{group_id}: conflicting accesses required")
            require(any(issues[key]["status"] == "confirmed" and
                        issues[key].get("review_category") == "synchronization" and
                        group_id in issues[key].get("state_group_ids", [])
                        for trace in linked for key in trace["issue_ids"]),
                    f"{group_id}: synchronization finding needs a confirmed issue")
            continue
        counter = group.get("counterexample_check", {})
        require(isinstance(counter, dict) and counter.get("status") == "complete" and
                evidence(counter.get("evidence")) and
                isinstance(counter.get("checked"), list) and
                all(text(item) for item in counter["checked"]) and
                set(counter.get("checked", [])) >=
                {"runtime_writers", "async_dispatch", "synchronization_both_sides"},
                f"{group_id}: safety conclusion needs counterexample check")
        ordering = group.get("ordering", {})
        require(isinstance(ordering, dict), f"{group_id}: ordering proof required")
        kind = ordering.get("kind")
        require(kind in ("initialization_only", "single_context", "common_lock",
                         "snapshot", "atomic", "ownership"),
                f"{group_id}: ordering proof required")
        require(evidence(ordering.get("evidence")) and
                isinstance(ordering.get("access_ids"), list) and
                set(ordering["access_ids"]) == set(access_ids),
                f"{group_id}: ordering must cover every access")
        if kind == "initialization_only":
            require(all(access["phase"] == "startup" for access in group["writers"]),
                    f"{group_id}: runtime writer contradicts initialization_only")
            for access in group["writers"]:
                if access["kind"] != "direct":
                    require(evidence(access.get("startup_only_evidence")),
                            f"{group_id}: startup callback needs proof it cannot run after startup")
        if kind == "single_context":
            require(len({access["context"] for access in accesses}) == 1,
                    f"{group_id}: different contexts contradict single_context")
        if kind in ("common_lock", "snapshot", "atomic"):
            require(text(ordering.get("protocol")), f"{group_id}: protocol required")
            for access in accesses:
                require(access.get("protocol") == ordering["protocol"] and
                        evidence(access.get("synchronization_evidence")),
                        f"{group_id}: synchronization must cover both sides")
    for path, check in checks.items():
        state = check["shared_state_context"]
        ids = state.get("state_group_ids")
        require(isinstance(ids, list) and all(text(key) for key in ids) and
                len(ids) == len(set(ids)), f"{path}: state_group_ids required")
        for group_id in ids:
            require(group_id in by_id and path in by_id[group_id]["files"],
                    f"{path}/{group_id}: missing reverse state link")
        if state["status"] == "not_applicable":
            require(not ids, f"{path}: not_applicable with mutable state groups")
        if state["status"] == "inspected" and not ids:
            require(text(state.get("no_state_reason")),
                    f"{path}: empty state inventory needs no_state_reason")
    for trace_id, trace in traces.items():
        if trace.get("kind") == "shared_state":
            ids = trace.get("state_group_ids")
            require(evidence(ids), f"{trace_id}: state_group_ids required")
            for group_id in ids:
                require(group_id in by_id and trace_id in by_id[group_id]["trace_ids"],
                        f"{trace_id}/{group_id}: missing reverse state link")
    for issue_id, issue in issues.items():
        ids = issue.get("state_group_ids", [])
        require(isinstance(ids, list) and all(text(key) for key in ids),
                f"{issue_id}: invalid state_group_ids")
        for group_id in ids:
            require(group_id in by_id and any(
                trace_id in by_id[group_id]["trace_ids"] for trace_id in issue["trace_ids"]),
                f"{issue_id}/{group_id}: missing shared-state trace link")
    if gate in ("integration", "final"):
        require_closed(unresolved, "Unresolved state groups", "state")
    return {"state_total": len(groups), "state_completed": len(groups) - len(unresolved),
            "remaining_state_groups": unresolved}


def validate_record_location(path, record):
    require(isinstance(record, dict), "review.json must be an object")
    source = record.get("source", {})
    require(isinstance(source, dict), "source must be an object")
    require(text(source.get("repository")), "source.repository is required")
    require(Path(source["repository"]).is_absolute(),
            "source.repository must be absolute")
    repository = Path(source["repository"]).resolve()
    require(path != repository and repository not in path.parents,
            "Record must be outside the reviewed repository")
    require(text(source.get("module")), "source.module is required")
    module = source["module"]
    require(not Path(module).is_absolute(), "source.module must be relative")
    module_path = (repository / module).resolve()
    require(repository == module_path or repository in module_path.parents,
            "source.module escapes source.repository")
    source_kind = source.get("source_kind", "worktree")
    require(source_kind in ("worktree", "gerrit"), "invalid source.source_kind")
    journal = path.with_name("issues.jsonl")
    require(journal.resolve().parent == path.parent,
            "issues.jsonl must not link outside the session record directory")


def load_record(path, allow_transaction=False):
    path = Path(path).resolve()
    transaction = path.with_name("transaction.json")
    if not allow_transaction and transaction.is_file():
        try:
            json.loads(transaction.read_text(encoding="utf-8"))
            raise RecordError(
                "Unfinished record transaction; run manage_review_record.py recover")
        except (json.JSONDecodeError, UnicodeDecodeError):
            # Corrupt transaction: preserve, allow the read path.
            transaction.replace(transaction.with_name("transaction.corrupt"))
    record = json.loads(path.read_text(encoding="utf-8"))
    validate_record_location(path, record)
    journal = path.with_name("issues.jsonl")
    issues = {}
    require(journal.is_file(), "Create issues.jsonl, even if empty")
    for number, line in enumerate(journal.read_text(encoding="utf-8").splitlines(), 1):
        try:
            event = json.loads(line)
        except json.JSONDecodeError as error:
            raise RecordError(f"issues.jsonl:{number}: {error}") from error
        require(isinstance(event, dict), f"Event {number} must be an object")
        issue_id = event.get("id")
        require(text(issue_id), f"Event {number} requires id")
        validate_event(event, issues.get(issue_id))
        issues[issue_id] = event
    return path, record, issues


def derive_phase(record, issues, risk_summary):
    inventory = record.get("inventory", {})
    inv_ok = inventory.get("reconciled") is True
    checks = record.get("file_checks", {})
    checks_complete = bool(checks) and all(
        all(item.get(key, {}).get("status") in ("inspected", "not_applicable")
            for key in CHECKS)
        for item in checks.values()
    )
    traces_resolved = all(t["status"] in ("verified", "finding")
                          for t in record.get("traces", []))
    issues_resolved = all(i["status"] not in ("pending", "blocked")
                          for i in issues.values())
    issues_resolved &= all(item["status"] != "pending"
                           for item in record.get("prior_findings", []))
    validation = record.get("validation", {})
    validation_ok = validation.get("status") in (
        "executed", "unavailable", "unsafe", "not_applicable")
    if inv_ok and checks_complete and not risk_summary["remaining_risk_files"]:
        if traces_resolved and issues_resolved and validation_ok:
            return "integration"
        return "integrating"
    return "initial"


def validate(record, issues, gate="progress"):
    require(record.get("schema_version") == 3, "Expected schema_version 3; migrate explicitly")
    validate_evidence_catalog(record, issues)
    source = record.get("source", {})
    for key in ("module", "identity"):
        require(text(source.get(key)), f"source.{key} required")
    review_kind = source.get("review_kind", "module")
    require(review_kind in ("file", "module"), "invalid source.review_kind")
    inventory = record.get("inventory")
    require(isinstance(inventory, dict), "inventory must be an object")
    files = inventory.get("files")
    require(isinstance(files, list) and files, "inventory.files must be nonempty")
    paths = []
    included = []
    for item in files:
        require(isinstance(item, dict) and text(item.get("path")), "Invalid inventory item")
        paths.append(item["path"])
        require(item.get("status") in ("in_scope", "excluded"), "Invalid inventory status")
        if item["status"] == "in_scope":
            included.append(item["path"])
        else:
            require(text(item.get("reason")), f"{item['path']}: exclusion reason required")
    require(len(paths) == len(set(paths)), "Duplicate inventory paths")
    if review_kind == "file":
        require(paths == [source["module"]] and included == paths,
                "File review inventory must contain only the selected in-scope file")
    for field, expected in (("discovered", len(files)), ("in_scope", len(included)),
                            ("excluded", len(files) - len(included))):
        require(inventory.get(field) == expected, f"inventory.{field} inconsistent")
    checks = record.get("file_checks")
    require(isinstance(checks, dict) and set(checks) == set(included),
            "file_checks must match in-scope inventory")
    remaining = []
    for path in included:
        item = checks[path]
        identity = item.get("identity")
        require(identity is None or text(identity),
                f"{path}: content identity must be text or null")
        complete = True
        for key in CHECKS:
            check = item.get(key, {})
            require(isinstance(check, dict), f"{path}/{key}: invalid check")
            status = check.get("status")
            require(status in ("pending", "inspected", "blocked", "not_applicable"),
                    f"{path}/{key}: invalid status")
            if status == "inspected":
                require(isinstance(check.get("evidence"), list) and check["evidence"],
                        f"{path}/{key}: inspected without evidence")
            if status in ("blocked", "not_applicable"):
                require(text(check.get("reason")), f"{path}/{key}: reason required")
            complete &= status in ("inspected", "not_applicable")
        if not complete:
            remaining.append(path)
    traces = record.get("traces")
    require(isinstance(traces, list), "traces must be a list")
    by_id = {}
    for trace in traces:
        require(isinstance(trace, dict) and text(trace.get("id")), "Invalid trace")
        require(trace["id"] not in by_id, "Duplicate trace IDs")
        by_id[trace["id"]] = trace
        require(trace.get("status") in ("pending", "verified", "finding", "blocked"),
                f"{trace['id']}: invalid trace status")
        require(isinstance(trace.get("issue_ids"), list), "Trace issue_ids required")
        if trace["status"] in ("verified", "finding"):
            require(isinstance(trace.get("evidence"), list) and trace["evidence"],
                    f"{trace['id']}: resolved trace needs evidence")
        if trace["status"] == "blocked":
            require(text(trace.get("reason")), f"{trace['id']}: blocker reason required")
        for issue_id in trace["issue_ids"]:
            require(issue_id in issues and trace["id"] in issues[issue_id]["trace_ids"],
                    f"{trace['id']}/{issue_id}: missing reverse issue link")
    for issue_id, issue in issues.items():
        for trace_id in issue["trace_ids"]:
            require(trace_id in by_id and issue_id in by_id[trace_id]["issue_ids"],
                    f"{issue_id}/{trace_id}: missing reverse trace link")
        visited = {issue_id}
        target = issue
        while target["status"] == "merged":
            destination = target.get("merged_into")
            require(destination in issues and destination not in visited,
                    f"{issue_id}: invalid or cyclic merge")
            visited.add(destination)
            target = issues[destination]
    for trace in traces:
        if trace["status"] == "finding":
            require(any(issues[key]["status"] in ("confirmed", "merged")
                        for key in trace["issue_ids"]),
                    f"{trace['id']}: finding trace has no corresponding finding")
    risk_summary = validate_risk_sites(checks, by_id, issues)
    prior_summary = validate_prior_findings(record, issues, gate)
    remaining = list(dict.fromkeys(remaining + risk_summary["remaining_risk_files"]))
    state_summary = validate_state_groups(record, checks, by_id, issues, gate)
    progress = record.get("progress")
    require(isinstance(progress, dict), "progress required")
    require(text(progress.get("next_step")), "progress.next_step required")
    phase = progress.get("phase", "initial")
    require(phase in PHASES, f"progress.phase must be one of {PHASES}")
    # Never trust manually maintained coverage totals or remaining-file lists.
    for field in ("remaining_files", "completed_files", "completed_count"):
        require(field not in progress, f"Remove derived progress.{field}")
    interruption = progress.get("interruption")
    if interruption is not None:
        require(text(interruption),
                "progress.interruption must be nonempty text when present")
    report_map = record.get("report_map")
    require(isinstance(report_map, dict), "report_map must be an object")
    confirmed = {key for key, issue in issues.items() if issue["status"] == "confirmed"}
    require(set(report_map) <= confirmed, "Report maps an unconfirmed or unknown issue")
    entries = list(report_map.values())
    require(all(text(entry) for entry in entries) and len(entries) == len(set(entries)),
            "Report entries must be unique nonempty identifiers")
    if gate in ("initial", "integration", "final"):
        require(inventory.get("reconciled") is True, "Inventory is not reconciled")
        require_closed(remaining, "Initial pass incomplete", "file")
    if gate in ("integration", "final"):
        for issue in issues.values():
            if issue["status"] != "confirmed":
                continue
            claim = issue.get("claim", {})
            require(isinstance(claim, dict)
                    and claim.get("level") in ("standards", "runtime", "impact")
                    and evidence(claim.get("evidence")),
                    f"{issue['id']}: claim strength and evidence required")
            if claim["level"] != "standards":
                require(text(claim.get("trigger")), f"{issue['id']}: runtime trigger required")
        unresolved = [t["id"] for t in traces if t["status"] not in ("verified", "finding")]
        require_closed(unresolved, "Unresolved traces", "trace")
        unresolved = [key for key, issue in issues.items()
                      if issue["status"] in ("pending", "blocked")]
        require_closed(unresolved, "Unresolved issues", "issue")
        validation = record.get("validation", {})
        require(isinstance(validation, dict) and validation.get("status") in
                ("executed", "unavailable", "unsafe", "not_applicable"),
                "Validation outcome missing")
        require(text(validation.get("details")), "Validation details required")
        require(not progress.get("blockers"), "Material blockers remain")
        require(not progress.get("interruption"),
                "Clear interruption only after resuming and resolving its blocker")
    if gate == "final":
        require(set(report_map) == confirmed, "Confirmed issue missing report mapping")
    return {"total": len(included), "completed": len(included) - len(remaining),
            "remaining_files": remaining, "confirmed": len(confirmed),
            "derived_phase": derive_phase(record, issues, risk_summary),
            **state_summary, **risk_summary, **prior_summary}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("record", type=Path)
    parser.add_argument("--gate", choices=("progress", "initial", "integration", "final"),
                        default="progress")
    parser.add_argument("--details", action="store_true",
                        help="Return full success summary or all gap IDs (explicit opt-in)")
    parser.add_argument("--offset", type=int, default=0, help="Offset into failed gate's gap IDs")
    parser.add_argument("--limit", type=int, default=5, help="Gap IDs per diagnostic page")
    args = parser.parse_args()
    try:
        require(args.offset >= 0 and args.limit > 0, "Invalid diagnostic pagination")
        _, record, issues = load_record(args.record)
        summary = validate(record, issues, args.gate)
        if args.gate in ("initial", "integration", "final"):
            verify_sources(record)
    except (OSError, ValueError, TypeError, KeyError) as error:
        diagnostic = {"error": f"Record validation failed: {error}", "gate": args.gate}
        if isinstance(error, RecordError) and error.items is not None:
            end = len(error.items) if args.details else args.offset + args.limit
            start = 0 if args.details else args.offset
            diagnostic["gap"] = {
                "kind": error.kind, "total": len(error.items), "offset": start,
                "items": error.items[start:end],
                "next_offset": end if end < len(error.items) else None,
            }
        print(json.dumps(diagnostic, ensure_ascii=False), file=sys.stderr)
        return 1
    print(json.dumps(summary if args.details else compact_summary(summary), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
