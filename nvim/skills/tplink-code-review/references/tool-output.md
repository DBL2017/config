# Bound tool output, not review coverage

Use built-in scoped search and range reads first. Narrow paths and language/file
globs before returning matches; request locations with about 1–2 context lines.
Use file-only results for discovery. Do not dump whole files, recursively print a
module, or repeat already validated shared evidence to obtain one contract.
Read enclosing functions and related paths when verification needs them: a short
preview is a navigation aid, not enough evidence to mark a file or path inspected.

## Large searches

When built-in result limits would obscure whether more hits remain, use:

```sh
python3 <skill-dir>/scripts/search_review_source.py <selected-source-root> refresh_cache \
  --path src/module --glob '*.{c,h}' --literal
```

Requires existing `rg` and Python 3; do not install dependencies for review.
If unavailable, use built-in scoped search/count and explicit bounded reads;
record any unresolved enumeration gap rather than claiming complete access coverage.
For revision/index reviews, root and dependencies must be from the exact selected
materialized snapshot, not the current worktree.

Defaults: 10 matching lines/page, one context line on either side, 160 characters
per line preview. Output includes exact file/line positions, total matching-line
count, `next_offset`, and per-line `truncated`/`preview_start`. Matching occurrences
on the same line count once. Long-line previews center near the first match;
`encoding_replaced` means source bytes were not valid UTF-8, not that replacement
text is the exact source. Inspect the original bytes with a suitable read-only
tool before making encoding-sensitive claims.

Continue the same search with `--offset <next_offset>`. `--limit` (1–50),
`--context` (0–3), and `--max-chars` (1–1000) adjust output only, not scanned scope.
Read original source around relevant locations, expanding ranges through the
complete function/control flow when needed. Classify remaining relevant hits;
neither a page boundary nor an initial excerpt is a review stopping criterion.
Never use `head` or ripgrep's per-file match limit to claim all accesses were found.
Revalidate source identity if the source changes between pages.

The helper scans only explicit repository-relative paths and supplied globs in
stable path/line order. It includes hidden/ignored text sources but excludes Git
object storage, binary files and unfollowed directory symlinks. Consumer/build
references can require additional explicit paths/globs, generated sources or
readable symlink targets; reconcile these exclusions rather than inferring a
complete call graph. Invalid patterns, inaccessible paths and ripgrep failures
are errors, not an empty successful result. Previews never certify coverage.

## Gate diagnostics

```sh
python3 <skill-dir>/scripts/validate_review_record.py <record> --gate initial
python3 <skill-dir>/scripts/validate_review_record.py <record> --gate initial --offset 5 --limit 5
```

Successful CLI validation returns counts and the next file, not whole remaining
lists. The default failure output is JSON on stderr, a nonzero exit, and the
specific failed gate condition. For incomplete file/state/trace/issue lists,
`gap` supplies its kind, total, current IDs and `next_offset` (five IDs/page).
Use `manage_review_record.py get --kind <kind> --id <id>` to inspect one item;
re-run the gate after fixing it to expose the next condition. Structural errors
name the field/link needing repair; do not relabel or skip records to pass.
`--details` explicitly requests full successful summary or all gap IDs, only
when necessary. Library validation still checks/returns the full record.

Keep complete parser/compiler logs in session storage when needed, but read
focused diagnostic ranges into context. Preserve the actual exit status;
truncating a log or a successful `head` command does not mean validation passed.
Keep material limitations in the report and full evidence in the ledger.

## Final report

Continue using `generate_review_report.py` for module reports, with no findings
quota or output truncation. Tool preview limits never limit confirmed findings,
required coverage, report mappings, or the prescribed partial-report fields.
Do not regenerate the same report merely to summarize it a second time.
