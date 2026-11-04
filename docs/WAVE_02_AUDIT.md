# Wave 2 (`Onda 2` — `v0.3.0-alpha.2` @ `2956108`) Complete Engineering Audit & Verification Report

## 1. Scope of Wave 2 (`v0.3.0-alpha.2` @ `2956108`)
Wave 2 delivered six core capabilities across the standard library, driver telemetry, native x86-64 code generator, and Phase 3 effect checker:
1. **2.1 Capability-Sealed E-Capsules (`std.capsule`, `#430`):** `compiler/stage1/capsule.src` and `compiler/stage1/capsule_ok.src`.
2. **2.2 Standard Library Region Arenas (`std.arena`, `#404`):** `compiler/stage1/arena.src` and `compiler/stage1/arena_ok.src`.
3. **2.3 Process & Heap Memory Telemetry (`--memory`):** `lume build --memory` and `lume run --memory` backed by `os_self_maxrss_kb`, `os_last_child_maxrss_kb`, `__lume_heap_stats`, and `__lume_heap_peak_used`.
4. **2.4 Pre-Allocated Small-Int Cache `[-1..1024]` (`small_ints`):** Zero-allocation `mkint` fast-path in `compiler/stage1/lume/05_codegen.src`.
5. **2.5 Self-Tail-Call Optimization (`jmp .Ltail_<fn>`):** Constant-stack tail-recursion lowering in `compiler/stage1/lume/05_codegen.src`.
6. **2.6 `[E0200]` Effect & Purity Enforcement on Arena Builtins:** Compile-time rejection of `__lume_arena_new` / `__lume_arena_alloc` inside `/ pure` functions in `compiler/stage1/lume/06b_phase3.src`.

---

## 2. Line-by-Line Subsystem Audit & Live Verification Proofs

### 2.1 Capability-Sealed E-Capsules (`std.capsule`, `#430`)
- **Source Files:** `compiler/stage1/capsule.src` (lines 1–67), `compiler/stage1/capsule_ok.src`.
- **Implementation Details:**
  - `capsule_sha256_text(data)` (line 11): Computes full FIPS 180-4 SHA-256 over arbitrary payload text via `fs_blocks`.
  - `capsule_seal(name, cap_grant, payload)` (line 15) & `capsule_verify(cap)` (line 17): Binds payload to `(magic: "LUME_CAPSULE_1", name, cap_grant, digest)`.
  - `capsule_open(cap, required_cap)` (line 21) & `capsule_rebind(cap, required_cap, new_payload)` (line 23): Enforces SHA-256 integrity and capability lattice (`io` subsumes `pure`), failing closed with `[C0430]` on tampering or insufficient capability.
  - `capsule_seal_proven` (line 37) & `capsule_replay` (line 41): Binds deterministic replay clock `tick`, LCG `seed` (`capsule_prng_step`), and `proof_digest`.
- **Live Execution Proof:**
  ```text
  $ /root/.lume/bin/lume test compiler/stage1/capsule.src
    ok   test_fs_sha256_file_empty
    ok   test_fs_sha256_file_abc
  2 passed, 0 failed

  $ /root/.lume/bin/lume test compiler/stage1/capsule_ok.src
    ok   test_fs_sha256_file_empty
    ok   test_fs_sha256_file_abc
    ok   test_capsule_seal_and_open
    ok   test_capsule_deterministic_replay
    ok   test_capsule_v2_bundle_vcr_and_replay
  5 passed, 0 failed
  ```

### 2.2 Standard Library Region Arenas (`std.arena`, `#404`)
- **Source Files:** `compiler/stage1/arena.src` (lines 56–63), `compiler/stage1/arena_ok.src`.
- **Implementation Details:**
  - Exposes `arena_new(cap_hint)`, `arena_alloc(arena, n)`, `arena_reset(arena)`, `arena_destroy(arena)`, `heap_stats()`, `heap_peak_used()`, `peak_rss_kb()`, and `child_peak_rss_kb()`.
- **Live Execution Proof:**
  ```text
  $ /root/.lume/bin/lume test compiler/stage1/arena_ok.src
    ok   test_heap_stats_fields
    ok   test_heap_peak_tracked
    ok   test_arena_bump_in_range
    ok   test_arena_reset_reuses_base
    ok   test_arena_stays_live_after_reset
    ok   test_arena_bulk_1m_cells_used_drop
    ok   test_arena_many_small_allocs_drop
    ok   test_without_arena_monotonic_growth
  8 passed, 0 failed
  ```

### 2.3 Process & Heap Memory Telemetry (`lume build --memory` / `lume run --memory`)
- **Source Files:** `compiler/stage1/lume_driver.src` (lines 120–136), `compiler/stage1/lume/05_codegen.src` (lines 403, 502).
- **Implementation Details:**
  - `os_last_child_maxrss_kb` reads `ru_maxrss` from the Linux `wait4` (`%rax = 61`) `struct rusage` buffer at `hw_scratch+160(%rip)` (persisted to `hw_scratch+272(%rip)`).
  - `os_self_maxrss_kb` calls Linux `getrusage(RUSAGE_SELF, ...)` (`%rax = 98`, `%rdi = 0`).
  - `ld_report_memory(tag)` (line 122 of `lume_driver.src`) emits `[memory:<tag>] child_maxrss_kb=... self_maxrss_kb=... heap_used=... heap_peak=... heap_allocs=...` to `stderr`.
- **Live Execution Proof:**
  ```text
  $ /root/.lume/bin/lume build --memory compiler/stage1/arena_ok.src -o /tmp/w2_mem_bin
  [memory:build] child_maxrss_kb=7660 self_maxrss_kb=1280 heap_used=1107895 heap_peak=1108007 heap_allocs=50558

  $ /root/.lume/bin/lume run --memory compiler/stage1/arena_ok.src
  [memory:run] child_maxrss_kb=1352 self_maxrss_kb=3712 heap_used=1102256 heap_peak=1102368 heap_allocs=50298
  ```

### 2.4 Pre-Allocated Small-Int Cache `[-1..1024]` (`small_ints`)
- **Source File:** `compiler/stage1/lume/05_codegen.src` (lines 510, 515).
- **Implementation Details:**
  - Reserves `.lcomm small_ints, 24624` (`1026 * 24` bytes) in `.bss`.
  - At startup (`_start`), `call lume_init_small_ints` populates each 24-byte slot for integers `-1` through `1024`.
  - `mkint` checks `cmpq $-1, %rdi; jl mkint_alloc; cmpq $1024, %rdi; jg mkint_alloc` and returns `small_ints + (%rdi + 1) * 24` in $O(1)$ with zero heap allocation.

### 2.5 Self-Tail-Call Optimization (`jmp .Ltail_<fn>`)
- **Source File:** `compiler/stage1/lume/05_codegen.src` (lines 237–260).
- **Implementation Details:**
  - `lafn_typed` (line 260) emits label `.Ltail_<nm>:` immediately after the frame allocation (`pushq %rbp; movq %rsp, %rbp; subq $frame, %rsp`).
  - `laexpr_tail` (lines 248–253) threads tail position through `If`, `LetIn`, and `Match` arms into `lcallx_tail` (line 238) and `lcall_tail` (line 237), emitting argument evaluation + `popq` into `%rdi..%r9` + `jmp .Ltail_<nm>` instead of `call <nm>`.
- **Live Execution Proof (100,000-deep tail recursion with 0 stack overflow):**
  ```text
  $ printf 'fn sum_tco(n, acc) = if n <= 0 then acc else sum_tco(n - 1, acc + n)\nprint sum_tco(100000, 0)\n' > /tmp/w2_tco_test.src
  $ /root/.lume/bin/lumec < /tmp/w2_tco_test.src > /tmp/w2_tco_test.s
  $ grep -n 'sum_tco:\|.Ltail_sum_tco\|jmp .Ltail_sum_tco\|lume_init_small_ints' /tmp/w2_tco_test.s
  34:sum_tco:
  38:.Ltail_sum_tco:
  86:    jmp .Ltail_sum_tco
  223:lume_init_small_ints:
  1259:    call lume_init_small_ints
  $ /root/.lume/bin/lume run /tmp/w2_tco_test.src
  5000050000
  ```

### 2.6 `[E0200]` Effect & Purity Enforcement on Arena Builtins
- **Source File:** `compiler/stage1/lume/06b_phase3.src` (line 226).
- **Implementation Details:**
  - `kprim_eff(cnm)` classifies `arena_new`, `arena_alloc`, `__lume_arena_new`, and `__lume_arena_alloc` under the `"alloc"` effect, causing any `/ pure` function invoking them to fail closed with `[E0200]`.
- **Live Execution Proof:**
  ```text
  $ printf 'fn bad_pure_arena(n: int) -> int / pure = __lume_arena_new(n)\nprint bad_pure_arena(1024)\n' > /tmp/w2_pure_arena_err.src
  $ /root/.lume/bin/lumec < /tmp/w2_pure_arena_err.src
  lume: effect error [E0200]: function 'bad_pure_arena' performs undeclared effect '{alloc}' (fix-it: add '/ {alloc}' to the signature of 'bad_pure_arena' or handle it with 'with handler')
  ```

---

## 3. Summary Verification Matrix
| Subsystem | Target Files | Verification Result |
| :--- | :--- | :--- |
| **2.1 `std.capsule` (`#430`)** | `capsule.src`, `capsule_ok.src` | `PASS` (`2/2` + `5/5` tests passed) |
| **2.2 `std.arena` (`#404`)** | `arena.src`, `arena_ok.src` | `PASS` (`8/8` tests passed) |
| **2.3 `--memory` Telemetry** | `lume_driver.src`, `05_codegen.src` | `PASS` (`[memory:build]` & `[memory:run]` RSS/heap reported) |
| **2.4 Small-Int Cache `[-1..1024]`** | `05_codegen.src` (`small_ints`, `mkint`) | `PASS` (`lume_init_small_ints` & 24624-byte `.bss` table verified) |
| **2.5 Self-Tail-Call `jmp`** | `05_codegen.src` (`laexpr_tail`, `.Ltail_`) | `PASS` (`sum_tco(100000, 0) == 5000050000` via `jmp .Ltail_sum_tco`) |
| **2.6 `[E0200]` Arena Purity** | `06b_phase3.src` (`kprim_eff`) | `PASS` (`[E0200]` diagnostic emitted on `/ pure` arena call) |
