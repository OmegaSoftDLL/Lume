# Memory management in the native Lume runtime (#404)

Status: **shipped increment** — heap observability, heap caps, and arena
(regions) are real, tested, and green in CI. A true garbage collector is
**planned**, not shipped; this document says exactly what exists, what was
deliberately chosen, and what the options are.

## What the runtime looked like before

The hosted native runtime (`alloc` in `compiler/stage1/data_asmgen.lume`,
mirrored in `compiler/stage1/lume/05_codegen.src`) was a single upward
`brk` bump pointer (`heap_cur`/`heap_end`, 64 MiB growth chunks). Nothing was
ever freed: peak memory equaled total allocated. That was the documented
"memory is the scaling wall" pitfall in `docs/PROJECT_STATE.md` §9 — the
compiler itself already fights it with output built as chunk lists, not
`+`-accumulated strings.

## What is shipped now (#404)

### 1. Heap observability

Every `alloc` maintains three counters (unconditional, a few instructions per
allocation):

- `heap_stats() -> {used, cap, allocs}` (std.arena):
  - `used` — live bytes: the normal bump heap plus every live arena's used
    bytes (`heap_cur - heap_base + heap_arena_used`).
  - `cap` — `LUME_HEAP_CAP` in bytes when configured, else the total mapped
    heap (`brk_end - heap_base`).
  - `allocs` — number of allocation calls (`alloc` + `arena_alloc`).
- `heap_peak_used() -> int` — the high-water mark of `used`.

### 2. Heap cap (fail-closed)

`LUME_HEAP_CAP=<bytes>` (suffixes K/M/G) bounds the whole mapped heap. Parsed
once at startup from the process environment (`lume_env_cap` walks `envp`;
a malformed value fails closed at startup, exit 12, clear diagnostic).
`alloc_grow` clamps to the cap and a request beyond it fails closed:
`lume: heap cap exceeded (LUME_HEAP_CAP=...)` on stderr, exit 12. Without a
cap, behavior is unchanged (grow until the kernel refuses, then the existing
out-of-memory diagnostic).

### 3. Arenas (region allocation)

`use arena` (`compiler/stage1/arena.src`) gives `arena_new(cap_hint)`,
`arena_alloc(arena, n)`, `arena_reset(arena)`, `arena_destroy(arena)`.
Real level: **4 concurrent arenas, each a dedicated `brk` region carved above
the normal heap**, O(1) bump allocation, `cap_hint` a hard per-arena budget,
`arena_reset` frees everything at once and makes the region immediately
reusable. Arena allocation interleaves freely with ordinary boxed allocation
— no scope discipline, because the regions are physically separate.

Two honest limitations, both fail-closed (exit 12, stderr diagnostic):

- While any arena is live, the normal heap cannot grow past the lowest arena
  base (the arena "pins the heap ceiling"); a normal allocation past the pin
  fails with `heap ceiling pinned by a live arena region` until arenas are
  reset/destroyed. Arena regions are mapped once and never moved.
- `arena_alloc` returns a raw address (boxed int) that dangles after
  reset/destroy; only handles are stable across a reset.

Observability and arenas are **hosted-runtime** features. `@freestanding`
kernel images keep their fixed heap and do not get these builtins.

### 4. Evidence (the regression tests)

- `compiler/stage1/arena_ok.src` (`lume test`): bump/reset/destroy
  semantics, address reuse, stats fields, the 1M-cell used-drop, and the
  no-arena monotonic-growth control.
- `compiler/stage1/arena_mem.src` (`lume run`): prints boolean-first,
  machine-checkable lines — `arena_drop` (used returns near baseline while
  `heap_peak_used` keeps the ~48 MiB high-water), `monotonic_growth`
  (without an arena the same shape only grows), and `vmhwm_at_least_24m`
  (peak RSS from `/proc/self/status` VmHWM really reached the touched
  region — the filler writes each cell via `mmio_volatile_write64`, since a
  pure pointer bump would not make the kernel supply pages). VmHWM is the
  kernel high-water mark and does **not** drop after `arena_reset`; the
  logical `used` does. That asymmetry is the honest picture: `arena_reset`
  releases memory to the runtime instantly; the OS mapping follows later.
- `tests/memory/*_fail.src` (driver-level): heap cap exceeded, malformed
  `LUME_HEAP_CAP`, too many arenas, arena budget exceeded, heap pinned by an
  arena — each must exit 12 with its diagnostic.

## Why regions first (the strategy)

The issue asks for "arena/release strategies before considering a full GC".
That ordering is deliberate and matches how the compiler is actually written:

1. **Regions kill the dominant cost pattern.** The workloads that hurt
   (compiler passes, parsers, serializers) allocate many short-lived objects
   with a clear lifetime boundary. A region turns "1M allocations + 1M
   deferred frees" into "1M O(1) bumps + one reset". The 1M-cell test shows
   the used-bytes curve returning to baseline; nothing else does that with
   so little machinery.
2. **Determinism.** Reset cost is O(1) and happens exactly where the program
   says. No pause times, no finalizers, no background threads — properties
   the effect system, the WCET analyzer (`@bound`), and the freestanding
   targets already assume.
3. **The compiler already does the sharper optimization.** Track K3 ships
   Perceus-style in-place constructor reuse (`__perceus_reuse_1/2`,
   `compiler/stage1/perceus_ok.src`): a matched `own` constructor cell is
   mutated in place instead of reallocated. That is *precise reuse* — the
   modern refinement-counting idea — applied to hot compiler data structures
   (`pairs2`, `gerase`, `cfold`). Between regions (bulk lifetimes) and
   Perceus (individual hot cells), the runtime's real pressure points are
   covered today.

## What a future GC would have to beat

The gap a collector would close is the **monotonic-growth control** in
`arena_ok.src`: long-lived programs with *no* lifetime structure — channels,
actor mailboxes, caches, REPL sessions — accumulate boxed garbage forever.
The options, honestly weighed:

### Mark-and-sweep (the conservative default)

- **Pros**: works with the existing runtime unchanged (no compiler analysis
  needed for correctness); collects any heap shape; well understood.
- **Cons**: needs a root set (stacks, globals, the `rc`/`arc` control blocks,
  arena-external references — Lume's runtime has all of these live at once);
  pause times are unbounded unless incremental; `alloc` needs a free list or
  compaction policy; and sweeping must cooperate with the bump fast path.
  A non-moving collector also fragments; a moving one needs to update every
  root and every `rc` interior pointer, at which point the runtime needs to
   know where pointers live in every object — the runtime's boxed values are
  self-describing (tag word), so scanning is feasible, but this is a real
  collector project, not an afternoon.

### Precise / Perceus-style ownership reuse, extended

- **Pros**: zero runtime cost beyond what K3 already pays; deterministic;
  the compiler already has the ownership analysis (`own`, move semantics,
  drop checking) to support it.
- **Cons**: only applies where ownership discipline exists; does nothing for
  `rc[T]` cycles or unstructured long-lived data. Reference counting (which
  `rc[T]`/`arc[T]` already are) leaks on cycles and pays per-operation cost.

### The recommendation

Keep regions as the primary user-facing tool for bulk lifetimes (they are
superior to "just add a GC" for the compiler's own shape of work). If and
when unstructured long-running workloads become first-class (long-lived
actors, servers), implement a **non-moving mark-and-sweep over the boxed
heap** as an opt-in `@gc` region tier — the O-track already reserves `@gc`
region types and checks their boundaries (`O0030`), so the type-system slot
exists. Until then, the honest statement is: **no automatic collection
ships; memory is reclaimed by regions, by `rc`/`arc` drops, by Perceus
reuse, or by process exit.**

## Files

- Runtime templates: `compiler/stage1/lume/05_codegen.src`
  (`runtime_tail`, `runtime_mem_tail`, `luses_mem_*`, `lgen` heap init/bss/
  rodata, FFI export heap init), `compiler/stage1/data_asmgen.lume` (same,
  always-emitted for the ML-core/bootstrap path).
- Std module: `compiler/stage1/arena.src`.
- Tests: `compiler/stage1/arena_ok.src`, `compiler/stage1/arena_mem.src`,
  `tests/memory/*.src`, wired in `bootstrap/lume0/tests/run.sh`.
