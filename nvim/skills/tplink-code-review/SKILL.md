---
name: tplink-code-review
description: >-
  Perform evidence-based code reviews using TP-LINK embedded Linux and C
  engineering rules. Use whenever the user asks to review a module, code,
  diff, staged changes, commit, Gerrit change, Change-Id, or patchset against
  TP-LINK standards, or requests a TP-LINK-style security, correctness, or
  stability review. Review only the requested scope, report actionable
  defects in Simplified Chinese, and never modify the reviewed code.
compatibility: Requires repository/file access and Git for local diffs; incremental module tools require POSIX and Python 3; Gerrit requires configured SSH access or an explicit URL.
---

# TP-LINK Code Review

Review behavior, not just style. Keep the reviewed repository read-only:
do not edit files, generate patches, commit, install dependencies, or claim
checks ran unless they actually did. Save module progress outside that
repository in the runtime-provided session directory.

## 1. Resolve the exact source

| Input | Source of truth |
|---|---|
| Pasted diff/patch | Supplied diff and necessary supplied context |
| File, selection, buffer | Specified current source and minimum context |
| Module/subsystem without revision | Current implementation, local headers, build/configuration and relevant tests |
| Repository review without target/revision | Staged diff only: `git diff --cached` |
| Commit/hash/ref | Selected commit against its first parent |
| Gerrit URL/change/Change-Id/patchset | Exact requested patchset, retrieved using `gerrit-code-review` |

Resolve ambiguous module names before reviewing. A module request is not a
diff review and needs no staged changes. Do not substitute the worktree for
a selected index/commit/patchset or fall back to local code after Gerrit
retrieval failure. Read surrounding revision context from the same snapshot.
For change reviews, report only introduced defects or old defects whose
reachability/behavior the change materially alters. File/module reviews cover
the requested current implementation without implying change attribution.
Follow neighboring callers only to establish a concrete target contract.

If Gerrit retrieval fails, return exactly:

```text
结论：无法评审
原因：无法获取指定 Gerrit change/patchset 的有效 diff，请检查连接、权限或 patchset。
```

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
| Module review only, before inventory/initial pass | `references/module-review-completion.md` |
| Shared mutable state, multiple contexts or async lifetimes | `references/concurrency-review.md` |
| Non-module review, when preparing output | `references/report-format.md` |
| Module record commands | `references/record-tools.md` |
| Large search results or gate diagnostic pagination | `references/tool-output.md` |
| Hand-editing, migration or unfamiliar record fields only | Relevant section of `references/review-record-format.md` |

Do not preload all references, scripts, tests or evals. References own their
respective protocols; do not reconstruct duplicate checklists. Module output
comes from the generator, not the non-module output reference. Non-module
reviews do not require a module ledger or module completion gates.
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

Search scoped repository standards and established conventions. Apply explicit
repository rules before generic heuristics. For change reviews, also check
user-supplied requirements, linked issues and directly relevant documentation
when accessible. Standards and Spec are separate reasoning axes, not separate
agents; do not invent requirements or scan unrelated revisions for a spec.
Use both report axes only when an actual spec is available, without duplicating
one root cause.

Before reporting each suspicion:

- Establish the trigger and invalid behavior from source and caller contracts.
  Inspect nearby validation, cleanup and synchronization before alleging absence.
- Verify selected-source attribution and actual build flags for diagnostics.
  Parser success does not prove semantic correctness; missing host dependencies
  do not prove a supported-build regression.
- For races, establish conflicting accesses, at least one write, actual
  scheduling contexts and missing ordering. Prove any additional crash,
  overflow or exploitation claim separately.
- Deduplicate by root cause. Recommend the smallest concrete repair, not a patch.
  Names, smells, generic test absence and guessed costs are leads, not defects.
  Architectural/performance/reuse findings need a concrete contract or cost.
- Use the lowest supported severity: Critical for highly likely catastrophic
  failure; High for common-path security/corruption/deadlock or serious failure;
  Medium for meaningful boundary/error-path failures; Low for limited,
  actionable maintainability or enterprise-rule violations.

Do not turn uncertainty into a low-severity finding. Conditional failures need
not reproduce on every run, but their trigger and invalid behavior need evidence.
Never invent locations, ownership, business rules, runtime facts or check results.

## 4. Complete the selected route

For modules, follow the completion reference through inventory, four-dimensional
file coverage, integrated traces and issue reconciliation. Reuse stable evidence
and dependency IDs through the record tools rather than re-reading shared paths.
Do not stop at a findings quota or confuse inspected files with proven paths.
After compaction, use the validated recovery working set, verify source identity,
then continue the first unfinished task; do not dump the historical journal.

For other reviews, retain the narrow source boundary and render using
`references/report-format.md`. Write explanatory prose in Simplified Chinese;
preserve paths, symbols, commands and excerpts verbatim. Report material limits
honestly, without generic summaries, praise, checklists or internal reasoning.
