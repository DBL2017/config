# C/C++ Resource Lifecycle Closure

This audit is mandatory for every C/C++ review route: file, excerpt, module,
staged diff, commit, and Gerrit patchset. It applies even when the task appears
to be style-only or no concurrency issue has yet been identified. Keep the
audit inside the selected source/revision boundary; for change reviews, report
only defects introduced or materially affected by the change.

The purpose is to prove that acquired resources have a valid owner and are
released or transferred on every applicable path. Do not treat a search result
or a successful normal path as proof of lifecycle correctness.

## 1. Inventory acquisitions and ownership

Identify lifecycle-sensitive objects in the selected code and relevant
contracts, including:

- Heap allocations, file streams, file descriptors, sockets, handles, and
  temporary files.
- Mutexes, read/write locks, spinlocks, semaphores, condition variables, and
  project wrappers/macros such as `UCI_LOCK()`.
- References, registrations, callback arguments, queued tasks, timers, and
  asynchronous buffers.
- In C++, resources managed by RAII, including smart pointers and scoped lock
  guards, as well as raw resources and ownership transfers.

Use searches for common APIs and project wrappers to find candidates, then
trace the actual implementation and callers. Resolve macros, conditional
compilation, configured build flags, and ownership contracts before deciding
whether a resource is acquired or a cleanup is active. A macro that expands to
nothing in one build is not an active lock there; do not assume it is empty or
active without evidence.

For each meaningful acquisition, establish who owns the resource, whether
ownership is transferred, and which function or scope is responsible for
cleanup. Follow callers when needed to determine whether an error is ignored,
whether a later operation retries the same acquisition, or whether the object
escapes asynchronously.

## 2. Close every control-flow path

For each acquisition, trace all applicable exits: normal returns, early
returns, `goto` cleanup labels, loop exits, error branches, and C++ exception
unwinding. Verify that every path either releases the resource exactly once or
transfers ownership under a demonstrated contract.

For locks, specifically:

- Pair each lock operation with unlocks across every exit that can occur while
  the lock is held; account for nested and conditional acquisitions.
- Determine whether a shared cleanup label can be reached both with and
  without the lock. Do not infer lock ownership from the label name.
- Inspect return handling and the next relevant caller operation. A leaked
  non-recursive lock may self-deadlock when the same thread reacquires it, or
  block other users; claim only the consequences supported by the call path.
- Check lock ordering or callbacks while holding locks only when the paths can
  actually overlap.

For C++, verify that scope-based destructors run on the relevant returns and
exceptions, and that RAII objects are not released, moved, or bypassed
incorrectly. Do not report a leak solely because there is no explicit
`unlock()` or `free()` when a valid RAII/ownership contract proves cleanup.

## 3. Record an internal closure matrix

Maintain a compact internal matrix for each lifecycle concern:

| Resource / lock | Acquisition and owner | Applicable exits | Release / transfer evidence | Build condition / disposition |
|---|---|---|---|---|

Use dispositions such as `closed`, `transferred`, `not acquired on path`,
`inactive in selected build`, or `blocked`. Every `blocked` item must identify
the missing source, contract, or build evidence and appear as a material
limitation in the review scope. Do not use this matrix as a substitute for
source evidence or expand the user-facing report with clean-path checklist
items.

The C/C++ review is not lifecycle-closed while a reachable acquisition has an
unresolved exit, ownership transfer, or relevant build condition. Continue
accessible checks; do not stop at a findings quota.

## 4. Report only proven defects

Before reporting a lifecycle defect, establish:

1. The trigger that enters the path after acquisition.
2. The missing, duplicated, premature, or invalid release/transfer.
3. The resulting failure, such as a leak, stale reference, deadlock, or
   blocked operation, using caller and synchronization evidence as needed.
4. The selected revision/build condition and exact source locations.

Recommend the smallest concrete correction. For a lock leak, prefer repairing
the specific held-lock error path or making cleanup ownership explicit; do not
add an unconditional unlock to a shared error label if some paths reach it
without acquiring the lock.

Absence of a `free`, `close`, or `unlock` at one location is only a lead:
confirm cleanup helpers, RAII, aliases, transfer, and all relevant exits before
reporting. Conversely, an error path that bypasses the only release is
actionable even if the normal path is correctly balanced.
