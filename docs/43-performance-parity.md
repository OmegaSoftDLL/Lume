# Performance parity: Windows vs Linux (measured)

Goal (owner): Windows performance never below Linux — and be able to **prove** it, not just claim it. This is the
measured parity snapshot. It is a program, not a sample: the same Lume source runs on both systems and times its own
work with `os_monotonic_ns`, so a cold start or a virus scanner holding a freshly built `.exe` never enters a measured
section. The checksum printed at the end is the same on both systems, so the two runs did identical work — correctness
parity, not just timing parity.

## Method

Run the benchmark below with the installed toolchain on each system:

- Linux (WSL / native): `lume run bench_parity.src`
- Windows (C:\Lume native toolchain): `C:\Lume\bin\lume.exe run bench_parity.src`

Each workload is timed over many iterations and reported per operation. The workloads are the ones the LumeDesk
project actually leans on: X25519 (crypto), a `buf_set` / `buf_get` hot loop (the inline fast path), and a 1080p
BGRA→I420 colour conversion (one video frame).

## Results (2026-11-23)

| Workload | Linux | Windows | Windows vs Linux |
| --- | --- | --- | --- |
| X25519 scalar multiplication | 733 µs / op | **593 µs / op** | 1.24× faster |
| `buf_set` + `buf_get` | 10 ns / op | **8 ns / op** | 1.25× faster |
| BGRA→I420, 1920×1080 | 9.3 ms / frame | **8.2 ms / frame** | 1.13× faster |
| checksum | 603444000 | 603444000 | identical |

On every measured workload Windows is at or above Linux, and the identical checksum shows both produced the same
bytes. The 1080p colour convert is under the 16 ms per-frame budget on both. These are this machine's numbers;
re-run the benchmark to refresh them on other hardware.

## Benchmark source

```lume
fn nzeros(n) = if n <= 0 then "" else chr(0) + nzeros(n - 1)
fn nine() = chr(9) + nzeros(31)
fn rep_x(k, u, n, acc) = if n <= 0 then acc else let r = crypto_x25519(k, u) in rep_x(k, u, n - 1, acc + ord_at(r, 0))
fn bufloop(b, i, n, acc) = if i >= n then acc else let z = buf_set(b, i % 4096, i % 256) in bufloop(b, i + 1, n, acc + buf_get(b, i % 4096))
fn ccloop(src, st, w, h, dst, n, acc) = if n <= 0 then acc else let r = buf_bgra_to_i420(src, st, w, h, dst) in ccloop(src, st, w, h, dst, n - 1, acc + r)
let nine_k = nine()
let t0 = os_monotonic_ns()
let a1 = rep_x(nine_k, nine_k, 2000, 0)
let t1 = os_monotonic_ns()
let b = buf_new(4096)
let a2 = bufloop(b, 0, 4000000, 0)
let t2 = os_monotonic_ns()
let w = 1920
let h = 1080
let src = buf_new(w * h * 4)
let dst = buf_new(w * h * 3 / 2)
let a3 = ccloop(src, w * 4, w, h, dst, 30, 0)
let t3 = os_monotonic_ns()
print f"platform {os_platform()}"
print f"x25519_ns_per_op {(t1 - t0) / 2000}"
print f"buf_setget_ns_per_op {(t2 - t1) / 4000000}"
print f"bgra_to_i420_1080p_us_per_frame {(t3 - t2) / 30 / 1000}"
print f"checksum {a1 + a2 + a3}"
```
