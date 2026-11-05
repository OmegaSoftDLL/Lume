# Lume — The AI-First & Human-Friendly Programming Language (`v1.0.0`)

**Written by AI & Humans · Mathematically Proven by Compiler · 100% Self-Hosted Zero-C Steady State (`stage2 == stage3`)**

> **Official Production Status (`v1.0.0` — Edition 2026): 100% Complete & Verified.**
> All language phases (**Phases 0–5**), **Inflection Stages A–D**, **Waves 1–10**, **10/10 Developer Ergonomics**, **27 Universal Targets**, the **Sovereign Quantum Nexus Engine**, **KerneLume Bare-Metal OS**, and **12 Reference Architecture Engines** are implemented in 100% self-hosted Lume (`stage2 == stage3` bit-identical in ~3.8s), passing **24/24 Acceptance Matrix claims (`0 UNKNOWN`, `0 FAIL`)** and **14/14 Embedded Compiler Proof Batteries (`396` formal obligations, `134` unit tests, `98` SHA-256 verified files)**.

---

## Official Installation (`v1.0.0` — Linux, macOS & Windows)

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

All 6 official prebuilt Zero-C release archives are available at [**GitHub Releases (`v1.0.0`)**](https://github.com/OmegaSoftDLL/lume/releases/tag/v1.0.0):

| Platform / Architecture | Official Archive (`v1.0.0`) | SHA-256 Digest |
| :--- | :--- | :--- |
| **Linux x86_64 (ELF64)** | [`lume-v1.0.0-linux-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-x86_64.tar.gz) | `03b6c910b78024a0776b519a1cc4aa2062b796a90c50dff561dd75df922c161f` |
| **Linux ARM64 (`aarch64` ELF64)** | [`lume-v1.0.0-linux-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-aarch64.tar.gz) | `cef3671b60dd674f7601b3206dfb986a321f1780a33257bfc32d39ff53fdba1e` |
| **Linux RISC-V (`riscv64` ELF64)** | [`lume-v1.0.0-linux-riscv64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-riscv64.tar.gz) | `d18f9c31b52baaab32316b19a6da0f1d5108fcacde63e1f57a1f7080c7df104b` |
| **macOS Apple Silicon (`aarch64` Mach-O 64)** | [`lume-v1.0.0-macos-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-aarch64.tar.gz) | `f1bcc77c60f628f747867c6ee170ba6de79edc60601550a34b9cb51c52c8bb07` |
| **macOS Intel (`x86_64` Mach-O 64)** | [`lume-v1.0.0-macos-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-x86_64.tar.gz) | `e44e832d9e87e4326e6f1705f85035542b249b11d167667e3f362af64dcbdebe` |
| **Windows x86_64 (`PE32+`)** | [`lume-v1.0.0-windows-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-windows-x86_64.tar.gz) | `2f705bfd8f2850f9e5abdb7a6bae83ea94046bddccdf6ed73dae46a74d02290e` |
| **Unified Checksums** | [`SHA256SUMS`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/SHA256SUMS) | Verifies all archives & standalone binaries |

#### Manual Install on Linux or macOS
```sh
PLAT="linux-x86_64" # or: macos-aarch64, macos-x86_64, linux-aarch64, linux-riscv64
mkdir -p "$HOME/.lume"
curl -fsSL "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-${PLAT}.tar.gz" -o /tmp/lume.tar.gz
tar -xzf /tmp/lume.tar.gz -C "$HOME/.lume"
export PATH="$HOME/.lume/bin:$PATH"
lume self verify
```

#### Manual Install on Windows (PowerShell)
```powershell
New-Item -ItemType Directory -Force "$HOME\.lume" | Out-Null
Invoke-WebRequest -Uri "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-windows-x86_64.tar.gz" -OutFile "$env:TEMP\lume-win64.tar.gz"
tar -xzf "$env:TEMP\lume-win64.tar.gz" -C "$HOME\.lume"
$env:PATH = "$HOME\.lume\bin;$env:PATH"
lume --version
```

---

## 30-Second Quickstart & Built-In Manual

```sh
lume manual                      # Built-in 10-chapter Programmer's Manual (English)
lume manual --pt                 # Manual Interno Completo em Portugues (pt-BR)
lume run examples/01_hello.lume  # Run a program
lume prove <file.src>            # Prove requires/ensures/law contracts (QF_LIA + QF_NIA)
lume certify <file.src>          # Emit standalone Lume Verified proof certificate
lume build <file.src> -o app     # Compile standalone native binary (Zero-C)
lume self-prove                  # Run all 14 embedded compiler proof batteries
```

---

## Complete Documentation & Architecture Index

### Manuals & Complete Status Reports
- [**Repository & Overview (`README.md`)**](https://github.com/OmegaSoftDLL/lume) — Quickstart, 10/10 DX showcase, 27 targets, and sovereign engines.
- [**Lume `v1.0.0` Technical Paper (`LUME_TECHNICAL_PAPER.md`)**](LUME_TECHNICAL_PAPER.md) — Engineering deep dive on the `stage2 == stage3` Zero-C bootstrap, `QF_LIA` verification, and native code generation.
- [**English Programmer's Manual (10 Chapters)**](LUME_MANUAL_EN.md) · [**Manual do Programador em Português (`pt-BR`, 10 Capítulos)**](LUME_MANUAL_PT_BR.md)
- [**Complete Phases (0–5), Stages (A–D) & Waves (1–10) Reference**](PHASES_AND_WAVES_COMPLETE.md)
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
- [06 — P33 Software Protection & Anti-REA](06-software-protection.md) · [20 — Fail-Closed C/WASM Interop](20-interop.md)
- [35 — Bounded Economic Benchmark](35-economic-benchmark.md) · [36 — Verified Component Registry](36-verified-component-registry.md) · [37 — Portable Renewable Evidence](37-portable-renewable-evidence.md)

### Reference Surveys
- [00 — Catalog of ~260 Languages](00-catalog.md) · [01 — Language Survey](01-survey.md) · [07 — Competitive Scan](07-competitive.md)

---

## Contributors

| Contributor | Role & Focus |
| :--- | :--- |
| **[Ricardo Bueno (`@OmegaSoftDLL`)](https://github.com/OmegaSoftDLL)** | Creator, Language Architect & Principal Systems Engineer |
| **[Claude (`@claude`)](https://github.com/claude)** | Self-Hosted Compiler, Formal Verification (`QF_LIA` / `QF_NIA` / Separation Logic) & Runtime Engineering |
| **[Kimi (`@kimi-ai` / `@MoonshotAI`)](https://github.com/kimi-ai)** | Phase 0 Consolidation, Incremental Module Cache, Memory Arenas & Conformance Engineering |
| **[AGY — Google Antigravity (`@antigravity-bot` / `@google-deepmind`)](https://github.com/antigravity-bot)** | Compiler Performance Optimization, Multi-Platform Release Packaging & Autonomous Verification |

---

*Dual-licensed under **MIT OR Apache-2.0**. Source repository: [`https://github.com/OmegaSoftDLL/lume`](https://github.com/OmegaSoftDLL/lume).*
