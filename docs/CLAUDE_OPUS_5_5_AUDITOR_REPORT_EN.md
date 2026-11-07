# Lume Audit on Commit `9cddc82` (Round 6 — Soundness & Fuzzer Auditor Report)

> **Original Portuguese Report:** [`docs/CLAUDE_OPUS_5_5_AUDITOR_REPORT.md`](CLAUDE_OPUS_5_5_AUDITOR_REPORT.md)
> **GitHub Issue Tracker:** [Issues #1–#21](https://github.com/OmegaSoftDLL/lume/issues)

**Verdict:** The execution foundation is strong, but the formal guarantees are not yet sound. Across 24,000 generated programs, native execution did not produce a single wrong arithmetic answer. However, the prover certifies false contracts outside linear integers, and Perceus in-place reuse can overwrite a live aliased value. My **overall score is 6.5/10**. It drops compared to the previous 8.0 because I audited formal proof soundness for the first time, not because Round 6 regressed.

## Scope and Limits of This Report

- **This list is exhaustive over what was collected**, not over every possible program in the language.
- **The four subagent reviewers were interrupted before writing final prose reports.** I extracted their findings directly from their session transcripts.
- **Audited on a clean clone of `9cddc82`**, bootstrapped from the C seed.

| Area | Covered | Left Out |
|---|---|---|
| Soundness | `b01` through `b09` | `b09` read from transcript; `b10` did not run (concurrency, tensors, decimal, money) |
| Specification | Literals, declarations, and seed dialect | Operator batches, control flow, patterns, and numerics |
| Stdlib & CLI | Only a slice of `query` | **Largely unevaluated in this run** |
| Claims | CI inventory and missing files | Origin of 75,512 count and local CI step count |
| Sweeps | Native differential fuzzing & 3-evaluator fuzzing | Full source sweep did not complete on this commit |

**Provenance of each item:** **[M]** reproduced directly by me on this commit; **[R]** executed by a reviewer subagent and verified from its transcript output.

**Severity levels:** **S1** silent wrong or unsafe answer; **S2** crash or wrong diagnostic; **S3** friction / ergonomics; **S4** cosmetic.

## 1. Scores by Area

| Area | Score | Reason |
|---|---:|---|
| AI-First Design | **8.5** | Oracle and fix-its are very good, though `check` and `build` still diverge on trait impls and decimals (items 21–24) |
| Memory / Atomic Compactor | **8.5** | Compact tagged values and arenas passed 32 probes; 537 MB RSS confirmed |
| Ownership | **5.5** | Catches direct cases, but misses aliases through tuples, records, and untyped returns, and Perceus reuse corrupts live aliased data |
| QF_LIA Formal Verification | **4.0** | `"proven"` is not reliable outside pure linear integer arithmetic |
| Codegen / Runtime | **8.0** | Zero native execution errors across 24,000 fuzzed programs; score reduced by silent I/O write loss and constant overflow panic |
| Practical Robustness | **6.5** | Zero crashes on the 317-program battery, but silent errors remain outside known batteries |
| Breadth vs. Depth | **5.5** | Huge surface area with two dialects (`.lume` vs. `.src`) and partial features |
| **Overall** | **6.5** | A language promising formal proof cannot certify false contracts as `"proven"` |

### Confirmed Claims

| Claim | Measured Result |
|---|---|
| 410/410 test suite | **Confirmed:** 410 passed, 0 failed; 215 s / 537 MB with another job running |
| Bootstrap in 22 s / 537 MB | **Confirmed in RSS:** 26.45 s / 537 MB |
| 317 programs with zero crashes | **Confirmed:** 188 run, 57 rejected at compile time, 72 trap with clean message |
| 159/159 battery | **Confirmed** with my battery |
| Inputs for 317 and 159 batteries | **Not in the repository**, nor `snap.py` and `ana.py` |
| 75,512 differential cases | **Not verified in repo** |
| 44/44 CI steps | **Not verified:** `ci.yml` has 17 jobs and 87 steps |

### What the Fuzzers Showed

- **Differential fuzzer against an independent Python reference model:** Out of 20,000 generated programs, 19,954 matched identically, including under GC stress. The remaining 46 panicked the compiler on constant integer overflow (item 26). The initial 196 divergences were a bug in my Python model for `bit_shr`.
- **Three-evaluator fuzzer (4,000 expressions across native, comptime, and oracle):** Native got all 4,000 right, and 3,626 agreed across all three evaluators. The oracle diverged on 282 (returning `<runtime>`) and `comptime` on 113 (string comparison).

---

## 2. Issue List (79 Items)

### A. False Proofs and Contracts

**1. [S1][R] Strings are proven as if they were linear integers.** `06b_phase3.src`, `vlin_bin_op`: `+` enters linear integer arithmetic without checking that operands are `int`. Outputs `xy`, status `proven`:
```lume
fn f(a: str, b: str) -> str ensures result == b + a = a + b
```
The same happens with `law cc(a: str, b: str) = a + b == b + a` and `(a + b) - b == a`.

**2. [S1][R] Bitwise operations produce false proofs.** `06b_phase3.src`, `vlin_call`/`veval_call`:
```lume
law b1(x: int) = bit_and(65537, 65536) == 0    # proven; actual value is 65536
law b2(x: int) = bit_or(65536, 1) == 1         # proven; actual value is 65537
```
`bit_shl(x, 2)` with `ensures result >= 0` is also marked `proven` and yields a negative number at `x = 2^61`.

**3. [S1][R] True bitwise laws are refuted.** Same root cause as item 2; blocks the build:
```lume
law l(x: int) = bit_and(65536, 65537) == 65536    # [V0001] refuted
```

**4. [S1][R] User function sharing an intrinsic name is proven using the intrinsic's semantics.** `06b_phase3.src:1215` (`veval_call`) and `:1553` (`vlin_call`) match the function name before checking user definitions:
```lume
fn clone(x: int) -> int = x + 1
fn f(x: int) -> int ensures result == x = clone(x)    # proven; f(1) returns 2
```
Also affects `old`, `verify`, `dec_add`, and `array_select`. Conversely, rejects valid contracts on user functions named `get` and `signal`.

**5. [S1][R] Variable capture during substitution in the prover.** `06b_phase3.src`, `vtemp_subst_var`:
```lume
fn f(x: int) -> int ensures result != 7 = let r = {a: x} in let x = 5 in r.a
print str(f(7))    # proven; prints 7
```

**6. [S1][R] `requires` is neither proven nor checked at runtime when called from an unconstrained caller.** Once a function is marked `proven`, its runtime precondition check is elided even for unproven callers:
```lume
fn f(x: int) -> int requires x >= 0 ensures result >= 0 = x
fn g(y: int) -> int = f(y)
print str(g(toint("-5")))    # proven; prints -5, exit 0
```

**7. [S1][R] `runtime_checked` does not always emit a runtime check.**
```lume
fn f(x: int) -> int requires x <= -100 ensures result >= 0 = x % 2    # f(-101) returns -1
fn f(x: int) -> int requires x >= 0 and x <= 3000000000 ensures result <= 3000000000 = x
print str(f(toint("4000000000")))                                     # prints 4000000000, exit 0
```
`bit_shr` with `ensures result == x / 2` behaves the same way.

**8. [S1][R] False `law` declarations pass silently when not refuted.** An unrefuted `law` becomes `runtime_checked`, but nothing executes it at runtime:
```lume
law bad(x: int) = x != 12345
law bad2(x: int, y: int) = x * y != 391
```

**9. [S1][R] `total fn` accepts non-terminating functions.** `06b_phase3.src`, `[A0002]` check does not require a base case, does not detect mutual recursion cycles, and does not track recursion through higher-order function values:
```lume
total fn f(n: int) -> int = if n > 0 then f(n - 1) else f(n - 1)
total fn a(n: int) -> int = if n <= 0 then 0 else b(n)
total fn b(n: int) -> int = a(n)
fn app(f, x: int) -> int = f(x)
total fn c(n: int) -> int = app(c, n)
```

**10. [S1][R] Function parameter shadowing a global function is proven as the global function.**
```lume
fn inc(x: int) -> int = x + 1
fn dec1(x: int) -> int = x - 1
fn apply(inc, x: int) -> int ensures result == x + 1 = inc(x)
```
Marked `proven`; calling `apply(dec1, 5)` traps at runtime.

**11. [S1][R] Record `invariant` and refinement types (`where`) only check compile-time constants.** Runtime values pass unchecked with exit 0:
```lume
type P = record x: int invariant x > 0
fn mk(a: int) -> P = P{x: a}                       # mk(toint("-1")) succeeds
type Pos = int where self > 0
fn g() -> int = let p: Pos = toint("-7") in p      # same in record, list, and constructor
```

**12. [S1][R] `@bound` does not traverse into `match` or record literals.** Structural WCET cost in `06b_phase3.src`:
```lume
@bound(cycles: 20)
fn g(n: int) -> int = {a: slow(100000000)}.a       # budget_checked
```
The same trick allows calling `mem_pack` inside `@bound`, bypassing `[V0002]`.

**13. [S2][R] Valid contract is refuted when `if` compares string literals.**
```lume
fn f() -> int ensures result == 1 = if "a" == "b" then 0 else 1
```
Fails with `[V0001]` and an empty counterexample.

**14. [S2][M+R] Oracle and `lume build` diverge on caller precondition obligations.** Below, `lume build` succeeds while the oracle rejects with `[V0001]`:
```lume
fn f(x: int) -> int requires x >= 0 ensures result >= 0 = x
fn g(y: int) -> int requires y <= 0 ensures result == y = f(y)
```
The same happens with `eventually`.

**15. [S3][R] Proofs hold only modulo no runtime integer overflow.** `ensures result == 2 * x` on `x + x` is marked `proven` and traps on overflow at `2^62`. Acceptable under trapping arithmetic, but should be explicitly documented.

**16. [S3][R] Nested quantifiers reusing the same bound variable name confuse substitution.** `vtemp_subst_var`; reproduces with `forall_range(i, 0, 40, forall_range(i, 50, 90, 1 == 0))`.

### B. Ownership and Perceus Reuse

**17. [S1][R] Perceus in-place reuse overwrites a live aliased value.** Uniqueness gate (`06b_phase3.src`/`own_flow.src`) trusts declared return types or call context. Expected `1101`; actual `101101`:
```lume
type L = enum Nil | Cons(int, L)
fn bump(own xs: L) -> L = match xs
    Nil => Nil
    Cons(h, t) => Cons(h + 100, t)
fn peek(xs: L) -> int = match xs
    Nil => 0
    Cons(h, t) => h + 0
pub fn launder(x) -> int = x
fn run() -> int = let a = Cons(1, Nil) in let c = launder(a) in let d = bump(own c) in peek(a) * 1000 + peek(d)
print run()
```

**18. [S1][R] Valid postcondition fails at runtime because Perceus reuse mutated the input (`xs` / `old(b)`) in-place before `ensures` evaluated.**
```lume
fn bump(own xs: L) -> L ensures peek(result) == peek(xs) + 100 = match xs ...
print peek(bump(own Cons(1, Nil)))
```

**19. [S2][R] Double move via tuple destructuring, helper return, or `match` scrutinee is accepted.** `own_flow.src`:
```lume
fn run() -> int = let a = Cons(1, Nil) in let (x, y) = (a, a) in eat(own x) + eat(own y)
fn run2() -> int = let a = Cons(1, Nil) in let b = ident(a) in let z = eat(own a) in peek(b)
fn run3() -> int = let a = Cons(1, Nil) in match a
    Cons(h, t) => eat(own a) + h
```
`{ a with x: 2 }` after moving `a`, and repeated `eat(own a)` at top-level also pass.

**20. [S2][R] Linear `resource type` leaks without `[O0004]`.** `[O0004]` only sees direct `let` bindings of a literal constructor:
```lume
fn run() -> int = let g = open_h() in 7                     # open_h without return annotation
fn run2() -> int = open_h().fd + open_h().fd
fn sink(own h: H) -> int = 0                                # receives own h and never consumes it
```
Also passes across `if`, `match`, nested `let`, and list elements.

**Additional ownership notes [S3][R]:**
- Borrows escape through `ident(borrow(x))` and `[borrow(x)]`.
- `add(c, 2)` compiles without `mut` at the call site for a `mut` parameter.
- **[Known Limit]** `own` passed through a first-class function value is shared rather than moved.

### C. Compiler

**21. [S2][R] Decimal literal without `use decimal` fails at link time.** `name_flow.src`, `nf_libmod` does not auto-link `decimal_add` / `decimal_div`.
**22. [S2][R] Extra method in `impl` compiles, passes the oracle, and fails at link time (`undefined symbol`).**
**23. [S2][R] `impl` method signature is not checked against the `trait` declaration.**
**24. [S2][R] Two traits with the same method name on different types trigger false `[T0401]`.**
**25. [S2][M] Undefined uppercase constant becomes a nullary constructor (`const A: int = B` prints `B`).** `name_flow.src`, `nf_var` / `nf_isctor`.
**26. [S2][M] Constant overflow in `let` crashes the compiler (`lume: integer overflow` with no diagnostic code or source span).** Happened in 46 of 20,000 fuzzed programs (`let v = 9223372036854775807 * 5 in 1`).
**27. [S1][M] Top-level `let` reading a later global prints garbage (`{__fn_id: 1, __env: {}}`) without error.**
**28. [S1][R] Type annotations are ignored when `06_typecheck.src` falls back to `any`.** (`const MAX: int = "a"`, `let x: int = "a"`, `fn launder(x) -> int = x`).
**29. [S1][R] Uppercase `const` in a `match` pattern is treated as a constructor tag rather than compared by value.**
**30. [S1][R] Unclosed attribute `@foo(1` silently discards the rest of the file with exit 0.**
**31. [S1][R] Triple-quoted string `"""line1\nline2"""` prints empty.**
**32. [S1][R] `f"{x:>3}"` and `{x:.2}` in `.src` print the format specifier literally.**
**33. [S1][R] `/ pure` violation passes for `fs_read_file("/tmp/x")` and unknown effect `/ {Nope}`.**
**34. [S1][R] Effect operation called without a handler returns `0`.**
**35. [S1][R] `errdefer` treats any negative integer return (`x = -5`) as an error and runs rollback on normal return.**
**36. [S2][R] Non-exhaustive `match` on integers, lists, or nested patterns only fails at runtime.**
**37. [S2][R] `extern "c"` generates an ELF binary that fails dynamic symbol lookup (`rc=127`).**
**38. [S2][R] Unknown type identifiers in `record`, `impl`, and duplicate enum variants (`enum A | A`) compile without error.**
**39. [S3][M] Compilation scales quadratically on huge files (16,000 functions take 5.19 s, ~3.3× per doubling).**
**40. [S3][M] `comptime("a" < "b")` fails with a type error even though native execution supports string comparison.**
**41. [S3][M] Oracle returns `<runtime>` on `at`, `slice`, and similar string builtins (282 of 4,000 expressions).**
**42. [S4][R] Diagnostic `[D0002]` exposes internal mangled name `__impl_M_s`.**

### D. Runtime and I/O

**43. [S1][M] Write errors are ignored in `flush` and `fs_write_sync` (`/dev/full` returns `1` / `rc=0`).**
**44. [S1][M] Writes larger than 2 GiB silently truncate after a single `write` syscall without a loop.**
**45. [S1][M] Paths containing a NUL byte (`"q" + chr(0) + "evil"`) silently truncate to `"q"`.**
**46. [S1][M] Raw memory and privileged CPU instructions (`mmio_volatile_write64`, `mem_set`, `atomic_xadd64`, `cpu_cli`, `port_in8`) are callable from normal safe code without a gate.**
**47. [S1][M] `__lume_global_set(99999, 1)` executes without a bounds check.**
**48. [S2][M] `__lume_try_*` internal API lacks guard checks when called without `begin` or across returned frames (`rc=139`).**
**49. [S2][R] User-defined `query_order` causes `rc=139` segfault.**
**50. [S3][M] Infinite recursion takes 20 s and 4 GiB to fault when `ulimit -s unlimited` is set.**
**51. [S3][M] No default heap cap (`LUME_HEAP_CAP` is opt-in).**
**52. [S3][M] `os_run` returns raw `wait4` status and does not search `PATH` in 2-arg form.**
**53. [S3][M] `lasm` without `--strict` accepts undefined symbols (producing a binary that segfaults).**
**54. [S3][M] `read()` does not distinguish EOF from an empty line.**
**55. [S4][M] Imprecise runtime error messages (`arena_alloc("x", 8)` says `arithmetic needs integers`).**
**56. [S3][M] `bit_shr` is arithmetic right shift, which is not documented in the manual.**

### E. Security (`@secret`)

**57. [S1][R] `[C0009]` on `mem_pack` is bypassed via helper functions, lambdas, let-wrappers, records, and `match` bindings.**
**58. [S1][R] Branching on a `@secret` value passes inside helpers, records, lambdas, and `spawn`.**
**59. [S1][R] Secret-dependent indexing passes on `sec_index` and `sec_list_index`.**
*(Note on 57–59: taint analysis is currently intraprocedural.)*

### F. Documented Language Surface Missing in Native Compiler

**60. [S1][R] Two dialects exist (`.lume` in `lume0` vs. `.src` in `lumec`), and the manual mixes both.**
**61. [S2][R] Missing literals/comments in `.src`:** `1_000`, `0xFF`, `0b1`, `0o7`, `1e3`, `'a'`, `r"..."`, `b"..."`, `re"..."`, `#[ ]#`, Unicode identifiers, and raw identifiers `` `let` ``.
**62. [S2][R] Missing declarations in `.src`:** `mod`, `use std.x`, `use ... as`, selective imports, `pub(crate)`, named enum payloads, default record fields, `distinct`, `int in 0..150`, `error A | B`, `type X = [int]`, `fn main()`.
**63. [S2][R] Missing trait features:** default methods, associated types, trait bounds, `dyn`, inherent `impl`, supertraits, generic traits.
**64. [S2][R] Missing effect/type syntax:** `perform`, `handle ... with`, `fn(int) -> int` parameter type syntax, `-> ()`, native `float`.
**65. [S2][R] In the Stage-0 seed:** `0xFFFFFFFFFFFFFFFF` wraps silently, `300` fits in `u8`, and format specifiers `:x`, `:b`, `:o`, `:03` are ignored.
**66. [S3][R] `print` is only valid at top level in `.src` (inside a function it gives `[R0200]`).**
**67. [S3][R] Value coercion footguns:** `1 + "a"` concatenates; `not 5` is `0`; `true + 1` is `2`; `toint("12x")` is `12`.
**68. [S3][M] `count` and indexing are byte-oriented (`count("é") == 2`).**
**69. [S3][R] Typechecking is local with `any` fallback except on lambdas, rather than global Hindley-Milner.**
**70. [LIMIT, S3] Known limits:** builtins/effects are not values; `r.f(1)` is a method call; `id[int](x)` is `[R0204]`; up to 4 live arenas; `.so` does not GC; freestanding `xs[i]` returns 0 out of bounds.
**71. [S3][M] Hosted runtime has no OS threads (`clone`/`futex`).**

### G. Project, Tests, and Documentation

**72. [S2][M+R] Unreproducible evidence:** inputs for `b1..b5` (317 programs), the 159-program battery, `snap.py`, and `ana.py` should be committed under `tests/`.
**73. [S2][M] `use query` requires `use table` and `use decimal` to be imported manually first.**
**74. [S3][M] A local file named `query.src` next to a program shadows the standard library `query` module.**
**75. [S3][R] Docs reference removed/nonexistent paths:** `formal/lean/LumeCore.lean`, `docs/CLAUDE_OPUS_AUDIT.md`, `docs/install.ps1`, `docs/GITHUB_REFERENCE_INNOVATIONS_REPORT.md`.
**76. [S3][M] Outdated version references (`v1.0.0`) in `LUME_TECHNICAL_PAPER.md:106`.**
**77. [S3][M] Dossier cites `75,512` and `44/44` without a checked-in script that reproduces those exact counts.**
**78. [S3][R] `PROJECT_STATE.md` claims forward top-level `let` traps at runtime, which is contradicted by item 27.**
**79. [S3][M] Seed ASan suite skips 3 tests without documented audit notes.**

## Suggested Remediation Order

1. **Proofs (items 1 to 11):** Reject to `unknown`/`runtime_checked` anything that is not pure linear integer arithmetic, and always enforce `requires` at unproven call sites.
2. **Perceus reuse (items 17 and 18):** The only real live-data corruption found; disable reuse whenever alias escape cannot be ruled out.
3. **Silent I/O loss (items 43 to 45):** Check `write` return values, loop on partial writes >2 GiB, and reject NUL bytes in file paths.
4. **Close `any` in explicit type annotations (item 28)** and unify on a single canonical dialect (item 60).
5. **Commit all fuzzers and adversarial batteries (`b1..b5`, 159 programs) into `tests/`.**

---

# Complete Session History `98f9ef83-75f8-45a1-8c37-2f955dd879e1` (Round 5 Reports and Updated Scoreboard)

---
## [Line 4024 | 2026-11-07T03:23:50.237Z] — Round 5 Final Report (Initial Pass)

**Round 5 is applied in `C:\Users\Ricardo.Bueno\lume`, reaching 404 passed, 0 failed, 0 skipped, and byte-identical `stage2 == stage3`.**

### Memory and Speed (Round 5 vs. Baseline `2421a92`)

| Metric | Before (`2421a92`) | After Round 5 |
|---|---|---|
| Seed bootstrap without cache | 194.8 s / 12.7 GB | ~165 s / 2.5 GB |
| Seed bootstrap with tool cache | not measured | 72 s / 1.2 GB |
| Seed compiling `lumec.src` | 102.0 s / 12.5 GB | **5.5 s / 472 MB** |
| `lumec` self-compiling | 1.82 s / 1,165 MB | 2.27 s / **187 MB** |
| `lasm` on 6.6 MB assembly | 6.92 s / 3,556 MB | 4.95 s / 1,217 MB |
| `levolve` build without cache | 13.8 s / 6.76 GB | 31.1 s / 2.47 GB |
| `lmanual` build without cache | 1.10 s / 846 MB | 0.86 s / 91 MB |
| 30M-allocation churn benchmark | 3.30 s / 5,721 MB | 3.77 s / **66 MB** |
| String benchmark | 5.09 s / 6,013 MB | 2.59 s / **66 MB** |
| `fib(38)` | 1.19 s | 1.22 s |

---
## [Line 5390 | 2026-11-07T06:55:15.468Z] — Round 5: Updated Scoreboard After Closing 10 Defects

**All ten defects from the initial Round 5 review were closed, raising the Round 5 score from 7.5 to 8.0.** The test suite passed 404/404, and all 317 adversarial programs (`b1..b5`) ran with zero crashes.

### The 317 Adversarial Programs (`b1..b5`)

| Outcome | Initial R5 Report | After 10 Fixes |
|---|---:|---:|
| Crash | 13 | **0** |
| Difference under GC stress | 2 | **0** |
| Oracle without JSON | 4 | **0** |
| Oracle stopped with `E0002` | 1 | **0** |
| Link error | 3 | **0** |

### The Ten Closed Round 5 Defects

| # | Defect | Behavior After Fix |
|---|---|---|
| 1 | `print true`, `fn f() -> bool = true` | Works; prints `1` |
| 2 | `fn f(x: int) -> bool = x > 0` | Works |
| 3 | `slice("abc", 1)` missing arity check | Rejected with `[R0202]` |
| 4 | Out-of-bounds read in `slicen` | Clamped to actual string length |
| 5 | `str(inc)` and named functions inside lists | Work |
| 6 | Constants, indexing, and closures inside `with handler` / `with alloc` | Work |
| 7 | `min / -1`, `min % -1` (`SIGFPE`) | Traps cleanly with `lume: integer overflow`, exit 3 |
| 8 | Symbol collision with `strlen` | `[R0203]` at call site, `[R0201]` at definition |
| 9 | Closure with 9 args, 0-arg lambda, HOF without closures | Work |
| 10 | `own` and `mut` functions used as first-class values | Work |
