"""Deterministic regression tests; never execute reviewed fixture code."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from generate_review_report import render
from validate_review_record import CHECKS, RecordError, load_record, validate


def record_for(count=1, completed=1):
    paths = [f"src/file{i}.c" for i in range(count)]
    return {
        "schema_version": 3,
        "source": {"repository": "/reviewed-repository", "module": "example",
                   "identity": "test snapshot", "spec_available": False},
        "inventory": {"reconciled": True, "discovered": count, "in_scope": count,
                      "excluded": 0, "files": [
                          {"path": path, "status": "in_scope"} for path in paths]},
        "file_checks": {path: {
            "identity": "test hash",
            **{key: {"status": "inspected" if i < completed else "pending",
                     "evidence": [f"{path}:1-10"] if i < completed else []}
               for key in CHECKS},
            "shared_state_context": {
                "status": "inspected" if i < completed else "pending",
                "evidence": [f"{path}:1-10"] if i < completed else [],
                "state_group_ids": [], "no_state_reason": "No mutable state in test file"}}
            for i, path in enumerate(paths)},
        "state_groups": [],
        "traces": [], "validation": {"status": "unavailable", "details": "test only"},
        "progress": {"phase": "initial", "next_step": "Inspect next path", "blockers": []},
        "report_map": {}, "limitations": [],
    }


def issue(status="confirmed"):
    return {
        "id": "R001", "seq": 1, "updated_at": "2026-10-23T14:00:00+08:00",
        "origin": "initial src/file0.c:3", "summary": "测试问题",
        "evidence": ["src/file0.c:3"], "dependencies": ["resource"],
        "open_questions": [], "trace_ids": [], "next_check": "Inspect caller",
        "status": status, "disposition": "source evidence", "merged_into": None,
        "location": "src/file0.c:3", "severity": "High", "axis": "Standards",
        "cause": "失败路径未释放资源。", "recommendation": "补齐清理。",
        "rule": "资源生命周期",
    }


def state_record(ordering="initialization_only"):
    record = record_for()
    record["file_checks"]["src/file0.c"]["shared_state_context"]["state_group_ids"] = ["S001"]
    group = {
        "id": "S001", "symbols": ["cache.address", "cache.mask"],
        "files": ["src/file0.c"], "trace_ids": ["T001"], "status": "verified",
        "writers": [{"id": "W001", "location": "src/file0.c:10", "function": "refresh",
                     "context": "main", "kind": "direct", "phase": "startup",
                     "evidence": ["main.c:10 refresh before worker creation"]}],
        "readers": [{"id": "A001", "location": "src/file0.c:20", "function": "query",
                     "context": "worker", "kind": "worker", "phase": "runtime",
                     "evidence": ["src/file0.c:20 reads cache"],
                     "dispatch_evidence": ["main.c:11 creates worker calling query"]}],
        "access_inventory": {"status": "complete",
                             "evidence": ["Scoped symbol/alias/caller search; all hits classified"]},
        "ordering": {"kind": ordering, "access_ids": ["W001", "A001"],
                     "evidence": ["main.c:10-11 publishes cache before pthread_create"]},
        "counterexample_check": {
            "status": "complete",
            "checked": ["runtime_writers", "async_dispatch", "synchronization_both_sides"],
            "evidence": ["Reviewed refresh callers/registration; no post-start writer"]},
        "evidence": ["All writes precede worker startup"],
    }
    record["state_groups"] = [group]
    record["traces"] = [{"id": "T001", "status": "verified", "kind": "shared_state",
                         "state_group_ids": ["S001"], "issue_ids": [],
                         "evidence": ["main.c:10-11"]}]
    return record, group


class ReviewRecordTests(unittest.TestCase):
    def test_state_safe_ordering_patterns(self):
        for kind in ("initialization_only", "single_context", "common_lock", "snapshot",
                     "atomic", "ownership"):
            with self.subTest(kind=kind):
                record, group = state_record(kind)
                if kind == "single_context":
                    group["readers"][0]["context"] = "main"
                if kind in ("common_lock", "snapshot", "atomic"):
                    group["ordering"]["protocol"] = "cache publication protocol"
                    for access in group["writers"] + group["readers"]:
                        access["protocol"] = "cache publication protocol"
                        access["synchronization_evidence"] = ["src/file0.c:1-30 protocol coverage"]
                report = render(record, {})
                self.assertIn("共享状态组闭环 1/1", report)

    def test_runtime_callback_invalidates_initialization_only(self):
        record, group = state_record()
        group["writers"].append({
            "id": "W002", "location": "server.c:1090", "function": "lan_update",
            "context": "uloop", "kind": "callback", "phase": "runtime",
            "evidence": ["server.c:1090 calls refresh"],
            "dispatch_evidence": ["server.c:407 registers lan_update"]})
        group["ordering"]["access_ids"].append("W002")
        with self.assertRaisesRegex(RecordError, "runtime writer contradicts"):
            render(record, {})
        group["status"] = "pending"
        group["next_check"] = "Compare runtime refresh with worker read"
        record["traces"][0]["status"] = "pending"
        validate(record, {}, "initial")
        with self.assertRaisesRegex(RecordError, "Unresolved state groups"):
            render(record, {})
        record["progress"]["interruption"] = "User stop"
        report = render(record, {}, partial=True)
        self.assertIn("共享状态组闭环 0/1", report)
        self.assertIn("S001", report)
        group["status"] = record["traces"][0]["status"] = "finding"
        record["traces"][0]["issue_ids"] = ["R001"]
        finding = issue()
        finding.update(trace_ids=["T001"], cause="运行期刷新与 worker 无共同同步。",
                       review_category="synchronization", state_group_ids=["S001"])
        self.assertIn("运行期刷新", render(record, {"R001": finding}, partial=True))

    def test_state_evidence_and_dedicated_trace_requirements(self):
        mutations = [
            (lambda r, g: g.update(trace_ids=[]), "trace_ids required"),
            (lambda r, g: r["traces"][0].pop("kind"), "dedicated shared_state"),
            (lambda r, g: g["readers"][0].pop("dispatch_evidence"), "dispatch evidence"),
            (lambda r, g: g["readers"][0].update(phase="unknown"), "unresolved access"),
            (lambda r, g: g["access_inventory"].update(status="pending"), "inventory incomplete"),
            (lambda r, g: g["counterexample_check"].update(evidence=[]), "counterexample"),
            (lambda r, g: g["ordering"].update(access_ids=["W001"]), "every access"),
            (lambda r, g: g["ordering"].update(kind="single_context"), "different contexts"),
            (lambda r, g: r["file_checks"]["src/file0.c"]["shared_state_context"]
             .update(state_group_ids=[]), "reverse file"),
        ]
        for mutate, message in mutations:
            with self.subTest(message=message):
                record, group = state_record()
                mutate(record, group)
                with self.assertRaisesRegex(RecordError, message):
                    validate(record, {})

    def test_writer_only_lock_does_not_close_state_group(self):
        record, group = state_record("common_lock")
        group["ordering"]["protocol"] = "UCI_LOCK"
        group["writers"][0].update(protocol="UCI_LOCK",
                                   synchronization_evidence=["refresh: lock covers write"])
        with self.assertRaisesRegex(RecordError, "both sides"):
            render(record, {})

    def test_callback_startup_label_is_not_a_startup_proof(self):
        record, group = state_record()
        writer = group["writers"][0]
        writer.update(kind="callback", dispatch_evidence=["server.c:407 registration"])
        with self.assertRaisesRegex(RecordError, "cannot run after startup"):
            render(record, {})
        writer["startup_only_evidence"] = [
            "startup.c:12 synchronous callback completes and unregisters before worker creation"]
        render(record, {})

    def test_write_only_state_is_not_implicitly_safe(self):
        record, group = state_record()
        group["readers"] = []
        group["ordering"]["access_ids"] = ["W001"]
        with self.assertRaisesRegex(RecordError, "no_readers_reason"):
            render(record, {})
        group["no_readers_reason"] = "Scoped alias search found writes only"
        render(record, {})
        group["status"] = record["traces"][0]["status"] = "finding"
        record["traces"][0]["issue_ids"] = ["R001"]
        finding = {**issue(), "trace_ids": ["T001"],
                   "review_category": "synchronization", "state_group_ids": ["S001"]}
        with self.assertRaisesRegex(RecordError, "conflicting accesses"):
            render(record, {"R001": finding})

    def test_capacity_finding_cannot_close_synchronization_trace(self):
        record, group = state_record()
        record["traces"][0]["status"] = "finding"
        record["traces"][0]["issue_ids"] = ["R001"]
        finding = issue()
        finding["trace_ids"] = ["T001"]
        with self.assertRaisesRegex(RecordError, "dispositions disagree"):
            render(record, {"R001": finding})
        group["status"] = "finding"
        with self.assertRaisesRegex(RecordError, "synchronization finding"):
            render(record, {"R001": finding})

    def test_state_inventory_is_explicit_and_old_records_rejected(self):
        record = record_for()
        record["schema_version"] = 2
        with self.assertRaisesRegex(RecordError, "migrate explicitly"):
            validate(record, {})
        record["schema_version"] = 3
        record.pop("state_groups")
        with self.assertRaisesRegex(RecordError, "state_groups must"):
            validate(record, {})
        record = record_for()
        record["file_checks"]["src/file0.c"]["shared_state_context"].pop("no_state_reason")
        with self.assertRaisesRegex(RecordError, "no_state_reason"):
            validate(record, {})

    def test_real_failure_shape_cannot_complete(self):
        record = record_for(30, 17)
        record["traces"] = [{"id": f"T{i}", "status": "pending", "issue_ids": []}
                            for i in range(7)]
        issues = {f"R{i}": {**issue("pending"), "id": f"R{i}"} for i in range(7)}
        self.assertEqual(validate(record, issues)["completed"], 17)
        with self.assertRaisesRegex(RecordError, "Initial pass incomplete"):
            render(record, issues)
        record["progress"]["interruption"] = "用户要求停止"
        report = render(record, issues, partial=True)
        self.assertIn("17/30", report)
        self.assertIn("尚不能判定", report)
        self.assertNotIn("[High]", report)

    def test_final_requires_mapping_generator_creates_it(self):
        record = record_for()
        issues = {"R001": issue()}
        with self.assertRaisesRegex(RecordError, "missing report mapping"):
            validate(record, issues, "final")
        report = render(record, issues)
        self.assertEqual(report.count("- [High]"), 1)
        self.assertEqual(record["report_map"], {"R001": "finding-1"})
        validate(record, issues, "final")

    def test_progress_derives_remaining_after_resume(self):
        result = validate(record_for(30, 17), {})
        self.assertEqual(len(result["remaining_files"]), 13)
        self.assertEqual(result["remaining_files"][0], "src/file17.c")
        record = record_for()
        record["progress"]["remaining_files"] = []
        with self.assertRaisesRegex(RecordError, "Remove derived"):
            validate(record, {})

    def test_pending_issues_and_traces_block_completion(self):
        record = record_for()
        with self.assertRaisesRegex(RecordError, "Unresolved issues"):
            render(record, {"R001": issue("pending")})
        record["traces"] = [{"id": "T001", "status": "pending", "issue_ids": []}]
        with self.assertRaisesRegex(RecordError, "Unresolved traces"):
            render(record, {})

    def test_links_counts_and_evidence(self):
        record = record_for()
        record["inventory"]["discovered"] = 33
        with self.assertRaisesRegex(RecordError, "inconsistent"):
            validate(record, {})
        record = record_for()
        suspect = issue("pending")
        suspect["trace_ids"] = ["T001"]
        with self.assertRaisesRegex(RecordError, "reverse trace"):
            validate(record, {"R001": suspect})
        record["traces"] = [{"id": "T001", "status": "pending", "issue_ids": ["R001"]}]
        validate(record, {"R001": suspect})
        record["file_checks"]["src/file0.c"]["functional_paths"]["evidence"] = []
        with self.assertRaisesRegex(RecordError, "without evidence"):
            validate(record, {"R001": suspect})

    def test_merge_cycles_and_reopened_mapping(self):
        record = record_for()
        merged = issue("merged")
        merged["merged_into"] = "R001"
        with self.assertRaisesRegex(RecordError, "cyclic merge"):
            validate(record, {"R001": merged})
        record["report_map"] = {"R001": "finding-1"}
        with self.assertRaisesRegex(RecordError, "unconfirmed"):
            validate(record, {"R001": issue("pending")})

    def test_no_spec_and_partial_reason(self):
        record = record_for()
        with self.assertRaisesRegex(RecordError, "interruption reason"):
            render(record, {}, partial=True)
        spec = issue()
        spec["axis"] = "Spec"
        with self.assertRaisesRegex(RecordError, "without a specification"):
            render(record, {"R001": spec})
        record["source"]["spec_available"] = True
        report = render(record, {"R001": spec})
        self.assertIn("## Standards（规范符合性）", report)
        self.assertIn("## Spec（需求符合性）", report)

    def test_interruption_and_orphan_finding_cannot_complete(self):
        record = record_for()
        record["progress"]["interruption"] = "用户要求停止"
        with self.assertRaisesRegex(RecordError, "Clear interruption"):
            render(record, {})
        record["progress"].pop("interruption")
        record["traces"] = [{"id": "T001", "status": "finding",
                             "issue_ids": [], "evidence": ["src/file0.c:3"]}]
        with self.assertRaisesRegex(RecordError, "no corresponding finding"):
            validate(record, {})

    def test_actual_files_event_history_and_cli(self):
        with tempfile.TemporaryDirectory() as directory:
            working = Path(directory) / "work"
            working.mkdir()
            path = Path(directory) / "review.json"
            journal = path.with_name("issues.jsonl")
            path.write_text(json.dumps(record_for()), encoding="utf-8")
            first = issue("dismissed")
            second = {**first, "seq": 2, "status": "pending", "disposition": "New evidence"}
            journal.write_text(json.dumps(first) + "\n" + json.dumps(second) + "\n",
                               encoding="utf-8")
            _, _, issues = load_record(path)
            self.assertEqual(issues["R001"]["status"], "pending")
            script = Path(__file__).with_name("generate_review_report.py")
            failed = subprocess.run([sys.executable, str(script), str(path)],
                                    capture_output=True, text=True, cwd=working)
            self.assertEqual(failed.returncode, 1)
            self.assertEqual(failed.stdout, "")
            third = {**issue(), "seq": 3}
            with journal.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(third) + "\n")
            result = subprocess.run([sys.executable, str(script), str(path)],
                                    capture_output=True, text=True, cwd=working)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("评审状态：已完成", result.stdout)
            _, saved, latest = load_record(path)
            report_path = working / saved["report_file"]
            self.assertEqual(saved["report_directory"], str(working))
            self.assertEqual(list(path.parent.glob("*.md")), [])
            self.assertRegex(report_path.name, r"^\d{4}-\d{2}-\d{2}-example-评审报告-v1\.md$")
            self.assertIn(f"报告文件：{report_path}", result.stdout)
            self.assertNotIn("- [High]", result.stdout)
            self.assertEqual(report_path.read_text(encoding="utf-8").count("- [High]"), 1)
            validate(saved, latest, "final")
            self.assertEqual(len(journal.read_text().splitlines()), 3)
            # A truncated append must never be ignored as an empty issue list.
            with journal.open("a", encoding="utf-8") as handle:
                handle.write("{")
            with self.assertRaisesRegex(RecordError, "issues.jsonl:4"):
                load_record(path)

    def test_partial_report_is_updated_in_place_until_complete(self):
        with tempfile.TemporaryDirectory() as directory:
            working = Path(directory) / "work"
            working.mkdir()
            path = Path(directory) / "review.json"
            record = record_for(completed=0)
            record["progress"]["interruption"] = "用户要求暂停"
            record["report_file"] = "2020-01-02-example-评审报告-v1.md"
            path.write_text(json.dumps(record), encoding="utf-8")
            path.with_name("issues.jsonl").write_text("", encoding="utf-8")
            script = Path(__file__).with_name("generate_review_report.py")
            command = [sys.executable, str(script), str(path)]
            report_path = working / record["report_file"]
            for step in ("Inspect first file", "Resume first file"):
                record["progress"]["next_step"] = step
                path.write_text(json.dumps(record), encoding="utf-8")
                result = subprocess.run(command + ["--partial"], capture_output=True,
                                        text=True, cwd=working)
                self.assertEqual(result.returncode, 0, result.stderr)
                report = report_path.read_text(encoding="utf-8")
                self.assertIn("评审状态：未完成（阶段结果）", report)
                self.assertIn(step, report)
                self.assertIn("初审 0/1", report)
                self.assertIn(str(report_path), result.stdout)
                record = json.loads(path.read_text())
            previous = report
            failed = subprocess.run(command, capture_output=True, text=True, cwd=directory)
            self.assertEqual(failed.returncode, 1)
            self.assertEqual(report_path.read_text(encoding="utf-8"), previous)
            completed = record_for()
            completed["report_file"] = record["report_file"]
            completed["report_directory"] = record["report_directory"]
            path.write_text(json.dumps(completed), encoding="utf-8")
            result = subprocess.run(command, capture_output=True, text=True, cwd=directory)
            self.assertEqual(result.returncode, 0, result.stderr)
            report = report_path.read_text(encoding="utf-8")
            self.assertIn("评审状态：已完成", report)
            self.assertIn("初审 1/1", report)
            self.assertNotIn("中断原因", report)
            self.assertEqual(list(working.glob("*.md")), [report_path])
            self.assertEqual(list(path.parent.glob("*.md")), [])
            self.assertEqual(json.loads(path.read_text())["report_file"], record["report_file"])

    def test_report_rejects_escaping_filename_and_symlink(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "review.json"
            path.with_name("issues.jsonl").write_text("", encoding="utf-8")
            script = Path(__file__).with_name("generate_review_report.py")
            report_path = path.parent / "2020-01-02-example-评审报告-v1.md"
            report_path.symlink_to(path)
            original = None
            for filename in ("../2020-01-02-example-评审报告-v1.md", report_path.name):
                record = record_for()
                record["report_file"] = filename
                original = json.dumps(record)
                path.write_text(original, encoding="utf-8")
                result = subprocess.run([sys.executable, str(script), str(path)],
                                        capture_output=True, text=True, cwd=directory)
                self.assertEqual(result.returncode, 1)
                self.assertEqual(result.stdout, "")
                self.assertEqual(path.read_text(encoding="utf-8"), original)

    def test_sequence_and_record_location(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "review.json"
            record = record_for()
            path.write_text(json.dumps(record))
            journal = path.with_name("issues.jsonl")
            journal.write_text(json.dumps({**issue(), "seq": 2}) + "\n")
            with self.assertRaisesRegex(RecordError, "sequence"):
                load_record(path)
            record["source"]["repository"] = directory
            path.write_text(json.dumps(record))
            with self.assertRaisesRegex(RecordError, "outside"):
                load_record(path)


if __name__ == "__main__":
    unittest.main()
