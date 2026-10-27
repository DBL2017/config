"""Incremental record-tool tests; all source and session files are temporary."""

from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from generate_review_report import render
from manage_review_record import (
    apply_update, commit_update, digest, encoded, initialize, query, recover, working_set,
)
from test_review_record import issue, state_record
from validate_review_record import CHECKS, RecordError, load_record, validate


class ManageRecordTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        root = Path(self.temporary.name)
        self.repository = root / "repo"
        self.repository.mkdir()
        (self.repository / "main.c").write_text("int main(void) { return 0; }\n")
        (self.repository / "helper.c").write_text("int helper(void) { return 1; }\n")
        (self.repository / "module.h").write_text("int helper(void);\n")
        self.path = root / "session" / "review.json"
        self.manifest = {
            "source": {"repository": str(self.repository), "module": ".",
                       "identity": "current worktree; default variant", "spec_available": False},
            "files": [{"path": name, "status": "in_scope"}
                      for name in ("main.c", "helper.c")],
            "supporting_files": ["module.h"],
        }
        initialize(self.path, self.manifest)

    def read(self):
        _, record, issues = load_record(self.path)
        return record, issues

    def update(self, payload):
        record, issues = self.read()
        updated, latest, events = apply_update(record, issues, payload)
        result = commit_update(self.path, updated, events)
        return updated, latest, result

    def complete_files(self):
        return {"file_checks": {
            name: {**{key: {"status": "inspected", "evidence": [name + ":1"]}
                      for key in CHECKS},
                   "shared_state_context": {
                       "status": "inspected", "evidence": [name + ":1"],
                       "state_group_ids": [], "no_state_reason": "No shared mutable objects"}}
            for name in ("main.c", "helper.c")}}

    def test_initialization_hashes_and_does_not_claim_reconciliation(self):
        record, issues = self.read()
        self.assertFalse(record["inventory"]["reconciled"])
        self.assertEqual(validate(record, issues)["completed"], 0)
        self.assertEqual(record["file_checks"]["main.c"]["identity"],
                         digest((self.repository / "main.c").read_bytes()))
        self.assertEqual(len(record["supporting_files"]), 1)
        self.assertEqual(self.path.with_name("issues.jsonl").read_text(), "")
        with self.assertRaisesRegex(RecordError, "new review directory"):
            initialize(self.path, self.manifest)

    def test_initialization_rejects_escape_duplicate_and_repository_records(self):
        for name in ("../outside.c", str(self.repository / "main.c")):
            manifest = deepcopy(self.manifest)
            manifest["files"][0]["path"] = name
            with self.assertRaises(RecordError):
                initialize(self.path.parent.parent / "other" / "review.json", manifest)
        manifest = deepcopy(self.manifest)
        manifest["files"].append(manifest["files"][0])
        with self.assertRaisesRegex(RecordError, "Duplicate"):
            initialize(self.path.parent.parent / "other" / "review.json", manifest)
        with self.assertRaisesRegex(RecordError, "outside"):
            initialize(self.repository / "session" / "review.json", self.manifest)

    def test_incremental_checks_and_completion_gate(self):
        record, issues, _ = self.update({"file_checks": {
            "main.c": {"functional_paths": {"status": "inspected", "evidence": ["main.c:1"]}}
        }})
        self.assertEqual(record["file_checks"]["main.c"]["call_interface"]["status"], "pending")
        with self.assertRaisesRegex(RecordError, "Inventory"):
            validate(record, issues, "initial")
        payload = self.complete_files()
        payload.update(inventory_reconciled=True,
                       validation={"status": "unavailable", "details": "No target compiler"})
        record, issues, _ = self.update(payload)
        validate(record, issues, "initial")
        self.assertIn("已完成", render(record, issues))

    def test_issue_deltas_append_complete_snapshots_and_reopen(self):
        first = issue("dismissed")
        first.pop("seq")
        first.pop("updated_at")
        self.update({"issues": [first]})
        self.update({"issues": [{"id": "R001", "status": "pending",
                                 "disposition": "New dispatch", "next_check": "Inspect worker"}]})
        _, latest = self.read()
        self.assertEqual(latest["R001"]["seq"], 2)
        self.assertEqual(latest["R001"]["summary"], first["summary"])
        history = query(self.path, *self.read(), "history", "R001")
        self.assertEqual([event["status"] for event in history], ["dismissed", "pending"])
        self.update({"issues": [{"id": "R001", "status": "confirmed",
                                 "disposition": "Source verified"}]})
        before = self.path.with_name("issues.jsonl").read_bytes()
        with self.assertRaisesRegex(RecordError, "reopen"):
            self.update({"issues": [{"id": "R001", "status": "dismissed"}]})
        self.assertEqual(before, self.path.with_name("issues.jsonl").read_bytes())

    def test_auto_issue_ids_and_sequence_are_tool_owned(self):
        delta = issue("pending")
        for key in ("id", "seq", "updated_at"):
            delta.pop(key)
        _, latest, result = self.update({"issues": [delta, delta]})
        self.assertEqual(result["confirmed"], 0)
        self.assertEqual(set(latest), {"R001", "R002"})
        with self.assertRaisesRegex(RecordError, "tool-maintained"):
            self.update({"issues": [{"id": "R001", "seq": 10}]})

    def test_reciprocal_links_can_be_created_in_one_update(self):
        finding = issue()
        finding.pop("seq")
        finding.pop("updated_at")
        finding["trace_ids"] = ["T001"]
        record, issues, _ = self.update({
            "issues": [finding],
            "traces": [{"id": "T001", "status": "finding", "issue_ids": ["R001"],
                        "evidence": ["main.c:1"]}],
        })
        validate(record, issues)
        before = self.path.read_bytes()
        with self.assertRaisesRegex(RecordError, "reverse"):
            self.update({"traces": [{"id": "T001", "issue_ids": []}]})
        self.assertEqual(self.path.read_bytes(), before)

    def test_catalog_reuse_and_changed_evidence_reopens_dependents(self):
        delta = issue("dismissed")
        delta.pop("seq")
        delta.pop("updated_at")
        delta["evidence"] = ["@E001"]
        self.update({
            "evidence_catalog": {"E001": {"summary": "Dispatch contract",
                                          "evidence": ["main.c:1"]}},
            "issues": [delta],
        })
        record, issues, _ = self.update({
            "evidence_catalog": {"E001": {"summary": "Worker dispatch discovered",
                                          "evidence": ["helper.c:1"]}},
            "reason": "Recheck worker lifetime",
        })
        self.assertEqual(issues["R001"]["status"], "pending")
        self.assertEqual(issues["R001"]["seq"], 2)
        history = query(self.path, record, issues, "history", "R001")
        self.assertEqual(history[0]["evidence_snapshots"]["E001"]["evidence"], ["main.c:1"])
        self.assertEqual(history[1]["evidence_snapshots"]["E001"]["evidence"], ["main.c:1"])
        self.update({"issues": [{"id": "R001", "disposition": "New evidence inspected"}]})
        _, refreshed = self.read()
        self.assertEqual(refreshed["R001"]["evidence_snapshots"]["E001"]["evidence"],
                         ["helper.c:1"])
        value = query(self.path, record, issues, "issue", "R001")
        self.assertEqual(value["evidence_catalog"]["E001"]["evidence"], ["helper.c:1"])
        with self.assertRaisesRegex(RecordError, "Unknown evidence"):
            self.update({"file_checks": {"main.c": {"functional_paths": {
                "status": "inspected", "evidence": ["@missing"]}}}})

    def test_resume_is_paginated_and_excludes_issue_history(self):
        record, issues = self.read()
        result = working_set(record, issues)
        self.assertEqual(result["tasks"][0]["id"], "main.c")
        self.assertEqual(result["next_offset"], 1)
        self.assertNotIn("remaining_files", result["coverage"])
        self.assertEqual(working_set(record, issues, 1)["tasks"][0]["id"], "helper.c")
        self.assertTrue(result["resume_allowed"])
        self.assertNotIn("issues.jsonl", json.dumps(result))

    def test_source_change_blocks_resume_and_requires_explicit_invalidation(self):
        self.update(self.complete_files())
        (self.repository / "main.c").write_text("int main(void) { return 1; }\n")
        record, issues = self.read()
        result = working_set(record, issues)
        self.assertFalse(result["resume_allowed"])
        self.assertIn("main.c", result["source_changes"])
        with self.assertRaisesRegex(RecordError, "explicitly invalidate"):
            self.update({"progress": {"next_step": "Read main"}})
        record, issues, _ = self.update({
            "invalidate": ["main.c"], "reason": "Source changed; re-read main.c"})
        self.assertEqual(record["file_checks"]["main.c"]["functional_paths"]["status"], "pending")
        self.assertEqual(record["file_checks"]["helper.c"]["functional_paths"]["status"], "inspected")
        self.assertTrue(working_set(record, issues)["resume_allowed"])

    def test_supporting_file_change_invalidates_evidence_dependencies(self):
        self.update(self.complete_files())
        self.update({"evidence_catalog": {
            "E001": {"summary": "Interface", "evidence": ["module.h:1"]}},
            "file_checks": {"main.c": {"call_interface": {
                "status": "inspected", "evidence": ["@E001"]}}}})
        (self.repository / "module.h").write_text("long helper(void);\n")
        record, _, _ = self.update({
            "invalidate": ["module.h"], "reason": "Interface changed"})
        self.assertEqual(record["file_checks"]["main.c"]["call_interface"]["status"], "pending")
        self.assertEqual(record["file_checks"]["helper.c"]["call_interface"]["status"], "inspected")

    def test_shared_state_dependency_invalidation_preserves_links(self):
        record, group = state_record()
        record["source"]["repository"] = str(self.repository)
        record["file_checks"]["src/file0.c"]["identity"] = "unused test hash"
        with patch("manage_review_record.source_changes", return_value={}):
            updated, issues, _ = apply_update(record, {}, {
                "invalidate": ["T001"], "reason": "New runtime caller"})
        self.assertEqual(updated["state_groups"][0]["status"], "pending")
        self.assertEqual(updated["file_checks"]["src/file0.c"]["shared_state_context"]
                         ["state_group_ids"], ["S001"])
        validate(updated, issues, "progress")
        with self.assertRaises(RecordError):
            validate(updated, issues, "integration")

    def test_interrupted_transaction_replays_partial_append_once(self):
        record, issues = self.read()
        delta = issue("pending")
        delta.pop("seq")
        delta.pop("updated_at")
        updated, _, events = apply_update(record, issues, {"issues": [delta]})
        with patch("manage_review_record.recover", side_effect=OSError("interruption")):
            with self.assertRaises(OSError):
                commit_update(self.path, updated, events)
        with self.assertRaisesRegex(RecordError, "Unfinished record transaction"):
            load_record(self.path)
        suffix = (json.dumps(events[0], ensure_ascii=False) + "\n").encode()
        self.path.with_name("issues.jsonl").write_bytes(suffix[:15])
        recover(self.path)
        _, latest = self.read()
        self.assertEqual(latest["R001"]["seq"], 1)
        self.assertEqual(len(self.path.with_name("issues.jsonl").read_text().splitlines()), 1)
        self.assertFalse(self.path.with_name("transaction.json").exists())

    def test_transaction_recovery_refuses_external_edits(self):
        record, issues = self.read()
        updated, _, events = apply_update(record, issues, {})
        with patch("manage_review_record.recover", side_effect=OSError("interruption")):
            with self.assertRaises(OSError):
                commit_update(self.path, updated, events)
        self.path.write_bytes(encoded({**record, "limitations": ["external edit"]}))
        with self.assertRaisesRegex(RecordError, "external edits"):
            recover(self.path)

    def test_cli_errors_and_scoped_query(self):
        script = Path(__file__).with_name("manage_review_record.py")
        result = subprocess.run([sys.executable, str(script), "resume", str(self.path)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(json.loads(result.stdout)["tasks"]), 1)
        failed = subprocess.run([sys.executable, str(script), "get", str(self.path),
                                 "--kind", "issue", "--id", "unknown"],
                                capture_output=True, text=True)
        self.assertEqual(failed.returncode, 1)
        self.assertEqual(failed.stdout, "")
        self.assertIn("Unknown issue", failed.stderr)

    def test_write_summaries_do_not_dump_remaining_files(self):
        _, _, result = self.update({})
        self.assertNotIn("remaining_files", result)
        self.assertEqual(result["pending_files"], 2)
        self.assertEqual(result["next_file"], "main.c")

    def test_malformed_payloads_fail_without_writing(self):
        before = self.path.read_bytes()
        for payload in ({"file_checks": []}, {"issues": {}}, {"traces": "T001"},
                        {"file_checks": {"main.c": []}}, {"limitations": [1]},
                        {"unknown": True}, {"invalidate": ["missing"], "reason": "Unknown ID"}):
            with self.subTest(payload=payload), self.assertRaises(RecordError):
                self.update(payload)
        self.assertEqual(before, self.path.read_bytes())

    def test_cli_update_returns_allocated_ids_without_history(self):
        script = Path(__file__).with_name("manage_review_record.py")
        delta = issue("pending")
        for key in ("id", "seq", "updated_at"):
            delta.pop(key)
        result = subprocess.run(
            [sys.executable, str(script), "update", str(self.path)],
            input=json.dumps({"issues": [delta]}), capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        saved = json.loads(result.stdout)
        self.assertEqual(saved["updated_issue_ids"], ["R001"])
        self.assertNotIn("remaining_files", saved)

    def test_failed_location_check_does_not_create_repository_lock(self):
        record, _ = self.read()
        path = self.repository / "review.json"
        path.write_bytes(encoded(record))
        path.with_name("issues.jsonl").touch()
        script = Path(__file__).with_name("manage_review_record.py")
        result = subprocess.run([sys.executable, str(script), "resume", str(path)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("outside", result.stderr)
        self.assertFalse(path.with_name("record.lock").exists())

    def test_skill_is_routed_and_keeps_scope_failure_contracts(self):
        skill = Path(__file__).resolve().parents[1]
        content = (skill / "SKILL.md").read_text()
        self.assertLessEqual(len(content.splitlines()), 180)
        self.assertIn("未提供有效的 Git diff，请先暂存变更或指定一个 Git commit。", content)
        self.assertIn("无法获取指定 Gerrit change/patchset 的有效 diff", content)
        for name in ("record-tools.md", "report-format.md", "module-review-completion.md"):
            self.assertIn(name, content)
            self.assertTrue((skill / "references" / name).is_file())
        self.assertIn("Non-module", content)

    def test_long_history_is_retained_but_resume_emits_latest_issue_only(self):
        delta = issue("pending")
        delta.pop("seq")
        delta.pop("updated_at")
        self.update({"issues": [delta]})
        for number in range(20):
            self.update({"issues": [{"id": "R001", "disposition": f"Checked caller {number}"}]})
        record, issues = self.read()
        result = working_set(record, issues, offset=2)
        self.assertEqual(result["task_count"], 3)
        self.assertEqual(len(result["tasks"]), 1)
        self.assertEqual(result["tasks"][0]["record"]["seq"], 21)
        self.assertLess(len(json.dumps(result)), 4000)
        self.assertEqual(len(query(self.path, record, issues, "history", "R001")), 21)

    def test_evidence_prose_is_not_mistaken_for_a_reference(self):
        record, issues, _ = self.update({"evidence_catalog": {
            "E001": {"summary": "@symbol denotes a callback", "evidence": ["main.c:1"]}}})
        result = query(self.path, record, issues, "evidence", "E001")
        self.assertEqual(result["evidence_catalog"], {})

    def test_symlink_sources_cannot_escape_repository(self):
        outside = self.repository.parent / "outside.c"
        outside.write_text("int outside;\n")
        (self.repository / "escape.c").symlink_to(outside)
        manifest = deepcopy(self.manifest)
        manifest["files"][0]["path"] = "escape.c"
        with self.assertRaisesRegex(RecordError, "outside repository"):
            initialize(self.path.parent.parent / "other" / "review.json", manifest)

    def test_invalidating_merged_issue_reopens_surviving_root(self):
        root = issue()
        root.pop("seq")
        root.pop("updated_at")
        merged = {**root, "id": "R002", "status": "merged", "merged_into": "R001"}
        self.update({"issues": [root, merged]})
        _, issues, _ = self.update({
            "invalidate": ["R002"], "reason": "Merged trigger contract changed"})
        self.assertEqual(issues["R001"]["status"], "pending")
        self.assertEqual(issues["R002"]["status"], "merged")

    def test_incremental_record_generates_existing_final_report(self):
        payload = self.complete_files()
        finding = issue()
        finding.pop("seq")
        finding.pop("updated_at")
        finding.update(evidence=["@E001"], location="main.c:1")
        payload.update(
            inventory_reconciled=True,
            validation={"status": "unavailable", "details": "No target compiler"},
            evidence_catalog={"E001": {"summary": "Verified error path",
                                       "evidence": ["main.c:1"]}},
            issues=[finding])
        self.update(payload)
        script = Path(__file__).with_name("generate_review_report.py")
        result = subprocess.run([sys.executable, str(script), str(self.path)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("评审状态：已完成", result.stdout)
        self.assertIn("初审 2/2", result.stdout)
        self.assertIn("- [High] main.c:1", result.stdout)
        self.assertEqual(result.stdout.count("- [High]"), 1)
        record, issues = self.read()
        validate(record, issues, "final")


if __name__ == "__main__":
    unittest.main()
