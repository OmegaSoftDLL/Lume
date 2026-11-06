---
name: lume
description: Complete guide to programming in the Lume programming language (v1.0.0) — syntax, Hindley-Milner type system, ownership and Perceus memory management, formal QF_LIA verification (requires/ensures/law, lume prove, lume certify), financial decimals and persistent tables, shape-checked tensors and GPU kernels (PTX/SPIR-V), bare-metal Ring-0 kernels (@freestanding), C interop, and Sovereign Sentience CLI commands. Always use this skill whenever the user asks to write, read, debug, prove, compile, or evolve code in Lume (.src or .lume files) or use the lume CLI.
license: Apache-2.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Programming in Lume (v1.0.0)

Lume is a **self-hosted, formally verified, zero-GC systems, AI, and quantum programming language** designed to be written seamlessly by both humans and AI agents. Every Lume program compiles directly to native machine code (`x86_64`, `aarch64`, `riscv64`, `wasm32-wasi`, bare-metal `.kernel` MBR/Long-Mode images, CUDA `PTX`, and Vulkan `SPIR-V`) with built-in **`QF_LIA` theorem proving** (`lume prove` and `lume certify`) at compile time.

---

## 1. Quick-Start CLI Commands

Once `lume` is in your `PATH` (`~/.lume/bin` on Linux/macOS/WSL or `$HOME\.lume\bin` on Windows PowerShell):

```bash
# Run, test, prove, certify, and compile a Lume source file
lume run app.src
lume test app.src
lume prove app.src
lume certify app.src
lume build app.src -o app

# Format code and check types/ownership
lume fmt app.src
lume check app.src

# Query Lume's Sovereign Memory & Compiler-as-Oracle before coding
lume consult "implement bounded rate limiter with mathematical proof"

# Built-in full language manual (English or Brazilian Portuguese)
lume manual en
lume manual pt-br
```

---

## 2. Core Syntax & Formal Verification (`.src`)

Lume uses `#` for comments, `const` for constants, `fn` for functions, `requires`/`ensures` for compile-time contracts, `law` for universal algebraic theorems, `f"...{expr}..."` for string interpolation, and `|>` for left-associative pipes:

```lume
# Comments in Lume always start with #
const BONUS: int = 10

fn clamp_fee(amount: int, lo: int, hi: int) -> int
  requires lo <= hi
  ensures result >= lo and result <= hi
= if amount < lo then lo else if amount > hi then hi else amount

law clamp_lower_bound(x: int, lo: int, hi: int) =
  if lo <= hi then clamp_fee(x, lo, hi) >= lo else 1 == 1

fn classify_list(xs) =
  let head_val = match xs
    Nil        => 0
    Cons(h, _) => h
  in head_val |> clamp_fee(10, 100)

fn test_clamp() =
  let (a, b) = (250, 100) in
  let st = {raw: a, cap: b} in
  let st2 = { st with cap: st.cap + 50 } in
  clamp_fee(st2.raw, 10, st2.cap) == 150

print f"Verified fee: {clamp_fee(250, 10, 100)}"
```

> **Critical Rules When Writing Lume (`.src` / `.lume`):**
> 1. **Comments:** Always use `#` for line comments (never `//`).
> 2. **Logical Operators in Contracts:** Use `and`, `or`, `not` (or `&&`, `||`, `==>`) in `requires`, `ensures`, and `law`.
> 3. **Conditional Expressions:** Every `if cond then a else b` is an expression and must have both `then` and `else` branches.
> 4. **Compiler Internal `.src` Invariant:** When editing the self-hosted compiler (`compiler/stage1/*.src`), keep `match` at the top level of helper functions and never edit generated `compiler/stage1/lumec.src` directly (`make amalgamate`).
> 5. **Pure LF (`\n`) Line Endings:** Always save `.src`, `.lume`, `.expected`, and `.sh` files with pure `LF (\n)`, never `CRLF (\r\n)`.

### 2.1 Stage-1 `.src` Builtins, Implication Idiom & Parameter Invariants

- **Core Builtins:**
  - Strings & Collections: `count(s_or_list)`, `at(s, i)`, `slice(s, start, end)`, `ord(ch)`, `chr(code)`, `toint(s)`, `str(v)`
  - Filesystem & OS Process Execution: `fs_read_file(path)`, `fs_write_file(path, data)`, `fs_write_sync(path, data)`, `fs_path_exists(path)`, `fs_read_byte(path, offset)`, `os_run(cmd, args)`, `os_getenv(name)`, `os_argc()`, `os_argv(i)`
- **Implication Idiom in `law`:** Express logical implication $P \implies Q$ inside `law` declarations using `if P then Q else 1 == 1`, which reduces directly to decidable branches in both `lcaas.src` and the independent proof kernel `lcert.src` (which also verifies compound `terminates` obligations via `lk_prove_term_cond` and NIST FIPS 180-4 SHA-256 KAT).
- **Decidable `QF_LIA` vs. `runtime_checked`:** Linear integer arithmetic (`a + b`, `a - b`, `c * x` with constant integer `c`) is proven statically at compile time by `lcaas` and verified by `lcert`. Non-linear variable multiplication (`x * y`) falls outside pure `QF_LIA` and is marked `runtime_checked` unless bounded within the degree-2 Positivstellensatz `QF_NIA` fragment (`x >= 0 and y >= 0`).
- **Max 6 Parameters in Stage-1 `.src` Compiler Modules:** Native SysV AMD64 codegen (`05_codegen.src`) passes up to 6 arguments in registers (`%rdi, %rsi, %rdx, %rcx, %r8, %r9`); group additional parameters into a record `{...}` if a function requires more than 6 inputs.
- **Unit Test Convention:** Any zero-argument function named `fn test_<name>() = <bool_expr>` is automatically discovered and executed by `lume test <file.src>`.

---

## 3. Core Capabilities, Sovereign Engines & Verified Capstones

| Pillar | Key Constructs | Reference Guide |
|---|---|---|
| **Types, ADTs, Ownership & Effects** | `type`, `match`, `own`, `mut`, `&T`, `effect`, `handle`, Perceus reuse | Read [`references/language-syntax-and-types.md`](references/language-syntax-and-types.md) |
| **Formal Verification (`QF_LIA`) & Hole Synthesis** | `requires`, `ensures`, `law`, `??` (synthesis hole), `@bound(cycles: N)`, `lume prove`, `lume certify` | Read [`references/verification-and-prover.md`](references/verification-and-prover.md) |
| **Financial Data, Tensors/GPU & Ring-0 Systems** | `decimal(p,s)`, `money[CCY]`, `persist table`, `tensor[DType, ...]`, `grad`, `@schedule kernel fn`, `@freestanding`, `@repr(c)`, `@mmio` | Read [`references/data-ai-and-systems.md`](references/data-ai-and-systems.md) |
| **CLI, Self-Evolution & Sovereign Sentience** | `lume consult`, `lume self-build`, `lume hot-evolve`, `lume swarm-evolve`, `lume evolve`, `lume reveng`, `lume neural-kernel`, `lume mesh` | Read [`references/cli-and-sentience-toolchain.md`](references/cli-and-sentience-toolchain.md) |
| **Sovereign 1-Bit/Ternary LLM Core & COSMIC 1.11** | `compiler/stage1/lume_llm_core.src` (`21/21` `QF_LIA` proofs: Bonsai 1-bit & BitNet 1.58-bit MAC, 5-trit byte packing, Liquid AI `LFM3` $O(1)$ recurrence & `LiquidCodec` 24 kHz audio, `DSpark` speculative verifier, `Colibri` MoE SSD guard, 3-tier router), `gui.src` (`4/4` proofs: Wayland `xdg-dialog-v1` modal z-index/click-block), `los.src` (`11/11` proofs: hybrid `iGPU`/`dGPU` PCI selection) | `lume test compiler/stage1/lume_llm_core.src` |
| **Verified Executable Showcase** | Ready-to-run verified example (`lume run`, `lume test`, `lume prove`, `lume certify`) | Read [`examples/verified_showcase.src`](examples/verified_showcase.src) |

### 3.1 All 8 Sovereign & Brazilian Verified Capstones (`examples/apps/`)

| Capstone (`examples/apps/<name>/main.src`) | `QF_LIA` Proofs | Domain & Verified Invariants |
|---|---|---|
| `pix_fraud_trace` | `9/9` proven | Real-time Pix graph taint propagation & fraud trace engine |
| `sentry_uav_guard` | `9/9` proven | Autonomous UAV geofence, battery & attitude safety envelope |
| `verified_accounting` | `7/7` proven | Double-entry ledger balance conservation & audit trail |
| `dfe_pix_bacen` | `11/11` proven | SEFAZ NF-e/NFC-e Modulo-11 DV, ICMS/DIFAL & BACEN Pix EMV CRC-16 |
| `omniroute_guard` | `8/8` proven | Quota-aware multi-provider LLM & payment failover router |
| `brasil_public_id` | `9/9` proven | CPF, PIS/PASEP, Titulo Eleitoral & RFB/SERPRO July 2026 Alphanumeric CNPJ (`ord(ch) - 48`) |
| `zero_breach_forensics` | `8/8` proven | Pegasus/Predator/Candiru anti-spyware forensic scanner & STIX 2.1 IOC verifier |
| `sovereign_llm_router` | `20/20` proven | 1-Bit/Ternary MAC, Liquid `LFM3` 24 kHz audio, `Colibri` MoE SSD guard & 3-tier hybrid router + price oracle |

### 3.2 IDE Integrations (`editors/`)
- **VS Code (`editors/vscode-lume/`):** `extension.js` + `lsp_bridge.src` (`7/7` `QF_LIA` proofs) with real-time diagnostics and `QF_LIA` proof code lenses.
- **OpenIDEA / JetBrains (`editors/openidea-lume/plugin.toml`):** Declarative Lume language plugin manifest.

---

## 4. Standard Workflow for AI Agents Writing Lume

1. **Consult Sovereign Memory First (Optional):**
   Run `lume consult "<intent>"` to retrieve proven `QF_LIA` laws and hyperdimensional context vectors.
2. **Model Domain Types & Contracts Explicitly:**
   Write `requires` and `ensures` on critical functions and at least one `law` theorem per module.
3. **Verify & Execute:**
   Run `lume prove <file.src>`, `lume test <file.src>`, and `lume run <file.src>` to confirm 100% proven obligations (`"status":"proven"`) and deterministic execution.
