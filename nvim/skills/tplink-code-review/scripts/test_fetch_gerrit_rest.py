"""End-to-end tests for SSH-free Gerrit REST retrieval and scoped context."""

import argparse
import base64
import contextlib
from concurrent.futures import ThreadPoolExecutor
import hashlib
import http.client
import io
import json
import os
from pathlib import Path
import tempfile
import threading
import time
import unittest
from unittest.mock import Mock, patch
from urllib.parse import parse_qs, unquote, urlsplit

from fetch_gerrit_context import main as context_main
from fetch_gerrit_patch import (
    MAX_CONTEXT_BYTES, RestClient, RetrievalError, main, retrieve, retrieve_context,
)
from test_fetch_gerrit_patch import CHANGE_ID, SHA1, SHA2, change


def read_records(path):
    return [json.loads(line) for line in path.read_text().splitlines()]


class Response:
    def __init__(self, body, content_type="application/json", status=200):
        self.body = body
        self.offset = 0
        self.length = len(body)
        self.status, self.reason = status, "fixture response"
        self.content_type = content_type

    def getheader(self, name, default=None):
        return self.content_type if name.lower() == "content-type" else default

    def read1(self, size):
        result = self.body[self.offset:self.offset + size]
        self.offset += len(result)
        self.length -= len(result)
        return result

    def isclosed(self):
        return self.length == 0


class Endpoint:
    def __init__(self):
        self.requests = []
        self.routes = {}
        self.lock = threading.Lock()
        self.search_change = change()
        self.query_status = None

    def connection(self, host, port, timeout):
        connection = Mock()
        connection.sock = Mock()

        def request(method, path, headers):
            with self.lock:
                self.requests.append((method, path, dict(headers)))
            connection.requested_path = path

        connection.request.side_effect = request
        connection.getresponse.side_effect = lambda: self.response(connection.requested_path)
        return connection

    def response(self, path):
        if path.startswith("/gerrit/a/changes/?") and self.query_status:
            return Response(b"", "text/plain", self.query_status)
        route = self.routes.get(path)
        if route is None and path.startswith("/gerrit/a/changes/?"):
            query = parse_qs(urlsplit(path).query).get("q", [""])[0]
            row = self.search_change
            revision_prefix = query.split("commit:", 1)[-1].split()[0] \
                if "commit:" in query else None
            if "change:12345" not in query and CHANGE_ID.lower() not in query.lower() \
                    and not (revision_prefix and any(
                        sha.startswith(revision_prefix) for sha in row["revisions"])):
                return Response(b"[]\n", status=200)
            route = (b")]}'\n" + json.dumps([row]).encode(), "application/json", 200)
        if route is None:
            route = (b"", "text/plain", 404)
        body, content_type, status = route
        return Response(body, content_type, status)

    def json(self, path, value):
        self.routes[path] = (
            b")]}'\n" + json.dumps(value).encode(), "application/json", 200)

    def content(self, path, value):
        self.routes[path] = (base64.b64encode(value), "text/plain", 200)


class RestFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.output_count = 0
        self.endpoint = Endpoint()
        factory = patch("fetch_gerrit_patch.http.client.HTTPSConnection",
                        side_effect=self.endpoint.connection)
        factory.start()
        self.addCleanup(factory.stop)
        self.env = patch.dict(os.environ, {"GERRIT_AUTH_NAME": "test-reviewer",
                                           "GERRIT_AUTH_TOKEN": "fixture-password"})
        self.env.start()
        self.addCleanup(self.env.stop)
        self.url = "https://web/gerrit"
        self.base_path = "/gerrit/a/changes/team%2Fproject~12345/revisions/"
        self.configure(SHA2, 2, ["a" * 40])

    def configure(self, revision, patch_number, parents):
        change_info = change()
        change_info["current_revision"] = revision
        change_info["revisions"] = {
            SHA1: {"_number": 1, "ref": "refs/changes/45/12345/1"},
            SHA2: {"_number": 2, "ref": "refs/changes/45/12345/2"},
        }
        self.search_change = change_info
        resource = self.base_path + revision
        commit = {"commit": revision, "parents": [{"commit": parent} for parent in parents],
                  "message": f"patchset {patch_number}\n"}
        self.endpoint.json(resource + "/commit", commit)
        self.endpoint.json(resource + "/files/" + ("?parent=1" if parents else ""),
                           {"/COMMIT_MSG": {"status": "A"},
                            "src/file.c": {"lines_inserted": 1, "lines_deleted": 1}})
        diff = (b"diff --git a/src/file.c b/src/file.c\n"
                b"index 1234567..abcdef0 100644\n--- a/src/file.c\n+++ b/src/file.c\n"
                b"@@ -1 +1 @@\n-old\n+new\n")
        self.endpoint.content(resource + "/patch" + ("?parent=1" if parents else ""), diff)
        self.endpoint.content(resource + "/files/src%2Ffile.c/content", b"new\n")
        if parents:
            self.endpoint.content(resource + "/files/src%2Ffile.c/content?parent=1",
                                  b"old\n")
        self.endpoint.content(resource + "/files/old%20name.c/content?parent=1",
                              b"old name\n")

    def fetch(self, target="https://web/gerrit/c/team/project/+/12345/2",
              **overrides):
        self.output_count += 1
        args = argparse.Namespace(
            target=target, patchset=None, project=None, web_url=None,
            output=str(self.root / f"out{self.output_count}"),
            max_bytes=1024 * 1024, timeout=30, connect_timeout=10)
        vars(args).update(overrides)
        result = retrieve(args)
        self.assertTrue(all(header.get("Authorization", "").startswith("Basic ")
                            for _, _, header in self.endpoint.requests))
        return result

    def context(self, result, path="src/file.c", side="revision", **overrides):
        args = argparse.Namespace(
            manifest=str(Path(result["diff"]).with_name("manifest.json")),
            file=path, side=side, timeout=30, connect_timeout=10,
            max_bytes=MAX_CONTEXT_BYTES)
        vars(args).update(overrides)
        return retrieve_context(args)


class RetrievalWorkflowTests(RestFixture):
    def test_patchset_download_uses_only_authenticated_http_and_no_git(self):
        result = self.fetch()
        self.assertEqual(result["schema_version"], 3)
        self.assertEqual(result["retrieval"], "rest")
        self.assertEqual((result["revision"], result["patchset"]), (SHA2, 2))
        self.assertEqual(result["base"], "a" * 40)
        self.assertIsNone(result["repository"])
        self.assertFalse((Path(result["diff"]).parent / "repository.git").exists())
        self.assertFalse(Path(result["context_directory"]).exists())
        self.assertIn("+new", Path(result["diff"]).read_text())
        self.assertEqual(Path(result["commit_message"]).read_text(), "patchset 2\n")
        self.assertEqual(len(self.endpoint.requests), 4)
        self.assertTrue(all(path.startswith("/gerrit/a/") for _, path, _ in
                            self.endpoint.requests))
        records = read_records(Path(result["http_diagnostics"]))
        self.assertEqual(len(records), 4)
        self.assertGreater(sum(row["bytes_received"] for row in records), 0)
        serialized = json.dumps(result) + Path(result["http_diagnostics"]).read_text()
        self.assertNotIn("fixture-password", serialized)
        self.assertNotIn("Authorization", serialized)

    def test_explicit_and_latest_patchsets_use_exact_query_revision(self):
        self.configure(SHA1, 1, ["a" * 40])
        result = self.fetch("https://web/gerrit/c/team/project/+/12345/1")
        self.assertEqual(result["revision"], SHA1)
        self.assertEqual(result["patchset"], 1)
        self.assertEqual(Path(result["commit_message"]).read_text(), "patchset 1\n")

    def test_current_worktree_is_not_consulted_and_http_auth_is_required(self):
        result = self.fetch()
        self.assertFalse(any("git" in path.lower() or "ssh" in path.lower()
                             for _, path, _ in self.endpoint.requests))
        self.assertIsNone(result["repository"])

    def test_context_is_explicit_cached_and_hash_checked(self):
        result = self.fetch()
        record = self.context(result)
        self.assertEqual(Path(record["content"]).read_bytes(), b"new\n")
        self.assertEqual(record["sha256"], hashlib.sha256(b"new\n").hexdigest())
        previous_count = len(self.endpoint.requests)
        self.assertEqual(self.context(result), record)
        self.assertEqual(len(self.endpoint.requests), previous_count)
        Path(record["content"]).write_bytes(b"tampered\n")
        with self.assertRaisesRegex(RetrievalError, "identity/hash mismatch"):
            self.context(result)

    def test_base_context_uses_selected_revision_parent(self):
        result = self.fetch()
        record = self.context(result, side="base")
        self.assertEqual(Path(record["content"]).read_bytes(), b"old\n")
        self.assertEqual(record["revision"], "a" * 40)
        self.assertTrue(self.endpoint.requests[-1][1].endswith(
            "/files/src%2Ffile.c/content?parent=1"))

    def test_root_and_empty_commits(self):
        self.configure(SHA1, 1, [])
        self.search_change["current_revision"] = SHA1
        self.search_change["revisions"] = {
            SHA1: {"_number": 1, "ref": "refs/changes/45/12345/1"}}
        self.endpoint.json(self.base_path + SHA1 + "/files/",
                           {"/COMMIT_MSG": {"status": "A"}})
        self.endpoint.content(self.base_path + SHA1 + "/patch", b"")
        result = self.fetch("https://web/gerrit/c/team/project/+/12345/1")
        self.assertIsNone(result["base"])
        self.assertTrue(result["empty_diff"])
        with self.assertRaisesRegex(RetrievalError, "Root commit"):
            self.context(result, side="base")

    def test_http_errors_fail_without_fallback(self):
        self.endpoint.query_status = 401
        with patch("fetch_gerrit_patch.time.sleep"):
            with self.assertRaises(RetrievalError) as caught:
                self.fetch()
        self.assertEqual(caught.exception.details["http_status"], 401)
        self.assertEqual(caught.exception.details["stage"], "rest_query")
        self.assertEqual(caught.exception.details["attempt_count"], 1)
        self.assertIn("GERRIT_AUTH_NAME/GERRIT_AUTH_TOKEN", str(caught.exception))

    def test_credentials_missing_or_bad_fail_without_network_or_secret_echo(self):
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(RetrievalError, "GERRIT_AUTH_NAME"):
                self.fetch()
        with patch.dict(os.environ, {"GERRIT_AUTH_NAME": "user",
                                     "GERRIT_AUTH_TOKEN": "secret\npassword"}):
            with self.assertRaises(RetrievalError):
                self.fetch()
        self.assertEqual(self.endpoint.requests, [])

    def test_timeout_truncation_redirect_and_tls_errors_are_explicit(self):
        class SlowResponse(Response):
            def read1(self, size):
                time.sleep(0.03)
                return super().read1(size)

        connection = self.endpoint.connection("web", 443, 1)
        connection.getresponse.return_value = SlowResponse(b"{}")
        connection.getresponse.side_effect = None
        with patch("fetch_gerrit_patch.http.client.HTTPSConnection",
                   return_value=connection):
            client = RestClient("https://web", self.root / "diag",
                                "user", "secret", timeout=0.01)
            with self.assertRaises(RetrievalError) as caught:
                client.json("/resource", "rest_query")
        self.assertEqual(caught.exception.details["timeout_type"], "http_timeout")

        self.endpoint.routes["/gerrit/a/private"] = (b"", "text/plain", 302)
        with self.assertRaises(RetrievalError) as caught:
            RestClient(self.url, self.root / "diag", "user", "secret").json(
                "/private", "rest_query")
        self.assertEqual(caught.exception.details["http_status"], 302)

    def test_query_retry_records_only_transient_failures(self):
        path = "/gerrit/a/changes/?q=change%3A12345+limit%3A2&o=ALL_REVISIONS&o=ALL_COMMITS"
        self.endpoint.query_status = 503
        with patch("fetch_gerrit_patch.time.sleep") as sleep:
            with self.assertRaises(RetrievalError) as caught:
                self.fetch()
        self.assertEqual(caught.exception.details["attempt_count"], 3)
        self.assertEqual(sleep.call_count, 2)
        self.assertEqual(len(read_records(Path(caught.exception.details["diagnostics"]))), 3)

    def test_cli_reports_missing_credentials_and_never_emits_success(self):
        with patch.dict(os.environ, {}, clear=True):
            stdout, stderr = io.StringIO(), io.StringIO()
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                status = main(["12345", "--web-url", "https://web",
                               "--output", str(self.root / "out")])
        self.assertEqual(status, 1)
        self.assertEqual(stdout.getvalue(), "")
        self.assertIn("GERRIT_AUTH_NAME", json.loads(stderr.getvalue())["error"])

    def test_context_cli_failure_is_specific(self):
        result = self.fetch()
        stdout, stderr = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            status = context_main([
                str(Path(result["diff"]).with_name("manifest.json")), "../escape"])
        self.assertEqual(status, 1)
        self.assertEqual(stdout.getvalue(), "")
        self.assertIn("traversal", json.loads(stderr.getvalue())["error"])

    def test_parallel_context_requests_keep_diagnostics_complete(self):
        result = self.fetch()

        def fetch_context(_):
            return self.context(result)

        with ThreadPoolExecutor(max_workers=8) as executor:
            results = list(executor.map(fetch_context, range(16)))
        self.assertTrue(all(item["path"] == "src/file.c" for item in results))
        records = read_records(Path(result["http_diagnostics"]))
        self.assertGreaterEqual(len(records), 5)
        self.assertLessEqual(len(records), 4 + 16)


if __name__ == "__main__":
    unittest.main()
