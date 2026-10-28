---
name: problem-analysis-documentation
description: "Standardize evidence-based diagnosis and resolution of technical problems. Use this skill when the user reports or asks to investigate a bug, incident, crash, regression, or other unexpected behavior, including requests to explain its cause or fix. Do not use the full problem-analysis workflow for general code explanations, routine code reviews without a reported problem, or feature implementation unrelated to a defect."
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

## Choose the response mode

Match the work to the user's request, impact, and available evidence. The workflow below is a toolbox, not a requirement to produce a full incident report for every problem.

- **Quick triage (default for simple investigations):** State the current conclusion or that the cause is not yet known, then give the most useful next check or action. Keep it brief; do not produce the full report template.
- **Root-cause analysis:** When the user asks why, or the issue needs deeper investigation, provide the evidence-backed causal chain, confidence, unresolved alternatives, and recommended fix and validation.
- **Implementation:** Edit files only when the user asks for a fix or implementation. A request to diagnose or explain alone is not permission to change code. After changes, report the checks actually run and their results.
- **Formal report:** Use `references/report-template.md` when the user requests a report, or when the incident's impact or audit needs justify a durable record. Do not force every template field when evidence is unavailable; mark gaps rather than inventing details.

Modes can be combined when the request calls for it (for example, root-cause analysis plus implementation). Ask only for information that blocks useful progress; otherwise proceed with clearly stated assumptions and the smallest relevant investigation.

## Workflow

### 1. Frame the problem

For triage, capture only the details needed to identify the symptom and the next check. For deeper analysis or a formal report, build a problem record using the applicable fields:

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

If essential information is missing, ask focused questions before making a strong claim. If useful progress is possible, proceed with explicit assumptions and gaps rather than blocking. Do not require every field for a quick triage.

### 2. Ingest code and logs safely

For deeper analysis and formal reports, inventory relevant supplied artifacts before interpreting them. Record their path/name, version or commit, time range, origin, and whether they may contain secrets or personal data. For quick triage, inspect only the evidence needed to answer the immediate question.

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

Only implement when the user asks for a fix or implementation. Make surgical changes using repository conventions. Before editing, inspect the relevant files and current diff. After editing:

1. Run the narrowest relevant unit/integration/regression test.
2. Run type-check, lint, build, or static analysis when the changed surface requires it.
3. Re-run the original reproduction and verify the expected behavior.
4. Exercise relevant negative, boundary, concurrency, compatibility, and rollback cases.
5. Report commands, results, and any unverified conditions.

If a check cannot run, state the exact blocker and provide a reproducible command for the next engineer. Distinguish checks that were run from checks that are merely recommended; never report an unrun check as passing.

### 7. Produce the final document

Only produce a formal document in **Formal report** mode. Use `references/report-template.md` unless the repository or user specifies another format. The document must be useful to both implementers and reviewers:

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

Follow the selected response mode rather than returning every deliverable by default:

- **Quick triage:** Give the current conclusion (or state that the cause is unresolved) and the next useful check/action. Include a brief evidence or uncertainty note when needed.
- **Root-cause analysis:** Summarize impact and confidence, then provide the evidence-backed causal chain, recommended fix, validation plan, and remaining gaps. Include a timeline or alternatives when they help explain the case.
- **Implementation:** Summarize the change, files affected, checks actually run and their results, and any remaining gaps. Include rollout or rollback guidance when relevant.
- **Formal report:** Provide the complete report using the referenced template, with evidence, analysis, solution, validation, rollout/rollback, and action items.

For an unresolved case, give only the hypotheses and next evidence appropriate to the selected mode; rank hypotheses for deeper analysis or formal reports. Never fill unknown fields with invented values.
