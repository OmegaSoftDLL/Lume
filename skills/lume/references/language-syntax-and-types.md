# Lume Language Syntax, Type System, Ownership & Effects

## Table of Contents
1. [Primitive & Built-in Types](#1-primitive--built-in-types)
2. [Functions, Let-Bindings & Control Flow](#2-functions-let-bindings--control-flow)
3. [Algebraic Data Types (ADTs) & Pattern Matching](#3-algebraic-data-types-adts--pattern-matching)
4. [Deterministic Memory: Ownership, Borrowing & Perceus Reuse](#4-deterministic-memory-ownership-borrowing--perceus-reuse)
5. [Algebraic Effects & Structured Concurrency](#5-algebraic-effects--structured-concurrency)
6. [Built-in Runtime & OS Primitives](#6-built-in-runtime--os-primitives)

---

## 1. Primitive & Built-in Types

| Type | Description | Literal Examples |
|---|---|---|
| `Int` | 64-bit signed integer (`i64` in native codegen). Overflow of `+`, `-`, `*` stops the program; `+%`, `-%`, `*%` wrap | `0`, `42`, `-100`, `0xFF` |
| `Bool` | Boolean (`true` / `false`, or `1` / `0` in `.src`) | `true`, `false` |
| `String` | Immutable UTF-8 string | `"hello"`, `"line1\nline2"` |
| `Unit` | Empty tuple / void return | `()` |
| `decimal(p, s)` | Exact fixed-point decimal with precision `p` and scale `s` | `19.99d`, `decimal_new(1999, 2)` |
| `money[CCY]` | Currency-tagged exact decimal (prevents mixing currencies at compile time) | `money[BRL](150.00d)`, `money[USD](30.00d)` |
| `table[T]` | Typed relational in-memory or WAL-persisted table | `persist table[LedgerRow]` |
| `tensor[DType, ...]` | Statically shape-checked multidimensional tensor | `tensor[f32, 128, 64]` |
| `cap[Kind]` | Linear hardware capability token (`Page`, `Port`, `Irq`) | `cap[Port]` |

---

## 2. Functions, Let-Bindings & Control Flow

### Surface Syntax (`.lume`)
```rust
fn fib(n: Int) -> Int {
  if n <= 1 {
    n
  } else {
    fib(n - 1) + fib(n - 2)
  }
}

fn compute(x: Int) -> Int {
  let a = x * 2
  let b = a + 10
  b
}
```

### Core Syntax (`.src`)
```rust
fn fib(n: Int) -> Int =
  if n <= 1 then n
  else fib(n - 1) + fib(n - 2)

fn compute(x: Int) -> Int =
  let a = x * 2 in
  let b = a + 10 in
  b
```

---

## 3. Algebraic Data Types (ADTs) & Pattern Matching

Lume supports sum types (tagged unions) and product types (structs/records) with exhaustive pattern matching:

```rust
type Result[T, E] =
  | Ok(T)
  | Err(E)

type Expr =
  | Lit(Int)
  | Add(Expr, Expr)
  | Neg(Expr)

fn eval(e: Expr) -> Int =
  match e {
    Lit(n) => n,
    Add(l, r) => eval(l) + eval(r),
    Neg(inner) => 0 - eval(inner)
  }
```

> **Important Invariant for `.src` Files:**
> When writing in `.src` dialect, `match` must always be the outermost expression of a function body (`fn f(...) = match ...`). If you need to compute a value before matching, pass it to a helper function whose body starts with `match`.

---

## 4. Deterministic Memory: Ownership, Borrowing, 4-Tier Atomic Compactor & Perceus Reuse

Ownership is checked at compile time; reclaiming memory is the runtime's job. The single-source hosted runtime (`compiler/stage1/runtime_core.lume`) has a segregated 43-size-class non-moving mark-and-lazy-sweep collector (`madvise(MADV_DONTNEED)`), so a program with no annotations still runs in bounded memory (`docs/38-memory-management.md`, `docs/39-memory-saga-and-atomic-compactor-dossier.md`).

1. **4-Tier Atomic Memory Compactor:**
   - **Stage 0 (`.rodata`):** String literals, constructor descriptors, record shapes, and zero-arity constructors (`Nil`, `None` = `0 B` heap) reside in `.rodata`.
   - **Level 1 (64-Bit Tagged Register Word):** 63-bit signed integers (`...iiii1`) and `0..7`-byte inline SSO strings (`...ss|lll|010`, `0 B` heap, beating Rust's 24-byte + heap `String`) live directly in a 64-bit CPU register word; the 64th integer bit uses a 16-byte overflow cell `[3][value]`.
   - **Level 2 (Compact Cells):** `Cons(h, t)` is `24 B` (down from `80 B`); a 3-field record is `32 B` (down from `160 B`).
   - **Level 3 (Cold Arena Demand-Paged `LZ1` Compactor):** `mem_pack`/`mem_unpack`, `arena_freeze`/`arena_thaw`/`arena_compact`, and `lume pack`/`lume unpack` compress cold arenas and `.lcaps`/`.lumb` bundles (`~355 MB/s` pack, `~975 MB/s` unpack) with lazy per-page `PROT_NONE` + `SIGSEGV` thaw on first touch (`@secret` `[C0009]` and `@bound` `[V0002]` fail closed).
2. **Affine Ownership & Move Semantics (`[O0001]`–`[O0030]`, `own_flow.src`):**
   - Moving a value (`own x`) invalidates every binding that can observe it: aliases, containers, parts and closures (`[O0001]`). Moving out of a borrow is rejected through any alias or pattern (`[O0002]`).
   - A `resource type` value held by a `let` must leave on every path (`[O0004]`).
3. **Borrowing (`borrow`, `borrow_mut`, `mut` parameters):**
   - A live borrow conflicts with a move, a mutable borrow, or, for a mutable borrow, any use of its target, up to the borrow's last use (`[O0013]`). Conflicts in one call are `[O0011]`.
   - A borrow cannot escape through a return value, record or constructor (`[O0020]`, `[O0021]`).
4. **Perceus Constructor Reuse (`__perceus_reuse`):**
   - Matching an `own` constructor parameter and rebuilding the same shape reuses the cell in place, but only when every call site in the program passes a provably unique value. Otherwise the compiler allocates, which is always correct. Reuse is an optimization, never a semantic promise.

```rust
fn increment_in_place(own buf: Buffer) -> Buffer {
  // Ownership transferred in and returned out deterministically
  buf
}
```

---

## 5. Algebraic Effects & Structured Concurrency

Side effects are tracked in function signatures using algebraic effect rows (`effect`) and handled lexically (`handle ... with`):

```rust
effect Log {
  fn info(msg: String) -> Unit
}

fn process_order(order_id: Int) -> Int ! {Log} {
  perform Log.info("processing order")
  order_id + 1
}
```

For concurrency, Lume provides **supervised actors and structured task scopes (`S0001`)** where child tasks cannot outlive their parent scope and message passing is free of data races by construction.

---

## 6. Built-in Runtime & OS Primitives

The native standard prelude (`compiler/stage1/lume/05_codegen.src`) provides these zero-overhead built-in functions:

| Built-in Function | Signature | Description |
|---|---|---|
| `len(s)` | `(String) -> Int` | Byte length of string `s` |
| `at(s, idx)` | `(String, Int) -> String` | Single-byte substring at index `idx` |
| `slice(s, start, end)` | `(String, Int, Int) -> String` | Substring `[start..end)` |
| `ord(c)` | `(String) -> Int` | Unsigned byte value (`0..255`) of first byte of `c` |
| `chr(code)` | `(Int) -> String` | Single-character string from ASCII/byte code `code` |
| `str_eq(a, b)` / `a == b` | `(String, String) -> Bool` | Exact string equality |
| `int_to_str(n)` / `str(n)` | `(Int) -> String` | Convert integer to decimal string |
| `str_to_int(s)` | `(String) -> Int` | Parse decimal string to integer |
| `fs_read(path)` / `read_file(path)` | `(String) -> String` | Read entire file contents as string |
| `fs_write(path, content)` | `(String, String) -> Int` | Write string to file (`0` on success) |
| `fs_path_exists(path)` | `(String) -> Int` | Returns `1` if file/directory exists, `0` otherwise |
| `fs_read_byte(path, offset)` | `(String, Int) -> Int` | Read unsigned byte (`0..255`) at binary file offset, or `-1` on EOF |
| `os_run(cmd)` | `(String) -> Int` | Execute shell command via `fork`+`execve`+`wait4` and return exit status |
| `argc()` / `argv(i)` | `() -> Int` / `(Int) -> String` | Command-line argument count and `i`-th argument |
