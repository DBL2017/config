---
name: tplink-code-review
description: >-
  Perform evidence-based code reviews using TP-LINK embedded Linux and C
  engineering rules. Use whenever the user asks to review a module, code,
  diff, staged changes, commit, Gerrit change, Change-Id, or patchset against
  TP-LINK standards, or requests a TP-LINK-style security, correctness, or
  stability review. Review only the requested scope, report actionable
  defects in Simplified Chinese, and never modify the reviewed code.
compatibility: Requires repository/file access and Git for local diffs; Gerrit reviews require the repository's configured SSH access or an explicit Gerrit URL.
---

# TP-LINK Code Review

Review behavior, not just style. Establish the exact requested source first,
trace enough surrounding code to verify each suspected defect, and report only
problems that the supplied evidence demonstrates or strongly supports. Keep
the reviewed repository read-only: do not edit its files, create patches,
commit, or claim tests were run unless they actually were. Module-review
progress and issue records must be saved in session-local files outside the
reviewed repository, not kept solely in conversation context.

## 1. Establish the review scope

Use the narrowest source explicitly requested. A request to review a module
means a review of that module's current code, not merely its latest commit or
diff. Do not substitute the current working tree for an explicitly requested
commit or Gerrit patchset.

| User input | Source of truth |
|---|---|
| Pasted diff or patch | The supplied diff |
| Explicit file(s), code selection, or buffer | The specified code; read only directly needed context |
| Named module or subsystem, without a revision | The current module implementation and its directly relevant local headers, configuration, and tests |
| No target or revision specified for a repository review | The staged diff from `git diff --cached` only |
| Commit, hash, or ref | That commit's diff against its first parent |
| Gerrit URL, change number, Change-Id, or patchset | The exact requested Gerrit patchset |

- Treat explicit module requests as **module reviews**, even if the user
  mentions the repository's current changes generally. Do not require staged
  changes or a commit for this mode.
- Resolve a named module to its implementation files using explicit paths,
  repository structure, build/configuration references, and local conventions.
  If the module name maps ambiguously to multiple components, ask which one
  before reviewing. If a module path is given, use it as the scope boundary.
- Review the module's current code, including relevant files outside Git's
  diff. Include directly related headers, configuration, and tests when needed
  to understand behavior or contracts. Inspect callers or neighboring modules
  only as far as needed to verify a concrete interface or data-flow issue;
  do not expand into a repository-wide audit.
- In module-review mode, report confirmed defects in the requested module
  whether or not they were introduced by a particular commit. Do not imply
  that a finding is newly introduced unless a relevant diff proves that.
- For staged review, do not use unstaged changes, untracked files, other
  commits, or the full worktree as review evidence.
- For commit review, read surrounding code from the selected commit snapshot,
  not from a potentially different worktree version.
- For Gerrit review, use the `gerrit-code-review` skill to resolve and fetch
  the exact target. Apply this skill's TP-LINK criteria to that retrieved
  patchset; never fall back to a local diff if Gerrit retrieval fails.
- For an explicit file or code selection, review only that target and the
  minimum context needed to understand its behavior. Do not silently turn it
  into a repository-wide audit.
- For diff, commit, and Gerrit reviews, report only defects introduced by the
  diff or pre-existing defects made reachable or behaviorally different by
  it. For whole-file and module reviews, review the requested current source,
  not only changes made in a diff.
- If a requested Gerrit diff cannot be retrieved, return exactly:

  ```text
  结论：无法评审
  原因：无法获取指定 Gerrit change/patchset 的有效 diff，请检查连接、权限或 patchset。
  ```

- If a repository review has no valid staged diff and no explicit target or
  revision, return exactly:

  ```text
  结论：无法评审
  原因：未提供有效的 Git diff，请先暂存变更或指定一个 Git commit。
  ```

Do not invent line numbers, business rules, runtime behavior, ownership
contracts, test results, or environmental facts. If a conclusion depends on
missing context, either omit it or state the specific uncertainty in the
review scope.

## 2. Review the behavior

First understand the target code's intent, inputs and outputs, callers, state
transitions, error paths, and resource ownership. Use a breadth pass before
deep tracing so early findings in a large file do not hide defects in smaller
helpers. Check both normal and failure paths, including boundary values.

### Basic validation and semantic checks

After resolving the target, read `references/validation-and-semantics.md`.
Identify applicable parsers/compiler checks and inspect their invocation
before running the smallest safe, non-fixing checks against the exact review
source. Do this before deep behavioral tracing when the required context is
available; validation does not replace the per-file coverage pass. If tools,
dependencies, or safe execution are unavailable, perform structured manual
checks, record the concrete limitation, and continue accessible review work.
Do not invent a build failure or stop solely because a checker is unavailable.

Apply the reference's semantic quick checks during each relevant file pass:
declaration/definition/call consistency, signed error returns, boundary math,
boolean/status direction, current versus stale variables, target objects and
fields, and state transitions. Use repository contracts and callers to verify
suspicions; names, comments, and checker warnings are leads, not proof.

### Coverage before conclusions

- For a module review, use the following staged workflow. The per-file pass
  makes coverage observable; the later cross-file pass preserves the context
  needed to find call-chain, ownership, and concurrency defects. Do not treat
  files as isolated units. Read `references/module-review-completion.md`
  before starting; its stage gates and interruption protocol apply even when
  confirmed findings already exist.

1. **Inventory and count.** Enumerate the module's implementation files and
   local contracts, cross-checking build inputs, conditional sources, and
   user-supplied paths. Record the total file count. Mark generated/vendor
   files and inactive build variants as included, excluded, or not applicable,
   with a reason; do not silently skip a helper translation unit.
   Save the inventory and source identity in session storage before the
   per-file pass. Separate discovered, in-scope, and excluded counts.
2. **Review each file once.** Visit every in-scope implementation file and
   perform an initial pass for its purpose and entry points, functional and
   error paths, important callees/callers, acquired and released resources,
   and mutable shared state. Record per file whether this pass is complete,
   blocked, or excluded with reason. Follow direct calls enough to understand
   the local contract, but do not duplicate deep tracing of a shared path in
   every file. Finish this pass across the inventory before concentrated
   cross-file tracing. If an urgent suspect needs immediate verification,
   record it and then return to the next pending file; it is not an exit.
   Persist every concrete suspect and confirmed finding with a stable issue
   ID before moving to another file. Pending verification does not prevent
   completing a file's initial pass; link it to the cross-file queue instead.
   Persist each mutable state group in `state_groups` and link it from each
   relevant file's `shared_state_context.state_group_ids`. An initial
   `inspected` state check means discovery is complete, not synchronization
   is proven. Empty inventories need an evidence-backed `no_state_reason`.
3. **Integrate cross-file paths.** Connect the calls and state surfaced by
   the per-file pass. Trace important end-to-end behavior, ownership
   transfers and cleanup, and shared-state accesses through callers, aliases,
   getters, and helper files. Build execution contexts from actual
   registration/startup sites: event-loop callbacks, workers, explicit
   threads, timers, notifications, and signal/interrupt handlers where
   present. Confirm who schedules each callback; do not infer its thread from
   its name. Use `references/concurrency-review.md` for shared-state and
   asynchronous-lifetime checks.
   Give each state group a dedicated `kind: shared_state` trace; capacity
   and allocation findings do not close its synchronization question.
   Before accepting initialization-only, single-context, or protected-access
   explanations, inspect every discovered writer call path, callback
   registration and worker dispatch, then seek counterexamples. Persist
   access classification and the safety proof, not just a conclusion.
   Unresolved indirect calls or build contexts keep the group pending.
   Update the persisted issue status and evidence after each verification.
   If a newly established contract contradicts an earlier assumption, reopen
   affected dismissed issues and revisit dependent checks.
4. **Close coverage gaps.** Reconcile the ledger against the inventory and
   revisit every unreviewed file and unresolved important path. A symbol
   search is not inspection, and a file pass is not proof that a cross-file
   path was traced. Finding several serious bugs is not a stopping criterion;
   do not impose an arbitrary findings quota. If scope or context limits
   prevent completion, identify the remaining files or paths instead of
   implying a complete review.
   Reconcile all recorded suspects and confirmed findings with their
   dispositions and final-report entries; file coverage alone is not enough.

### Manual verification and runtime blockers

A failed agent request, policy block, or HTTP 4xx/5xx response establishes only
that the tool call did not complete. It does not establish that the source
path cannot be reviewed, nor does it justify attributing every unfinished item
to one "protocol-identification partition." Record the event as a runtime
blocker, then verify the affected items individually using the procedure
below. If the source and local review record remain accessible, continue the
analysis directly rather than waiting for the agent to recover or resubmitting
the same task.

For each pending or blocked trace, issue, and `state_group`, record auditable
details:

- `blocker_type`: `agent_transport`, `tool_access`, `source_context`, or
  `reviewer_stop`; do not use a vague label such as "tool restriction."
- The raw error text, time, request/agent ID, tool invoked, and affected record
  IDs. If the original diagnostic is unavailable, state
  `raw_diagnostic_unavailable`; do not guess the triggering rule, risk policy,
  or conditions for clearing the block.
- `next_check`: an actionable check that a reviewer or the current session can
  perform. Avoid vague steps such as "continue tracing."
- `closure_evidence`: the source locations, dispatch evidence, access
  classifications, synchronization/lifetime proof, or counterevidence needed
  to resolve the item.

Perform manual verification in this order, recording source locations for
each step in `evidence`:

1. **Rebuild the object inventory.** List the functions, global/static
   objects, aliases, fields read or written, and known files involved in the
   trace. Use `rg` or editor references to find direct accesses and call sites;
   record generated code and inactive conditional-build branches that are
   excluded, with reasons.
2. **Rebuild call paths and execution contexts.** Follow calls from entry
   points, registration and startup sites, workers/threads, timers, event
   callbacks, and shutdown paths. For every callback or worker, record both
   registration and actual dispatch/execution evidence; do not infer a thread
   from a function name.
3. **Check normal, failure, and lifetime paths.** Inspect initialization,
   refresh, error returns, cancellation, retry, shutdown, release, and
   reentrancy. For each resource or object, record who acquires, uses, and
   releases it, and the ordering around release.
4. **Verify shared state separately.** For each `state_group`, list every
   writer and reader, including write/write conflicts, and classify its
   `startup`/`runtime` phase, context, and access kind. Then establish one
   applicable proof: `initialization_only`, `single_context`, `common_lock`,
   `snapshot`, `atomic`, or `ownership`. A lock name or an assumption that
   code "usually runs on the main thread" is not proof. Cite synchronization,
   publication, or ownership evidence for both sides, and complete the
   `runtime_writers`, `async_dispatch`, and `synchronization_both_sides`
   counterexample checks.
5. **Record an item-level disposition.** If the trigger and invalid impact are
   demonstrated, update the item to `confirmed`/`finding`. If source evidence
   disproves the concern, update it to `dismissed`/`verified`. If evidence is
   missing, keep it `pending`/`blocked`, state the specific gap in
   `next_check`, and do not present incomplete verification as "no issues
   found."

The report's "remaining work" must list each unresolved trace/state-group ID,
file/symbol, current blocker, `next_check`, and `closure_evidence`. If the
only failure was agent communication and source access is intact, state that
"the agent request failed, but source verification can continue directly";
do not make "these traces cannot currently be completed" the sole conclusion.
Treat an item as blocked from manual review only when the source, a relevant
build variant, caller, or dispatch evidence is genuinely inaccessible. In that
case, list the access methods attempted and the specific input needed to
resolve the dependency.

Keep coverage in session-local `review.json` and append full issue-state
events to the adjacent `issues.jsonl`, not in the reviewed repository or
only in conversation context. Use the version-3 schema, validation commands,
and write/read-back protocol in
`references/module-review-completion.md`. Record per-file functional,
call/interface, resource, and
shared-state checks with evidence locations, pending cross-file traces, and
exclusions/blockers. Update it after each file and each integrated trace.
Resume from it only after verifying source identity and invalidating entries
affected by source changes. File counts measure initial coverage, not proof
that all behavioral paths or synchronization contracts were verified.
Shared-state closure is counted separately. The validator checks evidence
structure and links, not the truth or completeness of the recorded call graph.
After compaction, reload both files and run the progress validator before
resuming the first unfinished item. Run initial/integration gates at their
phase boundaries. Generate module reports only through
`scripts/generate_review_report.py`; a rejected gate means continue the review
or document a real interruption, not compose a substitute final report.
For file, diff, commit, and Gerrit reviews, retain their narrower scope rules:
do not expand them into a whole-module audit. In diff/revision reviews,
include only relevant changed
files and behavior in the ledger; use surrounding code only to verify the
changed behavior and contracts.

Follow callers or neighboring code only to resolve a target state, interface,
or lifetime contract. Cross-file access tracing is necessary context, not
permission for a repository-wide audit. Use the selected snapshot for all
such evidence in revision/diff reviews.

Prioritize:

1. **Correctness and control flow:** incorrect conditions, boundary errors,
   invalid state transitions, broken error handling, unchecked return values,
   unintended fall-through, or regressions.
2. **Memory and resource lifetime:** out-of-bounds access, integer overflow or
   underflow, null/dangling pointers, use-after-free, double free, missing
   cleanup, leaked files/locks/references, and incorrect asynchronous,
   callback, interrupt, or RCU lifetimes.
3. **Concurrency and reliability:** data races, lock-order inversions,
   deadlocks, unsafe reentrancy, stale state, and failure paths that leave
   state inconsistent.
4. **Inputs and interfaces:** unchecked parameters, global/file/hardware
   inputs, lengths, indexes, counts, enums, flags, protocol fields, ownership
   and byte-order contracts, unsafe conversions, and unintended interface or
   configuration changes.
5. **Security:** trace untrusted or externally influenced input to a concrete
   impact such as command injection, path traversal, format-string misuse,
   permission bypass, or unsafe deserialization. Do not label a theoretical
   concern exploitable without an evidence-based path.
6. **TP-LINK engineering rules:** apply the relevant items in
   `references/tplink-c-review-rules.md`. Focus on the requested target and
   treat stylistic violations as findings only when they are clear,
   actionable, and proportionate to their impact.

Use project conventions when they are visible and consistent with the
requested rules. Do not demand unrelated refactors, speculative defensive
checks, or changes outside the review scope.
For architecture, performance, test, and reuse concerns, verify a concrete
contract or cost: changed dependency/ownership boundaries, supported size or
frequency, blocking in a constrained execution context, or a demonstrated
missing regression case. Prefer existing helpers only when their semantics
and ownership match. Do not turn generic design principles, complexity
guesses, or test absence alone into defects.

## 3. Check repository standards and intended behavior

For change reviews, perform two complementary checks when the evidence is
available:

### Standards

- Identify relevant standards in the repository, prioritizing files such as
  `CODING_STANDARDS.md`, `CONTRIBUTING.md`, module-specific guidance, and
  established local conventions. Search only the requested repository and
  scope. Read standards documents as review criteria, not as evidence that
  code was changed.
- Apply the repository's explicit rules before general heuristics. Apply
  `references/tplink-c-review-rules.md` as the TP-LINK baseline when relevant;
  do not claim organizational style rules are C language requirements.
- Treat common code smells (for example, duplicated logic, overly indirect
  code, or speculative abstractions) as prompts to inspect, not automatic
  violations. Report them only when the reviewed change creates a concrete,
  material maintainability problem and the remedy is proportionate. Never
  recommend refactoring solely to satisfy a heuristic.

### Spec

- Look for the originating requirement in user-supplied issue/spec material,
  explicit issue references associated with the reviewed change, or relevant
  repository documentation. Use available repository tools or documented
  tracker workflows when access is configured.
- Check whether requested behavior is missing or partial, whether the
  implementation contradicts a requirement, and whether the change adds
  behavior outside the requested scope.
- A spec is a source of expected behavior, not proof that the implementation
  is wrong. Verify suspected mismatches against the actual code and report
  only actionable defects attributable to the reviewed change.
- If no spec can be found or accessed, continue the Standards review. Do not
  invent requirements or claim spec compliance; note the unavailable spec
  only if it materially limits the review.

Keep the evidence boundary intact: requirements may explain intended behavior,
but code findings must still be grounded in the selected diff for diff, commit,
and Gerrit reviews. Do not inspect unrelated commits, branches, or worktree
content merely to locate a spec. For module or whole-file reviews, assess the
current requested source and use any supplied spec as the behavior contract.

Keep Standards and Spec findings distinct in the report so one axis does not
hide the other. Do not duplicate one root cause under both axes. These are
separate reasoning checks; do not require parallel agents. When no
specification is available, do not fabricate a Spec section with inferred
requirements.

## 4. Verify and qualify findings

Before reporting a suspected issue:

- For a diff review, confirm the defect is in changed code or that the change
  makes its behavior newly reachable or materially different. For a module
  review, confirm it exists in the requested module's current code.
- Identify the triggering input, state, timing, or failure condition.
- Trace the consequence and explain why the behavior is incorrect or risky.
- Check nearby validation, cleanup, synchronization, and caller contracts
  before concluding they are absent.
- Confirm checker diagnostics against the selected source, effective build
  flags, and changed-line attribution where applicable. Missing toolchains or
  headers are validation limitations unless the reviewed code demonstrably
  breaks the supported build. Syntax-only success does not prove runtime
  safety or semantic correctness.
- For concurrency findings, establish two conflicting accesses, their
  execution contexts, at least one write, and why no common synchronization
  or ordering prevents overlap. Cite both sides in the cause, with a
  concrete possible interleaving or missing happens-before relationship.
  A global variable alone is not evidence of a race. Do not infer an
  out-of-bounds access, torn read, crash, or exploit merely from inconsistent
  state; prove the additional conditions separately.
- Prefer one finding per independent root cause. Do not report the same defect
  under multiple categories. For module reviews, retain merged issue IDs and
  their mapping to the surviving issue in the session record; do not delete
  suspects or confirmed findings when consolidating the report.
- Give the smallest concrete remediation direction; do not write a patch.
- Assign the lowest severity that accurately reflects likelihood and impact.

Severity guide:

- **Critical:** highly likely crash, arbitrary code execution, severe data
  corruption, resource exhaustion, or device unavailability.
- **High:** common-path security issue, memory corruption, deadlock, leak, or
  serious functional failure.
- **Medium:** boundary-case functional error, inconsistent state, missing
  error handling with meaningful impact, or a substantial stability risk.
- **Low:** a concrete but limited maintainability, readability, or TP-LINK
  standards issue.

Do not downgrade an unverified claim into a finding. If there is not enough
evidence to establish a defect, say what is uncertain only when it materially
limits the review.
Evidence can establish a conditional failure or a data race without a
deterministic crash on every run. Prove the trigger and invalid behavior;
do not require guaranteed reproduction or inflate a possible consequence.

## 5. Return the review

Write all explanatory prose in Simplified Chinese. Preserve paths, symbols,
identifiers, error codes, commands, and code excerpts verbatim.

The exact scope-resolution failure messages in section 1 take precedence.
Otherwise, for module reviews separate completion from the code verdict:

```text
评审状态：已完成
结论：通过
```

Use `已完成` only when the completion gate in
`references/module-review-completion.md` is met; the verdict can instead be
`需要修改`. For an actual interruption, use:

```text
评审状态：未完成（阶段结果）
当前结论：需要修改
中断原因：具体阻塞、已尝试的处理及其影响。
```

If there are no confirmed findings in an interrupted review, replace the
second line with `当前结论：尚不能判定`; never emit `通过` or an ordinary
final verdict for a partial module review. Report verified findings in the
normal issue format, then the scope line and continuation information
required by the completion reference. Do not stop merely to produce this
interim format while useful review work remains possible.

For non-module reviews, the first line remains `结论：通过` or
`结论：需要修改`. If material context cannot be reviewed and no confirmed
finding supports `需要修改`, use `结论：无法完成评审` and name the limitation.

For an ordinary review without an explicit or discoverable spec, retain the
existing single findings list, sorted by severity (Critical, High, Medium,
Low). For a change review with an available spec, use separate sections
`## Standards（规范符合性）` and `## Spec（需求符合性）`, including both
even when one axis has no findings; state `未发现明确问题。` under that
section. Sort each axis's findings independently by severity. Within either
layout, use this format for each issue:

```text
- [Severity] 文件:行号：问题标题
原因：说明风险及触发条件。
建议：给出最小、具体、可验证的修复方向。
规则：注明对应的评审类别或 TP-LINK 规范章节（如适用）。
```

For a diff review, use the changed line that best identifies the cause. For a
file or module review, cite the line in the reviewed current file. If a
reliable line number is unavailable, identify the function, code fragment, or
relative location; never guess.

If no clear issue is found in a completed ordinary non-module review, output:

```text
结论：通过
未发现明确的功能、安全、稳定性或规范问题。
```

For a completed module review without findings, precede those two lines
with `评审状态：已完成` and append the required scope line.

When missing context or unexecuted validation materially limits confidence,
append a concise final line:

```text
评审范围：说明无法确认的依赖、未提供的上下文或未执行的验证。
```

For module reviews, always append one concise `评审范围：` line reporting
the implementation-file count and initial-pass coverage (for example,
`已逐文件初审 12/12 个实现文件`), plus material exclusions, untraced paths,
or unreviewed files. Distinguish inspected files from cross-file paths
actually traced; do not claim full coverage based on search results alone.
If the inventory itself is incomplete, say so rather than presenting a
misleading denominator. Merge material limitations into this line rather
than duplicating them.

Do not add a general summary, checklist, praise, patch, or internal reasoning
to the prescribed result. Module completion status, scope, and required
interruption/continuation fields are not an internal reasoning transcript.
For module reviews, use the bundled generator's output, including its session
record path, rather than reimplementing these layouts manually.

For a two-axis review with no findings on either axis, use:

```text
结论：通过

## Standards（规范符合性）
未发现明确问题。

## Spec（需求符合性）
未发现明确问题。
```
