# 43 — Trust root and reproducibility

Lume is self-hosting: `lumec` (the compiler) and `lasm` (the assembler) are written in Lume and compile themselves.
A self-hosting toolchain asks for one act of trust — that the binary you run is the one the public sources produce,
with nothing slipped in between (Ken Thompson, *Reflections on Trusting Trust*). This document explains how Lume turns
that act of trust into a property **anyone can verify from a clone, with no faith in the maintainer**, and how the
`trust_root_gate` enforces it on every build.

## The chain

```
bootstrap/lume0/*.c   (the frozen Stage-0 seed: ~5200 lines of dependency-free C11)
        │  cc
        ▼
     lume0            two independent code generators in one binary:
        │               • the C backend  (asmgen.c + elf.c): .src → x86-64 ELF, no `as`, no `ld`
        │               • the Lume codegen (data_asmgen.lume, run by the seed's interpreter)
        ▼
   stage-0 lumec  →  self-hosted lumec  →  (fixpoint) the shipped lumec / lasm
```

The **only** thing you must trust is the Stage-0 seed: a small, auditable amount of C that uses no network, runs no
external program (its single `execv` is a self-re-exec to raise the stack limit), and depends on nothing but libc.
Everything above it is Lume compiling Lume, and is checked against the seed.

## The four guarantees

1. **Reproducible — determinism is proven, not assumed.**
   `lumec` compiling its own source twice yields byte-identical assembly; `lasm` assembling that twice yields a
   byte-identical ELF. Any nondeterminism a change introduces — a timestamp, an iteration-order leak, an address in the
   output — breaks this immediately. (Measured: identical across repeated builds.)

2. **Self-verifying — the binary equals the source.**
   Assembling the compiler's own source with the shipped toolchain, `lasm(lumec(lumec.src))`, reproduces the shipped
   `lumec` binary **byte for byte**. You do not have to trust that the published binary matches the published source —
   you reproduce it.

3. **A small, bounded trust root.**
   The entire seed is a handful of C files (currently 5213 lines across 14 files). The gate fails if that audited
   surface grows past a line bound or gains a file, so the anchor a newcomer must read to trust the whole stack stays
   small on purpose.

4. **Corroborated by independent implementations (diverse double-compilation).**
   The self-hosted `lumec`, the seed's independent Lume code generator (`data_asmgen`), and the `lcaas` oracle must all
   agree on the emitted runtime and on a corpus of programs (`runtime_sync_gate`). The encoders are also checked
   against external assemblers: `lasm_gate` against GNU `as`, `multi_arch_gate` against LLVM. A trusting-trust backdoor
   would have to be replicated, identically, across all of these independent implementations.

## How to verify it yourself

From a clean clone on Linux x86-64:

```
make -C bootstrap/lume0           # build the seed (lume0) from C
./lume ...                        # bootstrap the toolchain from the seed
printf '@root %s\n' "$PWD" | build/bin/trust_root_gate
```

The gate prints, and asserts, the four guarantees. `runtime_sync_gate`, `lasm_gate`, `seed_safe_gate` and
`multi_arch_gate` add the cross-implementation and seed-compatibility checks. All of them run in the standard battery
(`bootstrap/lume0/tests/run.sh`).

## Why this matters

For a public, fast-moving project with a small core team, "trust the maintainer" does not scale. Reproducibility and a
bounded, corroborated trust root are how the bootstrappable-builds and reproducible-builds communities answer the same
question for GCC, Debian and GNU Mes. Lume holds the property by construction; `trust_root_gate` keeps it from ever
silently regressing.
