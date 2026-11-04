# Wave 4 (`Onda 4` — `v0.3.0-alpha.4` @ `8c1983e`) — Complete Technical Audit & Live Verification Proof

**Audit Date:** 2026-11-04
**Base Wave 4 Commit:** `8c1983e` (`feat(wave4): complete P35 verification, P33 protection, comptime embed/schema, and zero_c`)
**Audit & WASM Binary Section Parser Upgrade Commit:** Recorded on `feat/p0-full-integration`
**Auditor:** Lume Core Engineering (Sovereign Triad)

---

## 1. Executive Summary

Wave 4 (`v0.3.0-alpha.4`) replaced remaining shell scripts with self-hosted Lume programs (`scripts/amalgamate.src` and `scripts/zero_c.src`), added compile-time capability-gated file embedding (`comptime embed("path")`) and compile-time relational schema synthesis (`comptime table_schema(RecordType)`), implemented P35 hardware/freestanding verification (`compiler/stage1/p35_ok.src`), added P33 secret scanning (`[W0002]`) in `compiler/stage1/lprotect.src`, and introduced the binary WebAssembly capability sandbox (`@wasm-sandbox` `[I0275]`) in `compiler/stage1/ltarget.src`.

During this line-by-line audit, we verified all 5 subsystems and **upgraded `wasm_sandbox_verify` in `compiler/stage1/ltarget.src`** so that in addition to checking the 8-byte WASM magic/version header (`0061736d01000000`), it decodes the binary WebAssembly sections via ULEB128 (`wasm_read_uleb`, `wasm_walk_sections`), parses **Section 2 (Import Section)** (`wasm_verify_import_sec`) to verify every `(module, field)` import pair against the capability allowlist, and parses **Section 5 (Memory Section)** (`wasm_parse_mem_sec`) to extract the actual initial page count and reject out-of-bounds memory limits (`> 16` pages) with `[I0275]`.

| Subsystem | Source Files | Self-Hosted Verification | Status |
| :--- | :--- | :--- | :--- |
| **4.1 Atomic Amalgamation & Self-Hosted Zero-C Gate** | `scripts/amalgamate.src`, `scripts/zero_c.src` | `lume test scripts/amalgamate.src` (`1/1`) & `lume test scripts/zero_c.src` (`15/15`) | **PASS (100%)** |
| **4.2 `comptime embed("path")` & `comptime table_schema(RecordType)`** | `compiler/stage1/lume/06b_phase3.src`, `compiler/stage1/data_eval.lume` | Positive build/run (`#LumeEmbeddedAsset` + `CREATE TABLE IF NOT EXISTS InvoiceRow`) + `[E0200]`, `[C0271]`, `[D0273]` | **PASS (100%)** |
| **4.3 P35 Public API & Freestanding Hardware Verification** | `compiler/stage1/p35_ok.src`, `compiler/stage1/lume/06b_phase3.src` | `lume test compiler/stage1/p35_ok.src` (`6/6`) + `example_<name>()` + `[V0001]` under `## @strict_p35` | **PASS (100%)** |
| **4.4 P33 Secret Scanner (`[W0002]`) & Binary Protection** | `compiler/stage1/lprotect.src` | `lume test compiler/stage1/lprotect.src` (`2/2`) + live `@scan-secrets` CLI verification | **PASS (100%)** |
| **4.5 Binary WASM Capability Sandbox (`[I0275]`) & UEFI PE64** | `compiler/stage1/ltarget.src` | `lume test compiler/stage1/ltarget.src` (`11/11`) with binary Section 2 & Section 5 ULEB128 parser | **PASS (100% — Upgraded)** |

---

## 2. Detailed Audit & Upgraded Binary WASM Section Parser

### 2.1 Self-Hosted Amalgamation (`scripts/amalgamate.src`) & Zero-C Gate (`scripts/zero_c.src`)
- **Implementation:**
  - `scripts/amalgamate.src` concatenates all 8 stage1 compiler modules (`00_prelude.src` .. `07_driver.src`) into a temporary file and atomically renames it to `compiler/stage1/lumec.src` so concurrent processes never observe a truncated compiler source.
  - `scripts/zero_c.src` implements the complete Zero-C bootstrap and bit-for-bit fixpoint gate (`lumec2 == lumec3`, `lasm`, `lcli`) in pure Lume without invoking `gcc`, `clang`, `cc`, `ld`, or `as`.
- **Live Verification Output:**
  ```text
  $ lume test scripts/amalgamate.src
    ok   test_amalgamate_parts_exist
  1 passed, 0 failed

  $ lume test scripts/zero_c.src
    ok   test_zc_find_last_slash
    ok   test_zc_dirname
    ok   test_zc_resolve_root_from_script
    ok   test_zc_strip_trail_nl
    ok   test_zc_first_token
    ok   test_zc_has_prefix
    ok   test_zc_parse_opt_default
    ok   test_zc_parse_opt_lumec
    ok   test_zc_parse_opt_lasm
    ok   test_zc_parse_opt_help
    ok   test_zc_parse_opt_unknown
    ok   test_zc_check_bin_exists
    ok   test_zc_verify_elf64_magic
    ok   test_zc_sha256_match
    ok   test_zc_amalgamate_matches_parts
  15 passed, 0 failed
  ```

### 2.2 `comptime embed("path")` (`[E0200]` / `[C0271]`) & `comptime table_schema(RecordType)` (`[D0273]`)
- **Implementation (`compiler/stage1/lume/06b_phase3.src` & `compiler/stage1/data_eval.lume`):**
  - `comptime embed("path")` requires `@capability fs` in the module header (`[E0200]` if missing), verifies the file exists at compile time (`[C0271]` if missing), and embeds its contents as a compile-time string literal.
  - `comptime table_schema(RecordType)` inspects a record `type` declaration at compile time (`[D0273]` if undefined or not a record) and synthesizes deterministic SQL DDL (`CREATE TABLE IF NOT EXISTS <Name> (...);`).
- **Live Verification Output:**
  ```text
  --- 4.2a comptime embed + comptime table_schema (positive) ---
  asset=#LumeEmbeddedAsset_v4
  schema=CREATE TABLE IF NOT EXISTS InvoiceRow (id INTEGER NOT NULL, tenant TEXT NOT NULL, amount_cents INTEGER NOT NULL);
  --- 4.2b comptime embed without @capability fs ([E0200]) ---
  lumec: capability error [E0200]: 'comptime embed("...")' requires '@capability fs' declaration in module header
  --- 4.2c comptime embed missing file ([C0271]) ---
  lumec: comptime error [C0271]: comptime embed('/tmp/nonexistent_w4_file_xyz.txt') failed: file not found
  --- 4.2d comptime table_schema unknown type ([D0273]) ---
  lumec: schema error [D0273]: comptime table_schema('NonExistentType') requires a declared record 'type NonExistentType = { ... }'
  ```

### 2.3 P35 Public API & Freestanding Hardware Verification (`compiler/stage1/p35_ok.src`)
- **Implementation (`compiler/stage1/p35_ok.src` & `compiler/stage1/lume/06b_phase3.src`):**
  - Enforces public API example coverage (`pub fn <name>` paired with `fn example_<name>()`), `## @strict_p35` contract enforcement (`[V0001]`), `@packed` / `@bits` bitfield widths, `@mmio` volatile register bounds, and freestanding capability safety.
- **Live Verification Output:**
  ```text
  $ lume test compiler/stage1/p35_ok.src
    ok   test_p35_1_doc_examples_and_strict_contracts
    ok   test_p35_2_linear_drop_and_secret_zeroize
    ok   test_p35_3_mmio_bitfields_and_packed_layout
    ok   test_p35_4_deterministic_wcet_and_freestanding_no_alloc
    ok   test_p35_5_supply_chain_sbom_and_deterministic_build
    ok   test_p35_6_locale_independent_diagnostics
  6 passed, 0 failed

  --- 4.3b @strict_p35 missing contract rejection ([V0001]) ---
  lumec: verification error [V0001]: public function 'unverified_api' under '@strict_p35' requires an explicit 'requires' or 'ensures' contract or a companion 'fn example_unverified_api()'
  ```

### 2.4 P33 Secret Scanner (`[W0002]`) (`compiler/stage1/lprotect.src`)
- **Implementation (`compiler/stage1/lprotect.src`):**
  - `lp_scan_secrets_src(src)` scans string literals for high-entropy / credential patterns (`AKIA`, `ghp_`, `sk_live_`, `-----BEGIN`, `xoxb-`) while honoring `@allow_secret_literal` annotations, emitting `[W0002]` diagnostics.
- **Live Verification Output:**
  ```text
  $ lume test compiler/stage1/lprotect.src
    ok   test_p33_secret_scanner_and_symbol_obfuscation
    ok   test_p33_control_flow_flattening_and_lsym
  2 passed, 0 failed

  --- 4.4b Live secret scanner CLI check ([W0002]) ---
  lprotect: security warning [W0002]: potential hardcoded secret literal detected ('AKIAIOSFODNN7EXAMPLE...'); use environment/vault injection or annotate with '@allow_secret_literal'
  ```

### 2.5 Binary WASM Capability Sandbox (`[I0275]`) — Upgraded Binary Section Parser (`compiler/stage1/ltarget.src`)
- **Audit Finding & Engineering Fix:**
  - Initially, `wasm_sandbox_verify(wasm_hex)` in `compiler/stage1/ltarget.src` validated the 8-byte WASM magic header and scanned hex substrings while reporting a static `"memory_pages":1`.
  - We upgraded `compiler/stage1/ltarget.src` (lines 974–1000) with a complete binary WebAssembly section walker:
    - `wasm_read_uleb(bs)` decodes unsigned LEB128 integers from the binary byte stream.
    - `wasm_walk_sections(bs, mem_pages)` walks every binary section `(id, payload_len, payload_bytes)` after the 8-byte header.
    - `wasm_verify_import_sec(sec_bs)` parses **Section 2 (Import Section)**, decoding each `(module_name, field_name, import_desc)` entry and rejecting any import outside the sandbox capability allowlist (`wasi_snapshot_preview1.{fd_write,proc_exit}` and `env.{dom_append_int,dom_set_attr,web_trap}`) with `[I0275]`.
    - `wasm_parse_mem_sec(sec_bs)` parses **Section 5 (Memory Section)**, extracting the real `initial_pages` limit and rejecting memory configurations outside `1..16` pages (`64KB..1MB`) with `[I0275]`.
- **Live Verification Output:**
  ```text
  $ lume test compiler/stage1/ltarget.src
    ok   test_t0_orthogonal_target_triple_registry
    ok   test_t1_t2_aarch64_elf_and_macho_proof_preserving
    ok   test_t3_t4_pe64_and_riscv64_and_refuted_contract_rejection
    ok   test_t5_ihex_checksum_and_lumb_bytecode_vm
    ok   test_t6_gpu_ptx_and_spirv_lowering_and_vm
    ok   test_t7_mcu_cortexm_avr_xtensa_and_traps
    ok   test_t8_fpga_verilog_and_vhdl_rtl_sim
    ok   test_t9_mobile_ios_android_and_web_dom_wasm
    ok   test_t10_wasm_capability_sandbox
    ok   test_t11_lume_mir_and_store_packagers_apk_ipa_iso_uefi
    ok   test_t12_neural_kernel_differentiable_silicon
  11 passed, 0 failed
  ```
