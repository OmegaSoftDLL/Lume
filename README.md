<div align="center">

# Lume

### **Self-Hosted, Formally Verified Systems, AI, and Quantum Programming Language**
*Mathematically Proven by Compiler · Self-Hosted Zero-C Steady State (`stage2 == stage3`) · 27 Target Architectures*

[![CI](https://github.com/OmegaSoftDLL/lume/actions/workflows/ci.yml/badge.svg)](https://github.com/OmegaSoftDLL/lume/actions/workflows/ci.yml)
[![Release](https://img.shields.io/badge/release-v1.1.0-blue)](https://github.com/OmegaSoftDLL/lume/releases/tag/v1.1.0)
[![Zero-C Steady State](https://img.shields.io/badge/steady--state-100%25%20Lume%20%28Zero--C%29-success)](docs/PROJECT_STATE.md)
[![Acceptance Matrix](https://img.shields.io/badge/acceptance%20matrix-24%2F24%20PASS-brightgreen)](docs/acceptance-matrix.md)
[![Red Team & Claude Audit](https://img.shields.io/badge/Claude%20%2B%20Red%20Team%20Audit-85%2F85%20Remediated-brightgreen)](docs/LUME_REMEDIATION_AND_REDTEAM_REPORT.md)
[![Targets](https://img.shields.io/badge/targets-27%20architectures-orange)](docs/26-targets.md)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-green.svg)](#license)

[**Installation**](#installation--terminal-setup-lume-command) · [**Quickstart**](#quickstart) · [**Claude & Red Team Audit (`EN` / `PT-BR`)**](docs/LUME_REMEDIATION_AND_REDTEAM_REPORT.md) · [**Memory Saga (`31.8×`)**](#memory-saga--4-tier-atomic-memory-compactor-evolution) · [**Memory Dossier (`EN` / `PT-BR`)**](docs/39-memory-saga-and-atomic-compactor-dossier.md) · [**Technical Paper (`v1.1.0`)**](docs/LUME_TECHNICAL_PAPER.md) · [**Language Ergonomics**](#language-ergonomics--core-syntax) · [**Built-In Manual (`EN` / `PT-BR`)**](#built-in-bilingual-programmers-manual) · [**Architecture & Verification**](#architecture--verification-matrix) · [**27 Compilation Targets**](#27-universal-targets--packagers) · [**Domain Engines**](#verified-domain--quantum-engines)

<br/>

![Lume v1.1.0 Live Programming, Formal Verification & 27-Target Native Compilation](docs/assets/lume-hero-animated.svg)

</div>

---

## Overview

**Lume (`v1.1.0`, Edition 2026)** is a statically typed, formally verified systems, artificial intelligence, and quantum programming language. Its entire production toolchain is written in Lume itself and operates in a verified **Zero-C steady state**:

- **Self-Hosted Fixpoint (`stage2 == stage3`):** The compiler (`lumec`), machine-code assembler and binary linker (`lasm`), module bundler (`lmod`), theorem prover (`lcaas`), independent proof certificate kernel (`lcert`), formatter (`lfmt`), test runner (`ltest`), and unified CLI driver (`lume_driver` + `lcli`) compile themselves bit-for-bit (`0 diff`) in **~3.8 seconds** without any external C compiler, assembler (`as`), or linker (`ld`).
- **Sound Compile-Time Verification (`QF_LIA`, `QF_NIA`, `QF_BV`, Separation Logic):** Built-in Fourier-Motzkin linear integer arithmetic solver with cutting-plane tightening, nonlinear Positivstellensatz and shifted bilinear monotonicity, bitvector verification, Separation Logic heap frame reasoning, `[K0005]` W^X DMA protection, `[K0006]` kernel stack bounds, `[C0009]` constant-time cryptographic side-channel analysis, and standalone certificate checking via `lcert`.
- **Expressive Functional & Systems Ergonomics:** Combines affine ownership (`own`, `mut`, region-tracked borrows, Perceus in-place reuse, and scoped bump arenas) with layout-sensitive or braced pattern matching, `f"...{expr}..."` string interpolation, left-associative `|>` pipe operators, `{ record with field: value }` functional updates, top-level `const` declarations, and tuple/record/ADT destructuring.
- **24/24 Acceptance Matrix (`0 UNKNOWN`, `0 FAIL`) & 15 Embedded Verification Batteries (`lume self-prove`):** Every subsystem — including B+Tree ACID WAL storage, RFC 8446 TLS 1.3, X11/Web/Win64 GUI, Universal Chameleon 9-ecosystem polyglot FFI (`lchameleon.src`), industrial telemetry (`Modbus`, `DNP3`, `IEC 60870-5-104`, `IEC 61850`, `ANSI` protection relays), 2D/3D software rendering, differentiable tensor/GPU kernels, quantum circuit synthesis (`OpenQASM 3.0`, `QIR`, `Quil`, `IQM`, `Stim`), and the freestanding `lume-os` microkernel — is verified continuously in CI (`413` formal obligations, `141` unit tests, `99` verified manifest files).

---

## Memory Saga & 4-Tier Atomic Memory Compactor Evolution

<div align="center">

![Lume Memory Saga & 4-Tier Atomic Memory Compactor Evolution](docs/assets/lume-memory-evolution-animated.svg)

📄 **[Read the Complete Benchmark & Architecture Dossier (English)](docs/39-memory-saga-and-atomic-compactor-dossier.md)** · 🇧🇷 **[Ler o Dossiê Completo da Saga da Memória (Português `pt-BR`)](docs/LUME_MEMORY_SAGA_DOSSIER_PT_BR.md)** · ⚙️ **[Runtime & Collector Spec](docs/38-memory-management.md)**

</div>

Lume's native x86-64 runtime ([`compiler/stage1/runtime_core.lume`](compiler/stage1/runtime_core.lume)) combines a **43-size-class segregated Mark & Lazy-Sweep Collector** (`MADV_DONTNEED` physical page release), **Rust-grade Ownership v2 & proven-unique Perceus reuse** ([`compiler/stage1/own_flow.src`](compiler/stage1/own_flow.src)), and a **4-Tier Atomic Memory Compactor**:

1. **Stage 0 — Content-Addressed `.rodata` Literals & Zero-Arity Singletons:** Deduplicated immutable string literals, constructor descriptors, and shared `Nil`/`None` singletons (`0 B` heap cost, eliminating `285 MB` of repeated `mkstr` allocations during self-compilation).
2. **Level 1 — 64-Bit Tagged Register Word (`0–1` Cycle Pack/Unpack):**
   - `...iiii1`: 63-bit signed integers unboxed directly inside the 64-bit register word (`0 B` heap; values using the 64th bit transparently spill to a `16 B` cell, and overflow past 64 bits traps via hardware `jo __rt_ovf`).
   - `...ss|lll|010`: Short strings up to **7 UTF-8 bytes (`at`, `chr`, identifiers, tokens) packed inline inside the 64-bit word (`0 B` heap)** — outperforming Rust's `String` (`24 B` + heap allocation) and eliminating `74.9%–94.9%` of dynamic short string allocations.
3. **Level 2 — Compact ADT Cells & Shared-Shape Records:** `Cons(int, tail)` shrunk from `80 B` to **`24 B`** (`-70%`); 3-field records shrunk from `160 B` to **`32 B`** (`-80%`) with interned field keys (`cmpq` pointer equality instead of `streq`).
4. **Level 3 — Cold Arena Demand-Paged `LZ1` Compactor (`mem_pack`, `arena_freeze`, `.lcaps`/`.lumb`):** Compresses cold arenas and bytecode/capsule blobs at **`~355 MB/s` pack / `~975 MB/s` unpack** with a 64-bit integrity checksum (verified against `1,500` corrupted fuzz blobs), **transparent lazy page thaw on first touch (`PROT_NONE` + `SIGSEGV` page restoration)**, and fail-closed rejection on `@secret` data (`[C0009]` *Decomp+Time* defense) and `@bound` WCET functions (`[V0002]`).

### Complete 3-Generation Benchmark Evolution Matrix (Intel Core Ultra 5 135U, WSL2 x86-64)

| Workload | Gen 1: Baseline | Gen 2: Round 5 (GC + Own v2) | **Gen 3: Round 6 (Atomic Compactor)** | Speedup & Allocs | RAM Reduction |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **`b_loop` (`100M` iters)** | `4,800 MB` | `2,796 ms` · `68 MB` (`200M`) | **`88 ms` · `0.39 MB` (`1` alloc!)** | **`31.8×` · `-99.9999%` allocs** | **`174×` (`-99.4%`)** |
| **Full C Seed Bootstrap** | `194.8 s` · `12.7 GB` | `200.0 s` · `2.5 GB` | **`22.0 s` · `537 MB`** | **`9.0×` faster chain** | **`23.6×` (`-95.8%`)** |
| **Seed $\rightarrow$ `lumec.src`** | `102.0 s` · `12.5 GB` | `5.5 s` · `472 MB` | **`5.5 s` · `472 MB`** | **`18.5×` faster** | **`26.5×` (`-96.2%`)** |
| **`lumec` (`stage2 == 3`)** | `1,820 ms` · `1,165 MB` | `1,908 ms` · `228 MB` | **`445 ms` · `115 MB` (`1.01 MB` ELF)** | **`4.3×` · ELF `-34%`** | **`10.1×` (`-90.1%`)** |
| **`b_rec` (`20M` 3-field)** | `6,000 MB` | `3,270 ms` · `67 MB` (`240M`) | **`429 ms` · `66 MB` (`20M` allocs)** | **`7.6×` · `12×` fewer allocs** | **64 MiB GC cap** |
| **`b_match` (`20M` ADT)** | Unbounded | `1,617 ms` · `72 MB` (`80M`) | **`235 ms` · `68 MB` (`20M` allocs)** | **`6.9×` · `4×` fewer allocs** | **64 MiB GC cap** |
| **`b_list` (`30M` `Cons`)** | Unbounded | `2,747 ms` · `239 MB` (`180M`) | **`480 ms` · `67 MB` (`30M` allocs)** | **`5.7×` · `6×` fewer allocs** | **`3.6×` (`-72%`)** |
| **`b_str` (Strings)** | `5,090 ms` · `6.0 GB` | `679 ms` · `74 MB` (`42.6M`) | **`131 ms` · `2.2 MB` (`17` allocs!)** | **`5.2×` (`38.8×` vs Gen 1)** | **`2,733×` (`-99.96%`)** |
| **`b_fib` (`fib(38)`)** | `1,190 ms` | `1,042 ms` | **`273 ms`** | **`3.8×` (`4.4×` vs Gen 1)** | **`0 B` heap** |
| **410-Test Suite** | `> 600 s` · `12.7 GB` | `529 s` · `2.49 GB` (`404`) | **`136 s` · `537 MB` (`410/410`)** | **`3.9×` (`0` fail)** | **`23.6×` (`-95.8%`)** |

---

## Installation & Terminal Setup (`lume` Command)

### 1. Linux, macOS & WSL (Bash / Zsh)

Run the one-line installer and register `~/.lume/bin` permanently in your shell profile so typing `lume` works directly in every terminal window:

```sh
curl -fsSL https://github.com/OmegaSoftDLL/lume/releases/latest/download/install.sh | sh

# Enable `lume` immediately in current terminal + permanently in ~/.bashrc and ~/.zshrc
export PATH="$HOME/.lume/bin:$PATH"
grep -qxF 'export PATH="$HOME/.lume/bin:$PATH"' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.lume/bin:$PATH"' >> ~/.bashrc
[ -f ~/.zshrc ] && (grep -qxF 'export PATH="$HOME/.lume/bin:$PATH"' ~/.zshrc || echo 'export PATH="$HOME/.lume/bin:$PATH"' >> ~/.zshrc)

# Verify installation
lume --version
lume self verify
lume self-prove
```

### 2. Homebrew (macOS Apple Silicon, macOS Intel & Linux)

```sh
brew install OmegaSoftDLL/lume/lume
lume --version
```

### 3. Windows x64 (PowerShell — Direct `lume` Command)

Download the release archive and add `$HOME\.lume\bin` to your **persistent Windows User `PATH`** so you can type `lume` directly in any PowerShell or Command Prompt window:

```powershell
# 1. Download and extract Lume v1.1.0 to $HOME\.lume
Invoke-WebRequest -Uri "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-windows-x86_64.tar.gz" -OutFile "lume-win64.tar.gz"
mkdir "$HOME\.lume" -Force | Out-Null
tar -xzf lume-win64.tar.gz --strip-components=1 -C "$HOME\.lume"

# 2. Add $HOME\.lume\bin to current session AND permanently to your Windows User PATH
$lumeBin = "$HOME\.lume\bin"
$env:PATH = "$lumeBin;$env:PATH"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$lumeBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$lumeBin;$userPath", "User")
}

# 3. Run `lume` directly from PowerShell!
lume --version
lume self verify
lume evolve list
```

### 4. Official Prebuilt Archives (`v1.1.0`)

| Platform / Architecture | Archive |
| :--- | :--- |
| **Linux x86-64** | [`lume-v1.1.0-linux-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-x86_64.tar.gz) |
| **Linux ARM64 (`aarch64`)** | [`lume-v1.1.0-linux-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-aarch64.tar.gz) |
| **Linux RISC-V 64 (`riscv64`)** | [`lume-v1.1.0-linux-riscv64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-riscv64.tar.gz) |
| **macOS Apple Silicon (`M1/M2/M3/M4`)** | [`lume-v1.1.0-macos-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-aarch64.tar.gz) |
| **macOS Intel (`x86_64`)** | [`lume-v1.1.0-macos-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-x86_64.tar.gz) |
| **Windows x64 (`PE32+`)** | [`lume-v1.1.0-windows-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-windows-x86_64.tar.gz) |
| **SHA-256 Checksums** | [`SHA256SUMS`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/SHA256SUMS) |

### 5. Teach Your AI Assistant to Program in Lume (`skills/lume`)

Lume ships with an official, self-contained **AI Agent Skill ([`skills/lume/`](skills/lume/SKILL.md))** compatible with **Antigravity (AGY)**, **Claude Code**, **Cursor**, **Codex**, **Windsurf**, and **`skills.sh`**. Once installed, your AI coding agent immediately knows how to write, prove (`lume prove`), certify (`lume certify`), compile (`lume build`), and evolve (`lume consult`, `lume evolve`, `lume reveng`, `lume neural-kernel`) programs in Lume:

#### Install via `skills.sh` CLI (Cross-Platform)
```sh
npx skills add OmegaSoftDLL/lume@lume -g -y
```

#### Install Directly on Linux / macOS / WSL
```sh
mkdir -p ~/.agents/skills ~/.gemini/config/skills ~/.claude/skills
cp -r skills/lume ~/.agents/skills/lume
cp -r skills/lume ~/.gemini/config/skills/lume
cp -r skills/lume ~/.claude/skills/lume
```

#### Install Directly on Windows (PowerShell)
```powershell
New-Item -ItemType Directory -Path "$HOME\.agents\skills", "$HOME\.gemini\config\skills", "$HOME\.claude\skills" -Force | Out-Null
Copy-Item -Path ".\skills\lume" -Destination "$HOME\.agents\skills\lume" -Recurse -Force
Copy-Item -Path ".\skills\lume" -Destination "$HOME\.gemini\config\skills\lume" -Recurse -Force
Copy-Item -Path ".\skills\lume" -Destination "$HOME\.claude\skills\lume" -Recurse -Force
```

---

## Quickstart

Create `hello.src`:

```lume
const BONUS: int = 10

fn scale_and_bonus(x: int, factor: int) -> int
  requires x >= 0 and factor >= 1
  ensures result >= x + BONUS
= (x * factor) + BONUS

fn classify_list(xs) =
    let head_val = match xs
        Nil        => 0
        Cons(h, _) => h
    in head_val |> scale_and_bonus(2)

fn test_classify() =
    let (a, b) = (15, 25) in
    let st = {count: a, total: b} in
    let st2 = { st with count: st.count + 5 } in
    classify_list(Cons(st2.count, Nil)) == 50

print f"Verified result: {classify_list(Cons(20, Nil))}"
```

Run, test, prove, certify, and compile to native machine code:

```sh
lume run hello.src                  # -> Verified result: 50
lume test hello.src                 # -> 1 passed, 0 failed
lume prove hello.src                # -> {"ok":true, ... "status":"proven"}
lume certify hello.src              # -> Lume Verified certificate JSON
lume build hello.src -o hello       # -> standalone native ELF64 / Mach-O / PE64 binary
```

---

## Language Ergonomics & Core Syntax

Lume pairs formal verification with concise functional and systems syntax:

| Feature | Syntax in `.src` (Lume-Core) | Compiler & Prover Support |
| :--- | :--- | :--- |
| **String Interpolation** | `f"total={x + y}"`, `"total=${x + y}"`, `"{x:04x}"` | Hardened `02_parser.src`/`lcaas.src`/`lfmt.src` (`isbadholech`, `isjsblock`, `/ {ffi}` literal brace guard, $O(1)$ `strplainchunk` scanner, `win64_gui_and_interp_regression_ok.src` `8/8`) |
| **Pipe Operator (`\|>`)** | `x \|> scale(10) \|> encode` | Left-associative binary operator lowered to direct calls |
| **Functional Record Update** | `{ st with count: st.count + 1 }` | Preserves unmodified fields; reduced symbolically in `lcaas` and `lcert` |
| **Nested & Braced `match`** | `let y = match xs ...` or `match x { ... }` | Indentation-aware `ispipe` + `arm_dedent` and braced arms |
| **Top-Level `const`** | `const MAX_BYTES: int = 4096` | Substituted across functions, `requires` / `ensures` contracts, and `law` declarations |
| **Destructuring Bindings** | `let (a, b) = pair`, `let {x, y} = pt` | Supported in `let ... in` expressions and imperative `var` statements (`Cons(h, t)`) |
| **Wrapping Arithmetic** | `a +% b`, `a -% b`, `a *% b` | Explicit 64-bit two's-complement modular arithmetic (distinct from checked `+`, `-`, `*`) |
| **Scalar Replacement (`SRA`)** | `let p = {a: x, b: y} in p.a + p.b` | Promotes non-escaping records to stack slots with zero heap allocation |

---

## Built-In Bilingual Programmer's Manual

Lume embeds a 10-chapter programmer's manual in both **English (`en`)** and **Portuguese (`pt-BR`)** directly inside the CLI binary:

```sh
lume manual                      # Table of contents (English)
lume manual --pt                 # Indice completo em Portugues (pt-BR)
lume manual syntax               # Chapter 2: Syntax & Language Ergonomics
lume manual --pt sintaxe         # Capitulo 2: Sintaxe e Ergonomia
lume manual contracts            # Chapter 4: Formal Verification (QF_LIA / QF_NIA)
lume manual stdlib               # Chapter 6: Standard Library & Domain Engines
lume manual targets              # Chapter 7: 27 Universal Targets & Packagers
lume manual commands             # Chapter 8: Complete CLI Reference
lume manual all                  # Full 10-chapter manual
lume manual --export MANUAL.md   # Export full Markdown manual to disk
```

Pre-exported manuals in the repository:
- **English Manual:** [`docs/LUME_MANUAL_EN.md`](docs/LUME_MANUAL_EN.md)
- **Portuguese Manual (`pt-BR`):** [`docs/LUME_MANUAL_PT_BR.md`](docs/LUME_MANUAL_PT_BR.md)

---

## Architecture & Verification Matrix

| Milestone | Core Capabilities (`compiler/stage1/`) | Verification Evidence |
| :--- | :--- | :--- |
| **Stage 0 Seed** | Frozen C11 bootstrap interpreter (`bootstrap/lume0/`), LBE binary AST, `lume0 asm` ELF64 writer | `393/393` conformance · `168/168` ASan/UBSan |
| **Phase 1 — Self-Host** | Self-hosted `lumec`, `lasm`, `lmod`, Zero-C fixpoint (`stage2 == stage3`) | `zero_c.src` (`15/15`) · `0 diff` |
| **Phase 2 — Data & Meta** | Comptime `C1–C4`, Hygienic Macros `M1–M2`, Data `D1–D4` (`decimal`, `table`, `query`, `money`, WAL), HM Inference `F1–F4`, Single CLI `T1–T3`, Self-Evolution `E1–E3` | `decimal.src`, `table.src`, `query.src`, `lfmt.src`, `lmod.src`, `lcaas.src`, `levolve.src` |
| **Phase 3 — Safety & Proofs** | Ownership `O1–O4` (`own`, `mut`, `from`, `rc` / `arc` / `weak`, `arena`), AI Authoring `A1–A3`, Effects & Perceus `K1–K3`, Concurrency `S1–S3`, `QF_LIA` / `QF_NIA` Prover & `law` `V1–V3` | `ownership.src`, `concurrency.src`, `actor.src`, `qflia_ok.src`, `intent_oracle_ok.src` |
| **Phase 4 — Differentiable & AI** | Shape-checked `tensor[DType, ...]`, Autodiff (`grad`, `jvp`, `vjp`), `@schedule(...)` `kernel fn` -> CUDA PTX 8.0 & SPIR-V 1.6, `.safetensors` & `.onnx` (`nn.src`), Datalog, `std.prob`, LIF `std.neuro` | `tensor.src`, `nn.src`, `ai_runtime.src`, `apps/mnist/`, `apps/agent/` |
| **Phase 5 — Systems & Kernels** | `@repr(c)`, `@packed`, `@bits`, `@mmio`, Fail-closed `lume adapt c`, Freestanding Kernels `K0–K9` (`@freestanding`, `.kernel` writer, `@interrupt`, `@bound` WCET `[V0002]`, `cap[Page]`), 27 Targets, `lcert.src`, Lean 4 (`LumeCore.lean`), P33 Protection | `apps/lume_os/`, `ltarget.src`, `lcert.src`, `lprotect.src` |
| **Waves 1–12 & Audit** | Incremental cache, Arenas, E-Capsules, `--memory` profiler, `lume symbolize`, P35, WASM sandbox (`[I0275]`), OS async runtime, B+Tree ACID WAL (`db.src`), TLS 1.3 (`net.src`), X11/Web GUI (`gui.src`), `LumeMIR` SSA, APK / IPA / ISO / UEFI, `genesis`, `heal`, `equiv`, `morph`, `neural-kernel`, Quantum Nexus, **85/85 Audit & Red Team Gate** | `acceptance/matrix.json` (`24/24 PASS`), `claude_audit_gate.src` |

---

## Verified Domain & Quantum Engines

Lume includes self-hosted, formally verified domain engines in `compiler/stage1/`:

1. **Quantum Nexus Engine (`compiler/stage1/lume_quantum_nexus_engine.src` — `15/15` tests, `Lume Verified ✓`):**
   - **Linear `Qubit` Type Checker & Automatic $U^\dagger$ Uncomputation (`[Q0001]` / `[Q0002]`):** Enforces Quantum No-Cloning and No-Measurement-Reuse, and verifies automatic adjoint uncomputation of ancilla wires (`qfree_safe == 1`).
   - **Graphical ZX-Calculus & Clifford+T Optimizer:** Performs spider fusion ($Z(\alpha) \circ Z(\beta) \to Z(\alpha + \beta)$), phase teleportation, and non-Clifford $T$-gate reduction.
   - **Stabilizer Tableau Simulator & Surface Code `[[9, 1, 3]]` QEC Decoder:** Simulates Clifford stabilizer tableaux in $O(n^2)$ and decodes all `27/27` single-qubit Pauli $X, Y, Z$ errors ($d = 2t + 1$).
   - **Variational Quantum Algorithms & Neutral-Atom FPQA Routing:** Parameter-shift VQE, QAOA MaxCut, Neutral-Atom 2D Acousto-Optic Deflector (`AOD`) monotone row/column routing, and 6 quantum compilation targets (`qasm3-quantum`, `qir-llvm`, `quil-rigetti`, `iqm-json`, `stim-qec`).
2. **Cryptographic & Quantitative Ledger Engine (`compiler/stage1/lume_crypto_blockchain_engine.src` — `10/10` tests, `Lume Verified ✓`):**
   - FIPS 180-4 SHA-256, Ed25519, Secp256k1, BIP-32/39/44 HD Wallets, UTXO Merkle ledger, CEI reentrancy analysis, Constant-Product AMM ($x \cdot y = k$), and Kelly Criterion risk sizing.
3. **Binary Dissection & Specification Recovery Engine (`compiler/stage1/lume_reversa_engine.src` — `4/4` tests, `13/13` proofs, `Lume Verified ✓`):**
   - Lifts ELF64, PE64, UEFI, Mach-O, and WASM binaries to SSA `LumeMIR` and generates architecture dependency graphs.
4. **Edge Proxy & CDN Engine (`compiler/stage1/lume_pingora_proxy_engine.src` — `4/4` tests, `14/14` proofs, `Lume Verified ✓`):**
   - TinyUFO 3-queue (`Small`/`Main`/`Ghost`) + TinyLFU cache admission, Ketama consistent hashing with Power-of-Two-Choices (`P2C`) failover, sliding-window rate limiting, and stampede coalescing over RFC 8446 TLS 1.3.
5. **Architecture Review & Anti-Drift Engine (`compiler/stage1/lume_egm_engine.src` — `4/4` tests, `15/15` proofs, `Lume Verified ✓`):**
   - Stateless 5-stage code review (`R1..R5`) and bidirectional specification-to-implementation drift verification.
6. **Multi-Scale Next-Concept Modeling Engine (`compiler/stage1/lume_ncm_engine.src` — `4/4` tests, `19/19` proofs, `Lume Verified ✓`):**
   - Multi-Scale Residual Vector Quantization (`MS-RVQ`), tied codebook embeddings, block-diagonal scale-causal masks, and Classifier-Free Guidance (`CFG`).
7. **Systolic AI Accelerator & ISA Engine (`compiler/stage1/lume_opentpu_engine.src` — `4/4` tests, `23/23` proofs, `Lume Verified ✓`):**
   - 20-instruction `openTPU ISA v1` assembler and weight-stationary MXU systolic simulator, two-level `QACT` + `FP4` quantization, *K-Smoothing* outlier migration, and RTL equivalence checking.
8. **Context & Distributed State Engine (`compiler/stage1/lume_continuum_nexus_engine.src` — `4/4` tests, `27/27` proofs, `Lume Verified ✓`):**
   - Tree superposition (`bend`/`fold`), Active Context Pruning (`ACP`), quota-aware multi-provider routing, and `LWW-Element-Set` CRDT state convergence.
9. **Pix Fraud Graph Tracer & BACEN MED Recovery Engine (`examples/apps/pix_fraud_trace/main.src` — `1/1` test, `9/9` proofs, `Lume Verified ✓`):**
   - Zero-float basis-point temporal graph expansion (`JANELA_RASTREIO_SEG=86400s`, `PROFUNDIDADE_MAX_SALTOS=5`), weighted suspicion scoring (`40% * repasse + 50% * rapidez + 10% * pequeno`), composite hop risk evaluation (`pix_trace_hop_risk_bps`), automatic classification of Money Mule (`Laranja` / `Conta de Passagem`) and Cash-Out (`Saque`) accounts, and formally proven Central Bank MED precautionary block conservation (`pix_med_conservation_law`, `pix_med_cap_law`).
10. **SENTRY UAV Trajectory Forecaster & Ring-0 Geofence Guard (`examples/apps/sentry_uav_guard/main.src` — `1/1` test, `9/9` proofs, `Lume Verified ✓`):**
    - Deterministic linear trajectory forecaster (`SIGNAL`), monotonically calibrated 95% bivariate confidence radius (`PROBE`, `uav_radius_monotonic_law`), worst-case floor guard (`uav_safe_altitude_guard_mm`), and mathematically proven airspace altitude envelope enforcement (`uav_geofence_ceiling_law`, `uav_geofence_floor_law`, `uav_safe_altitude_envelope_law`).
11. **Formally Verified Double-Entry Accounting & Fiscal Split Engine (`examples/apps/verified_accounting/main.src` — `1/1` test, `7/7` proofs, `Lume Verified ✓`):**
    - Compile-time proof of the Fundamental Double-Entry Accounting Identity (`Ativo == Passivo + Patrimonio_Liquido`, zero cent imbalance `double_entry_zero_imbalance_law`), bounded retention guard (`clamped_retention_bounds_law`), and exact basis-point tax retention (`fiscal_split_conservation_law`).
12. **SEFAZ DFe (NF-e/NFC-e) & BACEN Pix API (`CobV` & `Devolucao`) Engine (`examples/apps/dfe_pix_bacen/main.src` — `1/1` test, `11/11` proofs, `Lume Verified ✓`):**
    - Formally proven SEFAZ Layout 4.00 invoice valuation (`vNF = (vProd - vDesc) + vST + vFrete + vIPI`), EC 87/2015 interstate DIFAL + FCP split (`dfe_difal_total`, `dfe_fcp_total`, `dfe_difal_with_fcp_total`), and Central Bank `bacen/pix-api` `CobV` settlement (`pix_cobv_positive_settlement_law`) and clamped anti-over-refund conservation (`pix_devolucao_safe_refund_cap_law`, `pix_devolucao_conservation_law`).
13. **OmniRoute Multi-LLM Circuit Breaker & Sovereignty Guard (`examples/apps/omniroute_guard/main.src` — `1/1` test, `8/8` proofs, `Lume Verified ✓`):**
    - Resilient multi-provider AI gateway routing (`Primary Cloud -> Secondary Fallback -> Sovereign Local LLM`) with mathematically proven confidentiality isolation (`omniroute_confidential_sovereignty_law`), hard micro-credit budget caps (`omniroute_budget_conservation_law`), and concurrent pre-attempt in-flight token reservation (`omniroute_concurrent_inflight_safety_law`).
14. **Brazilian Public Registry & Modulo-11 Verifier (`examples/apps/brasil_public_id/main.src` — `1/1` test, `9/9` proofs, `Lume Verified ✓`):**
    - Formally verified Receita Federal / SEFAZ Modulo-11 check digit arithmetic (`0 <= dv <= 9`), Receita Federal / SERPRO July 2026 Alphanumeric CNPJ character valuation (`cnpj_alnum_char_value`, `cnpj_alnum_monotonic_law`), 44-digit NF-e Access Key structural verification (`nfe_access_key_exact_44_digits_law`), and QSA corporate equity conservation (`qsa_equity_conservation_law`).
15. **Zero-Breach Forensic Anti-Spyware Triage Oracle (`examples/apps/zero_breach_forensics/main.src` — `1/1` test, `8/8` proofs, `Lume Verified ✓`):**
    - Formally verified mobile/endpoint spyware triage oracle (`Pegasus`, `Predator`, `Candiru`, `Graphite` IOCs) enforcing zero-network isolation (`zbt_netguard_isolated`), fail-closed `PARTIAL_UNKNOWN` verdicts on incomplete checks (`zbt_fail_closed_never_clean_law`), strict non-escalation of heuristic leads (`zbt_heuristics_alone_never_compromised_law`), and STIX 2.1 indicator revocation safety (`zbt_withdrawn_stix_never_active_law`).
16. **Sovereign 1-Bit/Ternary LLM Core & 3-Tier Hybrid Router (`compiler/stage1/lume_llm_core.src` — `21/21` proofs & `examples/apps/sovereign_llm_router/main.src` — `20/20` proofs, `Lume Verified ✓`):**
    - Zero-float 1-bit (`{-1, +1}`, PrismML Bonsai) and 1.58-bit ternary (`{-1, 0, +1}`, BitNet b1.58) integer MAC engine with 5-trit byte packing, Liquid AI `LFM3` $O(1)$ state-space recurrence and `LiquidCodec` 24 kHz audio frame budgeting, `DSpark` speculative decoding verifier, fail-closed MoE SSD admission guard (`llm_moe_admission_guard`), and 3-tier hybrid routing (`Tier 0` Pure Lume Core -> `Tier 1` Local `Gemma4-E2B`/`Ministral-3B-Q4`/`Bonsai-1bit` -> `Tier 2` Cloud API Key) with `QF_LIA` anti-hallucination price/contract repair.
17. **Universal Chameleon Polyglot Interop Engine (`compiler/stage1/lchameleon.src` — `28/28` proven obligations, `8/8` unit tests, `Lume Verified ✓`):**
    - Commands `lume chameleon [eco]`, `lume camaleao`, `lume polyglot`, `lume ffi-bridge`, `lume adapt <c|rust|python|js|go|java|dotnet|sql|openapi> [file]`, and `lume morph <file>` across 9 verified ecosystems (`c_abi`, `rust_cdylib`, `python_capi` with DLPack zero-copy tensors, `node_napi_wasm`, `go_cshared`, `java_jni`, `dotnet_pinvoke`, `sql_relational`, and `openapi_rpc`) with `[I0003]` fail-closed `QF_LIA` boundary contracts (`unverified[T] -> verified[T]` under `/ {ffi}`).

---

## 27 Universal Targets & Packagers

Lume compiles directly from `.src` to **27 target triples** (`ISA ⊥ Container ⊥ OS/ABI`) via `lumec`, `lasm`, and `ltarget` (`16/16` target tests):

```sh
lume targets                                              # List all 27 target triples
lume build --target x86_64-linux-elf app.src -o app       # Native Linux ELF64
lume build --target x86_64-windows-pe app.src -o app.exe  # Native Windows PE32+ (kernel32.dll IAT)
lume build --target x86_64-windows-gui app.src -o gui.exe # Clean Generic Win64 Native GUI (Subsystem 2, zero Notepad++ strings, hMenu=0, Segoe UI -12, wide buttons, 4 WS_CLIPSIBLINGS | WS_THICKFRAME | WS_HSCROLL | WS_VSCROLL panes with LB_SETHORIZONTALEXTENT = 680)
lume build --target aarch64-macos-macho app.src -o app    # Native Apple Silicon Mach-O 64 (16 KB aligned)
lume build --target x86_64-macos-macho app.src -o app     # Native macOS Intel Mach-O 64
lume build --target aarch64-linux-elf app.src -o app      # Native ARM64 ELF64
lume build --target riscv64-linux-elf app.src -o app      # Native RISC-V RV64IM ELF64
lume build --target wasm32-wasi app.src -o app.wasm       # WebAssembly WASI (with @wasm-sandbox [I0275])
lume build --target nvptx64-nvidia-cuda k.src -o k.ptx    # NVIDIA CUDA PTX 8.0
lume build --target spirv64-vulkan-compute k.src -o k.spv # Vulkan SPIR-V 1.6
lume build --target verilog-rtl k.src -o k.v              # IEEE 1364-2005 Synthesizable Verilog RTL
lume build --target vhdl-rtl k.src -o k.vhd               # IEEE 1076-2008 Synthesizable VHDL RTL
lume build --target qasm3-quantum q.src -o q.qasm         # OpenQASM 3.0 Quantum Circuit
lume build --target qir-llvm q.src -o q.ll                # Microsoft/Quantinuum QIR LLVM IR Profile
lume build --target quil-rigetti q.src -o q.quil          # Rigetti Quil 2.0 Instruction Set
lume build --target iqm-json q.src -o q.iqm.json          # IQM / EuroHPC Native JSON Schedule
lume build --target stim-qec q.src -o q.stim              # Google Stim Stabilizer QEC Circuit
lume build --target dna-quaternary d.src -o d.dna         # Homopolymer-Free Quaternary DNA (A,C,G,T)
lume package apk app.src -o app.apk                       # One-command Android APK package
lume package ipa app.src -o app.ipa                       # One-command iOS IPA package
lume package iso kernel.src -o lume_os.iso                # One-command Bootable BIOS/El-Torito ISO
lume package uefi kernel.src -o BOOTX64.EFI               # One-command UEFI PE32+ Boot Application
```

---

## Repository Structure

```text
.
├── lume                                # Bootstrap launcher -> execs native build/bin/lume_driver
├── Formula/lume.rb                     # Official Homebrew formula (macOS ARM64/x86_64 & Linux)
├── bootstrap/lume0/                    # Frozen Stage-0 C11 seed (~4.8k LoC, SEED_FREEZE.sha256)
├── compiler/stage1/
│   ├── lume/                           # Self-hosted compiler passes (01_lexer .. 07_driver)
│   ├── lasm.src                        # Self-hosted x86-64 assembler, ELF64/Mach-O/PE64 & .kernel writer
│   ├── lcaas.src                       # Compiler-as-a-Service, QF_LIA/QF_NIA/SL prover, heal/equiv/morph, MCP
│   ├── lcert.src                       # Standalone zero-compiler-import proof certificate kernel
│   ├── ltarget.src                     # 27 universal targets, LumeMIR SSA, APK/IPA/ISO/UEFI & neural-kernel
│   ├── lume_driver.src                 # Native single-binary CLI driver & self-prove engine
│   ├── lcli.src                        # CLI control plane (version, help, describe, pkg, evolve)
│   ├── lmanual.src                     # Built-in 10-chapter bilingual manual (EN & PT-BR)
│   ├── lsentience.src                  # Autonomous verification, orchestration & memory modules
│   ├── lgenesis.src                    # Full-stack multi-target application synthesizer
│   ├── lprotect.src / protect.src      # P33 software protection, MBA obfuscation, secret scanner & symbolize
│   └── std & domain modules            # fs, bytes, map, arena, capsule, db, net, gfx, gui, nn, tensor, quantum...
├── skills/lume/                        # Official AI Agent Skill (SKILL.md, references/, verified_showcase.src)
├── editors/                            # Official VS Code LSP bridge (vscode-lume) & OpenIDEA plugin (openidea-lume)
├── examples/
│   ├── 01_hello.lume .. 09_*.lume      # Surface Lume tour
│   └── apps/                           # Capstones: inventory, job_server, mnist, agent, p0_tenant_ledger,
│                                       #            p0_rtc_kernel, supply_chain_demo, lume_os,
│                                       #            pix_fraud_trace, sentry_uav_guard, verified_accounting,
│                                       #            dfe_pix_bacen, omniroute_guard, brasil_public_id,
│                                       #            zero_breach_forensics, sovereign_llm_router
├── tests/harness/claude_audit_gate.src # 100% pure-Lume Claude Opus 5.5 + Red Team (R1, R2 & R3) audit & 4-way fuzzer
├── acceptance/matrix.json              # Track A/L Acceptance Matrix (24/24 PASS, 0 UNKNOWN, 0 FAIL)
├── formal/lean/LumeCore.lean           # Mechanized Lean 4 formalization of Lume-Core soundness
├── grammar/lume.ebnf                   # Complete formal grammar
└── docs/                               # Architecture, specification, manuals & wave-by-wave audits
```

---

## Verification & Quality Gates (`100% Lume Generates Lume`)

Run the complete self-hosted verification and adversarial Red Team suite locally (zero Python or external test runners):

```sh
./lume self-prove                                         # LumeCompiler-Embedded-OmniProof-v3: 15 batteries, 413 formal obligations, 141 unit tests, 99 verified manifest files
./lume test compiler/stage1/lchameleon.src                # Universal Chameleon 9-ecosystem polyglot FFI suite (8/8 tests, 28/28 proven obligations)
./lume test compiler/stage1/win64_gui_and_interp_regression_ok.src # Win64 GUI & O(1) string interpolation regression suite (8/8)
./lume test compiler/stage1/lume_quantum_nexus_engine.src # Quantum Nexus unit & proof suite (15/15)
./lume test compiler/stage1/ltarget.src                   # 27 universal targets & quantum emitters (16/16)
./lume test compiler/stage1/lmanual.src                   # Bilingual manual suite (3/3)
build/bin/lume_make bootstrap                             # Triple self-build fixpoint (stage2 == stage3)
build/bin/lume_make zero-c                                # Prove steady-state compilation with C compilers blocked
build/bin/lume_make test                                  # Frozen Stage-0 conformance suite via native Lume runner
build/bin/lume_make asan                                  # Stage-0 under AddressSanitizer & UBSan via native Lume runner
./lume build tests/harness/claude_audit_gate.src -o build/claude_audit_gate && printf '@root %s\n' "$(pwd)" | build/claude_audit_gate
```

📄 **Bilingual Audit & Red Team Reports:**
- **English:** [`docs/LUME_REMEDIATION_AND_REDTEAM_REPORT.md`](docs/LUME_REMEDIATION_AND_REDTEAM_REPORT.md)
- **Português (`pt-BR`):** [`docs/LUME_REMEDIATION_AND_REDTEAM_REPORT_PT_BR.md`](docs/LUME_REMEDIATION_AND_REDTEAM_REPORT_PT_BR.md)

---

## Contributors & AI-Assisted Engineering Co-Pilots

| Contributor | Role & Focus |
| :--- | :--- |
| **[Ricardo Bueno (`@OmegaSoftDLL`)](https://github.com/OmegaSoftDLL)** | Creator, Language Architect & Principal Systems Engineer |
| **Claude (AI-Assisted Engineering & Formal Verification Co-Pilot)** | Self-Hosted Compiler, Formal Verification (`QF_LIA` / `QF_NIA` / Separation Logic) & Runtime Engineering |
| **Kimi (AI-Assisted Engineering & Conformance Co-Pilot)** | Phase 0 Consolidation, Incremental Module Cache, Memory Arenas & Conformance Engineering |
| **AGY — Antigravity (AI-Assisted Engineering & Autonomous Verification Co-Pilot)** | Compiler Performance Optimization, Multi-Platform Release Packaging & Autonomous Verification |

> *Note: AI coding assistants listed under "AI-Assisted Engineering & Formal Verification Co-Pilots" were used as pair-programming tools under human architectural direction and do not imply organizational endorsement by their respective vendors.*

---

## License

Licensed under the [Apache License, Version 2.0 (`Apache-2.0`)](LICENSE-APACHE). See [COPYRIGHT](COPYRIGHT) for details.
