"""Tests for REST Gerrit target selection, authentication and metadata validation."""

import base64
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

from fetch_gerrit_patch import (
    RetrievalError, RestClient, credentials, parse_selection, project_name,
    query_change_id, select_patchset,
)


SHA1 = "a" * 40
SHA2 = "b" * 40
CHANGE_ID = "I" + "c" * 40


def change():
    return {
        "_number": 12345,
        "project": "team/project",
        "change_id": CHANGE_ID,
        "current_revision": SHA2,
        "revisions": {
            SHA1: {"_number": 1, "ref": "refs/changes/45/12345/1"},
            SHA2: {"_number": 2, "ref": "refs/changes/45/12345/2"},
        },
    }


class SelectionTests(unittest.TestCase):
    def test_numeric_change_and_patchset(self):
        self.assertEqual(parse_selection("12345/3").patchset, 3)
        self.assertEqual(parse_selection("12345").value, "12345")
        with self.assertRaisesRegex(RetrievalError, "Conflicting"):
            parse_selection("12345/3", 2)

    def test_change_id_and_commit_hash(self):
        self.assertEqual(parse_selection(CHANGE_ID).kind, "change")
        self.assertEqual(parse_selection("abcdef012").kind, "commit")
        for value in ("not-a-target", "I123", "******web"):
            with self.assertRaises(RetrievalError):
                parse_selection(value)

    def test_change_urls_and_web_path_prefix(self):
        for value, expected in (
                ("https://web/c/team/project/+/12345/3",
                 ("team/project", "https://web")),
                ("https://web:8443/gerrit/c/team%2Fproject/+/12345/3",
                 ("team/project", "https://web:8443/gerrit")),
                ("https://web/gerrit/c/12345/3", (None, "https://web/gerrit"))):
            selection = parse_selection(value)
            self.assertEqual((selection.project, selection.web_url), expected)
            self.assertEqual(selection.patchset, 3)

    def test_http_and_malformed_urls_are_rejected(self):
        for value in ("http://web/c/12345", "https://user@web/c/12345",
                      "https://web/other", "https://web/c/p/+/12345/3/file.c"):
            with self.subTest(value=value), self.assertRaises(RetrievalError):
                parse_selection(value)

    def test_project_and_credentials_validate_without_echoing_secret(self):
        for value in ("", "../escape", "team//project", "team\nproject"):
            with self.subTest(value=value), self.assertRaises(RetrievalError):
                project_name(value)
        with patch.dict(os.environ, {"GERRIT_AUTH_NAME": "reviewer",
                                     "GERRIT_AUTH_TOKEN": "never-log-this"}):
            self.assertEqual(credentials(), ("reviewer", "never-log-this"))
        with patch.dict(os.environ, {"GERRIT_AUTH_NAME": "reviewer"}, clear=True):
            with self.assertRaisesRegex(RetrievalError, "GERRIT_AUTH_TOKEN"):
                credentials()
        with patch.dict(os.environ, {"GERRIT_AUTH_NAME": "reviewer",
                                     "GERRIT_AUTH_PASSWD": "legacy-value"},
                        clear=True):
            with self.assertRaisesRegex(RetrievalError, "GERRIT_AUTH_TOKEN"):
                credentials()
        with patch.dict(os.environ, {"GERRIT_AUTH_NAME": "bad:name",
                                     "GERRIT_AUTH_TOKEN": "secret"}):
            with self.assertRaises(RetrievalError):
                credentials()


class FakeClient:
    def __init__(self, response):
        self.response = response
        self.calls = []
        self.url = "https://web/gerrit"

    def json(self, resource, stage):
        self.calls.append((resource, stage))
        return self.response


class RestQueryTests(unittest.TestCase):
    def test_basic_auth_header_is_not_a_url_or_persisted_field(self):
        with tempfile.TemporaryDirectory() as temp:
            with patch.dict(os.environ, {"GERRIT_AUTH_NAME": "reviewer",
                                         "GERRIT_AUTH_TOKEN": "secret-pass"}):
                client = RestClient("https://web/gerrit", Path(temp), *credentials())
            self.assertEqual(base64.b64decode(client.authorization[6:]),
                             b"reviewer:secret-pass")
            self.assertNotIn("secret-pass", client.url)
            self.assertNotIn("secret-pass", repr(client.__dict__))

    def test_change_query_uses_authenticated_rest_change_search(self):
        response = [change()]
        client = FakeClient(response)
        with tempfile.TemporaryDirectory() as temp:
            result, number, project = query_change_id(
                client, parse_selection("12345"), "team/project", Path(temp))
        self.assertEqual((number, project), (12345, "team/project"))
        self.assertEqual(result, response[0])
        resource, stage = client.calls[0]
        self.assertTrue(resource.startswith("/changes/?"))
        self.assertIn("ALL_REVISIONS", resource)
        self.assertIn("ALL_COMMITS", resource)
        self.assertIn("rest_query", stage)
        self.assertNotIn("ssh", resource.lower())

    def test_change_id_commit_prefix_and_project_scope(self):
        for target in ("12345", CHANGE_ID, SHA1[:12]):
            client = FakeClient([change()])
            with tempfile.TemporaryDirectory() as temp:
                result, _, _ = query_change_id(
                    client, parse_selection(target), "team/project", Path(temp))
            self.assertEqual(result["_number"], 12345)
            resource = client.calls[0][0]
            self.assertIn("project", resource)
        client = FakeClient([change()])
        with tempfile.TemporaryDirectory() as temp:
            query_change_id(client, parse_selection(SHA1), None, Path(temp))
        self.assertIn("commit%3A", client.calls[0][0])

    def test_ambiguous_malformed_or_wrong_project_results_fail(self):
        cases = [
            ([], "received 0"),
            ([change(), change()], "received 2"),
            ([dict(change(), project="other")], "project mismatch"),
            ([dict(change(), _number=99999)], "change number mismatch"),
            ([dict(change(), change_id="invalid")], "Change-Id"),
        ]
        for rows, reason in cases:
            client = FakeClient(rows)
            with tempfile.TemporaryDirectory() as temp:
                with self.subTest(reason=reason), self.assertRaisesRegex(
                        RetrievalError, reason):
                    query_change_id(client, parse_selection("12345"),
                                    "team/project", Path(temp))

    def test_selects_exact_historical_patchset_and_sha(self):
        value = change()
        for target in ("12345/1", SHA1[:12]):
            revision, patchset = select_patchset(value, parse_selection(target))
            self.assertEqual((revision, patchset["_number"]), (SHA1, 1))
        revision, patchset = select_patchset(
            value, parse_selection(CHANGE_ID, patchset=2))
        self.assertEqual((revision, patchset["_number"]), (SHA2, 2))
        revision, patchset = select_patchset(value, parse_selection("12345"))
        self.assertEqual((revision, patchset["_number"]), (SHA2, 2))

    def test_bad_refs_missing_historical_revision_and_ambiguous_sha_fail(self):
        value = change()
        value["revisions"][SHA1]["ref"] = "refs/heads/main"
        with self.assertRaisesRegex(RetrievalError, "ref mismatch"):
            select_patchset(value, parse_selection("12345/1"))
        with self.assertRaisesRegex(RetrievalError, "not found"):
            select_patchset(change(), parse_selection("12345/3"))
        ambiguous = change()
        ambiguous["revisions"]["a" * 7 + "d" * 33] = {
            "_number": 3, "ref": "refs/changes/45/12345/3"
        }
        with self.assertRaisesRegex(RetrievalError, "multiple"):
            select_patchset(ambiguous, parse_selection("a" * 7))


if __name__ == "__main__":
    unittest.main()
