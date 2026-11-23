# Lume Reference (factual) — v1.2.0

This is the reference of what works today. It contains no roadmap and no vision material: that is in
`lume manual vision` and in the other chapters, which mix both. Every example below is run by
`tests/docs/ref_examples_gate.src` (in the test suite) with the installed toolchain; the block under each example
is its exact output.

Status labels: **stable** = Linux x86-64 and Windows x64, same behavior; **linux** / **windows** = that platform
only; **experimental** = works, the API may still change; **privileged** = needs root (Linux) or an elevated
process (Windows); **kernel** = only inside an `@freestanding` kernel (section 7a).

Every builtin a program can call is listed here (the table `compiler/stage1/builtins_table.src`, column doc, is
checked against this file by the builtins gate); runtime routines no program calls and names only the compiler
produces are left out.

## 1. Programs and commands

A program is a `.src` file. Top-level `print` lines run in order. `lume run f.src [args]` builds and runs it,
`lume build f.src -o out` writes a native executable (`out.exe` on Windows), `lume test f.src` runs every
`fn test_*()` that returns a truth value, `lume check f.src` type-checks without running, `lume fmt f.src` formats
in place (`--check`, `--stdout`), `lume manual [chapter]` prints the manual (`--pt` in Portuguese). `lume run --profile f.src` prints per function
the self and total time, calls and allocations, and the GC time, on stderr at exit (inlined functions count in their
caller; `LUME_FL=off` keeps them; a tail loop is one call). `lume debug [--commands FILE] [-x CMD]... f.src` runs it
under the debugger: breakpoints on a function or FILE:LINE, `step` / `next` / `finish` / `continue` from call to call,
`bt` with each frame's arguments, `args`, `locals`, `print NAME`, `frame N`, `up`, `down`, `mark` (ends an answer),
`output FILE` (write to FILE, appending), and a stop on a run-time
error; text commands, output on stderr (an AI drives it with `-x`). `lume debug --dap` serves the same debugger over
the Debug Adapter Protocol on stdin / stdout (Content-Length framing or one JSON per line): launch, breakpoints by
line or function, stackTrace, scopes, variables, evaluate, continue, next, stepIn, stepOut; events stopped (breakpoint,
step, exception on a run-time error), output, exited, terminated.

`lume verify [--jobs=N] a.src b.src ...` runs check, test, prove, the format check and certify on many files in N processes
(default 2); each file's result is cached by the SHA-256 of its whole bundle and of the tools, so after a change only
the changed module and the files that import it run again. Each line shows the time of every step
(`ok   a.src  (check 0.030 s, test 0.124 s, prove 0.014 s, fmt 0.017 s, certify 0.027 s)`), so a slow step stands out;
a file without contracts has nothing to certify and passes that step.

Packages: `lume pkg publish [dir] --store=DIR` runs the package's own checks (`lume test` on every file with a
`fn test_`, `lume prove` on every file with contracts; a package with dependencies is checked beside them, resolved
from the same store) and stores NAME/VERSION immutably with its SHA-256. `lume pkg add NAME@REQ` writes
`name = "REQ"` under `[dependencies]` (REQ: `1.2.3`, `^1.2`, `~1.2.3`, `>=1.2`, `<2`, a comma-joined list such as
`>=1.2, <2`, or `*`). `lume pkg install --store=DIR` resolves the manifest and every package's own dependencies (the
version `lume.lock` names while it still fits, else the highest stored version that meets every requirement; a
conflict names each requirement and who made it), checks each copy against its published hash and the hash in
`lume.lock`, runs each package's own tests and proofs, and only when all pass fills `lume_modules/` and writes the
versions and hashes into `lume.lock`. A refused install changes nothing; `--allow-failing` installs anyway, with a
warning. `--update` ignores the lock and takes the newest versions; `--locked` refuses any change to the lock (CI).
`lume pkg resolve [dir] --store=DIR` prints the versions install would take and changes nothing. `use NAME` finds an
installed package, also from inside another one. The store can also be named by `LUME_PKG_STORE`.

Remote registries: `--registry=https://host/path` (or `[registry] url = "..."` in `lume.toml`, or
`LUME_PKG_REGISTRY`) names an index registry: `lume-index.toml` at its root holds one `[[package]]` table per version
(`name`, `version`, `archive`, the archive's `sha256`, the files' `hash`, `deps = ["util ^1.0"]`). The index and the
archives are fetched with `std/http` (HTTPS: TLS 1.3, the certificate checked against the system roots and the host
name; plain `http://` only to this machine unless `--allow-http`); a directory path works the same way without the
network. Each archive (a ustar `.tar.gz` that `tar` also reads, holding only `lume.toml` and `NAME.src` files) is
checked against the index's SHA-256 BEFORE anything is extracted, kept in the cache (`--cache=DIR`, `LUME_PKG_CACHE`,
default `~/.lume/pkg-cache`), then staged, tested, proved and installed exactly like a store package; `lume.lock`
records each archive's URL and SHA-256, and a published version whose archive changed is refused. `--registry=git+URL`
reads an index registry kept in a git repository and pins its commit in `lume.lock`. A dependency
`name = { git = "URL", rev = "REV" }` (written by `lume pkg add NAME --git=URL [--rev=REV]`) is fetched with the
system `git` (started directly, no shell) and pinned to its commit in `lume.lock` until `--update`. With a complete
`lume.lock` and cache, `--offline` installs without the network. `lume pkg publish [dir] --registry=DIR` runs the
package's checks, writes `DIR/NAME/NAME-VERSION.tar.gz` and adds the version to `DIR/lume-index.toml`; serve DIR with
any static web server, or commit it to a git repository.

Official examples: `examples/topics/*.src` (one file per topic, each run by `lume test`) and
`examples/diagnostics/` (for a diagnostic code, `CODE_name.bad` gives it and `CODE_name.fixed.src` is the corrected
program); `tests/docs/examples_gate.src` runs all of them on every release.

```lume
fn square(x) = x * x
print square(7)
```
```output
49
```

## 2. Syntax

- `fn name(a, b) = expr`, `pub fn` (exported), `priv fn` / `priv const` / `priv law` (private to its module), `const NAME: T = expr`,
  `type T = A(x) | B(x, y)`, `use module`, `use module as alias`, `use std/NAME` (always the standard library's NAME, even when the project has a NAME.src), `## comment` (to the end of the line).
- Expressions: `let x = e in body`, `if c then a else b`, `match v` with one `Pattern => expr` per line,
  `fn(x) => expr` (a closure; captures variables), `{a: 1, b: 2}` (record), `r.a` (field), `{ r with a: 3 }`
  (a copy with a field changed), `[1, 2, 3]` (a list), `Cons(h, t)` / `Nil`.
- Integers are 64-bit; an overflow stops the program (exit 3). `/` truncates toward zero, `%` has the sign of the
  left operand. `*` `/` `%` bind tighter than `+` `-`. Comparisons and `and` / `or` / `not` give booleans, printed
  as `1` / `0`.
- Strings are bytes (UTF-8): `count` counts bytes, `+` joins two strings and nothing converts implicitly
  (`str(x)` makes a string, `toint(s)` reads one).

```lume
type Shape = Circle(r) | Rect(w, h)
fn area(s) = match s
    Circle(r)  => 3 * r * r
    Rect(w, h) => w * h
print area(Circle(2))
print area(Rect(3, 4))
let p = {x: 1, y: 2}
print p.x + p.y
let q = { p with y: 10 }
print q.y
print 7 / 2
print 0 - 7 / 2
print 7 % 3
```
```output
12
12
3
10
3
-3
1
```

## 3. Errors at run time

A program stops with exit code 3 and one line on stderr on: integer overflow, division by zero, an index outside a
list, string or buffer, a field a record does not have, a value of the wrong kind for an operation, a `match` with
no arm. `lume test` reports such a stop as a failed test and goes on with the others. After the message come the
calls that led there, innermost first, one `  at NAME (file.src:LINE)` line each (a function inlined into its caller
and a tail call leave no line; `LUME_FL=off` keeps small functions as calls).

```lume
print 9223372036854775807 + 1
```
```output
exit 3
stderr: lume: integer overflow
```

## 3a. Diagnostic codes

Every diagnostic carries a code in brackets (`[T0604]`) or, as JSON (`lume agent check`), the field `"code"`.
"compiler" = `lume build / run / test / check`; "analyser" = `lume check` and `lume agent check`. A code with an
example has, in `examples/diagnostics/`, the program that gives it (`.bad`) and the corrected one (`.fixed.src`),
both checked by the examples gate on every release.

| Code | Means | Reported by | Example |
|---|---|---|---|
| `A0001` | unfilled typed hole `_` in a `pub fn`; the fix-it proposes a candidate | analyser | `A0001_typed_hole` |
| `A0002` | `total fn` whose recursion is not proven to decrease | analyser | `A0002_not_terminating` |
| `A0003` | value of an `llm fn` reaches a `pub fn` result or a trusted sink unverified | analyser | `A0003_unverified_ai_value` |
| `A0004` | semantic AST patch names a missing function or a malformed expression | lume agent patch | - |
| `C0001` | internal: a construct without lowering (a call through a value inside a contract) | compiler | - |
| `C0002` | internal: a name with no value at code generation | compiler | - |
| `C0009` | branch or match on a secret value (timing leak) | analyser | `C0009_secret_branch` |
| `C0010` | emitted code of a `@secret` function branches, divides or reads outside its frame | ltv (lume tv) | - |
| `C0011` | what a constant-time kernel (`@secret` + `@no_alloc`) cannot lower branch-free | compiler | `C0011_secret_kernel_shift` |
| `C0012` | literal shift count outside 0..63 | compiler | `C0012_shift_count_literal` |
| `C0271` | `comptime embed`: bad, empty, `..` or missing path | compiler | - |
| `C0430` | capsule opened without its grant, or tampered | lume capsule | - |
| `C1001` | comptime evaluation error (overflow, `unquote` outside `quote`...) | compiler | `C1001_comptime_overflow` |
| `D0002` | two functions with one name | compiler | `D0002_duplicate_function` |
| `D0003` | two types with one name | compiler | `D0003_duplicate_type` |
| `D0004` | a record literal gives one field twice | compiler | `D0004_field_given_twice` |
| `D0273` | `comptime table_schema(T)` of a type that is not a supported record | compiler | `D0273_table_schema_of_int` |
| `D0405` | symbol or address not in the `.lsym` sidecar | lume symbolize | - |
| `E0001` | internal: a compiler error the analyser could not classify | analyser | - |
| `E0002` | internal: an analysis stopped (report it with the program) | analyser | - |
| `E0200` | an effect the signature does not declare (`/ pure`, kernel, ISR, shard, capability) | compiler | `E0200_effect_of_pure_fn` |
| `E0210` | `@no_alloc` code that may allocate (an unbounded int, a call that allocates) | compiler | `E0210_no_alloc_unbounded` |
| `E0305` | a value used after `chan_send_linear` moved it (immediates copied around it are fine) | compiler | `E0305_linear_used_after_send` |
| `E0306` | locks out of rank order, a lock held at return, or an actor wait cycle | compiler | `E0306_lock_never_released` |
| `I0002` | a WASM-exported function outside the scalar i64 fragment | analyser | - |
| `I0003` | unsupported or duplicate C declaration in a header | lume adapt | - |
| `I0004` | a C FFI function with more than 6 parameters | compiler | - |
| `I0275` | target-specific interop refusal | ltarget | - |
| `K0005` | physical write into the kernel text/rodata range [32768..262143] | analyser | `K0005_write_into_kernel_text` |
| `K0006` | mutual recursion in a freestanding kernel | analyser | `K0006_kernel_mutual_recursion` |
| `K0007` | a kernel-only builtin (port I/O, MSRs, cli / sti / hlt, CR3, invlpg, IDT, interrupts, AP boot, task switch, `vga_*`) in a hosted program | compiler | `K0007_kernel_builtin_in_hosted` |
| `K0010` | certificate for another source (hash mismatch) | lcert | - |
| `K0011` | source obligation without a certificate entry | lcert | - |
| `K0012` | certificate entry without a source obligation | lcert | - |
| `K0013` | certificate term is not the obligation the source states | lcert | - |
| `K0014` | declaration or expression outside the certifiable fragment | lcert | - |
| `K0015` | source unreadable as a whole | lcert | - |
| `K0016` | obligation kind outside the fragment | lcert | - |
| `K0017` | duplicate declaration or certificate entry | lcert | - |
| `K0400` | a GPU kernel body outside scalar arithmetic, let and if | lume agent kernel | `K0400_kernel_outside_fragment` |
| `L0001` | unterminated string literal | compiler | `L0001_unterminated_string` |
| `L0002` | other lexical error (unknown escape, bad character) | compiler | `L0002_bad_escape` |
| `L0003` | malformed number (digit glued to a name, bad radix, trailing `_`) | compiler | `L0003_digit_glued_to_name` |
| `L0004` | unterminated block comment `#[` | compiler | `L0004_unterminated_block_comment` |
| `L0010` | a symbol defined twice in the assembly | lasm | - |
| `M1001` | payload not printable ASCII | lume mesh | - |
| `M1002` | missing, duplicate or unknown payload field | lume mesh | - |
| `M1003` | unknown transaction operation | lume mesh | - |
| `M1004` | construct outside the semantic protocol fragment | lume mesh | - |
| `M2001` | compiler rejected the canonical AST without a diagnostic | lume mesh | - |
| `M2002` | duplicate, orphan or ambiguous function or signature | lume mesh | - |
| `M2003` | unsupported semantic target | lume mesh | - |
| `M2004` | capabilities outside the negotiated set | lume mesh | - |
| `M2005` | request beyond the negotiated bounds | lume mesh | - |
| `M3001` | acceptance `prove` with an obligation not proven | lume mesh | - |
| `M3002` | contract target missing or ambiguous | lume mesh | - |
| `M3003` | replace of a contract that does not exist | lume mesh | - |
| `M3004` | lineage index that does not exist | lume mesh | - |
| `N0400` | `grad` / `jvp` / `vjp` of a function outside the differentiable fragment | compiler | `N0400_autodiff_division` |
| `O0001` | use of a moved value | compiler | `O0001_use_after_move` |
| `O0002` | move out of a borrowed parameter | compiler | `O0002_move_from_borrowed` |
| `O0004` | a resource never released, returned or passed on | compiler | `O0004_resource_dropped` |
| `O0010` | immutable binding borrowed as `mut` | compiler | `O0010_immutable_to_mut` |
| `O0011` | one value borrowed `mut` and read in the same call | compiler | `O0011_conflicting_borrows` |
| `O0012` | an `own` parameter given an argument without `own` | compiler | `O0012_missing_own` |
| `O0013` | a move or mutation while a borrow is live | compiler | `O0013_move_while_borrowed` |
| `O0020` | a borrow of a local escapes its function | compiler | `O0020_borrow_escapes` |
| `O0021` | a `pub fn` returns a borrow without `from PARAM` | compiler | `O0021_borrow_without_origin` |
| `O0030` | heap allocation in `@freestanding` code without `with alloc` | compiler | - |
| `P0001` | a delimiter still open at the end of the file | compiler | `P0001_unclosed_at_end` |
| `P0002` | other parse error | compiler | `P0002_parse_error` |
| `P0003` | two statements or functions on one line | compiler | `P0003_two_functions` |
| `P0004` | unknown attribute (a typo in `@no_alloc`, `@secret`...) | compiler | `P0004_unknown_attribute` |
| `PC0002` | proof cache entry rejected (version, schema or digest) | lproof_cache | - |
| `PC0003` | the prover binary is missing for the missed obligations | lproof_cache | - |
| `PC0005` | cache misses where all hits were required | lproof_cache | - |
| `R0001` | missing or empty component artifact | lume registry | - |
| `R0002` | the independent proof kernel rejected the certificate | lume registry | - |
| `R0003` | registry toolchain incomplete | lume registry | - |
| `R0004` | target other than x86_64-linux-elf | lume registry | - |
| `R0005` | other registry error (message says which) | lume registry | - |
| `R0200` | call to a function that does not exist | compiler | `R0200_undefined_function` |
| `R0201` | a function named like a runtime builtin | compiler | `R0201_builtin_clash` |
| `R0202` | a builtin called with the wrong number of arguments | compiler | `R0202_builtin_arguments` |
| `R0203` | call to an internal routine of the runtime | compiler | `R0203_internal_routine` |
| `R0204` | `f[...]` on a function | compiler | `R0204_index_a_function` |
| `R0205` | a local named like a builtin is called (the call goes to the builtin) | compiler | `R0205_local_named_like_builtin` |
| `S0001` | spawn outside a scope, or capturing a non-Send or `var` value | compiler | `S0001_spawn_captures_var` |
| `T0001` | type error (argument, branch or return of another type) | compiler | `T0001_type_error` |
| `T0300` | tensor shapes that do not agree | compiler | `T0300_tensor_shape` |
| `T0400` | an impl leaves out a method of its trait | compiler | `T0400_impl_missing_method` |
| `T0401` | a method called on a type with no impl of it | compiler | `T0401_method_without_impl` |
| `T0402` | an impl method that is not in its trait | compiler | - |
| `T0403` | an impl method whose types differ from the trait | compiler | - |
| `T0500` | a generic let function used at an incompatible type | compiler | `T0500_polymorphic_let_misuse` |
| `T0601` | `if` condition that is not a bool | compiler | `T0601_int_condition` |
| `T0602` | bool returned where int is declared, or the reverse | compiler | `T0602_bool_returned_as_int` |
| `T0603` | argument of another type than its parameter declares | compiler | `T0603_argument_type` |
| `T0604` | `+` (and `and`/`or`) between values of different types: `+` never converts | compiler | `T0604_plus_never_converts` |
| `T0605` | a let annotated with one type given another | compiler | `T0605_let_annotation` |
| `T0606` | branches of `if` / `match` of different types | compiler | `T0606_branch_types` |
| `T0607` | a `requires` / `ensures` / law that is not a bool | compiler | `T0607_clause_not_bool` |
| `T0900` | construct outside the fragment of the chosen target | ltarget | - |
| `T0901` | source outside the kernel fragment for a bare-metal target | ltarget | - |
| `T0902` | the lumec front end rejected the source (its diagnostic follows) | ltarget | - |
| `T0903` | lumec is missing | ltarget | - |
| `T1001` | a constructor no enum declares | compiler | `T1001_unknown_constructor` |
| `T1002` | a match missing a variant, or a constructor with the wrong arity | compiler | `T1002_match_missing_variant` |
| `T1003` | record type not declared, or a field it does not have | analyser | `T1003_unknown_record_field` |
| `T2001` | argument type differs from the parameter (money currencies included) | analyser | `T2001_money_currency` |
| `T2002` | a function returns another type than it declares | analyser | `T2002_return_type` |
| `T2101` | a field read that the record does not have | compiler | `T2101_missing_field` |
| `T3001` | a `comptime T: type` parameter given a value (warning) | analyser | `T3001_comptime_needs_type` |
| `V0001` | a contract refuted, with a counterexample | prove | `V0001_contract_refuted` |
| `V0002` | over the `@bound(cycles: N)` budget | analyser | `V0002_wcet_budget` |
| `V0003` | an obligation weaker than in the baseline | lume proof-diff | - |
| `V0004` | cross-module contracts or relational laws that do not compose | analyser | - |
| `V0005` | a temporal law (`always`, `eventually`, `until`, `leads_to`) refuted | prove | `V0005_temporal_law_refuted` |
| `W0001` | a credential literal in the source (`sk-`, `ghp_`, `AKIA`, PEM) | compiler | `W0001_hardcoded_secret` |
| `W0002` | a secret literal found by the protection scan | lume protect | - |
| `W0003` | a program function has the name of an imported one | compiler (warning) | `W0003_duplicate_name` |
| `W0004` | f64 and int mixed in one expression | compiler (warning) | `W0004_f64_int_mix` |
| `W0005` | call to a function marked `## Deprecated:` in another module | compiler (warning) | - |
| `W0064` | a program without the hosted start-up (a kernel image) for Windows | lumec --win64 | - |

## 4. Core builtins (stable)

| Builtin | Answer | On a wrong argument |
| --- | --- | --- |
| `count(s)` | bytes of a string, or elements of a list | stops on a value that has no length |
| `at(s, i)` | the byte at i as a one-byte string | `""` when i is outside |
| `slice(s, a, b)` | bytes a..b-1, clamped to the string | — |
| `ord_at(s, i)` | the byte at i as an int (0..255) | stops when outside |
| `chr(n)` | the one-byte string of n (0..255) | stops outside 0..255 |
| `str(v)` | the text of a value | — |
| `toint(s)` | the integer written in s | `0` when s is not an integer (check the text first) |
| `print v` / `emit(s)` / `flush()` | write to stdout | — |
| `ord(s)` | the first byte of s as an int (0..255); `0` for `""` | stops on a value that is not a string |
| `utf8_chr(n)` | the UTF-8 bytes (1 to 4) of code point n | n <= 0, a surrogate (U+D800..U+DFFF) or n > U+10FFFF: writes `lume: utf8_chr requires a non-zero Unicode scalar <= U+10FFFF` on **stdout** and exits 3 (no call stack, not caught by a try) |
| `slicen(s, x, a, b)` | `slice(s, a, b)`; x is not used (any value) | as `slice` |
| `lidx(v, i)` | `v[i]`: the item i of a list, or the byte i of a string as a one-byte string | stops on an index outside (`list index out of bounds`), a non-int index, or a value that cannot be indexed |
| `printval(v)` | writes the text of v (as `print` does) and a newline to stdout | its answer is not a Lume value: call it only for the effect, never use what it answers |

```lume
print count("héllo")
print slice("abcdef", 1, 4)
print ord_at("A", 0)
print chr(66)
print str(42) + "!"
print toint("123") + 1
print bit_and(12, 10)
print bit_shl(1, 4)
print at("ab", 5) == ""
print toint("abc")
print slice("abc", 2, 9)
print count([1, 2, 3])
```
```output
6
bcd
65
B
42!
124
8
16
1
0
c
3
```

Bit operations (stable; ints are 64-bit two's complement):

| Builtin | Answer |
| --- | --- |
| `bit_and(a, b)` / `bit_or(a, b)` / `bit_xor(a, b)` | the bitwise and / or / exclusive or |
| `bit_not(a)` | the bitwise complement, `-a - 1` |
| `bit_shl(a, k)` | a shifted left k places; the bits that leave the 64-bit word are dropped (no overflow stop) |
| `bit_shr(a, k)` | a shifted right k places, arithmetic (the sign is kept: `bit_shr(-16, 2)` is -4) |

A shift count outside 0..63 stops the program (`lume: shift count outside 0..63`, exit 3); a literal one is
refused when compiling ([C0012]).

Failing and catching (stable): `ctfail(s)` fails with the program's own message s. Outside a try, s is written to
stderr as it is (no newline added, no call stack) and the program exits 3. `__lume_try_begin()` opens a try and
answers 0; when a run-time error or a `ctfail` happens before the matching `__lume_try_end()`, control comes back to
that `__lume_try_begin()` call, which then answers 1, and `__lume_try_msg()` gives the message (`ctfail`'s s as it
is, a runtime error's text with its newline, `""` when nothing failed yet; it is not cleared afterwards).
`__lume_try_end()` closes the innermost try and answers 0 (also with no try open). At most 16 tries can be open at
once; a 17th stops the program. `lume test` runs every test inside such a try.

```lume
fn risky(x) = if x > 3 then ctfail("too big") else x * 2
fn guarded(x) = if __lume_try_begin() == 0 then (let r = risky(x) in let e = __lume_try_end() in str(r)) else "failed: " + __lume_try_msg()
print guarded(2)
print guarded(5)
print ord("A")
print utf8_chr(233)
print lidx([10, 20, 30], 1)
print bit_not(5)
print bit_shr(0 - 16, 2)
```
```output
4
failed: too big
65
é
20
-6
-4
```

## 5. Byte buffers (stable)

`buf_new(n)` (n bytes, all zero), `buf_len(b)`, `buf_get(b, i)` (0..255), `buf_set(b, i, v)` (answers b),
`buf_copy(dst, d_off, src, s_off, n)` (src a buffer or a string: a frame that arrives as a string goes into an
existing buffer without a new one), `buf_slice(b, off, n)`, `buf_from_str(s)`, `buf_to_str(b, off, n)`,
`buf_addr(b)` (the address of byte 0, for system calls). An index outside the buffer or a value outside
0..255 stops the program. `buf_shared(n)` is a buffer in memory shared with the processes `os_fork` starts
afterwards (what one writes, all read). With `use par`: `par_pool(n, fn(k, job) => ...)` starts n worker processes
once, `par_run(pool, job)` runs the function in all of them at the same time and answers the sum of their answers
(their writes into shared buffers are then visible), `par_slice(k, n, total)` is worker k's first item, `par_queue()` /
`par_reset(q)` / `par_take(q)` hand out item numbers one at a time to whichever worker asks (faster cores take more),
`par_close(pool)`
stops them.

```lume
let b = buf_new(4)
let s = buf_set(b, 0, 255)
print buf_len(b)
print buf_get(b, 0)
print buf_get(b, 1)
```
```output
4
255
0
```

Video and codec builtins (stable; arguments are buffers, byte offsets and strides; each answers -1 on a wrong
argument): `buf_bgra_to_i420`, `buf_i420_to_bgra`, `buf_bgra_to_i420_rows(src, stride, w, h, dst, r0, r1)` (only the
rows r0 .. r1 - 1, r0 even, written where the whole conversion puts them: each worker of a pool converts its own band
into one shared I420 buffer), `buf_sad16x16 / buf_sad8x8 / buf_sad4x4 (a, ai, sa, b, bi, sb)` and
`buf_satd4x4 / buf_satd16x16 (same)` (SSE2), `buf_h264_fdct4x4 / buf_h264_idct4x4 (src, si, dst, di)` (int16 blocks),
`buf_h264_quant4x4 (src, si, qp, intra, dst, di)` (answers the nonzero levels), `buf_h264_dequant4x4 (src, si, qp,
dst, di)`, `buf_h264_sub4x4 (a, ai, sa, pred, pi, dst)`, `buf_h264_recon4x4 (pred, pi, res, ri, dst, di)`,
`buf_h264_intra4x4 / buf_h264_intra16x16 (frame, fi, fs, mode, avail, dst)` (avail bits: 1 left, 2 top, 4 top-right,
8 top-left). With `use h264`: `buf_h264_cavlc4x4 (coef, ci, nc, maxc, out, pos)` codes one block of maxc
(16, 15 or 4) int16 coefficients in zigzag order with CAVLC (nC -1: chroma DC) into out from bit pos and answers
{pos, total} (the new bit position, -1 on a wrong argument or a full buffer, and TotalCoeff). The stream is written
in order: the bits after the new position in its last byte are 0 (with 1344 bits or more left the block is coded
without a check per code, ~140 ns for a block of 5 levels).
`buf_h264_mb_i4 (src, si, ss, rec, ri, cfg)` encodes a whole Intra4x4 macroblock in one call: for each of its 16
blocks (luma4x4BlkIdx order) the 9 predictions its neighbours allow, cost SATD + lambda x (1 for the predicted mode,
else 4), the cheapest is transformed, quantized and reconstructed into rec. cfg (at least 592 bytes, int32 little
endian) gives rs, qp, lambda, the macroblock neighbours (1 left, 2 top, 4 top-right, 8 top-left; + 65536: fast mode
decision, vertical / horizontal / DC and then only the diagonal modes next to the winner, ~20% faster) and the neighbour
modes (bytes 16..23, 255 = none); it returns the modes (32..47), nonzero levels (48..63), the zigzag levels ready
for CAVLC (64 + 32 x block) and the mode codes (576..591, 255 = predicted). Answers the total cost or -1. Same
result as the block builtins; a 1080p luma frame takes about 120 ms (screen content) to 230 ms (textured).
`buf_h264_mb_p (src, si, ss, ref, rec, cfg)` codes a whole inter 16x16 macroblock with one motion vector: the
quarter-sample prediction from ref (as `buf_h264_luma_mc`, into cfg bytes 640..895), then each 4x4 block is
subtracted, transformed, quantized with the inter rounding and reconstructed into rec (ref and rec: luma plane at
offset 0, rows rs apart). cfg (at least 896 bytes, int32): rs, qp, picture width and height, macroblock x and y,
mvx and mvy (quarter samples, signed); out the nonzero levels per block (32..47), zigzag levels (64 + 32 x block)
and the luma coded_block_pattern (int32 at 576). Answers the total of nonzero levels (0: a P_Skip candidate) or
-1. Same result as `buf_h264_luma_mc` plus the block builtins; about 8 us per macroblock.
`buf_h264_mb_pc (src, si, ss, ref, rec, cfg)` codes one chroma plane (8x8) of an inter macroblock with the luma
vector: eighth-sample prediction (as `buf_h264_chroma_mc`, into cfg 256..319), the 4 blocks transformed, the DC
coefficients through the 2x2 Hadamard and the chroma DC quantization, the AC through the 4x4 one, and the
reconstruction into rec; qPc from QPY + chroma_qp_index_offset (table 8-15). cfg (512 bytes): rs, QPY, offset,
plane width, height, block x, y, mvx, mvy; out AC counts (40..43), DC count (44), the 4 DC levels (48..55), the
zigzag levels per block (64 + 32 x block, DC slot 0: CAVLC from + 2 with maxc 15) and the plane's cbp part (200:
0, 1 DC, 2 AC). About 4 us per plane and macroblock.
`buf_h264_me16 (src, si, ss, ref, cfg)` finds the vector of a 16x16 macroblock: (0, 0) and the predicted vector,
a small diamond on SAD + lambda x vector bits within the range, then (level 1 / 2) the 8 half and quarter
neighbours on SATD of the interpolated prediction. cfg (1088 bytes): rs, width, height, macroblock x, y, predicted
pmx, pmy (quarter samples), range, lambda, level; out mvx, mvy (40, 44), the cost (48) and the prediction for the
vector (640..895). About 1 us per macroblock at whole samples when the predicted vector is right, 2 us with quarter.
`buf_h264_mb_i16 (src, si, ss, rec, ri, cfg)` codes a whole Intra16x16 macroblock: the mode (vertical, horizontal,
DC, plane, as the neighbours allow) of least SATD, then unless the decide-only flag is set the 16 blocks are
transformed, their DC coefficients go through the 4x4 Hadamard and the luma DC quantization, the AC through the 4x4
one, and the decoding of 8.5.10 is written to rec. cfg (896 bytes): rs, qp, flags (1 = decide only: answers the cost
and leaves rec alone, to compare with `buf_h264_mb_i4` first), neighbours (1 left, 2 top, 8 top-left); out the mode
(16), DC count (20), the 16 DC levels in zigzag order (24..55), AC counts per block (64..79), zigzag levels per
block (96 + 32 x block, CAVLC from + 2, maxc 15), cbp (608: 0 or 15) and the prediction (640..895). Answers the SATD.
`buf_h264_mb_ic (srcu, srcv, recu, recv, cfg)` codes the intra chroma of a macroblock: the intra_chroma_pred_mode
(0 DC with the per-block rules of 8.3.4, 1 horizontal, 2 vertical, 3 plane) of least SATD over Cb and Cr together,
then both planes as `buf_h264_mb_pc` does but with the intra rounding (unless decide only). cfg (1344 bytes): rs,
ss, QPY, chroma offset, si, ri (both planes), neighbours (1 left, 2 top, 8 top-left), flags (1 decide only); out
the mode (32) and cost (36), Cb outputs at 512 + the offsets of `buf_h264_mb_pc` (prediction 768..831), Cr at 1024 +
the same (prediction 1280..1343). Answers the cost.
`buf_h264_cavlc_luma (lev, ctx, out, pos)` / `buf_h264_cavlc_chroma (lev, ctx, out, pos)` write the residual of a
whole macroblock with CAVLC, from the levels as the macroblock builtins leave them: nC of each block from 9.2.1
(inside the macroblock from the blocks already written, at the edges from the neighbour macroblocks' TotalCoeff in
ctx, 255 = not available), the order and the coded_block_pattern of 7.3.5.3. Luma ctx (64 bytes): mode (0: 16 blocks
of 16, 1: Intra16x16 DC then 15 AC per block), cbp (4), offset of block 0 (8), offset of the DC (12), left (16..19)
and top (20..23) TotalCoeff; out each block's TotalCoeff (32..47). Chroma ctx: cbp (0..2), Cb and Cr output bases
(4, 8), left (16..19: Cb 2, Cr 2) and top (20..23) TotalCoeff; out the AC TotalCoeff (32..39). Answer the new bit
position or -1.
`buf_h264_deblock_mb (y, u, v, cfg)` deblocks a whole macroblock in place (8.7, 4:2:0 frame macroblocks), as a
decoder does once it and everything before it in raster order are reconstructed: luma vertical edges left to right,
horizontal edges top to bottom, then Cb and Cr. bS per 4-sample segment (8.7.2.1): 4 on a macroblock edge with an
intra macroblock on either side, 3 inside an intra macroblock, 2 when the 4x4 block of p0 or q0 has coefficients, 1
when their reference pictures differ or a vector component differs by 4 quarter samples or more, else 0; the chroma
edges use the bS of luma edges 0 and 2. alpha / beta / tC0 from tables 8-16 / 8-17 with indexA / indexB = qPav +
FilterOffsetA / B (qPav: QPY inside, the rounded mean of both macroblocks on the left / top edge; chroma the same with
QPc of table 8-15). Edges on the picture border are skipped, slice borders too with disable_deblocking_filter_idc 2,
everything with idc 1. y, u, v hold the three planes. cfg (at least 400 bytes, int32 little endian): luma offset of
the picture (0), luma stride (4), Cb offset (8), Cr offset (12), chroma stride (16), mbx (20), mby (24), width (28)
and height (32) in macroblocks, idc (36), FilterOffsetA (40) and FilterOffsetB (44) (signed: slice_alpha_c0 /
beta_offset_div2 x 2), chroma_qp_index_offset (48, signed), flags (52: 1 the left, 2 the top macroblock is in another
slice); then 112 bytes for this macroblock (64), the left one (176) and the top one (288): intra (int32, nonzero =
intra), QPY (int32 at 4), coefficient flags (bytes 8..23), reference picture identities (bytes 24..39, e.g. ref_idx
in a P slice), motion vectors (int16 mvx, mvy at 40 + 4 x block, quarter samples), all per 4x4 block in
luma4x4BlkIdx order (the order of `buf_h264_mb_p`'s block counts). Answers 0, or -1 on a wrong argument. Every edge
runs in SSE2 (16 lines at once, the strong filter too); about 1.7 us per macroblock on 1080p content, inter or intra
(h264_dbkmb_ok.src checks it against the standard's procedure written in ordinary Lume).

Packed forms behind `use h264` (stable; at most six arguments each, so the module packs its integers; a program can
call them directly; each answers -1 on a wrong argument): `buf_h264_lmc6(ref, dst, a, b, g, q)` /
`buf_h264_cmc6(ref, dst, a, b, g, q)` are the luma (quarter-sample) / chroma (eighth-sample) motion compensation with
a = ri x 65536 + rs, b = di x 65536 + ds, g = rw + rh x 2^16 + w x 2^32 + h x 2^40 and q = (qx + 2^29) + (qy + 2^29) x
2^30 (qx, qy: the position in quarter or eighth samples); 0 on success. `buf_h264_dbk5(buf, q0, a, b, cp)` filters one
edge: a = across + 2^24 + (along + 2^24) x 2^25, b = lines + 256 (chroma) + alpha x 65536 + beta x 2^24, cp the bS
(4 bits per segment, at bit 4k) and tC0 (8 bits per segment, at bit 16 + 8k) values; 0 on success.
`buf_h264_cavlc6(coef, ci, nc, maxc, out, pos)` codes one block as the module's CAVLC function does and answers
pos x 32 + total (the new bit position and TotalCoeff), or -1.

Bit writing (stable; most significant bit first): `buf_bits_write(b, pos, v, n)` writes the low n bits of v (1..32)
at bit pos and answers pos + n, `buf_bits_read(b, pos, n)` answers them, `buf_bits_ue(b, pos, v)` / `buf_bits_se(b,
pos, v)` write Exp-Golomb codes and answer the new pos; each answers -1 on a wrong argument.

## 5a. Floating point (stable)

`f64` is an IEEE 754 double: `f64(x)` makes one from an int, a decimal, another f64 or text (`f64("1e-9")`,
`f64("inf")`, `f64("nan")`); `+ - * /` and `< > <= >=` work on it (an int or decimal operand is converted), `==`
compares by value. `print` / `str` give the shortest text that reads back to the same double. Functions:
`f64_sqrt`, `f64_abs`, `f64_floor`, `f64_ceil`, `f64_round` (half away from zero), `f64_int` (toward zero, to an
int), `f64_sin`, `f64_cos`, `f64_tan`, `f64_atan2(y, x)`, `f64_exp`, `f64_log`, `f64_log10`, `f64_pow(x, y)`,
`f64_is_nan`, `f64_str(x, decimals)`, `f64_bits` / `f64_from_bits`. A literal with a point (`1.5`) is an exact
decimal, not an f64: write `f64(1.5)` or `f64("1.5")`. A comparison with NaN stops the program (test with
`f64_is_nan`). A parameter declared `x: f64` converts what it receives with `f64(x)` on entry, so a decimal literal
works there: `fn hyp(a: f64, b: f64) -> f64 = sqrt(a * a + b * b)` and `hyp(3.0, 4.0)`. `use math` gives `sqrt exp log
log10 pow sin cos tan atan2 floor ceil round abs_f fmin fmax tofloat is_nan is_inf`, `f32(x)` (nearest single
precision, ties to even) and `buf_f32_get(b, off)` / `buf_f32_set(b, off, x)` (4 bytes, little endian). `lume check`
warns [W0004] where an int meets an f64 (it is converted at run time); `lume prove` marks a contract over f64
`runtime_checked` with the reason (the integer prover does not decide floating point).

```lume
fn hypot(a, b) = f64_sqrt(a * a + b * b)
print hypot(f64(3), f64(4))
print hypot(f64(3), f64(4)) == f64(5)
print f64(1) / f64(3)
print f64_str(f64("2.5"), 2)
print f64_is_nan(f64("nan"))
print f64_int(f64_floor(f64("-2.5")))
print f64_pow(f64(2), f64(10))
```
```output
5.0
1
0.3333333333333333
2.50
1
-3
1024.0
```

## 5b. Bit vectors, constant time and SIMD

Byte-sized bit vectors (stable; the byte arithmetic `lume certify` models; any int argument):

| Builtin | Answer |
| --- | --- |
| `bv_u8(a)` | `a` masked to 8 bits (0..255; `bv_u8(-1)` is 255) |
| `bv_not_u8(a)` | the complement of the low 8 bits (0..255) |
| `bv_add_u8(a, b)` / `bv_sub_u8(a, b)` / `bv_mul_u8(a, b)` | the sum / difference / product modulo 256 (0..255) |
| `bv_and(a, b)` / `bv_or(a, b)` / `bv_xor(a, b)` | as `bit_and` / `bit_or` / `bit_xor` (64 bits, not masked) |
| `bv_shl(a, k)` / `bv_shr(a, k)` | as `bit_shl` / `bit_shr` (64 bits, the same 0..63 count check) |

Constant time (stable): `ct_eq(a, b)` answers 1 when a == b, else 0, and `ct_select(m, a, b)` answers, bit by bit,
the bit of a where m has a 1 and the bit of b where m has a 0 (`ct_select(-1, a, b)` is a, `ct_select(0, a, b)` is b);
both are computed without a branch on their arguments. Inside a constant-time kernel (`@secret` and `@no_alloc`) they,
`bit_*` and `bv_and` / `bv_or` / `bv_xor` / `bv_shl` / `bv_shr` lower to straight-line code (shift counts must be
literals: 0..62 for `bit_shr`, 0..61 for `bit_shl`); anything else there is [C0011].

SIMD probes (experimental; AVX2 instructions, so on a processor without AVX2 the program faults with an illegal instruction):
`simd_add4_i64(a, b)` puts a and b in all four 64-bit lanes of two vectors, adds them lane by lane and answers the
sum of the four lanes, `4 * (a + b)`, wrapping at 64 bits (`simd_add4_i64(9223372036854775807, 0)` is -4);
`simd_sub4_i64(a, b)` answers `4 * (a - b)` the same way; `simd_xor4_i64(a, b)` answers `bit_xor(a, b)` (lane 0).

```lume
print ct_eq(5, 5)
print ct_select(12, 10, 5)
print bv_add_u8(200, 100)
print bv_u8(0 - 1)
print simd_add4_i64(1, 2)
```
```output
1
9
44
255
12
```

## 6. Files and the operating system (stable)

| Builtin | Answer |
| --- | --- |
| `fs_read_file(p)` | the content, `""` when it cannot be read |
| `fs_write_sync(p, s)` / `fs_append_sync(p, s)` | 1, or 0 on failure |
| `fs_path_exists(p)` / `fs_remove(p)` / `fs_mkdir(p)` / `fs_copy(a, b)` | 1, or 0 |
| `os_getenv(name)` | the value, `""` when unset |
| `os_platform()` | `"linux"` or `"windows"` |
| `os_arg_count()` / `os_arg_at(i)` | the program's arguments |
| `os_monotonic_ns()` | a monotonic clock in nanoseconds |
| `os_exit(code)` | ends the program |

```lume
print fs_write_sync("ref_probe.txt", "hi")
print fs_read_file("ref_probe.txt")
print fs_remove("ref_probe.txt")
print fs_path_exists("ref_probe.txt")
print fs_read_file("no_such_file.txt") == ""
print os_getenv("LUME_SURELY_UNSET_VAR") == ""
```
```output
1
hi
1
0
1
1
```

Directories, ranges, renames and modes (stable unless the row says otherwise; a path is relative to the current
directory; on Windows `/` and `\` both separate, and the answer is the same as on Linux unless the row says so):

| Builtin | Answer | Platforms |
| --- | --- | --- |
| `fs_current_dir()` | the absolute current directory, `""` when it cannot be read | stable; Windows writes it as `/c/Users/...` (drive letter as the first component, `/` separators) |
| `fs_chdir(p)` | 1, or 0 (no such directory); later relative paths and the programs started afterwards use the new directory | stable |
| `fs_read_dir(p)` | the names in the directory, each followed by `"\n"` (files, subdirectories and hidden names; never `.` / `..`), `""` for an empty directory, a missing path or a file | stable; order: Linux the file system's own (not sorted), Windows the NTFS order (sorted) |
| `fs_rmdir(p)` | 1, or 0 (missing, not empty, or a file) | stable |
| `fs_read_byte(p, off)` | the byte at offset off (0..255), -1 when off is negative or past the end, or the file cannot be read (a directory too) | stable |
| `fs_read_range(p, off, n)` | up to n bytes from off without reading the whole file; shorter at the end of the file; `""` past the end, for n <= 0, a negative off or an unreadable file | stable |
| `fs_files_equal(a, b)` | 1 when both files hold the same bytes, 0 when they differ (length included), -1 when one cannot be opened or read (a directory too) | stable |
| `fs_truncate(p, size)` | 1 after cutting the file to size bytes (a larger size extends it with zero bytes), 0 when size < 0 or the file does not exist (it is not created) | stable |
| `fs_rename(a, b)` | 1, or 0 (a missing, or across volumes); an existing b is replaced | stable |
| `fs_rename_noreplace(a, b)` | as `fs_rename`, but 0 when b already exists (atomic; Linux file systems without the no-replace flag use link + unlink, which refuses the same way) | stable |
| `fs_write_hex_file(p, hex)` | writes the bytes the hex text spells (`0-9 a-f A-F`, an even count; `""` makes an empty file), synced to disk: 1, or 0 for an odd count or a bad digit (the file is then not created) or a failed write | stable |
| `fs_mode(p)` | the permission bits (0..4095, e.g. 420 = 0644, 493 = 0755), -1 when the path cannot be read | stable; Windows derives them: 493 for a directory, 420 for a file, 448 / 384 when only the owner can reach it, the read-only attribute removes the write bits (a file never shows execute bits) |
| `fs_chmod(p, mode)` | 1, or 0 for a mode outside 0..4095 or a missing path | stable; Windows: the owner write bit is the read-only attribute, a mode without group and other bits makes the DACL owner-only, one with them restores the inherited entries; execute bits have no meaning |
| `fs_make_executable(p)` | `fs_chmod(p, 493)`: 1, or 0 | stable; on Windows the extension decides what runs, so it only drops owner-only protection (`fs_mode` then answers 420) |

Owner-only files (stable; for secrets: Linux mode 0600 / 0700 owned by this user, Windows a protected DACL that
grants the running user alone):

| Builtin | Answer |
| --- | --- |
| `fs_create_private(p, s)` | creates p with the string s, owner-only, synced to disk: 1, or 0 when p already exists or cannot be written (a half-written file is removed) |
| `fs_write_private(p, s)` | replaces p atomically with an owner-only file holding s (written to `p.~` + 16 hex digits of the process id beside it, then renamed): 1, or 0 |
| `fs_mkdir_private(p)` | an owner-only directory (0700); an existing directory is set to 0700: 1, or 0 (a file, or a missing parent) |
| `fs_is_private(p)` | 1 when this user owns p and nobody else is granted anything, 0 when not, -1 when p cannot be read |

OS keychain: `os_keychain_put(name, secret)` stores secret (up to 2560 bytes) under name and answers 1, else a
negative error; `os_keychain_get(name)` answers `"+"` followed by the secret (so an empty secret is `"+"`), `""` only
when there is no such entry, and `"-"` followed by the error number for any other failure (a locked or refused store
is never read as an absent secret); `os_keychain_delete(name)` answers 1 when removed, 0 when there was no such entry,
else a negative error; `os_keychain_available()` is 1 when the store can be used. **windows**: the Credential Manager
(a generic credential that persists for this user on this machine); a Win32 failure e is -(100000 + e) (an empty name
gives -100087) and a secret over 2560 bytes -22. On Linux there is no OS keychain: `os_keychain_available()` is 0,
put and delete answer -38 and get `"-38"`; `use keychain` falls back to owner-only files there.

Standard input (stable): `read()` is one line without its `"\n"` (a `"\r"` before it is kept), read a byte at a time
so nothing after the line is consumed, `""` at the end of input (also for an empty line: test the end with
`io_read_byte()` or `readall()`); `readall()` is all of the remaining input, `""` when none; `io_read_byte()` is the
next byte (0..255), -1 at the end of input. All three block while the input is a terminal or pipe with nothing yet.

```lume
print fs_write_hex_file("ref_a_hex.bin", "48690a")
print fs_read_range("ref_a_hex.bin", 0, 2)
print fs_read_byte("ref_a_hex.bin", 2)
print fs_truncate("ref_a_hex.bin", 1)
print fs_read_file("ref_a_hex.bin")
print fs_rename_noreplace("ref_a_hex.bin", "ref_a_hex2.bin")
print fs_files_equal("ref_a_hex2.bin", "ref_a_missing.bin")
print fs_remove("ref_a_hex2.bin")
```
```output
1
Hi
10
1
H
1
-1
1
```

```lume
print fs_mkdir("ref_a_dir")
print fs_write_sync("ref_a_dir/one.txt", "1")
print fs_read_dir("ref_a_dir")
print fs_rmdir("ref_a_dir")
print fs_remove("ref_a_dir/one.txt")
print fs_rmdir("ref_a_dir")
```
```output
1
1
one.txt

0
1
1
```

### Environment and system information (stable)

| Builtin | Answer | Platforms |
| --- | --- | --- |
| `os_cpu_count()` | the processors this process may run on (the CPU affinity mask on Linux, NUMBER_OF_PROCESSORS on Windows), at least 1 | stable |
| `os_fd_write(fd, s)` | writes the bytes of string `s` to file descriptor `fd` (2 is standard error, 1 standard output), after flushing buffered output so it stays ordered; returns the byte count. A short write continues, `EINTR` retries, any other failure ends the program with exit 3 | stable |
| `os_env_has(name)` | 1 when the variable is set (also to `""`), else 0; 0 for `""` | stable; Windows compares names without regard to ASCII case |
| `os_setenv(name, value)` | 1; 0 when name is `""` or holds `=` (or memory cannot be mapped). The new table is this process's environment from then on (`os_getenv`, `os_env_has`) and every child started afterwards inherits it | stable; see the note on case below |
| `os_unsetenv(name)` | 1, also when the variable was not set; 0 when name is `""` or holds `=` | stable |
| `os_unix_time()` | seconds since 1970-01-01 UTC (the real-time clock), 0 when the clock cannot be read | stable |
| `os_uname_field(i)` | 0 system (`"Linux"`, `"Windows_NT"`), 1 host name, 2 release (the kernel release; `"10.0.26200"` style on Windows), 3 version (the kernel build text on Linux, `""` on Windows), 4 machine (`"x86_64"`); `""` for i outside 0..4 | stable |
| `os_getpid()` | this process's id | stable |
| `os_self_maxrss_kb()` | the peak resident memory of this process so far, in KiB (getrusage on Linux, the peak working set on Windows) | stable |
| `os_dns_servers()` | one line `nameserver ADDR` per DNS server of every network adapter that is up (an adapter's IPv6 servers keep their `%scope`; a server listed by two adapters appears twice); `""` when none | windows; on Linux it always answers `""` (read `/etc/resolv.conf`, as `use dns` does) |

Names compare exactly on Linux. On Windows `os_getenv` / `os_env_has` find a name in any ASCII case (`Path` is
`PATH`), but `os_setenv` and `os_unsetenv` replace or remove only an entry written in the same case: after
`os_setenv("LUME_X", "a")`, `os_setenv("lume_x", "b")` adds a second entry and `os_getenv("LUME_X")` still answers
`"a"`; use one spelling. All of these are for hosted programs; an `@freestanding` kernel image has none of them.

### Processes (stable)

A child's **status** is the raw wait status: exit code x 256 for a normal exit (`os_exit(7)` gives 1792), the signal
number for a child that a signal ended (9 after `os_kill(pid, 9)`, 15 after `os_kill(pid, 15)`), or -errno when there
is nothing to wait for (-10, ECHILD). A child that cannot start (no such program, an output file that cannot be
created) exits with 127: status 32512. Launchers take `path` (run as given: there is no PATH search; on Windows a
missing `.exe` is added) and `args`, a list of strings that become argv 1, 2, ... (argv 0 is path; at most 39
arguments, extra ones and anything after a non-string element are dropped; an empty string is passed as an empty
argument). The child inherits the environment as `os_setenv` left it, and stdin unless stated.

| Builtin | Answer | Platforms |
| --- | --- | --- |
| `os_fork()` | 0 in the child, the child's id in the parent, -errno on failure. The child is a copy of the process (Windows: the layer copies the address space, the child continues at the same point); `buf_shared` buffers stay shared | stable |
| `os_exec(path, args)` | replaces the process with the program and does not return; on failure answers -errno (-2: no such file) and the process goes on | stable |
| `os_run(path, args)` | runs the program with this process's stdin, stdout and stderr, waits, answers its status (-errno when no child can be created) | stable |
| `os_run_capture(path, args, out, err)` | as `os_run`, with stdout written to file out and stderr to file err (each created or truncated, mode 0644; the same path for both gives one file with both streams) | stable |
| `os_run_capture_timeout(path, args, out, err, ms)` | as `os_run_capture`, but after ms milliseconds the child and its whole process group (it gets its own; on Windows a job) are killed: status 9 and `os_last_timed_out()` 1 | stable |
| `os_run_input_capture_timeout(path, args, inp, out, err, ms)` | as `os_run_capture_timeout`, with stdin read from file inp (a missing inp: status 32512) | stable |
| `os_spawn_capture(path, args, out, err)` | starts the program as `os_run_capture` does and answers its id at once, without waiting (-errno on failure); reap it with `os_waitpid_status` | stable |
| `os_waitpid(pid)` | waits for that child, answers pid (its status is not kept), or -errno (-10 when it is not a child or was already reaped) | stable |
| `os_waitpid_status(pid)` | waits for that child, answers its status, or -errno | stable |
| `os_kill(pid, sig)` | sends the signal: 0, or -errno (-3, ESRCH: no such process). Signal 0 only checks that the process exists | stable; Windows ends a child of this process (any nonzero sig, reported by the wait as that signal) or this process itself |
| `os_sleep_ms(ms)` | sleeps ms milliseconds, answers 1 (`0` returns at once) | stable; a negative ms sleeps practically for ever on Linux and returns at once on Windows |
| `os_last_timed_out()` | 1 when the last `os_run_capture_timeout` / `os_run_input_capture_timeout` killed its child, 0 when it ended in time; the other launchers leave it unchanged | stable; read it right after the call (see the note below) |
| `os_last_child_maxrss_kb()` | the peak resident memory, in KiB, of the last child waited for by `os_run*`, `os_waitpid_status` (0 before any) | stable; Linux reports 0 for a small child (a Lume program measured 0, a 50 MB Python child 58468); Windows reports the child's peak working set |

Pipes and shared memory (stable): `os_pipe_new()` creates a pipe and answers `rfd * 10000 + wfd` (read end
`p / 10000`, write end `p % 10000`; both ends are inherited by `os_fork` children, and on Windows by the programs
they exec). `os_pipe_write_int(fd, n)` writes n as 8 bytes and answers 1 (also when the write fails).
`os_pipe_read_int(fd)` reads 8 bytes (one read, blocking until data arrives) and answers the integer; at end of file or on an error it answers
whatever the runtime's 8-byte slot held, so send a count or a sentinel first. `os_shm_map(n)` maps n bytes of
read/write memory shared with every child `os_fork` starts afterwards and answers its address (-22 for n = 0,
-errno on failure); the address is for `--raw` code and system calls, `buf_shared(n)` is the same memory as a buffer.
Not in `@freestanding` kernel images.

io_uring (experimental): `os_io_uring_setup(entries, flags)` answers a ring descriptor or -errno (-22 for 0 entries;
-38 or -1 where the kernel disables io_uring); `os_io_uring_enter(fd, submit, wait)` submits up to submit entries
and, when wait > 0, waits for that many completions; answers the number submitted or -errno (-9: not a ring);
`os_io_uring_register(fd, opcode, nargs)` passes a null argument and answers what the kernel answers (-14 for
opcode 0). No builtin maps the rings, so a Lume program can create, enter and close a ring (`net_close(fd)`) but
not fill its queues: these are for probing the kernel. Linux: the real system calls; Windows: an emulation that
validates setup (1..32768 entries) and answers like Linux 6.18, where enter submits nothing and, asked to wait,
blocks for ever.

The runtime keeps the last wait status, `os_last_timed_out()` and the pipe integers in the 32-byte scratch area
that `print` uses to write numbers: printing an integer of 9 or more digits, or calling `os_pipe_new()`, between a
timed launch and `os_last_timed_out()` changes what it answers. Name the answer with `let` right after the call.

```lume
print os_setenv("LUME_REF_VAR", "on")
print os_getenv("LUME_REF_VAR")
print os_env_has("LUME_REF_VAR")
print os_unsetenv("LUME_REF_VAR")
print os_env_has("LUME_REF_VAR")
let pid = os_fork()
let w = if pid == 0 then os_exit(7) else 0
print os_waitpid_status(pid)
print os_run("/no/such/tool", Nil)
```
```output
1
on
1
1
0
1792
32512
```

```lume
let p = os_pipe_new()
let pid = os_fork()
let w = if pid == 0 then os_exit(os_pipe_write_int(p % 10000, 42)) else 0
print os_pipe_read_int(p / 10000)
print os_waitpid_status(pid)
```
```output
42
256
```

Network (stable): `net_udp_bind_addr(ip, port)` (a socket, -1 on failure), `net_udp_send_to(fd, ip, port, data)`
(bytes sent), `net_udp_recv_from(fd, max)` (the datagram, `""` when none), `net_last_peer_ip()`,
`net_last_peer_port()`, `net_tcp_connect_addr(ip, port)` (a socket, -1 when refused), `net_close(fd)`;
`use netctl` adds timeouts and non-blocking I/O with epoll.

Loopback sockets and epoll (stable; hosted programs on Linux and Windows, where the Win64 layer gives Winsock
sockets the same numbers and answers; effect `net`, epoll `io`). The forms that take only a port work on 127.0.0.1;
a port is used modulo 65536, it is not checked. A failure answers a negative number: -1 where noted, else the
negated system error (`-9` a closed descriptor, `-17` an fd already watched).

| Builtin | Answer |
| --- | --- |
| `net_tcp_listen(port)` | a TCP socket listening on 127.0.0.1:port (address reuse on, backlog 8), or -1 (the port is taken) |
| `net_tcp_listen_addr(ip, port)` | the same on the IPv4 (`"0.0.0.0"`, `"127.0.0.1"`) or IPv6 (`"::1"`) address ip, backlog 128; -1 on a malformed address, a port outside 0..65535 or a failed bind (the socket is closed) |
| `net_tcp_connect(port)` | a TCP socket connected to 127.0.0.1:port, or -1 when refused |
| `net_tcp_accept(fd)` | the socket of the next connection on the listening fd (waits for one), or a negative error (Linux `-9` on a closed fd, Windows `-88`) |
| `net_send_str(fd, s)` | writes the bytes of s; answers the count written, or a negative error (`-9` closed) |
| `net_recv_str(fd, max)` | one read of at most 4095 bytes (max is not used: every call reads up to 4095); `""` at end of stream or on an error |
| `net_shutdown_write(fd)` | ends the sending direction (the peer reads end of stream); always answers 1 |
| `net_udp_bind(port)` | a UDP socket bound to 127.0.0.1:port, or -1; a second bind to a port in use succeeds on Linux (address reuse) and answers -1 on Windows |
| `net_udp_sendto(port, s)` | sends s as one datagram to 127.0.0.1:port from a fresh socket it then closes; answers the bytes sent (with no receiver too) |
| `epoll_create_fd()` | a new epoll descriptor (close it with `net_close`), or a negative error |
| `epoll_add_in(ep, fd, data)` | watches fd for input, level-triggered; data (any int) is what `epoll_wait_one` answers for it; 0, or a negative error (`-17` already watched, `-9` a bad fd) |
| `epoll_wait_one(ep, ms)` | waits up to ms milliseconds (-1 = no limit, 0 = poll) and answers the data of one ready fd, 0 on a timeout or an error (so give data other than 0); end of stream counts as ready |

```lume
let l = net_tcp_listen(47540)
let c = net_tcp_connect(47540)
let a = net_tcp_accept(l)
print net_send_str(c, "ping")
let ep = epoll_create_fd()
print epoll_add_in(ep, a, 7)
print epoll_wait_one(ep, 1000)
print net_recv_str(a, 4096)
print net_shutdown_write(c)
print net_recv_str(a, 4096) == ""
print net_close(a) + net_close(c) + net_close(l) + net_close(ep)
print net_tcp_connect(47541)
```
```output
4
0
7
ping
1
1
4
-1
```

Crypto primitives (stable; the bulk routines of `lcrypto_tls`, linked into a program only when it names one of
them; keys, nonces and points are strings of bytes, little endian as in the RFCs). A key of the wrong size, an output
that is not a buffer (`buf_new`) or a range outside the data stops the program with exit 3 and a `lume: crypto: ...`
line; X25519 and Ed25519 fail closed instead.

| Builtin | Answer |
| --- | --- |
| `crypto_x25519(k, u)` | X25519 of RFC 7748 (k clamped, u the 32-byte u-coordinate; constant time): 32 bytes; a k or u that is not 32 bytes gives 32 zero bytes. Public key: u = `chr(9)` + 31 zero bytes |
| `crypto_ed25519_base(s)` | the packed Ed25519 point [s]B of RFC 8032 for the 32-byte little-endian scalar s (constant time): 32 bytes; another size gives 32 zero bytes |
| `crypto_ed25519_vpt(pk, k, s)` | the packed point [s]B + [k](-A), A the point packed in pk (variable time: inputs are public); a signature (R, S) is valid when it equals R. `""` when pk is not a point or an argument is not 32 bytes |
| `crypto_chacha20_xor(out, data, key, nonce, counter)` | ChaCha20 of RFC 8439 (32-byte key, 12-byte nonce, 32-bit block counter): writes data XOR the key stream into bytes 0..count(data)-1 of the buffer out (bytes after them unchanged) and answers out; stops when out is smaller than data |
| `crypto_poly1305(key, msg)` | the 16-byte Poly1305 tag of RFC 8439 for the 32-byte one-time key |
| `crypto_sha256_blocks(state, data, from, to)` | runs the SHA-256 compression (FIPS 180-4) over data bytes from..to-1, a whole number of 64-byte blocks (from = to does nothing), on the state buffer (at least 32 bytes: the eight words H0..H7, each a 32-bit little-endian int) in place, and answers state; padding and the final big-endian digest are the caller's (`lcrypto_tls` does both) |

```lume
fn hd(n) = slice("0123456789abcdef", n, n + 1)
fn hex(s, i) = if i >= count(s) then "" else hd(ord_at(s, i) / 16) + hd(ord_at(s, i) % 16) + hex(s, i + 1)
fn zeros(n) = if n == 0 then "" else chr(0) + zeros(n - 1)
let nine = chr(9) + zeros(31)
print hex(crypto_x25519(nine, nine), 0)
print hex(crypto_ed25519_base(chr(1) + zeros(31)), 0)
print count(crypto_poly1305(zeros(32), "msg"))
let out = crypto_chacha20_xor(buf_new(3), "abc", zeros(32), zeros(12), 0)
print hex(buf_to_str(out, 0, 3), 0)
```
```output
422c8e7a6227d7bca1350b3e2bb7279f7897b87bb6854b783c60e80311ae3079
5866666666666666666666666666666666666666666666666666666666666666
16
17da83
```
Loopback forms and system calls (the same answers on Linux and Windows): `net_tcp_listen(port)`,
`net_tcp_connect(port)`, `net_udp_bind(port)` (127.0.0.1; a socket, or -1 when the port is outside 0..65535 or a
step fails, and then the socket is closed; a UDP port already bound is refused), `net_udp_sendto(port, data)`
(bytes sent, -1 on a bad port or socket), `net_recv_str(fd, max)` (at most `max` bytes, clamped to 1..65536; `""` on
an error or at the end), `net_send_str(fd, data)`, `net_tcp_accept(fd)` (a socket, or minus the Linux errno: -9 for a
descriptor that is not open, -88 for one that is not a socket), `net_shutdown_write(fd)` (1, or -1). `epoll_create_fd()`,
`epoll_add_in(ep, fd, data)` (0 or minus the errno), `epoll_wait_one(ep, ms)` (the `data` of a ready descriptor, -1
when the timeout expires, -2 on an error; give non-negative data). `os_pipe_new()` (`rfd * 10000 + wfd`, or -1 when
pipe fails or a descriptor is 10000 or more), `os_pipe_write_int(wfd, n)` (1, or -1 when the 8 bytes are not
written), `os_pipe_read_int(rfd)` (the int, or -1 at the end of the data or on an error: send -1 only as a stop
mark). `os_sleep_ms(ms)` (1; a negative or zero `ms` returns at once). `os_setenv(name, value)` / `os_unsetenv(name)`
find the old entry as `os_getenv` does: exactly, and on Windows without regard to ASCII case. `printval(v)` prints
`v` and a newline and answers `v`. `utf8_chr(n)` with n <= 0, a surrogate or n > 0x10FFFF is a runtime stop (stderr,
exit 3, catchable). `mem_crc64(addr, len)` is the 64-bit FNV-1a hash (offset basis 14695981039346656037, prime
1099511628211, wrapping) as a signed 64-bit int (a hash of 2^63 or more reads negative). `krn_slot_write(i, v)` /
`krn_slot_read(i)`: a 1024-slot table of its own (`i` modulo 1024; 0 for a slot never written).
`simd_add4_i64(a, b)` / `simd_sub4_i64(a, b)`: four equal 64-bit lanes of `a + b` / `a - b` summed, that is
`4 * (a op b)` modulo 2^64 as a signed int (SSE2, every x86-64 CPU); `simd_xor4_i64(a, b)` is one lane, `a xor b`.
Builtins that need ring 0 (port I/O, MSRs, cli / sti / hlt, CR3, invlpg, the IDT, interrupts,
AP boot, task switch, `vga_*`) are refused in a hosted program with [K0007].

## 7. Standard library modules

| Module | What it gives | Status |
| --- | --- | --- |
| `h264` | `buf_h264_luma_mc(ref, ri, rs, rw, rh, x, y, mx, my, w, h, dst, di, ds)` (quarter-sample 6-tap luma, 8.4.2.2.1), `buf_h264_chroma_mc(...)` (same arguments, eighth-sample bilinear, 8.4.2.2.2), `buf_h264_deblock_edge(buf, q0, across, along, lines, bs, alpha, beta, tc0, chroma)` (8.7.2.3 / 8.7.2.4; bs and tc0 lists, one value per 4 luma / 2 chroma lines); 0, or -1 on a wrong argument; coordinates clamped to the picture | stable |
| `hash` | `crc32`, `adler32`, `md5`, `sha1`, `sha224`, `sha256`, `sha384`, `sha512` (strings; `*_buf` for buffers), `hash_hex` / `hash_raw(name, s)`, `hmac_md5` / `hmac_sha1` / `hmac_sha256` / `hmac_sha384` / `hmac_sha512(key, msg)` and `hmac_hex` / `hmac_raw(name, key, msg)` (RFC 2104), `pbkdf2_sha256` / `pbkdf2_hex` (RFC 8018), `crc32c`, `fnv1a32`, `fnv1a64` (16 hex digits), `hex32`; checked against the FIPS 180-4, RFC 4231 / 2202 / 2104 / 7914 / 6070 vectors | stable |
| `encoding` | `hex_encode` / `hex_decode`, `base64_encode` / `base64_decode` (RFC 4648 section 4, strict padding and trailing bits), `base64url_encode` / `base64url_decode` (section 5, padding optional), `base64_decode_mime` (white space ignored); decoders answer `{ok, bytes}` | experimental |
| `json` | `json_parse(text)` -> `{ok, value, err, pos, line, col}` (strict RFC 8259: number grammar, every escape, `\u` surrogate pairs, lone surrogates and ill-formed UTF-8 refused, depth 512), values `{k, s, items, fields}` (numbers keep their exact text), `json_get` / `json_has` / `json_at` / `json_len` / `json_keys` / `json_pointer` (RFC 6901), `json_str` / `json_int` / `json_f64` / `json_bool` / `json_is_null`, builders `jv_*`, `json_set` / `json_remove` / `json_push`, `json_write` / `json_write_ascii` / `json_pretty` / `json_quote` | experimental |
| `csv` | `csv_parse(text)` (RFC 4180: quotes, separators and line breaks inside fields), `csv_format(rows)`, `csv_parse_sep` / `csv_format_sep`, `csv_parse_checked` / `csv_parse_checked_sep` (strict: `{ok, rows, err, line}` on an unterminated quote or text after a closing quote), `csv_field`, `csv_index` / `csv_get(header, row, name)` | stable |
| `utf8` | `utf8_len`, `utf8_decode` / `utf8_encode` / `utf8_encode_cp`, `utf8_char`, `utf8_cp`, `utf8_slice`, `utf8_offset`, `utf8_next` / `utf8_fold` (walk by code point without a list), `utf8_valid` / `utf8_check` (offset of the first ill-formed byte) / `utf8_sanitize` (U+FFFD), `utf8_to_utf16` / `utf8_from_utf16`, `utf8_upper` / `utf8_lower` (ASCII, Latin-1, Latin Extended-A, Greek, Cyrillic), `utf8_reverse` (strings are bytes; these count characters) | stable |
| `datetime` | `dt_from_unix`, `dt_to_unix`, `dt_iso`, `dt_parse_iso`, `dt_parse` (ISO 8601 / RFC 3339 extended and basic forms, nanoseconds, the written offset), `dt_format(t, off, pattern)` (strftime subset), `dt_weekday`, `dt_yday`, `dt_iso_week`, `dt_add_days` / `dt_add_months`, `dt_offset(zone, t)` / `dt_local` / `dt_iso_local` (fixed offsets, US / EU / Sydney daylight rules) | stable |
| `tz` | `tz_zone(spec)`: a fixed offset, a POSIX TZ rule (`EST5EDT,M3.2.0,M11.1.0`, Jn / n / Mm.w.d dates) or an IANA name read from tzdata; `tz_load(name)` (TZif files, RFC 8536 versions 1-4, the footer rule; `$TZDIR`, `/usr/share/zoneinfo`, ...), `tz_from_tzif(bytes, name)`, `tz_offset`, `tz_abbr`, `tz_is_dst`, `tz_local`, `tz_iso`, `tz_from_local` (gaps and overlaps resolved) | experimental; Windows has no tzdata: `tz_load` needs `TZDIR` there (fixed offsets and POSIX rules work everywhere) |
| `regex` | `re_match`, `re_search`, `re_find`, `re_find_all`, `re_find_all_groups`, `re_groups`, `re_named`, `re_group_names`, `re_replace` (`$1`), `re_split`: classes (ranges across UTF-8 lengths), `\d \w \s`, `\xHH`, anchors, `\b \B`, groups, named groups `(?<n>...)`, backreferences `\1`..`\9`, lookahead `(?=...)` `(?!...)`, alternation, greedy and lazy quantifiers, `(?i)` (ASCII); a backtracking matcher (no lookbehind) | stable |
| `deflate` | `inflate_buf` (refuses what zlib refuses), `deflate_level(b, off, n, level)` (zlib's algorithm and parameters for levels 1-9: hash chains, lazy matching from level 4, a block every 16383 symbols written in the smallest of stored / fixed / dynamic Huffman; 0 = stored), `deflate_buf` (level 6), `zlib_decompress` / `zlib_compress` / `zlib_compress_level`, `gunzip` / `gzip` / `gzip_level`, `gunzip_str` / `gzip_str` (Adler-32 / CRC-32 checked); sizes within 0.1 % of zlib at the same level | stable |
| `zstd` | `zstd_decompress(b, n)` -> `{ok, buf, n, err}` (RFC 8878: every frame, raw / RLE / compressed blocks, Huffman and FSE, repeat offsets, skippable and concatenated frames, content size and XXH64 checksum checked; dictionaries refused), `zstd_compress_level(b, n, level)` / `zstd_compress` (level 3: one frame with the content size and the checksum, raw / RLE / compressed blocks of up to 128 KiB; `zstd -d` reads it), `zstd_decompress_str` / `zstd_compress_str`, `xxh64_buf` / `xxh64` -> `{hi, lo}`, `xxh64_hex` | stable |
| `http` | `http_get`, `http_post`, `http_request(method, url, headers, body, ms)`, `http_header`: chunked, gzip, redirects, deadlines; `https://` through `tls` | stable |
| `tls` | `tls_request(host, port, data, ms)`: TLS 1.3 client (X25519, AES-128-GCM / ChaCha20-Poly1305); the server certificate is checked against the system roots (`SSL_CERT_FILE`, the Linux bundle, the Windows stores through `lchameleon`) and the host name | stable |
| `tlspki`, `bignum` | RSA (PKCS #1 v1.5, PSS), ECDSA P-256 / P-384, SHA-384 / SHA-512, X.509 parsing and chain validation, PEM; integers of any size with Montgomery `bn_modexp` | stable |
| `seq` | `seq_map`, `seq_filter`, `seq_fold`, `seq_loop(a, b, acc, f)` (a loop over a..b-1 without a list), `seq_while`, `seq_nth`, `seq_range`, `seq_concat` | stable |
| `arena` | `heap_stats()`, `gc_collect()`, `gc_count()`, `arena_new / alloc / reset / destroy` | stable |
| `netctl`, `dns` | TCP with timeouts, non-blocking sockets, epoll, DNS | stable |
| `tun` | TUN interfaces: `tun_open`, `tun_read`, `tun_write`, `tun_wait`, `tun_set_ipv4`, `tun_set_mtu`, `tun_set_up`, `tun_close` | linux + windows, privileged; Windows loads Wintun only through `lchameleon` |
| `lchameleon` | foreign boundaries: `chameleon_c_open(path)` (Windows: a signed DLL inside System32 / Program Files), `chameleon_c_sym`, `chameleon_c_call` (answer `unverified[int]`), `chameleon_verify_boundary` | `chameleon_c_*`: windows; guards: stable |
| `winsys` | displays, capture, input, windows, registry, services, sessions, named pipes | windows |
| `lcrypto_tls` | AES-GCM, ECDSA P-256, X25519, Ed25519, SHA-256 | stable |

```lume
use seq
print seq_loop(0, 5, 0, fn(i, acc) => acc + i)
print seq_map([1, 2, 3], fn(x) => x * 10)
print seq_fold([1, 2, 3], 0, fn(acc, x) => acc + x)
```
```output
10
Cons(10, Cons(20, Cons(30, Nil)))
6
```

## 7a. Freestanding and hardware builtins

These builtins are for `@freestanding` kernels (ring 0, booted from the image `lasm` writes) and for low-level
runtime and library code. Every one has the effect `sys`, except `cpu_rdtsc` (`time`) and `hw_scratch_addr`,
`static_arena_addr`, `static_arena_cap` (pure). Integer arguments are machine words; an address is a plain int
(in a hosted program, take it from `buf_addr(b)`).

Where they run: **kernel** = only inside an `@freestanding` kernel; in a hosted program (Linux or Windows) the
instruction is privileged or touches physical memory the process does not have, and the program stops with
`lume: invalid memory access` and exit code 139, the same on both systems. **stable** = also works in a hosted
program, the same on Linux and Windows.

| Builtin | Answer | Where |
| --- | --- | --- |
| `cpu_rdtsc()` | the time-stamp counter (64 bits, `rdtsc`) | stable |
| `cpu_pause()` | 1, after a spin-wait hint (`pause`) | stable |
| `cpu_mfence()` | 1, after a full memory barrier (`mfence`) | stable |
| `cpu_cli()` / `cpu_sti()` | 1, after masking / enabling interrupts | kernel |
| `cpu_hlt()` | 1, after the processor wakes from `hlt` on an interrupt | kernel |
| `cpu_rdmsr(msr)` | the 64-bit model-specific register msr | kernel |
| `cpu_wrmsr(msr, v)` | v, after writing it to msr (high half from v / 2^32) | kernel |
| `cpu_read_cr3()` | CR3 (the page-table root) | kernel |
| `cpu_write_cr3(v)` | v, after loading it into CR3 (flushes the TLB) | kernel |
| `cpu_invlpg(va)` | 1, after dropping the TLB entry of the page at va | kernel |
| `cpu_idt_init()` | 1, after installing interrupt gates 14 (page fault) and 32 (timer) and loading the IDT | kernel |
| `cpu_trigger_irq32()` | the timer tick count, after raising interrupt 32 by software (`int $32`) | kernel |
| `cpu_wait_timer_irq()` | the timer tick count, after `sti; hlt; cli` (waits for one hardware interrupt) | kernel |
| `cpu_irq32_count()` | the timer tick count (0 until interrupt 32 has run) | stable (0 outside a kernel) |
| `cpu_pf14_count()` / `cpu_pf14_addr()` | page faults taken by the vector-14 handler / the last faulting address (CR2) | stable (0 outside a kernel) |
| `cpu_run_2tasks(v)` | 2031 + v: v goes through a spinlocked ring to a second task on its own stack, which adds 31 and switches back (two context switches x 1000 + the answer) | kernel |
| `cpu_smp_boot_ap(v)` | 1012 + 2 x v when CPU 1 starts (INIT + SIPI through the local APIC, a 16-to-64-bit trampoline at 0x7000; the AP computes 2 x v + 12 under a spinlock), 0 when it does not answer in time | kernel (`qemu -smp 2`) |
| `port_in8(port)` / `port_in16(port)` / `port_in32(port)` | the byte / word / dword read from the I/O port | kernel |
| `port_out8(port, v)` / `port_out16(port, v)` / `port_out32(port, v)` | v, after writing its low 8 / 16 / 32 bits to the port | kernel |
| `mmio_volatile_read8(a)` / `mmio_volatile_read16(a)` / `mmio_volatile_read32(a)` / `mmio_volatile_read64(a)` | the 1 / 2 / 4 / 8 bytes at address a, little endian, unsigned except the 64-bit read; an `mfence` comes first | stable |
| `mmio_volatile_write8(a, v)` / `mmio_volatile_write16(a, v)` / `mmio_volatile_write32(a, v)` / `mmio_volatile_write64(a, v)` | v, after storing its low 1 / 2 / 4 / 8 bytes at a, then `mfence`; an address in 32768..262143 (the kernel text) is not written: a literal one is error [K0005] inside a function, a computed one is skipped | stable |
| `mem_set(a, byte, n)` | n, after writing the low 8 bits of byte into n bytes from a (nothing when n <= 0) | stable |
| `mem_copy(dst, src, n)` | n, after copying n bytes forward, one at a time (nothing when n <= 0) | stable |
| `mem_crc64(a, n)` | the 64-bit FNV-1a hash of the n bytes at a, as a signed int (not a CRC) | stable |
| `atomic_xadd64(a, d)` | the old value of the 64-bit word at a, after adding d to it atomically (`lock xadd`) | stable |
| `spinlock_acquire(a)` / `spinlock_release(a)` | 1, after taking (`xchg` loop with `pause`) / freeing (store 0) the lock word at a | stable |
| `krn_slot_write(i, v)` / `krn_slot_read(i)` | v / the value stored in slot i mod 1024 (0 when never written) of a table that needs no heap | stable, see the note |
| `hw_scratch_addr()` | the address of the 8 KiB scratch area behind the slots | stable |
| `static_arena_addr()` / `static_arena_cap()` | the address / the size (65536) of a 64 KiB zeroed static area | stable |
| `vga_puts(row, col, attr, s)` | 1, after writing s with colour attr into the 80x25 text screen at 0xB8000 | kernel |
| `vga_fill_row(row, attr, ch)` | 1, after filling one row with character ch | kernel |
| `vga_scroll_up(top, bottom, attr)` | 1, after moving rows top+1..bottom up one row and blanking row bottom | kernel |
| `vga_set_cursor(row, col)` | 1, after moving the hardware cursor (CRT ports 0x3D4 / 0x3D5) | kernel |
| `sys_call(nr, a1, a2, a3, a4, a5)` | the operating-system call nr with Linux x86-64 numbers (sixth argument 0); the raw answer, -errno on failure (-38 for an unknown number); on Windows the runtime answers the same numbers; a non-integer argument stops (`lume: type error: this needs an integer`); in `--raw` runtime code it is an intrinsic over raw words | stable, not in a kernel |

Notes: the slots of `krn_slot_write` / `krn_slot_read` share the scratch area the runtime itself uses for sleeping, process, network
and SIMD builtins, so in a hosted program only slots 160..1023 keep their value across those calls (a low slot can
be overwritten, and reading it back can then stop the program). Interrupt gates, task stacks and the SMP mailbox
sit at fixed low physical addresses of the kernel image. The kernel start-up programs COM1 for `print`, and a kernel
ends through the isa-debug-exit port 0xF4 and `cli; hlt`.

```lume
let b = buf_new(24)
let a = buf_addr(b)
print mem_set(a, 65, 3)
print mem_copy(a + 8, a, 3)
print buf_to_str(b, 8, 3)
print atomic_xadd64(a + 16, 5)
print atomic_xadd64(a + 16, 2)
print mmio_volatile_read8(a + 16)
print krn_slot_write(1000, 42)
print krn_slot_read(1000)
print static_arena_cap()
```
```output
3
3
AAA
0
5
7
42
42
65536
```

## 8. Contracts

`requires` / `ensures` after the parameters; `lume prove` proves them where it can, the rest is checked at run
time (a violation stops the program, exit 3). `result` is the returned value, `old(x)` the value at entry.

```lume
fn half(x) requires x >= 0 ensures result >= 0 = x / 2
print half(10)
```
```output
5
```

Builtin contracts: the prover knows what some builtins answer, when the call's result is named with `let` or is
the function's result: `buf_bits_write(b, p, v, n)` is `p + n` or `-1`; `buf_get(b, i)` is 0..255 (an index
outside the buffer stops the program); `buf_len(b)` and `count(s)` are >= 0; `buf_sad*` / `buf_satd*` are >= -1;
`buf_h264_quant4x4` is -1..16. A clause the prover proves must not trap itself: `p + n` can overflow, so bound
p and n in `requires`.

```lume
fn put3(b: buf, p: int, v: int) -> int
    requires p >= 0 and p <= 1000000000
    ensures result == p + 3 or result == 0 - 1
    = buf_bits_write(b, p, v, 3)
print put3(buf_new(4), 0, 5)
```
```output
3
```

## 9. Conventions and reserved names

Keywords: `if then else elif let in var mut match not and or own with spawn do defer errdefer comptime quote
splice scope shard fn pub priv use as type const law print requires ensures true false`. A capitalized name is a
constructor. Runtime builtins and the prefixes `__rt_` / `__lume_` cannot name a function ([R0201]). `ct_` at the
start of a function name makes its parameters secrets ([C0009] on a branch over them); parameters named `secret`
/ `secret_*` are secrets anywhere. `test_*` functions are what `lume test` runs. A comment
`## Deprecated: <message>` directly above a function marks it: a call from another module warns [W0005] with the
message, and it keeps working for at least one whole MINOR release (versions, deprecation and the long-term-support
line: `docs/STABILITY.md`). `grad`, `value_and_grad`, `jvp`,
`vjp` are autodiff operators. A name defined in two modules gives warning [W0003].

## 10. Known limits

- The runtime is single-threaded.
- At most 6 parameters in `--raw` runtime code; ordinary functions take any number.
- Constant list and record literals (nested ones too) are shared static data: they are never mutated (Lume values are immutable).
- Record flattening inlines small functions; `LUME_FL=off` turns it off (for measuring allocation or reading the
  call shape in the assembly).
- macOS targets cover the verified core only (write / exit); `winsys` exists only on Windows.

## 11. Changed in this version

Added: `use std/zstd` (Zstandard decoder and encoder, XXH64), `deflate_level` / `zlib_compress_level` / `gzip_level` (zlib's levels 1-9), entries for every builtin a program can call (files, owner-only files, the OS keychain, standard input, environment, processes, pipes, shared memory, io_uring, TCP / UDP and epoll, crypto primitives, try / fail, bit vectors, constant time, SIMD, the packed h264 forms, freestanding and hardware builtins), `use std/json` (strict RFC 8259 parser and writers, JSON Pointer), `use std/tz` (TZif tzdata and POSIX TZ rules), `use std/encoding` (hex, base64, base64url), `sha224` / `sha384` / `sha512`, HMAC, PBKDF2, `crc32c`, `fnv1a32` / `fnv1a64`, `dt_parse`, `dt_format`, `dt_yday`, `dt_iso_week`, `csv_parse_checked`, `csv_index` / `csv_get`, `utf8_next` / `utf8_fold` / `utf8_check` / `utf8_sanitize` / `utf8_offset` / `utf8_encode_cp` / `utf8_to_utf16` / `utf8_from_utf16`, regex `\b \B`, backreferences, lookahead, named groups, `(?i)`, `\xHH`, `re_named`, `re_group_names`, `re_find_all_groups`, dynamic Huffman and stored blocks in `deflate_buf`, `lume debug --dap` (the debugger over the Debug Adapter Protocol), `buf_h264_mb_i4`, `buf_h264_mb_i16`, `buf_h264_mb_ic`, `buf_h264_mb_p`, `buf_h264_mb_pc`, `buf_h264_cavlc_luma` / `chroma` (whole Intra4x4, inter luma and inter chroma macroblocks in one call), `buf_h264_me16` (motion search), the table of every diagnostic code (section 3a) and diagnostic examples for 68 codes, `use std/hash`, `csv`, `utf8`, `datetime`, `regex`, `deflate`, `http`, `tls` (HTTPS with TLS 1.3), `tlspki`, `bignum`, package versions (`lume pkg publish / add / install`, `[packages]` in lume.lock), `lume verify` (many files, N processes, per-file cache), the call stack (`at NAME (file:LINE)`) after a run-time error, builtin contracts in the prover (`buf_bits_write`, `buf_get`, `buf_len`, `count`, `buf_sad*`, `buf_satd*`, `buf_h264_quant4x4`), official examples (`examples/topics`, `examples/diagnostics`, examples gate), `use std/NAME`, `buf_bits_write / read / ue / se`, `## Deprecated:` and warning [W0005], docs/STABILITY.md (semver, deprecation, LTS 1.2), `use math` (math names, f32, f32 buffers), f64 parameters, W0004, `lume run --profile`, `use h264` (motion compensation, deblocking), `buf_sad*`, `buf_satd*` (SSE2), `buf_h264_*`, `use tun`, `lchameleon` `chameleon_c_open / sym / call` and
`chameleon_verify_boundary`, `priv fn`, warning [W0003], `LUME_FL`, constant literals in .rodata, per-site field
cache, collection pacing `max(8 MiB, 3 x live)`.
Changed: `deflate_buf` follows zlib level 6 (lazy matching, a block every 16383 symbols) and `inflate_buf` refuses over-subscribed and incomplete codes and more than 286 / 30 codes; `dt_parse_iso` refuses text after the zone; `utf8_encode` writes U+FFFD for a surrogate or an out-of-range value and a NUL byte for 0 (it stopped before); `utf8_upper` / `utf8_lower` also map Latin Extended-A, Greek and Cyrillic; lenient `csv_parse` keeps text after a closing quote in the field (it started a new row); regex class ranges work across UTF-8 lengths and an empty match at the end no longer stops `re_find_all`; [E0305] lets an int or bool copied into or out of a sent record stay with the sender; a delimiter still open at the end of the file is [P0001] (was [P0002]); `lume agent kernel` examples run in the examples gate; W0004 also sees parameters typed `f64` and results of `f64(...)`; `buf_sad4x4` runs in SSE2; C0009 in a `ct_` function names the prefix as the reason; `lume fmt` refuses to run on the Stage-0
fallback; on Git Bash `lume` runs the native `lume.exe`; `fs_copy` keeps the source's permission bits.
Removed: nothing.
