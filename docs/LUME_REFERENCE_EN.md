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

`lume verify [--jobs=N] a.src b.src ...` runs check, test, prove, fmt --check and certify on many files in N processes
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

Added: `use std/hash`, `csv`, `utf8`, `datetime`, `regex`, `deflate`, `http`, `tls` (HTTPS with TLS 1.3), `tlspki`, `bignum`, package versions (`lume pkg publish / add / install`, `[packages]` in lume.lock), `lume verify` (many files, N processes, per-file cache), the call stack (`at NAME (file:LINE)`) after a run-time error, builtin contracts in the prover (`buf_bits_write`, `buf_get`, `buf_len`, `count`, `buf_sad*`, `buf_satd*`, `buf_h264_quant4x4`), official examples (`examples/topics`, `examples/diagnostics`, examples gate), `use std/NAME`, `buf_bits_write / read / ue / se`, `## Deprecated:` and warning [W0005], docs/STABILITY.md (semver, deprecation, LTS 1.2), `use math` (math names, f32, f32 buffers), f64 parameters, W0004, `lume run --profile`, `use h264` (motion compensation, deblocking), `buf_sad*`, `buf_satd*` (SSE2), `buf_h264_*`, `use tun`, `lchameleon` `chameleon_c_open / sym / call` and
`chameleon_verify_boundary`, `priv fn`, warning [W0003], `LUME_FL`, constant literals in .rodata, per-site field
cache, collection pacing `max(8 MiB, 3 x live)`.
Changed: W0004 also sees parameters typed `f64` and results of `f64(...)`; `buf_sad4x4` runs in SSE2; C0009 in a `ct_` function names the prefix as the reason; `lume fmt` refuses to run on the Stage-0
fallback; on Git Bash `lume` runs the native `lume.exe`; `fs_copy` keeps the source's permission bits.
Removed: nothing.
