<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Lume Mascot" width="76" height="76" align="left" />
  Formal Verification &amp; Embedded OmniProof v3 Prover
</h1>
<br clear="left"/>

Unlike languages thatbolt on external SMT solvers (Z3/CVC5) requiring gigabytes of C++ dependencies and unpredictable solver timeouts, **Lume embeds its entire formal verification engine (`OmniProof v3`, `compiler/stage1/lume/03_prover.src`) directly inside the self-hosted compiler**.

---

## 1. Six Verification Theories in One Self-Hosted Pass

| Theory / Guard | Diagnostic Code | Decision Procedure |
| :--- | :--- | :--- |
| **`QF_LIA` Refinement Contracts** | `[V0001]` | Exact Fourier-Motzkin variable elimination + integer cutting planes + `or` branch splitting |
| **`QF_NIA` Nonlinear Arithmetic** | `[V0001]` | Positivstellensatz sum-of-squares (`x*x >= 0`), product sign rules, and 64-bit overflow guard (`<= 3037000499`) |
| **`QF_BV` Bitvector Identities** | `[V0001]` | Bitwise mask bounds (`0 <= bit_and(x, m) <= m`), XOR self-inverse (`bit_xor(x, x) == 0`), shift semantics |
| **Separation Logic & Perceus** | `[E0100]`–`[E0106]` | Disjoint heap frame rules (`p != q`), alias-safe in-place reuse (`pat_scrutinee_safe`) |
| **WCET Cycle Bounds (`@bound`)** | `[V0002]` | Static abstract-interpretation instruction-cycle summation across call graphs |
| **Constant-Time Crypto (`@secret`)** | `[C0009]` | Taint propagation rejecting secret-dependent branches, variable-latency `/`/`%`, and memory indices |
| **Kernel DMA & Stack Safety** | `[K0005]`, `[K0006]` | Symbolic `W^X` page-table permission verification (`bit_and(flags, 6) != 6`) and mutual recursion rejection |

---

## 2. Writing `requires`, `ensures`, `invariant`, and `law`

### Algebraic Laws (`law`)

A `law` is a universally quantified theorem verified at compile time for all possible inputs:

```lume
law ledger_conservation(balance: int, fee: int, amount: int) =
    if balance >= amount + fee and amount >= 0 and fee >= 0 then
        (balance - amount - fee) + amount + fee == balance
    else
        1 == 1
```

### Preconditions & Postconditions (`requires` / `ensures`)

When a function declares `requires`, every call site must statically satisfy the precondition; when it declares `ensures`, the function body must statically imply the postcondition for `result`:

```lume
@bound(cycles: 40)
pub fn withdraw(balance: int, amount: int, fee: int) -> int / pure
    requires balance >= 0 and amount > 0 and fee >= 0 and amount + fee <= balance
    ensures result == balance - amount - fee and result >= 0 and result < balance
=
    balance - amount - fee
```

If a contract can be falsified, `lumec` halts compilation immediately with a concrete counterexample witness (`[V0001]`).

---

## 3. Constant-Time Cryptographic Verification (`@secret` / `[C0009]`)

Parameters marked `@secret` are tracked through `let` bindings and expressions. Any timing side channel is rejected at compile time:

```lume
## REJECTED with [C0009]: branch condition depends on @secret key
fn bad_mac_check(@secret key: int, guess: int) -> int / pure =
    if key == guess then 1 else 0

## REJECTED with [C0009]: hardware division latency leaks @secret scalar
fn bad_scalar_div(@secret scalar: int, pub_mod: int) -> int / pure =
    scalar / pub_mod
```

---

## 4. Sound Negative Modulo & Overflow-Hardened Prover (Claude Opus 5.5 Audit)

Lume's `QF_LIA` solver is hardened against all 21 classes of SMT soundness bugs identified during the Claude Opus 5.5 + Sovereign Red-Team Audit:
- **C99 Truncated Remainder Soundness:** For `r = x % k` (`k > 0`) where `x` may be negative, the solver asserts `-k + 1 <= r <= k - 1` (and only asserts `r >= 0` when `x >= 0` is already entailed by the context).
- **64-Bit Coefficient Overflow Guard:** Linear combination elimination steps clamp to fail-closed unknown whenever `|coeff| > 1,000,000,000` (`10^9`), preventing 64-bit integer wrap-around inside Fourier-Motzkin elimination.
- **Fail-Closed Contract Parser:** Any malformed token in a `requires`/`ensures`/`invariant`/`law` clause immediately emits `[V0001]` instead of silently dropping constraints.

---

## 5. Proof-Carrying Certificates (`.lcert`)

Run `lume certify <file.lume>` to emit a standalone `.lcert` JSON/cryptographic proof certificate signed with **SHA-256 + Ed25519 + Hybrid Post-Quantum ML-DSA-65 (`FIPS 204`)**, verifiable offline in <1 ms via `lcert verify`.
