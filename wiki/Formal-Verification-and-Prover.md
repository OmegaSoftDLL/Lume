<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="76" height="76" align="left" />
  Formal Verification &amp; Embedded `OmniProof-v4` Prover
</h1>
<br clear="left"/>

Unlike toolchains that delegate verification to gigabyte-scale external C++ solvers with unpredictable timeouts, **Lume embeds its multi-theory theorem prover (`OmniProof-v4`) directly inside the self-hosted compiler** (`compiler/stage1/lume/06_typecheck.src`, `06b_phase3.src`, `lcaas.src`) and pairs it with an **independent, zero-compiler-import proof certificate kernel (`compiler/stage1/lcert.src`)**.

---

## 1. Live `OmniProof-v4` Verification Metrics (`lume self-prove`)

Running `lume self-prove --json` executes live compile-time proofs and native tests across the entire self-hosted standard library and domain engine suite with zero external scripts:

| Metric | Verified Result (`v1.1.0`) |
| :--- | :--- |
| **Embedded Proof Engine** | `LumeCompiler-Embedded-OmniProof-v4` |
| **Domain Proof Batteries** | **`16 / 16` certified (`ok: true`)** |
| **Formal Mathematical Obligations Verified** | **`1,682`** (`proven` + `@bound` budget-checked) |
| **Runtime-Fallback or Refuted Obligations** | **`0`** |
| **Native Unit Tests Passed** | **`372`** (`exit 0`) |
| **Translation-Validated `lstd.src` Functions** | **`70` functions (`426` proof cases)** |
| **Verified Sovereign Domains** | **`122` domains** |

---

## 2. Multi-Theory Decision Procedures

| Theory / Analysis | Diagnostic Codes | Self-Hosted Decision Procedure |
| :--- | :--- | :--- |
| **`QF_LIA` Linear Integer Arithmetic** | `[V0001]` | Exact **Fourier-Motzkin variable elimination**, **integer cutting planes**, disjunctive `or` splitting, C99 truncated remainder bounds (`-k + 1 <= r <= k - 1`), `10^9` coefficient overflow guard, and **Farkas dual certificates** |
| **`QF_NIA` Nonlinear Polynomials** | `[V0001]` | **Horner/Bernstein polynomial interval envelopes**, **native quadratic square-completion** (`(a*x + b)^2 >= 0`), Positivstellensatz witnesses, sign-rule propagation, and 64-bit multiplication overflow guards (`<= 3,037,000,499`) |
| **`QF_BV` Bitvectors &amp; Shifts** | `[V0001]` | Exact bitmask bounds (`0 <= bit_and(x, m) <= m`), `bit_or`/`bit_xor` algebraic identities, and bounded left/right **bit-shift semantics** |
| **Relational Octagons (`±x ± y <= c`)** | `[V0001]` | Difference-bound &amp; octagon closure tracking coupled index/length invariants across branches and loops |
| **Termination, DAG &amp; WCET Budgets** | `[V0002]`, `[K0006]` | Lexicographic ranking measures for `total fn`, call-DAG acyclicity (`[K0006]`), and static instruction-cycle summation (`@bound(N)`) |
| **Separation Logic &amp; Perceus Reuse** | `[O0001]`–`[O0030]` | Disjoint heap frame rules (`p != q`), affine ownership dataflow, and alias-safe in-place cell reuse (`pat_scrutinee_safe`) |
| **Constant-Time Secret Isolation** | `[C0009]`, `[C0011]` | Secret taint lattices forbidding secret branches, divisions, memory indices, and non-kernel calls; paired with `ltv` `[C0010]` |

---

## 3. Writing Provable Specifications (`requires`, `ensures`, `invariant`, `law`)

### Linear &amp; Nonlinear Contracts

```lume
## Quadratic non-negativity discharged by native square-completion / QF_NIA:
law shifted_parabola_floor(x: int) =
  (x * x) - (6 * x) + 14 >= 5

## Conservation-proven ledger withdrawal with static WCET bound:
@no_alloc
@bound(40)
pub fn withdraw(balance: int, amount: int, fee: int) -> int / pure
  requires balance >= 0 and amount > 0 and fee >= 0 and amount + fee <= balance
  ensures result == balance - amount - fee and result >= 0 and result < balance
= balance - amount - fee
```

When a contract is falsifiable, compilation aborts fail-closed (`exit 3`) with `[V0001]` before a single byte of object code is emitted.

---

## 4. Sub-10 ms Incremental SHA-256 Proof Cache (`lproof_cache.src`)

To keep interactive IDE and incremental builds instantaneous on large verified modules, [`compiler/stage1/lproof_cache.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lproof_cache.src) caches discharged obligation digests keyed by normalized function AST, contract AST, transitive callee `ensures` signatures, and prover version:

- **Warm Cache Latency:** **`~6.9 ms` in-process / `~7.4 ms` CLI** (`< 10 ms`, verified in `G-DWARF-CACHE` across `20/20` warm hits and `19/20` single-function edits).
- **Sound Invalidation &amp; Tamper Refusal:** Automatically invalidates cached proofs whenever a function body, its `requires`/`ensures`, or any transitive callee's `ensures` changes; rejects corrupted cache entries with **`[PC0002]`** and refuses forged false-theorem cache injections with **`[PC0003]`**.

---

## 5. Standalone Zero-Compiler-Import Proof Kernel (`lcert.src --check-source`)

Lume enforces strict separation between **proof search (`lcaas.src`)** and **proof checking (`lcert.src`)**:

1. **`Zero-Compiler-Import` TCB:** `compiler/stage1/lcert.src` imports **zero** modules from `lumec` or `lcaas`. It independently re-derives every Farkas linear combination, quadratic/Horner step, and frame condition from the emitted `.cert.json` artifact.
2. **Source-to-Certificate AST Binding (`--check-source`):** Running `lume verify-cert --check-source <file.src> <file.cert.json>` re-parses the original `.src` file, verifies its SHA-256 digest, enforces kernel safety laws (`[K0005]` symbolic `W^X` DMA page protection and `[K0006]` mutual recursion prohibition), and ensures no obligation was omitted, weakened, or forged:
   - **`[K0010]`:** Edited or mismatched source file refused.
   - **`[K0011]`:** Deleted/missing proof obligation refused.
   - **`[K0012]`:** Certificate referencing a non-existent function refused.
   - **`[K0013]`:** Weakened postcondition goal, strengthened precondition hypothesis, captured caller parameter, loosened `@bound`, or weakened `law` refused.

```sh
lume prove app.src
lume certify app.src > app.cert.json
lume verify-cert --check-source app.src app.cert.json
```

---

## 6. Continuous Adversarial Soundness Fuzzing (`lume prover-fuzz`)

Every CI run executes [`tests/harness/prover_fuzz_gate.src`](https://github.com/OmegaSoftDLL/lume/blob/main/tests/harness/prover_fuzz_gate.src) (`lume prover-fuzz`) and `claude_audit_gate.src`:
- Generates and mutates hundreds of subtle false theorems across **6 verification domains** (64-bit boundaries, division/modulo signs, records + variable shadowing, canonical arrays, separation/heap aliasing, nested quantifiers, wrapping `+%`/`-%`/`*%` operators, `2^40` coefficients, and lexicographic termination measures).
- Verifies that **`0` false theorems are ever accepted** by `lumec`, `lcaas`, or `lcert`, while `266` valid control theorems are independently re-derived by `lcert`.

For post-codegen machine-code translation validation (`ltv`), clean-room `.smt2` solving (`lsmt` + `z3`), `0/9,618` Masking MC/DC, `118` constant-time crypto kernels, and `2oo2D` lockstep qualification, continue to **[Binary Assurance, Crypto &amp; Qualification](Binary-Assurance-Crypto-and-Qualification)**.
