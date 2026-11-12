<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="76" height="76" align="left" />
  Language Tour &amp; Ergonomics
</h1>
<br clear="left"/>

Lume combines the algebraic clarity of **ML/OCaml**, the affine ownership discipline of **Rust**, and the systems transparency of **Zig**, while making refinement contracts, capability isolation, worst-case execution bounds, and constant-time cryptographic secrecy first-class citizens of the type system.

---

## 1. Refinement Contracts &amp; Universal Algebraic Laws (`requires`, `ensures`, `invariant`, `law`)

Every Lume function and data type can state mathematical specifications checked at compile time by `OmniProof-v4` (`[V0001]` fail-closed contract parser — malformed contract tokens never degrade silently):

```lume
const BONUS: int = 10

type Account = { balance: int, tx_count: int } invariant balance >= 0

fn scale_and_bonus(x: int, factor: int) -> int / pure
  requires x >= 0 and factor >= 1
  ensures result >= x + BONUS
= (x * factor) + BONUS

law scale_monotone(x: int) =
  if x >= 0 then scale_and_bonus(x, 2) >= x + BONUS else 1 == 1
```

- **`requires P`:** Statically verified at every call site before entering the function.
- **`ensures Q`:** Statically verified across every return path for `result`.
- **`invariant I`:** Enforced across every record construction and functional update `{ acc with ... }`.
- **`law L(...) = ...`:** Universally quantified theorem verified across the mathematical domain at compile time.

---

## 2. Affine Ownership, Borrows &amp; Perceus Reuse (`own`, `&T`, `&mut T`)

Implemented in [`compiler/stage1/own_flow.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/own_flow.src) (`[O0001]`..`[O0030]`):

- **`own T`:** Uniquely owned affine value moved at most once (`use-after-move` and double-drop are rejected statically).
- **`&T` / `&mut T`:** Shared immutable and exclusive mutable borrows with alias/exclusivity checking, complemented by `rc[T]`, `arc[T]`, `weak[T]`, and region `arena` allocators.
- **Perceus Constructor Reuse (`pat_scrutinee_safe`):** When matching an unaliased ADT cell (`Cons(h, tl)`) or updating an owned record, `lumec` reuses the existing heap cell in place (`0` heap allocations, `0` GC pauses). Non-escaping records are lowered directly to registers via **Scalar Replacement of Aggregates (`SRA`)**.

```lume
pub fn debit_account(own acc: Account, amount: int, fee: int) -> Account / pure
  requires amount >= 0 and fee >= 0 and acc.balance >= amount + fee
  ensures result.balance == acc.balance - amount - fee and result.balance >= 0
= { acc with balance: acc.balance - amount - fee, tx_count: acc.tx_count + 1 }
```

---

## 3. Algebraic Effects &amp; Capability Isolation (`/ pure` vs. `/ {io, net, fs, ffi}`)

Functions declare explicit effect rows enforced by `[E0200]`:
- Functions annotated `/ pure` cannot perform I/O, filesystem mutations, network sockets, or foreign calls, nor bypass isolation through ambient effect handlers.
- Foreign calls must execute inside `/ {ffi}` and promote untrusted returns through `[I0003]` contracts.

---

## 4. Hard Real-Time (`@no_alloc` `[E0210]`) &amp; WCET Budgets (`@bound` `[V0002]`)

For safety-critical control loops, interrupt handlers (`@interrupt`), and bare-metal `@freestanding` kernels:

- **`@no_alloc` (`[E0210]`):** Rejects heap constructors, allocating builtins, non-`@no_alloc` callees, non-tail recursion, mutual recursion cycles, untyped signatures, and arithmetic whose result could leave the 63-bit unboxed immediate register range (`16 B` spill guard).
- **`@bound(N)` (`[V0002]`):** Enforces a static worst-case execution cycle budget across the call graph, paired with `lume stack` worst-case stack byte verification on emitted assembly.
- **`--critical` / `--keep-proven-checks`:** Retains runtime boundary traps even for statically proven contracts so hardware single-event upsets (`SEUs`) cannot bypass postconditions silently.

```lume
@no_alloc
@bound(32)
fn clamp_dose(dose: int, lo: int, hi: int) -> int
  requires dose >= 0 and dose <= 10000 and lo >= 0 and lo <= hi and hi <= 5000
  ensures result >= lo and result <= hi
= if dose < lo then lo else if dose > hi then hi else dose
```

---

## 5. Constant-Time Secret Types (`@secret` `[C0009]` &amp; `@secret @no_alloc` `[C0011]`)

Lume enforces two complementary levels of cryptographic side-channel resistance:

1. **Source Taint Isolation (`@secret` `[C0009]`):** Tracks secret parameters through bindings and expressions, rejecting secret-dependent `if`/`match` branches, variable-latency `/` and `%` instructions, secret array/memory indices, and `LZ1` arena compression on secret values.
2. **Branch-Free Constant-Time Kernels (`@secret @no_alloc` `[C0011]` + Machine `[C0010]`):** Enforces strict constant-time kernel discipline using `ct_select` and `ct_eq`, lowered to branchless `cmov` instructions and verified on emitted x86-64 assembly by `lume tv` (`[C0010]`) across all transitive `call` targets (`0` conditional jumps, `0` secret memory addresses, `0` divisions across all **`118` kernels** in `lcrypto_tls.src`).

```lume
@secret
@no_alloc
fn ct_mux_u32(mask: int, a: int, b: int) -> int =
  let ma = bit_and(a, 4294967295) in
  let mb = bit_and(b, 4294967295) in
  ct_select(ct_eq(bit_and(mask, 1), 1), ma, mb)
```

---

## 6. Linear Concurrency (`[E0305]`) &amp; Deadlock-Free Lock Ranks (`[E0306]`)

- **Linear Channel Ownership (`chan_send_linear`, `[E0305]`):** Sending an owned payload over a channel consumes the sender's linear capability, statically preventing post-send data races.
- **Strict Lock-Rank Ordering (`[E0306]`):** Mutex acquisitions carry static rank annotations; acquiring locks out of order or forming a wait-for cycle fails compilation.

---

## 7. Checked Arithmetic (`+`, `-`, `*`) vs. Wrapping Modular Arithmetic (`+%`, `-%`, `*%`)

- **Checked Operators (`+`, `-`, `*`, `/`, `%`):** Model exact mathematical integers in `QF_LIA`/`QF_NIA` proofs and emit hardware signed-overflow traps (`jo __rt_ovf`, `exit 3`) at runtime.
- **Wrapping Operators (`+%`, `-%`, `*%`):** Model explicit 64-bit two's-complement modular wrap-around (`mod 2^64`) for hashes and ciphers, kept strictly separate from mathematical linear arithmetic in the prover so wrap-around can never falsify a proof.

---

## 8. Exact Financial Decimals (`decimal`), Relational Tables &amp; Hardened Interpolation

- **Exact Base-10 Decimals &amp; ACID Tables (`decimal.src`, `table.src`, `query.src`, `db.src`):** Scaled integer `decimal` and `money` types eliminate IEEE-754 binary floating-point rounding drift, backed by typed `table[T]` queries and B+Tree Write-Ahead Logging (`WAL`).
- **Hardened String Interpolation &amp; Pipes (`f"..."`, `|>`):** Supports format specifiers (`f"0x{v:04x}"`) while rejecting code-injection blocks inside interpolation holes and scanning plain literal chunks in $O(1)$ without per-character allocations:

```lume
fn classify_list(xs) =
  let head_val = match xs
    Nil        => 0
    Cons(h, _) => h
  in head_val |> scale_and_bonus(2)

print f"Verified result: {classify_list(Cons(20, Nil))}"
```

---

## 9. Formal Intent Synthesis (`.intent` &amp; `V0005` Cache Guard)

With `@intent` specifications (`examples/intent/`), developers or AI systems can write a typed signature with `requires` and `ensures` contracts and leave a synthesis hole `= _`. Lume synthesizes a candidate body, discharges its `QF_LIA` postconditions before emitting code, and protects cached `.intent` artifacts with SHA-256 tamper detection (`[V0005]`).
