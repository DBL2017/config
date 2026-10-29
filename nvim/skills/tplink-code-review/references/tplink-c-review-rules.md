# TP-LINK C Review Rules

Use these rules as review criteria, not as a mechanical checklist. Attribute
findings to the most relevant section. Review the current requested source
for module/file reviews, or attributable changes for diff/revision reviews.
Report only clear violations with a meaningful, actionable impact.
Project-specific conventions take precedence where the user has not asked
for a specific TP-LINK rule.

## Style and comments

- Use four spaces for indentation, avoid mixed tabs and spaces, and keep code
  lines within 80 columns where practical.
- Put control statements on their own lines and brace every body. Keep
  `switch`, braces, and `case` labels consistently aligned; include a
  `default` branch. Mark intentional fall-through with `/* fall through */`.
- Keep comments synchronized with code. Explain why for non-obvious logic,
  bit operations, platform workarounds, and empty loops or functions; avoid
  comments that merely restate code.
- Use include guards in headers. Keep headers focused on declarations and
  include only necessary dependencies; put implementation-only includes in
  source files where practical.
- Prefer readable, locally grouped code over dense tricks. Treat style-only
  findings as Low at most, and report them only when they are specific and
  useful to fix.

## Names and program structure

- Prefer descriptive, consistent names; project convention uses lowercase
  snake_case for functions and variables, uppercase snake_case for macros and
  constants, and `g_` for globals.
- Avoid single-character names except conventional loop counters; avoid
  local/global name collisions.
- Keep naming conventions consistent within a project. Prefer action-oriented
  function names and consistent opposites for paired operations.
- Keep functions focused and preferably under 200 non-comment, non-blank lines.
  Prefer limited fan-out (roughly 3–7 direct calls), low recursion, and shared
  helpers for genuinely repeated logic.
- Give file-private functions and globals internal linkage with `static`.
  Declare variables in the smallest practical scope and initialize them
  before use. Never return a pointer to an expired local object.

## Interfaces, types, and concurrency

- Validate parameters and other inputs, including global state, files,
  hardware values, and protocol fields. Handle meaningful error return codes;
  make return-value semantics clear.
- Validate values before writing shared global state; do not use uninitialized
  values as inputs.
- Use `const` for read-only pointer inputs. Check integer ranges, signedness,
  width, promotions, byte order, and conversion behavior at interfaces.
- Preserve ownership and compatibility contracts between modules. Do not
  change another module's configuration, constants, or interfaces without
  justification.
- In reentrant or multi-task code, avoid mutable `static` locals and protect
  shared state with the project's synchronization mechanism. Check lock order,
  callback/interrupt context, and object lifetime.
- Verify the synchronization contract for every reader and writer, including
  getters and aliases. Writer-only locking does not protect unlocked readers;
  separately locked fields may still violate a multi-field snapshot contract.
  Establish actual execution contexts and startup ordering before reporting
  a race. Use `concurrency-review.md` for the cross-file evidence workflow.

## Memory, resources, and strings

- Check allocation results and all bounds. Ensure every acquired allocation,
  file, lock, reference, or other resource is released on every applicable
  exit path; do not use released or uninitialized objects.
- Prevent integer overflow/underflow, especially unsigned wraparound in
  indexes, lengths, sizes, and loop termination.
- Bound string and formatting operations, ensure destination termination, and
  detect truncation where it affects correctness. `strncpy` is not inherently
  safe: account for its non-termination behavior and the actual destination
  capacity. Prefer `snprintf` with correct size and return-value checks for
  formatted output. Never use `gets`.
- Treat macro arguments as expressions that may have side effects. Parenthesize
  macro parameters and the whole expression; use `do { ... } while (0)` for
  statement-like macros.
- Check `=`, `==`, `&`, `&&`, `|`, `||`, `<`, and `<=` for accidental
  substitution.

## Tests, diagnostics, and delivery

- Debug controls should be consistent, include module and line information,
  and not alter functional behavior; production builds should disable debug
  output as required by the project.
- New or changed logic should have appropriate unit tests; the stated project
  baseline is at least statement coverage. Do not infer test execution from
  source or configuration.
- Keep build options consistent. Resolve compiler warnings or document an
  explicit, justified suppression.
- Significant version changes should be tested and documented. Distinguish
  evidence visible in the requested diff from validation that was not run.

## Rule catalog and citation

The IDs below are stable identifiers for individual requirements in TP-LINK
《软件编程规范书》V1.1. Do not reuse an ID for a different requirement; if a
requirement is retired, reserve its ID. Cite the ID and source clause together.
The short descriptions are locator aids; the source document remains
authoritative. Recommendations retain their advisory status and must not be
reported as mandatory requirements.

| Stable ID | Source clause | Requirement |
|---|---|---|
| `TPL-C-STYLE-001` | 1.1 | Use four-space indentation; do not mix tabs and spaces. |
| `TPL-C-STYLE-002` | 1.2 | Keep each line within 80 characters and use the prescribed continuation style. |
| `TPL-C-STYLE-003` | 1.3 | Put control statements on their own lines and brace every body. |
| `TPL-C-STYLE-004` | 1.4 | Align `switch`, braces, and `case` labels consistently. |
| `TPL-C-COMMENT-001` | 2.1 | Keep comments consistent with code, explain why, and align them with the code. |
| `TPL-C-COMMENT-002` | 2.2 | Comment intentional fall-through, complex expressions, bit operations, platform-specific workarounds, and empty loops/functions. |
| `TPL-C-NAME-001` | 3.1 | Avoid single-character names except conventional loop counters. |
| `TPL-C-NAME-002` | 3.1 | Use descriptive names consistent with project conventions. |
| `TPL-C-NAME-003` | 3.1 | Prefix global variables with `g_`. |
| `TPL-C-NAME-004` | 3.1 | Do not give a local variable the same name as a global variable. |
| `TPL-C-NAME-005` | 3.2 | Use lowercase snake_case for functions/variables, uppercase snake_case for macros/constants, uppercase or CamelCase for types, and uppercase `_STRU` structure tags. |
| `TPL-C-NAME-006` | 3.3 | Prefer action-oriented function names and consistent opposites for paired operations. (Recommendation) |
| `TPL-C-READ-001` | 4.1 | Use parentheses to make expression evaluation order explicit. |
| `TPL-C-READ-002` | 4.2 | Keep related code together and avoid obscure techniques without justification. (Recommendation) |
| `TPL-C-VAR-001` | 5.1 | Do not read uninitialized values; validate values before assigning global state. |
| `TPL-C-TYPE-001` | 5.2 | Check range, signedness, width, promotion, byte order, and conversion behavior. |
| `TPL-C-TYPE-002` | 5.3 | Mark read-only pointer inputs `const`; prefer `const` or enums for non-changing local/file-scope values. |
| `TPL-C-SCOPE-001` | 5.4 | Use the smallest practical scope and initialize variables at declaration where practical. |
| `TPL-C-SCOPE-002` | 5.4 | Give file-private functions and globals internal linkage. |
| `TPL-C-SCOPE-003` | 5.4 | Never return a pointer to an expired local object. |
| `TPL-C-FUNC-001` | 6.1 | Use accurate function names. |
| `TPL-C-FUNC-002` | 6.1 | Handle error return codes from called functions. |
| `TPL-C-FUNC-SIZE-001` | 6.1 | Keep functions within the recommended 200 non-comment, non-blank lines. (Recommendation) |
| `TPL-C-INTERFACE-001` | 6.2 | Validate parameters and non-parameter inputs; pass actual arguments when modifying parameters. |
| `TPL-C-INTERFACE-002` | 6.3 | Make return semantics clear, use returned values, and return a compatible type. |
| `TPL-C-CONCURRENCY-001` | 6.4 | Avoid mutable static locals in reentrant code; protect shared globals. |
| `TPL-C-FUNC-003` | 6.5 | Prefer focused functions, limited fan-out, low recursion, and shared helpers for repeated work. (Recommendation) |
| `TPL-C-TEST-001` | 7.1 | Use consistent debug controls and logs with module and line; disable debug output in production without changing behavior. |
| `TPL-C-TEST-002` | 7.2 | Provide independent unit tests for new logic, install/remove them through the debug switch, and meet the stated statement-coverage baseline. |
| `TPL-C-PERF-001` | 8.1 | Do not trade correctness, stability, readability, or testability for optimization. |
| `TPL-C-PERF-002` | 8.2 | Minimize loop-body work, move invariants/independent conditions out, put the longest loop innermost, and reduce nesting where appropriate. (Recommendation) |
| `TPL-C-PERF-003` | 8.3 | Prefer multiplication over floating-point division when appropriate. (Recommendation) |
| `TPL-C-QUALITY-001` | 9.1 | Prioritize correctness, stability/security, testability, readability, global efficiency, then local efficiency. |
| `TPL-C-MEMORY-001` | 9.2 | Check allocations; release acquired memory/resources on every exit path; prevent invalid memory use, out-of-bounds access, and use of uninitialized values. |
| `TPL-C-INTEGER-001` | 9.3 | Prevent integer overflow/underflow and validate boundary values. |
| `TPL-C-OPERATOR-001` | 9.4 | Check for accidental substitution of commonly confused operators. |
| `TPL-C-FLOW-001` | 9.5 | Include a `default` branch in every `switch`. |
| `TPL-C-FLOW-002` | 9.5 | Prefer an appropriate `else` branch for `if` statements. (Recommendation) |
| `TPL-C-FLOW-003` | 9.5 | Have worker threads exit cooperatively rather than forcibly terminating them. |
| `TPL-C-MODULE-001` | 9.6 | Do not change another module's configuration, constants, or interfaces without authorization/justification. |
| `TPL-C-STRING-001` | 9.7 | Bound string operations; avoid unbounded `strcpy`/`strcat`/`sprintf`; guarantee termination (including after `strncpy`); check `snprintf` truncation; never use `gets`. |
| `TPL-C-HEADER-001` | 9.8 | Use include guards; keep headers to declarations and necessary includes; follow the prescribed include order. |
| `TPL-C-MACRO-001` | 10.1 | Parenthesize macro parameters and the complete macro expression. |
| `TPL-C-MACRO-002` | 10.2 | Wrap multi-statement macros in `do { ... } while (0)`. |
| `TPL-C-MACRO-003` | 10.3 | Do not pass side-effecting expressions to macros that evaluate parameters more than once. |
| `TPL-C-BUILD-001` | 11.1 | Keep build options consistent and fix warnings or document justified suppressions. |
| `TPL-C-REVIEW-001` | 11.2–11.3 | Review code and test/document significant version upgrades. |

Use the tags below only as broad categories, never as the complete citation:

| Tag | Stable IDs |
|---|---|
| `tplink_style` | `TPL-C-STYLE-*`, `TPL-C-READ-*`, `TPL-C-HEADER-*` |
| `tplink_commenting` | `TPL-C-COMMENT-*` |
| `tplink_naming` | `TPL-C-NAME-*`, `TPL-C-SCOPE-002` |
| `tplink_interface_contract` | `TPL-C-INTERFACE-*`, `TPL-C-TYPE-*`, `TPL-C-FUNC-002`, `TPL-C-MODULE-001` |
| `tplink_function_design` | `TPL-C-FUNC-001`, `TPL-C-FUNC-SIZE-001`, `TPL-C-FUNC-003`, `TPL-C-CONCURRENCY-001` |
| `tplink_testability` | `TPL-C-TEST-*` |
| `tplink_security_baseline` | `TPL-C-VAR-*`, `TPL-C-TYPE-*`, `TPL-C-MEMORY-*`, `TPL-C-INTEGER-*`, `TPL-C-STRING-*`, `TPL-C-MACRO-*` |
| `tplink_module_boundary` | `TPL-C-MODULE-001` |
| `tplink_build_quality_gate` | `TPL-C-BUILD-001` |
| `tplink_review_process` | `TPL-C-REVIEW-001` |

For every reported finding, distinguish:

- **Rule tags**: zero or more applicable category labels from the table above.
- **Rule basis**: one or more exact citations, each naming a stable ID and
  clause, plus a short explanation of its application.
- **Project contract**: when behavior depends on a local interface/business
  contract rather than a TP-LINK clause, cite the relevant source/caller
  locations and explain the contract. Do not imply this is a TP-LINK rule.

Do not force a broad or adjacent clause onto a finding. If no TP-LINK clause
directly applies, say so and cite the project contract or other actual source.
These organizational rules are not C language requirements; do not attribute
them to ISO/IEC 9899.
