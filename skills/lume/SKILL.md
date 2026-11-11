---
name: lume
description: Complete guide to programming in the Lume programming language (v1.1.0) — syntax, Hindley-Milner type system, ownership and Perceus memory management, formal QF_LIA verification (requires/ensures/law, lume prove, lume certify, lume self-prove), financial decimals and persistent tables, shape-checked tensors and GPU kernels (PTX/SPIR-V), bare-metal Ring-0 kernels (@freestanding), Clean Generic Win64 Native GUI (--target x86_64-windows-gui), Universal Chameleon 9-ecosystem polyglot interop (lchameleon.src, lume chameleon, lume adapt, lume morph), and Sovereign Sentience CLI commands. Always use this skill whenever the user asks to write, read, debug, prove, compile, or evolve code in Lume (.src or .lume files) or use the lume CLI.
license: Apache-2.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Programming in Lume (v1.1.0)

Lume is a **self-hosted, formally verified systems, AI, and quantum programming language** designed to be written seamlessly by both humans and AI agents. Every Lume program compiles directly to native machine code (`x86_64`, `aarch64`, `riscv64`, `wasm32-wasi`, `@freestanding` zero-GC bare-metal `.kernel` MBR/Long-Mode images, CUDA `PTX`, and Vulkan `SPIR-V`) with built-in **`QF_LIA` theorem proving** (`lume prove` and `lume certify`) at compile time, a single-source segregated Mark & Lazy-Sweep GC (`compiler/stage1/runtime_core.lume`), and the **4-Tier Atomic Memory Compactor** (`docs/39-memory-saga-and-atomic-compactor-dossier.md`).

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

# Universal Chameleon Polyglot Interop Engine (9 verified ecosystems) & Cyber-Physical Engines
lume chameleon
lume camaleao rust
lume polyglot
lume ffi-bridge
lume adapt <c|c-raw|rust|python|js|go|java|dotnet|sql|openapi> [file]
lume adapt c --preprocess <header.h>
lume morph <legacy_file>
lume unified-field
lume singularity
lume net-sentinel
lume lumeputer
lume lumepu
lume qwenputer

# Certification tools (Wave 11): translation validation, MC/DC, 2oo2 lockstep envelope, qualification dossier
lume tv app.src --exec
lume mcdc app.src --exec
lume safety-envelope kernel.src --fn dose --args 700,500
lume qualify            # developer evidence (TOR, TQP, RTM, signed dossier), not a qualification
lume qualify --verify   # re-check the SHA-256 chain and Ed25519 signature of build/certification/

# Industrial options (Waves 12-13)
lume build -g app.src -o app                      # DWARF v4 line table and symbols
lume build --critical app.src -o app              # keep the run-time checks of proven ensures
lume build --target aarch64-linux-gnu kernel.src -o kernel.a64     # also riscv64-linux-gnu, riscv64-none-elf, riscv32-none-elf, ...
lume build --target safetensors --entry dose kernel.src -o dose.safetensors
lume proof-cache store app.src .lume_cache && lume proof-cache check app.src .lume_cache --require-all-hits
lume certify app.src > cert.json && lume verify-cert --check-source app.src cert.json

# Built-in full language manual (English or Brazilian Portuguese)
lume manual en
lume manual pt-br
```

Rules that the Wave 12-13 checks enforce (write code that satisfies them the first time):

- `@no_alloc fn`: `int` / `bool` parameters with `requires` bounds on every parameter, arithmetic that provably
  stays inside 63 bits, no record, list, string or allocating builtin, callees `@no_alloc` too, recursion only in
  tail position. Anything else is `[E0210]`.
- `@secret fn`: no branch, division or table index on a secret (`[C0009]` at source level; `lume tv` adds `[C0010]`
  on the emitted code AND on every routine it calls, so a plain `@secret fn` that uses `+` or a bit operation is
  refused there: its runtime helpers branch).
- Constant-time kernel = `@secret` + `@no_alloc` on the same function: `int` parameters and result, no `requires`,
  `ensures` only if proven, body of `+ - * +% -% *%`, `bit_and` / `bit_or` / `bit_xor` / `bit_not`, `bit_shl` /
  `bit_shr` by a literal, `ct_select(mask, a, b)`, `ct_eq(a, b)` and calls of other kernels; no `if` / `match` /
  comparison / `/` / `%` / recursion (`[C0011]`); mask operands with `bit_and` until every sum and product is
  proven inside 63 bits (`[E0210]`). It compiles to branch-free code that `lume tv` validates.
- A value passed to `chan_send_linear` is gone (`[E0305]`); take locks in ascending rank and release them (`[E0306]`).
- The AArch64 / RISC-V targets accept the integer kernel fragment only (`[T0901]`) and only sources `lumec` accepts
  (`[T0902]`).
- `use lcrypto_tls` gives SHA-256/512, HMAC, HKDF, ChaCha20-Poly1305, Ed25519, X25519 and a TLS 1.3 client / server
  (one suite, x25519, pinned raw Ed25519 key, no X.509, caller-supplied randomness).

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
> 1. **Comments:** Always use `#` or `##` for line comments (never `//`).
> 2. **Logical & Checked Arithmetic Operators:** Use `and`, `or`, `not` (`not` binds looser than `==`/`<`, so `not 1 == 2` is `not (1 == 2)`) in `requires`, `ensures`, and `law`. Signed 64-bit `+`, `-`, `*` trap on overflow (exit 3, `jo __rt_ovf`); use `+%`, `-%`, `*%` when 2's-complement wrapping is intended.
> 3. **Conditional, List & Indexing Expressions:** Both `if cond then a else b` and braced `if cond { a } else { b }` are supported; list literals `[]` (`Nil`) and `[1, 2, 3]` (`Cons` chains, `count([1, 2, 3]) == 3`) and postfix indexing `xs[i]` (on lists and strings; out-of-range traps with exit 3, whereas `at(s, i)` returns `""` past the end) work directly in `.src`.
> 4. **Pattern Matching & Hardened String Interpolation:** `match` works at top level, nested in `let`/`if`, call arguments, record fields, and `match` arms (or braced `match x { Pat => body, ... }`). Non-exhaustive `match` on a declared `enum` is rejected with `[T1002]`. Raw JSON strings `"{\"a\":{\"b\":1}}"`, JS/CSS blocks (`isbadholech` / `isjsblock`), and `/ {ffi}` effect annotations inside strings are preserved as literal `{`; format specifiers `"{x:04x}"` are supported, plain chunks are scanned in $O(1)$ via `strplainchunk`/`cs_strplainchunk` without per-character `Cons` heap pressure (`win64_gui_and_interp_regression_ok.src` `8/8`), and literal interpolation braces can be escaped with `"\{x}"`, `"{{x}}"`, or `"cost: \${x}"`.
> 5. **Pure LF (`\n`) Line Endings:** Always save `.src`, `.lume`, `.expected`, and `.sh` files with pure `LF (\n)`, never `CRLF (\r\n)`, and never edit generated `compiler/stage1/lumec.src` directly (`make amalgamate`).

### 2.1 Stage-1 `.src` Builtins, 4-Tier Atomic Memory Compactor & Invariants

- **Core Builtins:**
  - Strings & Collections: `count(s_or_list)`, `at(s, i)`, `slice(s, start, end)`, `slicen(s, len, start, end)`, `ord(ch)`, `chr(code)`, `toint(s)`, `str(v)`
  - Filesystem & OS Process Execution: `fs_read_file(path)`, `fs_write_file(path, data)`, `fs_write_sync(path, data)`, `fs_path_exists(path)`, `fs_read_byte(path, offset)`, `os_run(cmd, args)`, `os_getenv(name)`, `os_argc()`, `os_argv(i)`
  - Memory, GC & Atomic Compactor (`use arena`): `arena_new(cap)`, `arena_reset(a)`, `arena_destroy(a)`, `mem_pack(s)`, `mem_unpack(b)`, `arena_freeze(a)`, `arena_thaw(a)`, `arena_compact(a)`, `arena_mark_secret(a)`, `heap_stats()`, `heap_peak_used()`, `gc_collect()`, `gc_count()`, CLI `lume pack <in> -o <out>` / `lume unpack <in> -o <out>`
- **4-Tier Atomic Memory Compactor (`docs/39-memory-saga-and-atomic-compactor-dossier.md`):**
  - **Stage 0 (`.rodata`):** String literals, constructor descriptors, record shapes, and zero-arity constructors (`Nil`, `None` = `0 B` heap) live in `.rodata`.
  - **Level 1 (64-Bit Tagged Register Word):** 63-bit signed integers (`...iiii1`) and `0..7`-byte inline SSO strings (`...ss|lll|010`) live inside a single 64-bit CPU register word (`0 B` heap, beating Rust's 24-byte + heap `String`), while full 64-bit `int` semantics are preserved via a 16-byte overflow cell `[3][value]`.
  - **Level 2 (Compact Cells):** `Cons(h, t)` is `24 B` (down from `80 B`); a 3-field record is `32 B` (down from `160 B`).
  - **Level 3 (Cold Arena Demand-Paged `LZ1` Compactor):** `mem_pack` (`~355 MB/s`) and `mem_unpack` (`~975 MB/s`) compress cold arenas (`arena_freeze`, `LUME_ARENA_COLD=<n>`) and `.lcaps`/`.lumb` bundles with a 64-bit checksum and lazy per-page `PROT_NONE` + `SIGSEGV` thaw on first touch (`@secret` `[C0009]` and `@bound` `[V0002]` fail closed).
- **Implication Idiom in `law`:** Express logical implication $P \implies Q$ inside `law` declarations using `if P then Q else 1 == 1`, which reduces directly to decidable branches in both `lcaas.src` and the independent proof kernel `lcert.src` (which also verifies compound `terminates` obligations via `lk_prove_term_cond` and NIST FIPS 180-4 SHA-256 KAT).
- **Decidable `QF_LIA` vs. `runtime_checked`:** Linear integer arithmetic (`a + b`, `a - b`, `c * x` with constant integer `c`) is proven statically at compile time by `lcaas` and verified by `lcert`. Non-linear variable multiplication (`x * y`) falls outside pure `QF_LIA` and is marked `runtime_checked` unless bounded within the degree-2 Positivstellensatz `QF_NIA` fragment (`x >= 0 and y >= 0`).
- **Arbitrary Function Arity, First-Class Functions & O(1)-Stack Structural Equality:** Functions and closures support any number of parameters (`1..6` in SysV AMD64 registers `%rdi..%r9`, `7+` on the stack with swap-safe self-tail-call optimization `jmp`), named functions are first-class values, and `==`/`!=` uses an explicit heap worklist (`O(1)` native stack) on arbitrarily deep lists, ADTs, and records.
- **Unit Test Convention:** Any zero-argument function named `fn test_<name>() = <bool_expr>` is automatically discovered and executed by `lume test <file.src>`.

---

## 3. Core Capabilities, Sovereign Engines & Verified Capstones

| Pillar | Key Constructs | Reference Guide |
|---|---|---|
| **Types, ADTs, Ownership & Effects** | `type`, `match`, `own`, `mut`, `&T`, `effect`, `handle`, Perceus reuse | Read [`references/language-syntax-and-types.md`](references/language-syntax-and-types.md) |
| **Formal Verification (`QF_LIA`) & Hole Synthesis** | `requires`, `ensures`, `law`, `??` (synthesis hole), `@bound(cycles: N)`, `lume prove`, `lume certify` | Read [`references/verification-and-prover.md`](references/verification-and-prover.md) |
| **Financial Data, Tensors/GPU & Ring-0 Systems** | `decimal(p,s)`, `money[CCY]`, `persist table`, `tensor[DType, ...]`, `grad`, `@schedule kernel fn`, `@freestanding`, `@repr(c)`, `@mmio` | Read [`references/data-ai-and-systems.md`](references/data-ai-and-systems.md) |
| **CLI, Self-Evolution & Sovereign Sentience** | `lume consult`, `lume self-prove` (`LumeCompiler-Embedded-OmniProof-v3`: `15` batteries, `700` obligations, `162` tests, `99` manifest files, `112` autonomous evolution domains `#0..#111`, `17` `LumePuter`/`LumePU` modules), `lume self-build`, `lume daemon-triad`, `lume hot-evolve`, `lume live-cockpit`, `lume swarm-evolve`, `lume evolve`, `lume reveng`, `lume neural-kernel`, `lume ui-layout`, `lume lumeputer`, `lume lumepu`, `lume qwenputer`, `lume mesh` (`lsentience.src`: `80` obligations, `21` tests) | Read [`references/cli-and-sentience-toolchain.md`](references/cli-and-sentience-toolchain.md) |
| **LumePuter & LumePU Weight-Compiled RV32IM_Zba + VX NPU In-Weights VM, Trap/CSR + In-Weights `lcert` Verifier, Octagon/Farkas/Bit-Shift/Horner-Bernstein/Inductive-Graph/AST-Quadratic Prover, Incremental Interface Cache v2, `#334` FFI Callback Arena Epoch Guard, `#407` Fuzzy Symbol/Arity Repair, Deep SSA/Chaitin RegAlloc/AVX2-VEX & AVX-512-EVEX Hardware SIMD, Automated OS/Socket/CUDA + Real Linux Kernel `io_uring` Syscalls, Industrial C Header Preprocessor/Parser, Structural Compiler Pass Self-Evolver & Wave 10 Critical Production-Assurance Suite (17 Modules & 112 Domains)** | `compiler/stage1/lchameleon.src` (`200/200` proven obligations, `19/19` tests), `lsentience.src`, `ltarget.src` (`--target lumeputer-rv32im-weights`), `stdlib/std.lume`, `lstd.src`, `tensor.src`, `nn.src`, `ai_runtime.src`, `lume_llm_core.src`, `lume_opentpu_engine.src`, `lume_ncm_engine.src`, `lume_continuum_nexus_engine.src` (`lume lumeputer`, `lume lumepu`, `lume qwenputer`, REPL `:lumeputer` / `:lumepu` / `:qwenputer` — exact SwiGLU `ReLU` gate `lumeputer_swiglu_exact_relu_unit`, `lumeputer_swiglu_relu_zero_gate_law`, RMSNorm ballast norm-absorption guard `lumeputer_ballast_rmsnorm_guard_ok`, `lumeputer_norm_absorption_immunity_law`, zero-drift Gated DeltaNet addressable RAM `lumeputer_deltanet_ram_step_exact`, `lumeputer_deltanet_zero_drift_retention_law`, 4-byte aligned RV32IM PC `lumeputer_rv32im_pc_step`, `lumeputer_rv32im_pc_4byte_aligned_law`, 128-digit Bignum `BMAC` `lumeputer_bmac_digit_file_step`, NPU `VDOT` `int8 * int4` MAC `lumepu_vdot_int8_int4_mac`, VX Streaming Vector Unit `VMAT` 64-lane row MAC `lumepu_vx_vmat_row_mac_exact`, `lumepu_vx_vmat_zero_bf16_drift_law`, 11/13-layer weight compiler `lumeputer_compile_rv32_vx_to_weights_layers`, Wave 6 recursive stack `.lweights` compiler `lumeputer_stack_push_frame_sp` / `lumeputer_compile_src_bundle_lweights`, Relational Octagon/Interval loop prover `prover_octagon_transitive_upper` / `prover_loop_ranking_steps_remaining`, Incremental Interface Cache v2 `incremental_module_iface_digest` / `incremental_can_reuse_downstream_mod`, Wave 7 Trap/CSR `ecall`/`mret` & In-Weights `lcert` verifier `lumeputer_ecall_save_mepc` / `lumeputer_mret_restore_pc` / `lumeputer_inweights_lcert_check`, Farkas Lemma linear dual certificate & exact bit-shift `shl` bounds `prover_farkas_dual_rhs_sum` / `prover_farkas_unsat_witness_ok` / `prover_bitshift_shl_exact_bound`, `#334` FFI callback arena epoch guard `ffi_callback_arena_epoch_safe` & `#407` fuzzy symbol/arity repair `diag_fuzzy_repair_distance_score` / `diag_fuzzy_repair_suggest_ok`, Wave 8 Deep SSA/Chaitin RegAlloc/AVX-512 `ssa_chaitin_register_spill_cost` / `ssa_interprocedural_inline_gain` / `avx512_autovec_loop_speedup_lanes`, Automated OS/POSIX/CUDA `io_uring` zero-copy FFI bridge `ffi_auto_header_abi_layout_ok` / `io_uring_zero_copy_ring_submit`, Non-Linear Horner/Bernstein & Inductive Graph DAG prover `prover_nonlinear_horner_lower_bound` / `prover_inductive_graph_dag_rank_ok`, Structural Compiler Pass Self-Evolver `compiler_pass_evolve_verified_promote`, Wave 9 real x86-64 VEX (`AVX2` `%ymm0..%ymm15`) & EVEX (`AVX-512` `%zmm0..%zmm15`) machine-code encoding in `lasm.src` + hardware SIMD intrinsics (`simd_add4_i64`, `simd_sub4_i64`, `simd_xor4_i64`, `vex_simd_hardware_add4_sum`), real Linux kernel `io_uring` syscalls (`os_io_uring_setup` = 425, `os_io_uring_enter` = 426, `os_io_uring_register` = 427, `io_uring_kernel_syscall_sqe_batch_safe`), native AST `x * x` quadratic Horner square-completion prover (`ast_native_horner_quadratic_eval`, `ast_native_quadratic_square_completion_law`) in `06b_phase3.src` and `lcaas.src`, industrial C header preprocessor & auto-parser (`lume adapt c --preprocess <header.h>` / `lume adapt c-raw <header.h>`, `c_header_preprocessor_macro_strip_ok`), Wave 10 Critical Production-Assurance & Independent Verification Suite (`#108` `LASM_Differential_Assembler_Oracle` `lasm_vs_gnu_as_differential_byte_eq` / `lasm_differential_Mismatch_rejected_law`, `#109` `Adversarial_Prover_False_Theorem_Fuzzer` `prover_adversarial_false_theorem_rejected` / `prover_unsound_acceptance_rejected_law`, `#110` `Gate_Mutation_Testing_Kill_Verifier` `mutation_testing_kill_ratio_verified` / `mutation_surviving_mutant_rejected_law`, `#111` `Wheeler_Diverse_Double_Compilation_DDC` `ddc_diverse_double_compilation_bit_identical` / `ddc_bootstrap_divergence_rejected_law`), and 112-domain `#0..#111` 24/7 Sanctuary Evolver) | `lume lumeputer` |
| **Universal Chameleon Polyglot Interop & Win64 Native GUI (`@ui-layout`)** | `compiler/stage1/lchameleon.src` (`lume chameleon [eco]`, `lume camaleao`, `lume polyglot`, `lume ffi-bridge`, `lume adapt <c\|c-raw\|rust\|python\|js\|go\|java\|dotnet\|sql\|openapi> [file]`, `lume adapt c --preprocess <header.h>`, `lume morph <file>` across 9 ecosystems: `c_abi`, `rust_cdylib`, `python_capi` DLPack, `node_napi_wasm`, `go_cshared`, `java_jni`, `dotnet_pinvoke`, `sql_relational`, `openapi_rpc` with `[I0003]` fail-closed `QF_LIA` contracts, `#334` `ffi_callback_arena_epoch_safe`, `ffi_auto_header_abi_layout_ok`, `io_uring_zero_copy_ring_submit`, `io_uring_kernel_syscall_sqe_batch_safe` & `c_header_preprocessor_macro_strip_ok`, `200/200` proven obligations, `19/19` tests), `--target x86_64-windows-gui` (`ltarget.src`: 33,792B PE32+ GUI, zero Notepad++ strings, `hMenu=0`, `Segoe UI -12`, wide buttons, 4 `WS_CLIPSIBLINGS \| WS_THICKFRAME \| WS_HSCROLL \| WS_VSCROLL` panes with `LB_SETHORIZONTALEXTENT = 680`), and declarative `lume ui-layout` / `@ui-layout` (`1412694337` / `0x54340141` Listbox + `1412698308` / `0x543410C4` Edit styles, `ui_split_conservation_law`) | `lume test compiler/stage1/lchameleon.src` |
| **Formally Verified Generic Collection Invariants** | `compiler/stage1/vec.src`, `compiler/stage1/decimal.src`, `stdlib/std.lume` (`vec_clamp_index`, `vec_checked_slice_len`, `map_checked_slot`, `decimal_clamp`) | `lume test compiler/stage1/decimal.src` |
| **Cyber-Physical Unified Field & Subsea (`UFE`), Singularity Transition Engine & Bayesian SPC (`OTE`) & NetSentinel IEC 62443 / Conduite / Omega-Mesh** | `std.gfx` (`lume unified-field` / `lume ufe` / `lume subsea` — `77/77` proofs, `15/15` tests: 7-DOF DLS `ufe_dls_lambda_sq_milli`, `ufe_dls_safe_denom_milli`, 3D Laplace SOR `ufe_laplace_sor_step_milli`, `ufe_harmonic_maximum_principle_law`, GNRON swirl `ufe_gnron_swirl_scale_milli`, capsule self-collision `ufe_self_collision_capsule_ok`, `ufe_ieee754_f32_finite_guard`, $5\sigma$ + Joseph EKF `ufe_ekf_mahalanobis_5sigma_ok`, `ufe_ekf_joseph_cov_pos_milli`, `ufe_actuator_stiction_detect`, `ufe_actuator_rul_hours`, `ufe_swarm_separation_ok`, IAPWS-IF97 + Carnot `ufe_if97_region_select`, `ufe_turbine_wet_steam_guard`, `ufe_carnot_efficiency_bound_ok`, 1 kHz `ufe_latency_shedder_step`, Subsea Catenary & API RP 1111 `subsea_catenary_top_tension_n`, `subsea_catenary_tdp_bend_ok`, `subsea_combined_longitudinal_stress_ok`, VIV & Palmgren-Miner `subsea_viv_screening_ok`, `subsea_miner_fatigue_safe_ok`, Heavy-Lift DAF `marine_dnv_daf_floor_milli`, `marine_heavy_lift_feasible_ok`, Bühlmann ZH-L16C `subsea_hyperbaric_decompression_safe_ok`, Well-Kill `subsea_well_kill_icp_kpa`, `subsea_well_kill_mud_sg_milli`, ASME B31G `subsea_b31g_corroded_pipe_safe_ok`), `lchameleon.src` (`lume singularity` / `lume ote` — `68/68` proofs, `12/12` tests: dual-regime step ID & $\zeta$ estimator `ote_select_damping_regime`, `ote_estimate_zeta_milli`, Power Triangle `ote_power_factor_milli`, `ote_reactive_waste_ratio_milli`, `ote_phase_coherence_ok`, Singularity Boundary $\Omega$ $\tau_{\max} = T_m/4$ `ote_singularity_tau_max_ms`, `ote_omega_boundary_crossed`, `ote_singularity_margin_zone`, `ote_nyquist_status_code`, `ote_cascade_bandwidth_decoupled_ok`, `ote_retune_kp_scale_milli`, 9 leverage-ordered prescriptions `ote_diagnose_primary_code`, Bayesian SPC & CUSUM `spc_beta_binomial_posterior_num`, `spc_cusum_upper_step_milli`, CPM float `ops_cpm_total_float_hours`, $k$-anonymous PAVA `analytics_k_anonymity_release_ok`, `analytics_pava_monotonic_pair_hi`), and `std.net` (`lume net-sentinel` / `lume iec62443` / `lume conduite` / `lume omega-mesh` — `68/68` proofs, `27/27` tests: Purdue `L0..L4` + `L3.5` DMZ `iec62443_purdue_conduit_ok`, `netsentinel_fw_policy_audit_ok`, `ot_readonly_dcs_guard`, `ot_tristate_quality_code`, `ot_finite_sentinel_clamp`, Conduite `conduit_admin_timeout_ok`, `conduit_ha_failover_parity_ok`, `conduit_severity_escalate_rank`, `ot_goose_state_transition_code`, `netsentinel_posture_traffic_confirmed`, `netsentinel_broadcast_storm_code`, and Omega-Mesh P2P `mesh_frame_bounds_ok`, `mesh_atomic_dual_rate_deduct`, `mesh_dht_healing_rank`, `mesh_raft_quorum_ok`, `mesh_raft_backtrack_index`, `mesh_tofu_verify_code`, `mesh_channel_mux_quota_ok`) | `lume test compiler/stage1/lchameleon.src` |
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

### 3.3 Official Brand Identity, Lumi Mascot & Visual Architecture Assets (`docs/assets/`)
- **Lumi — Bioluminescent Crystal Chameleon Mascot:** `docs/assets/lume-mascot.jpg`, `docs/assets/lume-icon.jpg`, and `docs/assets/lume.ico`.
- **Animated SVG Showcases:** `docs/assets/lume-hero-animated.svg` (IDE + `QF_LIA` prover + 27-target compiler), `docs/assets/lume-chameleon-showcase.svg` (`lchameleon.src` 9-ecosystem `[I0003]` fail-closed polyglot bridge), and `docs/assets/lume-memory-evolution-animated.svg` (4-Tier Atomic Memory Compactor).

---

## 4. Standard Workflow for AI Agents Writing Lume

1. **Consult Sovereign Memory First (Optional):**
   Run `lume consult "<intent>"` to retrieve proven `QF_LIA` laws and hyperdimensional context vectors.
2. **Model Domain Types & Contracts Explicitly:**
   Write `requires` and `ensures` on critical functions and at least one `law` theorem per module.
3. **Verify & Execute:**
   Run `lume prove <file.src>`, `lume test <file.src>`, and `lume run <file.src>` to confirm 100% proven obligations (`"status":"proven"`) and deterministic execution.
