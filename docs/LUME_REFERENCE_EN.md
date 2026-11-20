# Lume Reference (factual) — v1.2.0

This is the reference of what works today. It contains no roadmap and no vision material: that is in
`lume manual vision` and in the other chapters, which mix both. Every example below is run by
`tests/docs/ref_examples_gate.src` (in the test suite) with the installed toolchain; the block under each example
is its exact output.

Status labels: **stable** = Linux x86-64 and Windows x64, same behavior; **linux** / **windows** = that platform
only; **experimental** = works, the API may still change; **privileged** = needs root (Linux) or an elevated
process (Windows).

## 1. Programs and commands

A program is a `.src` file. Top-level `print` lines run in order. `lume run f.src [args]` builds and runs it,
`lume build f.src -o out` writes a native executable (`out.exe` on Windows), `lume test f.src` runs every
`fn test_*()` that returns a truth value, `lume check f.src` type-checks without running, `lume fmt f.src` formats
in place (`--check`, `--stdout`), `lume manual [chapter]` prints the manual (`--pt` in Portuguese). `lume run --profile f.src` prints per function
the self and total time, calls and allocations, and the GC time, on stderr at exit (inlined functions count in their
caller; `LUME_FL=off` keeps them; a tail loop is one call). `lume debug [--commands FILE] [-x CMD]... f.src` runs it
under the debugger: breakpoints on a function or FILE:LINE, `step` / `next` / `finish` / `continue` from call to call,
`bt` with each frame's arguments, `args`, `locals`, `print NAME`, `frame N`, `up`, `down`, and a stop on a run-time
error; text commands, output on stderr (an AI drives it with `-x`).

`lume verify [--jobs=N] a.src b.src ...` runs check, test, prove, the format check and certify on many files in N processes
(default 2); each file's result is cached by the SHA-256 of its whole bundle and of the tools, so after a change only
the changed module and the files that import it run again.

Packages: `lume pkg publish [dir] --store=DIR` runs the package's tests and stores NAME/VERSION immutably with its
SHA-256; `lume pkg add NAME@REQ` writes `name = "REQ"` under `[dependencies]` (REQ: `1.2.3`, `^1.2`, `~1.2.3`, `*`);
`lume pkg install --store=DIR` takes the highest matching versions into `lume_modules/`, runs their tests and writes
the versions and hashes into `lume.lock`; `use NAME` finds an installed package.

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

- `fn name(a, b) = expr`, `pub fn` (exported), `priv fn` (private to its module), `const NAME: T = expr`,
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

## 5. Byte buffers (stable)

`buf_new(n)` (n bytes, all zero), `buf_len(b)`, `buf_get(b, i)` (0..255), `buf_set(b, i, v)` (answers b),
`buf_copy(dst, d_off, src, s_off, n)`, `buf_slice(b, off, n)`, `buf_from_str(s)`, `buf_to_str(b, off, n)`,
`buf_addr(b)` (the address of byte 0, for system calls). An index outside the buffer or a value outside
0..255 stops the program.

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
argument): `buf_bgra_to_i420`, `buf_i420_to_bgra`, `buf_sad16x16 / 8x8 / 4x4 (a, ai, sa, b, bi, sb)` and
`buf_satd4x4 / 16x16 (same)` (SSE2), `buf_h264_fdct4x4 / idct4x4 (src, si, dst, di)` (int16 blocks),
`buf_h264_quant4x4 (src, si, qp, intra, dst, di)` (answers the nonzero levels), `buf_h264_dequant4x4 (src, si, qp,
dst, di)`, `buf_h264_sub4x4 (a, ai, sa, pred, pi, dst)`, `buf_h264_recon4x4 (pred, pi, res, ri, dst, di)`,
`buf_h264_intra4x4 / intra16x16 (frame, fi, fs, mode, avail, dst)` (avail bits: 1 left, 2 top, 4 top-right,
8 top-left). With `use h264`: `buf_h264_cavlc4x4 (coef, ci, nc, maxc, out, pos)` codes one block of maxc
(16, 15 or 4) int16 coefficients in zigzag order with CAVLC (nC -1: chroma DC) into out from bit pos and answers
{pos, total} (the new bit position, -1 on a wrong argument or a full buffer, and TotalCoeff).
`buf_h264_mb_i4 (src, si, ss, rec, ri, cfg)` encodes a whole Intra4x4 macroblock in one call: for each of its 16
blocks (luma4x4BlkIdx order) the 9 predictions its neighbours allow, cost SATD + lambda x (1 for the predicted mode,
else 4), the cheapest is transformed, quantized and reconstructed into rec. cfg (at least 592 bytes, int32 little
endian) gives rs, qp, lambda, the macroblock neighbours (1 left, 2 top, 4 top-right, 8 top-left) and the neighbour
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

Network (stable): `net_udp_bind_addr(ip, port)` (a socket, -1 on failure), `net_udp_send_to(fd, ip, port, data)`
(bytes sent), `net_udp_recv_from(fd, max)` (the datagram, `""` when none), `net_last_peer_ip()`,
`net_last_peer_port()`, `net_tcp_connect_addr(ip, port)` (a socket, -1 when refused), `net_close(fd)`;
`use netctl` adds timeouts and non-blocking I/O with epoll.

## 7. Standard library modules

| Module | What it gives | Status |
| --- | --- | --- |
| `h264` | `buf_h264_luma_mc(ref, ri, rs, rw, rh, x, y, mx, my, w, h, dst, di, ds)` (quarter-sample 6-tap luma, 8.4.2.2.1), `buf_h264_chroma_mc(...)` (same arguments, eighth-sample bilinear, 8.4.2.2.2), `buf_h264_deblock_edge(buf, q0, across, along, lines, bs, alpha, beta, tc0, chroma)` (8.7.2.3 / 8.7.2.4; bs and tc0 lists, one value per 4 luma / 2 chroma lines); 0, or -1 on a wrong argument; coordinates clamped to the picture | stable |
| `hash` | `crc32`, `adler32`, `md5`, `sha1`, `sha256` (strings; `*_buf` for buffers), `hex32` | stable |
| `csv` | `csv_parse(text)` (RFC 4180: quotes, separators and line breaks inside fields), `csv_format(rows)`, `csv_parse_sep` / `csv_format_sep`, `csv_field` | stable |
| `utf8` | `utf8_len`, `utf8_decode` / `utf8_encode`, `utf8_char`, `utf8_cp`, `utf8_slice`, `utf8_upper` / `utf8_lower` (ASCII + Latin-1), `utf8_reverse`, `utf8_valid` (strings are bytes; these count characters) | stable |
| `datetime` | `dt_from_unix`, `dt_to_unix`, `dt_iso`, `dt_parse_iso`, `dt_weekday`, `dt_add_days` / `dt_add_months`, `dt_offset(zone, t)` / `dt_local` / `dt_iso_local` (fixed offsets, US / EU / Sydney daylight rules) | stable |
| `regex` | `re_match`, `re_search`, `re_find`, `re_find_all`, `re_groups`, `re_replace` (`$1`), `re_split`: classes, `\d \w \s`, anchors, groups, alternation, greedy and lazy quantifiers | stable |
| `deflate` | `inflate_buf` / `deflate_buf`, `zlib_decompress` / `zlib_compress`, `gunzip` / `gzip`, `gunzip_str` / `gzip_str` (Adler-32 / CRC-32 checked) | stable |
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

Added: `buf_h264_mb_i4` and `buf_h264_mb_p` (a whole Intra4x4 or inter 16x16 macroblock in one call), the table of every diagnostic code (section 3a) and diagnostic examples for 68 codes, `use std/hash`, `csv`, `utf8`, `datetime`, `regex`, `deflate`, `http`, `tls` (HTTPS with TLS 1.3), `tlspki`, `bignum`, package versions (`lume pkg publish / add / install`, `[packages]` in lume.lock), `lume verify` (many files, N processes, per-file cache), the call stack (`at NAME (file:LINE)`) after a run-time error, builtin contracts in the prover (`buf_bits_write`, `buf_get`, `buf_len`, `count`, `buf_sad*`, `buf_satd*`, `buf_h264_quant4x4`), official examples (`examples/topics`, `examples/diagnostics`, examples gate), `use std/NAME`, `buf_bits_write / read / ue / se`, `## Deprecated:` and warning [W0005], docs/STABILITY.md (semver, deprecation, LTS 1.2), `use math` (math names, f32, f32 buffers), f64 parameters, W0004, `lume run --profile`, `use h264` (motion compensation, deblocking), `buf_sad*`, `buf_satd*` (SSE2), `buf_h264_*`, `use tun`, `lchameleon` `chameleon_c_open / sym / call` and
`chameleon_verify_boundary`, `priv fn`, warning [W0003], `LUME_FL`, constant literals in .rodata, per-site field
cache, collection pacing `max(8 MiB, 3 x live)`.
Changed: [E0305] lets an int or bool copied into or out of a sent record stay with the sender; a delimiter still open at the end of the file is [P0001] (was [P0002]); `lume agent kernel` examples run in the examples gate; W0004 also sees parameters typed `f64` and results of `f64(...)`; `buf_sad4x4` runs in SSE2; C0009 in a `ct_` function names the prefix as the reason; `lume fmt` refuses to run on the Stage-0
fallback; on Git Bash `lume` runs the native `lume.exe`; `fs_copy` keeps the source's permission bits.
Removed: nothing.
