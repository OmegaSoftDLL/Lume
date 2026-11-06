# Formal Verification (`QF_LIA`), Laws, Hole Synthesis & Proof Certificates

## Table of Contents
1. [Preconditions & Postconditions (`requires` / `ensures`)](#1-preconditions--postconditions-requires--ensures)
2. [Algebraic Laws (`law`) & Universal Properties](#2-algebraic-laws-law--universal-properties)
3. [Compiler-as-Oracle Hole Synthesis (`??`)](#3-compiler-as-oracle-hole-synthesis-)
4. [Worst-Case Execution Time (`@bound(cycles: N)`)](#4-worst-case-execution-time-boundcycles-n)
5. [Standalone Proof Certificates (`lcert`) & Portable Evidence (`levidence`)](#5-standalone-proof-certificates-lcert--portable-evidence-levidence)

---

## 1. Preconditions & Postconditions (`requires` / `ensures`)

Lume embeds a sound **Quantifier-Free Linear Integer Arithmetic (`QF_LIA`)** solver directly inside the compiler (`06b_phase3.src` and `lcert.src`). Contracts are checked **statically at compile time** — if a postcondition could ever be violated, compilation fails with `[V0001]` and a concrete counterexample.

```rust
fn safe_withdraw(balance: Int, amount: Int) -> Int
  requires balance >= 0 && amount >= 0 && amount <= balance
  ensures result >= 0 && result <= balance && result + amount == balance
{
  balance - amount
}
```

### Key Rules for `QF_LIA` Contracts
- Use `result` in `ensures` clauses to refer to the function's return value.
- Logical implication is written `p ==> q` (or `if p then q else true`).
- Conjunction is `&&`, disjunction is `||`, negation is `!`.
- Call sites are checked automatically: calling `safe_withdraw(bal, amt)` requires the caller's path conditions to entail `bal >= 0 && amt >= 0 && amt <= bal`.

---

## 2. Algebraic Laws (`law`) & Universal Properties

In addition to per-function contracts, Lume lets you state module-level algebraic theorems using `law`. The compiler unrolls non-recursive calls and proves the law across all possible integer inputs:

```lume
fn clamp(x: int, lo: int, hi: int) -> int
  requires lo <= hi
  ensures result >= lo and result <= hi
= if x < lo then lo else if x > hi then hi else x

law clamp_lower_bound(x: int, lo: int, hi: int) =
  if lo <= hi then clamp(x, lo, hi) >= lo else 1 == 1

law clamp_upper_bound(x: int, lo: int, hi: int) =
  if lo <= hi then clamp(x, lo, hi) <= hi else 1 == 1
```
> **Prover Tip for `lume certify` (`lcert` Kernel):** In `law` declarations with preconditions, write `if <precondition> then <conclusion> else 1 == 1` so the standalone proof kernel (`lume-minimal-kernel-v1`) discharges the vacuous `else` branch as the arithmetic tautology `(== 1 1)` and grants `"badge": "Lume Verified ✓"`.

---

## 3. Compiler-as-Oracle Hole Synthesis (`??`)

When an AI agent or developer writes a function signature with `requires` and `ensures` contracts and leaves an expression hole `??`, Lume's **CEGIS (Counterexample-Guided Inductive Synthesis)** engine synthesizes the provably correct expression that satisfies the specification:

```rust
fn synthesize_margin(revenue: Int, cost: Int) -> Int
  requires revenue >= cost && cost >= 0
  ensures result >= 0 && result + cost == revenue
{
  ?? // Compiler synthesizes: revenue - cost
}
```

---

## 4. Worst-Case Execution Time (`@bound(cycles: N)`)

For real-time kernels, interrupt handlers, and high-frequency systems code, annotate functions with `@bound(cycles: N)`. The compiler statically sums worst-case instruction cycle costs across all control-flow paths and rejects any unbounded loop or path exceeding `N` cycles with `[V0002]`:

```rust
@freestanding
@bound(cycles: 64)
fn ring0_align_page_4k(addr: Int) -> Int =
  let rem = addr % 4096 in
  if rem == 0 then addr else addr - rem
```

---

## 5. Standalone Proof Certificates (`lcert`) & Portable Evidence (`levidence`)

Every proven obligation emits a machine-checkable proof certificate verified by the standalone micro-kernel (`compiler/stage1/lcert.src`, mechanized in `formal/lean/LumeCore.lean`).

```bash
# Bundle portable cryptographic evidence for a module
lume evidence bundle app.lume -o app.evidence.json

# Verify an evidence bundle (checks FIPS 180-4 SHA-256 digests + QF_LIA proof steps)
lume evidence verify app.evidence.json

# Renew evidence after a dependency update
lume evidence renew app.evidence.json
```
