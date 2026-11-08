<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Lume Mascot" width="76" height="76" align="left" />
  Language Tour &amp; Sovereign Ergonomics
</h1>
<br clear="left"/>

Lume blends the algebraic clarity of **ML/OCaml**, the zero-cost ownership discipline of **Rust**, and the explicit compilation transparency of **Zig** — while embedding first-class refinement contracts (`requires`, `ensures`, `law`) directly into the type system.

---

## 1. Functions, Contracts & Effects (`fn`)

Every Lume function can declare:
- An **effect row** (`/ pure`, `/ {io}`, `/ {net, fs}`, `/ {ffi}`) checked by capability isolation (`[E0200]`).
- **Preconditions (`requires`)** and **postconditions (`ensures`)** discharged at compile time by the embedded `QF_LIA` prover (`[V0001]`).
- **Hardware cycle budgets (`@bound(cycles: N)`)** verified statically (`[V0002]`).

```lume
@bound(cycles: 24)
pub fn clamp(val: int, lo: int, hi: int) -> int / pure
    requires lo <= hi
    ensures result >= lo and result <= hi
=
    if val < lo then lo
    else if val > hi then hi
    else val
```

---

## 2. Algebraic Data Types (`type`) & Pattern Matching (`match`)

Lume supports sum types (tagged unions), product types (records), and exhaustive pattern matching with Perceus drop-guided in-place reuse:

```lume
type List =
    | Nil
    | Cons(int, List)

fn sum_list(xs: List, acc: int) -> int / pure = match xs
    Nil         => acc
    Cons(h, tl) => sum_list(tl, acc + h)
```

---

## 3. Immutable Records & Functional Record Update (`{ r with ... }`)

Records are immutable by default and stack-allocated via Scalar Replacement of Aggregates (`SRA`) whenever they do not escape:

```lume
fn advance_cursor(pt, dx: int, dy: int) =
    { pt with x: pt.x + dx, y: pt.y + dy }

let p0 = { x: 10, y: 20, label: "origin" } in
let p1 = advance_cursor(p0, 5, 15) in
print f"({p1.x}, {p1.y})"
```

---

## 4. Pipe Operator (`|>`) & Composition

Chain data transformations left-to-right without deeply nested parentheses:

```lume
fn double(x: int) -> int = x * 2
fn inc(x: int) -> int = x + 1
fn square(x: int) -> int = x * x

let ans = 5 |> double |> inc |> square in
print ans   ## Prints 121
```

---

## 5. Hardened String Interpolation (`"..."` & `f"..."`)

Lume supports inline `{expr}` interpolation and format specifiers (`{val:04x}`, `{val:08b}`, `{val:>6}`) while **automatically ignoring** embedded CSS rules, JavaScript functions, JSON literals, and Lume effect annotations (`/ {ffi}`) inside plain strings:

```lume
let v = 42 in
let msg = "ans={v}" in               ## "ans=42"
let hex = f"hex=0x{v:04x}" in        ## "hex=0x002a"

## Embedded CSS, JS, JSON, and effect strings are never falsely interpolated:
let css = ".panel{display:none;color:#10b981;font-weight:600}" in
let js  = "function(a){if(a)return a}" in
let eff = "extern \"c\" fn foo(x: int) -> int / {ffi}" in
print hex
```

---

## 6. Linear Ownership (`own`, `mut`) & Perceus Reuse

- `own T`: Linear uniquely-owned resource that must be consumed exactly once (`[E0100]` on double use, `[E0101]` on unconsumed drop without handler).
- Perceus Reuse Analysis automatically reuses `Cons` and record allocations in place when the scrutinee of a `match` has reference count `1` — achieving **zero GC pause** and **C-level allocation speed**.

---

## 7. Wrapping Arithmetic (`+%`, `-%`, `*%`) vs Checked Arithmetic (`+`, `-`, `*`)

- Standard `+`, `-`, `*` model mathematical integers in `QF_LIA` proofs.
- Wrapping operators `+%`, `-%`, `*%` model modular 64-bit two's-complement wrap-around and are treated as uninterpreted opaque terms by the `QF_LIA` prover so modular wrap-around can never be unsoundly conflated with linear integer arithmetic.
