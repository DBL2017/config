"""Output budgets and pagination tests; never execute reviewed source."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from generate_review_report import render
from search_review_source import search
from test_review_record import issue, record_for, state_record
from validate_review_record import RecordError, validate


class GateOutputTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.path = Path(self.temporary.name) / "review.json"
        self.path.with_name("issues.jsonl").touch()
        self.script = Path(__file__).with_name("validate_review_record.py")

    def save(self, record, issues=None):
        self.path.write_text(json.dumps(record), encoding="utf-8")
        self.path.with_name("issues.jsonl").write_text(
            "".join(json.dumps(value) + "\n" for value in (issues or {}).values()),
            encoding="utf-8")

    def run_gate(self, *args):
        return subprocess.run([sys.executable, str(self.script), str(self.path), *args],
                              capture_output=True, text=True)

    def test_success_default_is_small_but_library_and_details_are_complete(self):
        record = record_for(1000, 0)
        self.save(record)
        result = self.run_gate()
        self.assertEqual(result.returncode, 0, result.stderr)
        summary = json.loads(result.stdout)
        self.assertEqual(summary["pending_files"], 1000)
        self.assertEqual(summary["next_file"], "src/file0.c")
        self.assertNotIn("remaining_files", summary)
        self.assertLess(len(result.stdout), 1000)
        self.assertEqual(len(validate(record, {})["remaining_files"]), 1000)
        details = self.run_gate("--details")
        self.assertEqual(len(json.loads(details.stdout)["remaining_files"]), 1000)

    def test_failure_pages_retain_total_and_nonzero_status(self):
        self.save(record_for(1000, 0))
        result = self.run_gate("--gate", "initial")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertLess(len(result.stderr), 1500)
        gap = json.loads(result.stderr)["gap"]
        self.assertEqual(gap, {"kind": "file", "total": 1000, "offset": 0,
                               "items": [f"src/file{i}.c" for i in range(5)],
                               "next_offset": 5})
        page = self.run_gate("--gate", "initial", "--offset", "995", "--limit", "5")
        last = json.loads(page.stderr)["gap"]
        self.assertEqual(last["items"], [f"src/file{i}.c" for i in range(995, 1000)])
        self.assertIsNone(last["next_offset"])
        full = self.run_gate("--gate", "initial", "--details")
        self.assertEqual(len(json.loads(full.stderr)["gap"]["items"]), 1000)

    def test_trace_issue_and_state_gaps_identify_query_kind(self):
        record = record_for()
        record["traces"] = [{"id": f"T{i:03}", "status": "pending", "issue_ids": []}
                            for i in range(200)]
        self.save(record)
        result = self.run_gate("--gate", "integration", "--offset", "10")
        gap = json.loads(result.stderr)["gap"]
        self.assertEqual(gap["kind"], "trace")
        self.assertEqual(gap["items"][0], "T010")
        self.assertEqual(gap["total"], 200)
        suspects = {f"R{i:03}": {**issue("pending"), "id": f"R{i:03}"} for i in range(200)}
        self.save(record_for(), suspects)
        result = self.run_gate("--gate", "integration")
        self.assertEqual(json.loads(result.stderr)["gap"]["kind"], "issue")
        record, group = state_record()
        group.update(status="pending", next_check="Inspect refresh dispatch")
        record["traces"][0]["status"] = "pending"
        self.save(record)
        result = self.run_gate("--gate", "integration")
        self.assertEqual(json.loads(result.stderr)["gap"]["kind"], "state")

    def test_structural_errors_and_invalid_pagination_are_not_success(self):
        record = record_for()
        record["file_checks"]["src/file0.c"]["functional_paths"]["evidence"] = []
        self.save(record)
        result = self.run_gate("--gate", "initial")
        self.assertEqual(result.returncode, 1)
        diagnostic = json.loads(result.stderr)
        self.assertIn("functional_paths", diagnostic["error"])
        self.assertNotIn("gap", diagnostic)
        result = self.run_gate("--limit", "0")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Invalid diagnostic pagination", result.stderr)

    def test_final_report_has_no_preview_or_finding_quota(self):
        issues = {f"R{i:03}": {**issue(), "id": f"R{i:03}", "summary": f"Confirmed {i}"}
                  for i in range(150)}
        record = record_for()
        report = render(record, issues)
        self.assertEqual(report.count("- [High]"), 150)
        self.assertEqual(len(record["report_map"]), 150)
        self.assertIn("Confirmed 149", report)
        validate(record, issues, "final")


@unittest.skipUnless(shutil.which("rg"), "Source preview tests require installed ripgrep")
class SearchOutputTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.module = self.root / "module"
        self.module.mkdir()
        self.script = Path(__file__).with_name("search_review_source.py")

    def run_search(self, pattern="target", **kwargs):
        return search(self.root, pattern, ["module"], ["*.c"], **kwargs)

    def test_pages_count_all_lines_without_dumping_long_source(self):
        text = "".join("x" * 1000 + "target" + "y" * 1000 + "\n" for _ in range(200))
        (self.module / "main.c").write_text(text)
        result = self.run_search()
        self.assertEqual(result["total_matching_lines"], 200)
        self.assertEqual(len(result["hits"]), 10)
        self.assertEqual(result["next_offset"], 10)
        self.assertLess(len(json.dumps(result)), 16000)
        hit = result["hits"][0]
        self.assertIn("target", hit["preview"])
        self.assertTrue(hit["truncated"])
        self.assertGreater(hit["preview_start"], 1)
        self.assertLessEqual(len(hit["preview"]), 160)
        for item in result["hits"]:
            self.assertLessEqual(len(item["before"]), 1)
            self.assertLessEqual(len(item["after"]), 1)
        seen = []
        offset = 0
        while offset is not None:
            page = self.run_search(offset=offset, limit=50, context=0)
            seen.extend((hit["path"], hit["line"]) for hit in page["hits"])
            offset = page["next_offset"]
        self.assertEqual(len(seen), 200)
        self.assertEqual(len(set(seen)), 200)

    def test_context_and_line_positions_match_original_source(self):
        (self.module / "main.c").write_text("before\ntarget\nafter\nno\n")
        hit = self.run_search()["hits"][0]
        self.assertEqual(hit["line"], 2)
        self.assertEqual(hit["path"], "module/main.c")
        self.assertFalse(hit["truncated"])
        self.assertEqual(hit["before"][0]["preview"], "before")
        self.assertEqual(hit["before"][0]["line"], 1)
        self.assertEqual(hit["after"][0]["preview"], "after")
        self.assertEqual(hit["after"][0]["line"], 3)

    def test_unicode_and_invalid_encoding_are_explicit(self):
        (self.module / "a.c").write_text("中文" * 200 + "target\n", encoding="utf-8")
        (self.module / "b.c").write_bytes(b"\xfftarget\xfe\n")
        result = self.run_search()
        self.assertEqual(result["total_matching_lines"], 2)
        self.assertIn("target", result["hits"][0]["preview"])
        self.assertFalse(result["hits"][0]["encoding_replaced"])
        self.assertTrue(result["hits"][1]["encoding_replaced"])

    def test_hidden_and_ignored_source_count_but_git_and_other_globs_do_not(self):
        (self.module / ".gitignore").write_text("ignored.c\n")
        for name in (".hidden.c", "ignored.c", "main.c", "other.txt"):
            (self.module / name).write_text("target\n")
        (self.module / ".git").mkdir()
        (self.module / ".git" / "object.c").write_text("target\n")
        hits = self.run_search()["hits"]
        self.assertEqual([item["path"] for item in hits],
                         ["module/.hidden.c", "module/ignored.c", "module/main.c"])
        all_globs = search(self.root, "target", ["module"], ["*"])
        self.assertNotIn("module/.git/object.c", [hit["path"] for hit in all_globs["hits"]])

    def test_ambient_ripgrep_configuration_cannot_limit_hits(self):
        (self.module / "main.c").write_text("target\n" * 30)
        config = self.root / "rg.conf"
        config.write_text("--max-count=1\n")
        with patch.dict(os.environ, {"RIPGREP_CONFIG_PATH": str(config)}):
            self.assertEqual(self.run_search()["total_matching_lines"], 30)

    def test_no_match_is_empty_but_bad_pattern_is_an_error(self):
        (self.module / "main.c").write_text("no matches\n")
        result = self.run_search()
        self.assertEqual(result["total_matching_lines"], 0)
        self.assertEqual(result["hits"], [])
        self.assertIsNone(result["next_offset"])
        with self.assertRaisesRegex(ValueError, "ripgrep failed"):
            self.run_search("(")
        failed = subprocess.run(
            [sys.executable, str(self.script), str(self.root), "(", "--path", "module",
             "--glob", "*.c"], capture_output=True, text=True)
        self.assertEqual(failed.returncode, 1)
        self.assertEqual(failed.stdout, "")
        self.assertIn("Source search failed", failed.stderr)

    def test_literal_search_and_multiple_globs_and_paths(self):
        (self.module / "main.c").write_text("target( target(\n")
        (self.root / "header.h").write_text("target(\n")
        result = search(self.root, "target(", ["module", "header.h"], ["*.c", "*.h"],
                        literal=True)
        self.assertEqual(result["total_matching_lines"], 2)

    def test_scope_and_output_options_are_validated(self):
        for kwargs in ({"offset": -1}, {"limit": 0}, {"limit": 51},
                       {"context": 4}, {"max_chars": 0}):
            with self.subTest(kwargs=kwargs), self.assertRaises(RecordError):
                self.run_search(**kwargs)
        for paths in (["../"], [str(self.root)], ["absent"], ["module/.git"]):
            with self.subTest(paths=paths), self.assertRaises(RecordError):
                search(self.root, "target", paths, ["*.c"])
        with patch("search_review_source.shutil.which", return_value=None):
            with self.assertRaisesRegex(RecordError, "ripgrep unavailable"):
                self.run_search()

    def test_overlapping_paths_do_not_duplicate_matching_lines(self):
        (self.module / "main.c").write_text("target\n")
        result = search(self.root, "target", ["module/main.c", "module", "module"], ["*.c"])
        self.assertEqual(result["scope"]["paths"], ["module"])
        self.assertEqual(result["total_matching_lines"], 1)

    def test_binary_sources_are_not_silently_counted_as_text_coverage(self):
        (self.module / "binary.c").write_bytes(b"target\x00content\n")
        result = self.run_search()
        self.assertEqual(result["scope"]["binary_files"], "excluded")
        self.assertEqual(result["total_matching_lines"], 0)

    def test_late_binary_detection_does_not_consume_a_result_page(self):
        (self.module / "a.c").write_bytes(b"target\n" + b"x" * 200000 + b"\x00\n")
        (self.module / "z.c").write_text("target\n")
        result = self.run_search(limit=1, context=0)
        self.assertEqual(result["total_matching_lines"], 1)
        self.assertEqual(result["hits"][0]["path"], "module/z.c")
        self.assertIsNone(result["next_offset"])


if __name__ == "__main__":
    unittest.main()
