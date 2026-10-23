# Shared-state and asynchronous-lifetime review

Use this reference when the target has multiple execution contexts or
asynchronous work. The goal is to establish actual conflicting paths, not to
flag every global or require a lock around all accesses.

## 1. Map state to execution contexts

For module reviews, persist each mutable state object or coherent field group
in `review.json.state_groups`, using `review-record-format.md`; an internal
table or conversation-only observation is not a substitute. For narrower
reviews, apply the same reasoning within the selected evidence boundary.

| State | Writers | Readers | Execution contexts | Synchronization/order | Status |
|---|---|---|---|---|---|
| Configuration fields, buffers, counts, pointers | Initialization, refresh, reset, teardown | Direct reads, getters, aliases, callbacks | Registration and scheduling sites | Common lock, atomic protocol, publication, confinement | Verified, finding, or unresolved |

Locate definitions and declarations, then trace actual accesses and their
callers. Include helper files and accesses outside the module only when they
touch the target's state or establish a relevant contract. Search results are
candidates: distinguish similarly named locals, inactive code, and aliases.
Resolve macros and wrappers before deciding what a lock protects.
Reconcile each file's mutable-state observations with its `state_group_ids`.
Use a dedicated synchronization trace for each group, separate from array
capacity, parsing, or allocation traces. A finding in another category cannot
close the group's synchronization question.

For each access, distinguish:

- Initialization before worker startup from refresh/reset after startup.
- One serialized event loop from callbacks dispatched to a worker pool.
- Synchronous calls from queued tasks and callback registration.
- Object ownership from pointer aliases and borrowed buffers.
- Configuration variants from code that can actually run together.

An event-loop callback and a worker may overlap even if callbacks within that
loop are serialized. Conversely, different callback names do not prove
parallelism. A serialized loop can still have a stale queued callback or
reentrant lifetime defect; demonstrate its actual ordering.

### Evidence required for safety exclusions

Classify every discovered writer call path, including refresh/reset/teardown,
not just startup callers. Search direct calls, aliases and callback tables;
inspect enclosing functions and registration/dispatch sites. Retain scoped
search coverage and excluded/inactive hits with reasons in
`access_inventory.evidence`. A matching line is not a call-context proof.
Do not infer phase from file order, function names, or a different updater
that does not write this cache. Unresolved indirect calls or variants remain
pending/blocked rather than being silently classified as startup.
For an initialization-only conclusion, a callback labeled startup needs
`startup_only_evidence` proving it cannot run later; registration before
worker creation does not establish invocation before worker creation.

Before marking a group verified, perform and persist a counterexample check:

| Proposed proof | Required evidence and attempted falsification |
|---|---|
| Initialization only | All writer paths precede reader startup/publication; inspect registrations for post-start refresh/reset writes |
| Single context | Every access is confined to the same non-reentrant context; follow enqueue/thread creation and exclude async escape |
| Common lock or snapshot | Both sides use the same protocol over the entire access and coherent field group; inspect unlocked aliases and post-unlock use |
| Atomics or ownership | Actual memory ordering/publication or exclusive ownership transfer, including related fields and later mutations |

All safety conclusions record checks for runtime writers, async dispatch,
and synchronization on both sides, explaining non-applicability when needed.
Record one access per distinct call/context path even if several paths share
the same write instruction. Finding a runtime writer invalidates an
initialization-only proof immediately; a newly found worker invalidates a
single-context assumption until revisited. Reopen dependent dispositions and
clear report mappings before continuing.

For example, `init -> refresh_cache` before worker creation does not establish
initialization-only when `methods["reload"] -> refresh_cache` is registered.
The reload handler runs later; a queued reader runs on the worker even though
both the handler and its enqueue callback originate in one event loop.

## 2. Verify synchronization and snapshot consistency

For every shared mutable state group, establish:

1. Which two access paths can overlap, with at least one write? Trace from
   startup/registration to each access, rather than guessing from filenames.
2. Does the same synchronization discipline cover both sides and the whole
   access interval? A lock around a library call or writer is insufficient
   if readers bypass it. A UCI/config-library lock does not automatically
   protect cached configuration returned to other threads.
3. Is there another valid ordering contract? Consider initialization before
   `pthread_create`, joins, ownership transfer, thread confinement, atomics
   and their memory ordering, or a correctly implemented snapshot protocol.
   `volatile`, aligned scalar accesses, and `const` pointer types alone do
   not synchronize mutable shared memory.
4. Do related fields form one logical snapshot? Check address/mask pairs,
   array/count pairs, gateway identity/port pairs, and pointer/length pairs.
   Individually race-free fields can still expose incompatible versions.
5. Does a returned pointer remain protected after the getter unlocks?
   Check whether it is copied, immutable, refcounted, or later mutated/freed.

Separate the demonstrated race or inconsistent snapshot from its possible
consequences. For an array/count mismatch, prove the count range and actual
indexing path before claiming an overflow. Do not inflate severity based on
an unproven crash or attacker control.

**Positive pattern:** a configuration refresh writes cached address/mask
fields under a configuration-library mutex while a started worker reads
those fields without that mutex. Cite the refresh path, worker path, and
startup/registration evidence; describe the missing synchronization and
the demonstrated functional consequence.

**Negative patterns:** fields initialized before thread creation and never
modified later; all accesses confined to one non-reentrant event loop;
readers and writers copying the complete state under the same mutex.
Do not report a data race in these cases without evidence contradicting
the ordering or confinement contract.

## 3. Follow ownership through asynchronous work

Trace creation/acquisition, publication, use, cancellation, quiescence, and
destruction for tasks, callback arguments, queues, timers, descriptors,
references, locks, and shared objects.

- Check enqueue success and rejection separately: who owns the task and
  argument before/after submission, and who frees them on each path?
- Check worker completion, queued-task disposal, and partial startup failure,
  including cleanup when only some workers or synchronization objects exist.
- On shutdown, verify that producers stop, pending callbacks/tasks are
  removed or safely drained, and active users finish before shared state,
  locks, condition variables, or queue storage are destroyed.
- Cancellation is not proof of termination. Verify joins or an equivalent
  quiescence/lifetime protocol. Check cancellation while holding a mutex,
  condition-wait mutex reacquisition, and cleanup handlers if applicable.
- Trace lock acquisition/release on every early return and error path.
  Check lock-order inversion only between paths that can actually overlap;
  check reentrant callbacks and blocking waits while holding locks.

## 4. Close the evidence loop

Before finalizing, revisit every unresolved state group and lifetime path.
Mark it verified only when the relevant access/ordering contract was read.
If a required caller, build variant, or synchronization wrapper cannot be
resolved, state that concrete limitation in `评审范围`, not as a confirmed
defect or a claim of complete review.

Keep findings in the parent skill's format. For one shared-state root cause,
include representative conflicting read/write locations and scheduling
evidence in `原因`; group related fields only if they share the same access
and synchronization defect. Recommend the smallest appropriate repair
(confinement, common locking, a copied snapshot, or a proven atomic protocol),
not a blanket lock/refactor for the entire module.
