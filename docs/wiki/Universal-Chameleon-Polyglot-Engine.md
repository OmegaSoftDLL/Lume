<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="76" height="76" align="left" />
  Universal Chameleon Polyglot Interoperability Engine (`lchameleon.src`)
</h1>
<br clear="left"/>

## 1. Closing the Foreign Function Verification Gap

<img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-chameleon-emblem.jpg" alt="Lume 9-Ecosystem Chameleon Polyglot Emblem" width="300" align="right" />

In conventional toolchains, crossing an FFI boundary (`extern "C"`, JNI, Python C-API, N-API, `cgo`, P/Invoke) discards compile-time guarantees: null pointers, misaligned tensor strides, unpinned GC references, dangling callback arenas, and out-of-range integers silently corrupt host memory.

Implemented in [`compiler/stage1/lchameleon.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lchameleon.src), Lume's **Universal Chameleon Polyglot Engine** eliminates unverified foreign boundaries across **9 ecosystems**:
- **`256 / 256` certified obligations** (`160` proven `QF_LIA` theorems + `96` `@bound` WCET budgets, `0` runtime/refuted).
- **`160 / 160` functions symbolically translation-validated (`ltv`)** across `1,781` native boundary vectors (`0` rejected).
- **`0 / 2,392` uncovered Masking MC/DC conditions** (`2,118` native witnesses + `256` law conclusions + `18` `lcert`-proven infeasible).
- **`19 / 19` native unit tests** + dedicated C header preprocessor gate (`tests/harness/c_adapter_gate.src`).

Every foreign payload enters Lume as `unverified[T]` inside the `/ {ffi}` capability effect and must pass a synthesized **`[I0003]` `QF_LIA` refinement gate** (plus **FFI callback arena epoch guards** preventing use-after-reset callbacks) before promotion to `verified[T]`.

<br clear="right"/>

<div align="center">
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-chameleon-showcase.svg" alt="Universal Chameleon 9-Ecosystem Polyglot Interop Engine" width="100%" />
</div>

---

## 2. The 9 Verified Foreign Ecosystems

| Ecosystem ID | Target Runtime &amp; ABI | `[I0003]` Formal Boundary Contract &amp; Zero-Copy Mechanism | CLI Command |
| :--- | :--- | :--- | :--- |
| **`c_abi`** | **C / C++ (`SysV AMD64` / `Win64` / `AAPCS64`)** | Built-in C header preprocessor (`--preprocess` expanding `#define`, `typedef`, `enum`, structs &amp; Linux `io_uring` syscalls `425..427`), `@repr(c)` layout, `ptr != 0`, alignment &amp; `[0..cap]` bounds | `lume adapt c --preprocess <h>` |
| **`rust_cdylib`** | **Rust (`cdylib` / `#[repr(C)]` / `extern "C"`)** | Affine `own` / `&T` Perceus lifetime parity, borrow exclusivity, and `panic = "abort"` FFI boundary isolation | `lume adapt rust <lib.rs>` |
| **`python_capi`** | **Python 3.12+ (`PyObject*` / `DLPack`)** | `Py_INCREF`/`Py_DECREF` balance + **DLPack zero-copy `NDArray` tensor bridge** (`64 B` alignment, `shape_dim >= 1`, monotone strides) | `lume adapt python <mod.py>` |
| **`node_napi_wasm`** | **Node.js / TypeScript (`N-API v9` &amp; `WASM32`)** | Linear memory page-bound verification (`offset + len <= wasm_pages * 65536`, `[I0275]`) &amp; UTF-8 slice validation | `lume adapt js <index.d.ts>` |
| **`go_cshared`** | **Go (`-buildmode=c-shared` / `cgo`)** | `runtime.Pinner` enforcement forbidding unpinned Go heap pointers from crossing into Lume | `lume adapt go <pkg.go>` |
| **`java_jni`** | **Java / Kotlin (`JNI` &amp; `JDK 22+ Panama FFM`)** | `PushLocalFrame` / `PopLocalFrame` capacity balance (`<= 64`) and `MemorySegment` byte bounds | `lume adapt java <Api.java>` |
| **`dotnet_pinvoke`** | **C# / .NET 8+ (`P/Invoke` &amp; `NativeAOT`)** | `GCHandle.Alloc(Pinned)` blittable struct size/alignment verification and span bounds | `lume adapt dotnet <Api.cs>` |
| **`sql_relational`** | **SQL (`PostgreSQL` / `SQLite` / `DuckDB`)** | DDL/DML schema lifting to typed `table[T]` with exact base-10 `decimal` scale &amp; ACID WAL invariants | `lume adapt sql <schema.sql>` |
| **`openapi_rpc`** | **OpenAPI 3.1 / JSON-Schema / gRPC** | Authenticated TLS 1.3 transport + bounded payload contracts (`0 < body <= max_bytes`) | `lume adapt openapi <api.yaml>` |

```sh
lume chameleon                                # Inspect all 9 verified ecosystems & [I0003] contract status
lume adapt c --preprocess include/api.h       # Preprocess C macros/typedefs and emit fail-closed [I0003] bindings
lume adapt python model_bridge.py             # Synthesize Python C-API + zero-copy DLPack tensor adapter
lume morph legacy_service.py                  # Transpile legacy C/Python/JS/Rust/Go/SQL into verified Lume (.src)
```

---

## 3. FFI Callback Arena Epoch Guards &amp; `[I0003]` Perimeter Proofs

When Lume passes a callback handle or arena-backed buffer to foreign C/Rust/Python code, `lchameleon.src` pairs pointer/alignment guards with monotonic **arena epoch tokens**:

```lume
@no_alloc
@bound(48)
pub fn chameleon_dlpack_ingest(data_ptr: int, ndim: int, numel: int, alignment: int, cb_epoch: int, live_epoch: int) -> int / pure
  requires data_ptr > 0 and ndim >= 1 and ndim <= 8 and numel > 0 and alignment == 64 and cb_epoch == live_epoch
  ensures result == numel and result > 0
= numel
```

Any null pointer, unaligned `DLManagedTensor`, negative byte count, or stale arena epoch (`cb_epoch != live_epoch`) fails closed with `ERR:[I0003]` at the foreign perimeter before pure Lume logic executes.

---

## 4. `LumePuter` Weight-Compiled Neural VM (`lume lumeputer`, `lneural_cartridge.src`)

Beyond traditional FFI, `lchameleon.src` and [`compiler/stage1/lneural_cartridge.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lneural_cartridge.src) implement **`LumePuter`**, compiling verified Lume functions directly into `.safetensors` neural weight cartridges (`--target safetensors` and `--target lumeputer-rv32im-weights`):
- Encodes program execution into `SwiGLU` (`K = 128`) projections (`swiglu_gate_proj`, `swiglu_up_proj`, `swiglu_down_proj`), `Gated-DeltaNet` recurrent state, `RV32IM_Zba` instruction ROM (`deltanet_rom`), and `RMSNorm` integrity ballast (`ballast_rmsnorm_guard`) with an embedded `lcert` proof certificate.
- Verified in `lume safetensors-gate` (`G-SAFETENSORS`): **`63 / 63` argument vectors execute `100.0%` bit-identically** across `.safetensors` forward passes, native `x86-64`, and the `LumePuter` emulator, while `99` damaged files and opcode/weight tamper attempts are deterministically caught.

---

## 5. Dynamical Singularity Boundary ($\Omega$) &amp; Bayesian SPC Analytics (`lume singularity`)

`lchameleon.src` also houses Lume's verified operational physics and statistical process control engine (`lume singularity` / `lume ote`):

- **Dynamical Singularity Boundary ($\Omega$):** Dual-regime underdamped/overdamped 2nd-order step identification ($\zeta \in (0, 100]$), Operational Power Triangle ($S^2 = P^2 + Q^2$, power factor $\cos\Phi$), **counter-phase Singularity Boundary theorem** ($\tau_{\max} = T_m / 4$ where transport delay drives phase margin to zero), Nyquist sampling guard, and $3\times$ cascade control loop bandwidth decoupling.
- **Bayesian &amp; Operations Research Kernels:** Conjugate Beta-Binomial posterior SPC (`spc_beta_binomial_posterior_num`), Page's tabular CUSUM shift detection (`spc_cusum_upper_step_milli`), Critical Path Method total float (`ops_cpm_total_float_hours`), $k$-anonymity disclosure guard (`analytics_k_anonymity_release_ok`), and Pool-Adjacent-Violators (`PAVA`) monotonic isotonic regression (`analytics_pava_monotonic_pair_hi`).
