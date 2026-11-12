# 03 — The Lume Language Specification, v0.1 (draft)

Status: **draft**, edition `2026`. This document is normative for Stage 0/1 implementations.
Sections marked **[Stage N]** describe features whose syntax is reserved now and implemented in that
roadmap stage; Stage 0 implements §1–§9 (the "core subset"). Grammar: `grammar/lume.ebnf`.

> **Implementation note.** The **[Stage N]** tags mark the stage at which the spec *intends* a feature to land; they do not all mean it is implemented in the self-hosted `lumec` today. As of `#239`, traits/`impl`, closures, refinement `T where ...`, `async`/`.await`, `shard`, and `let`-polymorphism **are** implemented and tested; AArch64/RISC-V ELF targets run under QEMU and Mach-O/PE/Intel-HEX are *emitted* (`#238`, see `docs/26`). Still **not** real as language types: `rc[T]`/`arc[T]`/`weak[T]` ownership tiers and `promise[T]`/`signal[T]` (today only hand-written library mocks - reopened `#197`/`#215`). See `docs/10-stage1-status.md` and `docs/PROJECT_STATE.md` for what is real.

Notation: `code` for syntax; *italics* for metavariables; "MUST/SHOULD" as in RFC 2119.

---

## 1. Source text and lexical structure

### 1.1 Encoding and files
- Source files are UTF-8, extension `.lume`. A file is a **module**. A directory with `mod.lume`
  is a module containing its files as submodules.
- Line endings are LF (CRLF is normalised by the lexer). Tabs are an error (code `L0001`).

### 1.2 Comments
- `# text` to end of line. `## text` is a **doc comment** attached to the next item.
- `#[ … ]#` block comments, nestable; they may span lines. An unterminated one is a lexical error (`L0004`).
  (Implemented by both front ends since Wave 14: `lumec` used to read `#[` as a line comment; see §19.3.)

### 1.3 Identifiers and keywords
- Identifiers: `[A-Za-z_][A-Za-z0-9_]*`, plus Unicode letters (XID_Start/XID_Continue).
  Convention enforced by `lume fmt --check`: `snake_case` for values/functions/modules,
  `PascalCase` for types/traits/enum variants, `SCREAMING_CASE` for constants.
- Reserved keywords (edition 2026, 58):
  `and as async await break catch comptime continue defer distinct do dyn elif else ensures enum
  errdefer extern fail false fn for if impl import in invariant is let loop macro match mod mut none
  not or own pub record requires return scope select self Self spawn trait true type unsafe use var
  where while with yield` and the reserved-for-later words
  `kernel model query rule llm par persist table` (contextual: usable as identifiers only when not
  in statement-initial position; the formatter renames them).
- Raw identifiers: `` `name` `` to use a keyword as an identifier (e.g. for FFI).

### 1.4 Literals
- **Integers**: `42`, `1_000_000`, `0xFF`, `0b1010`, `0o755`. Untyped: adopt the context type;
  default `int` (`i64`). A literal that does not fit its type is an error (`L0010`).
  The radix prefixes are lowercase (`0X1F`, `0B11`, `0O17` are not literals). A `_` separates two digits: it is
  never first, last or doubled (`1_`, `1__0`, `0x_F`, `0xF_`). A literal ends at a character that is neither one of
  its digits nor part of a name: `2a`, `12abc`, `0x1G` are errors, not a number followed by a name (`L0003`, §19.4).
- **Floats**: `3.14`, `1e-9`, `2.5e3`. Default `f64`.
- **Decimals**: any numeric literal in a `decimal` context is exact: `price * 0.10` with `price:
  decimal(12,2)` is decimal arithmetic. A float literal in decimal context is parsed exactly as
  written (never through binary floating point).
- **Booleans**: `true`, `false`. **Absence**: `none`.
- **Characters**: `'a'`, `'\n'`, `'\u{1F600}'` (type `char`, a Unicode scalar).
- **Strings**: `"text"` with escapes `\n \t \r \b \f \\ \" \' \$ \{ \}` and **interpolation** `{expr}` and
  `{expr:fmt}`; raw `r"…"` (no escapes, no interpolation); multi-line `"""…"""` (indentation of the
  closing quotes is stripped); bytes `b"…"` (type `[u8]`). Type `str` (owned, UTF-8).
- **Regex**: `re"pattern"` — validated at compile time; named groups become record fields
  **[Stage 3]**.

### 1.5 Layout: indentation
- Blocks are delimited by indentation. The lexer emits `NEWLINE`, `INDENT`, `DEDENT` as in Python:
  a block opens when a line is more indented than the previous logical line; it closes on the first
  less-indented line. Indent unit is any consistent number of spaces (formatter: 4).
- Inside `( )`, `[ ]`, `{ }` newlines and indentation are insignificant (implicit line joining).
- A line ending in a binary operator, `,`, `.` or `|>` continues on the next line. A line
  *starting* with `|>` or `.name` also continues the previous line (leading-operator style for
  pipelines and method chains).
- The explicit-brace form `header { stmts }` is accepted anywhere a block is expected; `lume fmt`
  converts it to indentation **[Stage 1]**.

### 1.6 Operators and punctuation
`+ - * / % ** == != < <= > >= = += -= *= /= %= .. ..= -> => | || & && ^ ~ << >> . ?. ?? ? ! : , ; ( ) [ ] { } @ |>`
plus keyword operators `and or not in is as`. `|>` pipes the left value as the first argument of
the right call.

---

## 2. Modules and visibility

```lume
mod payroll                 # optional; defaults to the file name
use std.io                  # brings `io` into scope
use std.data (table, query) # selective import
use std.collections as col  # alias
pub use self.types.*        # re-export
```

- Items (`fn`, `type`, `trait`, `impl`, `const`, `mod`) are private to the module unless `pub`.
  `pub(crate)` → visible to the package.
- Import paths: `std.…` (standard library), `pkg.…` (dependencies by package name), `self.…`,
  `super.…`, `crate.…`. No cyclic module imports (error `M0003`).
- A module's **interface** is the set of its `pub` items; `lume doc` renders it.
- The entry point is `pub fn main()` (returns `()`, or `() ! E` to exit non-zero on error).
  A file without `main` and with top-level statements is a **script** and runs top to bottom.

---

## 3. Types

### 3.1 Primitive types
| Type | Meaning |
|---|---|
| `bool` | `true`/`false` |
| `i8 i16 i32 i64 i128 isize`, `u8 u16 u32 u64 u128 usize` | fixed-width integers; `int` = `i64`, `uint` = `u64` |
| `f16 f32 f64` | IEEE 754 floats; `float` = `f64` |
| `decimal(p, s)` | exact decimal, *p* digits, *s* after the point; `decimal` = `decimal(34, 6)` |
| `char` | Unicode scalar value |
| `str` | owned UTF-8 string; `&str`-like views are `str` borrows (see §6) |
| `()` | unit |
| `never` | the type of expressions that do not return (`fail`, `panic`, `return`, infinite `loop`) |

`int` holds the full 64-bit range whatever its machine representation: the native runtime keeps values of 63 bits
inside the word and the others in a small cell (docs/38-memory-management.md).

Integer arithmetic is **checked** (panics on overflow) in debug and test builds and **wrapping** is
*never* the silent default: release builds keep checks unless the module opts into
`@overflow(wrap)` or uses the explicit operators `+%` (wrapping), `+|` (saturating),
`+?` (checked, returns `T?`). Division by zero is an error value for `checked_div` and a panic for `/`.

Implemented today in native code: `+`, `-` and `*` stop the program on overflow in every build, and `+%`, `-%`, `*%`
wrap. `@overflow(wrap)` is rejected with `[P0002]` rather than ignored, and `+|` and `+?` do not exist yet. The Stage-0
seed wraps: it only runs the bootstrap.

### 3.2 Compound types
| Syntax | Type |
|---|---|
| `(A, B, C)` | tuple; fields `.0`, `.1` |
| `[T]` | growable list (owned, heap) |
| `[T; n]` | fixed array, *n* a comptime integer |
| `T[]` | slice view (borrowed, contiguous) — see §6 |
| `map[K, V]` | hash map; `omap[K, V]` ordered map |
| `set[T]` | hash set; `bitset[E]` for enums (Pascal `set of`) |
| `T?` | optional: `some(x)` or `none`; literals auto-wrap in optional context |
| `T ! E` | error union: a `T` or an error from error set `E`; `T !` infers `E` |
| `fn(A, B) -> R / {effs}` | function type (effects optional, see §8) |
| `rc[T]`, `arc[T]`, `cell[T]`, `weak[T]` | shared ownership tiers (§6) |
| `ptr[T]`, `rawptr` | raw pointers, usable only in `unsafe` |
| `dyn Trait` | trait object (dynamic dispatch) |
| `impl Trait` | some type implementing *Trait* (static, inferred) |
| `T in lo..hi` | range type (subtype of `T`) |
| `T where pred(self)` | refinement type **[Stage 3]**; checked at the boundary |
| `distinct T` | newtype with no implicit conversion to `T` |
| `tensor[T, d1, d2, …]` | tensor with static or symbolic dims **[Stage 4]** |

### 3.3 Type declarations

```lume
type Celsius = distinct f64
type Age     = int in 0..150
type Point   = record
    x: f64
    y: f64 = 0.0                 # default value

type Dept = enum Sales | IT | Finance             # unit variants
type Shape = enum                                  # payload variants
    Circle(radius: f64)
    Rect(w: f64, h: f64)
    Empty

type IoError = error NotFound | Permission(path: str) | Other(msg: str)   # error set
type Pair[T] = record                               # generic
    a: T
    b: T
```

- **`record`** — product type with named fields, value semantics, structural construction
  `Point(x: 1.0, y: 2.0)` (named arguments required unless the record has ≤ 2 fields of distinct
  types). Fields are immutable unless the binding is `var`. Records can declare `invariant`
  blocks (§9).
- **`enum`** — sum type; variants may carry named payloads. `match` must be exhaustive.
- **`error`** — an enum used as an error set; error sets compose: `type AppError = IoError | ParseError`.
- `@derive(Eq, Ord, Hash, Show, Clone, Default, Serde)` on any type generates trait impls.
  Records and enums derive `Eq, Show, Clone` automatically unless `@derive(none)`.

### 3.4 Generics
`fn max[T: Ord](a: T, b: T) -> T`. Type parameters in square brackets; bounds with `:`; multiple
bounds `T: Ord + Show`; `where` clauses for complex bounds. Generics are **monomorphised**.
Comptime values are parameters too: `fn zeros[T, n: usize]() -> [T; n]`.

### 3.5 Type inference
Local inference everywhere (`let x = 3` ⇒ `int`); bidirectional checking lets literals adopt
context types. **Function signatures of `pub` items MUST be fully annotated**; private functions
may omit the return type and effects (inferred). Generic parameters are inferred at call sites.

### 3.6 Conversions
No implicit conversions. `as` converts between numeric types (checked: `x as u8` panics on
overflow in debug; `x as! u8` truncates; `x as? u8` returns `u8?`). `from`/`into` traits for
user-defined conversions. `str(x)` ≡ `x.show()`.

---

## 4. Expressions

Precedence, highest first (same row = same level, left-associative unless noted):

1. Postfix: call `f(x)`, index `a[i]`, field `a.b`, method/UFCS `a.f(x)`, `?` (propagate),
   `?.` (optional chain), `.await` **[Stage 3]**
2. Unary: `-x`, `~x`, `own x`, `mut x`, `&x` (explicit borrow, rarely needed)
3. `**` (right-assoc)
4. `* / %`
5. `+ -`
6. `<< >>`
7. `&`
8. `^`
9. `|`
10. `..` `..=` (ranges; non-associative)
11. `== != < <= > >= in is as` (non-associative: `a < b < c` is a parse error)
12. `not` (prefix; `not not x` is allowed)
13. `??` (right-assoc)
14. `and` / `&&`
15. `or` / `||`
16. `|>` (pipe)
17. `= += -= …` (assignment; statement-level, yields `()`)

**`not` binds looser than a comparison and tighter than `and`** (row 12, as in Python): `not a < b` is
`not (a < b)`, `not a == b and c` is `(not (a == b)) and c`. Earlier drafts of this table listed `not` with unary
minus, which made `not 0 < 2` mean `(not 0) < 2`; the implementations never read it that way, no source of the
repository relies on that reading, and a reader of `if not x < limit` expects the negated comparison, so the table
was corrected (Wave 14; conformance: `w14_not_precedence`). Where a `not` is written as the operand of an
arithmetic or comparison operator (`a == not b`, `x + not y`) it applies to the one postfix expression that
follows it; write parentheses for anything larger. Details and the tree that is built: §19.1.

### 4.1 Blocks as expressions
A block's value is its last expression. `if c then_block elif c2 block else block` is an
expression; all branches must have compatible types (or the `if` is used as a statement with
type `()`).

### 4.2 `match`
```lume
match shape
    Circle(radius)          => 3.14159 * radius ** 2
    Rect(w, h) if w == h    => w * w              # guard
    Rect(w, h)              => w * h
    Empty                   => 0.0
```
Patterns: literals, ranges `0..=9`, bindings `x`, wildcard `_`, variant patterns, record patterns
`Point(x, y: 0.0)`, tuples, lists `[first, ..rest]`, `some(x)`/`none`, `ok(x)`/`err(e)` for error
unions, `x @ pattern` (bind and match), alternatives `A | B`, `is Type` for `dyn` downcast.
An arm body is an expression or an indented block. Matches are checked for exhaustiveness
(`T0040`) and redundancy (warning `W0041`).

### 4.3 Closures
`|x| x * 2` · `|x: int, y: int| -> int x + y` · multi-line:
```lume
let f = |x|
    let y = x * 2
    y + 1
```
Closures capture by borrow by default, by move with `own |x| …`. Code blocks (Clipper) are
closures. A function expecting a closure can take it as a trailing block:
```lume
items.each |item|
    io.println(item)
```

### 4.4 Collections and comprehensions
`[1, 2, 3]` · `[0; 10]` · `{"a": 1, "b": 2}` (map) · `{1, 2, 3}` (set) · `(1, "a")` (tuple).
Comprehensions: `[x * 2 for x in items if x > 0]`, `{k: v for (k, v) in pairs}`.
Slicing: `a[1..3]`, `a[..2]`, `a[2..]`, `a[-1]` (negative from end; checked).

### 4.5 String interpolation
`"Hello, {name}! You are {age:>3} years old. Total {total:.2}"`. Format spec after `:` follows
`std.fmt` (width, alignment, precision, radix). `{{` and `}}` are literal braces. Interpolation
calls `Show` or `Format`.

### 4.6 Ranges
`a..b` half-open, `a..=b` inclusive, `a..` open, `..b`. Ranges are iterable values of type
`range[T]`. `x in 1..=10` tests membership.

### 4.7 `?`, `??`, `?.`
- `expr?` on `T ! E` returns early with the error (the enclosing function's error set must
  include `E`); on `T?` returns early with `none` (enclosing return type must be optional).
- `a ?? b` — `a` if `some`, else `b`. `a?.field` — `none` if `a` is `none`.

### 4.8 Holes
`todo` and `todo "message"` are expressions of type `never` that panic when reached and that the
compiler reports (`W0100`) with the expected type and in-scope bindings. `?` as a bare expression
(a *typed hole*) is an error in release builds and a reported hole in debug/agent mode.

---

## 5. Statements and control flow

```lume
let x = 1                 # immutable binding (shadowing allowed)
let y: f64 = 2            # annotated; literal adopts f64
var count = 0             # mutable binding
count += 1
let (a, b) = pair         # destructuring (also records, enums with one variant)
const MAX: int = 100      # comptime constant (module level)
```

- `if cond … elif cond … else …`
- `while cond …`
- `for x in iterable …` (iterates by borrow; `for own x in …` consumes). Optional index:
  `for (i, x) in items.enumerate()`. `else` clause runs if the loop never `break`s **[Stage 1]**.
- `loop …` infinite; `break`, `break value`, `continue`; loop labels `'outer: for …` / `break 'outer`.
- `return expr`; a function body's last expression is its value if the function is written in
  expression form (`fn sq(x: int) -> int = x * x`).
- `defer expr` runs at scope exit (LIFO); `errdefer expr` runs only when the scope exits with an
  error.
- `fail Variant(args)` returns the error value from a function with an error-union return type.
- `panic "message"` — unrecoverable bug; aborts the task (not the process) in `scope`-managed
  tasks; never caught by `match` or `catch`.
- `assert cond, "message"` — checked in all builds; `debug_assert` in debug only.
- `using resource = expr … ` — binds and guarantees `.close()`/`Drop` at block end (Python `with`).
- `unsafe …` block: enables raw pointers, `asm`, calling `unsafe fn`, `@mmio` access.
- `comptime …` block: evaluated at compile time; its value is a constant **[Stage 2]**.

---

## 6. Memory model: ownership, borrowing, sharing

### 6.1 Values and ownership
Every value has exactly one **owner** (a binding, a field, a collection slot). When the owner goes
out of scope the value is **dropped** (destructor `Drop.drop` runs, LIFO). Assignment and passing
`own` **move** the value; the source is no longer usable (`O0001` use after move). Types that are
plain data (integers, floats, `bool`, `char`, tuples/records/enums of them) are `Copy`: moves are
copies. Non-`Copy` values are duplicated only by explicit `.clone()`.

### 6.2 Borrowing — the default for parameters
```lume
fn total(items: [Item]) -> decimal          # `items` is a shared borrow
fn bump(counter: mut Counter)                # exclusive (mutable) borrow
fn consume(file: own File)                   # ownership moves in
```
- A parameter without a modifier is a **shared borrow**: the callee can read, cannot mutate, cannot
  keep it beyond the call. `mut` is an **exclusive borrow**. `own` **moves**.
- At the call site nothing is written for borrows: `total(items)`, `bump(counter)` (the compiler
  knows `bump` takes `mut`; if `counter` is not a `var`, error `O0010`). Moves are written
  `consume(own file)` so the transfer is visible (P7).
- Rules (Rust's): any number of shared borrows **or** one exclusive borrow at a time; a borrow
  never outlives its owner. Lume infers lifetimes (**regions**) within a module; a `pub` function
  that *returns* a borrow must say which parameter it borrows from: `fn first(items: [T]) -> T
  from items`. The `from` clause replaces lifetime parameters in the common case; full
  `'a` annotations exist for the rare rest **[Stage 3]**.
- `var` bindings own a mutable value; `let` bindings own an immutable one. `mut x` as an
  expression creates an exclusive borrow explicitly where inference needs help.

### 6.3 Shared ownership tiers
- `rc[T]` single-threaded reference count; `arc[T]` atomic (`lock incq` / `lock xaddq` with `mfence`); `weak[T]` non-owning; `cell[T]`
  interior mutability (single-threaded); `mutex[T]`, `rwlock[T]`, `atomic[T]` in `std.sync`.
  Literal syntax: `rc(value)`, `arc(value)`. Deref is automatic for field access (`r.field`) and UFCS (`r.method()`), and built-in tier methods `.clone()`, `.drop()`, `.strong_count()`, `.downgrade()`, `.upgrade(fallback)`, and `.get()` operate on native heap control blocks with compile-time `[O0001]` use-after-drop and `[S0001]` non-`Send` `rc[T]` capture enforcement.
- `@gc` on a type declaration places *that type's* values under a tracing collector for the
  region they are allocated in: `@gc type Node = record …`. GC'd values may form cycles freely;
  they cannot be moved across a `pub` API without the type's `@gc` being visible **[Stage 3]**.

### 6.4 Allocators
Heap-allocating types and functions take an allocator implicitly from the current **context**
(`std.alloc.current()`), which defaults to the global allocator and can be rebound for a scope:
`with alloc = arena … `. `freestanding` builds have no default allocator; the compiler
requires an explicit `with alloc` (`O0030`) — the Zig discipline where it matters.

### 6.5 `unsafe`
Inside `unsafe`: `ptr[T]` deref, pointer arithmetic, `rawptr as ptr[T]`, `asm`, FFI calls,
`@mmio` registers, `transmute`. The compiler never relaxes borrow rules for safe references
inside `unsafe`; `unsafe` only unlocks the operations above. `lume audit unsafe` lists them.

---

## 7. Functions, traits, implementations

### 7.1 Functions
```lume
## Divide, failing on zero.
pub fn divide(a: int, b: int) -> int ! DivError
    requires b != 0 or fail_ok      # contract (§9)
    ensures result * b == a
    if b == 0
        fail DivError.ByZero
    a / b

fn sq(x: int) -> int = x * x                       # expression form
fn greet(name: str, greeting: str = "Hello") -> str  # default argument
    "{greeting}, {name}"
greet("Ana", greeting: "Olá")                      # named argument at call
fn log(items: ...str)                               # variadic (a slice)
```
- `self` as the first parameter makes a function callable as a method on its type (`fn area(self) -> f64`, `fn grow(mut self, by: f64)`, `fn into_bytes(own self) -> [u8]`).
- Recursion is allowed; mutual recursion within a module needs no forward declarations.
- Nested functions and closures capture the environment (Pascal).
- `@inline`, `@noinline`, `@cold`, `@test`, `@bench`, `@deprecated("…")`, `@export`, `@extern("C")` attributes.

### 7.2 Traits
```lume
trait Shape
    fn area(self) -> f64
    fn perimeter(self) -> f64
    fn describe(self) -> str = "area {self.area():.2}"   # default method
    type Unit                                            # associated type
    const SIDES: int                                     # associated const

impl Shape for Circle
    fn area(self) -> f64 = 3.14159 * self.radius ** 2
    fn perimeter(self) -> f64 = 2 * 3.14159 * self.radius
    type Unit = Meter
    const SIDES = 0

fn print_all(shapes: [dyn Shape])          # dynamic dispatch
fn biggest[S: Shape](shapes: [S]) -> S     # static, monomorphised
```
- Traits are nominal (`impl … for …`). **`shape` types** are structural: `shape HasName = { name: str }`
  is satisfied by any record with a `name: str` field, for interop and duck typing **[Stage 2]**.
- Operator overloading only via `std.ops` traits (`Add`, `Mul`, `Index`, …). Comparison via
  `Eq`/`Ord`. Formatting via `Show`/`Format`. Destruction via `Drop`. Iteration via `Iter`.
- Multiple dispatch: `impl Mul[Matrix, Vector] for Matrix` — trait parameters select on more than
  `Self` **[Stage 2]**.
- Coherence: an `impl` lives in the module of the trait or of the type (orphan rule), except
  `@extension impl` which is module-local and never exported.

### 7.3 Properties (Delphi)
```lume
type Account = record
    _balance: decimal(12, 2)
    pub prop balance: decimal(12, 2)
        get = self._balance
        set(v) requires v >= 0 = self._balance = v
```

---

## 8. Errors, effects and panics

### 8.1 Error unions
- `T ! E` where `E` is an error set. `fn f() -> int !` infers `E` from the `fail`s and `?`s in the
  body (private functions only; `pub` must write it).
- `fail E.Variant(…)` returns the error. `expr?` propagates. `expr catch |e| fallback` handles
  inline; `expr catch default` for a value; `match expr` with `ok(v)`/`err(e)` arms.
- `try` block: `try … ` evaluates a block in which `?` jumps to the block's `catch` instead of
  returning from the function **[Stage 1]**.
- Errors carry a **trace** of `?` sites in debug builds (`e.trace()`).

### 8.2 Effects
```lume
fn load(path: str) -> Config ! IoError / {io, alloc}
fn pure_hash(data: u8[]) -> u64                     # no effects: pure
fn fetch(url: str) -> str ! NetError / {net, async}
```
- The effect row `/ {…}` lists what a function may do. Built-in effects: `alloc`, `io`, `fs`,
  `net`, `env`, `time`, `rand`, `async`, `panic`, `unsafe`, `ffi`, `gpu`, `prob`, `llm`,
  `interrupt`, `realtime`, `comptime`. User effects can be declared (`effect Logger …`) with
  handlers **[Stage 3]**.
- Effects are **inferred** for private functions and **required** on `pub` signatures (the
  compiler suggests the row). A caller's effects must include its callees' effects unless it
  *handles* them (`with handler … `).
- Capability security: a package manifest declares the effects it is granted; a dependency that
  needs `net` and was not granted it fails to compile (`E0200`).
- `async` is an effect: an `async` function is called like any other; the runtime provides the
  handler. `.await` exists only to *wait for a task handle* (`task.await`), not to call functions
  **[Stage 3]**.
- `interrupt` forbids `alloc`, blocking and `panic`; `realtime` forbids `alloc`, unbounded loops
  (the compiler requires `for` over finite ranges or `@bound(n)` on `while`) and makes `lume
  prove` attempt a WCET bound **[Stage 5]**.

### 8.3 Panics
`panic` is for bugs. It unwinds the current **task**, running `defer`s and `Drop`s, and is reported
to the task's `scope` as a failure. Processes with one task exit non-zero. `@panic(abort)` builds
abort immediately (kernels).

---

## 9. Contracts and invariants

```lume
fn withdraw(acct: mut Account, amount: decimal(12, 2)) ! InsufficientFunds
    requires amount > 0
    requires acct.balance >= amount or fail InsufficientFunds   # contract that fails softly
    ensures acct.balance == old(acct.balance) - amount
    acct.balance -= amount

type SortedList[T: Ord] = record
    items: [T]
    invariant items.is_sorted()
```
- `requires` — precondition; violation panics (bug in the caller) unless written with
  `or fail Error` (then it is an ordinary error).
- `ensures` — postcondition over `result` and `old(expr)`.
- `invariant` — on records; checked after construction and after every `mut self` method in
  debug/test builds.
- Contracts are documentation (`lume doc` shows them), tests (`lume test` checks them), and proof
  obligations (`lume prove`, **[Stage 5]**). Pure contracts (no effects) are required.

---

## 10. Concurrency **[Stage 3]**

```lume
fn fetch_all(urls: [str]) -> [str] ! NetError / {net, async}
    scope s                                  # structured: all tasks end before `scope` ends
        let handles = [s.spawn fetch(u) for u in urls]
        [h.await? for h in handles]

let (tx, rx) = chan[Msg](capacity: 100)
s.spawn
    for msg in rx
        handle(msg)
select
    msg = rx.recv()      => …
    _   = timer.after(1.s) => …

par for i in 0..n                             # data parallel
    out[i] = f(inp[i])
```
- **Structured concurrency**: tasks are spawned inside a `scope`; the scope waits for all of
  them; cancellation and errors propagate to the scope; no task outlives its scope (no leaks).
- `chan[T]` channels (bounded/unbounded), `select` over channels and timers.
- Data-race freedom from ownership: a value sent to another task must be `Send`; shared values
  must be `Sync` (`arc[mutex[T]]`). The compiler proves it; no runtime race detector needed for
  safe code.
- `std.actor`: `actor` types with typed mailboxes, `supervisor` with restart strategies (Erlang).
- `par for`, `par map`, `reduce` for data parallelism (work-stealing runtime); `kernel fn` for
  accelerators (§13).
- Deterministic logical time (`std.time.logical`) for simulations and reactors.

---

## 11. Data: records, tables, queries, persistence **[Stage 2]**

```lume
use std.data (table, query, index)

let customers = table[Customer].read_csv("customers.csv")?
index customers by id                       # unique index
index customers by (city, name)

let vip = query customers
    where balance > 10_000 and city == "Curitiba"
    order by balance desc
    select (name, balance)                  # projection → table[(str, decimal)]
    limit 50

let by_city = query customers
    group by city
    select (city, count(), sum(balance) as total)

let orders_with_names = query orders
    join customers on orders.customer_id == customers.id
    select (orders.id, customers.name, orders.total)

for c in vip
    io.println("{c.name}: {c.balance}")

persist table[Customer] customers at "data/customers"     # ACID, crash-safe, concurrent
customers.insert(Customer(id: 1, name: "Ana", …))?
customers.update(where: |c| c.id == 1, set: |c| c.balance += 10)?
```
- `table[T]` — typed, columnar in memory (`@soa` default), with indexes; implements `Iter[T]`.
- `query` is an expression with clauses in **logical order**: `from`-source first (`query src`),
  then `join`, `where`, `group by`, `having`, `order by`, `select`, `limit`/`offset`. Clause
  expressions are type-checked against the record type; field names resolve to the current row.
  Result type is derived from `select`. Compiles to vectorised in-memory plans, or to the backend's
  native query for external sources (PostgreSQL, SQLite, DuckDB adapters) — same syntax.
- `relation` declares a typed foreign-key relation usable in `join` by name (Clipper `SET RELATION`).
- `rule` blocks (Datalog) over tables **[Stage 4]**: `rule ancestor(x, z) when parent(x, y), ancestor(y, z)`.
- Types: `decimal(p,s)`, `date`, `time`, `datetime`, `duration`, `money[CUR]` (decimal with
  currency unit), `uuid`. Literals: `2026-10-24d`, `14:30t`, `1.5h`, `250ms`, `R$ 10.50`.
- `report` blocks (declarative headers/groups/footers) and `form` descriptions live in `std.report`
  and `std.ui`, not in the core.

---

## 12. Compile-time programming **[Stage 2]**

```lume
comptime
    const TABLE = [i * i for i in 0..256]           # computed at compile time

fn vec[T, n: usize]() -> [T; n] = [T.default(); n]

macro unless(cond, body)                             # hygienic AST macro
    quote
        if not $cond
            $body

unless x > 0
    io.println("non-positive")

@derive(Show) type P = record …                      # derive = macro over the type AST
type Row = schema "orders.sql"                       # type provider: types from a schema at comptime
```
- `comptime` blocks and parameters run the Lume interpreter at compile time (any pure function).
  Types are comptime values (`type` is a type).
- `macro` operates on typed AST (`quote`/`$splice`), hygienic by default; `lume expand` shows the
  result. Macros cannot perform effects other than `comptime` (reading schema files is allowed
  through the `schema`/`embed` builtins, which are tracked as build inputs).
- `when` compile-time branching: `when target.os == "linux" …`.
- `embed "file"` includes bytes at compile time.

---

## 13. Machine level **[Stage 5]**

```lume
@repr(c) type Header = record { magic: u32, len: u16, flags: u8, _pad: u8 }
@packed  type Pixel  = record { r: u8, g: u8, b: u8 }
@bits    type Status = record { ready: 1, error: 1, mode: 2, _: 4 }     # bit fields
@mmio(0x4000_0000) var UART: UartRegs

unsafe
    let p: ptr[u8] = buf.as_ptr()
    p[3] = 0xFF
    asm "mov {out}, cr3" out = own cr3: u64

kernel fn saxpy(a: f32, x: tensor[f32, n], y: mut tensor[f32, n])
    for i in par 0..n
        y[i] = a * x[i] + y[i]

@target(freestanding) @no_std
pub fn _start() -> never / {interrupt} …
```
- Layout attributes are contracts (P18). Default record layout is compiler-chosen (reordered for
  size) unless `@repr(c)`.
- `import c "header.h"` makes C declarations available as `extern "C"` items with mapped types;
  `@export("C")` exposes Lume functions to C.
- `kernel fn` compiles for the active accelerator target; `@gpu` memory spaces in tensor types;
  `@schedule(…)` / `@autotune`.
- Capability types for kernel resources (`cap[Page]`, `cap[Port]`): linear (must be used exactly
  once, cannot be copied), from `std.os.cap`.

---

## 14. AI constructs **[Stage 4]**

```lume
type Mlp = model
    w1: tensor[f32, 784, 128]
    b1: tensor[f32, 128]
    w2: tensor[f32, 128, 10]
    b2: tensor[f32, 10]
    fn forward(self, x: tensor[f32, batch, 784]) -> tensor[f32, batch, 10]
        (x @ self.w1 + self.b1).relu() @ self.w2 + self.b2

fn loss(m: Mlp, x, y) -> f32 = m.forward(x).cross_entropy(y)
let g = grad(loss)                               # ∇ wrt the first argument, compiled
var m = Mlp.init(rand)
for (x, y) in batches
    m -= lr * g(m, x, y)

fn coin(prior: Beta) -> f64 / {prob}
    let p = sample prior
    observe flips ~ Bernoulli(p)
    p
let post = infer coin(Beta(1, 1)) with mcmc(steps: 10_000)

extern llm fn extract(text: str) -> Invoice ! LlmError / {llm}
    """Extract invoice fields. Dates ISO-8601, amounts decimal."""
    ensures result.total == result.items.sum(.amount)
```
- `model` types: records whose tensor fields are **parameters** (iterable as a tree), with a
  `forward`; `save`/`load` (safetensors), `export onnx`, a content hash as version.
- `tensor[T, dims…]`: dims are comptime integers or symbolic names unified across a function.
  `@` is matrix multiplication (`std.ops.MatMul`); broadcasting operators `.+ .* ./`; `einsum`
  typed. Shape mismatch is error `T0300`.
- `grad`, `vjp`, `jvp`, `vmap`, `jit`, `shard` are compiler intrinsics on pure functions with
  tensor types (including control flow).
- `prob` effect: `sample`, `observe`, `infer … with algorithm` as handlers.
- `extern llm fn`: the docstring is the instruction; the signature is the schema (constrained
  decoding); `ensures` validates; retries/budget/model in the `llm` handler configuration;
  `test llm` cases in the test runner.

---

## 15. Standard library map (names are normative; contents grow by stage)

`std.core` (prelude: `Option`, `Result`, `Iter`, `Show`, `Eq`, `Ord`, `Clone`, `Drop`, `Default`),
`std.io`, `std.fs`, `std.fmt`, `std.str`, `std.collections`, `std.math`, `std.decimal`, `std.time`,
`std.rand`, `std.sync`, `std.task`, `std.actor`, `std.chan`, `std.net`, `std.http`, `std.json`,
`std.data` (`table`, `query`, `index`, `persist`, adapters), `std.report`, `std.ui`, `std.sh`,
`std.regex`, `std.alloc`, `std.mem`, `std.os`, `std.os.cap`, `std.ffi`, `std.simd`, `std.tensor`,
`std.nn`, `std.prob`, `std.llm`, `std.rules`, `std.neuro`, `std.test`, `std.bench`, `std.prove`,
`std.build`.

---

## 16. The `lume-core` IR (normative kernel) **[Stage 0]**

Everything above desugars to a small typed core:

- **Values**: literals (`int`, `float`, `decimal`, `bool`, `char`, `str`, `unit`), tuples,
  records (nominal), variants (nominal sum), closures, references (`&`, `&mut`, `own`), raw pointers.
- **Terms**: `let`, `var`/`set`, `call`, `if`, `match` (flat, exhaustive, on one scrutinee),
  `loop`/`break`/`continue`, `return`, `block`, `defer`, `fail`, `panic`, `borrow`, `move`, `drop`,
  `field`, `index`, `construct`, `cast`, `unsafe`, `asm`, `comptime`, `handle`/`perform` (effects).
- **Types**: the primitives, `fn` with effect row, `tuple`, `record`, `variant`, `ref`, `ptr`,
  `array[n]`, `slice`, `forall` (generics), `exists` (`dyn`), `range`, `refine`.
- Operational semantics and typing rules are in `docs/core/` (to be mechanised in Lean,
  **[Stage 5]**). Stage 0 implements this core plus the surface subset of §1–§9.

---

## 17. Diagnostics (normative format)

Every diagnostic: `code` (`L` lexical, `P` parse, `T` type, `O` ownership, `E` effect,
`M` module, `C` contract, `W` warning), `severity`, `message` (one sentence, plain English, names
the concept), `span` (file, line, col, len), `labels` (secondary spans), `expected`/`actual`
(when applicable), `help` (a suggested fix, ideally as a text edit), `principle` (optional `P#`),
`doc` (URL/anchor into the spec). `--json` emits one JSON object per diagnostic; `lume agent`
streams them.

---

## 18. Editions and conformance

- `edition = "2026"` in `lume.toml`. The conformance suite `tests/conformance/` is normative: an
  implementation conforms to v0.1 if it passes the Stage-tagged subset for its stage.
- Reserved for future editions: `yield` semantics, `shape` types, `effect` declarations,
  `@gc` regions, `realtime` WCET, hardware generation (`std.hw`).

---

## 19. Lume-Core as compiled by `lumec` (normative for `.src`, Stage 1)

The sections above describe the surface language. The self-hosted compiler `lumec` (and `lcaas`, which runs the same
front end) compiles **Lume-Core**, the expression language of the `.src` files: `fn name(params) = expr`, `let .. in`,
`if .. then .. else`, `match`, records, `law`, contracts. Where Lume-Core is narrower or more precise than the surface
rules, this section is the rule; every item names its diagnostic and its conformance test
(`bootstrap/lume0/tests/run_native.src`, run by `build/bin/lume_make test`; the fail-closed sources are in
`tests/conformance/stage1/fail_closed/`). The decisions were taken in Wave 14 against one principle: *what a reader
of the source expects, and what existing certified code relies on*.

### 19.1 `not`
`not` is a prefix operator one level looser than the comparisons and one level tighter than `and` (§4, row 12).
`not a < b` is `not (a < b)`; `not not x` is `x` as a truth value; `not a and b` is `(not a) and b`. The tree that
is built for `not e` is `(== e 0)`, in the compiler and in the prover alike, so a program and its proof read the
same thing. As the operand of an arithmetic or comparison operator (`a == not b`) a `not` takes exactly the
postfix expression that follows it. Test: `w14_not_precedence`.

### 19.2 Lines and statements
Lume-Core is free-form inside an item: **a line break is white space**. An expression runs on to the first token
that cannot continue it, so

```
fn total(a, b) = a
    + b            ## one expression: a + b
```

and a line that starts with a binary operator (`+ - * / % == != < <= > >= and or |>`) always continues the
expression before it. Three places are tied to the line:

- a call parenthesis or an index bracket is postfix only on the line of its operand (`f` newline `(x)` is the value
  `f` followed by a new expression);
- `let x = v` without `in` needs its body on a new line;
- **a top-level item starts on a new line.** `print 1 2`, or `fn f() = 1 fn g() = 2`, is one line with two
  statements and is an error (`P0003`); they used to be accepted as two statements. A stray closing token or
  operator keeps its own `P0002`.

The arms of a layout `match` are recognised by their column (the column of the first arm). Tests:
`w14_statement_rule`, `fail_closed/P0003_two_statements.src`.

### 19.3 Comments
`#` starts a comment that ends with the line (`##` by convention). `#[` starts a **block comment** that ends at
the matching `]#`; block comments nest and may span lines; inside a `#` / `##` line comment `#[` has no meaning. An
unterminated block comment is `L0004` and names the position where it opened. Tests: `w14_block_comment`,
`fail_closed/L0004_unterminated_block_comment.src`.

### 19.4 Integer literals
Decimal `42`, `1_000_000`; `0x1F`, `0b1010`, `0o755` with **lowercase** prefixes. An underscore separates two digits
of the literal. Everything else that starts with a digit is `L0003` and is never split into two tokens: an uppercase
prefix (`0X1F`, `0B11`, `0O17`), a leading, trailing or doubled underscore (`0x_F`, `1_`, `1__0`), a digit glued to a
name (`2a`, `12abc`, `1e3`, `0x1G`, `0b12`), a prefix without digits (`0x`), and a literal outside the 64-bit range.
Tests: `w14_int_literals`.

### 19.5 Types: gradual by default, strict where everything is annotated
A function without annotations is dynamically typed, and a partly annotated one is checked where a type is evident
(`T0001`), exactly as before. A function is **fully annotated** when every parameter has a type and the return type
is declared; that is the critical subset, and inside it (the body, the `requires` / `ensures` clauses, and the body
of a `law` whose parameters are all annotated) `int`, `bool` and `str` do not convert into one another:

| Code | Rejected |
|---|---|
| `T0601` | the condition of an `if` is an `int` / `str` (`if n then ..`) |
| `T0602` | the body does not have the declared return type (`-> int = a < b`, `-> bool = 1`) |
| `T0603` | an argument does not have the declared type of the callee's parameter |
| `T0604` | an operator on operands it does not take: arithmetic on a `bool` or a `str`, `and` / `or` on an `int`, an `int` compared with a `bool`, an `int` mixed with a decimal literal (`1.0 + a`) |
| `T0605` | `let x: T = v` where `v` is not a `T` |
| `T0606` | the branches of an `if` / `match` have different types |
| `T0607` | a `requires` / `ensures` / `law` clause is not a `bool` |

The types are read from what is written: literals, the annotated parameters and `let`s, the declared return type of a
callee, the operators, `count` / `ord` / `toint` (`int`) and `str` / `chr` (`str`); a `type N = int` alias or
refinement counts as its base. An expression whose type is not known that way is never flagged, so the rule has no
false positive on untyped values flowing through a typed function. `not b` is `b == 0`, the one comparison of a
`bool` with an `int` literal that is accepted. `if b then 1 else 0` turns a `bool` into an `int`; a comparison turns
an `int` into a `bool`. Tests: `w14_strict_types`.

### 19.6 Attributes
An attribute is `@name` or `@name(args)` on the line(s) before the item. The names with a meaning in `lumec`:
`@bound(cycles: n)`, `@no_alloc`, `@secret`, `@freestanding`, `@interrupt`, `@export`, `@protect` (before `fn`,
`pub fn`, `total fn`, `pub total fn` and `extern .. fn`), `@gc` / `@soa` (before `type`), `@capability` / `@grant`,
`@link` / `@need` (module level). The names this specification reserves for later stages are read and have no
effect in Stage 1: `@repr @schedule @autotune @derive @inline @noinline @cold @deprecated @test @bench @target @mmio
@bits @packed @panic @no_std @gpu @extension`. **Any other name is an error (`P0004`)** with a did-you-mean for a
near miss (`@no_aloc` -> `@no_alloc`, `@secert` -> `@secret`): a misspelt safety attribute used to be dropped without
a word. A function attribute in front of an item it cannot qualify (`@no_alloc` before `type`, before `law`, before
`kernel fn`) is `P0004` too, and an attribute above `extern .. fn` now reaches the function (it used to be parsed
and dropped). `@overflow` is not supported (`P0002`: write `+% -% *%`). Tests: `w14_attributes`.

### 19.7 Effects and totality
- `ctfail(msg)` stops the program with a message and exit status 3. It is not an effect: a function declared
  `/ pure` may call it (stopping is how a pure function reports a violated precondition).
- A `total fn` has to terminate. Direct recursion needs a measure (`terminates (m1, m2, ..)`, lexicographic) that
  is proven to decrease; **mutual recursion between `total` functions is always refused (`A0002`)**: only direct
  recursion carries a measure. Tests: `w14_pure_ctfail_total_mutual`.

### 19.8 Bit operations and shifts
`bit_and`, `bit_or`, `bit_xor`, `bit_not` work on the 64-bit two's-complement value. `bit_shl(a, k)` and
`bit_shr(a, k)` (also spelt `bv_shl` / `bv_shr`) are **defined for 0 <= k <= 63**: `bit_shr` is arithmetic (it
propagates the sign, `bit_shr(-8, 1)` is `-4`, `bit_shr(-8, 63)` is `-1`), `bit_shl` drops the bits that leave the
word (`bit_shl(1, 63)` is the smallest integer; it never traps on the value). **A count outside 0..63 stops the
program**, as a division by zero does: a literal count is a compile-time error (`C0012`), a computed one is the
run-time error `lume: shift count outside 0..63` (exit status 3). The machine would take the count modulo 64
(`bit_shl(1, 64)` was `1`), which no evaluator of the tool chain models. The prover gives a shift a value for
counts 0..62 and no value otherwise (a contract that depends on it stays `runtime_checked`); `lcaas` folds counts
0..63 and reports the others. `@secret` code takes literal counts only (`C0011`). `emit(v)` writes a string, or the
low byte of the integer `v`; any other value is the run-time type error. Tests: `w14_shift_range`, `w14_emit_byte`.

### 19.9 Contracts: what `proven` means
`requires` is checked at run time on every call. `ensures` is checked at run time unless it is **proven**, and
`--keep-proven-checks` (`--critical`) keeps the check of a proven clause as well. `proven` therefore means: *on every
execution that reaches the check, the check passes*. That is two things, and the prover establishes both:

1. the clause cannot evaluate to false (QF_LIA / Fourier-Motzkin over the paths of the body), and
2. **the clause evaluates**: its own evaluation cannot stop the program. On each path the evidence is the path's
   (the `requires`, the body that ran, the earlier clauses), never the clause's own:
   - an operand of arithmetic or of `< <= > >=` is an integer on that evidence (`==` / `!=` take any value);
   - `+ - *` stay inside the 64-bit range: the term is a constant, the value of one variable, a value the path
     already computed, or is proven between `-MAX` and `MAX` from the hypotheses;
   - a divisor is proven `> 0` or `< -1`; a shift count is proven inside `0..63`;
   - a call of a program function, a field read or an arithmetic operation may be repeated in the words in which
     the path evaluated it; another call of a program function, a field without evidence, a string operation are
     not shown to evaluate.

A clause that fails (2) is `runtime_checked`: its check is compiled in every build, so the default build and
`--keep-proven-checks` agree on every input, including the inputs on which the clause stops the program (a type
error, an overflow, a division by zero in the clause). Before Wave 14 such a clause was `proven`:
`fn g(x) ensures x - 0 == x = x` returned from `g("s")` in the default build and stopped under
`--keep-proven-checks`. `refuted` (a counterexample was found: `V0001`) and `budget_checked` (`@bound`, one
structural cost model shared by `lumec` and `lcaas`: `V0002`) are unchanged. A proof certificate
(`lume certify` / `lume verify-cert`) states (1) over the mathematical integers; only
`lume verify-cert --check-source <file.src> <certificate.json>` binds a certificate to a source, and its kernel
does not re-derive (2). Tests: `tests/harness/prover_fuzz.src` (`clause_*` cases), `tests/harness/realtime_gate.src`.
