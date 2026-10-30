#!/usr/bin/env python3
"""Incremental, recoverable module-record writes and bounded recovery queries."""

import argparse
from copy import deepcopy
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile

from validate_review_record import (
    CHECKS, compact_summary, evidence_references, load_record, require, text, validate, validate_event,
    validate_record_location,
)


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def atomic_write(path, data):
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as handle:
            temporary = Path(handle.name)
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def source_file(repository, name):
    require(text(name) and not Path(name).is_absolute(), "Source paths must be relative")
    path = (repository / name).resolve()
    require(repository in path.parents, f"Source outside repository: {name}")
    return path


def identities(record):
    return {**record.get("supporting_files", {}),
            **{name: item["identity"] for name, item in record["file_checks"].items()}}


def source_changes(record):
    repository = Path(record["source"]["repository"])
    changed = {}
    for name, old in identities(record).items():
        if old is None:
            # Init-time unreadable path; only record a change once readable.
            try:
                current = digest(source_file(repository, name).read_bytes())
            except OSError:
                continue
            changed[name] = {"identity": current, "note": "source readable"}
            continue
        try:
            current = digest(source_file(repository, name).read_bytes())
        except OSError as error:
            changed[name] = {"error": str(error)}
        else:
            if old != current:
                changed[name] = {"identity": current}
    return changed


def initialize(path, manifest):
    require(isinstance(manifest, dict), "Manifest must be an object")
    source = deepcopy(manifest["source"])
    require(isinstance(source, dict) and text(source.get("repository")),
            "source.repository is required")
    require(Path(source["repository"]).is_absolute(), "Repository path must be absolute")
    repository = Path(source["repository"]).resolve()
    require(repository.is_dir(), "Repository is not a directory")
    source["repository"] = str(repository)
    require(repository not in path.parents, "Record must be outside reviewed repository")
    require(text(source.get("module")), "source.module is required")
    module = source["module"]
    require(not Path(module).is_absolute(), "source.module must be relative")
    module_path = (repository / module).resolve()
    require(repository == module_path or repository in module_path.parents,
            "source.module escapes source.repository")
    require(module_path.is_dir(), "source.module is not an existing directory")
    files = deepcopy(manifest["files"])
    require(isinstance(files, list) and files, "Manifest files must be nonempty")
    checks = {}
    for item in files:
        require(isinstance(item, dict), "Inventory item must be an object")
        if item["status"] == "in_scope":
            name = item["path"]
            try:
                identity = digest(source_file(repository, name).read_bytes())
                initial = {key: {"status": "pending", "evidence": []} for key in CHECKS}
            except OSError as error:
                identity = None
                reason = f"source unreadable at init: {error}"
                initial = {key: {"status": "blocked", "evidence": [], "reason": reason}
                           for key in CHECKS}
            checks[name] = {"identity": identity, **initial}
            checks[name]["shared_state_context"]["state_group_ids"] = []
    record = {
        "schema_version": 3, "source": source,
        "inventory": {"reconciled": False, "discovered": len(files),
                      "in_scope": len(checks), "excluded": len(files) - len(checks),
                      "files": files},
        "file_checks": checks, "state_groups": [], "traces": [],
        "validation": {"status": "pending", "details": ""},
        "progress": {"phase": "initial", "next_step": "Reconcile build inventory",
                     "blockers": []},
        "report_map": {}, "limitations": [], "evidence_catalog": {},
        "supporting_files": {},
    }
    for name in manifest.get("supporting_files", []):
        try:
            record["supporting_files"][name] = digest(
                source_file(repository, name).read_bytes())
        except OSError:
            record["supporting_files"][name] = None
    validate(record, {})
    require(not path.parent.exists(), "Use a new review directory; initialization never overwrites")
    path.parent.mkdir(parents=True)
    path.with_name("issues.jsonl").touch(exist_ok=False)
    atomic_write(path, encoded(record))
    _, saved, issues = load_record(path)
    return compact_summary(validate(saved, issues))


def merge(target, delta):
    require(isinstance(delta, dict), "Update must be an object")
    for key, value in delta.items():
        if isinstance(value, dict) and isinstance(target.get(key), dict):
            merge(target[key], value)
        else:
            target[key] = deepcopy(value)


def strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for key, child in value.items():
            if key not in ("id", "status", "seq", "updated_at"):
                yield from strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from strings(child)


def depends(value, keys):
    return any(item == key or item == "@" + key or item.startswith(key + ":")
               for item in strings(value) for key in keys)


def issue_event(delta, issues, catalog):
    require(isinstance(delta, dict), "Issue delta must be an object")
    require(not {"seq", "updated_at"} & delta.keys(), "Issue sequence/time are tool-maintained")
    issue_id = delta.get("id")
    if issue_id is None:
        number = 1
        while f"R{number:03}" in issues:
            number += 1
        issue_id = f"R{number:03}"
    require(text(issue_id), "Invalid issue ID")
    previous = issues.get(issue_id)
    event = deepcopy(previous) if previous else {
        "id": issue_id, "status": "pending", "merged_into": None,
        "dependencies": [], "open_questions": [], "trace_ids": [],
    }
    merge(event, delta)
    event["seq"] = previous["seq"] + 1 if previous else 1
    event["updated_at"] = datetime.now(timezone.utc).isoformat()
    references = set(evidence_references(event))
    require(not references - catalog.keys(), "Issue references unknown catalog evidence")
    if references:
        event["evidence_snapshots"] = {key: deepcopy(catalog[key]) for key in references}
    else:
        event.pop("evidence_snapshots", None)
    validate_event(event, previous)
    issues[issue_id] = event
    return event


def invalidate(record, issues, keys, reason, sections=None):
    require(text(reason), "Invalidation requires a concrete reason")
    all_sections = ("file_checks", "traces", "state_groups", "issues")
    if sections is None:
        sections = all_sections
    require(set(sections) <= set(all_sections),
            "invalidate_sections contains unknown names")
    affected = set(keys)
    objects = {
        **record["file_checks"],
        **{item["id"]: item for item in record["traces"] + record["state_groups"]},
        **issues,
        **record.get("evidence_catalog", {}),
    }
    known = set(objects) | set(record.get("supporting_files", {}))
    require(not affected - known, "Unknown invalidation IDs: " + ", ".join(sorted(affected - known)))
    while True:
        extra = {key for key, value in objects.items()
                 if key not in affected and depends(value, affected)}
        extra.update(issues[key]["merged_into"] for key in affected & issues.keys()
                     if issues[key]["status"] == "merged" and
                     issues[key]["merged_into"] not in affected)
        if not extra:
            break
        affected.update(extra)
    events = []
    if "file_checks" in sections:
        for name, checks in record["file_checks"].items():
            if name in affected:
                for key in CHECKS:
                    checks[key]["status"] = "pending"
                    checks[key].pop("reason", None)
                    checks[key].setdefault("invalidated_by", []).append(
                        {"reason": reason, "keys": sorted(keys)})
    touched_traces = [item for item in record["traces"] if item["id"] in affected
                      and "traces" in sections]
    for item in touched_traces:
        item["status"] = "pending"
        item.setdefault("invalidated_by", []).append(reason)
        if "next_check" in item:
            item.setdefault("next_check_history", []).append(item["next_check"])
    touched_states = [item for item in record["state_groups"]
                      if item["id"] in affected and "state_groups" in sections]
    for item in touched_states:
        item["status"] = "pending"
        item.setdefault("invalidated_by", []).append(reason)
        if "access_inventory" in item:
            item["access_inventory"]["status"] = "pending"
        if "next_check" in item:
            item.setdefault("next_check_history", []).append(item["next_check"])
    if "issues" in sections:
        for issue_id in sorted(set(issues) & affected):
            if issues[issue_id]["status"] != "merged":
                events.append(issue_event({
                    "id": issue_id, "status": "pending", "disposition": reason,
                    "next_check": reason,
                }, issues, record.get("evidence_catalog", {})))
    confirmed_removed = {key for key in affected
                         if key in issues and issues[key]["status"] == "confirmed"}
    if confirmed_removed:
        record["report_map"] = {i: v for i, v in record["report_map"].items()
                                if i not in confirmed_removed}
    else:
        record["report_map"] = {}
    record["progress"]["last_invalidate"] = {
        "reason": reason, "keys": sorted(keys),
        "sections": list(sections),
    }
    record["progress"]["next_step"] = reason
    return events


def apply_update(record, issues, payload):
    require(isinstance(payload, dict), "Payload must be an object")
    allowed = {"file_checks", "traces", "state_groups", "issues", "evidence_catalog",
               "progress", "validation", "limitations", "inventory_reconciled",
               "invalidate", "invalidate_sections", "reason"}
    require(not payload.keys() - allowed, "Unknown update fields")
    for section in ("file_checks", "evidence_catalog", "progress", "validation"):
        require(isinstance(payload.get(section, {}), dict), f"{section} must be an object")
    for section in ("traces", "state_groups", "issues", "limitations"):
        require(isinstance(payload.get(section, []), list), f"{section} must be a list")
    require(all(text(item) for item in payload.get("limitations", [])),
            "limitations must contain text")
    record, issues = deepcopy(record), deepcopy(issues)
    changed = source_changes(record)
    invalidated = payload.get("invalidate", [])
    require(isinstance(invalidated, list) and all(text(key) for key in invalidated),
            "invalidate must be a list of IDs or source paths")
    sections = payload.get("invalidate_sections")
    require(sections is None or (isinstance(sections, list) and
                                 all(text(item) for item in sections)),
            "invalidate_sections must be a list of section names")
    unconfirmed_changes = set(changed) - set(invalidated)
    # Auto-invalidate tracked source drift; the caller still sees them via
    # source_changes in the returned result for visibility.
    if unconfirmed_changes:
        invalidated = list(invalidated) + sorted(unconfirmed_changes)
        payload["invalidate_sections"] = sections
        if not text(payload.get("reason")):
            payload["reason"] = ("tracked source content changed; "
                                 "automatic invalidation")
    catalog = payload.get("evidence_catalog", {})
    require(isinstance(catalog, dict), "evidence_catalog must be an object")
    changed_evidence = [key for key, value in catalog.items()
                        if key in record.get("evidence_catalog", {}) and
                        value != record["evidence_catalog"][key]]
    keys = list(set(invalidated + changed_evidence))
    events = invalidate(record, issues, keys, payload.get("reason"),
                        sections=sections) if keys else []
    for name, value in changed.items():
        require("identity" in value, f"Cannot re-identify inaccessible source: {name}")
        if name in record["file_checks"]:
            record["file_checks"][name]["identity"] = value["identity"]
        if name in record.get("supporting_files", {}):
            record["supporting_files"][name] = value["identity"]
    for name, delta in payload.get("file_checks", {}).items():
        require(name in record["file_checks"], f"Unknown file: {name}")
        require(isinstance(delta, dict), "File check update must be an object")
        require(not delta.keys() - set(CHECKS), "Only check fields may be updated")
        merge(record["file_checks"][name], delta)
    merge(record.setdefault("evidence_catalog", {}), catalog)
    for section in ("traces", "state_groups"):
        for delta in payload.get(section, []):
            require(isinstance(delta, dict) and text(delta.get("id")), f"{section}: ID required")
            item = next((item for item in record[section] if item["id"] == delta["id"]), None)
            if item is None:
                item = {"id": delta["id"]}
                record[section].append(item)
            merge(item, delta)
    for delta in payload.get("issues", []):
        events.append(issue_event(delta, issues, record.get("evidence_catalog", {})))
    if "inventory_reconciled" in payload:
        require(isinstance(payload["inventory_reconciled"], bool), "Reconciliation must be boolean")
        record["inventory"]["reconciled"] = payload["inventory_reconciled"]
    for section in ("progress", "validation"):
        if section in payload:
            merge(record[section], payload[section])
    if "limitations" in payload:
        record["limitations"] = deepcopy(payload["limitations"])
    # Report mappings for unaffected confirmed issues persist; invalidate() has
    # already pruned entries tied to confirmed issues in the affected closure.
    ids = (list(record["file_checks"]) + list(record.get("evidence_catalog", {})) +
           list(issues) + [item["id"] for item in record["traces"] + record["state_groups"]])
    require(len(ids) == len(set(ids)), "Record IDs must be unique across sections")
    validate(record, issues)
    return record, issues, events


def commit_update(path, record, events):
    journal = path.with_name("issues.jsonl")
    transaction = {
        "base_record": digest(path.read_bytes()),
        "base_journal": digest(journal.read_bytes()),
        "base_size": journal.stat().st_size,
        "record": record, "events": events,
    }
    encoded_transaction = encoded(transaction)
    atomic_write(path.with_name("transaction.json"), encoded_transaction)
    directory = path.parent
    with directory.open("r+" if directory != Path("/") else "r") as handle:
        os.fsync(handle.fileno())
    return recover(path)


def recover(path):
    transaction_path = path.with_name("transaction.json")
    if not transaction_path.is_file():
        _, record, issues = load_record(path)
        return compact_summary(validate(record, issues))
    try:
        transaction = json.loads(transaction_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError) as error:
        preserved = transaction_path.with_name("transaction.corrupt")
        transaction_path.replace(preserved)
        _, record, issues = load_record(path)
        summary = compact_summary(validate(record, issues))
        summary["transaction_corrupt"] = str(error)
        summary["preserved_at"] = str(preserved)
        return summary
    journal = path.with_name("issues.jsonl")
    current = journal.read_bytes()
    size = transaction["base_size"]
    suffix = b"".join((json.dumps(event, ensure_ascii=False) + "\n").encode("utf-8")
                      for event in transaction["events"])
    require(digest(current[:size]) == transaction["base_journal"] and
            len(current) >= size and suffix.startswith(current[size:]),
            "Journal differs from transaction; do not overwrite external edits")
    result = encoded(transaction["record"])
    require(digest(path.read_bytes()) in (transaction["base_record"], digest(result)),
            "Record differs from transaction; do not overwrite external edits")
    issues = {}
    for line in current[:size].decode("utf-8").splitlines():
        event = json.loads(line)
        validate_event(event, issues.get(event["id"]))
        issues[event["id"]] = event
    for event in transaction["events"]:
        validate_event(event, issues.get(event["id"]))
        issues[event["id"]] = event
    validate(transaction["record"], issues)
    validate_record_location(path, transaction["record"])
    with journal.open("ab") as handle:
        handle.write(suffix[len(current) - size:])
        handle.flush()
        os.fsync(handle.fileno())
    atomic_write(path, result)
    _, saved, issues = load_record(path, allow_transaction=True)
    summary = compact_summary(validate(saved, issues))
    transaction_path.unlink()
    return summary


def working_set(record, issues, offset=0, limit=1):
    summary = validate(record, issues)
    changed = source_changes(record)
    queue = ([("file", name) for name in summary["remaining_files"]] +
             [("state", name) for name in summary["remaining_state_groups"]] +
             [("trace", item["id"]) for item in record["traces"]
              if item["status"] in ("pending", "blocked")] +
             [("issue", key) for key, item in issues.items()
              if item["status"] in ("pending", "blocked")])
    selected = queue[offset:offset + limit]
    objects = {"file": record["file_checks"], "issue": issues,
               "state": {item["id"]: item for item in record["state_groups"]},
               "trace": {item["id"]: item for item in record["traces"]}}
    tasks = []
    for kind, key in selected:
        value = objects[kind][key]
        related = {
            section: [name for name, item in entries.items()
                      if (name != key and depends(item, {key})) or
                      name in value.get("trace_ids", []) or
                      name in value.get("state_group_ids", []) or
                      name in value.get("issue_ids", [])]
            for section, entries in objects.items() if section != "file"
        }
        evidence_ids = set(evidence_references(value))
        tasks.append({"kind": kind, "id": key, "record": value, "related_ids": related,
                      "evidence_catalog": {name: record["evidence_catalog"][name]
                                           for name in sorted(evidence_ids)}})
    return {
        "source": record["source"], "progress": record["progress"],
        "inventory_reconciled": record["inventory"]["reconciled"],
        "validation": record["validation"], "limitations": record.get("limitations", []),
        "coverage": {key: value for key, value in summary.items()
                     if not key.startswith("remaining")},
        "source_changes": changed, "resume_allowed": not changed,
        "task_count": len(queue), "offset": offset,
        "next_offset": offset + limit if offset + limit < len(queue) else None,
        "tasks": tasks,
    }


def query(path, record, issues, kind, key):
    if kind == "history":
        require(key in issues, f"Unknown issue: {key}")
        return [event for line in path.with_name("issues.jsonl").read_text(
            encoding="utf-8").splitlines() if (event := json.loads(line))["id"] == key]
    collections = {"file": record["file_checks"], "issue": issues,
                   "trace": {item["id"]: item for item in record["traces"]},
                   "state": {item["id"]: item for item in record["state_groups"]},
                   "evidence": record.get("evidence_catalog", {})}
    require(key in collections[kind], f"Unknown {kind}: {key}")
    value = collections[kind][key]
    refs = set(evidence_references(value))
    return {"record": value, "evidence_catalog": {
        name: record["evidence_catalog"][name] for name in sorted(refs)}}


LOCK_MODES = {"update": fcntl.LOCK_EX, "recover": fcntl.LOCK_EX,
              "resume": fcntl.LOCK_SH, "get": fcntl.LOCK_SH}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("init", "update", "resume", "get", "recover"))
    parser.add_argument("record", type=Path)
    parser.add_argument("--input", type=Path, help="Manifest/update JSON; stdin if omitted")
    parser.add_argument("--kind", choices=("file", "issue", "trace", "state", "evidence", "history"))
    parser.add_argument("--id")
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--limit", type=int, default=1)
    args = parser.parse_args()
    try:
        path = args.record.resolve()
        require(args.offset >= 0 and args.limit > 0, "Invalid query pagination")
        if args.command == "init":
            payload = json.loads(args.input.read_text(encoding="utf-8")
                                 if args.input else sys.stdin.read())
            result = initialize(path, payload)
        else:
            validate_record_location(path, json.loads(path.read_text(encoding="utf-8")))
            # Readers share; writers/recovery take an exclusive lock.
            with path.with_name("record.lock").open("a") as lock:
                fcntl.flock(lock, LOCK_MODES[args.command])
                pending = path.with_name("transaction.json").exists()
                require(args.command == "recover" or not pending,
                        "Unfinished write; run recover before reading or updating")
                if args.command == "recover":
                    result = recover(path)
                else:
                    _, record, issues = load_record(path)
                    validate(record, issues)
                    if args.command == "update":
                        payload = json.loads(args.input.read_text(encoding="utf-8")
                                             if args.input else sys.stdin.read())
                        saved, latest, events = apply_update(record, issues, payload)
                        result = commit_update(path, saved, events)
                        result["updated_issue_ids"] = [event["id"] for event in events]
                    elif args.command == "resume":
                        result = working_set(record, issues, args.offset, args.limit)
                    else:
                        require(args.kind and args.id, "get requires --kind and --id")
                        result = query(path, record, issues, args.kind, args.id)
        print(json.dumps(result, ensure_ascii=False))
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(f"Record operation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
