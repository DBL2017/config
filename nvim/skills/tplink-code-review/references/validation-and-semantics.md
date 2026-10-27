# Safe basic validation and semantic quick checks

Use after scope resolution for every review. These checks complement the
parent skill's normal/error-path and cross-file analysis; they do not narrow
module reviews to changed lines or widen revision reviews to current code.

## 1. Establish what can safely be checked

- Identify actual languages/formats, configured dialects, build entrypoints,
  compiler flags, generated inputs and relevant conditional branches.
  Prefer repository-provided commands and installed tooling.
- Validate the selected source: worktree files for current-file/module
  requests; staged/index contents for staged requests; selected commit or
  patchset contents and dependencies for revision requests. Never run a
  worktree command and attribute its result to a different snapshot.
- When necessary, materialize the selected files and required local context
  in session storage without checking out over the user's worktree. If the
  required snapshot/build context cannot be reproduced, name the limitation;
  do not validate a mixed snapshot or incomplete file fragments as full files.
- Inspect commands/configuration before execution. Parser, compiler, lint,
  build and test invocations may execute project hooks/plugins or write
  caches/artifacts. Do not use auto-fix, format-in-place, code generation,
  dependency installation, deployment or device/network operations merely
  to review code. A dry run is not inherently side-effect-free.
- Prefer syntax/check-only modes with output/cache redirected to isolated
  session storage. Run builds/tests only when their behavior is understood,
  permitted, and safely isolated; otherwise choose a narrower check or
  document why execution is unsafe. Never execute intentionally defective
  fixtures, untrusted scripts, or project commands blindly.
- Combine checks covering the same surface; avoid full builds when a focused
  parser/compiler check suffices. Do not fetch dependencies or send source
  to external validation services just to satisfy this protocol.

## 2. Choose an appropriate check

| Surface | Preferred existing check | What still needs review |
|---|---|---|
| C/C++ | Configured compiler syntax/type diagnostics with actual include paths, defines, dialect and target ABI | Linking, ownership, bounds, signedness, runtime behavior |
| Shell | Matching interpreter's parse-only mode; existing ShellCheck configuration when available | Command lookup/expansion, sourced context, exit-status handling, runtime effects |
| Lua | Configured Lua/LuaJIT compilation/parse check without executing the chunk | Patterns, module/API contracts and runtime types |
| JSON/XML/YAML/TOML | Existing format parser/schema validator in safe mode | Consumer dialect/schema, semantic constraints, references |
| Other code | Project's non-fixing type/compiler/lint check | Framework contracts and actual failure paths |
| Templates/generated sources | Safe template parsing and existing isolated generation checks if feasible | Both template syntax and generated syntax; do not silently regenerate target files |

For C branches and generated/build inputs, check relevant selected variants
or manually trace branches not exercised by available commands. A default
configuration passing does not cover other configurations. Do not blindly
enable incompatible feature combinations.

Do not use unsafe deserializers or parsers that resolve external entities,
network schemas, includes or custom constructors on untrusted input. Disable
such features or use an existing safe parser; otherwise record the limitation.

## 3. Review semantic consistency

Apply only relevant rows, verify callers/contracts, and deduplicate root causes.

| Check | Evidence to trace |
|---|---|
| Signature and return consistency | Declaration, definition, return statements, direct/indirect calls, callback registration, parameter order and ownership |
| Signed error results | API return type and error sentinel through storage/casts to the branch; unsigned storage can make `< 0` unreachable |
| Bounds and arithmetic | Actual available/received bytes, destination capacity, terminators, indexes, inclusive/exclusive endpoints, overflow before length arithmetic |
| Boolean/status direction | Success/failure convention from implementation and callers; `false` or `0` is not universally failure |
| Current versus stale values | Producer and consumer of result/length/status across retries and branches; distinguish intentionally retained last-good state |
| Correct object and field | Which object was loaded/validated versus updated/serialized; similarly named variables and configuration fields |
| State-machine side effects | Allowed transitions, retry counters, publication/commit ordering, failure paths that accidentally advance to success |
| Error and cleanup paths | Return-value handling, ownership transfer, partial initialization, resources retained or freed across every applicable exit |
| Reuse and compatibility | Existing helper's validation, return, lifetime and byte-order contract; affected callers and supported versions |

For Shell, distinguish parse errors from runtime command/expansion mistakes.
For example, `var =1` is normally parsed as a command named `var`, not as an
assignment; `bash -n` can succeed. Verify its context before reporting the
wrong assignment/command behavior. A top-level `return` can be valid in a
sourced script; `local` and test operators vary by shell and context.

For Lua patterns, verify the exact pattern, position and target runtime.
Parse-only Lua checking does not validate pattern strings. Do not declare
every occurrence of `+`, `-`, or another metacharacter a malformed pattern;
distinguish intended pattern operators, literal matching mistakes and actual
runtime pattern errors. Avoid executing production chunks to test a pattern.

## 4. Record results without overstating them

In session evidence record the command, exact source identity, configuration,
exit status, relevant diagnostics, scope/variants checked, and skipped checks
with concrete reasons. Record manual checks as manual, not as executed tools.
For modules, add this to the existing ledger instead of creating a parallel
coverage system.

A warning is not automatically a defect. Confirm its reachable conditions
and relevant contract; for change reviews establish attribution to the diff.
Missing dependencies, wrong host ABI, or a partial snapshot do not establish
a source regression. Do not hide failed checks behind a later successful
unrelated command.

Record validation as executed, unavailable, unsafe, or not applicable. Lack
of tooling alone need not block completion of a static review; an unresolved
material build/behavior question does. Explain material limits in the parent
skill's scope line, without implying that syntax/type success proves runtime
correctness or that a conditional bug must happen on every run.
Keep the selected route's report layout (non-module `report-format.md`, module
generator): do not add a separate validation section or `验证说明` paragraph.
Mention only material validation limitations
in `评审范围`; keep detailed successful-check logs in session evidence.
