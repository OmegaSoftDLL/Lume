<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="76" height="76" align="left" />
  Binary Assurance, Constant-Time Cryptography &amp; Tool Qualification (`PASS`)
</h1>
<br clear="left"/>

Source-level verification alone cannot protect safety-critical or cryptographic systems if a compiler backend miscompiles a branch, introduces a secret-dependent jump during register allocation, overflows an interrupt stack, or suffers a single-event hardware upset (`SEU`).

Lume closes the source-to-silicon gap through **clean-room mutual binary assurance**, **machine-verified constant-time cryptography**, **`2oo2D` dual-channel clean-room lockstep**, and a cryptographically signed **Tool Qualification Dossier (`lume qualify` — `PASS`)** structured for **DO-178C / DO-330**, **IEC 61508**, **ISO 26262**, and **IEC 62304** engineering workflows.

---

## 1. Symbolic Machine-Code Translation Validation (`ltv.src`, `ltv_rt.src`, `ltv_multiarch.src`)

Instead of trusting `05_codegen.src` on faith, Lume parses the emitted native assembly/machine instructions, lifts every basic block into symbolic state transformers, and proves semantic equivalence against the source AST:

- **`ltv.src` (`lume tv --exec`):**
  - Validates **`694` compiled functions** across the certified module suite (`0` rejected) with **`7,846` native boundary vectors** agreeing bit-for-bit between real CPU execution and AST semantics.
  - Enforces **`687/687` 1-to-1 AST-to-object branch correlation** so optimization passes never silently drop or invert safety branches.
  - Kills **`600/600` behavior-changing codegen mutants** (`0` unsound acceptances across stack-pointer unbalancing, slot shifts, register swaps, deleted instructions, immediate flips, `jcc` inversions, call swaps, and `setcc` mutations in `G-TV`).
- **`ltv_rt.src` (`lume tv-rt`):**
  - Symbolically verifies all **`18/18` integer runtime helpers** emitted from `runtime_core.lume` across **`268` control-flow paths and `462` proof obligations**, turning arithmetic and overflow-trap helpers into machine-checked theorems rather than trusted axioms (`21/21` mutated helpers rejected in `G-TVRT`).
- **`ltv_multiarch.src` (`lume multi-arch-gate`):**
  - Extends symbolic translation validation and execution equivalence across **AArch64** (`larm64.src`, `73/73` official encoding vectors identical to `clang`) and **RISC-V RV64IM / RV32IM** (`lriscv.src`, `55/55` vectors identical to `clang`), verified live across `x86-64`, `qemu-aarch64`, `qemu-riscv64`, and bare-metal `LumePuter`.

```sh
lume tv examples/safety_envelope/critical_kernels.src --exec
lume tv-rt examples/safety_envelope/critical_kernels.src
lume tv-gate && lume tv-rt-gate && lume multi-arch-gate
```

---

## 2. Clean-Room SMT-LIB2 Certificate Solver (`lsmt.src` + `z3`)

Every translation-validation equivalence obligation exported by `ltv` is emitted as a standard `QF_UFNIA` `.smt2` certificate and checked independently by **two completely separate engines** (`lume smt-cert-gate` / `G-SMT`):

1. **`lsmt.src` (`lume smt-check`):** Clean-room native Lume SMT-LIB2 checker (`237` bundle functions, `32 ms` total solve time across `94` module certificates).
2. **External `z3` (`/usr/bin/z3`):** Independent industrial SMT solver.

| Verification Check (`G-SMT`) | Result |
| :--- | :--- |
| **Fresh `.smt2` Module Certificates (`lstd`, `critical_kernels`, `smtfix`)** | **`94 / 94` `unsat` (`100%` `lsmt` &amp; `z3` agreement)** |
| **Injected Codegen `.smt2` Mutants + Fixed Forged/SAT/Malformed Controls** | **`3,820` rejected (`3,626` mutants + `194` forged/SAT/truncated controls, `0` unsound acceptances)** |

---

## 3. Zero Uncovered Masking MC/DC &amp; Static Worst-Case Stack Bounds (`lmcdc.src`, `lstack.src`)

### Native-Binary Masking MC/DC (`lume mcdc --exec`)

[`compiler/stage1/lmcdc.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lmcdc.src) measures **Decision + Masking Modified Condition/Decision Coverage (MC/DC)** executed by real compiled native binaries, paired with `lcert` infeasibility proofs for unreachable defensive guards. Across all 4 certified core modules, **uncovered MC/DC is strictly `0 / 9,618`**:

| Certified Module | `ltv` Validated / Rejected | Native Vectors | Coverage Obligations | Witness Covered | Law Conclusion False | `lcert` Infeasible | **Uncovered (Must Be `0`)** |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `compiler/stage1/lstd.src` | `70 / 0` | `753` | `980` | `928` | `46` | `6` | **`0`** |
| `examples/safety_envelope/critical_kernels.src` | `5 / 0` | `52` | `112` | `112` | `0` | `0` | **`0`** |
| `compiler/stage1/lchameleon.src` | `160 / 0` | `1,781` | `2,392` | `2,118` | `256` | `18` | **`0`** |
| `compiler/stage1/lsentience.src` | `459 / 0` | `5,260` | `6,134` | `5,529` | `577` | `28` | **`0`** |
| **Total Across All 4 Certified Modules** | **`694 / 0`** | **`7,846`** | **`9,618`** | **`8,687`** | **`879`** | **`52`** | **`0 / 9,618`** |

### Static `@no_alloc` Stack Analyzer (`lume stack`)

[`compiler/stage1/lstack.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lstack.src) computes exact worst-case stack byte consumption directly over emitted x86-64 assembly across `@no_alloc` call DAGs, matching painted runtime stack high-water marks byte-for-byte (`G-REALTIME`) and failing closed (`exit 3`) on any unbounded frame or call cycle.

---

## 4. Constant-Time Cryptography, X.509v3 PKI, TLS 1.3 &amp; Entropy (`lcrypto_tls.src`, `lx509.src`)

[`compiler/stage1/lcrypto_tls.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lcrypto_tls.src) and [`compiler/stage1/lx509.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lx509.src) implement Lume's pure-Lume cryptographic and PKI stack (`7,232` checks in `G-CRYPTO`):

- **`118` Machine-Verified Constant-Time Kernels (`@secret @no_alloc` `[C0011]`):**
  - Every `@secret` function in `lcrypto_tls.src` (`118/118`) carries `@no_alloc`, compiles to **`15,378` branch-free instructions** (`cmov`, zero conditional jumps, zero divisions, zero non-kernel calls), passes transitive machine-code verification (`ltv` `[C0010]`, **`1,068/1,068` CT mutants killed**), and is bounded by `lstack` (**largest frame `536 B`** in `lct_k_fe_m0`).
  - Empirically verified for constant execution timing across **`24/24` `dudect` Welch $t$-test targets (`|t| <= 2.690 < 4.5`)**.
- **Cryptographic Primitives &amp; RFC 8446 TLS 1.3:**
  - FIPS 180-4 SHA-256 &amp; SHA-512, RFC 4231 HMAC, RFC 5869 HKDF, RFC 8439 ChaCha20-Poly1305 AEAD, RFC 7748 X25519 ECDH, RFC 8032 Ed25519 signatures, and authenticated TLS 1.3 key schedule, transcript binding, and AEAD record protection.
- **Strict X.509v3 Path Validation (`lume x509`) &amp; NIST SP 800-90B Entropy (`lume entropy`):**
  - Deterministic DER/PEM Ed25519 X.509v3 chain validator (`BasicConstraints`, `KeyUsage`, validity window, cryptographic chain signatures) that refused **`6,000 / 6,000` tampered certificate chains**.
  - Continuous NIST SP 800-90B Repetition Count Test (RCT) and Adaptive Proportion Test (APT) health checks over OS CSPRNG entropy before key generation.

```sh
lume crypto-gate
lume x509 show docs/certification/QUALIFICATION_SIGNING_CERT.der
lume entropy --bytes 32 --json
```

---

## 5. `2oo2D` Clean-Room Dual-Channel Safety Envelope (`lsafety_envelope.src`, `lrv32_lowered.src`)

To protect safety-critical actuation against residual compiler bugs and hardware bit-flips, [`compiler/stage1/lsafety_envelope.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lsafety_envelope.src) executes critical functions in **`2oo2D` (2-out-of-2 with Diverse Diagnostics) lockstep**:

- **Channel A (Primary Native Host):** Compiled by `lumec` to native `x86-64`, `AArch64`, or `RV64`.
- **Channel B (Clean-Room Bare-Metal `RV32IM`):** Compiled directly from `.src` to `RV32IM` machine code by [`compiler/stage1/lrv32_lowered.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lrv32_lowered.src), an independent clean-room frontend and code generator sharing **`0 / 3,169` functions** with `lumec`.
- **Zero Undetected Faults (`G-ENV`):** Across **`87,224` injected faults** (single/multi-bit register, RAM, and ROM upsets, frontend mutants, and backend codegen mutants), the `2oo2D` voter caught **`100%` of behavior-diverging faults (`0` undetected / `0` false negatives)**.
- **Multi-Board Split Bundles (`--split`):** Exports standalone Channel A and Channel B artifacts with SHA-256 manifests and framed inter-channel voting (`lume safety-envelope --split` / `--split-verify` / `--split-run`, specified in [`docs/41-safety-envelope-split-bundle.md`](https://github.com/OmegaSoftDLL/lume/blob/main/docs/41-safety-envelope-split-bundle.md)).

---

## 6. Ed25519 + X.509v3-Signed Tool Qualification Dossier (`lume qualify` — `PASS`)

[`compiler/stage1/lqualify.src`](https://github.com/OmegaSoftDLL/lume/blob/main/compiler/stage1/lqualify.src) orchestrates the complete qualification campaign and emits hash-chained, cryptographically signed evidence under [`docs/certification/`](https://github.com/OmegaSoftDLL/lume/tree/main/docs/certification):

| Qualification Item | Verified Result (`docs/certification/QUALIFICATION_DOSSIER.md`) |
| :--- | :--- |
| **Overall Campaign Result** | **`PASS`** |
| **Requirement Probes (Positive &amp; Negative)** | **`106 / 106` passed** |
| **End-to-End Verification Gates (`G-BOOT` .. `G-CLI`)** | **`21 / 21` passed** (`G-SYNERGY`: `17/17` stages, `36/36` tamper checks) |
| **Operational &amp; Tool Requirements (`TOR` / `TQP` / `RTM`)** | **`10` HLR &amp; `44 / 44` LLR fully traced (`VERIFIED`)** |
| **Uncovered Certified-Module MC/DC** | **`0 / 9,618`** |
| **Cryptographic Attestation** | SHA-256 evidence chain + **RFC 8032 Ed25519 signature** (`QUALIFICATION_EVIDENCE.sig.json`) + **RFC 8410 Ed25519 X.509v3 certificate** (`QUALIFICATION_SIGNING_CERT.der`) |

```sh
lume qualify --verify    # Re-verifies SHA-256 chain, Ed25519 signature & X.509v3 path offline
lume synergy-gate        # Runs 17-stage cross-module pipeline + 36/36 tamper rejections
lume qualify             # Executes full 106-probe, 21-gate, 4-module MC/DC campaign
```

> **Institutional Engineering Scope:** As documented in [`QUALIFICATION_DOSSIER.md`](https://github.com/OmegaSoftDLL/lume/blob/main/docs/certification/QUALIFICATION_DOSSIER.md), `lume qualify` produces reproducible developer verification evidence; formal tool qualification credit under DO-330, IEC 61508, ISO 26262, or IEC 62304 is always granted per project by the cognizant certification authority or assessor against project-specific operational requirements.
