# Incremental full-source record tools

Use Python 3 on POSIX (`flock`), no third-party dependencies. Record commands
operate only on session files and read selected current source for hashes;
the report generator writes Markdown to the review's working directory.
Neither executes or edits reviewed code.
Do not read tool implementations just to invoke them. Full field definitions
are in `review-record-format.md`; load only the section needed.

Use a unique, initially nonexistent review directory outside the repository.
All examples use absolute `<record>` and `<skill-dir>` paths. Supply JSON through
stdin or `--input <session-payload.json>`; do not put payloads in the repository.
One writer owns updates and report generation. Do not run these concurrently.

## Initialize

```sh
python3 <skill-dir>/scripts/manage_review_record.py init <record> --input <manifest>
```

Manifest:

```json
{
  "source": {
    "repository": "/absolute/repository",
    "review_kind": "module",
    "module": "src/module",
    "identity": "revision/worktree and reviewed build variants",
    "spec_available": false
  },
  "files": [
    {"path": "src/module/main.c", "status": "in_scope"},
    {"path": "src/module/vendor.c", "status": "excluded", "reason": "Specific reason"}
  ],
  "supporting_files": ["src/module/module.h", "src/module/Makefile"]
}
```

Enumerate the complete discovered implementation inventory first; this is not an
automatic directory audit. Paths are repository-relative and cannot escape via
symlinks. The tool hashes in-scope and supporting files, derives counts, creates
all pending checks and an empty journal. It never asserts inventory reconciliation
or that any file has been inspected. Existing review directories are not overwritten.
Each file starts with four pending risk categories inside
`functional_paths.risk_inventory`; inspecting a file does not automatically
complete their discovery or their linked call-site proofs.
The initializer also extracts tool-owned `functional_paths.candidate_scan`.
Do not include that field in update deltas. Known candidates use `candidate_id`;
manual wrappers use an exact `manual_anchor` obtained with
`discover_risk_sites.py --all-calls`. Read `input-boundary-review.md` for the
required `scenarios`, numeric/field `facts`, and per-issue `claim` contract.
Old records without candidate snapshots reopen dependent work on update.

When old reports are supplied, add `"prior_reports": ["/absolute/old-report.md"]`
to the init manifest. Imports are snapshotted outside the repository. Disposition
updates use, for example:

```json
{
  "prior_findings": [{
    "id": "P001", "status": "retained", "issue_ids": ["R003"],
    "reason": "The original error path still returns success",
    "evidence": ["src/main.c:30-45"]
  }]
}
```

Original prior fields are immutable; status/reason/evidence/issue links and an
optional `severity_change_reason` are updateable. Query via `get --kind prior`;
normal `resume` includes pending prior tasks. No prior item may silently vanish.
`resume` gives candidate counts rather than dumping expressions. Read counted
pages with `get <review.json> --kind candidates --id <target-path> --offset 0
--limit 5`; continue until `next_offset` is null. Explicit `get --kind file`
still returns the full selected check object.
For a full-file review, set `source.review_kind` to `file`, put the requested
file path (for example `src/module/main.c`) in `source.module`, and supply exactly
that one `in_scope` inventory entry. This includes explicitly selected headers
or scripts. Headers/callers/helpers read only for context belong in
`supporting_files`, never in the target inventory. Omitting `review_kind`
retains the existing module behavior.
For supplied excerpts without real files or old ledgers, use the schema/migration
reference instead; do not fabricate hashes to satisfy this initializer.

## Update only changed facts

```sh
python3 <skill-dir>/scripts/manage_review_record.py update <record> --input <delta>
```

One payload may update linked files, traces, state groups and issues together:

```json
{
  "file_checks": {
    "src/module/main.c": {
      "functional_paths": {"status": "inspected", "evidence": ["src/module/main.c:10-80"]},
      "call_interface": {"status": "inspected", "evidence": ["@E001"]}
    }
  },
  "evidence_catalog": {
    "E001": {
      "summary": "Worker dispatch and shared helper contract",
      "evidence": ["src/module/main.c:20-35", "src/module/helper.c:10-40"],
      "dependencies": ["src/module/module.h"]
    }
  },
  "traces": [
    {"id": "T001", "status": "pending", "issue_ids": ["R001"],
     "evidence": ["@E001"], "next_check": "Inspect worker exit"}
  ],
  "issues": [
    {"id": "R001", "origin": "initial src/module/main.c:30",
     "summary": "Worker may outlive argument", "status": "pending",
     "evidence": ["@E001"], "dependencies": ["T001"],
     "trace_ids": ["T001"], "open_questions": ["Does shutdown join?"],
     "next_check": "Read shutdown join path", "disposition": "Needs lifetime evidence"}
  ],
  "progress": {"next_step": "Inspect src/module/helper.c"}
}
```

Object fields merge recursively; arrays replace, not append. Trace/state entries
upsert by stable `id`; issue deltas merge with the last event and append a full
snapshot. The tool owns `seq` and `updated_at`. Omit a new issue ID for automatic
`R001` allocation; specify it when creating reciprocal links in the same update.
New issues default to pending, empty links/questions/dependencies and null merge
target, never to confirmed. Confirmation still requires all report fields.
Resolved/dismissed issues must reopen pending before a contrary disposition.
All links and the progress gate validate before writing.
Issue events also snapshot referenced catalog facts in `evidence_snapshots`;
later catalog changes cannot silently change the meaning of historical evidence.

For new confirmed findings, provide `rule_tags` and `rule_basis` as specified
in `review-record-format.md`; do not use the legacy `rule` field for new entries.

Risk inventories merge under `file_checks[path].functional_paths.risk_inventory`.
In the same update, upsert their linked `kind: risk_site` entries in `traces`.
Supply all four category discovery decisions before the initial gate, then
close each site's proof or exclusion before integration. Read
`input-boundary-review.md` for exact category names, statuses and proof fields.
Use `get --kind trace --id <id>` for a site; there is no separate risk ledger.

Other fields: `state_groups` (see schema section Shared-state evidence),
`validation`, `limitations`, and `inventory_reconciled` (explicit boolean after
build reconciliation). Updating always clears the stale report mapping; generate
the report again. Initial inventory/scope edits require evidenced manual migration
or repair under the schema reference, not a silent count adjustment.

### Save or refresh the full-source report

```sh
python3 <skill-dir>/scripts/generate_review_report.py <record> --partial
python3 <skill-dir>/scripts/generate_review_report.py <record>
```

Use `--partial` only for an actual interruption recorded in
`progress.interruption`; use the second command after completion gates pass and
the interruption is cleared. Both atomically write and read back a Markdown
file in the working directory where the review starts, named
`YYYY-MM-DD-Target-评审报告-v1.md` (full filename including extension for a file;
directory name for a module). Run the first generation from that directory,
not the skill/session directory. It stores the basename in `report_file` and the
absolute destination directory in `report_directory`; later runs update that same
file even from a different directory, retaining the original date and version.
The internal record/journal stay outside the reviewed repository, but the report
may be written inside it. Refresh it at every continuation
handoff and on completion. The CLI prints only review status and the absolute
report path for chat; findings remain in the file. A write/read-back failure
is an explicit error, not a delivered report.

### Reuse and invalidate evidence

Catalog IDs are bare (`E001`); evidence lists reference them with `@E001`.
Catalog entries contain concise facts and actual locations, not further `@`
references or source bodies. Use trace/state IDs for call paths and context
proofs, and `dependencies` for material contracts. Reuse an ID only after reading
its facts and checking source identity; an ID is not a synchronization proof.
Final issue `cause` and `location` must still include concrete source locations,
because report rendering does not expand catalog references.

Changing a catalog entry automatically invalidates dependent work and requires
`reason`. For new scheduling/ownership contracts or changed source, submit:

```json
{
  "invalidate": ["src/module/helper.c", "T001"],
  "reason": "New runtime caller contradicts startup-only assumption"
}
```

The tool follows exact IDs, `@` references and `path:location` strings transitively,
resets affected file checks/traces/state inventories to pending, reopens affected
non-merged issues through journal events, and clears report mappings. It refreshes
changed tracked file hashes after invalidation. `update` also invalidates detected
tracked-source drift automatically, with a recorded reason; `resume` never reuses
changed source as verified evidence. Affected risk discovery categories and
call-site traces reopen, retaining their IDs and inventory links. It cannot infer
unrecorded semantic dependencies; record those and invalidate them explicitly.
Keep invalidation and re-verification separate unless new inspected evidence is
already available. Missing files require inventory reconciliation, not a fake hash.

## Resume and query a bounded working set

```sh
python3 <skill-dir>/scripts/manage_review_record.py resume <record>
python3 <skill-dir>/scripts/manage_review_record.py resume <record> --offset 1 --limit 1
python3 <skill-dir>/scripts/manage_review_record.py get <record> --kind trace --id T001
python3 <skill-dir>/scripts/manage_review_record.py get <record> --kind issue --id R001
```

`resume` validates the complete ledger and issue history internally, checks tracked
source hashes and returns counts, one unfinished task by default, its related IDs
and directly referenced evidence. `resume_allowed: false` means reconcile changed
or inaccessible sources before reusing prior evidence. Also verify selected scope,
build variants and newly discovered files; hashes cannot detect new build inputs.
No full journal or duplicate pending lists are injected into model context.
Continue from the first unfinished file, then unresolved state/trace/issue tasks.
Read linked records with `get`, not by dumping the whole ledger.

`get --kind` supports `file`, `issue` (latest only), `trace`, `state`, `evidence`,
and `history` (one issue's full history, only when needed). Pagination uses
`next_offset`; total tasks and coverage counts make omitted pages explicit.
These commands read back saved facts and run the progress gate, but do not claim
initial/integration gates passed or source analysis was complete.

Standalone gate commands return compact counts on success and a failed condition
with paginated gap IDs on stderr; `tool-output.md` documents `--offset`, `--limit`
and opt-in `--details`. This changes returned text, not what the gate validates.

## Recover interrupted writes

An update validates first, saves a `transaction.json`, flushes appended issue
events, atomically replaces `review.json`, reads back and validates both, then
removes the transaction. Cooperating commands lock the record. Report generation
and validators refuse unfinished transactions.

```sh
python3 <skill-dir>/scripts/manage_review_record.py recover <record>
```

Recovery checks base hashes, completes a partial append without duplicating
events, replaces the record and validates it. External conflicting edits are
errors, never overwritten. Until recovery succeeds, do not claim saved progress
or generate a report. Save/checkpoint before interruption when possible.
