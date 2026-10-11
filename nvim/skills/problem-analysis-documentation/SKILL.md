---
name: problem-analysis-documentation
description: "Standardize end-to-end technical problem handling: clarify the problem statement, collect and protect source code and logs, reproduce and analyze the root cause, design and validate a solution, and produce an auditable engineering document. Use this skill whenever the user reports a bug, incident, customer issue, crash, regression, abnormal behavior, or asks to analyze provided code/logs and explain the cause and fix—even if they do not explicitly ask for a formal report."
compatibility: Requires access to the relevant repository, source files, logs, test/build tools, and issue or document destination when available.
---

# Problem Analysis and Documentation

Use this workflow to turn incomplete technical evidence into a defensible diagnosis and an actionable, verifiable solution. Keep observed facts, inferences, and proposed changes separate so the result can be reviewed or reproduced by another engineer.

## Operating principles

- Preserve the user's environment and existing work. Read before editing; do not overwrite unrelated changes.
- Treat source code, logs, traces, configs, and reproduction steps as evidence. Quote exact paths, line ranges, timestamps, identifiers, and relevant excerpts.
- Never invent missing evidence. Mark unknowns, assumptions, and confidence explicitly, then state the smallest next check that would resolve each uncertainty.
- Protect secrets and personal data in outputs. Redact tokens, passwords, private keys, session identifiers, customer data, and internal URLs unless the user explicitly needs a safe reference.
- Prefer the smallest root-cause fix that preserves intended behavior. Include compatibility, rollout, rollback, and failure-mode considerations.
- A diagnosis is incomplete until it has a causal chain and a validation plan. A plausible symptom description alone is not a root cause.

## Workflow

### 1. Frame the problem

Start with a concise problem record:

| Field | Content |
|---|---|
| Problem | What is wrong, in one sentence |
| Expected | Intended behavior or invariant |
| Actual | Observed behavior, error, impact |
| Scope | Affected versions, platforms, users, devices, or requests |
| Time | First occurrence, recurrence, and relevant timestamps/time zone |
| Severity | User/business impact, availability, data integrity, security, and urgency |
| Reproduction | Minimal steps, inputs, frequency, and whether it is deterministic |
| Evidence | Files, logs, traces, commits, configs, metrics, and test results |

If essential information is missing, ask focused questions before making a strong claim. If useful progress is possible, proceed with an explicit **Assumptions and gaps** subsection rather than blocking.

### 2. Ingest code and logs safely

Inventory every supplied artifact before interpreting it. For each item record its path/name, version or commit, time range, origin, and whether it may contain secrets or personal data.

For source:

1. Locate the external entrypoint and the code path that handles the failing input.
2. Trace data and control flow through validation, state changes, I/O, concurrency, error handling, and cleanup.
3. Check recent changes, feature flags, configuration differences, and dependency/runtime versions.

For logs:

1. Normalize timestamps and correlate request/session/thread/process identifiers.
2. Build a chronological event sequence; distinguish the first failure from later cascading errors.
3. Preserve exact error text and stack frames, while redacting sensitive values.
4. Compare failing and successful examples when available.

Do not treat log severity, the last stack frame, or the first suspicious line as proof of causality. Use them to select code paths for verification.

### 3. Reproduce and localize

Convert the evidence into a minimal reproduction or a deterministic test. If reproduction is unavailable, state why and use static tracing plus controlled evidence.

Localize the failure by checking:

- the first violated invariant or unexpected state transition;
- the boundary where actual behavior diverges from expected behavior;
- input/permission/configuration/version conditions required for the divergence;
- whether the issue is deterministic, race-dependent, resource-dependent, or data-dependent.

Use targeted searches, tests, tracing, assertions, and a minimal fixture. Avoid broad refactors while the causal chain is still uncertain.

### 4. Establish root cause

Write the causal chain in this order:

1. **Trigger:** the input, event, environment, or timing condition.
2. **Mechanism:** the exact code path and state transition.
3. **Failure:** the violated invariant, exception, incorrect output, leak, race, or data corruption.
4. **Propagation:** why the observed log, user symptom, and impact follow.
5. **Why not caught:** missing validation, test coverage, monitoring, review, or deployment guard.

For each material conclusion include evidence and confidence (`High`, `Medium`, or `Low`). Separate:

- **Confirmed:** directly reproduced or proven by source/evidence;
- **Likely:** strongly supported but missing one confirming check;
- **Possible:** a competing hypothesis that remains unresolved.

Rank alternative hypotheses and specify a falsification check for each. Do not present “root cause” as confirmed when only a correlation is known.

### 5. Design the solution

Provide an options table when there is a meaningful tradeoff:

| Option | Change | Benefits | Risks/limits | Validation | Rollback |
|---|---|---|---|---|---|

Recommend one option and explain why. The recommended solution should identify exact files/modules, behavior changes, input validation, error handling, compatibility impact, migration needs, observability, rollout controls, and rollback steps.

Include layered controls where appropriate:

- immediate mitigation or containment;
- permanent code/configuration fix;
- regression test or reproduction test;
- monitoring/alerting and operational runbook update;
- prevention work such as review rules, static checks, or documentation.

Do not prescribe a code edit that has not been connected to the causal mechanism.

### 6. Implement and verify

When the user asks for implementation, make surgical changes using repository conventions. Before editing, inspect the relevant files and current diff. After editing:

1. Run the narrowest relevant unit/integration/regression test.
2. Run type-check, lint, build, or static analysis when the changed surface requires it.
3. Re-run the original reproduction and verify the expected behavior.
4. Exercise relevant negative, boundary, concurrency, compatibility, and rollback cases.
5. Report commands, results, and any unverified conditions.

If a check cannot run, state the exact blocker and provide a reproducible command for the next engineer.

### 7. Produce the final document

Use the structure in `references/report-template.md` unless the repository or user specifies another format. The document must be useful to both implementers and reviewers:

- Executive summary: impact, status, root cause, and recommended action.
- Problem statement and scope.
- Evidence inventory and redaction notes.
- Reproduction and timeline.
- Technical analysis with source/log references.
- Root cause and contributing factors, with confidence.
- Options and recommended solution.
- Implementation/files changed (if applicable).
- Validation evidence and remaining gaps.
- Rollout, monitoring, rollback, and prevention.
- Appendix: safe excerpts, commands, assumptions, and glossary.

End with a compact **Action items** table containing owner, action, priority, and acceptance evidence. Keep the report factual and avoid blame-oriented language.

## Output contract

Unless the user asks for a different format, return:

1. **Diagnosis summary** — one paragraph stating impact, root cause status, and confidence.
2. **Evidence-based analysis** — timeline, causal chain, and exact references.
3. **Solution** — recommended fix plus mitigation, tests, rollout, and rollback.
4. **Validation status** — commands/results and explicit remaining gaps.
5. **Standardized report** — the complete document using the referenced template.

For an unresolved case, still provide a ranked hypothesis table and the next evidence needed. Never fill unknown fields with invented values.
