# Full-source completion and continuation

Apply to full-file and current-module reviews through the same pipeline.
Do not apply to selections, excerpts, diffs or revision reviews.
This reference owns stage gates and persistence policy. Record commands live in
`record-tools.md`; consult `review-record-format.md` only for unfamiliar fields,
manual repair or migration. Read `concurrency-review.md` for shared-state or
asynchronous reasoning, not as a second completion checklist.

## 1. Inventory and initialize

For a full-file review, the complete discovered and in-scope inventory is the
single requested file, including an explicitly requested header or script.
Use `source.review_kind: file` and put its repository-relative path in the
legacy `source.module` field. Do not enumerate sibling files as targets.
For a module review, use `source.review_kind: module` (the legacy default) and
resolve implementation files against build inputs, conditional variants and
user paths. Distinguish discovered, in-scope and excluded counts; generated,
vendor and inactive sources need explicit inclusion/exclusion reasons.
Unless explicitly selected as the full-file target, headers/build/configuration/
tests support contracts, not target counts. Callers and helpers read to verify
a target contract are supporting files, not additional audit targets.
Unexplained or unreadable files are gaps, not convenient exclusions.

Before the per-file pass, use the record tools to create a unique session-local
review directory outside the reviewed repository. Save repository/module,
revision/worktree identity, reviewed variants, inventory and real content hashes.
Track supporting files whose contracts evidence depends on. A commit hash alone
does not identify dirty worktree content. Mark inventory reconciled only after
checking build/conditional inputs relevant to the selected target; a file
review does not require reconciling its whole directory. Source enumeration
is not review coverage.

## 2. Initial pass

Visit every in-scope target file. Record four checks with locations:
functional/normal/error paths; calls/interfaces; resource ownership/cleanup;
mutable state/execution contexts. Mark inspected, justified not applicable,
pending or blocked. Inspecting a file is not proof every integrated path is safe.
Use `input-boundary-review.md` to populate every target's
`functional_paths.risk_inventory` and dedicated `kind: risk_site` traces.
Discovery must explicitly account for strings, scanning, structured inputs and
allocation/I/O, with evidence for empty or inapplicable categories. Register
each candidate even when its safety proof will be deferred to integration.
For C/C++, include string/buffer operations and actual input/capacity/termination
bounds in the functional check, and conversion counts, truncation and meaningful
return-value propagation in the functional/interface checks. Include `strncpy`,
`sscanf` conversions, unbounded string APIs and bounded alternatives as applicable.
Inspect reads/resets/counters before lock acquisition as well as protected
regions; later locking cannot protect earlier accesses. Preserve caller evidence
for destructive error cleanup, such as deleting input that should be retried.

Persist every concrete suspect/confirmed finding with a stable issue ID before
switching files or verification tasks. Queue cross-file questions with reciprocal
issue links. Coverage-driven traces need no originating issue. Avoid repeatedly
deep-tracing the same shared helper; reference its stable trace/evidence ID.
Urgent verification is allowed, but then return to the next pending file.

Register each mutable object/coherent state group and link relevant file checks
to it. Every group needs a dedicated `kind: shared_state` trace; capacity or
allocation findings cannot close synchronization. An initial inspected state
check means discovery/handoff only. Empty inventories need evidenced no-state
reasons, not omitted groups.

Save after each file; read back through the validated scoped query. Run:

```sh
python3 <skill-dir>/scripts/validate_review_record.py <review.json> --gate initial
```

Only then begin concentrated integration. All risk categories must have complete
discovery or evidenced non-applicability; broad inspected ranges alone do not
pass this gate. Pending risk sites, suspects and state proofs can
cross this gate; inaccessible files keep it open while other review work continues.
Tool-extracted candidates must each map to an exact call trace. Complete final
delivery also requires all applicable site scenarios and supplied prior findings
reconciled under `input-boundary-review.md`; one finding does not close other
failures in the same function.
Gate CLI output is compact; use `tool-output.md` only when additional diagnostic
pages are needed. Never mistake a returned subset for the full outstanding scope.

## 3. Integrate and reconcile

Trace material target-related end-to-end behavior, ownership transfers,
normal/error exits, startup/refresh/shutdown, and asynchronous paths. Establish actual callback
registration and dispatch, reader/writer contexts, aliases and ordering using
the concurrency reference. Resolve each registered state group independently.

Update traces and issue dispositions after each verification. Confirm defects
only with triggers and invalid behavior; dismiss only with counterevidence;
merge only the same root cause, preserving distinct triggers/impacts and IDs.
Keep pending/blocked questions actionable. Contract changes reopen dependent
checks, proofs and issue dispositions, including previously dismissed concerns.
Use explicit dependency IDs and evidence catalog references so the tools can
invalidate linked work instead of restarting unaffected files.

```sh
python3 <skill-dir>/scripts/validate_review_record.py <review.json> --gate integration
python3 <skill-dir>/scripts/generate_review_report.py <review.json>
```

Integration requires complete initial coverage, reconciled inventory, resolved
material traces/issues/state groups, and recorded validation outcomes/limitations.
Risk sites must also have category-specific proofs or evidenced build/path
exclusions, with confirmed defects linked to issues. Shared-state closure
cannot close an independent string, parser or input-contract concern.
Unavailable tools alone do not block static review; unresolved material questions
do. Several serious findings, elapsed effort or a batch boundary are not exits.

The generator builds the confirmed-issue/report bijection, saves the record,
reads back and validates the final gate, then atomically writes and reads back
the Markdown report in the working directory where the review starts, not beside
the session record. Run the first generation from that working directory.
Its filename is
`YYYY-MM-DD-Target-评审报告-v1.md`: the date is the first report's local date,
and Target is the full filename including extension for a file review, or the
module path's final component (repository name for a root module), with
filename-unsafe characters replaced. The record's `report_file`
and absolute `report_directory` preserve the name and destination across
continuations, including on a later date or from a different working directory.
Deliver only the saved report path and review status in chat, not its full
findings. Do not drop, add or regroup findings from memory. It does not prove
source reasoning or enforce a runtime hook. A rejected gate means repair the evidenced gap and
continue, not hand-write a substitute complete report.

## 4. Durable updates and recovery

`review.json` and adjacent append-only `issues.jsonl` are authoritative, not chat
or database-only summaries. Keep one writer, including report generation; do not
let agents update concurrently. Tools maintain complete issue event snapshots,
consecutive sequence numbers, flushes, atomic record replacement and read-back.
Use their compact results rather than dumping both files into model context.
Store facts/locations, not source bodies, credentials or private reasoning.

After compaction/continuation, run the record tool's `resume`: it loads and
validates both complete files internally and emits a bounded working set.
Verify scope/variants, reconcile new/removed files against build inputs and
check source changes before continuing the first unfinished task. Query related
IDs only as needed. Changed files and supporting contracts invalidate dependent
work; retain unaffected evidence and all issue history. The `progress` gate is
run internally; re-run initial/integration gates at phase boundaries.

If a write is interrupted, use `recover` before further analysis or reporting.
If persistence fails, try another runtime-approved session-local location outside
the repository. If none works, record a completion blocker; never claim an
unsaved checkpoint or silently substitute conversation storage.

## 5. Real blockers and interruptions

Continue accessible work before interrupting unless the user/runtime stops it.
Agent transport failures, policy blocks and HTTP errors prove only a failed call,
not that source cannot be reviewed. If source is accessible, directly rebuild
objects/aliases, entry/registration/dispatch paths, normal/error/lifetime paths
and shared-state proofs; record an individual disposition for each pending item.
Do not repeatedly resubmit the same failed agent task.

For unresolved items record `blocker_type` (`agent_transport`, `tool_access`,
`source_context`, `reviewer_stop`), raw diagnostic/time/tool/request ID and
affected record IDs, attempted alternatives, executable `next_check` and required
`closure_evidence`. Use `raw_diagnostic_unavailable` rather than guessing a policy.
If only agent communication failed, state that source verification can continue.

A partial report is justified only by user stop, an actual inaccessible dependency
after reasonable alternatives, or an observed/enforced runtime/context limit.
Do not invent limits from task size. Save a factual `progress.interruption` and
run the generator with `--partial`. Preserve confirmed findings; use
`评审状态：未完成（阶段结果）` and `当前结论：需要修改` or `尚不能判定`,
never `通过`. Include concrete interruption, coverage, pending file/trace/state/
issue IDs, checkpoint path and next check. Keep item-level blocker/closure detail
in the queried record; a long pending list may reference that saved record.
At each continuation handoff, regenerate this same report with current findings,
coverage and next check; do not create a new date/version file or substitute chat
for the saved report. Continue accessible work instead of inventing interruptions
just to publish updates. On completion, clear the interruption and run the
generator without `--partial` to replace the same file with `评审状态：已完成`.
If records/tools are inaccessible, report the actual blocker without claiming
successful report generation or completion.
