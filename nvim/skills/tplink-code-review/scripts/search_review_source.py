#!/usr/bin/env python3
"""Return paginated ripgrep locations and short previews, never coverage verdicts."""

import argparse
import base64
from collections import deque
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from validate_review_record import require


def preview(data, width, byte_start=0):
    raw = data.get("text")
    replaced = raw is None
    if replaced:
        binary = base64.b64decode(data["bytes"], validate=True)
        raw = binary.decode("utf-8", errors="replace")
        column = len(binary[:byte_start].decode("utf-8", errors="replace"))
    else:
        column = len(raw.encode("utf-8")[:byte_start].decode("utf-8"))
    raw = raw.rstrip("\r\n")
    start = max(0, column - width // 3)
    return {
        "preview": raw[start:start + width], "preview_start": start + 1,
        "line_characters": len(raw), "truncated": start > 0 or len(raw) > width,
        "encoding_replaced": replaced,
    }


def search(root, pattern, paths, globs, offset=0, limit=10, context=1,
           max_chars=160, literal=False):
    require(root.is_dir(), "Search root must be a selected source directory")
    require(".git" not in root.parts, "Do not search Git object storage")
    require(offset >= 0 and 1 <= limit <= 50 and 0 <= context <= 3 and
            1 <= max_chars <= 1000, "Invalid search pagination or preview bounds")
    require(paths and globs, "Explicit paths and file globs are required")
    scopes = {}
    for name in paths:
        candidate = Path(name)
        require(not candidate.is_absolute(), "Search paths must be relative to source root")
        resolved = (root / candidate).resolve()
        require(resolved == root or root in resolved.parents, "Search path escapes source root")
        require(".git" not in candidate.parts and ".git" not in resolved.relative_to(root).parts,
                "Do not search Git object storage")
        require(resolved.exists(), f"Search path does not exist: {name}")
        scopes[resolved] = resolved.is_dir()
    paths = [path.relative_to(root).as_posix() for path in scopes
             if not any(parent != path and is_directory and parent in path.parents
                        for parent, is_directory in scopes.items())]
    executable = shutil.which("rg")
    require(executable is not None, "ripgrep unavailable; use scoped built-in search and explicit limits")
    command = [executable, "--no-config", "--json", "--sort", "path", "--hidden", "--no-ignore",
               "--context", str(context)]
    for glob in globs:
        command.extend(("--glob", glob))
    command.extend(("--glob", "!.git", "--glob", "!**/.git/**"))
    if literal:
        command.append("--fixed-strings")
    command.extend(("--", pattern, *paths))
    hits = []
    total = 0
    file_start_total = 0
    file_hit_start = 0
    before = deque(maxlen=context)
    with tempfile.TemporaryFile() as errors:
        process = subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE,
                                   stderr=errors, text=True, encoding="utf-8")
        try:
            for line in process.stdout:
                event = json.loads(line)
                kind, data = event["type"], event["data"]
                if kind == "begin":
                    file_start_total, file_hit_start = total, len(hits)
                    before.clear()
                    continue
                if kind == "end":
                    if data.get("binary_offset") is not None:
                        total = file_start_total
                        del hits[file_hit_start:]
                    before.clear()
                    continue
                if kind not in ("match", "context"):
                    continue
                path_data = data["path"]
                require("text" in path_data, "Non-UTF-8 paths require direct filesystem inspection")
                path = Path(path_data["text"]).as_posix()
                number = data["line_number"]
                row = {"line": number, **preview(data["lines"], max_chars)}
                for hit in hits:
                    if hit["path"] == path and 0 < number - hit["line"] <= context:
                        hit["after"].append(row)
                if kind == "match":
                    if offset <= total < offset + limit:
                        first = data["submatches"][0]["start"]
                        hits.append({
                            "path": path, "line": number,
                            **preview(data["lines"], max_chars, first),
                            "before": [item for item in before
                                       if 0 < number - item["line"] <= context],
                            "after": [],
                        })
                    total += 1
                before.append(row)
            status = process.wait()
        finally:
            process.stdout.close()
            if process.poll() is None:
                process.terminate()
                process.wait()
        if status not in (0, 1):
            errors.seek(0)
            diagnostic = errors.read(2049)
            suffix = " [diagnostic truncated]" if len(diagnostic) > 2048 else ""
            message = diagnostic[:2048].decode("utf-8", errors="replace")
            raise ValueError(f"ripgrep failed ({status}): {message}{suffix}")
    return {
        "scope": {"root": str(root), "paths": paths, "globs": globs,
                  "hidden": True, "ignore_rules": False, "binary_files": "excluded"},
        "previews_only": True, "total_matching_lines": total,
        "offset": offset, "limit": limit,
        "next_offset": offset + limit if offset + limit < total else None,
        "hits": hits,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path, help="Exact worktree or materialized review snapshot")
    parser.add_argument("pattern")
    parser.add_argument("--path", action="append", required=True, help="Explicit relative scope")
    parser.add_argument("--glob", action="append", required=True, help="Source file glob")
    parser.add_argument("--literal", action="store_true")
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--context", type=int, default=1)
    parser.add_argument("--max-chars", type=int, default=160)
    args = parser.parse_args()
    try:
        result = search(args.root.resolve(), args.pattern, args.path, args.glob,
                        args.offset, args.limit, args.context, args.max_chars, args.literal)
        print(json.dumps(result, ensure_ascii=False))
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(f"Source search failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
