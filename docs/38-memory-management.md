# Memory management in the native Lume runtime

Status: **shipped.** The hosted x86-64 Linux runtime reclaims memory with a tracing collector. This document
says what exists, how it was verified, and what its limits are. The implementation is one file:
`compiler/stage1/runtime_core.lume`.

## The model

A Lume value lives as long as something can reach it. `own`, borrows and `resource type` are compile-time
rules about who may use a value and when (see "Ownership and memory" below). Reclaiming the memory itself is
the runtime's job, and it does not depend on those annotations: a program with no annotation at all runs in
bounded memory.

The collector is **non-moving mark-sweep**, conservative for roots and for scanned objects.

| Part | What it does |
| --- | --- |
| Heap | One reserved address range (`mmap` `PROT_NONE`, committed with `mprotect` as it grows), cut into 64 KiB chunks. It never uses `brk`, which belongs to `malloc` in any process that links C code. |
| Small objects | 43 size classes up to 32 KiB, separate for scanned and atomic objects. A fresh chunk is threaded one page at a time, so a small program only touches what it uses. |
| Large objects | Their own run of chunks. |
| Roots | Registers, stack, bss, every live arena. |
| Pointers | Any word that points into a live object keeps it alive, interior pointers included. Atomic objects (string bytes) are not scanned. |
| Sweep | Lazy. A collection only frees whole chunks, which go straight back to the OS through `madvise(MADV_DONTNEED)`. A partly live chunk is swept when its size class next needs memory, so the pause is the mark phase. |
| Pacing | The next collection happens when the bytes allocated since the last one reach `max(64 MiB, 3 × live)`. A program below 64 MiB never collects. |
| Zeroing | `alloc` always returns zeroed memory. |

`alloc` keeps its historical contract: it clobbers only `rax` and `r10`, which is what lets the assembly
runtime keep working unchanged, and also why no register is ever a hidden root.

### Limits

These are real, and a production user should know them.

- **The pause is proportional to the live heap.** There is no generational or concurrent mode. Measured on this
  compiler's workloads the mark phase is tens of milliseconds at 60 MiB live; expect roughly a second per
  several GiB of live data. A latency-sensitive service with a large heap will see that.
- **The collector is conservative**, so an integer that happens to look like a heap address keeps an object
  alive. That can delay reclaiming memory; it can never free a live object.
- **Objects never move, so the heap can fragment.** A large object needs a contiguous run of free chunks. Under a
  tight `LUME_HEAP_CAP` such an allocation can fail closed while enough memory is free in total but scattered. A
  chunk with one live small object stays in its size class until that object dies.
- **A shared library does not collect.** A Lume `.so` has no `_start`, and a C host may keep pointers that the
  collector cannot see, so the export stubs initialize the heap with the collector off.
- **Hosted x86-64 Linux only.** `@freestanding` kernel images keep their fixed bump heap. Other targets, and the
  non-Linux dispatch through the seed interpreter, are unchanged.
- **No threads.** The hosted runtime is single-threaded today, and the collector relies on that.
- The reservation is 1 TiB of address space, halved until the kernel accepts it, so `ulimit -v` works but shows
  up as a smaller maximum heap.

## Controls

| Variable | Meaning |
| --- | --- |
| `LUME_GC=on\|off` | `off` never collects. |
| `LUME_GC_STRESS=<n>` | Collect on every n-th allocation and poison freed objects. This is how the collector itself is tested. |
| `LUME_HEAP_CAP=<bytes>` | Cap on mapped heap plus arenas (K/M/G suffixes). Over the cap the runtime collects first, then fails closed with exit 12. |

An invalid value fails at startup with exit 12.

`use arena` exposes `heap_stats() -> {used, cap, allocs}`, `heap_peak_used()`, `gc_collect()` and `gc_count()`.
`used` is the bytes allocated and not yet reclaimed, including live arenas. After a collection it is the live
size.

## Arenas

`arena_new(cap_hint)`, `arena_alloc(arena, n)`, `arena_reset(arena)` and `arena_destroy(arena)` remain: up to
4 concurrent regions, O(1) bump allocation, `cap_hint` a hard budget. Each arena is now its own `mmap` region,
so a live arena no longer limits how far the heap can grow, and `arena_destroy` returns the memory to the OS.
Arena contents are roots, so a heap object referenced only from an arena stays alive. `arena_alloc` returns a
raw address that dangles after reset or destroy.

## Value words

A value is one 64-bit word, so the common values never reach the heap.

| Word | Meaning |
|---|---|
| `...1` | integer of 63 bits, value = word >> 1 |
| `...010` | string of at most 7 bytes: bits 3..5 are the length, bytes 1..7 the text |
| `...000` | pointer to a cell, always aligned on 8 bytes |

`int` is still 64 bits in the language. A value that does not fit 63 bits lives in a 16-byte cell, and overflow past
64 bits still stops the program. Every value has one form: an integer that fits 63 bits is never boxed and a string of
at most 7 bytes is never a cell. That is why `x == "a"` and `x == 5` compile to one word comparison.

| Cell | Layout | Size |
|---|---|---|
| Long string | `[(len<<8)\|1][bytes][NUL]`, no pointers, not scanned | 9 + length |
| Big integer | `[3][value]` | 16 |
| Constructor | `[descriptor][fields]` | 8 + 8 per field |
| Record | `[shape][values]` | 8 + 8 per field |
| List | `[(len<<8)\|5][elements*]` | 16 + 8 per element |
| `rc`, `arc`, weak, promise | first word 7, 9, 11, 13 | 16 to 32 |

The first word of a cell tells the two families apart: odd is a kind, even is the address of a static descriptor.
A constructor descriptor is `[self][(arity<<8)|2][name]` and its first word makes it the one cell of that constructor
without fields, so `Nil` allocates nothing. A record shape is `[self][(n<<8)|4][key*]`, shared by every record with the
same keys. Keys are interned, so field access compares addresses.

Literals, descriptors, keys and shapes live in `.rodata` under labels computed from their content, one copy each.
Two different texts under one label stop the compilation: a hash collision must never become wrong data.

## The compactor

Cold data only. Unpacking costs microseconds per page and hot values already fit a word, so nothing here runs on an
ordinary allocation.

- `mem_pack(s)` and `mem_unpack(blob)` use the LZ4 block format behind a 20-byte header: magic, length and a 64-bit
  checksum of the original bytes. The decoder checks both buffers on every step and a blob that fails any check stops with
  `lume: packed data is corrupt`, exit 3. The checksum catches accidents, it is not a signature.
- `arena_freeze(a)` compresses an arena page by page, returns the memory to the OS and gives back the stored bytes. All-zero
  pages cost nothing. Addresses stay valid: the pages are mapped `PROT_NONE`, and the first touch of one brings that page
  back through the fault handler. `arena_thaw(a)` brings all of them. `arena_alloc` thaws first, `arena_reset` and
  `arena_destroy` drop the data without unpacking it. A frozen arena is not a collector root.
- `LUME_ARENA_COLD=<n>` freezes an arena after `n` collections without an `arena_alloc`. It is off by default.
- `.lcaps` and `.lumb` are stored packed when that is smaller and every reader accepts both forms.
  `lume pack <in> -o <out>` and `lume unpack <in> -o <out>` work on any file.

Two rules keep this from weakening the guarantees of the language:

- **Secrets.** Decompression time depends on the bytes, which is a published attack on compressed memory (Decomp+Time).
  So `mem_pack`, `arena_freeze` and `arena_compact` reject a value that comes from a `@secret fn`, `secret_new`, a
  `secret_*` parameter or a `ct_*` function with `[C0009]`. An arena marked with `arena_mark_secret` stops at run time, and
  `LUME_ARENA_COLD` skips it.
- **`@bound`.** The compactor runs in time that depends on the data, so calling it under `@bound` fails with `[V0002]`.
  With `LUME_ARENA_COLD` unset nothing freezes behind a program's back.

## Failure modes

All fail closed, on stderr, with a stable exit status.

| Condition | Message | Exit |
| --- | --- | --- |
| Live data exceeds `LUME_HEAP_CAP` | `lume: heap cap exceeded (LUME_HEAP_CAP=...)` | 12 |
| Address space or memory exhausted | `lume: out of memory (heap exhausted)` | 12 |
| Unbounded recursion | `lume: stack overflow (recursion too deep)` | 12 |
| Integer overflow of `+`, `-`, `*`, and `INT64_MIN / -1` or `% -1` | `lume: integer overflow` | 3 |
| Division or remainder by zero | `lume: division by zero` | 3 |
| List index past the end | `lume: list index out of bounds` | 3 |
| No `match` arm for the value | `lume: no match arm accepts this value` | 3 |
| Missing record field, or a field of a non-record | `lume: this value has no such field` | 3 |
| Arithmetic on a non-integer, or a non-boolean condition | `lume: type error: ...` | 3 |
| Other invalid memory access | `lume: invalid memory access` | 139 |

The stack limit is raised at startup to the hard limit, capped at 4 GiB, so runaway recursion stops with a
diagnostic before it can take the machine down.

## Ownership and memory

`own`, `mut`, borrows and `from` are compile-time rules, checked by `compiler/stage1/own_flow.src`:

- A move invalidates every binding that can observe the value: plain aliases (`let b = a`), containers
  (`{keep: a}`, `Cons(a, t)`), parts (`x.f`, match patterns) and closures. Siblings stay valid, so moving `t` out
  of `Cons(h, t)` leaves `h` usable. `[O0001]`
- Moving out of a borrowed parameter is rejected through any alias or pattern. `[O0002]`
- A `resource type` value held by a `let` must leave on every path. `[O0004]`
- A live borrow conflicts with a move, a mutable borrow, or (for a mutable borrow) any use of its target, up to
  the borrow's last use, not to the end of the scope. `[O0013]`
- A borrow cannot escape through a record, constructor or match result. `[O0020]`, `[O0021]`
- Moving `r.a` leaves `r.b` usable, but the whole of `r` is gone. A part already read stays valid when the whole
  moves on, because values are immutable. One expression cannot both move a value and hold a borrow of it.
- An `own` parameter that reaches the end of its function is consumed there. A `resource type` value bound by a
  `let` has to leave explicitly.

Top-level constants are inlined, so they have no identity to move or borrow.

A function with `own` or `mut` parameters can be used as a value, but the checker cannot see through a call to a
value, so the argument is shared there: the caller does not lose it. It stays safe because the reuse gate sees that
call site as not unique, so the function allocates instead of reusing the argument in place.

Unknown calls create no alias: treating every call as an alias would reject ordinary code such as
`let toks = tokenize(src) in run(own toks)`. So these errors do not by themselves prove a cell is unique, which
is what the next rule is for.

**Perceus reuse is an optimization that must be earned.** In-place constructor reuse overwrites a cell, so it is
sound only when nothing else can reach that cell. An `own` parameter keeps reuse only if **every call site in
the program** passes a provably, deeply unique value (`pu_*` in `06b_phase3.src`), and that value is used exactly
once on each path, with no exemptions. When that cannot be proven the
compiler emits a normal allocation, which is always correct. The compiler's own AST passes are in that second
group: their input comes from the parser, whose output is not provably unique, so since this change they
allocate instead of reusing. The collector reclaims the rest, and self-compilation is not measurably slower.

This is what closed a real soundness hole: `let b = a in let c = bump(own a) in head(b)` used to compile and
print a value overwritten through `b`.

## Evidence

- `compiler/stage1/gc_ok.src`: live data survives forced collections, value by value, including interior
  pointers, large objects, closures, `rc` and deep stacks. Garbage is really freed.
- `tests/harness/gc_gate.src`: `lumec` compiling itself gives byte-identical assembly with the collector on, off
  and under `LUME_GC_STRESS`.
- `tests/memory/gc_cap_ok.src`: 2 GiB allocated in total under `LUME_HEAP_CAP=32m` succeeds with the collector
  and fails closed with `LUME_GC=off`, so the test fails if nothing is reclaimed.
- `tests/memory/gc_stress_ok.src`: same output when collecting every 3 allocations with freed memory poisoned.
- `tests/memory/gc_frag_cap_ok.src`: a live object in every chunk leaves no free chunk, and the allocator must use
  the room inside them instead of reporting a false out-of-memory.
- `tests/memory/arena_cap_ok.src`, `dir_race_ok.src`: garbage is not charged to a new arena, and a directory that
  grows during `fs_read_dir` truncates the listing instead of overrunning the buffer.
- `bootstrap/lume0/tests/gc/*.lume`: the seed heap, with cases that fail if its registry roots are removed.
- `tests/memory/*_fail.src`: every failure mode above.
- `tests/harness/ownership_gate.src`: 35 fixtures that `lumec` and `lcaas` must judge identically, including the
  cases where aliased data must keep its value.

## Stage-0

The C seed uses the same approach for the same reason (`bootstrap/lume0/value.c`): 64-byte values, immortal
scalars and a conservative mark-sweep heap, in portable C11. Its output on `lumec.src` is byte-identical to the
previous seed. See `bootstrap/lume0/SEED_FREEZE.sha256`.
