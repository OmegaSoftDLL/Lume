<h1>
  <img src="docs/assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="84" height="84" align="left" />
  LumeLabs — Official R&amp;D Incubator &amp; Experimental Innovation Hub
</h1>

**Where High-Risk Systems, Polyglot FFI, 1-Bit Edge AI, Fault-Tolerant Quantum Computing, and Mechanized Proof Theory Graduate into 100% Pure-Lume Production (`stage2 == stage3`)**

<br clear="left"/>

<div align="center">

[![LumeLabs Status](https://img.shields.io/badge/LumeLabs-7%2F7%20Divisions%20Active-00d2ff)](#the-7-lumelabs-research-divisions)
[![Proof Gate](https://img.shields.io/badge/graduation%20gate-QF__LIA%20%2B%20lcert%20Required-brightgreen)](#the-lumelabs-graduation-protocol-rfc--proof--stage-1)
[![Zero-C Policy](https://img.shields.io/badge/implementation-100%25%20Native%20Lume%20%28.src%29-success)](docs/PROJECT_STATE.md)
[![Community](https://img.shields.io/badge/community-EN%20%26%20PT--BR-8b5cf6)](COMMUNITY.md)

[**Home (`README.md`)**](README.md) · [**Projects & Roadmap (`PROJECTS.md`)**](PROJECTS.md) · [**Community (`COMMUNITY.md`)**](COMMUNITY.md) · [**Wiki**](https://github.com/OmegaSoftDLL/lume/wiki) · [**GitHub Discussions**](https://github.com/OmegaSoftDLL/lume/discussions) · [**Manual (`EN`)**](docs/LUME_MANUAL_EN.md) · [**Manual (`PT-BR`)**](docs/LUME_MANUAL_PT_BR.md)

<br/>

![LumeLabs — 7 Sovereign Research Divisions & Experimental Innovation Pipeline](docs/assets/lumelabs-hero-animated.svg)

</div>

---

## 1. Mission & Sovereign Charter

<img src="docs/assets/lume-mascot.jpg" alt="Lumi — Bioluminescent Crystal Chameleon Mascot" width="260" align="right" />

**LumeLabs** is the official research, incubation, and advanced systems engineering arm of the **Lume Programming Language (`v1.1.0`, Edition 2026)**.

Unlike traditional language incubators where experimental libraries rely on unverified C/C++/Python glue or unstable compiler plugins, every LumeLabs project adheres to three non-negotiable rules:

1. **100% Native Lume (`.src`) Implementation:** Zero Python scripts, zero Rust dependencies, and zero C seed expansion (`"Lume gera Lume 100%"`).
2. **Compile-Time Mathematical Proof (`QF_LIA` / `QF_NIA` / `QF_BV` / Separation Logic):** Every subsystem must state its safety invariants via `requires`, `ensures`, and universal `law` theorems verified by `lcaas` and certified by the standalone `lcert` kernel (`Lume Verified ✓`).
3. **Self-Hosted Fixpoint Preservation (`stage2 == stage3`):** Graduating a LumeLabs module into `compiler/stage1/` requires passing the bit-identical triple bootstrap, the **85/85 Claude Opus 5.5 + Red Team (R1, R2 & R3) Audit Gate** (`tests/harness/claude_audit_gate.src`), and the **15/15 Embedded Compiler Proof Batteries** (`lume self-prove`, `413` obligations).

> 🇧🇷 **Comunidade em Português (`pt-BR`):** Pesquisadores e desenvolvedores podem submeter propostas do LumeLabs, abrir discussões técnicas e consultar o manual nativo em português (`lume manual --pt` ou [`docs/LUME_MANUAL_PT_BR.md`](docs/LUME_MANUAL_PT_BR.md)).

<br clear="right"/>

---

## 2. The 7 LumeLabs Research Divisions

### Lab 01 Spotlight — Universal Chameleon Polyglot & Zero-Copy FFI (`lchameleon.src`)

<img src="docs/assets/lume-chameleon-emblem.jpg" alt="Lume Chameleon Polyglot Lambda Emblem" width="240" align="right" />

**Lab 01 (`compiler/stage1/lchameleon.src`)** embodies Lumi's adaptive nature: it synthesizes fail-closed **`[I0003]` `QF_LIA` refinement adapters** (`unverified[T] -> verified[T]` under `/ {ffi}`, `28/28` proven obligations, `8/8` unit tests) across **9 foreign ecosystems** (`c_abi`, `rust_cdylib`, `python_capi` DLPack zero-copy tensors, `node_napi_wasm`, `go_cshared`, `java_jni`, `dotnet_pinvoke`, `sql_relational`, and `openapi_rpc`).

<br clear="right"/>

| Division | Core Engine & Source | Verified Obligations & Key Capabilities | CLI Entrypoint |
| :--- | :--- | :--- | :--- |
| **Lab 01 · Chameleon Polyglot & Zero-Copy FFI** | [`compiler/stage1/lchameleon.src`](compiler/stage1/lchameleon.src) | **`28/28` proven obligations (`8/8` tests)** · Bridges `c_abi`, `rust_cdylib`, `python_capi` (DLPack zero-copy tensors), `node_napi_wasm`, `go_cshared`, `java_jni`, `dotnet_pinvoke`, `sql_relational`, and `openapi_rpc` via fail-closed `[I0003]` `unverified[T] -> verified[T]` contracts | `lume chameleon [eco]` / `lume adapt <eco>` / `lume morph <file>` |
| **Lab 02 · Sovereign 1-Bit/Ternary Edge AI & Liquid Audio** | [`compiler/stage1/lume_llm_core.src`](compiler/stage1/lume_llm_core.src) | **`21/21` proven obligations** · Bonsai 1-bit & BitNet 1.58-bit ternary MAC (`{-1, 0, +1}`), 5-trit byte packing, Liquid AI `LFM3` $O(1)$ state-space recurrence, `LiquidCodec` 24 kHz audio frame bounds, `DSpark` speculative decoding, `Colibri` MoE SSD streaming guard (`8 GB` RAM cap) | `lume test compiler/stage1/lume_llm_core.src` |
| **Lab 03 · Quantum Nexus & Fault-Tolerant QEC** | [`compiler/stage1/lume_quantum_nexus_engine.src`](compiler/stage1/lume_quantum_nexus_engine.src) | **Linear Qubits (`[Q0001]` No-Cloning)** · `[Q0002]` Measurement Collapse, `[Q0003]` Uncomputation, `[Q0004]` Connectivity Routing, ZX-Calculus spider fusion, Rotated Surface Code `[[9,1,3]]` QEC, and 6 targets (`OpenQASM 3.0`, `QIR`, `Quil`, `IQM`, `Stim`, `QEC`) | `lume build <q.lume> --target openqasm3` |
| **Lab 04 · KerneLume Ring-0 Bare-Metal OS & Hardware Synthesis** | [`apps/lume_os/`](apps/lume_os/) · [`compiler/stage1/ltarget.src`](compiler/stage1/ltarget.src) | **`@freestanding` Zero-GC Ring-0 OS** · Bootable MBR -> 64-bit Long Mode `.kernel`, `[K0005]` W^X DMA protection, `[K0006]` interrupt stack bounds, `[V0002]` WCET cycle bounds, plus synthesizable `Verilog-2005`, `VHDL-2008`, and `openTPU` systolic array ISA | `lume build <k.lume> --target x86_64-kernel` |
| **Lab 05 · Mechanized Soundness & Proof Certificates** | [`compiler/stage1/lcaas.src`](compiler/stage1/lcaas.src) · [`compiler/stage1/lcert.src`](compiler/stage1/lcert.src) · [`formal/lean/LumeCore.lean`](formal/lean/LumeCore.lean) | **`413/413` compiler obligations** · Fourier-Motzkin `QF_LIA` with cutting planes, degree-2 Positivstellensatz `QF_NIA`, `QF_BV` bitvector bounds, Separation Logic frame rules, `[C0009]` `@secret` constant-time taint proofs, and FIPS 180-4 SHA-256 `.cert` artifacts | `lume prove <file.src>` / `lume certify <file.src>` / `lume self-prove` |
| **Lab 06 · Native Desktop GUI, WebAssembly & 3D Graphics** | [`compiler/stage1/ltarget.src`](compiler/stage1/ltarget.src) · [`compiler/stage1/gui.src`](compiler/stage1/gui.src) · [`compiler/stage1/gfx.src`](compiler/stage1/gfx.src) | **33,792-byte Win64 Native GUI (`PE32+`)** · Clean Generic `x86_64-windows-gui` cockpit (`WS_CLIPSIBLINGS \| LBS_DISABLENOSCROLL`, `1366px` full-width bottom panes), Wayland `xdg-dialog-v1` (`4/4` proofs), and Perceus allocation-free Virtual DOM | `lume build <app.src> --target x86_64-windows-gui` |
| **Lab 07 · Applied Sovereign FinTech, Pix/SEFAZ & Cyber Forensics** | [`examples/apps/`](examples/apps/) | **`81/81` capstone proofs across 8 production apps** · `dfe_pix_bacen` (`11/11`), `pix_fraud_trace` (`9/9`), `brasil_public_id` (`9/9` July 2026 Alphanumeric CNPJ), `zero_breach_forensics` (`8/8` Pegasus/Predator/Candiru STIX 2.1), `sentry_uav_guard` (`9/9`), `verified_accounting` (`7/7`), `omniroute_guard` (`8/8`), `sovereign_llm_router` (`20/20`) | `lume prove examples/apps/<app>/main.src` |

---

## 3. Running LumeLabs Experiments Locally

Every Lume `v1.1.0` installation ships with the complete LumeLabs engine suite built in:

```sh
# 1. Consult the Sovereign Compiler-as-Oracle & Hyperdimensional Memory
lume consult "design zero-copy rust cdylib tensor bridge with [I0003] bounds"

# 2. Run the Universal Chameleon Polyglot Interop Engine (Lab 01)
lume chameleon
lume chameleon rust
lume chameleon python
lume adapt rust
lume morph legacy_module.py

# 3. Prove & Certify LumeLabs Domain Engines (Labs 01, 02, 05, 07)
lume prove compiler/stage1/lchameleon.src
lume certify compiler/stage1/lchameleon.src
lume test compiler/stage1/lchameleon.src
lume test compiler/stage1/lume_llm_core.src

# 4. Run Autonomous Proof-Guided Program Evolution & Neural Kernel Synthesis
lume evolve examples/verified_showcase.src
lume neural-kernel
lume genesis "bounded ring buffer with QF_LIA head/tail invariants"

# 5. Execute the Full Embedded Compiler Self-Proof Suite (15 Batteries, 413 Obligations)
lume self-prove
```

---

## 4. The LumeLabs Graduation Protocol (`RFC -> Proof -> Stage-1`)

Every experimental idea in LumeLabs progresses through four deterministic lifecycle stages tracked on our [**Project Board & Roadmap (`PROJECTS.md`)**](PROJECTS.md):

1. **Stage I — Proposal (`LumeLabs RFC`):**
   - Open a proposal using the [LumeLabs RFC Issue Template](.github/ISSUE_TEMPLATE/lumelabs_proposal.md) or in [GitHub Discussions (`LumeLabs R&D`)](https://github.com/OmegaSoftDLL/lume/discussions).
   - Define the target problem, mathematical invariants (`requires`/`ensures`/`law`), and why Lume's formulation is strictly superior to prior art.
2. **Stage II — Prototype (`examples/apps/` or `compiler/stage1/l*.src`):**
   - Implement 100% in pure Lume (`.src`, pure LF `\n`, formatted via `lume fmt`).
   - Achieve `100%` proven status under `lume prove` and `lume certify` (`0` unproven obligations, `0` failed unit tests).
3. **Stage III — Adversarial Red-Team & Differential Fuzzing:**
   - Add negative conformance tests verifying that invalid inputs or contract violations fail closed with a deterministic diagnostic code (such as `[I0003]`, `[V0001]`, `[C0009]`, or `[E0200]`).
   - Pass the 4-way differential fuzzer (`lumec` ELF64 vs `LUME_GC_STRESS=1` vs Stage-0 `lume0` vs `lcaas`) in `tests/harness/claude_audit_gate.src`.
4. **Stage IV — Stage-1 Graduation & Manifest Lock:**
   - Integrate into `compiler/stage1/`, verify `stage2 == stage3` bit-identical bootstrap, update bilingual manuals (`lmanual.src` -> `LUME_MANUAL_EN.md` + `LUME_MANUAL_PT_BR.md`), and lock into `MANIFEST.sha256`.
