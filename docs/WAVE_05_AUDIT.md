# Wave 5 (`Onda 5` — `v0.3.0-alpha.5` @ `2d54bcc`) — Complete Technical Audit, Bug Fixes & Live Verification Proof

**Audit Date:** 2026-11-04
**Base Wave 5 Commit:** `2d54bcc` (`feat(wave5): complete Track L runtime/storage/ML/net verifiers, full install manifest & docs (#257, #336, #433)`)
**Audit & Bug-Fix Commit:** Recorded on `feat/p0-full-integration`
**Auditor:** Lume Core Engineering (Sovereign Triad)

---

## 1. Executive Summary

Wave 5 (`v0.3.0-alpha.5`) completed the Track L (`#257`) domain runtime/storage/ML/networking/GUI/media modules, expanded `scripts/install.src` (`MANIFEST.sha256`) to cryptographically bind all 54 core compiler, driver, and standard library `.src` modules plus `levidence`, and promoted the corresponding Track L claims in `acceptance/matrix.json` and `docs/acceptance-matrix.md`.

During this line-by-line audit and live execution of all 10 Wave 5 suites (`79` unit tests + full `track_l_domains_ok.src` conformance diff), we discovered and fixed **two real bugs**:
1. **`scripts/docs_ci.src` (`test_required_empty_file_is_readable`, line 63):** Attempted to write `"build/docs-ci-empty-required"` before creating `"build"`, causing the test to fail when run in a clean worktree without an existing `build/` directory. Fixed by calling `let made = fs_mkdir("build")` before `fs_write_sync`.
2. **`compiler/stage1/ltest.src` (`synth`, line 78 — Triple-Evaluation & Stateful False-Pass Bug):** Previously, `ltest.src` emitted `print _t_msg(test_i(), "test_i")` followed by `print _t_sum(_t_ok(test_1()) + ..., n)` and `_t_chk(_t_ok(test_1()) + ..., n)`, evaluating every `test_*()` function **three times**. When `test_required_empty_file_is_readable` failed on its first evaluation (before a later test created `build/`), it succeeded on the second and third evaluations in `sumcalls`, causing `lume test` to print `FAIL test_required_empty_file_is_readable` while reporting `17 passed, 0 failed` and exiting `0`. We fixed `ltest.src` to evaluate each `test_<name>()` **exactly once** and accumulate the pass count in `.bss` (`hw_scratch_addr() + 4096` via `mmio_volatile_read64`/`mmio_volatile_write64`), eliminating stateful false passes and speeding up all `lume test` runs by **3x**.

| Subsystem | Source Files | Self-Hosted Verification | Status |
| :--- | :--- | :--- | :--- |
| **5.1 Async I/O Runtime & Multi-Worker OS Fork/Pipe** | `compiler/stage1/async_rt.src` | `lume test compiler/stage1/async_rt.src` (`6/6 passed`) | **PASS (100%)** |
| **5.2 Multi-Way B+Tree (Height 4) & ACID WAL Crash Recovery** | `compiler/stage1/db.src` | `lume test compiler/stage1/db.src` (`8/8 passed`) | **PASS (100%)** |
| **5.3 Binary `.safetensors` & Protobuf `.onnx` Wire Parsers** | `compiler/stage1/nn.src`, `compiler/stage1/tensor.src` | `lume test compiler/stage1/nn.src` (`11/11 passed`) | **PASS (100%)** |
| **5.4 RFC 793 TCP Pseudo-Header Checksum & TLS 1.3 Loopback** | `compiler/stage1/net.src` | `lume test compiler/stage1/net.src` (`7/7 passed`) | **PASS (100%)** |
| **5.5 2D Software Rasterizer, X11 Loopback & WASM DOM** | `compiler/stage1/gui.src` | `lume test compiler/stage1/gui.src` (`6/6 passed`) | **PASS (100%)** |
| **5.6 RIFF/WAV PCM16, 3-Tap FIR & Video GOP Delta Codec** | `compiler/stage1/media.src` | `lume test compiler/stage1/media.src` (`5/5 passed`) | **PASS (100%)** |
| **5.7 Portable Renewable Evidence Bundles (`#335`)** | `compiler/stage1/levidence.src` | `lume test compiler/stage1/levidence.src` (`7/7 passed`) | **PASS (100%)** |
| **5.8 Full Manifest Installer & Acceptance Matrix Validator** | `scripts/install.src`, `acceptance/matrix_assertions.src` | `lume test` (`5/5` & `14/14 passed`) | **PASS (100%)** |
| **5.9 Docs CI Gate & Single-Evaluation `ltest` Harness** | `scripts/docs_ci.src`, `compiler/stage1/ltest.src` | `lume test scripts/docs_ci.src` (`17/17 passed`) + single-eval fail-closed probe (`exit_code=3`) | **PASS (100% — Fixed)** |
| **5.10 End-to-End Track L Conformance (`#257`)** | `compiler/stage1/track_l_domains_ok.src` | `diff -u track_l_domains_ok_asm.expected` (`0 diff`) | **PASS (100%)** |

---

## 2. Detailed Line-by-Line Audit & Live Proofs

### 2.1 Async I/O Runtime & Multi-Worker OS Execution (`compiler/stage1/async_rt.src`)
- **Implementation:**
  - Readiness-polled I/O reactor (`reactor_new`, `reactor_submit_io`, `reactor_notify_fd_ready`), deadline-ordered timer wheel (`reactor_schedule_timer`, `reactor_advance_clock`), bounded `max_inflight` backpressure rejection, multi-worker work-stealing scheduler (`ws_pool_new`, `ws_steal_if_needed`, `ws_run_all`), native Linux `epoll` (`epoll_create_fd`, `epoll_add_in`, `epoll_wait_one` over `os_pipe_new`), and `async_run_workers_os` spawning 2 concurrent OS worker processes via `os_fork()` + kernel pipes.
- **Live Verification Output:**
  ```text
  $ lume test compiler/stage1/async_rt.src
    ok   test_reactor_io_readiness_and_wakeup
    ok   test_reactor_timer_wheel_deadline_ordering
    ok   test_reactor_bounded_backpressure_rejection
    ok   test_work_stealing_scheduler_load_balance
    ok   test_reactor_mixed_io_and_timers_scale
    ok   test_async_multiworker_os
  6 passed, 0 failed
  ```

### 2.2 Multi-Way B+Tree (`BMLeaf`/`BMInner` Height 4) & File-Backed ACID WAL Crash Recovery (`compiler/stage1/db.src`)
- **Implementation:**
  - Recursive multi-way B+Tree with leaf and internal node splitting (`bm_split_leaf`, `bm_split_inner`, `bm_insert_rec`) reaching height 4 with verified leaf-depth balance (`bm_balanced`, `bm_verify_invariant`).
  - ACID MVCC snapshot isolation (`db_begin_tx`, `db_commit_tx`, `db_rollback_tx`, `db_snapshot_read`).
  - File-backed `fsync` ACID WAL crash recovery (`db_wal_recover_file`, `db_crash_recovery_probe`) spawning a child process via `os_fork()` that writes committed + uncommitted + corrupted WAL records and terminates abnormally with `os_exit(9)`, then verifying that the parent replays the 2 committed records and discards the 2 uncommitted/corrupted records.
- **Live Verification Output:**
  ```text
  $ lume test compiler/stage1/db.src
    ok   test_btree_page_split_and_logarithmic_lookup
    ok   test_btree_range_scan_pruning_and_sorted_invariant
    ok   test_acid_transaction_commit_and_snapshot_isolation
    ok   test_acid_transaction_rollback_restores_state
    ok   test_cost_based_query_planner_and_wal_encoding
    ok   test_btree_recursive_internal_split_multiheight
    ok   test_durable_acid_wal_crash_recovery
    ok   test_saas_schema_migration_backup_restore_and_metrics
  8 passed, 0 failed
  ```

### 2.3 Binary SafeTensors (`.safetensors`) & Binary Protobuf ONNX (`.onnx`) Wire Writers/Parsers (`compiler/stage1/nn.src`)
- **Implementation:**
  - Reverse-mode autodiff (`mlp2_grad`, Wengert tape `ad_backward`), `sgd_step_mlp2`, `adam_step_mlp2`, full 64-round FIPS 180-4 `sha256_hex`, SSA CUDA PTX 8.0 & Vulkan SPIR-V 1.6 lowering and VMs (`ptx_vm_exec`, `spirv_vm_exec`).
  - `safetensors_write_bin` and `safetensors_parse_bin_file`: writes and parses the 8-byte little-endian header length, UTF-8 JSON header, and raw LE64 tensor buffer via `fs_read_byte`.
  - `onnx_write_bin` and `onnx_parse_bin_file`: writes and parses binary Protobuf `onnx.ModelProto` (`ir_version=9`, `opset=21`, protobuf varints and wire-type 2 length-delimited `GraphProto`/`NodeProto`/`TensorProto` records) and rejects truncated/malformed files.
- **Live Verification Output:**
  ```text
  $ lume test compiler/stage1/nn.src
    ok   test_tensor_matmul_and_shapes
    ok   test_tensor_broadcast_bias_and_relu
    ok   test_tensor_transpose_and_argmax
    ok   test_tensor_einsum_contractions
    ok   test_tensor_elementwise_arithmetic
    ok   test_nn_mlp2_forward_and_loss
    ok   test_nn_mlp2_grad_and_sgd_step
    ok   test_nn_adam_step
    ok   test_nn_safetensors_and_onnx_export
    ok   test_nn_ptx_and_spirv_codegen
    ok   test_nn_binary_safetensors_and_onnx_wire_parsers
  11 passed, 0 failed
  ```

### 2.4 RFC 793 Full TCP Pseudo-Header Checksum & RFC 8446 TLS 1.3 Loopback (`compiler/stage1/net.src`)
- **Implementation:**
  - `tcp_rfc793_build` and `tcp_rfc793_verify`: computes the 16-bit one's-complement checksum (`net_checksum16`) over the 12-byte IPv4 pseudo-header (`src_ip`, `dst_ip`, protocol `6`, `tcp_len`), 20-byte TCP header (`src_port`, `dst_port`, 32-bit `seq`, 32-bit `ack`, data offset + flags, window), and odd-byte zero-padded payload with multi-carry folding (`net_fold16`).
  - `tls13_wire_encode_aead`, `tls13_wire_decode_aead`, and `tls13_loopback_handshake_exchange`: RFC 8446 5-byte record layer (`0x17 0x03 0x03` + uint16BE length) + authenticated encryption over live Linux TCP loopback sockets.
- **Live Verification Output:**
  ```text
  $ lume test compiler/stage1/net.src
    ok   test_ipv4_parse_format_and_cidr_subnet
    ok   test_rfc1071_checksum_and_udp_tamper_detection
    ok   test_tcp_3way_handshake_and_teardown_fsm
    ok   test_tls13_key_schedule_and_aead_tamper_rejection
    ok   test_http11_request_response_roundtrip_and_malformed_rejection
    ok   test_tcp_rfc793_full_pseudoheader_odd_padding_and_carry
    ok   test_tls13_rfc8446_wire_records_and_loopback_handshake
  7 passed, 0 failed
  ```

### 2.5 GUI (`gui.src`), Media (`media.src`), Renewable Evidence (`levidence.src`), Installer (`install.src`) & Matrix (`matrix_assertions.src`)
- **Live Verification Output:**
  ```text
  $ lume test compiler/stage1/gui.src
  6 passed, 0 failed
  $ lume test compiler/stage1/media.src
  5 passed, 0 failed
  $ lume test compiler/stage1/levidence.src
  7 passed, 0 failed
  $ lume test scripts/install.src
  5 passed, 0 failed
  $ lume test acceptance/matrix_assertions.src
  14 passed, 0 failed
  ```

### 2.6 Bug Fixes in `scripts/docs_ci.src` & `compiler/stage1/ltest.src` + Track L Conformance Proof
- **Root Cause & Fix:**
  - Fixed `test_required_empty_file_is_readable()` in `scripts/docs_ci.src` (line 63) to create `"build"` via `fs_mkdir("build")` before writing `"build/docs-ci-empty-required"`.
  - Fixed `synth` in `compiler/stage1/ltest.src` (line 78) so each `test_<name>()` is evaluated **once** (accumulating passes in `hw_scratch_addr() + 4096`) instead of 3 times.
- **Live Verification Output:**
  ```text
  $ rm -rf build && lume test scripts/docs_ci.src
    ok   test_required_file_inventory_is_complete
    ok   test_required_empty_file_is_readable
    ok   test_required_missing_file_keeps_diagnostic
    ok   test_line_parser_preserves_spaces_without_phantom_entry
    ok   test_listing_rejects_empty_input
    ok   test_listing_rejects_quoted_paths_fail_closed
    ok   test_source_selection_covers_all_existing_extensions
    ok   test_bad_lume_exclusion_applies_to_basename_only
    ok   test_tab_scanner_rejects_leading_embedded_and_trailing_tabs
    ok   test_lf_selection_covers_src_lume_and_mesh
    ok   test_cr_scanner_rejects_crlf_and_bare_cr
    ok   test_crlf_checker_lists_all_offending_files
    ok   test_principle_parser_deduplicates_valid_citations
    ok   test_principle_parser_enforces_word_boundaries
    ok   test_principle_parser_requires_digits
    ok   test_principle_definition_does_not_prefix_match
    ok   test_unknown_principle_citation_is_rejected
  17 passed, 0 failed

  === 5.9 Single-Evaluation ltest Fail-Closed Probe ===
    FAIL test_once_only
  0 passed, 1 failed
  lume test: failed
  exit_code=3

  === 5.10 End-to-End Track L Domains Verification (track_l_domains_ok.src) ===
  TRACK_L_CONFORMANCE_DIFF_ZERO
  ```
