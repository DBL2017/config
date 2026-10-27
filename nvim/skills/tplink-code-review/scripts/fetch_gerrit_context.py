#!/usr/bin/env python3
"""Download one exact-revision or first-parent file for a Gerrit REST manifest."""

import argparse
import json
import sys

from fetch_gerrit_patch import (
    MAX_CONTEXT_BYTES, RetrievalError, retrieve_context, sanitize_diagnostic,
)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", help="Completed diff retrieval manifest.json")
    parser.add_argument("file", help="Exact repository-relative file path")
    parser.add_argument("--side", choices=("revision", "base"), default="revision")
    parser.add_argument("--timeout", type=float, default=30)
    parser.add_argument("--connect-timeout", type=int, default=10)
    parser.add_argument("--max-bytes", type=int, default=MAX_CONTEXT_BYTES,
                        help="Maximum decoded file size (default: 16 MiB)")
    args = parser.parse_args(argv)
    try:
        result = retrieve_context(args)
    except (RetrievalError, OSError, ValueError, UnicodeError) as error:
        details = error.details if isinstance(error, RetrievalError) else {}
        diagnostic = {"stage": "input_validation", **details, "error": str(error)}
        print(json.dumps(sanitize_diagnostic(diagnostic), ensure_ascii=True), file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
