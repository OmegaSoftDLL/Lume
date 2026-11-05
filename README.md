<div align="center">

# Lume

### **Self-Hosted, Formally Verified Systems, AI, and Quantum Programming Language**
*Mathematically Proven by Compiler · Self-Hosted Zero-C Steady State (`stage2 == stage3`) · 27 Target Architectures*

[![CI](https://github.com/OmegaSoftDLL/lume/actions/workflows/ci.yml/badge.svg)](https://github.com/OmegaSoftDLL/lume/actions/workflows/ci.yml)
[![Release](https://img.shields.io/badge/release-v1.0.0-blue)](https://github.com/OmegaSoftDLL/lume/releases/tag/v1.0.0)
[![Zero-C Steady State](https://img.shields.io/badge/steady--state-100%25%20Lume%20%28Zero--C%29-success)](docs/PROJECT_STATE.md)
[![Acceptance Matrix](https://img.shields.io/badge/acceptance%20matrix-24%2F24%20PASS-brightgreen)](docs/acceptance-matrix.md)
[![Targets](https://img.shields.io/badge/targets-27%20architectures-orange)](docs/26-targets.md)
[![License: MIT OR Apache-2.0](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-green.svg)](#license)

[**Installation**](#installation) · [**Quickstart**](#quickstart) · [**Language Ergonomics**](#language-ergonomics--core-syntax) · [**Built-In Manual (`EN` / `PT-BR`)**](#built-in-bilingual-programmers-manual) · [**Architecture & Verification**](#architecture--verification-matrix) · [**27 Compilation Targets**](#27-universal-targets--packagers) · [**Domain Engines**](#verified-domain--quantum-engines)

</div>

---

## Overview

**Lume (`v1.0.0`, Edition 2026)** is a statically typed, formally verified systems, artificial intelligence, and quantum programming language. Its entire production toolchain is written in Lume itself and operates in a verified **Zero-C steady state**:

- **Self-Hosted Fixpoint (`stage2 == stage3`):** The compiler (`lumec`), machine-code assembler and binary linker (`lasm`), module bundler (`lmod`), theorem prover (`lcaas`), independent proof certificate kernel (`lcert`), formatter (`lfmt`), test runner (`ltest`), and unified CLI driver (`lume_driver` + `lcli`) compile themselves bit-for-bit (`0 diff`) in **~3.8 seconds** without any external C compiler, assembler (`as`), or linker (`ld`).
- **Sound Compile-Time Verification (`QF_LIA`, `QF_NIA`, `QF_BV`, Separation Logic):** Built-in Fourier-Motzkin linear integer arithmetic solver with cutting-plane tightening, nonlinear Positivstellensatz and shifted bilinear monotonicity, bitvector verification, Separation Logic heap frame reasoning, `[K0005]` W^X DMA protection, `[K0006]` kernel stack bounds, `[C0009]` constant-time cryptographic side-channel analysis, and standalone certificate checking via `lcert`.
- **Expressive Functional & Systems Ergonomics:** Combines affine ownership (`own`, `mut`, region-tracked borrows, Perceus in-place reuse, and scoped bump arenas) with layout-sensitive or braced pattern matching, `f"...{expr}..."` string interpolation, left-associative `|>` pipe operators, `{ record with field: value }` functional updates, top-level `const` declarations, and tuple/record/ADT destructuring.
- **24/24 Acceptance Matrix (`0 UNKNOWN`, `0 FAIL`) & 14 Embedded Verification Batteries (`lume self-prove`):** Every subsystem — including B+Tree ACID WAL storage, RFC 8446 TLS 1.3, X11/Web GUI, industrial telemetry (`Modbus`, `DNP3`, `IEC 60870-5-104`, `IEC 61850`, `ANSI` protection relays), 2D/3D software rendering, differentiable tensor/GPU kernels, quantum circuit synthesis (`OpenQASM 3.0`, `QIR`, `Quil`, `IQM`, `Stim`), and the freestanding `lume-os` microkernel — is verified continuously in CI.

---

## Installation

### 1. One-Line Installer (Linux & macOS)

```sh
curl -fsSL https://github.com/OmegaSoftDLL/lume/releases/latest/download/install.sh | sh
export PATH="$HOME/.lume/bin:$PATH"
lume self verify
lume self-prove
```

### 2. Homebrew (macOS Apple Silicon, macOS Intel & Linux)

```sh
brew install OmegaSoftDLL/lume/lume
lume --version
```

### 3. Windows x64 (PowerShell)

```powershell
Invoke-WebRequest -Uri "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-windows-x86_64.tar.gz" -OutFile "lume-win64.tar.gz"
mkdir "$HOME\.lume" -Force | Out-Null
tar -xzf lume-win64.tar.gz --strip-components=1 -C "$HOME\.lume"
$env:PATH = "$HOME\.lume\bin;$env:PATH"
lume --version
```

### 4. Official Prebuilt Archives (`v1.0.0`)

| Platform / Architecture | Archive |
| :--- | :--- |
| **Linux x86-64** | [`lume-v1.0.0-linux-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-x86_64.tar.gz) |
| **Linux ARM64 (`aarch64`)** | [`lume-v1.0.0-linux-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-aarch64.tar.gz) |
| **Linux RISC-V 64 (`riscv64`)** | [`lume-v1.0.0-linux-riscv64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-riscv64.tar.gz) |
| **macOS Apple Silicon (`M1/M2/M3/M4`)** | [`lume-v1.0.0-macos-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-aarch64.tar.gz) |
| **macOS Intel (`x86_64`)** | [`lume-v1.0.0-macos-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-x86_64.tar.gz) |
| **Windows x64 (`PE32+`)** | [`lume-v1.0.0-windows-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-windows-x86_64.tar.gz) |
| **SHA-256 Checksums** | [`SHA256SUMS`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/SHA256SUMS) |

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
| **String Interpolation** | `f"total={x + y}"` or `"total=${x + y}"` | Desugared in `01_lexer.src` / `02_parser.src` with automatic `str(...)` conversion |
| **Pipe Operator (`\|>`)** | `data \|> normalize(10) \|> encode` | Left-associative binary operator lowered to direct calls |
| **Functional Record Update** | `{ state with count: state.count + 1, ok: 1 }` | Preserves unmodified fields; reduced symbolically in `lcaas` and `lcert` |
| **Nested & Braced `match`** | `let y = match xs ... in y + 1` or `match x { ... }` | Indentation-aware `ispipe` + `arm_dedent` and braced arms |
| **Top-Level `const`** | `const MAX_BYTES: int = 4096` | Substituted across functions, `requires`/`ensures` contracts, and `law` declarations |
| **Destructuring Bindings** | `let (a, b) = pair`, `let {x, y} = pt`, `let Cons(h, t) = xs` | Supported in both `let ... in` expressions and imperative `var` statements |
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

| Milestone | Core Capabilities | Verification Evidence |
| :--- | :--- | :--- |
| **Stage 0 Seed** | Frozen C11 bootstrap interpreter (`bootstrap/lume0/`, `SEED_FREEZE.sha256`), LBE binary AST (`lbe.c`), `lume0 asm` ELF64 writer | `393/393` conformance tests + `168/168` ASan/UBSan (`0 failed`) |
| **Phase 1 — Self-Host** | Self-hosted compiler (`lumec`), native assembler (`lasm`), module bundler (`lmod`), Zero-C fixpoint (`stage2 == stage3`) | `scripts/zero_c.src` (`15/15`), `0 diff` between `lumec2.s` and `lumec3.s` |
| **Phase 2 — Data & Metaprogramming** | Comptime `C1–C4` (`comptime`, generics, `embed`, `table_schema`), Hygienic Macros `M1–M2`, Data `D1–D4` (`decimal(p,s)`, `table[T]`, `query`, `money[CCY]`, durable WAL `persist table`), HM Type Inference `F1–F4`, Single CLI `T1–T3` (`lsp`, `dap`, `repl`), Self-Evolution `E1–E3` | `compiler/stage1/{decimal,table,query,lfmt,lmod,lcaas,levolve}.src` |
| **Phase 3 — Safety & Proofs** | Ownership & Borrow Checker `O1–O4` (`own`, `mut`, `from` regions, `rc`/`arc`/`weak`, `arena`), AI Authoring `A1–A3` (typed holes `_`, `total fn`, `unverified[T]`), Algebraic Effects & Perceus Reuse `K1–K3` (`/ pure`, `with handler`), Structured Concurrency & Actors `S1–S3`, Sound `QF_LIA` / `QF_NIA` Prover & `law` `V1–V3` | `compiler/stage1/{ownership,concurrency,actor,qflia_ok,intent_oracle_ok}.src` |
| **Phase 4 — Differentiable & AI** | Shape-checked `tensor[DType, ...]` (`[T0300]`), forward/reverse Autodiff (`grad`, `value_and_grad`, `jvp`, `vjp`), `@schedule(...) kernel fn` -> CUDA PTX 8.0 & Vulkan SPIR-V 1.6 with VM execution, binary `.safetensors` & `.onnx` (`nn.src`), semi-naive Datalog, `std.prob`, LIF `std.neuro` | `compiler/stage1/{tensor,nn,ai_runtime}.src`, `examples/apps/{mnist,agent}/` |
| **Phase 5 — Systems & Kernels** | Machine layout (`@repr(c)`, `@packed`, `@bits`, `@mmio`), Fail-closed C/WASM Interop (`lume adapt c`), Freestanding Kernels `K0–K9` (`@freestanding`, MBR + 64-bit Long Mode `.kernel` writer, `@interrupt`, `@bound(cycles: N)` WCET `[V0002]`, linear `cap[Page\|Port\|Irq]`), 27 Universal Targets, Standalone Proof Kernel (`lcert.src`), Lean 4 Mechanization (`formal/lean/LumeCore.lean`), P33 Software Protection (`--protect max`) | `examples/apps/lume_os/`, `compiler/stage1/{ltarget,lcert,lprotect}.src` |
| **Production Waves 1–12** | Incremental module cache (`--incremental`), Scoped Arenas (`arena.src`), E-Capsules (`capsule.src`), `--memory` RSS profiler, `lume symbolize`, P35 hardware verification, WASM binary ULEB128 sandbox (`[I0275]`), Multi-worker OS async runtime (`async_rt.src`), B+Tree + ACID WAL crash recovery (`db.src`), RFC 793 TCP + RFC 8446 TLS 1.3 (`net.src`), X11 Core Wire GUI (`gui.src`), `LumeMIR` SSA IR, APK/IPA/ISO/UEFI packagers, `lume genesis`, `lume heal`, `lume equiv`, `lume morph`, `lume neural-kernel`, and Quantum Nexus | `docs/WAVE_01_AUDIT.md` .. `docs/WAVE_10_AUDIT.md`, `acceptance/matrix.json` (`24/24 PASS`) |

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

---

## 27 Universal Targets & Packagers

Lume compiles directly from `.src` to **27 target triples** (`ISA ⊥ Container ⊥ OS/ABI`) via `lumec`, `lasm`, and `ltarget` (`16/16` target tests):

```sh
lume targets                                              # List all 27 target triples
lume build --target x86_64-linux-elf app.src -o app       # Native Linux ELF64
lume build --target x86_64-windows-pe app.src -o app.exe  # Native Windows PE32+ (kernel32.dll IAT)
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
├── examples/
│   ├── 01_hello.lume .. 09_*.lume      # Surface Lume tour
│   └── apps/                           # Capstones: inventory, job_server, mnist, agent, p0_tenant_ledger,
│                                       #            p0_rtc_kernel, supply_chain_demo, lume_os
├── acceptance/matrix.json              # Track A/L Acceptance Matrix (24/24 PASS, 0 UNKNOWN, 0 FAIL)
├── formal/lean/LumeCore.lean           # Mechanized Lean 4 formalization of Lume-Core soundness
├── grammar/lume.ebnf                   # Complete formal grammar
└── docs/                               # Architecture, specification, manuals & wave-by-wave audits
```

---

## Verification & Quality Gates

Run the complete self-hosted verification suite locally:

```sh
./lume self-prove                                         # 14 batteries, 396 proofs, 134 unit tests, 98 SHA-256 files
./lume test compiler/stage1/lume_quantum_nexus_engine.src # Quantum Nexus unit & proof suite (15/15)
./lume test compiler/stage1/ltarget.src                   # 27 universal targets & quantum emitters (16/16)
./lume test compiler/stage1/lmanual.src                   # Bilingual manual suite (3/3)
build/bin/lume_make bootstrap                             # Triple self-build fixpoint (stage2 == stage3)
build/bin/lume_make zero-c                                # Prove steady-state compilation with C compilers blocked
make -C bootstrap/lume0 test                              # Frozen Stage-0 conformance suite (393/393)
make -C bootstrap/lume0 asan                              # Stage-0 under AddressSanitizer & UBSan (168/168)
```

---

## License

Distributed under the terms of both the [MIT License](LICENSE-MIT) and the [Apache License (Version 2.0)](LICENSE-APACHE), at your option. See [COPYRIGHT](COPYRIGHT) for details.
