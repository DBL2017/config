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

## Enterprise-rule tags and source mapping

Use these rule tags in the finding's `规则` field when applicable:

| Tag | Coverage | Source sections |
|---|---|---|
| `tplink_style` | Formatting and readability conventions | 1, 4 |
| `tplink_commenting` | Comment accuracy, intent, and required rationale | 2 |
| `tplink_naming` | Identifier and linkage conventions | 3 |
| `tplink_interface_contract` | Parameters, return values, types, module interfaces | 5–6, 9.6 |
| `tplink_function_design` | Function size, responsibility, fan-out, reentrancy | 6 |
| `tplink_testability` | Debug controls and unit-test expectations | 7 |
| `tplink_security_baseline` | Memory, integer, string, and input safety | 5, 9.2–9.7 |
| `tplink_module_boundary` | Cross-module configuration and interface stability | 9.6 |
| `tplink_build_quality_gate` | Compiler flags and warning handling | 11.1 |
| `tplink_review_process` | Review, test, and release-record expectations | 11.2–11.3 |

These rules describe organizational practices, not C language requirements.
Do not claim that a style rule is mandated by ISO/IEC 9899. When citing a
chapter, use the chapter numbering above.
