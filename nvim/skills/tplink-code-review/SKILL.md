---
name: tplink-code-review
description: >-
  Perform evidence-based code reviews using TP-LINK embedded Linux and C
  engineering rules. Use whenever the user asks to review a module, code,
  diff, staged changes, commit, Gerrit change, Change-Id, or patchset against
  TP-LINK standards, or requests a TP-LINK-style security, correctness, or
  stability review. Review only the requested scope, report actionable
  defects in Simplified Chinese, and never modify the reviewed code.
compatibility: Requires repository/file access and Git for local diffs; incremental module tools require POSIX and Python 3; Gerrit retrieval requires Python 3.8+, HTTPS access and GERRIT_AUTH_NAME/GERRIT_AUTH_TOKEN HTTP credentials.
---

# TP-LINK Code Review

Review behavior, not just style. Keep reviewed code read-only: do not edit
source/configuration files, generate patches, commit, install dependencies, or
claim checks ran unless they actually did. Save internal module progress outside
the reviewed repository in the runtime-provided session directory. Write module
reports as `YYYY-MM-DD-Module-评审报告-v1.md` in the working directory where the
review starts, even if it is inside that repository; this report is the only
permitted review output there. Other reviews report in chat.

## 1. Resolve the exact source

| Input | Source of truth |
|---|---|
| Pasted diff/patch | Supplied diff and necessary supplied context |
| File, selection, buffer | Specified current source and minimum context |
| Module/subsystem without revision | Current implementation, local headers, build/configuration and relevant tests |
| Repository review without target/revision | Staged diff only: `git diff --cached` |
| Commit/hash/ref | Selected commit against its first parent |
| Gerrit URL/change/Change-Id/patchset | Exact requested patchset, retrieved using `scripts/fetch_gerrit_patch.py`; read `references/gerrit-retrieval.md` first |

Resolve ambiguous module names before reviewing. A module request is not a
diff review and needs no staged changes. Do not substitute the worktree for
a selected index/commit/patchset or fall back to local code after Gerrit
retrieval failure. Read surrounding revision context from the same snapshot.
For change reviews, report only introduced defects or old defects whose
reachability/behavior the change materially alters. File/module reviews cover
the requested current implementation without implying change attribution.
Follow neighboring callers only to establish a concrete target contract.
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

For modules, follow the completion reference through inventory, four-dimensional
file coverage, integrated traces and issue reconciliation. Reuse stable evidence
and dependency IDs through the record tools rather than re-reading shared paths.
Do not stop at a findings quota or confuse inspected files with proven paths.
After compaction, use the validated recovery working set, verify source identity,
then continue the first unfinished task; do not dump the historical journal.
Deliver the generated module report as a file, with only its path and review
status in chat. For continuations, update the same report at each handoff and
on completion until it says `评审状态：已完成`; keep its original date and `v1`
filename rather than creating a new report per turn.
Preserve the original working-directory destination even if a continuation
starts in a different directory; do not run the generator from the skill directory.

For other reviews, retain the narrow source boundary and render using
`references/report-format.md` directly in chat, without creating a report file.
Write explanatory prose in Simplified Chinese;
preserve paths, symbols, commands and excerpts verbatim. Report material limits
honestly, without generic summaries, praise, checklists or internal reasoning.
