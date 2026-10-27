#!/usr/bin/env python3
"""Retrieve an exact Gerrit diff and fetch source files only when requested."""

import argparse
import base64
import binascii
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import http.client
import json
import math
import os
from pathlib import Path
import re
import ssl
import sys
import tempfile
import time
from urllib.parse import quote, unquote, urlencode, urlsplit


QUERY_ATTEMPTS = 3
QUERY_RETRY_DELAY = 5
ERROR_CHARS = 600
MAX_DIFF_BYTES = 32 * 1024 * 1024
MAX_CONTEXT_BYTES = 16 * 1024 * 1024


class RetrievalError(Exception):
    """The selected source could not be retrieved or verified."""

    def __init__(self, message, **details):
        super().__init__(message)
        self.details = details


def redact_error(value):
    value = re.sub(r"-----BEGIN [^-]*PRIVATE KEY-----.*?"
                   r"-----END [^-]*PRIVATE KEY-----", "[redacted private key]",
                   value, flags=re.DOTALL)
    value = re.sub(r"(?im)\b(authorization|proxy-authorization|cookie|set-cookie)"
                   r"\s*:[^\r\n]*", r"\1: [redacted]", value)
    value = re.sub(r"(?i)(https?://)[^\s/@]+@", r"\1[redacted]@", value)
    value = re.sub(r"""(?i)\b(password|passwd|token|access_token|api[_-]?key|secret)
                     (\s*[:=]\s*)("[^"]*"|'[^']*'|[^\s,;]+)""",
                  r"\1\2[redacted]", value, flags=re.VERBOSE)
    for secret in (os.environ.get("GERRIT_AUTH_NAME"),
                   os.environ.get("GERRIT_AUTH_TOKEN")):
        if secret:
            value = value.replace(secret, "[redacted]")
    return value


def bounded_text(value, limit=ERROR_CHARS):
    return value if len(value) <= limit else value[:limit - 14] + "...[truncated]"


def sanitize_diagnostic(value):
    if isinstance(value, str):
        return bounded_text(redact_error(value))
    if isinstance(value, dict):
        return {key: sanitize_diagnostic(item) for key, item in value.items()}
    if isinstance(value, list):
        return [sanitize_diagnostic(item) for item in value]
    return value


@contextmanager
def error_context(stage, endpoint=None):
    try:
        yield
    except (RetrievalError, OSError, ValueError, UnicodeError) as error:
        if not isinstance(error, RetrievalError):
            details = {}
            if isinstance(error, (TimeoutError, ssl.SSLError)):
                details = {"timeout_type": "http_timeout"} if isinstance(
                    error, TimeoutError) else {}
            error = RetrievalError(str(error), **details)
        error.details.setdefault("stage", stage)
        if endpoint:
            error.details.setdefault("endpoint", endpoint)
        raise error from None


def require(condition, message):
    if not condition:
        raise RetrievalError(message)


def positive_int(value):
    try:
        number = int(value)
    except (TypeError, ValueError):
        raise RetrievalError(f"Expected a positive integer: {value!r}") from None
    require(number > 0, f"Expected a positive integer: {value!r}")
    return number


def project_name(value):
    require(isinstance(value, str) and value, "Missing Gerrit project")
    require(not any(ord(char) < 32 or ord(char) == 127 for char in value),
            "Control character in project name")
    require(all(part not in ("", ".", "..") for part in value.split("/")),
            "Invalid Gerrit project path")
    return value


def credentials():
    username = os.environ.get("GERRIT_AUTH_NAME")
    token = os.environ.get("GERRIT_AUTH_TOKEN")
    require(username and token,
            "Set GERRIT_AUTH_NAME and GERRIT_AUTH_TOKEN for Gerrit HTTP authentication")
    require(":" not in username and not any(
        char in username + token for char in "\r\n\0"),
        "Gerrit HTTP username/token contains an invalid control character")
    return username, token


@dataclass(frozen=True)
class Selection:
    kind: str
    value: str
    patchset: int = None
    project: str = None
    web_url: str = None


def web_url(value):
    require(isinstance(value, str) and value, "Missing Gerrit Web URL")
    parsed = urlsplit(value)
    require(parsed.scheme == "https" and parsed.hostname
            and not parsed.username and not parsed.password
            and not parsed.query and not parsed.fragment,
            "Gerrit REST requires an HTTPS Web URL without credentials, query or fragment")
    require(not any(ord(char) < 33 or ord(char) == 127 for char in value),
            "Invalid control character or whitespace in Web URL")
    require(all(part not in (".", "..") for part in parsed.path.split("/")),
            "Invalid Web URL path")
    require(not parsed.path.rstrip("/").endswith("/a"),
            "Gerrit Web URL must not include the /a authentication prefix")
    require(parsed.port is None or parsed.port > 0, "Invalid HTTPS port")
    return value.rstrip("/")


def parse_selection(value, patchset=None):
    project = site = None
    if value.startswith(("http://", "https://")):
        parsed = urlsplit(value)
        require(parsed.hostname and not parsed.username and not parsed.password,
                "Invalid Gerrit Web URL")
        require(parsed.scheme == "https", "Gerrit REST requires HTTPS")
        path = parsed.path
        modern = re.search(
            r"/c/(.+?)/\+/([1-9]\d*)(?:/([1-9]\d*))?/?$", path)
        legacy = re.search(r"/(?:c/)?([1-9]\d*)(?:/([1-9]\d*))?/?$", path)
        require(modern or legacy,
                "Unsupported Gerrit URL; use a change/patchset page URL")
        prefix = path[:modern.start()] if modern else path[:legacy.start()]
        site = f"https://{parsed.netloc}{prefix}".rstrip("/")
        if modern:
            project = project_name(unquote(modern[1]))
            value = modern[2] + (f"/{modern[3]}" if modern[3] else "")
        else:
            value = legacy[1] + (f"/{legacy[2]}" if legacy[2] else "")
    numeric = re.fullmatch(r"([1-9]\d*)(?:/([1-9]\d*))?", value)
    if numeric:
        kind, identifier = "change", numeric[1]
        embedded = int(numeric[2]) if numeric[2] else None
        require(not (embedded and patchset and embedded != patchset),
                "Conflicting patchset selections")
        patchset = embedded or patchset
    elif re.fullmatch(r"I[0-9a-fA-F]{8,40}", value):
        kind, identifier = "change", value
    elif re.fullmatch(r"[0-9a-fA-F]{7,40}", value):
        kind, identifier = "commit", value.lower()
    else:
        raise RetrievalError("Expected a change number, Change-Id, SHA or Gerrit URL")
    return Selection(kind, identifier, patchset, project, site)


def decode_base64(body, limit):
    try:
        decoded = base64.b64decode(b"".join(body.split()), validate=True)
    except binascii.Error:
        raise RetrievalError("Gerrit response is not valid Base64 content") from None
    require(len(decoded) <= limit, f"Decoded content exceeds {limit} bytes")
    return decoded


class RestClient:
    def __init__(self, url, directory, username, token, timeout=30,
                 connect_timeout=10):
        self.url = web_url(url)
        self.directory = Path(directory)
        self.timeout, self.connect_timeout = timeout, connect_timeout
        self.authorization = "Basic " + base64.b64encode(
            f"{username}:{token}".encode("utf-8")).decode("ascii")

    @contextmanager
    def operation(self, stage, endpoint):
        try:
            with error_context(stage, endpoint):
                yield
        except RetrievalError as error:
            path = self.directory / "http-requests.jsonl"
            if path.is_file():
                error.details.setdefault("diagnostics", str(path))
            raise

    def get(self, resource, stage, limit, content_type="application/json"):
        url = self.url + "/a" + resource
        parsed = urlsplit(url)
        started = time.monotonic()
        record = {"endpoint": url, "stage": stage,
                  "started_at": datetime.now(timezone.utc).isoformat(),
                  "timeout_seconds": self.timeout, "bytes_received": 0}
        connection = http.client.HTTPSConnection(
            parsed.hostname, parsed.port, timeout=min(self.connect_timeout, self.timeout))
        try:
            with self.operation(stage, url):
                try:
                    connection.connect()
                    sock = connection.sock
                    if sock is None:
                        raise OSError("HTTPS socket is unavailable after connect")

                    def remaining():
                        budget = self.timeout - (time.monotonic() - started)
                        if budget <= 0:
                            raise TimeoutError("HTTP request total timeout exceeded")
                        sock.settimeout(budget)

                    remaining()
                    connection.request(
                        "GET", parsed.path + ("?" + parsed.query if parsed.query else ""),
                        headers={"Accept": content_type,
                                 "Authorization": self.authorization})
                    remaining()
                    response = connection.getresponse()
                    record["http_status"] = response.status
                    if response.status != 200:
                        if response.status == 401:
                            reason = "check GERRIT_AUTH_NAME/GERRIT_AUTH_TOKEN and Gerrit HTTP access"
                        elif response.status == 403:
                            reason = "authenticated account is not permitted to access this resource"
                        elif response.status == 404:
                            reason = "resource/change may not exist or is not visible to this account"
                        elif 300 <= response.status < 400:
                            reason = "redirects/login pages are not followed"
                        else:
                            reason = "request was rejected by Gerrit"
                        raise RetrievalError(
                            f"Gerrit REST returned HTTP {response.status}: "
                            f"{response.reason}; {reason}",
                            http_status=response.status,
                            retryable=response.status == 429 or response.status >= 500)
                    actual_type = response.getheader(
                        "Content-Type", "").split(";")[0].strip().lower()
                    require(actual_type == content_type,
                            f"Expected {content_type}, received {actual_type!r}; "
                            "HTML/login pages are not review input")
                    body = bytearray()
                    while True:
                        remaining()
                        chunk = response.read1(min(65536, limit + 1 - len(body)))
                        record["bytes_received"] += len(chunk)
                        if not chunk:
                            break
                        body.extend(chunk)
                        require(len(body) <= limit, f"HTTP response exceeds {limit} bytes")
                        if response.isclosed():
                            break
                    if response.length is not None:
                        require(response.length == 0, "Incomplete HTTP response body")
                    remaining()
                    record["status"] = "succeeded"
                    return bytes(body)
                except (OSError, http.client.HTTPException) as error:
                    details = {"timeout_type": "http_timeout",
                               "timeout_seconds": self.timeout} if isinstance(
                                   error, TimeoutError) else {}
                    raise RetrievalError(f"Gerrit REST request failed: {error}",
                                         retryable=True, **details) from None
        except RetrievalError as error:
            record.update(status="failed", error=bounded_text(redact_error(str(error))))
            error.details.setdefault("diagnostics", str(self.directory / "http-requests.jsonl"))
            error.details.setdefault("elapsed_seconds", round(time.monotonic() - started, 3))
            error.details.setdefault("bytes_received", record["bytes_received"])
            raise
        finally:
            connection.close()
            record["elapsed_seconds"] = round(time.monotonic() - started, 3)
            with error_context("diagnostic_write", str(self.directory)):
                self.directory.mkdir(mode=0o700, exist_ok=True)
                path = self.directory / "http-requests.jsonl"
                require(not self.directory.is_symlink() and not path.is_symlink(),
                        "HTTP diagnostics must not be symlinks")
                body = (json.dumps(sanitize_diagnostic(record), ensure_ascii=True) + "\n").encode()
                descriptor = os.open(path, os.O_APPEND | os.O_CREAT | os.O_WRONLY
                                     | getattr(os, "O_NOFOLLOW", 0), 0o600)
                try:
                    require(os.write(descriptor, body) == len(body),
                            "Incomplete HTTP diagnostic write")
                finally:
                    os.close(descriptor)

    def json(self, resource, stage):
        with self.operation(stage, self.url + "/a" + resource):
            body = self.get(resource, stage, MAX_CONTEXT_BYTES)
            if body.startswith(b")]}'\n"):
                body = body[5:]
            return json.loads(body.decode("utf-8"))

    def content(self, resource, stage, limit):
        with self.operation(stage, self.url + "/a" + resource):
            body = self.get(resource, stage, ((limit + 2) // 3) * 4 + 65536,
                            content_type="text/plain")
            return decode_base64(body, limit)


def query_change_id(client, selection, project, diagnostics):
    if selection.kind == "commit":
        expression = "commit:" + selection.value
    else:
        expression = "change:" + selection.value
    if project:
        expression += " project:" + json.dumps(project, ensure_ascii=False)
    expression += " limit:2"
    query = urlencode([("q", expression), ("o", "ALL_REVISIONS"),
                       ("o", "ALL_COMMITS")])
    resource = "/changes/?" + query
    started = time.monotonic()
    attempts = []
    for attempt in range(1, QUERY_ATTEMPTS + 1):
        try:
            result = client.json(resource, "rest_query")
            require(isinstance(result, list), "Gerrit query response is not a list")
            rows = [item for item in result if isinstance(item, dict)]
            require(len(rows) == 1,
                    f"Expected one Gerrit change for {selection.kind}:{selection.value}, "
                    f"received {len(rows)}")
            change = rows[0]
            number = positive_int(change.get("_number"))
            actual_project = project_name(change.get("project"))
            change_id = change.get("change_id")
            require(isinstance(change_id, str) and re.fullmatch(
                r"I[0-9a-fA-F]{8,40}", change_id), "Invalid Gerrit Change-Id")
            require(not project or actual_project == project,
                    f"Gerrit project mismatch: expected {project!r}, received {actual_project!r}")
            if selection.kind == "change" and selection.value.startswith("I"):
                require(change_id.lower() == selection.value.lower(),
                        "Gerrit Change-Id mismatch")
            if selection.kind == "change" and selection.value.isdigit():
                require(number == int(selection.value),
                        f"Gerrit change number mismatch: expected {selection.value}, received {number}")
            return change, number, actual_project
        except (RetrievalError, ValueError, UnicodeError) as error:
            failure = error if isinstance(error, RetrievalError) else RetrievalError(str(error))
            attempts.append({"attempt": attempt, "status": "failed",
                             "elapsed_seconds": round(time.monotonic() - started, 3),
                             "error": bounded_text(redact_error(str(failure)))})
            retryable = failure.details.get("retryable", False)
            if attempt < QUERY_ATTEMPTS and retryable:
                time.sleep(QUERY_RETRY_DELAY)
                continue
            failure.details.update({
                "stage": "rest_query", "attempt_count": attempt,
                "attempts": attempts,
                "elapsed_seconds": round(time.monotonic() - started, 3),
                "diagnostics": str(diagnostics / "http-requests.jsonl"),
            })
            raise failure
    raise RetrievalError("Gerrit REST query exhausted all attempts", stage="rest_query")


def valid_sha(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{40}", value) is not None


def rest_files(value):
    require(isinstance(value, dict), "Invalid REST file list")
    files = []
    for path, info in value.items():
        if path in ("/COMMIT_MSG", "/MERGE_LIST"):
            continue
        require(isinstance(path, str) and path and isinstance(info, dict),
                "Invalid REST file entry")
        status = info.get("status", "M")
        require(status in ("A", "D", "R", "C", "M", "W"), "Unknown REST file status")
        entry = {"path": path, "status": status}
        if status in ("R", "C"):
            require(isinstance(info.get("old_path"), str) and info["old_path"],
                    "Missing old path for renamed/copied file")
            entry["old_path"] = info["old_path"]
        if info.get("binary"):
            entry["binary"] = True
        files.append(entry)
    return files


def select_patchset(change, selection):
    revisions = change.get("revisions")
    require(isinstance(revisions, dict) and revisions,
            "Gerrit REST response has no patchset revisions; request ALL_REVISIONS")
    candidates = []
    for sha, info in revisions.items():
        if not valid_sha(sha) or not isinstance(info, dict):
            continue
        if selection.patchset and str(info.get("_number")) != str(selection.patchset):
            continue
        if selection.kind == "commit" and not sha.lower().startswith(selection.value):
            continue
        candidates.append((sha.lower(), info))
    if selection.kind == "change" and not selection.patchset:
        current = change.get("current_revision")
        candidates = [(sha, info) for sha, info in candidates if sha == current]
    if not candidates:
        requested = (f"patchset {selection.patchset}" if selection.patchset else
                     f"commit {selection.value}" if selection.kind == "commit" else
                     "current patchset")
        raise RetrievalError(f"Requested {requested} not found in Gerrit change "
                             f"{change.get('_number')}")
    require(len(candidates) == 1,
            "Selected commit matches multiple Gerrit patchsets")
    revision, patchset = candidates[0]
    number = positive_int(change.get("_number"))
    patch_number = positive_int(patchset.get("_number"))
    expected_ref = f"refs/changes/{number % 100:02d}/{number}/{patch_number}"
    require(patchset.get("ref") == expected_ref,
            f"Patchset ref mismatch: expected {expected_ref!r}, "
            f"received {patchset.get('ref')!r}")
    return revision, patchset


def retrieve_rest(client, change, revision, patchset, max_bytes):
    number = positive_int(change["_number"])
    project = project_name(change["project"])
    patch_number = positive_int(patchset["_number"])
    change_id = change["change_id"]
    resource = (f"/changes/{quote(project, safe='')}~{number}"
                f"/revisions/{revision}")
    with client.operation("rest_metadata", client.url + "/a" + resource):
        require(change.get("_number") == number and change.get("project") == project
                and change.get("change_id") == change_id,
                "Gerrit change identity is inconsistent")
        require(revision in change.get("revisions", {}),
                "Selected revision is absent from REST change metadata")
    with client.operation("rest_commit", client.url + "/a" + resource):
        commit = client.json(resource + "/commit", "rest_commit")
        require(isinstance(commit, dict) and commit.get("commit") == revision,
                "REST commit SHA does not match selected revision")
        parent_info = commit.get("parents")
        require(isinstance(parent_info, list)
                and all(isinstance(item, dict) and valid_sha(item.get("commit"))
                        for item in parent_info), "Invalid REST commit parents")
        parents = [item["commit"] for item in parent_info]
        require(isinstance(commit.get("message"), str), "Missing REST commit message")
    comparison = "?parent=1" if parents else ""
    with client.operation("rest_files", client.url + "/a" + resource):
        files = rest_files(client.json(resource + "/files/" + comparison, "rest_files"))
    with client.operation("rest_patch", client.url + "/a" + resource):
        patch = client.content(resource + "/patch" + comparison, "rest_patch", max_bytes)
        require(not patch or patch.startswith((b"From ", b"diff --git ")),
                "REST response is not a formatted revision patch")
        if patch.startswith(b"From "):
            require(patch.split(b" ", 2)[1] == revision.encode("ascii"),
                    "Patch header SHA does not match selected revision")
        start = 0 if patch.startswith(b"diff --git ") else patch.find(b"\ndiff --git ")
        require(bool(files) == (start >= 0),
                "REST patch and changed-file list disagree")
        if not files:
            require(not patch or patch.startswith(b"From " + revision.encode("ascii") + b" "),
                    "Invalid empty revision patch")
        diff = patch[start:].lstrip(b"\n") if files else b""
    return parents, diff, files, commit["message"].encode("utf-8")


def retrieve(args):
    with error_context("input_validation"):
        require(math.isfinite(args.timeout) and args.timeout > 0, "Invalid HTTP timeout")
        require(args.connect_timeout > 0, "HTTP connect timeout must be a positive integer")
        require(args.max_bytes > 0, "Maximum diff size must be positive")
        username, token = credentials()
        selection = parse_selection(args.target, args.patchset)
        require(not (args.project and selection.project
                     and args.project != selection.project),
                "URL and --project disagree")
        project = selection.project or args.project
        if project:
            project_name(project)
        url = web_url(args.web_url or selection.web_url or "")
        output = Path(args.output).resolve()
    with error_context("artifact_init", str(output)):
        output.mkdir(mode=0o700, parents=True, exist_ok=False)
    diagnostics = output / "diagnostics"
    diagnostics.mkdir(mode=0o700, exist_ok=True)
    client = RestClient(url, diagnostics, username, token,
                        args.timeout, args.connect_timeout)
    change, number, project = query_change_id(client, selection, project, diagnostics)
    revision, patchset = select_patchset(change, selection)
    patch_number = positive_int(patchset["_number"])
    parents, diff, files, message = retrieve_rest(
        client, change, revision, patchset, args.max_bytes)
    base = parents[0] if parents else None
    manifest = {
        "schema_version": 3, "retrieval": "rest",
        "project": project, "change": number, "change_id": change["change_id"],
        "patchset": patch_number,
        "selection": "explicit" if selection.patchset or selection.kind == "commit"
        else "current", "revision": revision, "base": base, "parents": parents,
        "repository": None, "diff": str(output / "patch.diff"),
        "commit_message": str(output / "commit.txt"),
        "metadata": str(output / "change.json"), "files": files,
        "empty_diff": not bool(files),
        "rest": {"url": url, "authenticated": True},
        "http_diagnostics": str(diagnostics / "http-requests.jsonl"),
        "context_directory": str(output / "context"),
    }
    with error_context("artifact_write", str(output)):
        (output / "patch.diff").write_bytes(diff)
        (output / "commit.txt").write_bytes(message)
        (output / "change.json").write_text(
            json.dumps(change, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
        (output / "manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    return manifest


def retrieve_context(args):
    with error_context("input_validation"):
        require(math.isfinite(args.timeout) and args.timeout > 0, "Invalid HTTP timeout")
        require(args.connect_timeout > 0 and args.max_bytes > 0,
                "Connect timeout and maximum file size must be positive")
        path = args.file
        require(path and not path.startswith("/") and "\0" not in path
                and all(part not in ("", ".", "..") for part in path.split("/")),
                "Context file must be a relative Gerrit path without traversal")
        manifest_path = Path(args.manifest).resolve(strict=True)
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        require(isinstance(manifest, dict) and manifest.get("schema_version") == 3
                and manifest.get("retrieval") == "rest",
                "Context retrieval requires a completed REST manifest")
        revision, parents = manifest.get("revision"), manifest.get("parents")
        require(valid_sha(revision) and isinstance(parents, list)
                and all(valid_sha(parent) for parent in parents)
                and manifest.get("base") == (parents[0] if parents else None),
                "Invalid revision/parents in manifest")
        require(args.side != "base" or parents, "Root commit has no base-side context")
        project = project_name(manifest.get("project"))
        number = positive_int(manifest.get("change"))
        rest = manifest.get("rest")
        require(isinstance(rest, dict) and rest.get("authenticated") is True,
                "Missing authenticated REST source in manifest")
        url = web_url(rest.get("url", ""))
    selected_sha = revision if args.side == "revision" else parents[0]
    directory = manifest_path.parent / "context"
    identity = hashlib.sha256((selected_sha + "\0" + path).encode("utf-8")).hexdigest()
    content_path, record_path = directory / (identity + ".bin"), directory / (identity + ".json")
    with error_context("context_cache", str(directory)):
        require(not directory.is_symlink(), "Context directory must not be a symlink")
        directory.mkdir(mode=0o700, exist_ok=True)
        require(not content_path.is_symlink() and not record_path.is_symlink(),
                "Context cache must not contain symlinks")
        if content_path.exists() and record_path.exists():
            require(content_path.is_file() and record_path.is_file(), "Invalid context cache")
            record = json.loads(record_path.read_text(encoding="utf-8"))
            require(isinstance(record, dict), "Invalid context cache record")
            require(content_path.stat().st_size <= args.max_bytes,
                    f"Cached context exceeds {args.max_bytes} bytes")
            data = content_path.read_bytes()
            require(record.get("revision") == selected_sha and record.get("path") == path
                    and record.get("web_url") == url and record.get("project") == project
                    and record.get("change") == number
                    and record.get("content") == str(content_path)
                    and record.get("sha256") == hashlib.sha256(data).hexdigest()
                    and record.get("bytes") == len(data), "Context cache identity/hash mismatch")
            return record
    username, token = credentials()
    client = RestClient(url, manifest_path.parent / "diagnostics", username, token,
                        args.timeout, args.connect_timeout)
    resource = (f"/changes/{quote(project, safe='')}~{number}/revisions/{revision}"
                f"/files/{quote(path, safe='')}/content")
    if args.side == "base":
        resource += "?parent=1"
    data = client.content(resource, "context_fetch", args.max_bytes)
    record = {"revision": selected_sha, "path": path, "content": str(content_path),
              "web_url": url, "project": project, "change": number,
              "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
    with error_context("context_cache", str(directory)):
        for destination, body in (
                (content_path, data),
                (record_path, (json.dumps(record, ensure_ascii=True, indent=2) + "\n")
                 .encode("utf-8"))):
            temporary = None
            try:
                with tempfile.NamedTemporaryFile(dir=directory, delete=False) as stream:
                    temporary = Path(stream.name)
                    temporary.chmod(0o600)
                    stream.write(body)
                os.replace(temporary, destination)
            finally:
                if temporary is not None:
                    temporary.unlink(missing_ok=True)
    return record


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", help="Change number[/patchset], Change-Id, SHA or Gerrit URL")
    parser.add_argument("--patchset", type=int, help="Exact historical patchset")
    parser.add_argument("--project", help="Restrict lookup to this Gerrit project")
    parser.add_argument("--web-url", help="HTTPS Gerrit base URL, required for non-URL targets")
    parser.add_argument("--output", required=True, help="New artifact directory for this review")
    parser.add_argument("--max-bytes", type=int, default=MAX_DIFF_BYTES,
                        help="Maximum decoded REST patch size (default: 32 MiB)")
    parser.add_argument("--timeout", type=float, default=30,
                        help="Total timeout per HTTP request in seconds")
    parser.add_argument("--connect-timeout", type=int, default=10,
                        help="HTTPS connection and initial handshake timeout in seconds")
    args = parser.parse_args(argv)
    try:
        if args.patchset is not None:
            args.patchset = positive_int(args.patchset)
        result = retrieve(args)
    except (RetrievalError, OSError, ValueError, UnicodeError) as error:
        details = error.details if isinstance(error, RetrievalError) else {}
        diagnostic = {"stage": "input_validation", **details, "error": str(error)}
        print(json.dumps(sanitize_diagnostic(diagnostic), ensure_ascii=True), file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
