<link rel="icon" type="image/svg+xml" href="favicon.svg" />
<link rel="icon" type="image/png" sizes="512x512" href="favicon.png" />
<link rel="alternate icon" type="image/x-icon" href="favicon.ico" />
<link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png" />

<h1>
  <img src="assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="84" height="84" align="left" />
  Lume — The AI-First &amp; Human-Friendly Programming Language (<code>v1.1.0</code>)
</h1>

**Written by AI &amp; Humans · Mathematically Proven by Compiler (`QF_LIA` / `QF_NIA` / `lcert`) · 9-Ecosystem Chameleon Polyglot FFI · 100% Self-Hosted Zero-C Steady State (`stage2 == stage3`)**

<br clear="left"/>

[**Install**](#official-installation-v110--linux-macos--windows) · [**Quickstart**](#30-second-quickstart--built-in-manual) · [**LumeLabs (`LUMELABS.md`)**](LUMELABS.md) · [**Projects & Roadmap (`PROJECTS.md`)**](PROJECTS.md) · [**Community (`COMMUNITY.md`)**](COMMUNITY.md) · [**Wiki**](https://github.com/OmegaSoftDLL/lume/wiki) · [**GitHub Discussions**](https://github.com/OmegaSoftDLL/lume/discussions) · [**Manual (`EN`)**](LUME_MANUAL_EN.md) · [**Manual (`PT-BR`)**](LUME_MANUAL_PT_BR.md) · [**Audit Report (`85/85`)**](LUME_REMEDIATION_AND_REDTEAM_REPORT.md)

![Lume v1.1.0 Live Programming, Formal Verification & 27-Target Native Compilation](assets/lume-hero-animated.svg)

> **Official Production Status (`v1.1.0` — Edition 2026): 100% Complete & Verified.**
> All language phases (**Phases 0–5**), **Inflection Stages A–D**, **Waves 1–12**, **10/10 Developer Ergonomics**, **Universal Chameleon Polyglot Interop Engine (`9` Ecosystems, `[I0003]`)**, **27 Universal Targets**, the **Sovereign Quantum Nexus Engine**, **KerneLume Bare-Metal OS**, and **17 Verified Domain Engines** are implemented in 100% self-hosted Lume (`stage2 == stage3` bit-identical in ~3.8s), passing **24/24 Acceptance Matrix claims (`0 UNKNOWN`, `0 FAIL`)**, **85/85 Claude Opus 5.5 + Red Team (R1, R2 & R3) Audit Checks**, and **15/15 Embedded Compiler Proof Batteries (`413` formal obligations, `141` unit tests, `99` SHA-256 verified files)**.

---

## Universal Chameleon Polyglot Interop Engine (`lchameleon.src` — 9 Ecosystems)

![Lume Universal Chameleon Polyglot Interop Engine — 9 Verified Ecosystems](assets/lume-chameleon-showcase.svg)

Lume's **Universal Chameleon Polyglot Interop Engine** (`lume chameleon`, `lume camaleao`, `lume polyglot`, `lume ffi-bridge`, `lume adapt <eco>`, `lume morph <file>`) bridges **9 verified ecosystems** (`c_abi`, `rust_cdylib`, `python_capi` with DLPack zero-copy tensors, `node_napi_wasm`, `go_cshared`, `java_jni`, `dotnet_pinvoke`, `sql_relational`, and `openapi_rpc`) through fail-closed **`[I0003]` `QF_LIA` refinement contracts** (`unverified[T] -> verified[T]` under `/ {ffi}`, `28/28` proven obligations, `8/8` unit tests).

---

## Official Installation (`v1.1.0` — Linux, macOS & Windows)

### 1. One-Command Official Installer (Linux `x86_64`/`aarch64`/`riscv64`, macOS Apple Silicon `aarch64` & Intel `x86_64`, Windows Git Bash / WSL2)

Install via the GitHub Pages official installer or directly from GitHub Releases (verifies `SHA256SUMS` and `MANIFEST.sha256` automatically before activation):

```sh
curl -fsSL https://omegasoftdll.github.io/lume/install.sh | sh
export PATH="$HOME/.lume/bin:$PATH"
lume self verify
lume self-prove
```

Or directly from the latest GitHub Release asset:

```sh
curl -fsSL https://github.com/OmegaSoftDLL/lume/releases/latest/download/install.sh | sh
export PATH="$HOME/.lume/bin:$PATH"
lume --version
```

### 2. Direct Platform Archive Download & SHA-256 Verification

All 6 official prebuilt Zero-C release archives are available at [**GitHub Releases (`v1.1.0`)**](https://github.com/OmegaSoftDLL/lume/releases/tag/v1.1.0):

| Platform / Architecture | Official Archive (`v1.1.0`) |
| :--- | :--- |
| **Linux x86_64 (ELF64)** | [`lume-v1.1.0-linux-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-x86_64.tar.gz) |
| **Linux ARM64 (`aarch64` ELF64)** | [`lume-v1.1.0-linux-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-aarch64.tar.gz) |
| **Linux RISC-V (`riscv64` ELF64)** | [`lume-v1.1.0-linux-riscv64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-riscv64.tar.gz) |
| **macOS Apple Silicon (`aarch64` Mach-O 64)** | [`lume-v1.1.0-macos-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-aarch64.tar.gz) |
| **macOS Intel (`x86_64` Mach-O 64)** | [`lume-v1.1.0-macos-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-x86_64.tar.gz) |
| **Windows x86_64 (`PE32+`)** | [`lume-v1.1.0-windows-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-windows-x86_64.tar.gz) |
| **Unified Checksums** | [`SHA256SUMS`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/SHA256SUMS) |

#### Manual Install on Linux or macOS
```sh
PLAT="linux-x86_64" # or: macos-aarch64, macos-x86_64, linux-aarch64, linux-riscv64
mkdir -p "$HOME/.lume"
curl -fsSL "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-${PLAT}.tar.gz" -o /tmp/lume.tar.gz
tar -xzf /tmp/lume.tar.gz -C "$HOME/.lume"
export PATH="$HOME/.lume/bin:$PATH"
lume self verify
```

#### Manual Install on Windows (PowerShell)
```powershell
New-Item -ItemType Directory -Force "$HOME\.lume" | Out-Null
Invoke-WebRequest -Uri "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-windows-x86_64.tar.gz" -OutFile "$env:TEMP\lume-win64.tar.gz"
tar -xzf "$env:TEMP\lume-win64.tar.gz" -C "$HOME\.lume"
$env:PATH = "$HOME\.lume\bin;$env:PATH"
lume --version
```

---

## 30-Second Quickstart & Built-In Manual

```sh
lume manual                      # Built-in 10-chapter Programmer's Manual (English)
lume manual --pt                 # Manual Interno Completo em Portugues (pt-BR)
lume manual chameleon            # Universal Chameleon Polyglot Interop Engine (EN)
lume manual --pt camaleao        # Motor Universal Camaleao Poliglota (pt-BR)
lume chameleon                   # Inspect all 9 verified polyglot ecosystems & [I0003] status
lume run examples/01_hello.lume  # Run a program
lume prove <file.src>            # Prove requires/ensures/law contracts (QF_LIA + QF_NIA)
lume certify <file.src>          # Emit standalone Lume Verified proof certificate
lume build <file.src> -o app     # Compile standalone native binary (Zero-C)
lume self-prove                  # Run all 15 embedded compiler proof batteries (413 obligations)
```

---

## Complete Documentation & Architecture Index

### Manuals & Complete Status Reports
- [**Repository & Overview (`README.md`)**](https://github.com/OmegaSoftDLL/lume) — Quickstart, 10/10 DX showcase, 9-ecosystem Chameleon FFI, 27 targets, and sovereign engines.
- [**Lume `v1.1.0` Technical Paper (`LUME_TECHNICAL_PAPER.md`)**](LUME_TECHNICAL_PAPER.md) — Engineering deep dive on the `stage2 == stage3` Zero-C bootstrap, `QF_LIA` verification, 4-Tier Atomic Memory Compactor, and native code generation.
- [**Claude Opus 5.5 Audit & Red Team Remediation Report (`EN`)**](LUME_REMEDIATION_AND_REDTEAM_REPORT.md) · [**Relatório Completo de Auditoria e Red Team (`pt-BR`)**](LUME_REMEDIATION_AND_REDTEAM_REPORT_PT_BR.md)
- [**Memory Saga & 4-Tier Atomic Compactor Dossier (`EN`)**](39-memory-saga-and-atomic-compactor-dossier.md) · [**Dossiê da Saga da Memória (`pt-BR`)**](LUME_MEMORY_SAGA_DOSSIER_PT_BR.md)
- [**English Programmer's Manual (10 Chapters)**](LUME_MANUAL_EN.md) · [**Manual do Programador em Português (`pt-BR`, 10 Capítulos)**](LUME_MANUAL_PT_BR.md)
- [**Complete Phases (0–5), Stages (A–D) & Waves (1–12) Reference**](PHASES_AND_WAVES_COMPLETE.md)
- [**Project Engineering State & Laws (`PROJECT_STATE.md`)**](PROJECT_STATE.md)
- [**12 GitHub Reference Architectures & Innovations Report**](GITHUB_REFERENCE_INNOVATIONS_REPORT.md)
- [**Track A/L Acceptance Matrix (`24/24 PASS`)**](acceptance-matrix.md)

### Wave-by-Wave Line-by-Line Audit Registry
- [Wave 1 Audit](WAVE_01_AUDIT.md) · [Wave 2 Audit](WAVE_02_AUDIT.md) · [Wave 3 Audit](WAVE_03_AUDIT.md) · [Wave 4 Audit](WAVE_04_AUDIT.md) · [Wave 5 Audit](WAVE_05_AUDIT.md)
- [Wave 6 Audit](WAVE_06_AUDIT.md) · [Wave 7 Audit](WAVE_07_AUDIT.md) · [Wave 8 Audit](WAVE_08_AUDIT.md) · [Wave 9 Audit](WAVE_09_AUDIT.md) · [Wave 10 Audit](WAVE_10_AUDIT.md)

### Language Specification, Vision & Self-Hosting
- [05 — Vision](05-vision.md) · [02 — Principles (P1–P35)](02-principles.md) · [03 — Specification](03-specification.md)
- [08 — AI-First Architecture](08-ai-first.md) · [30 — The Lume Book](30-lume-book.md) · [32 — AI Authoring Guide](32-ai-authoring.md)
- [11 — Self-Hosting Plan](11-self-hosting-plan.md) · [14 — Zero-C Steady State](14-zero-c.md) · [04 — Roadmap (Stages 0–5)](04-roadmap.md)

### Phases 3–5, Targets, Verification & Security
- [16 — Phase 3 Plan (Ownership, Effects, Concurrency, Verification)](16-phase3-plan.md) · [21 — Inflection Plan (Stages A–D)](21-inflection-plan.md)
- [24 — Phase 4 Plan (Tensors, Autodiff, GPU Kernels, Neuro/Prob)](24-phase4-plan.md) · [25 — Phase 5 Plan (Systems, Kernels, Bare-Metal OS)](25-phase5-plan.md)
- [19 — Intent as Source & Compiler as Oracle](19-intent-as-source.md) · [26 — 27 Universal Targets](26-targets.md)
- [06 — P33 Software Protection & Anti-REA](06-software-protection.md) · [20 — Fail-Closed C/WASM/Chameleon Interop](20-interop.md)
- [35 — Bounded Economic Benchmark](35-economic-benchmark.md) · [36 — Verified Component Registry](36-verified-component-registry.md) · [37 — Portable Renewable Evidence](37-portable-renewable-evidence.md)

### Reference Surveys
- [00 — Catalog of ~260 Languages](00-catalog.md) · [01 — Language Survey](01-survey.md) · [07 — Competitive Scan](07-competitive.md)

---

## Contributors & AI-Assisted Engineering Co-Pilots

| Contributor | Role & Focus |
| :--- | :--- |
| **[Ricardo Bueno (`@OmegaSoftDLL`)](https://github.com/OmegaSoftDLL)** | Creator, Language Architect & Principal Systems Engineer |
| **Claude (AI-Assisted Engineering & Formal Verification Co-Pilot)** | Self-Hosted Compiler, Formal Verification (`QF_LIA` / `QF_NIA` / Separation Logic) & Runtime Engineering |
| **Kimi (AI-Assisted Engineering & Conformance Co-Pilot)** | Phase 0 Consolidation, Incremental Module Cache, Memory Arenas & Conformance Engineering |
| **AGY — Antigravity (AI-Assisted Engineering & Autonomous Verification Co-Pilot)** | Compiler Performance Optimization, Multi-Platform Release Packaging & Autonomous Verification |

---

*Licensed under **Apache-2.0**. Source repository: [`https://github.com/OmegaSoftDLL/lume`](https://github.com/OmegaSoftDLL/lume).*
