# Call-site input and boundary closure

Apply to full-source reviews (full file or module), not snippet/change routes.
Use the existing file checks, traces and issues; do not create a second ledger.
A file marked inspected, a parser pass, or closed shared-state groups cannot
substitute for these checks.

## 1. Discover before proving

During each target file's initial pass, enumerate relevant operations and
project wrappers/macros in these four categories:

| Category | Candidates |
|---|---|
| `string_boundary` | Copies, concatenation, formatting, bounded alternatives, and consumers requiring terminated strings |
| `scan_conversion` | `scanf` family conversions, scansets and other fixed-destination field parsers |
| `structured_input` | JSON/XML/config field lookup and subsequent dereference, type conversion or use |
| `allocation_io` | Allocations, length/size arithmetic, file positioning and reads, and cleanup |

Use scoped searches and read the complete relevant expressions/functions.
Account for wrappers, aliases and multi-line expressions; lexical matches are
leads, not defects or proof of coverage. Record concrete search scopes, discovered
locations and excluded hits. Establish the selected build and follow supporting
producers/callers only to verify target contracts. Do not audit supporting files
as new targets.

For each target, populate `functional_paths.risk_inventory` with all four
categories. Each entry has `status` (`pending`, `complete`, `not_applicable`),
`trace_ids` (unique dedicated risk-site traces), and discovery `evidence`.
`complete` means candidate discovery is finished, not that every site is safe.
An empty complete entry requires `no_sites_reason`; `not_applicable` requires
`reason`, evidence and no sites. A declaration-only header may have no applicable
sites, but it still needs an evidenced applicability decision for every category.
Never copy empty examples to close a file that contains relevant operations.

Register one trace per relevant operation/category; multiple dependent lookups
must have separate source anchors even if they share one root-cause issue.
Do not use a whole function/file range or "remaining operations" as a call site.
Keep inactive-branch or unreachable candidates as evidenced exclusions rather
than silently dropping their search hits. Record discovery before moving on.

## 2. Verify each site

Risk sites are ordinary `traces` with:

- `kind: risk_site`, stable `id`, target `file`, `category`, exact
  `location` (`file:line` or line range), enclosing `function`, and `operation`.
- Normal `status`, `issue_ids`, `evidence`, and optional contract `dependencies`.
- Pending/blocked sites have an executable `next_check`; blocked sites also
  have `reason`.
- Resolved sites use `disposition: safe`, `confirmed_defect`, or `excluded`.
  Safe/excluded sites have `status: verified`; defects have `status: finding`.

Safe and confirmed-defect sites supply `checks`, with concrete facts for all
fields below. Explain genuine non-applicability within a field rather than
inventing a bound or check. Do not use blanket statements such as "checked".

| Category | Required `checks` fields |
|---|---|
| `string_boundary` | `input_max`, `destination_capacity`, `termination`, `length_handling` |
| `scan_conversion` | `input_max`, `destinations`, `field_widths`, `conversion_count`, `failure_handling` |
| `structured_input` | `producer`, `required_fields`, `type_checks`, `failure_handling` |
| `allocation_io` | `size_validation`, `allocation_result`, `read_result`, `cleanup` |

For concatenation, calculate the complete length including suffix and terminator;
a later hostname check does not protect an earlier write. For scanning, a length
check after conversion cannot protect the destination during conversion.
For structured data, successful parsing does not establish required fields or
types. Check each required field before dereference, including nested lookups.
For allocations/reads, prove size arithmetic, error sentinels, allocation success,
actual bytes read and every applicable cleanup path. Bounded APIs are not
automatically safe.

Check malformed/boundary inputs against actual producer contracts. Do not infer
remote reachability or exploitation merely from an unsafe operation. Distinguish
a demonstrated runtime error from a termination-rule violation with no proven
out-of-bounds read.

An excluded site needs `exclusion_reason` and `exclusion_evidence` proving its
build/reachability exclusion; it is not a generally safe implementation.
A confirmed-defect site must link directly and reciprocally to a confirmed issue.
Reuse one issue for one root cause across sites; include every affected site
in the surviving issue's trace links. A synchronization issue alone cannot close
a parsing or boundary concern.

## 3. Gates and recovery

Initial completion requires discovery decisions for all four categories of every
target, even if the ordinary four file checks are marked inspected. Sites may
remain pending for integration. Integration/final completion additionally requires
all sites resolved with category-specific evidence and valid issue associations.
An unresolved material input/producer contract prevents a completed report.
Use the existing actual-interruption protocol for partial delivery.

Use `manage_review_record.py update` to save inventories under
`file_checks[path].functional_paths` and sites under `traces` in one update.
Their links must agree in both directions. Use `get --kind trace` for a site;
`resume` first returns files whose discovery is incomplete, then unresolved
traces. Changed sources/contracts reopen dependent inventories, sites and issues;
preserve IDs and history, but reverify their conclusions.

Old version-3 records without inventories remain readable for recovery, but are
not complete under the new gates. Populate inventories and reverify sites from
source; do not treat historical file-wide line ranges as call-site evidence.
Gate counters refer to registered inventories/sites. The validator checks
structure and mandatory evidence fields, not source-search exhaustiveness or
the truth of semantic conclusions.

## 4. Source-anchored candidates

`init` maintains `functional_paths.candidate_scan` from the exact selected C/C++
snapshot. `update` refreshes it after source changes; do not edit this field.
Every extracted candidate must map to exactly one risk trace using `candidate_id`.
Copy the candidate's `callee` to `operation`, its enclosing `function`, and its
exact `line`/`end_line` to `location`. Keep separate calls separate, including
repeated calls on one line. The source hash, column and expression hash distinguish
them; a broad line range cannot replace the anchor.
Read counted candidate pages through `manage_review_record.py get --kind
candidates --id <target-path> --offset 0 --limit 5`; continue until `next_offset`
is null. `resume` returns their count rather than the whole list.

The lexical extractor skips comments/string contents, handles multiline calls,
and retains conditional-branch candidates. It is not a preprocessor or complete
C++ parser: declarations, macros, aliases and wrappers need manual classification.
For unclassified wrappers, run:

```bash
python3 <skill-dir>/scripts/discover_risk_sites.py <target> --all-calls
```

Copy the exact unclassified call object into `manual_anchor`, add concrete
`discovery_evidence`, and choose the applicable category. Declaration-only hits
may be excluded with source evidence. Non-C/C++ files use manual discovery;
the extractor's empty list is not proof of no risks.
Initial/final CLI gates and final generation re-read target/supporting identities
and recompute candidates. The tool does not execute reviewed source.

## 5. Per-scenario closure

In addition to existing `checks`, each resolved site supplies `scenarios`:

| Category | Required scenario keys |
|---|---|
| `string_boundary` | `bounds`, `termination`, `result_handling` |
| `scan_conversion` | `bounds`, `conversion_count`, `failure_handling` |
| `structured_input` | `presence`, `types`, `failure_handling` |
| `allocation_io` | `size`, `operation_failure`, `cleanup`, `caller_failure` |

Each scenario has `status` (`safe`, `finding`, `excluded`, `pending`, `blocked`).
Resolved entries need concrete `reason` and source `evidence`; `finding` also
needs `issue_ids` linking directly to confirmed issues on this site. Pending or
blocked entries need `next_check` and keep the whole site pending/blocked.
An inapplicable scenario uses `excluded` with evidence explaining why.
An excluded whole site has all scenarios excluded.

Review every applicable failure, not just the first finding. For `fopen`, prove
the NULL branch's return value, cleanup, and how its caller handles failure;
checking `fp == NULL` alone is not a safe conclusion. `cJSON_Print`, `fopen`,
`fprintf` and subsequent deletion are separate operations/traces. Add scenarios
for operation-specific failures beyond the required minimum.
Every linked issue must be accounted for by a scenario. One issue cannot stand
in for unrelated missing failure handling elsewhere in the function.

## 6. Structured facts

Each active resolved site also supplies `facts`. Facts describe actual writes
or reads and enforced bounds, not assumed business input sizes.

- **Strings:** `buffers` lists each relevant buffer with integer `capacity`,
  `max_bytes` (maximum payload actually written/consumed), `suffix_bytes`,
  `nul_bytes` (0 or 1), `bound_basis` and source `evidence`. Safe bounds require
  `max_bytes + suffix_bytes + nul_bytes <= capacity`. `bound_basis` is
  `target_guard`, `bounded_operation`, or `producer`; producer-based bounds also
  require `producer_evidence` locating the actual enforcement and access path.
  Unknown bounds use `bound_basis: unknown`, `max_bytes: null` and `reason`;
  they cannot establish safety. For bounded formatting, also verify truncation
  handling under `result_handling`, not just bytes fitting inside the buffer.
- **Scanning:** `format_string` must match the extracted literal. Nonliteral
  formats require `format_evidence`. `conversions` lists every unsuppressed
  string/scanset/character conversion in order with `index` (assignment index),
  `conversion` (`s`, `[` or `c`), `width` (integer or null), `nul_bytes`,
  destination `capacity`, and `evidence`. Values must match the actual format.
  Scan capacities are destination element counts (wide-character elements for
  wide conversions), not blindly `sizeof` bytes. A bare `%c` has width 1 and
  writes no terminator.
  Safe unbounded conversions additionally require numeric `producer_max` and
  `producer_evidence` for each destination. A bound on `%5s` does not protect
  preceding scansets. Numeric-only conversions use an empty conversion list,
  but still need conversion-count and error-handling proofs.
- **Structured inputs:** `fields` identifies each relevant `name`; safe presence
  and type scenarios require per-field `presence_evidence` and `type_evidence`.
  Attach concrete expected types and guards in the existing `checks` text.
- **Allocation/I/O:** `size` has boolean `applicable` and `evidence`. Applicable
  sizes provide integer `minimum`, `maximum`, `limit`; safe size scenarios require
  `0 <= minimum <= maximum <= limit`. Otherwise explain `reason`, e.g. closing
  an existing handle has no allocation size. Failure/cleanup/caller scenarios
  remain mandatory even when a size bound is inapplicable.

The validator checks these relationships and links, not the truth of quoted
producer contracts. Missing enforcement evidence stays unresolved; do not turn
uncertainty into either an automatic vulnerability or an automatic safe result.

## 7. Prior findings and claim strength

When old reports are supplied, include their absolute paths as `prior_reports`
in the init manifest. The tool snapshots them in session storage and imports each
supported finding as a pending `P...` entry. If the report has an unsupported
format, stop to normalize it in session storage rather than silently skipping it.
Do not search for unrelated reports or treat old findings as automatically true.

Update `prior_findings` by ID with `status`, `reason`, `evidence`, `issue_ids`.
`retained`/`merged` must point to confirmed current issues; `withdrawn`/`excluded`
need concrete source/build/scope evidence and no issue links. `pending` needs
`next_check` and blocks integration/final completion. Original text/severity and
report identity are immutable. Changed severity requires `severity_change_reason`.
Use `get --kind prior --id P001` and normal bounded `resume`; final reports show
the reconciliation. Invalidation reopens dependent prior dispositions.

Every confirmed issue needs `claim: {level, evidence}`. Levels are `standards`,
`runtime`, `impact`; the last two also require an explicit `trigger` proving the
asserted behavior. A missing terminator can establish a standards defect without
establishing an actual out-of-bounds read by a short-literal `strcmp`. Impact
and severity must follow the demonstrated path, not the API name.
