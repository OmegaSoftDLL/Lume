<h1>
  <img src="assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="84" height="84" align="left" />
  Lume Sovereign Community — Official Charter, Working Groups &amp; Governance
</h1>

**Bilingual (`English` &amp; `Português pt-BR`) Global Community · Formal Verification Engineers · Systems &amp; AI Researchers · LumeLabs Working Groups**

<br clear="left"/>

<div align="center">

[![GitHub Discussions](https://img.shields.io/badge/GitHub%20Discussions-Join%20the%20Community-8b5cf6)](https://github.com/OmegaSoftDLL/lume/discussions)
[![LumeLabs R&D](https://img.shields.io/badge/LumeLabs-7%20Working%20Groups-00d2ff)](LUMELABS.md)
[![Projects & Roadmap](https://img.shields.io/badge/Projects-Live%20Board%20%26%20Roadmap-brightgreen)](PROJECTS.md)
[![Code of Conduct](https://img.shields.io/badge/Contributor%20Covenant-v2.1-success)](https://github.com/OmegaSoftDLL/lume/blob/main/CODE_OF_CONDUCT.md)

[**Home (`index.md`)**](index.md) · [**LumeLabs (`LUMELABS.md`)**](LUMELABS.md) · [**Projects & Roadmap (`PROJECTS.md`)**](PROJECTS.md) · [**Wiki**](https://github.com/OmegaSoftDLL/lume/wiki) · [**GitHub Discussions**](https://github.com/OmegaSoftDLL/lume/discussions) · [**Manual (`EN`)**](LUME_MANUAL_EN.md) · [**Manual (`PT-BR`)**](LUME_MANUAL_PT_BR.md)

<br/>

![Lume Sovereign Community & Official Social Banner](assets/lume-social-banner.jpg)

</div>

---

## 1. Welcome to the Lume Community (EN / PT-BR)

Welcome to the official community of **Lume (`v1.1.0`, Edition 2026)** — the self-hosted, mathematically proven systems, AI, and quantum programming language represented by our mascot **Lumi** (the Bioluminescent Crystal Chameleon).

Our community brings together systems programmers, formal verification researchers, AI/ML engineers, quantum algorithm designers, financial infrastructure architects, and security auditors who believe software should be **written naturally by humans and AI, proven mathematically at compile time, and compiled directly to native machine code without external C/C++ toolchains**.

> 🇧🇷 **Boas-vindas à Comunidade Lume em Português (`pt-BR`):**
> A comunidade oficial da linguagem Lume é nativamente bilíngue (**Inglês** e **Português Brasileiro**). Você pode participar das [Discussões no GitHub](https://github.com/OmegaSoftDLL/lume/discussions), propor experimentos no [**LumeLabs (`LUMELABS.md`)**](LUMELABS.md), consultar o manual completo integrado (`lume manual --pt` ou [`LUME_MANUAL_PT_BR.md`](LUME_MANUAL_PT_BR.md)) e interagir em português ou inglês!

---

## 2. Official Community Channels & GitHub Discussions Categories

All community conversations, design RFCs, Q&A, and showcase announcements happen in [**GitHub Discussions (`OmegaSoftDLL/lume/discussions`)**](https://github.com/OmegaSoftDLL/lume/discussions):

| Category | Purpose | How to Participate |
| :--- | :--- | :--- |
| 📣 **Announcements** | Official Lume releases (`v1.1.0+`), security advisories, and LumeLabs Stage-1 graduations | Subscribe (Watch -> Custom -> Discussions) |
| 🦎 **LumeLabs R&D & RFCs** | Design proposals for new compiler passes, `QF_LIA`/`QF_NIA` theorems, and polyglot bridges | Open a discussion or [LumeLabs RFC Issue](https://github.com/OmegaSoftDLL/lume/issues/new/choose) |
| 🧮 **Proofs, `QF_LIA` & `lcert` Clinic** | Help writing `requires`, `ensures`, `law`, `@bound(cycles: N)`, and `@secret` contracts | Share a minimal `.src` snippet and `lume prove` output |
| 🌐 **Chameleon Polyglot Interop (`9` Ecosystems)** | Adapting C/C++, Rust, Python DLPack, Node/WASM, Go, Java, .NET, SQL, and OpenAPI via `lchameleon` | Share target ABI headers or `lume adapt <eco>` outputs |
| 🚀 **Show & Tell (`Feito com Lume`)** | Showcase verified applications, Ring-0 kernels, Win64 GUIs, 1-bit LLM routers, and FinTech engines | Post your repo link, `.cert` summary, and benchmarks |
| 🇧🇷 **Comunidade Brasil (`pt-BR`)** | Discussões técnicas em português, FinTech Brasileira (`Pix`, `SEFAZ NF-e`, `CNPJ 2026`) e IA Soberana | Converse diretamente em `pt-BR` |

---

## 3. LumeLabs Working Groups (WGs)

Contributors can join any of the **7 LumeLabs Working Groups** aligned with [`LUMELABS.md`](LUMELABS.md):

1. **WG-Polyglot (`Lab 01`):** Universal Chameleon FFI (`compiler/stage1/lchameleon.src`), zero-copy DLPack tensors, and `[I0003]` boundary proofs.
2. **WG-Edge-AI (`Lab 02`):** 1-Bit/Ternary inference (`Bonsai` / `BitNet`), `Liquid AI LFM3` audio, and `Colibri` MoE SSD streaming (`compiler/stage1/lume_llm_core.src`).
3. **WG-Quantum (`Lab 03`):** Linear qubit type systems (`[Q0001]`–`[Q0004]`), ZX-Calculus, and Surface Code QEC (`compiler/stage1/lume_quantum_nexus_engine.src`).
4. **WG-Ring0-Hardware (`Lab 04`):** KerneLume bare-metal OS (`apps/lume_os/`), WCET `[V0002]`, and `Verilog`/`VHDL`/`openTPU` synthesis.
5. **WG-Formal-Soundness (`Lab 05`):** `lcaas.src` solver algorithms, `lcert.src` certificate kernel, Lean 4 mechanization (`formal/lean/LumeCore.lean`), and the 4-way differential fuzzer (`tests/harness/claude_audit_gate.src`).
6. **WG-GUI-Web-Graphics (`Lab 06`):** Clean Generic Win64 Native GUI (`--target x86_64-windows-gui`), Wayland `xdg-dialog-v1`, WebAssembly, and 2D/3D software rendering.
7. **WG-FinTech-Sec (`Lab 07`):** Verified financial infrastructure (`decimal`, `money[CCY]`, `Pix`, `SEFAZ`), anti-spyware forensics (`zero_breach_forensics`), and `[C0009]` constant-time cryptography.

---

## 4. Contribution & Recognition Ladder

Every contribution to Lume — whether a bug report with a minimal `.src` reproducer, a new `law` proof, a documentation improvement, or a full LumeLabs domain engine — follows our [**Sovereign Test & Publication Standard**](https://github.com/OmegaSoftDLL/lume/blob/main/CONTRIBUTING.md):

1. **Explorer:** Runs `lume self verify` and `lume self-prove`, participates in Discussions, or submits reproducible issue reports.
2. **Verified Contributor:** Merges a PR with 100% pure-Lume (`.src`, pure LF `\n`) code, `QF_LIA` proofs (`lume prove` + `lume certify`), and regression tests.
3. **LumeLabs Fellow:** Authors or co-maintains a LumeLabs Research Division module or verified capstone application (`examples/apps/*`).
4. **Core Maintainer:** Stewards the Stage-1 compiler pipeline (`compiler/stage1/lume/01_lexer.src` .. `07_driver.src`), self-hosted fixpoint (`stage2 == stage3`), and release engineering.

---

## 5. Official Brand & Mascot Kit ("Lumi — The Bioluminescent Crystal Chameleon")

| **Lumi Mascot Illustration** (`lume-mascot.jpg`) | **Chameleon Lambda Emblem** (`lume-chameleon-emblem.jpg`) | **App & IDE Icon** (`lume-icon.jpg` / `lume.ico`) | **Harmonized Vector Badge** (`lume-mascot-badge.svg`) |
| :---: | :---: | :---: | :---: |
| <img src="assets/lume-mascot.jpg" alt="Lumi Mascot" width="180" /> | <img src="assets/lume-chameleon-emblem.jpg" alt="Lume Chameleon Emblem" width="180" /> | <img src="assets/lume-icon.jpg" alt="Lume Icon" width="180" /> | <img src="assets/lume-mascot-badge.svg" alt="Lumi Vector Badge" width="160" /> |
| Full-body crystal chameleon mascot | Prismatic chameleon + $\lambda$ emblem | Official desktop & IDE icon | Transparent vector crest |
