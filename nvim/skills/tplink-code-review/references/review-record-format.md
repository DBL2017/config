# Full-source review record format (version 3)

Store the following two files in a unique runtime session directory outside
the reviewed repository. Use absolute paths when invoking bundled scripts.
Do not copy example status/evidence as real review results.

Prefer `record-tools.md` commands over manually writing this schema. This file
owns field definitions and migrations, not stage gates or write policy (see
`module-review-completion.md`). Incremental commands preserve version-3 records.

## Contents

- [review.json](#reviewjson)
- [Risk call-site evidence](#risk-call-site-evidence)
- [Shared-state evidence](#shared-state-evidence)
- [issues.jsonl](#issuesjsonl)
- [Commands and migration](#commands-and-migration)

## review.json

```json
{
  "schema_version": 3,
  "source": {
    "repository": "/absolute/repository",
    "review_kind": "module",
    "module": "packages/private/example",
    "identity": "selected revision, worktree identity and reviewed build variants",
    "spec_available": false
  },
  "inventory": {
    "reconciled": false,
    "discovered": 1,
    "in_scope": 1,
    "excluded": 0,
    "files": [{"path": "src/main.c", "status": "in_scope"}]
  },
  "file_checks": {
    "src/main.c": {
      "identity": "actual file content hash",
      "functional_paths": {
        "status": "pending", "evidence": [],
        "risk_inventory": {
          "string_boundary": {"status": "pending", "trace_ids": []},
          "scan_conversion": {"status": "pending", "trace_ids": []},
          "structured_input": {"status": "pending", "trace_ids": []},
          "allocation_io": {"status": "pending", "trace_ids": []}
        }
      },
      "call_interface": {"status": "pending", "evidence": []},
      "resource_lifetime": {"status": "pending", "evidence": []},
      "shared_state_context": {
        "status": "pending", "evidence": [], "state_group_ids": []
      }
    }
  },
  "state_groups": [],
  "traces": [],
  "validation": {"status": "pending", "details": ""},
  "progress": {"phase": "initial", "next_step": "Inspect src/main.c", "blockers": []},
  "report_map": {},
  "limitations": []
}
```

The report generator adds optional `report_file`, the Markdown basename
(`YYYY-MM-DD-Target-评审报告-v1.md`), and `report_directory`, the absolute working
directory at first generation. Preserve both during updates and recovery so
every continuation refreshes the same report in the original working directory,
not the session directory. These are delivery metadata, not evidence that the
completion gates passed.

`source.review_kind` is `module` (also the default for existing records) or
`file`. The legacy `source.module` field stores the repository-relative target:
a directory for module reviews, the complete file path for file reviews.
A file review's inventory must contain exactly that one in-scope file,
even when it is a header or script. Necessary external callers, headers,
configuration and tests are supporting files, not additional targets.
Both routes use the same four checks, state/trace/issue records, completion
gates and continuation protocol. File report names use the full filename
including extension; module report names keep their existing directory name.

Set `inventory.reconciled` only after cross-checking build/conditional inputs.
Inventory counts must match its unique paths. Excluded items require a reason.
All in-scope paths must have file checks and actual content identities.
`inspected` checks need evidence locations; `blocked` and `not_applicable`
checks need reasons. The validator derives completed/remaining files; never
store duplicate counts or remaining-file lists in `progress`.

A trace has `id`, `status` (`pending`, `verified`, `finding`, `blocked`),
`issue_ids` (possibly empty for coverage-driven checks), and `evidence`.
Retain path, relevant objects, execution contexts and outstanding question
as additional fields. Resolved traces need evidence. Blocked traces require
`reason`. Issue/trace links must be reciprocal.

Optional `supporting_files` maps repository-relative header/build/config paths
to actual SHA-256 identities. Optional `evidence_catalog` maps stable IDs to
`summary`, source-location `evidence` and optional `dependencies`. Any evidence
list can reuse a catalog entry with `@E001`; references must resolve and catalog
entries cannot reference other entries. Retain concrete locations in report
fields. Use `dependencies` and trace/state IDs to identify reusable contracts.
The record tool invalidates their dependent work when facts change; the validator
checks references, not semantic dependency completeness. Neither optional field
is required when reading existing version-3 records.

Validation status is `executed`, `unavailable`, `unsafe`, or `not_applicable`
with factual `details` at completion. Record commands/results as supporting
fields; absence of tools is not automatically a defect.
`progress.blockers` contains material blockers. Document minor limitations
in `limitations`. Partial reports require a factual `progress.interruption`;
script rejection is not itself permission to abandon accessible review work.

## Risk call-site evidence

Every full-source target has a `functional_paths.risk_inventory` entry for each
of `string_boundary`, `scan_conversion`, `structured_input`, and `allocation_io`.
`input-boundary-review.md` owns discovery and category-specific proof rules.
The initializer creates pending entries; update them through ordinary
`file_checks[path].functional_paths` deltas.

Each category has `status`, unique `trace_ids`, and discovery `evidence`.
Statuses are `pending`, `complete` (discovery finished) and `not_applicable`.
Empty complete entries need `no_sites_reason`; not-applicable entries need
`reason`, evidence and an empty trace list. Missing/pending categories keep
that file's initial pass open, even when its four checks say inspected.

Each linked trace has `kind: risk_site`, target `file`, `category`, `location`,
`function`, `operation`, normal trace status/issue links, and evidence.
Inventory links are reciprocal: a site belongs to exactly one target/category.
For example, register a bounded-copy candidate pending full proof:

```json
{
  "id": "T010", "kind": "risk_site",
  "file": "src/main.c", "category": "string_boundary",
  "location": "src/main.c:30", "function": "copy_name", "operation": "snprintf",
  "candidate_id": "30:5:snprintf",
  "status": "pending", "issue_ids": [],
  "next_check": "Verify every scenario and fill structured facts",
  "evidence": ["src/main.c:25-34"],
  "checks": {
    "input_max": "Caller passes a terminated name; arbitrary length is rejected",
    "destination_capacity": "name[128]",
    "termination": "snprintf receives sizeof(name), leaving a terminator",
    "length_handling": "Return < 0 or >= sizeof(name) returns an error before use"
  }
}
```

The example is intentionally pending. `candidate_scan` is initialized from source;
its exact candidate ID, location and enclosing function must match. A resolved
site additionally needs per-scenario dispositions and structured facts defined
in `input-boundary-review.md`; copying free-text `checks` alone cannot close it.
Manual wrapper anchors must match `discover_risk_sites.py --all-calls`.

`verified` sites use `safe` with all category-specific `checks`, or `excluded`
with `exclusion_reason` and `exclusion_evidence`. `finding` sites use
`confirmed_defect`, all category-specific checks, and a directly linked confirmed
issue with the usual reciprocal `trace_ids`. Pending/blocked sites require
`next_check`; blocked sites also require `reason`. They prevent integration/final
completion, not initial discovery handoff.

Version-3 records without this additive inventory remain progress-readable but
cannot pass initial/integration/final gates. Reconstruct actual discovery and
site evidence before continuing; no automatic conversion from a broad source
range to a safe-site conclusion is allowed. Report counters describe registered
sites, not a proof of exhaustive discovery.

`prior_findings` is an optional tool-imported array from manifest `prior_reports`.
Each entry preserves immutable original location/summary/severity, report SHA-256
and session snapshot path. Its pending/retained/merged/withdrawn/excluded
disposition is validated separately from current issues. Integration requires all
entries reconciled. Confirmed current issues also need `claim.level` and
`claim.evidence`; runtime/impact levels require `claim.trigger`. Source, scenario,
prior reconciliation and claim-strength rules are owned by
`input-boundary-review.md`.

## Shared-state evidence

For each mutable state object or coherent group, create an entry such as:

```json
{
  "id": "S001",
  "symbols": ["cache.address", "cache.mask"],
  "files": ["src/main.c"],
  "status": "pending",
  "writers": [],
  "readers": [],
  "access_inventory": {"status": "pending", "evidence": []},
  "trace_ids": ["T001"],
  "next_check": "Inspect refresh callers, registration and worker readers"
}
```

Each related in-scope file links back through
`shared_state_context.state_group_ids`. Every group needs a dedicated trace:
`{"id":"T001","kind":"shared_state","state_group_ids":["S001"],"status":"pending","issue_ids":[]}`.
Do not reuse capacity/allocation traces as synchronization closure. Empty
file state inventories require `no_state_reason` plus inspected evidence,
or a justified `not_applicable` check. Initial-pass `inspected` means state
discovery/handoff is complete; groups may remain pending until integration.

`writers` and `readers` contain distinct call/context paths, not merely
distinct instructions. Each access has nonempty `id`, `location`, `function`,
`context`, `evidence`, `phase` (`startup`, `runtime`, `unknown`) and `kind`
(`direct`, `callback`, `worker`, `thread`, `interrupt`). For example:

```json
{
  "id": "W002",
  "location": "src/server.c:1090",
  "function": "reload_handler -> refresh_cache",
  "context": "main uloop",
  "kind": "callback",
  "phase": "runtime",
  "evidence": ["src/server.c:1086-1092 handler calls refresh"],
  "dispatch_evidence": ["src/server.c:407 method registration; main.c:140 event loop"]
}
```

Before a group becomes `verified` or `finding`, its writers must be
nonempty, phases resolved, and callback/worker/thread/interrupt paths must
have `dispatch_evidence` covering registration and dispatch. Set
`access_inventory.status: complete` with evidence of scoped symbol/alias/
caller searches and classification of excluded/inactive hits; preserve
unresolved paths rather than declaring the inventory complete.
Resolved groups need conclusion `evidence`, and all dedicated traces must
agree with their status. Pending/blocked groups need `next_check`; blocked
groups additionally need `reason`. They prevent integration/final completion.
If no readers exist, supply an evidenced `no_readers_reason`; still check
write/write conflicts, with at least two accesses for a finding. Do not
fabricate a reader. Preserve previously registered groups pending until
their scope or aliases are resolved and document any inventory correction.

A verified group requires:

- `ordering.kind`: `initialization_only`, `single_context`, `common_lock`,
  `snapshot`, `atomic`, or `ownership`; `evidence` explains the actual proof,
  including publication timing, non-reentrancy or ownership lifetime.
- `ordering.access_ids`: exactly all writer and reader access IDs. Startup
  only proofs require every writer to have `phase: startup`; single-context
  proofs require the same context for every access.
- A non-direct writer labeled startup also requires `startup_only_evidence`
  proving why it cannot run after startup (for example, synchronous completion
  and unregistration before worker creation). Merely registering a callback
  before starting the event loop is not that proof.
- For common-lock/snapshot/atomic proofs, `ordering.protocol` is a nonempty
  protocol identifier. Every access supplies the same `protocol` and its own
  `synchronization_evidence`; a write-side library lock is insufficient.
- `counterexample_check`: `status: complete`, nonempty `evidence`, and
  `checked` containing `runtime_writers`, `async_dispatch`, and
  `synchronization_both_sides`. Record what was inspected and why it failed
  to contradict the proof, not just these labels.

A finding group requires a confirmed issue linked to a dedicated trace,
with `review_category: synchronization` and `state_group_ids` including this
group. This distinguishes actual synchronization findings from unrelated
defects. The usual cause must cite conflicting accesses and scheduling.

When new evidence contradicts a proof, save the group and dedicated traces
as pending, invalidate dependent checks/dispositions and report mappings,
then reverify. The validator rejects structural contradictions but does not
parse source, establish search exhaustiveness, or prove evidence truthful.
Report counts say **registered** groups, not all possible shared state.

## issues.jsonl

Create this file even when there are no suspects (empty is valid). Each line
is a full snapshot for one issue, not a patch. Example first event:

```json
{"id":"R001","seq":1,"updated_at":"2026-10-23T14:00:00+08:00","origin":"initial src/main.c:20","summary":"待核实的资源清理问题","evidence":["src/main.c:20-25"],"dependencies":["worker shutdown contract"],"open_questions":["worker 是否仍运行"],"trace_ids":["T001"],"next_check":"核对 worker 退出路径","status":"pending","disposition":"需核对使用方生命周期","merged_into":null}
```

Append a new complete snapshot with `seq: 2`, etc. when updating that issue.
Do not delete history. Reopen a confirmed/dismissed issue as pending before
changing its disposition based on new evidence. Invalidate related checks,
traces, and report mappings when evidence changes.
The incremental tool supplies optional `evidence_snapshots` mapping referenced
catalog IDs to their facts at event time, preserving historical evidence even
when the current catalog is updated. Do not edit historical snapshots.

For `confirmed`, supply nonempty `location`, `cause`, `recommendation`,
`severity` (`Critical`, `High`, `Medium`, `Low`), `axis` (`Standards`, `Spec`),
and clear `open_questions`, plus the rule citation fields described below.
Use `Spec` only with an available specification. Dismissals need
evidence-backed dispositions. A `merged` event requires a valid `merged_into`
ID without cycles; preserve distinct impacts on the surviving issue.
Pending/blocked issues require `next_check`.

For new confirmed findings, use `rule_tags` (an array of broad classification
tags, possibly empty) and `rule_basis` (a nonempty array of precise citations).
Each TP-LINK citation must name a stable rule ID, clause, and its application.
Project contracts must identify source/caller locations and must not be
presented as TP-LINK clauses. These fields are additive in schema version 3.
The legacy `rule` string remains readable for existing records; new findings
must use `rule_tags` and `rule_basis` instead.

## Commands and migration

```sh
python3 <skill-dir>/scripts/validate_review_record.py <session-dir>/review.json --gate progress
python3 <skill-dir>/scripts/validate_review_record.py <session-dir>/review.json --gate initial
python3 <skill-dir>/scripts/validate_review_record.py <session-dir>/review.json --gate integration
python3 <skill-dir>/scripts/generate_review_report.py <session-dir>/review.json
python3 <skill-dir>/scripts/validate_review_record.py <session-dir>/review.json --gate final
```

`progress` validates structure/links and prints compact derived coverage; `initial`
also checks reconciled inventory, per-file coverage and risk-site discovery;
`integration` also checks resolved traces/issues, category-specific risk-site
proofs and recorded validation; `final` additionally
requires a bijection between confirmed IDs and report entries. The generator
constructs that mapping from confirmed issues and validates it before output.
A final validator alone does not prove a report was actually delivered.
CLI `--details` opts into full derived lists; failed coverage/closure conditions
expose paginated IDs with `--offset` and `--limit` (see `tool-output.md`).

Older single-file records are not silently accepted. Preserve the original;
create a version-3 review directory and transfer only evidenced source,
coverage, issues and traces. Revalidate identities, normalize field names,
and explicitly map old IDs. Do not invent missing evidence, upgrade pending
states, or claim unsupported historical writes. Resume unfinished work.
For version-2 dual-file records, also preserve both originals, copy the issue
history unchanged, and explicitly record the migration in `source`. Reopen
all shared-state file checks as pending with empty `state_group_ids`, rebuild
`state_groups` from observations and source, invalidate affected traces and
dispositions through appended issue events, and clear `report_map`. Preserve
unaffected checks. Merely changing the schema number or inserting an empty
state list does not establish synchronization coverage.
