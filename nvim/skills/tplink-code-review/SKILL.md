---
name: tplink-code-review
description: >-
  Perform evidence-based code reviews using TP-LINK embedded Linux and C/C++
  engineering rules, including mandatory resource and lock lifecycle closure.
  Use whenever the user asks to review a full file, module, code, diff, staged changes,
  commit, Gerrit change, Change-Id, or patchset against TP-LINK standards, or
  requests a TP-LINK-style security, correctness, or stability review. Review
  only the requested scope, report actionable defects in Simplified Chinese,
  and never modify the reviewed code.
compatibility: Requires repository/file access and Git for local diffs; full-source review tools require POSIX and Python 3; Gerrit retrieval requires Python 3.8+, HTTPS access and GERRIT_AUTH_NAME/GERRIT_AUTH_TOKEN HTTP credentials.
---

# TP-LINK Code Review

Review behavior, not just style. Keep reviewed code read-only: do not edit
source/configuration files, generate patches, commit, install dependencies, or
claim checks ran unless they actually did. Save internal full-source review
progress outside the reviewed repository in the runtime-provided session
directory. Full-file and module reviews share the full-source route. Write their
reports as `YYYY-MM-DD-Target-评审报告-v1.md` in the working directory where the
review starts, even if it is inside that repository; this report is the only
permitted review output there. Target is the full filename (including extension)
for a file, or the module directory name. Other reviews report in chat.

## 1. Resolve the exact source

| Input | Source of truth |
|---|---|
| Pasted diff/patch | Supplied diff and necessary supplied context |
| Full file/full buffer without revision | Complete specified current file and necessary supporting context; full-source route |
| Selection, line range, pasted function/code excerpt | Specified current fragment and minimum context; narrow route |
| Module/subsystem without revision | Current implementation, local headers, build/configuration and relevant tests |
| Repository review without target/revision | Staged diff only: `git diff --cached` |
| Commit/hash/ref | Selected commit against its first parent |
| Gerrit URL/change/Change-Id/patchset | Exact requested patchset, retrieved using `scripts/fetch_gerrit_patch.py`; read `references/gerrit-retrieval.md` first |

Resolve ambiguous module names before reviewing. A module request is not a
diff review and needs no staged changes. A full-file request is a full-source
review whose target inventory contains exactly that file, not its directory.
A buffer follows the file route only when the whole file is requested and its
complete content is accessible; selections and pasted excerpts remain narrow.
If unsaved buffer content differs from disk, materialize the selected snapshot
and necessary supporting context in session storage before initializing its
record. Hash the selected content, not the disk version; if the full snapshot
cannot be obtained, report the limitation rather than silently switching source.
Do not substitute the worktree for
a selected index/commit/patchset or fall back to local code after Gerrit
retrieval failure. Read surrounding revision context from the same snapshot.
For change reviews, report only introduced defects or old defects whose
reachability/behavior the change materially alters. File/module reviews cover
the requested current implementation without implying change attribution.
Follow neighboring callers only to establish a concrete target contract.
Keep target files separate from supporting files. Reading a header, caller,
configuration or test does not add it to full-source coverage or authorize an
independent audit of it. Report only defects in, or concretely involving, the
requested target. Do not widen snippets or change reviews to full-source review.
For Gerrit, the bundled script is the retrieval implementation; use its verified
manifest and REST diff rather than repeating manual fetch commands. The default
downloads no Git object store or full source tree. Read `patch.diff` first;
request only necessary same-revision/first-parent files with
`scripts/fetch_gerrit_context.py`, following the retrieval reference. Do not treat
diff context as sufficient when a finding needs a complete function or caller.
Gerrit query, patch download and context retrieval use authenticated REST only;
they require `GERRIT_AUTH_NAME` and `GERRIT_AUTH_TOKEN` and never use SSH, Git
fetch, browser cookies, or local worktree content as a fallback.
Do not delegate retrieval to `gerrit-code-review`: its separate retrieval and
generic failure instructions do not apply to this skill's Gerrit route.

If Gerrit retrieval fails, stop and report the script's actual diagnostic in
Simplified Chinese using this structure (replace placeholders, do not print them):

```text
结论：无法评审
阶段：<diagnostic.stage 的中文说明>
目标：<diagnostic.endpoint；未解析端点时写用户指定的目标>
原因：<diagnostic.error 中的具体错误，保留关键原始错误文本>
```

Include the exit code or HTTP status when returned, and the HTTP diagnostic path
when available. Required-context failures must report their actual stage and
error too; never substitute worktree/latest-branch content or claim completion.
Never replace a concrete
timeout, authentication, missing-patchset or SHA-mismatch error with
a generic connection/permission hint. Include the attempt count, elapsed time,
and `diagnostics` path when returned. Do not infer server-side root cause from
an HTTP timeout.
The script owns transient REST query retries; do not restart the whole script
automatically after they are exhausted.
Redact credentials, tokens and cookies;
do not invent a root cause beyond the observed error. If the script cannot run,
name the failed tool/path and its actual error. Do not review partial artifacts
or fall back to the worktree.

If no target/revision or valid staged diff exists, return exactly:

```text
结论：无法评审
原因：未提供有效的 Git diff，请先暂存变更或指定一个 Git commit。
```

Stop these failure routes before loading review references or scanning code.

## 2. Load only the applicable instructions

| When | Read |
|---|---|
| Any resolved review, before deep tracing | `references/validation-and-semantics.md` |
| C/C++ or requested TP-LINK enterprise criteria | `references/tplink-c-review-rules.md` |
| Every C/C++ review, regardless of review route | `references/resource-lifecycle-review.md` (mandatory lifecycle-closure gate) |
| Full-source review (full file or module), before inventory/initial pass | `references/module-review-completion.md` |
| Every full-source review, during per-file discovery and site verification | `references/input-boundary-review.md` |
| C/C++ target defines mutable global/file-scope state, or uses multiple contexts/async lifetimes | `references/concurrency-review.md` |
| Snippet or change review, when preparing output | `references/report-format.md` |
| Full-source record commands | `references/record-tools.md` |
| Large search results or gate diagnostic pagination | `references/tool-output.md` |
| Hand-editing, migration or unfamiliar record fields only | Relevant section of `references/review-record-format.md` |

Do not preload all references, scripts, tests or evals. References own their
respective protocols; do not reconstruct duplicate checklists. Full-source
output comes from the generator, not the narrow-route output reference.
Snippet and change reviews do not require a full-source ledger or its gates.
Return scoped search locations/short context and use bounded source ranges;
expand for actual verification, never truncate required coverage. For large
results use the output reference's counted pages, not silent `head` clipping.

## 3. Inspect and verify

Understand purpose, inputs/outputs, normal/error paths, important interfaces,
resource ownership and mutable state. Use breadth before concentrated deep
tracing. Prioritize correctness/control flow, memory/resource lifetime,
concurrency/reliability, inputs/interfaces, then actionable enterprise rules.
Apply semantic quick checks and the smallest safe non-fixing validation
against the selected source. Tool unavailability alone does not stop review.

For every C/C++ review, complete the resource-lifecycle audit in
`references/resource-lifecycle-review.md` before finalizing, even when the
request is a single file or no concurrency issue is initially apparent. Keep
the audit within the selected review scope; for change reviews, findings must
still be attributable to the selected change under §1.

For every C/C++ file or module review, inventory mutable global and
file-scope `static` state in the selected source before deciding whether
concurrency review applies. For each candidate, search the scoped repository
for its definitions, declarations, reads, writes, and address passing; trace
relevant callers, callback registrations, and dispatch paths outside the
target file. Map protocol/configuration field names and locals to the actual
shared object they update (for example, a UBUS `auth_state` field may be
assigned to a global named `fing_auth_status`). Load
`references/concurrency-review.md` and close each relevant access group using
its evidence requirements. This is a targeted identifier/call-path trace, not
permission to scan unrelated repository code. For diff reviews, use the
inventory to find relevant access paths but report only defects introduced or
materially affected by the selected change.

### Code-selection closure gate (C/C++)

For code-selection and excerpt reviews, complete and internally reconcile this
compact evidence checklist before writing the final answer. This is a review
gate, not a requirement to add a user-facing checklist or full-source ledger.
Apply it to the selected fragment and necessary context, not the whole file:

1. **Shared-state access intervals:** For every mutable global or file-scope
   `static` object, account for each scoped read, write, address escape, and
   caller/execution context. Verify that synchronization covers the entire
   conflicting access interval. In particular, inspect reads, resets, and
   counters before a later lock acquisition; a lock acquired later does not
   protect earlier accesses. Include timer re-submission, queued work, worker
   overlap, callbacks, and runtime refreshes where applicable. Use
   `references/concurrency-review.md`; record unresolved context as a material
   limitation rather than assuming safety.
2. **String and buffer boundaries:** Enumerate relevant `strncpy`, `sscanf`
   conversions (especially `%s` and scansets), `strcpy`, `strcat`, `sprintf`,
   `gets`, and bounded alternatives in the selected code. For each, verify the
   actual input maximum, destination capacity, terminator space, parse
   conversion count, and handling of truncation or malformed input. A bounded
   function is not automatically safe if its size or result is wrong; an
   unbounded-looking call is not a finding until its reachable input and
   impact are established.
3. **Resources and return values:** Inventory allocations, file/process
   handles, locks, registrations, and other acquired resources; trace every
   applicable normal and error exit to a release or ownership transfer.
   Separately inspect meaningful return values from calls and helpers through
   their callers. Confirm failures are not ignored, converted to success, or
   followed by destructive cleanup such as deleting retryable input.
4. **Disposition:** Before finalizing, mark each candidate internally as
   closed, confirmed, or unresolved, with its source/caller evidence. Report
   confirmed defects only; state material unresolved items in `评审范围`.
   Do not treat reading a file or running a parser as proof that these checks
   are complete. Full-file and module reviews use the shared inventory and
   integration gates in `references/module-review-completion.md`, including
   the same string-boundary and return-value checks during their initial pass.

For full-source reviews, enumerate and close the risk call sites under
`references/input-boundary-review.md`. File-wide evidence and shared-state
closure do not replace string, conversion, structured-input or allocation/I/O
site checks. Initial completion requires evidenced discovery for all categories;
integration requires each registered site's disposition and concrete proof.
Use tool-extracted exact call anchors and per-scenario dispositions, not grouped
function/file ranges. When prior reports are supplied, import and reconcile every
old finding; explain withdrawals and severity changes. Distinguish standards
violations, demonstrated runtime failures and proven downstream impact.

Search scoped repository standards and established conventions. Apply explicit
repository rules before generic heuristics. For change reviews, also check
user-supplied requirements, linked issues and directly relevant documentation
when accessible. Standards and Spec are separate reasoning axes, not separate
agents; do not invent requirements or scan unrelated revisions for a spec.
Use both report axes only when an actual spec is available, without duplicating
one root cause. A Spec finding is a confirmed requirement violation; verifying
that a requirement is met adds no finding.

Before reporting each suspicion:

- Establish the trigger and invalid behavior from source and caller contracts.
  Inspect nearby validation, cleanup and synchronization before alleging absence.
- Verify selected-source attribution and actual build flags for diagnostics.
  Parser success does not prove semantic correctness; missing host dependencies
  do not prove a supported-build regression.
- For C/C++ lifecycle findings, verify acquisition, ownership, every applicable
  exit path, and the matching release or RAII cleanup. Resolve lock/resource
  macros and their active build variants; for lock failures, follow the caller
  far enough to establish blocking or other consequences.
- For races, establish conflicting accesses, at least one write, actual
  scheduling contexts and missing ordering. Prove any additional crash,
  overflow or exploitation claim separately.
- Deduplicate by root cause. Recommend the smallest concrete repair, not a patch.
  Names, smells, generic test absence and guessed costs are leads, not defects.
  Architectural/performance/reuse findings need a concrete contract or cost.
- Before concluding there are no findings, make a separate standards pass over
  changed lines: check added/modified identifiers against applicable naming
  rules, and changed control statements and macros against their specific rules.
  Report only verified, attributable violations. A generic smell remains a
  lead, but a confirmed mismatch with an explicit TP-LINK rule is actionable
  (usually Low) even without runtime impact. If a documented repository
  exception or conflicting local convention applies, cite it and explain the
  precedence; do not silently omit a confirmed mismatch.
- For each finding, keep category tags separate from its rule basis. Cite the
  stable TP-LINK rule ID and exact clause when directly applicable; cite
  project contracts with source/caller locations separately. Never force a
  broad clause onto behavior it does not specify.
- Use the lowest supported severity: Critical for highly likely catastrophic
  failure; High for common-path security/corruption/deadlock or serious failure;
  Medium for meaningful boundary/error-path failures; Low for limited,
  actionable maintainability or enterprise-rule violations.

Do not turn uncertainty into a low-severity finding. Conditional failures need
not reproduce on every run, but their trigger and invalid behavior need evidence.
Never invent locations, ownership, business rules, runtime facts or check results.

## 4. Complete the selected route

For full-source reviews, follow the completion reference through inventory,
four-dimensional file coverage, integrated traces and issue reconciliation.
A full-file inventory stays at one target; integration may use supporting files
without promoting them to targets. Reuse stable evidence
and dependency IDs through the record tools rather than re-reading shared paths.
Do not stop at a findings quota or confuse inspected files with proven paths.
After compaction, use the validated recovery working set, verify source identity,
then continue the first unfinished task; do not dump the historical journal.
Deliver the generated full-source report as a file, with only its path and review
status in chat. For continuations, update the same report at each handoff and
on completion until it says `评审状态：已完成`; keep its original date and `v1`
filename rather than creating a new report per turn.
Preserve the original working-directory destination even if a continuation
starts in a different directory; do not run the generator from the skill directory.

For snippets and change reviews, retain the narrow source boundary and render using
`references/report-format.md` directly in chat, without creating a report file.
Write explanatory prose in Simplified Chinese;
preserve paths, symbols, commands and excerpts verbatim. Report material limits
honestly, without generic summaries, praise, checklists or internal reasoning.

When the user supplies a prior review report or explicitly asks to compare
reviews, reconcile every prior finding against the current source and selected
build/revision before finalizing. Classify each item as:

- **保留** — the defect is still confirmed; cite current evidence.
- **撤回** — current evidence disproves the prior finding; state the specific
  counterevidence rather than silently dropping it.
- **本次新增** — a confirmed current finding absent from the prior report.

If evidence is insufficient to decide an item, mark it **待确认**, explain
what evidence is missing, and do not mislabel it as withdrawn. Keep this
reconciliation separate from defect attribution: a prior report does not make
a defect current, and a defect omitted previously is not automatically new.
Do not search unrelated historical reports unless the user asks for that
comparison or provides them as context.

For all C/C++ routes, do not conclude the review or report a clean result until
the lifecycle-closure gate is complete. If an ownership contract, macro
expansion, or build variant needed to close a path is inaccessible, state that
specific limitation rather than assuming cleanup or lock behavior.
