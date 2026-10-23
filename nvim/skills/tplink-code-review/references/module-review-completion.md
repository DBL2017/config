# Module review: completion gates and resumable progress

Apply this protocol only to module reviews. It does not widen file, diff,
commit, or Gerrit scope. Keep source and evidence read-only; use session
storage for progress so review work does not modify the target repository.

## 1. Save an evidence-backed ledger

Create a review-specific directory in the runtime-provided session
directory, outside the reviewed repository, before the per-file pass. Use a
distinct directory for each review, such as `files/review-<review-id>/`;
resolve it to an absolute path and retain that path for continuation. Never
reuse another review's directory accidentally. Keep `review.json` for source,
inventory, coverage, traces and progress, and `issues.jsonl` for append-only
issue events. These files together are the authoritative review record;
conversation context, chat history, and
database-only records are not substitutes. Do not put source bodies, secrets,
credentials, or private reasoning in it.

Record:

- Source identity: repository/module path, revision when available, build
  variants reviewed, and a content identity for inspected worktree files.
  A commit hash alone does not identify dirty worktree contents.
- Inventory: each implementation file, inclusion/exclusion and reason;
  discovered total, in-scope total, and excluded total. Keep related headers,
  build files, configuration, and tests as supporting evidence, not additional
  implementation-file counts.
- Per-file checks: functional/normal/error paths; call/interface contracts;
  resource ownership/cleanup; shared state/execution contexts. For each check
  use pending, inspected, blocked, or not applicable, with evidence locations
  and a reason for blocked/not applicable. A whole-file initial pass is
  complete only when all four checks are inspected or justified not applicable.
- Cross-file queue: path/state/resource identity, producer/writer and
  consumer/reader, relevant contexts, evidence locations, outstanding
  question, pending/verified/finding/blocked status, and originating issue IDs.
  Coverage-driven traces may have no originating issue.
- Shared-state inventory: stable group IDs, member symbols, related in-scope
  files, writer/reader call paths, execution phases and dispatch evidence,
  dedicated synchronization traces, ordering proof and counterexample checks.
  Keep these in `state_groups`, not just per-file prose.
- Issue register: every concrete suspect, including unconfirmed initial-pass
  observations and independently confirmed findings; use the fields and
  dispositions below.
- Current phase, exact remaining files/paths, blockers,
  and the next executable review step.
- Basic validation: command/manual method, source identity/configuration,
  outcome and diagnostics, and unavailable/unsafe checks with reasons,
  following `validation-and-semantics.md`.

Read `review-record-format.md` before creating the files. Python 3 is required
for the bundled validators and report generator; no third-party packages are
needed. These scripts check recorded consistency, not reading quality or
whether all defects were found. They are not a client-side enforcement hook:
do not claim that the runtime makes bypass impossible.

Persist suspects immediately, before switching files or verification tasks.
Update after each file, cross-file trace, disposition change, and before any
interruption. Append one complete issue snapshot with a consecutive sequence
number to `issues.jsonl` for each new issue or disposition/evidence change;
never rewrite the entire issue history. Flush the append before moving on.
Update `review.json` through a temporary sibling file, validate its JSON,
then atomically replace it. Use one writer; do not let parallel agents append
or replace these files concurrently. Read the saved record
back before phase transitions, continuation, and report reconciliation; do
not claim persistence on the strength of a proposed write alone.

If creating or updating the record fails, try a usable runtime-approved
session-local location outside the repository and report concrete failures.
If no such file can be persisted, treat this as a completion blocker and use
the interruption protocol. Do not silently fall back to conversation-only
or database-only tracking, claim unsaved progress is durable, or advance a
phase whose record was not saved.

### Issue register and dispositions

Keep these top-level sections in `review.json`: `schema_version` (3), `source`,
`inventory`, `file_checks`, `state_groups`, `traces`, `validation`, `progress`,
and `report_map`.
Issues live only in the adjacent `issues.jsonl`; the latest event for an ID
is its current state and earlier events preserve its history.
Use stable IDs for files/traces where referenced. For each `issues` entry
record:

| Field | Required content |
|---|---|
| `id` | Stable review-local ID such as `R001`; never renumber or reuse |
| `origin` | Initial pass or cross-file trace, with file and location |
| `summary` | Concise suspected or confirmed invalid behavior |
| `evidence` | Source locations and observed facts, not source bodies |
| `open_questions` | Missing facts needed for verification |
| `dependencies` | Relevant functions, resources, shared state, and contracts |
| `trace_ids` | Linked cross-file tasks, if required |
| `next_check` | Executable verification step while pending or blocked |
| `status` | `pending`, `confirmed`, `dismissed`, `blocked`, or `merged` |
| `disposition` | Evidence-backed reason for the current disposition |
| `merged_into` | Surviving issue ID for a merged duplicate; otherwise null |
| `seq`, `updated_at` | Consecutive per-ID event sequence and update timestamp |

Confirmed events additionally require `location`, `severity`, `axis`, `cause`,
`recommendation`, and `rule`, sufficient to render the final finding without
reconstructing it from conversation. `cause` must contain the trigger and
invalid behavior. Do not promote a pending item just to make a report pass.

New suspects start `pending`; immediately verified defects may start
`confirmed`. Close a pending item only with evidence: `confirmed` for a
demonstrated defect, `dismissed` for a disproved suspicion, `blocked` for a
specific unresolved dependency, or `merged` for the same root cause already
represented by another issue. Lack of evidence is not a dismissal reason.
Preserve all events, including dismissed and merged items.
Merging must preserve distinct triggering conditions and independently
supported impacts; do not merge merely because symptoms or files are similar.

When new code evidence changes an ownership, scheduling, state, or interface
contract, inspect `dependencies` and reopen affected dispositions as `pending`.
Invalidate affected file checks and traces, record the reason, and revisit
only dependent evidence. The initial pass is coverage, not a permanent
declaration that a file is defect-free.

## 2. Enforce phase transitions

**Inventory gate:** reconcile discovered sources with build inputs and
conditional variants. Do not count unreadable or unexplained files as excluded.
Uncertainty about the inventory is an open limitation, not a smaller denominator.

**Initial-pass gate:** complete the four checks for every in-scope file before
the concentrated cross-file phase. Work in manageable batches, saving progress
after each batch and continuing without asking the user to authorize every
batch. If a file is inaccessible, mark it blocked, review other accessible
files, and keep the gate open. Local call following and verification of an
urgent suspected defect are allowed, but return to pending file coverage.
Before handoff, read back the record and reconcile each file's observations
with issue IDs. Every issue needing cross-file evidence must link to a trace,
and each suspect-driven trace must link back to its issues. Pending issues
may cross this gate; an inspected file does not imply those issues are closed.
Reconcile each mutable-state observation with a state group and dedicated
trace, including groups not yet known to be defects. Initial shared-state
`inspected` means discovery and handoff, not a safety verdict. Use explicit
no-state reasons when the list is empty; do not silently omit groups.
Run the validator with `--gate initial` before concentrated integration
(see the complete commands in `review-record-format.md`). A nonzero exit
means return to the reported gap, not skip the gate.

**Integration gate:** reconcile cross-file calls, shared state and resources
identified across all files. Trace normal/error behavior and startup, refresh,
shutdown, and asynchronous ownership where applicable. Resolve queue items
as verified or finding with evidence, or record a concrete blocker.
Do not treat inspected file counts as proof of integrated path coverage.
Update linked issue dispositions and perform dependency-triggered revisits
before declaring the integration complete.
Run the validator with `--gate integration`. Pending or blocked traces and
issues keep this gate open; do not relabel an unresolved suspect as dismissed.
Pending/blocked state groups also keep it open. Verified groups require
classified accesses, complete access inventory, a covering ordering proof
and a recorded counterexample check. Finding groups require a confirmed
synchronization issue; capacity or allocation findings are not substitutes.
Counts for files, traces and registered state-group closure are independent.

**Completion gate:** inventory is reconciled, every in-scope initial pass is
complete, validation outcomes/limitations are recorded, and identified
material cross-file questions are resolved. Missing tooling alone is not a
completion blocker; an unresolved material question remains one. Any
remaining material blocker means the requested review is incomplete, even
if all file contents were read. Document minor non-blocking limitations
without promising exhaustive defect detection.

**Issue/report gate:** read the saved record and account for every issue.
Resolve pending items; material blocked items mean the review is incomplete.
Document any minor non-blocking limitation explicitly rather than dismissing
it without evidence. Every confirmed issue must map to exactly one report
entry in `report_map`, and every report entry must reference a confirmed
issue. Merged IDs must resolve without cycles to a surviving issue; if that
issue is confirmed, its report mapping also accounts for its merged IDs.
Dismissed issues require evidence-backed reasons and stay in the record,
not the defect report. Save and read back the reconciled report mapping
before issuing the final answer. Use
`python3 <skill-dir>/scripts/generate_review_report.py <review.json>` to build
the mapping and report deterministically. It refuses a complete report if
integration is incomplete, updates the session record atomically, reads it
back, and runs the final gate. Deliver its report without freely rewriting,
dropping, adding or regrouping findings from memory. For an actual interruption
only, record `progress.interruption` and use `--partial`; this renders confirmed
findings only and never claims completion. A malformed record must be repaired
from evidence, not bypassed with hand-written final output. If the record or
tool cannot be accessed, explicitly report that blocker without claiming
completion or successful generation.

Re-read the ledger before the final answer. Several findings, elapsed effort,
an arbitrary file/tool-call quota, or reaching the end of one batch do not
satisfy a gate. Reporting incomplete coverage is not permission to stop.

## 3. Handle real interruptions

Continue while useful work within scope is possible. A final partial report
is appropriate only for a user stop, an observed access/dependency failure
that prevents completion after reasonable alternatives, or an explicitly
reported/enforced runtime/context limit. Do not invent a timeout or context
limit from task size or subjective effort. If an interruption gives no chance
to save progress, do not claim a checkpoint exists.

For a blocker affecting one path, finish other accessible work first unless
the user or runtime has stopped execution. Do not bypass access controls.

Use the parent skill's `评审状态：未完成（阶段结果）` header regardless of
whether findings already exist. Include:

```text
中断原因：具体失败/限制、尝试过的处理、阻塞的阶段或路径。
评审范围：发现 N 个实现文件，纳入 M 个，排除 E 个及原因；
          已完成初审 K/M；跨文件追踪的完成情况和未决项。
待续范围：准确列出剩余文件/路径；较长清单可引用已保存的完整记录。
续接记录：会话记录文件的绝对路径（无法保存时如实注明）；下一项检查。
```

These fields accompany verified findings, not speculative findings for unread
files. Never call the partial result a complete module conclusion.

## 4. Resume safely

Load the checkpoint, verify target/scope/variant and source identities, and
reconcile the inventory. Changed files invalidate their checks and dependent
cross-file traces; new files enter the pending queue. Preserve unaffected
verified work instead of restarting the same early files. If source identity
cannot be established, revalidate affected evidence rather than trusting
stale coverage counts. Continue from the next pending item until the gates
pass or a genuine interruption occurs.
Load pending/blocked issues and merged-ID mappings from the record file, not
from recollection. Reopen confirmed or dismissed issues whose evidence or
dependencies changed, preserving their IDs/history and invalidating affected
report mappings until verified again.

After any compaction or continuation, load both files, verify source identity,
then run `validate_review_record.py <review.json> --gate progress` before new
analysis. Its output derives coverage counts and remaining files; do not
maintain handwritten copies in `progress`. Repair invalid records and restore
unpersisted observations only by rechecking their evidence. Resume the first
remaining file, then unresolved traces/issues; reading the ledger alone is
not a successful resume. Re-run initial/integration gates before reporting.
