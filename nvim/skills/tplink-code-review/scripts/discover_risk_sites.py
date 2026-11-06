#!/usr/bin/env python3
"""List lexical C/C++ risk-call candidates; never execute or classify source as safe."""

import argparse
import ast
import hashlib
import json
from pathlib import Path
import re
import sys

FAMILIES = {
    "string_boundary": (
        "strcpy strncpy strcat strncat memcpy memmove sprintf snprintf vsprintf "
        "vsnprintf printf fprintf vprintf vfprintf strcmp strncmp strlen strnlen "
        "uci_get_state"
    ).split(),
    "scan_conversion": "scanf sscanf fscanf vscanf vsscanf vfscanf".split(),
    "structured_input": (
        "cJSON_GetObjectItem cJSON_GetObjectItemCaseSensitive cJSON_GetArrayItem "
        "uci_lookup_section uci_lookup_option_string"
    ).split(),
    "allocation_io": (
        "malloc calloc realloc free fopen fdopen open close fclose fread fwrite "
        "read write fseek ftell fflush remove unlink cJSON_Print cJSON_PrintUnformatted "
        "cJSON_CreateObject cJSON_CreateArray cJSON_CreateString cJSON_Delete "
        "uci_alloc_context uci_load uci_unload uci_free_context"
    ).split(),
}
CATEGORIES = {name: category for category, names in FAMILIES.items() for name in names}
TOKEN = re.compile(
    r"(?P<comment>//[^\n]*|/\*.*?\*/)"
    r"|(?P<string>(?:u8|[LuU])?\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*')"
    r"|(?P<name>[A-Za-z_]\w*)|(?P<punct>[^\s])", re.S)
CONTROL = {"if", "for", "while", "switch", "sizeof", "_Alignof", "alignof"}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def extract_calls(content, path):
    source = content.decode("utf-8")
    tokens = [match for match in TOKEN.finditer(source) if match.lastgroup != "comment"]
    pairs, stack = {}, []
    for index, token in enumerate(tokens):
        if token.group() in ("(", "{", "["):
            stack.append(index)
        elif token.group() in (")", "}", "]") and stack:
            opening = stack.pop()
            if tokens[opening].group() == {")": "(", "}": "{", "]": "["}[token.group()]:
                pairs[opening] = index
    functions = []
    for index, token in enumerate(tokens[:-1]):
        if token.lastgroup != "name" or token.group() in CONTROL:
            continue
        closing = pairs.get(index + 1) if tokens[index + 1].group() == "(" else None
        if closing is not None and closing + 1 in pairs and tokens[closing + 1].group() == "{":
            functions.append((closing + 1, pairs[closing + 1], token.group()))
    calls = []
    identity = sha(content)
    for index, token in enumerate(tokens[:-1]):
        callee = token.group()
        if token.lastgroup != "name" or callee in CONTROL or tokens[index + 1].group() != "(":
            continue
        closing = pairs.get(index + 1)
        if closing is None or (closing + 1 < len(tokens) and tokens[closing + 1].group() == "{"):
            continue
        function = next((name for start, end, name in reversed(functions)
                         if start < index < end), "<file-scope>")
        line = source.count("\n", 0, token.start()) + 1
        column = token.start() - source.rfind("\n", 0, token.start())
        end_line = source.count("\n", 0, tokens[closing].end()) + 1
        expression = source[token.start():tokens[closing].end()]
        arguments, start, cursor = [], index + 2, index + 2
        while cursor < closing:
            if cursor in pairs:
                cursor = pairs[cursor] + 1
                continue
            if tokens[cursor].group() == ",":
                arguments.append(tokens[start:cursor])
                start = cursor + 1
            cursor += 1
        arguments.append(tokens[start:closing])
        format_index = 0 if callee in ("scanf", "vscanf") else 1
        format_string = None
        if callee in FAMILIES["scan_conversion"] and len(arguments) > format_index:
            pieces = arguments[format_index]
            if pieces and all(piece.lastgroup == "string" and piece.group().startswith('"')
                              for piece in pieces):
                try:
                    format_string = "".join(ast.literal_eval(piece.group()) for piece in pieces)
                except (ValueError, SyntaxError):
                    format_string = None
        calls.append({
            "id": f"{line}:{column}:{callee}", "callee": callee, "function": function,
            "line": line, "end_line": end_line, "column": column,
            "expression_sha256": sha(expression.encode("utf-8")),
            "source_identity": identity,
            **({"format_string": format_string} if callee in FAMILIES["scan_conversion"] else {}),
        })
    return calls


def discover(content, path):
    c_source = Path(path).suffix.lower() in (".c", ".h", ".cc", ".cpp", ".cxx", ".hpp")
    calls = extract_calls(content, path) if c_source else []
    return {
        "version": 1, "source_identity": sha(content),
        "language": "c_cpp" if c_source else "manual",
        "candidates": [{**call, "category": CATEGORIES[call["callee"]]}
                       for call in calls if call["callee"] in CATEGORIES],
    }


def verify_sources(record):
    repository = Path(record["source"]["repository"]).resolve()
    for path, checks in record["file_checks"].items():
        target = (repository / path).resolve()
        if repository not in target.parents:
            raise ValueError(f"{path}: source escapes repository")
        content = target.read_bytes()
        if sha(content) != checks["identity"]:
            raise ValueError(f"{path}: source changed; update/invalidate before completion")
        scan = checks["functional_paths"].get("candidate_scan")
        if scan != discover(content, path):
            raise ValueError(f"{path}: candidate scan missing or stale; refresh through update")
        calls = {call["id"]: call for call in extract_calls(content, path)}
        for site in record["traces"]:
            if site.get("kind") == "risk_site" and site.get("file") == path:
                if site.get("manual_anchor") is not None:
                    anchor = site["manual_anchor"]
                    if anchor != calls.get(anchor.get("id")):
                        raise ValueError(f"{site['id']}: manual anchor does not match source")
    for path, identity in record.get("supporting_files", {}).items():
        if identity is None:
            continue
        target = (repository / path).resolve()
        if repository not in target.parents or sha(target.read_bytes()) != identity:
            raise ValueError(f"{path}: supporting evidence changed; invalidate before completion")
    tracked = set(record["file_checks"]) | {
        path for path, identity in record.get("supporting_files", {}).items() if identity is not None}
    for site in record["traces"]:
        facts = site.get("facts", {})
        for bound in facts.get("buffers", []) + facts.get("conversions", []):
            references = bound.get("producer_evidence", [])
            if references:
                paths = {match[1] for reference in references
                         if (match := re.search(r"([^\s:]+):[1-9][0-9]*", reference))}
                if not paths or not paths <= tracked:
                    raise ValueError(f"{site['id']}: producer evidence must use tracked source paths")
    for item in record.get("prior_findings", []):
        if sha(Path(item["snapshot"]).read_bytes()) != item["report_identity"]:
            raise ValueError(f"{item['id']}: imported prior-report snapshot changed")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path)
    parser.add_argument("--all-calls", action="store_true",
                        help="Also expose unclassified calls for manual wrapper anchoring")
    args = parser.parse_args()
    try:
        content = args.file.read_bytes()
        result = (extract_calls(content, str(args.file)) if args.all_calls
                  else discover(content, str(args.file)))
        print(json.dumps(result, ensure_ascii=False))
    except (OSError, UnicodeError, ValueError) as error:
        print(f"Candidate discovery failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
