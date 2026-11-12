<h1>
  <img src="assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="84" height="84" align="left" />
  Lume Sovereign Community — Official Charter, Working Groups &amp; Governance
</h1>

**Bilingual (`English` &amp; `Português pt-BR`) Global Community · Formal Verification &amp; Safety Engineers · Constant-Time Cryptography &amp; Systems Researchers · LumeLabs Working Groups**

<br clear="left"/>

<div align="center">

[![GitHub Discussions](https://img.shields.io/badge/GitHub%20Discussions-Join%20the%20Community-8b5cf6)](https://github.com/OmegaSoftDLL/lume/discussions)
[![Project Board #5](https://img.shields.io/badge/GitHub%20Project%20%235-Live%20Roadmap-00e5ff)](https://github.com/users/OmegaSoftDLL/projects/5)
[![LumeLabs R&D](https://img.shields.io/badge/LumeLabs-7%20Working%20Groups-00d2ff)](LUMELABS.md)
[![Wiki](https://img.shields.io/badge/GitHub%20Wiki-11%20Official%20Pages-10b981)](https://github.com/OmegaSoftDLL/lume/wiki)
[![Code of Conduct](https://img.shields.io/badge/Contributor%20Covenant-v2.1-success)](https://github.com/OmegaSoftDLL/lume/blob/main/CODE_OF_CONDUCT.md)

[**Home (`index.md`)**](index.md) · [**LumeLabs (`LUMELABS.md`)**](LUMELABS.md) · [**Projects & Roadmap (`PROJECTS.md`)**](PROJECTS.md) · [**Qualification Dossier (`PASS`)**](certification/QUALIFICATION_DOSSIER.md) · [**Wiki (`11` Pages)**](https://github.com/OmegaSoftDLL/lume/wiki) · [**GitHub Discussions**](https://github.com/OmegaSoftDLL/lume/discussions) · [**Contributing**](https://github.com/OmegaSoftDLL/lume/blob/main/CONTRIBUTING.md) · [**Support**](https://github.com/OmegaSoftDLL/lume/blob/main/SUPPORT.md) · [**Manual (`EN`)**](LUME_MANUAL_EN.md) · [**Manual (`PT-BR`)**](LUME_MANUAL_PT_BR.md)

<br/>

![Lume Sovereign Community & Official Social Banner](assets/lume-social-banner.jpg)

</div>

---

## 1. Welcome to the Lume Community (`EN` / `PT-BR`)

Welcome to the official community of **Lume (`v1.1.0`, Edition 2026)** — the 100% self-hosted Zero-C systems, AI, cyber-physical, and quantum programming language represented by our mascot **Lumi** (the Bioluminescent Crystal Chameleon).

Our community unites systems programmers, formal verification and high-assurance safety engineers (`DO-178C / DO-330`, `IEC 61508`, `ISO 26262`), cryptographers, AI/ML researchers, quantum algorithm designers, and financial infrastructure architects who believe software should be **written clearly by humans and AI, proven mathematically from source contracts down to machine code (`OmniProof-v4`, `ltv`, `lsmt`, `0/9,618` uncovered MC/DC), and compiled directly across 27 target architectures without external C/C++ toolchains**.

> 🇧🇷 **Boas-vindas à Comunidade Lume em Português (`pt-BR`):**
> A comunidade oficial da linguagem Lume é nativamente bilíngue (**Inglês** e **Português Brasileiro**). Você pode participar das [Discussões no GitHub](https://github.com/OmegaSoftDLL/lume/discussions), acompanhar o [Quadro Oficial `#5`](https://github.com/users/OmegaSoftDLL/projects/5) e o [**LumeLabs (`LUMELABS.md`)**](LUMELABS.md), explorar as [11 páginas oficiais da Wiki](https://github.com/OmegaSoftDLL/lume/wiki) e consultar o manual completo de 10 capítulos integrado ao compilador (`lume manual --pt` ou [`LUME_MANUAL_PT_BR.md`](LUME_MANUAL_PT_BR.md)).

---

## 2. Official Community Channels & GitHub Discussions Categories

All community conversations, design RFCs, proof clinics, and project showcases take place in [**GitHub Discussions (`OmegaSoftDLL/lume/discussions`)**](https://github.com/OmegaSoftDLL/lume/discussions):

| Category | Purpose | How to Participate |
| :--- | :--- | :--- |
| 📣 **Announcements** | Official Lume releases (`v1.1.0+`), security advisories, qualification updates, and LumeLabs graduations | Subscribe (`Watch -> Custom -> Discussions`) |
| 🦎 **LumeLabs R&D & RFCs** | Design proposals for compiler passes, `QF_LIA`/`QF_NIA` theorems, silicon HIL, and polyglot bridges | Open a discussion or [LumeLabs RFC Issue](https://github.com/OmegaSoftDLL/lume/issues/new/choose) |
| 🧮 **Proofs, `ltv` & Qualification Clinic** | Writing `requires`/`ensures`/`law`, `@bound` WCET, `@no_alloc` `[E0210]`, `@secret` `[C0009]`/`[C0011]`, `ltv`, and MC/DC | Share a minimal `.src` file and `lume prove` / `lume tv` output |
| 🌐 **Chameleon Polyglot Interop (`9` Ecosystems)** | Bridging C/C++ (`--preprocess`), Rust, Python DLPack, Node/WASM, Go, Java, .NET, SQL, and OpenAPI (`[I0003]`) | Share target ABI headers or `lume adapt` outputs |
| 🚀 **Show & Tell (`Feito com Lume`)** | Showcase verified apps, Ring-0 kernels, `2oo2D` split bundles, Win64 GUIs, 1.58-bit LLM routers & FinTech engines | Post your repository link, `.cert.json` summary, and benchmarks |
| 🇧🇷 **Comunidade Brasil (`pt-BR`)** | Discussões técnicas em português, FinTech Brasileira (`Pix`, `SEFAZ NF-e`, `CNPJ 2026`), Subsea/OT e IA Soberana | Converse diretamente em `pt-BR` |

---

## 3. LumeLabs Working Groups (WGs)

Contributors can join any of the **7 LumeLabs Working Groups** aligned with [`LUMELABS.md`](LUMELABS.md) and [`PROJECTS.md`](PROJECTS.md):

1. **WG-Polyglot (`Lab 01`):** Universal Chameleon 9-ecosystem FFI ([`compiler/stage1/lchameleon.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lchameleon.src)), C `--preprocess`, DLPack & Apache Arrow zero-copy bridges (`#29`), Singularity $\Omega$, and `LumePuter` weight-compiled VMs.
2. **WG-Edge-AI (`Lab 02`):** 1-Bit Bonsai / 1.58-Bit BitNet ternary inference, `Liquid AI LFM3` 24 kHz voice orchestration (`#29`), `Colibri` MoE SSD streaming ([`compiler/stage1/lume_llm_core.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lume_llm_core.src)), OpenTPU systolic MXU, and NCM.
3. **WG-Quantum (`Lab 03`):** Linear qubit type checking (`[Q0001]`–`[Q0004]`), ZX-calculus spider fusion, Clifford simulation, and `[[d^2, 1, d]]` surface-code QEC (`#30`, [`compiler/stage1/lume_quantum_nexus_engine.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lume_quantum_nexus_engine.src)).
4. **WG-Ring0-Hardware (`Lab 04`):** `KerneLume` bare-metal OS ([`examples/apps/lume_os/`](https://github.com/OmegaSoftDLL/lume/blob/main/examples/apps/lume_os)), SMP/IOMMU Ring-0 drivers (`#30`), `2oo2D` dual-MCU Cortex-M/RISC-V lockstep (`#32`), WCET `[V0002]`, and `Verilog`/`VHDL` RTL synthesis.
5. **WG-Formal-Assurance (`Lab 05`):** `OmniProof-v4` (`1,682` obligations), `lcaas.src`, `lcert.src --check-source`, symbolic translation validation (`ltv.src`, `ltv_rt.src`), clean-room `lsmt.src`, Masking MC/DC (`lmcdc.src`, `0/9,618` uncovered), `lqualify.src` (`PASS`), and Lean 4 mechanization (`#30`, `.lean` obligation certificates emitted by [`compiler/stage1/ltv.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/ltv.src)).
6. **WG-GUI-CyberPhysical (`Lab 06`):** Clean Generic Win64 Native GUI (`--target x86_64-windows-gui`), conservation-proven `@ui-layout`, 7-DOF robotics / Subsea / EKF (`gfx.src`), and Ed25519-governed autonomous evolution (`levolve.src`).
7. **WG-Crypto-FinTech-OT (`Lab 07`):** `118` `@secret @no_alloc` `[C0011]` constant-time cryptographic kernels (`[C0009]` taint + `[C0010]` `ltv` + `dudect` in [`lcrypto_tls.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lcrypto_tls.src)), Ed25519 X.509v3 PKI ([`lx509.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lx509.src)), PKCS#11/HSM custody (`#32`), IEC 62443 OT & Omega-Mesh (`net.src`), binary recovery (`lume_reversa_engine.src`), and verified financial infrastructure (`decimal`, `Pix`, `SEFAZ`, `zero_breach_forensics`).

---

## 4. Contribution & Recognition Ladder

Every contribution to Lume follows our [**Engineering & Verification Standard (`CONTRIBUTING.md`)**](https://github.com/OmegaSoftDLL/lume/blob/main/CONTRIBUTING.md):

1. **Explorer:** Installs Lume, verifies all **`134` SHA-256 manifest files** (`lume self verify`) and **`OmniProof-v4`** (`lume self-prove`), participates in Discussions, or files minimal `.src` reproducers.
2. **Verified Contributor:** Merges a pull request written 100% in pure Lume (`.src`, pure LF `\n`, zero tabs, formatted via `lume fmt --check`) with static proofs (`lume prove` + `lume certify`), `0` CLI parity drift (`lume cli-parity`), and unit/negative regression tests.
3. **LumeLabs Fellow:** Authors or co-maintains a LumeLabs Research Division subsystem, post-codegen binary verifier, or certified capstone application (`examples/apps/*`).
4. **Core Maintainer:** Stewards the self-hosted compiler pipeline (`compiler/stage1/lume/01_lexer.src` .. `07_driver.src`), triple-bootstrap fixpoint (`lumec1 == lumec2 == lumec3`), signed qualification dossier (`lume qualify`), and multi-platform release engineering.

---

## 5. Official Brand & Mascot Kit ("Lumi — The Bioluminescent Crystal Chameleon")

All official Lume visual identity assets are available in `assets/` and `docs/assets/`:

| **Lumi Mascot Illustration** (`lume-mascot.jpg`) | **Chameleon Lambda Emblem** (`lume-chameleon-emblem.jpg`) | **App & IDE Icon** (`lume-icon.jpg` / `lume.ico`) | **Harmonized Vector Badge** (`lume-mascot-badge.svg`) |
| :---: | :---: | :---: | :---: |
| <img src="assets/lume-mascot.jpg" alt="Lumi Mascot" width="180" /> | <img src="assets/lume-chameleon-emblem.jpg" alt="Lume Chameleon Emblem" width="180" /> | <img src="assets/lume-icon.jpg" alt="Lume Icon" width="180" /> | <img src="assets/lume-mascot-badge.svg" alt="Lumi Vector Badge" width="160" /> |
| Full-body crystal chameleon mascot | Prismatic chameleon + $\lambda$ emblem | Official desktop & IDE icon | Transparent vector crest |

---

## 6. Code of Conduct & Security

- All community spaces are governed by our [**Contributor Covenant Code of Conduct (`CODE_OF_CONDUCT.md`)**](https://github.com/OmegaSoftDLL/lume/blob/main/CODE_OF_CONDUCT.md).
- Security vulnerabilities must be reported privately via [**GitHub Security Advisories (`SECURITY.md`)**](https://github.com/OmegaSoftDLL/lume/blob/main/SECURITY.md).
