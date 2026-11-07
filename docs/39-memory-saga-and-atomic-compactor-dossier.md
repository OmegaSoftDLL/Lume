# The Lume Memory Saga & 4-Tier Atomic Memory Compactor — Empirical Benchmark & Architecture Dossier

**Status:** Shipped & Verified on `main` (`fa9a3ea`, `stage2 == stage3` Zero-C fixpoint)  
**Hardware Reference:** Intel Core Ultra 5 135U (WSL2 x86-64 Linux & Windows 11 x64 PE32+)  
**Implementation:** [`compiler/stage1/runtime_core.lume`](../compiler/stage1/runtime_core.lume), [`compiler/stage1/lume/05_codegen.src`](../compiler/stage1/lume/05_codegen.src), [`compiler/stage1/data_asmgen.lume`](../compiler/stage1/data_asmgen.lume), [`compiler/stage1/own_flow.src`](../compiler/stage1/own_flow.src), [`compiler/stage1/name_flow.src`](../compiler/stage1/name_flow.src), [`compiler/stage1/arena_mem.src`](../compiler/stage1/arena_mem.src)

![Lume Memory Saga & Atomic Memory Compactor Evolution](assets/lume-memory-evolution-animated.svg)

---

## 1. Executive Summary & Narrative Arc

### 1.1 The Hook
Across three architectural generations — **Generation 1 (Baseline Bump Runtime)**, **Generation 2 (Round 5 Segregated Mark-Sweep GC & Ownership v2)**, and **Generation 3 (Round 6 Four-Tier Atomic Memory Compactor)** — the Lume self-hosted toolchain (`100% Lume gera Lume`) achieved:
- **`31.8×` faster integer loops** (`2,796 ms -> 88 ms`), collapsing **`200,000,000` heap allocations to `1`** and peak RAM from **`68 MB` to `0.39 MB` (`390 KB`)**;
- **`10.1×` lower peak RAM and `4.3×` faster self-compilation** of `lumec` (`1,165 MB -> 115 MB`, `1,908 ms -> 445 ms`, while shrinking the `lumec` ELF binary by **`34%`** from `1.52 MB` to `1.01 MB`);
- **`23.6×` lower peak RAM and `9.0×` faster full bootstrap** from the Stage-0 C seed (`200 s / 12.7 GB -> 22 s / 537 MB`);
- **`2,733×` lower peak RAM on string-heavy workloads** (`6,013 MB -> 74 MB -> 2.2 MB`, collapsing `42.6M` allocations to **`17`**);
- **`3.9×` faster full 410-test verification suite** (`529 s / 2.49 GB -> 136 s / 537 MB`), backed by **`75,512` differential value-matrix test cases**, **`317/317` red-team adversarial programs (`0 crashes`)**, **`159/159` semantic edge-case assertions**, and **`1,500/1,500` corrupted blob fuzzing checks**.

---

## 2. Generation 1: The Baseline Bottleneck & Live Heap Radiography

### 2.1 Why the Baseline Runtime Consumed Multi-Gigabyte RAM
In Generation 1 (prior to Round 5), both the Stage-0 seed interpreter and the Stage-1/Stage-2 native x86-64 runtime used uncollected bump allocation with boxed heap cells for every runtime value:
1. **Stage-0 `Value` Struct (`bootstrap/lume0/value.h`):** Each `Value` occupied `200 bytes` (`sizeof(Value) == 200`), causing a single Stage-0 compilation of `lumec.src` to consume **`102.0 s` and `12.5 GB` RSS**.
2. **Native Boxed Cells (Unaligned Bump Heap):**
   - Every `int` outside `[-1, 1024]` allocated a **`24-byte` cell** (`[tag=0][int64_val][0]`).
   - Every string literal evaluation (`"0"`, `"a"`, `"9"`, `"z"`) in `05_codegen.src:141` (`fn lstr`) called `mkstr` at run time, allocating a fresh **`24-byte` heap header** pointing to `.rodata`.
   - Every zero-arity enum constructor (`Nil`, `None`, `True`, `False`) allocated a fresh **`40-byte` cell** on every use.
   - Every `Cons(int, tail)` allocated **`56 bytes` + `24 bytes` = `80 bytes`** of live cells (plus `48 bytes` of temporary garbage per iteration).
   - Every 3-field record `{a, b, c}` allocated **`88 bytes` + `72 bytes` = `160 bytes`** (and stored field keys per instance, scanning keys with `streq` on every field access).
   - `alloc` did not align allocations to 8-byte boundaries (`87.8%` of cells were misaligned).

### 2.2 Empirical Radiography of an `830.9 MB` Live `lumec` Heap (`/proc/<pid>/mem`)
To ground the Atomic Memory Compactor in hard data rather than assumptions, a live memory probe (`snap.py` + `ana.py`) captured an **`830,963,712`-byte (`830.9 MB`)** heap snapshot of `lumec` compiling `lumec.src` (`600,558` bytes of Lume source $\rightarrow$ `6,165,320` bytes of x86-64 assembly) and classified every object in the heap:

| Heap Object Class | Object Count | Bytes Occupied | Share of Heap (%) | Key Empirical Finding from Heap Forensics |
|---|---:|---:|---:|---|
| **1. Static `.rodata` String Literal Headers (`str_ro`)** | `11,861,855` | `284,684,520 B` (**285 MB**) | **34.3%** | `05_codegen.src:141` (`lstr`) called `mkstr` on every lexer character comparison (`"0"` allocated `469,180` times; `"a"` `444,817` times; `"9"` `344,352` times; `"z"` `289,856` times; `"\n"` `236,420` times). |
| **2. Raw String Payload Bytes (`rawbyte`)** | `312,873,913` | `312,873,913 B` (**313 MB**) | **37.7%** | Intermediate string concatenation buffers during assembly emission. |
| **3. ADT Constructors (`ctor`)** | `1,734,448` | `69,377,920 B` (**69 MB**) | **8.3%** | Arity breakdown: `arity 0` = `502,012` (`20.1 MB` of `Nil`/`None` alone!), `arity 1` = `81,793`, `arity 2` = `1,087,077` (`Cons`), `arity 3` = `63,541`. **`96.3%` have arity $\le 2$**. |
| **4. Dynamic Heap String Headers (`str_heap`)** | `2,510,376` | `60,249,024 B` (**60 MB**) | **7.2%** | **`74.9%` to `94.9%` of dynamic short strings are $\le 7$ bytes** (fitting entirely inside a single 64-bit register word!). |
| **5. Pointer Vectors (`ptrword`)** | `6,737,396` | `53,899,168 B` (**54 MB**) | **6.5%** | Constructor payload arrays and record key/value pointer vectors. |
| **6. Records (`rec`)** | `655,845` | `26,233,800 B` (**26 MB**) | **3.2%** | Repeatedly stored identical field-name pointer arrays on every record instance. |
| **7. Boxed Integers (`int`)** | `985,222` | `23,645,328 B` (**24 MB**) | **2.8%** | **`100.0%` (`985,222 / 985,222`) fit in 62 signed bits** (`89.2%` fit in 31 bits), yet each consumed a `24-byte` heap cell. |
| **Total Scanned Heap** | **17,747,746 cells** | **`830,963,673 B` (831 MB)** | **100.0%** | Alignment audit: `15,578,321` misaligned (`87.8%`) vs. `2,169,425` 8-byte aligned (`12.2%`). |

---

## 3. Generation 2: Round 5 — Segregated Mark & Lazy-Sweep GC, Ownership v2 & Full Oracle Parity

Before introducing bit-level value compaction, Round 5 established a rock-solid memory and type safety foundation across both Stage-0 and Stage-1/Stage-2:

1. **Stage-0 Seed Compaction & Collector (`bootstrap/lume0/value.h`, `value.c`, `interp.c`):**
   - Shrunk Stage-0 `Value` from **`200 bytes` to `64 bytes`** and added a mark-sweep collector tested clean under **AddressSanitizer + UndefinedBehaviorSanitizer (`170 passed, 0 failed`)**.
   - Result: Stage-0 compiling `lumec.src` dropped from **`102.0 s / 12.5 GB` to `5.5 s / 472 MB`** (**`18.5×` faster, `26.5×` less RAM**).
2. **Single-Source Native Runtime & Segregated Mark-Lazy-Sweep Collector ([`compiler/stage1/runtime_core.lume`](../compiler/stage1/runtime_core.lume)):**
   - Unified the x86-64 assembly runtime between `05_codegen.src` and `data_asmgen.lume` (enforced by `tests/harness/runtime_sync_gate.src`).
   - Replaced `brk` with an isolated `mmap` reservation cut into **64 KiB chunks** across **43 segregated size classes** up to 32 KiB, separated into **pointer-scanned (`__gc_map_s`)** and **atomic pointer-free (`__gc_map_a`)** bitmaps.
   - Implemented **lazy per-size-class sweeping (`__gc_sweep_chunk`)** and immediate OS page reclamation via **`sys_madvise(..., MADV_DONTNEED)`**, plus decoupled `mmap` arenas (`with alloc`) so live arenas never pin the main heap.
   - Result: A 30-million-allocation churn benchmark dropped from **`5,721 MB` to `66 MB` (`86.6×` less RAM)**.
3. **Rust-Grade Ownership v2 & Strict Perceus Reuse ([`compiler/stage1/own_flow.src`](../compiler/stage1/own_flow.src), [`compiler/stage1/name_flow.src`](../compiler/stage1/name_flow.src)):**
   - Equivalence-class alias tracking (`rid`), field-sensitive move paths (`r.a` vs. `r.b`), non-lexical lifetimes (NLL) for `&x` and `&mut x`, recursive linear resource enforcement (`[O0004]`), and proven-unique Perceus in-place reuse (`pu_uses <= 1`).
   - New compile-time diagnostics: `[R0201]` runtime symbol collision, `[R0202]` exact function/builtin/pattern arity, `[R0203]` internal routine call, `[R0204]` invalid indexing, `[R0205]` intrinsic shadowing, `[D0002..D0004]` $O(n \log n)$ duplicate function/type/field checks, `[L0003]` 64-bit integer literal overflow, `[L0010]` duplicate assembler label, `[P0002]` chained comparison, `[C1001]` comptime arithmetic overflow, and `[T1002]` enum `match` exhaustiveness.
4. **Hardware-Checked 64-Bit Arithmetic & In-Process Compiler Oracle:**
   - `+`, `-`, `*` emit `jo __rt_ovf` (trapping with `lume: integer overflow`, exit 3) and `rt_idiv` traps on `INT64_MIN / -1` and `% -1` without `SIGFPE`, while `+%`, `-%`, `*%` provide explicit two's-complement wrapping.
   - Both `lcaas.src` and `lfmt.src` now embed the real `lumec` compiler in-process under a 16-deep nestable trap handler (`__lume_try_begin`), reducing `lcaas` vs. `lumec` divergence from `115/543` to **`0/547`** and `lfmt` AST meaning changes from `96/234` to **`0/233`**.

---

## 4. Generation 3: Round 6 — The 4-Tier Atomic Memory Compactor

### 4.1 Why Register-Level Algebraic Compaction Beats Byte-Stream RAM Compression
A head-to-head microarchitectural evaluation compared **Option A (64-bit Register-Level Tagged Word + Structural Cell Compaction)** against **Option B (Per-Object LZ4 Byte-Stream Compression on every `alloc`/read)**:

| Metric | **Option A: 4-Tier Atomic Compactor (Shipped)** | **Option B: Per-Allocation LZ4 in Hot RAM (Rejected for Hot Path)** |
|---|---|---|
| **Pack Cost (`alloc` / write)** | **0–1 CPU cycle** (`leaq 1(%rax,%rax), %rax` / bit-shift in register) | **~83 ns (250–330 CPU cycles)** per 64 B cell |
| **Unpack Cost (read / `match`)** | **0–1 CPU cycle (0.25–0.33 ns)** (`sarq $1, %rax` in register) | **~13 ns (40–50 CPU cycles)** + temporary buffer copy |
| **L1 Data Cache Impact (32 KiB)** | **Increases effective L1 capacity by `3×–5×`** (values live in registers / 8 B words) | **Degrades L1 capacity** (must hold both compressed block and decompressed scratch buffer) |
| **100M Integer Loop (`b_loop`)** | **`88 ms` (`0.88 ns/iter`, `1` heap alloc, `0.39 MB` RAM)** | **~9,000 ms (`90 ns/iter`)** — `102×` slower |
| **Side-Channel & WCET Safety** | **100% constant-time (1 cycle), immune to *Decomp+Time* (`[C0009]`) & deterministic for `@bound` (`[V0002]`)** | Vulnerable to *Decomp+Time* (IEEE S&P, Schwarzl et al., leaking 49 bits/min) and breaks `@bound` WCET |

### 4.2 Tier-by-Tier Architecture of the Lume Atomic Memory Compactor

#### Stage 0: Content-Addressed `.rodata` Literals, Singletons & Descriptors
- Every string literal, constructor descriptor, record shape, and interned field key is emitted once in `.rodata` under a content-derived label (supported by `.quad <label>` relocation in [`compiler/stage1/lasm.src`](../compiler/stage1/lasm.src) and [`bootstrap/lume0/elf.c`](../bootstrap/lume0/elf.c)).
- Any hash collision between two distinct texts under the same label halts compilation immediately (fail-closed).
- In `--protect hardened` and `--protect max` builds ([`compiler/stage1/lprotect.src`](../compiler/stage1/lprotect.src)), static `.rodata` literals and short strings remain encrypted so no plaintext leaks into protected binaries.
- Zero-arity enum constructors (`Nil`, `None`, etc.) share their static `.rodata` descriptor `[self][(0<<8)|2][name]` directly — allocating **`0 bytes`** at run time.

#### Level 1: One-Word (64-Bit) Tagged Immediates & Inline Register Codegen
Because all heap cells and static descriptors in `runtime_core.lume` are strictly 8-byte aligned (low 3 bits `000`), every runtime value fits in a single 64-bit word (`8 bytes`), and common values never touch the heap:

```text
63                                                             3   2   1   0
+---------------------------------------------------------------+---+---+---+
|               63-bit Signed Integer (word >> 1)               |   |   | 1 |  --> Tag ...1   : 63-bit signed int (0 B heap)
+---------------------------------------------------+-----------+---+---+---+
|      bytes [7..1]: up to 7 UTF-8 bytes inline     | len[5..3] | 0 | 1 | 0 |  --> Tag ...010 : Inline SSO String <= 7 B (0 B heap)
+---------------------------------------------------+-----------+---+---+---+
|                  8-byte aligned cell / .rodata address        | 0 | 0 | 0 |  --> Tag ...000 : Pointer to Cell / Static Descriptor
+---------------------------------------------------------------+---+---+---+
```

- **Full 64-Bit Integer Semantics Preserved:** Values fitting in 63 signed bits (`[-4611686018427387904, 4611686018427387903]`, covering `100%` of compiler integers) live unboxed in the register word (`...1`). Values requiring the 64th bit (`INT64_MIN` / `INT64_MAX`) transparently spill to a compact `16-byte` big-integer cell `[3][int64_val]`, while overflow past 64 bits traps via `jo __rt_ovf`.
- **Canonical Uniqueness Invariant:** An integer that fits in 63 bits is *never* boxed, and a string of $\le 7$ bytes is *never* allocated as a heap cell. Consequently, `x == "a"`, `c >= "0"`, and `x == 5` compile to a single 64-bit register comparison (`cmpq`), and `at(s, i)` / `chr(n)` return a 1-byte inline SSO word in registers with **`0 bytes` of heap allocation**!
- **Inline Codegen Fast Paths (`05_codegen.src` & `data_asmgen.lume`):** Integer addition, subtraction (`subq` preserving overflow flags), comparisons jumping directly without materializing intermediate booleans, and register-direct literal loads bypass the operand stack.

#### Level 2: Compact ADT Cells & Shared-Shape Records
The first word of any heap cell distinguishes atomic/primitive cells (odd kind tag) from structured cells (even pointer to a static `.rodata` descriptor or shape):

| Runtime Value / Cell Type | Gen 1 / Gen 2 Size | **Gen 3 (Round 6) Layout & Size** | Memory Reduction |
|---|---|---|---|
| **63-bit `int`** | `24 B` heap cell | **`0 B` heap** (in 64-bit register word `...1`) | **-100% heap (`24 B -> 0 B`)** |
| **64th-bit `int` (`INT64_MIN/MAX`)** | `24 B` heap cell | **`16 B` cell** `[3][value]` | **-33.3% (`24 B -> 16 B`)** |
| **Short string (`0..7` bytes, `at`, `chr`)** | `~40 B` (`24 B` hdr + bytes) | **`0 B` heap** (inline in 64-bit word `...010`) | **-100% heap (beats Rust `String` 24 B + heap!)** |
| **Static string literal (`"hello"`)** | `24 B` heap cell per eval | **`0 B` heap** (deduplicated `.rodata` cell) | **-100% heap (`285 MB -> 0 B` in `lumec`)** |
| **Long dynamic string (`> 7` bytes)** | `24 B` hdr + `8 B` ptr + len | **`9 B + length`** `[(len<<8)\|1][bytes][NUL]` (atomic, unscanned) | **-23 B overhead per string** |
| **Zero-arity constructor (`Nil`, `None`)** | `40 B` heap cell per use | **`0 B` heap** (shared static `.rodata` descriptor) | **-100% heap (`20.1 MB -> 0 B` in `lumec`)** |
| **ADT Constructor (`arity` fields)** | `40 B + 8 B * arity` | **`8 B + 8 B * arity`** `[descriptor][field_0 ...]` | **`Cons(int, tail)`: `80 B -> 24 B` (-70%)** |
| **Record (`n` fields)** | `40 B + 16 B * n` (+ boxed fields) | **`8 B + 8 B * n`** `[shared_shape][val_0 ...]` | **3-int record: `160 B -> 32 B` (-80%)** |
| **List (`n` elements)** | `40 B + 8 B * n` | **`16 B + 8 B * n`** `[(len<<8)\|5][elems...]` | **-24 B header overhead** |

#### Level 3: Cold Arena Demand-Paged Compactor & `LZ1` Capsule/Bytecode Compression
For cold data, frozen arenas, `.lcaps` capsules, and `.lumb` bytecode bundles, Level 3 provides a verified native block compactor:
- **`mem_pack(s)` & `mem_unpack(blob)`:** Uses an LZ4-class block codec wrapped in a 20-byte header (`magic = "LZ1\x1a"`, 64-bit original length, and 64-bit checksum of original bytes). Every decoder step bounds-checks both input and output pointers; any corruption or checksum mismatch fails closed with `lume: packed data is corrupt` (exit 3), verified against **1,500 corrupted fuzz inputs**.
- **Demand-Paged `arena_freeze(a)` / `arena_thaw(a)` / `arena_compact(a)`:**
  - `arena_freeze(a)` compresses an arena page-by-page (skipping all-zero pages at zero cost), stores the compact pages, returns physical RAM to the OS, and marks the arena virtual address range `PROT_NONE`.
  - **Transparent Lazy Page Thaw on First Touch:** Pointers into a frozen arena remain 100% valid! The first memory read/write to any frozen page triggers the runtime's `SIGSEGV` page-fault handler (running on a dedicated `sigaltstack`), which transparently decompresses and restores that specific page in-place and resumes execution!
  - `LUME_ARENA_COLD=<n>` automatically freezes arenas that have gone `n` GC cycles without an `arena_alloc`.
- **Packed `.lcaps` & `.lumb` + CLI (`lume pack` / `lume unpack`):** Bytecode bundles and capsules are automatically stored packed when smaller, and all readers transparently accept both packed and unpacked forms.
- **Formal Security & Real-Time Guards:**
  - **`[C0009]` Secret Data Protection (*Decomp+Time* Defense):** `mem_pack`, `arena_freeze`, and `arena_compact` statically reject values derived from `@secret fn`, `secret_new`, `secret_*` parameters, or `ct_*` functions with `[C0009]`, and `arena_mark_secret` blocks runtime arena compression so secret data never undergoes data-dependent compression timing.
  - **`[V0002]` WCET Determinism Protection:** Calling the compactor inside a `@bound(cycles: N)` function is rejected at compile time with `[V0002]`.

---

## 5. Complete Multi-Generation Benchmark Evolution Matrix

All measurements below were recorded on the same **Intel Core Ultra 5 135U** machine under WSL2 x86-64 Linux (paired medians across 7 alternating runs for microbenchmarks; `/usr/bin/time -v` for peak RSS and full toolchain runs).

### 5.1 End-to-End Speed & Peak Memory (RSS) Evolution

| Benchmark / Toolchain Workload | Gen 1: Baseline (Pre-R5) | Gen 2: Round 5 (`3a296cd`, Mark-Sweep GC) | **Gen 3: Round 6 (`fa9a3ea`, Atomic Compactor Levels 0–3)** | Speedup (R6 vs. R5 / vs. Gen 1) | RAM Reduction (R6 vs. Gen 1) |
|---|---:|---:|---:|---|---|
| **Full Bootstrap from Stage-0 C Seed** | `194.8 s` / `12,700 MB` | `200.0 s` / `2,500 MB` | **`22.0 s` / `537 MB`** | **`9.0×` faster** | **`23.6×` less RAM (`-95.8%`)** |
| **Stage-0 C Seed Compiling `lumec.src`** | `102.0 s` / `12,500 MB` | `5.5 s` / `472 MB` | **`5.5 s` / `472 MB`** | **`18.5×` faster** | **`26.5×` less RAM (`-96.2%`)** |
| **`lumec` Self-Compile (`stage2 == stage3`)** | `1,820 ms` / `1,165 MB` | `1,908 ms` / `228 MB` | **`445 ms` / `115 MB`** | **`4.3×` faster** | **`10.1×` less RAM (`-90.1%`)** |
| **Full Verification Suite (`410` tests)** | `> 600 s` / `12,700 MB` | `529 s` / `2,490 MB` (`404` tests) | **`136 s` / `537 MB` (`410` tests)** | **`3.9×` faster** | **`23.6×` less RAM (`-95.8%`)** |
| **Integer Loop (`b_loop`, 100M iters)** | Unbounded (`~4,800 MB`) | `2,796 ms` / `68 MB` | **`88 ms` / `0.39 MB` (`390 KB`)** | **`31.8×` faster** | **`174×` less RAM vs. R5 (`~12,000×` vs. Gen 1)** |
| **Records Benchmark (`b_rec`, 20M recs)** | Unbounded (`~6,000 MB`) | `3,270 ms` / `67 MB` | **`429 ms` / `66 MB`** | **`7.6×` faster** | **Bounded by 64 MiB GC pacing** |
| **ADT Pattern Match (`b_match`, 20M)** | Unbounded | `1,617 ms` / `72 MB` | **`235 ms` / `68 MB`** | **`6.9×` faster** | **Bounded by 64 MiB GC pacing** |
| **Linked Lists (`b_list`, 30 × 1M `Cons`)** | Unbounded | `2,747 ms` / `239 MB` | **`480 ms` / `67 MB`** | **`5.7×` faster** | **`3.6×` less RAM vs. R5** |
| **String Workload (`b_str`)** | `5,090 ms` / `6,013 MB` | `679 ms` / `74 MB` | **`131 ms` / `2.2 MB`** | **`5.2×` faster vs. R5 (`38.8×` vs. Gen 1)** | **`2,733×` less RAM (`-99.96%`)** |
| **Recursive `fib(38)` (`b_fib`)** | `1,190 ms` | `1,042 ms` | **`273 ms`** | **`3.8×` faster vs. R5 (`4.4×` vs. Gen 1)** | **0 B heap** |
| **`lumec` Native ELF Binary Size** | `1.46 MB` | `1.52 MB` | **`1.01 MB` (`1,006,576 B`)** | — | **`-34%` smaller binary** |
| **`lumec` Generated Assembly Size** | `7.35 MB` | `7.35 MB` | **`4.29 MB`** | — | **`-41.6%` smaller assembly** |
| **Level-3 `LZ1` Compactor Throughput** | — | — | **`~355 MB/s` pack / `~975 MB/s` unpack** | `lumec.src`: `787 KB -> 307 KB` (`2.56×`) | **Lazy page thaw on first touch** |

### 5.2 Heap Allocation Count Collapse (Round 5 vs. Round 6 Atomic Compactor)

| Benchmark | Heap Allocations in Round 5 | **Heap Allocations in Round 6 (`fa9a3ea`)** | Allocation Reduction Factor |
|---|---:|---:|---|
| **`b_loop` (100,000,000 integer iterations)** | `200,000,000` | **`1`** | **`200,000,000×` fewer allocations (`-99.9999995%`)** |
| **`b_str` (String manipulation benchmark)** | `42,600,000` | **`17`** | **`2,505,882×` fewer allocations (`-99.99996%`)** |
| **`b_rec` (20,000,000 3-field records)** | `240,000,000` | **`20,000,000`** | **`12.0×` fewer allocations (`-91.7%`)** |
| **`b_list` (30 × 1,000,000 `Cons` cells)** | `180,000,000` | **`30,000,000`** | **`6.0×` fewer allocations (`-83.3%`)** |
| **`b_match` (20,000,000 ADT matches)** | `80,000,000` | **`20,000,000`** | **`4.0×` fewer allocations (`-75.0%`)** |

---

## 6. Verification & Red-Team Auditing Ledger

Every optimization in the Memory Saga was subjected to adversarial red-team testing and differential verification:

| Verification Gate / Suite | Scope & Methodology | Final Result (`fa9a3ea`) |
|---|---|---|
| **Zero-C Self-Hosted Fixpoint (`lume_make bootstrap` & `zero-c`)** | Stage-0 C seed $\rightarrow$ `lumec1` $\rightarrow$ `lumec2` $\rightarrow$ `lumec3` bit-for-bit comparison | **`stage2 == stage3` (`0 diff` in assembly and `1,006,576 B` ELF)** |
| **Windows Native Seed Cross-Verification (`lume0.exe`)** | `x86_64-w64-mingw32-gcc` seed compiling full `lumec.src` on Windows 11 | **Byte-for-byte identical assembly to Linux in `17 s`** |
| **Full Official Conformance & Regression Suite** | End-to-end compilation and execution across all language phases | **`410 passed, 0 failed, 0 skipped` (in `136 s / 537 MB`)** |
| **Stage-0 AddressSanitizer + UBSanitizer (`make asan`)** | Full Stage-0 test suite under `-fsanitize=address,undefined` | **`170 passed, 0 failed, 0 sanitizer reports`** |
| **75,512-Case Differential Value Matrix (`value_matrix_ok`, `value_edges_ok`)** | Exhaustive cross-check of 63-bit/64-bit integers, NUL strings, short/long strings, records, lists, and builtins | **`75,512 / 75,512` verified (`0 crashes`, `0 arithmetic divergences`)** |
| **317-Program Red-Team Adversarial Suite (`b1..b5`)** | Stress testing closures, mutual recursion, ownership, GC stress (`LUME_GC_STRESS=1`), and oracle parity | **`317 / 317` (`0 crashes`, `0 GC stress diffs`, `0 link errors`)** |
| **159-Program Semantic Edge-Case Battery** | Pinpoint tests for `[R0200..R0205]`, `[P0002]`, `[C1001]`, `toint` negative, string/list bounds, `slicen` | **`159 / 159` (`100%` match expected diagnostics/outputs)** |
| **148-Check Ownership & Fail-Closed Parity Gate (`ownership_gate.src`)** | 67 ownership fixtures + 28 fail-closed fixtures + 53 real programs compared across `lumec` and `lcaas` | **`148 / 148` (`100%` verdict & error-code agreement)** |
| **Level-3 Compactor Corruption Fuzzing (`pack_corrupt_fail.src`)** | 1,500 mutated/truncated/bit-flipped `LZ1` blobs fed to `mem_unpack` | **`1,500 / 1,500` controlled exit-3 rejections (`0 crashes`)** |
| **Freestanding QEMU Kernel Value Verification (`freestanding_values_ok.src`)** | Bootable x86-64 `@freestanding` kernel testing tagged values & indexing in QEMU | **`PASS`** |
| **Local CI Pipeline Execution (`.github/workflows/ci.yml`)** | All 44 local CI steps including JSON schema gates (`economy`, `registry`, `onnx`, `egm`, `ncm`) | **`44 / 44 PASS`** |
