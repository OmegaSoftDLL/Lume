# Lume CLI, Self-Evolution & Sovereign Sentience Reference

## Table of Contents
1. [Core Compilation, Verification & Tooling CLI](#1-core-compilation-verification--tooling-cli)
2. [Sovereign Sentience & Cumulative Memory Commands](#2-sovereign-sentience--cumulative-memory-commands)
3. [Guarded Self-Evolution (`lume evolve`) & 6 Verification Gates](#3-guarded-self-evolution-lume-evolve--6-verification-gates)
4. [Autonomous Binary Reverse Engineering (`lume reveng`)](#4-autonomous-binary-reverse-engineering-lume-reveng)
5. [Semantic Intent Mesh, Component Registry & Economic Benchmark](#5-semantic-intent-mesh-component-registry--economic-benchmark)

---

## 1. Core Compilation, Verification & Tooling CLI

| Command | Description |
|---|---|
| `lume build <file.lume\|.src> [-o <out>] [--target <triple>]` | Compile Lume source directly to native executable or kernel image |
| `lume run <file.lume\|.src> [args...]` | Compile and immediately execute a Lume program |
| `lume check <file.lume\|.src>` | Run HM type inference, ownership/borrow checking (`O0001`–`O0030`), and capability checks |
| `lume verify <file.lume\|.src>` | Prove all `requires`, `ensures`, `law`, and `@bound(cycles: N)` obligations via `QF_LIA` |
| `lume fmt <file.lume\|.src>` | Canonical deterministic code formatter (`lfmt`) |
| `lume test [dir]` | Run unit, conformance, and property tests |
| `lume adapt c <header.h>` | Generate fail-closed Lume wrapper with contracts from a C header |
| `lume lsp` / `lume dap` / `lume repl` | Start Language Server Protocol, Debug Adapter Protocol, or interactive REPL |
| `lume self verify` | Verify all 101 installed toolchain files against `MANIFEST.sha256` |
| `lume manual [en\|pt-br]` | Display the complete built-in Lume manual in English or Brazilian Portuguese |

### Supported Native Targets (`--target`)
- `x86_64-linux-elf` (Native 64-bit Linux ELF)
- `x86_64-windows-pe` (Native 64-bit Windows PE32+)
- `aarch64-linux-elf` (Native 64-bit ARM64 Linux ELF)
- `aarch64-macos-macho` (Native Apple Silicon macOS Mach-O)
- `riscv64-linux-elf` (Native 64-bit RISC-V ELF)
- `wasm32-wasi` (WebAssembly System Interface)
- `x86_64-baremetal-kernel` / `.kernel` (Bootable MBR + 64-bit Long Mode OS kernel image)
- `ihex` (Intel HEX firmware image)

---

## 2. Sovereign Sentience & Cumulative Memory Commands

When an AI agent operates Lume, these commands connect the agent's reasoning to Lume's deterministic prover, hyperdimensional memory (`10,000-bit` HDC vectors), and code synthesizer:

```bash
# 1. Consult cumulative Sovereign Memory & synthesize a verified QF_LIA law for a goal
lume consult "design a monotonic packet sequence validator"

# 2. Autonomously synthesize, compile, and prove a complete module from a specification
lume self-build "ring0 page alignment helper with 4KB alignment proof"

# 3. Generate a verified Ring-0 hot-patch with zero-downtime state migration proof
lume hot-evolve "align physical page address down to 4096-byte boundary"

# 4. Run multi-node swarm evolution across specialized synthesizer/prover roles
lume swarm-evolve "distributed consensus monotonic checksum"
```

All knowledge produced by `lume consult`, `lume self-build`, `lume hot-evolve`, and `lume swarm-evolve` is persisted with FIPS 180-4 SHA-256 integrity inside `~/.lume/sovereign_memory/memory_vault.ledger`.

---

## 3. Guarded Self-Evolution (`lume evolve`) & 6 Verification Gates

Lume can evolve its own compiler and standard library under strict mathematical and cryptographic governance:

```bash
# List all evolution proposals in the repository/distribution
lume evolve list

# Verify a specific proposal (by short alias, ID, or directory path)
lume evolve verify 0001_clamp
lume evolve verify 0003_decimal_clamp
```

Every `lume evolve verify` run enforces **6 mandatory gates** before a proposal can ever be merged:
1. **`compile`** — Candidate and tests compile cleanly to native `x86-64`.
2. **`conformance`** — All unit and property tests pass with exact expected output.
3. **`api_compat`** — 100% of baseline public symbols and signatures are preserved.
4. **`capability`** — Capability audit confirms no unauthorized I/O or ambient authority escalation.
5. **`budget`** — Generated assembly size (`asm_lines`) stays within the proposal's strict instruction budget.
6. **`fixpoint`** — Self-hosting fixpoint (`stage2 == stage3`) and `QF_LIA` proofs (`proofs_ok: true`) hold.

---

## 4. Autonomous Binary Reverse Engineering (`lume reveng`)

Decompile an existing compiled binary (`ELF`, `PE`, `Mach-O`) into clean, readable Lume source code with automatically inferred `QF_LIA` safety contracts:

```bash
lume reveng /path/to/binary
```

---

## 5. Semantic Intent Mesh, Component Registry & Economic Benchmark

```bash
# Semantic Intent Protocol 0.1 (discover/negotiate capabilities across agents)
lume mesh status

# Content-Addressed Verified Component Registry (publish/resolve by SHA-256 + proof)
lume registry discover

# Bounded Economic Benchmark Protocol 0.1
lume economy
```
