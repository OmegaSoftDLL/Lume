<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Lume Mascot" width="76" height="76" align="left" />
  Universal Chameleon Polyglot Interop Engine
</h1>
<br clear="left"/>

<div align="center">
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-chameleon-showcase.svg" alt="Universal Chameleon 9-Ecosystem Polyglot Interop Engine" width="100%" />
</div>

---

## 1. Why the Chameleon Engine Exists

In traditional languages, every Foreign Function Interface (`extern "C"`, JNI, Python C-API, N-API, P/Invoke) is a **verification black hole**: memory safety, null-pointer invariants, tensor strides, and integer bounds vanish the moment execution crosses a language boundary.

Lume's **Universal Chameleon Polyglot Engine** (`compiler/stage1/lchameleon.src`) eliminates this boundary gap. Every foreign payload enters Lume as an untrusted type `unverified[T]` and **cannot be dereferenced or passed to pure Lume code** until it passes an explicit `[I0003]` `QF_LIA`-verified refinement contract that promotes it to `verified[T]`.

---

## 2. The 9 Verified Ecosystems (`28/28` Proven Obligations)

| # | Ecosystem ID | Target Language / Runtime | ABI & Bridge Protocol | Zero-Copy & Safety Contract (`[I0003]`) |
| :-: | :--- | :--- | :--- | :--- |
| **1** | `c_abi` | **C / C++20** | System V AMD64 / Win64 ABI (`.h` + ELF/PE) | Non-null pointer, `len >= 0`, bounds-checked slice view |
| **2** | `rust_cdylib` | **Rust (`cargo cdylib`)** | `#[repr(C)]` + Perceus ownership transfer | Linear `own` borrow without double-free or alias violation |
| **3** | `python_capi` | **Python 3.12+ & PyTorch/JAX** | `PyModuleDef` C-API + **DLPack Tensor ABI** | 64-byte aligned zero-copy `DLManagedTensor` shape/stride proof |
| **4** | `node_napi_wasm` | **Node.js / Deno / Bun / Web** | Node-API (`napi_value`) + WebAssembly `memory` | TypedArray byte-length & UTF-8 boundary refinement |
| **5** | `go_cshared` | **Go (`c-shared` / CGO)** | C-shared goroutine-safe pinned channel bridge | Pinned pointer non-escape invariant across CGO calls |
| **6** | `java_jni` | **Java 21+ / Kotlin (JVM)** | JNI `CriticalNative` + Project Panama `Linker` | Direct `ByteBuffer` capacity & alignment verification |
| **7** | `dotnet_pinvoke` | **C# 12 / .NET 8+ (CLR)** | `[LibraryImport]` P/Invoke + `Span<T>` pinning | Blittable struct layout & pinned span bounds check |
| **8** | `sql_relational` | **PostgreSQL / SQLite3** | Typed relational wire/C-API prepared statements | Compile-time SQL parameter count & nullability verification |
| **9** | `openapi_rpc` | **OpenAPI 3.1 / JSON-RPC / gRPC** | Zero-allocation HTTP/JSON & protobuf wire codec | Schema range & required-field refinement (`unverified -> verified`) |

---

## 3. CLI Commands (`lume chameleon` / `lume camaleao`)

```bash
# Inspect all 9 verified ecosystems and their 28 formal QF_LIA obligations
lume chameleon

# Aliases in English and Portuguese
lume camaleao
lume polyglot
lume ffi-bridge

# Synthesize a complete verified bridge for a specific ecosystem
lume adapt rust_cdylib
lume adapt python_capi
lume adapt dotnet_pinvoke

# Auto-detect and morph an external header/schema (.h, .rs, .py, .sql, .json) into verified Lume
lume morph include/sensor.h
lume morph schema/orders.sql
```

---

## 4. How `[I0003]` Boundary Refinement Works

When `lume morph` or `lume adapt` generates a bridge, every foreign input is wrapped in a fail-closed boundary guard proven by `OmniProof v3`:

```lume
## Automatically synthesized by `lume adapt python_capi` (DLPack Zero-Copy Bridge)
@bound(cycles: 48)
pub fn chameleon_dlpack_ingest(
    data_ptr: int,
    ndim: int,
    numel: int,
    alignment: int
) -> int / pure
    requires data_ptr > 0 and ndim >= 1 and ndim <= 8 and numel > 0 and alignment == 64
    ensures result == numel and result > 0
=
    numel
```

If an external caller attempts to pass a null pointer (`data_ptr <= 0`), unaligned tensor buffer (`alignment != 64`), or negative length, the synthesized boundary shim rejects the call at the perimeter (`ERR:[I0003]`) before a single instruction of core Lume logic executes.
