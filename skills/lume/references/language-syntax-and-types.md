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
| `Int` | 64-bit signed integer (`i64` in native codegen) | `0`, `42`, `-100`, `0xFF` |
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

## 4. Deterministic Memory: Ownership, Borrowing & Perceus Reuse

Lume has **no stop-the-world garbage collector**. Memory is managed deterministically at compile time through three complementary mechanisms:

1. **Affine Ownership & Move Semantics (`[O0001]`–`[O0030]`):**
   - Values have a single owner. Moving a linear/owned resource invalidates the previous binding (`[O0001] use after move`).
2. **Lexical Borrowing (`&T` shared, `&mut T` exclusive):**
   - You may hold either multiple immutable borrows (`&T`) OR one mutable borrow (`&mut T`), never both simultaneously (`[O0002] conflicting borrow`).
3. **Perceus Reference-Counted Constructor Reuse (`__perceus_reuse`):**
   - When pattern matching on a uniquely owned ADT node (`Cons(h, t)`) and constructing a node of the same layout (`Cons(h + 1, ...)`), Lume reuses the heap allocation in-place with zero `malloc`/`free` overhead.

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
