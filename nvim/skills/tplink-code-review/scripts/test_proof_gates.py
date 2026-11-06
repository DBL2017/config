"""Operation-level closure regressions; C snippets are data, never executed."""

from pathlib import Path
import tempfile
import unittest

from discover_risk_sites import discover, extract_calls, verify_sources
from generate_review_report import render
from manage_review_record import apply_update, initialize, query, working_set
from test_review_record import issue, no_risk_inventory, record_for, risk_record
from validate_review_record import RecordError, load_record, scan_fields, validate


class ProofGateTests(unittest.TestCase):
    def test_discovery_ignores_comments_strings_and_keeps_each_multiline_call(self):
        source = b'''int run(void) {
            /* sscanf(fake); */ const char *note = "strcpy(fake)";
            sscanf(line,
                   "%15[^.].%15[^=]=%5s", one, two, state);
            sscanf(other, "%[^.]", one);
            project_copy(out, in);
        }'''
        scan = discover(source, "main.c")
        self.assertEqual([item["callee"] for item in scan["candidates"]], ["sscanf", "sscanf"])
        self.assertEqual(scan["candidates"][0]["function"], "run")
        self.assertEqual(scan["candidates"][0]["format_string"], "%15[^.].%15[^=]=%5s")
        self.assertGreater(scan["candidates"][0]["end_line"], scan["candidates"][0]["line"])
        self.assertIn("project_copy", [item["callee"] for item in extract_calls(source, "main.c")])

    def test_one_known_candidate_cannot_be_omitted_or_closed_by_broad_trace(self):
        record, site = risk_record()
        anchor = {**site.pop("manual_anchor"), "category": "string_boundary"}
        check = record["file_checks"]["src/file0.c"]["functional_paths"]
        check["candidate_scan"]["candidates"] = [anchor]
        with self.assertRaisesRegex(RecordError, "extracted candidates"):
            validate(record, {}, "initial")
        site["candidate_id"] = anchor["id"]
        validate(record, {}, "integration")
        site["location"] = "src/file0.c:1-2500"
        with self.assertRaisesRegex(RecordError, "one exact call"):
            validate(record, {}, "integration")

    def test_a_finding_does_not_close_other_failure_scenarios(self):
        record, site = risk_record("allocation_io", "finding")
        site.update(disposition="confirmed_defect", issue_ids=["R001"])
        finding = issue()
        finding["trace_ids"] = ["T001"]
        site["scenarios"]["operation_failure"].update(status="finding", issue_ids=["R001"])
        site["scenarios"]["caller_failure"].update(status="pending", next_check="Check caller deletion")
        with self.assertRaisesRegex(RecordError, "unresolved scenario"):
            render(record, {"R001": finding})
        site["scenarios"]["caller_failure"].update(
            status="finding", issue_ids=["R001"], reason="Caller deletes failed batch")
        validate(record, {"R001": finding}, "integration")
        del site["scenarios"]["cleanup"]
        with self.assertRaisesRegex(RecordError, "missing applicable scenarios"):
            validate(record, {"R001": finding})

    def test_safe_numeric_bounds_and_producer_claims_are_checked(self):
        record, site = risk_record()
        buffer = site["facts"]["buffers"][0]
        buffer.update(capacity=128, max_bytes=127, suffix_bytes=6, nul_bytes=1)
        with self.assertRaisesRegex(RecordError, "exceeds capacity"):
            validate(record, {})
        buffer.update(max_bytes=121, bound_basis="producer")
        with self.assertRaisesRegex(RecordError, "producer limit"):
            validate(record, {})
        buffer["producer_evidence"] = ["producer.c:10 rejects names longer than 121"]
        validate(record, {}, "integration")

    def test_each_unbounded_scanset_needs_its_own_enforced_bound(self):
        record, site = risk_record("scan_conversion")
        site["facts"].update(format_string="%[^.].%[^.=]=%5s", conversions=[
            {"index": 1, "conversion": "[", "width": None, "nul_bytes": 1,
             "capacity": 16, "evidence": ["src/file0.c:3"]},
            {"index": 2, "conversion": "[", "width": None, "nul_bytes": 1,
             "capacity": 16, "evidence": ["src/file0.c:3"]},
            {"index": 3, "conversion": "s", "width": 5, "nul_bytes": 1,
             "capacity": 512, "evidence": ["src/file0.c:3"]},
        ])
        with self.assertRaisesRegex(RecordError, "enforced producer bound"):
            validate(record, {})
        first, second, _ = site["facts"]["conversions"]
        first.update(producer_max=4, producer_evidence=["writer.c:5 fixed package"])
        with self.assertRaisesRegex(RecordError, "enforced producer bound"):
            validate(record, {})
        second.update(producer_max=12, producer_evidence=["writer.c:6 enforced section length"])
        validate(record, {}, "integration")
        second["width"] = 15
        with self.assertRaisesRegex(RecordError, "differs from format"):
            validate(record, {})

    def test_claim_level_requires_runtime_trigger_not_just_missing_terminator(self):
        record = record_for()
        finding = issue()
        finding["claim"] = {"level": "runtime", "evidence": ["src/file0.c:3"]}
        with self.assertRaisesRegex(RecordError, "runtime trigger"):
            validate(record, {"R001": finding}, "integration")
        finding["claim"]["level"] = "standards"
        validate(record, {"R001": finding}, "integration")

    def test_scan_fields_handle_default_character_width_and_literal_brackets(self):
        self.assertEqual(scan_fields("%c %*s %15[]a]"), [
            {"index": 1, "conversion": "c", "width": 1, "nul_bytes": 0},
            {"index": 2, "conversion": "[", "width": 15, "nul_bytes": 1},
        ])

    def test_source_scan_is_tool_owned_and_rechecked_against_disk(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repo = root / "repo"
            repo.mkdir()
            source = repo / "main.c"
            source.write_text('int run(void) { char out[16]; return snprintf(out, 16, "%s", "ok"); }\n')
            path = root / "record" / "review.json"
            initialize(path, {
                "source": {"repository": str(repo), "review_kind": "file",
                           "module": "main.c", "identity": "worktree"},
                "files": [{"path": "main.c", "status": "in_scope"}],
            })
            _, record, issues = load_record(path)
            work = working_set(record, issues)
            self.assertEqual(work["tasks"][0]["record"]["functional_paths"]
                             ["candidate_scan"]["candidate_count"], 1)
            page = query(path, record, issues, "candidates", "main.c", 0, 5)
            self.assertEqual(page["total"], 1)
            self.assertEqual(page["items"][0]["callee"], "snprintf")
            self.assertIsNone(page["next_offset"])
            with self.assertRaisesRegex(RecordError, "tool-maintained"):
                apply_update(record, issues, {"file_checks": {"main.c": {
                    "functional_paths": {"candidate_scan": {}}}}})
            verify_sources(record)
            scan = record["file_checks"]["main.c"]["functional_paths"]["candidate_scan"]
            scan["candidates"][0]["expression_sha256"] = "fabricated"
            with self.assertRaisesRegex(ValueError, "missing or stale"):
                verify_sources(record)
            scan.update(discover(source.read_bytes(), "main.c"))
            source.write_text(source.read_text() + "/* source changed */\n")
            with self.assertRaisesRegex(ValueError, "source changed"):
                verify_sources(record)

    def test_prior_import_reconciliation_and_immutable_original(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repo = root / "repo"
            repo.mkdir()
            (repo / "main.c").write_text("int run(void) { return 0; }\n")
            prior = root / "before.md"
            prior.write_text("- [High] main.c:1：open failure is swallowed\n")
            path = root / "record" / "review.json"
            initialize(path, {
                "source": {"repository": str(repo), "review_kind": "file",
                           "module": "main.c", "identity": "worktree"},
                "files": [{"path": "main.c", "status": "in_scope"}],
                "prior_reports": [str(prior)],
            })
            _, record, issues = load_record(path)
            self.assertEqual(record["prior_findings"][0]["status"], "pending")
            self.assertIn("P001", validate(record, issues)["remaining_prior_findings"])
            with self.assertRaisesRegex(RecordError, "immutable"):
                apply_update(record, issues, {"prior_findings": [{"id": "P001", "summary": "gone"}]})
            with self.assertRaisesRegex(RecordError, "Unreconciled prior"):
                validate(record, issues, "integration")
            record["prior_findings"][0].update(
                status="retained", reason="Still present", evidence=["main.c:1"],
                issue_ids=["R001"])
            finding = issue()
            finding["severity"] = "Low"
            with self.assertRaisesRegex(RecordError, "severity change"):
                validate(record, {"R001": finding})
            record["prior_findings"][0]["severity_change_reason"] = "Only a style contract applies"
            validate(record, {"R001": finding})
            reopened, latest, _ = apply_update(record, {"R001": finding}, {
                "invalidate": ["R001"], "reason": "Caller contract changed"})
            self.assertEqual(reopened["prior_findings"][0]["status"], "pending")
            self.assertEqual(latest["R001"]["status"], "pending")
            verify_sources(record)
            Path(record["prior_findings"][0]["snapshot"]).write_text("changed")
            with self.assertRaisesRegex(ValueError, "snapshot changed"):
                verify_sources(record)

    def test_unreadable_target_does_not_prevent_saving_other_review_progress(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repo = root / "repo"
            repo.mkdir()
            (repo / "main.c").write_text("int run(void) { return 0; }\n")
            path = root / "record" / "review.json"
            initialize(path, {
                "source": {"repository": str(repo), "module": ".", "identity": "worktree"},
                "files": [{"path": name, "status": "in_scope"}
                          for name in ("main.c", "missing.c")],
            })
            _, record, issues = load_record(path)
            updated, _, _ = apply_update(record, issues, {
                "progress": {"next_step": "Continue reviewing readable main.c"}})
            self.assertEqual(updated["file_checks"]["missing.c"]["functional_paths"]["status"],
                             "blocked")
            self.assertIsNone(updated["file_checks"]["missing.c"]["identity"])


if __name__ == "__main__":
    unittest.main()
