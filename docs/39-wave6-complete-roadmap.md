# Wave 6 ("Onda 6") — Total Project Completion & AI-First Superpowers Roadmap

This document records the complete Wave 6 execution plan so no requirement, open track, or AI-first enhancement is ever lost.

---

## Part 1: Closing the Remaining 2 `UNKNOWN` Claims in `acceptance/matrix.json` (Reaching 24/24 `PASS`)

1. **`L.NET.TLS13_INTEROP` (`compiler/stage1/net.src`):**
   - Implement RFC 8446 / RFC 8448 compliant TLS 1.3 binary record framing (`0x16` Handshake, `0x17` ApplicationData, legacy version `0x0303`, 16-bit big-endian length) and RFC 5869 HKDF-SHA256 (`hmac_sha256`, `hkdf_extract_sha256`, `hkdf_expand_label_sha256`) using real FIPS 180-4 SHA-256.
   - Implement native Linux TCP loopback TLS 1.3 `ClientHello` / `ServerHello` / encrypted `Finished` / AEAD application-data exchange (`tls13_loopback_handshake_exchange`) and verify against pinned RFC/independent vectors, rejecting tampered tags, wrong sequence numbers, and malformed record headers.
2. **`L.GUI.NATIVE_WINDOWING` (`compiler/stage1/gui.src`):**
   - Implement the native **X11 Core Wire Protocol** binary client/server windowing handshake and event loop over Linux loopback sockets (`x11_window_session_loopback`):
     - 12-byte X11 `ConnectionSetup` (`0x6C` `'l'` little-endian byte order, protocol `11.0`), server setup acceptance, `CreateWindow` (opcode `1`), `MapWindow` (opcode `8`), `Expose` event delivery (code `12`), and `ButtonPress` event delivery (code `4`) with real `(x, y)` coordinates dispatched to Lume `ui_dispatch_click` widgets.

---

## Part 2: Completing the Product Maturity Capstones (`docs/34-product-maturity-program.md`)

1. **Track I — Advanced Verifiable C Adapters (`#334`, `compiler/stage1/interop.src`):**
   - Extend verifiable C adapter generation to support mutable output buffers (`char *out_buf, int64_t out_cap` with bounds-checked write preconditions), function-pointer callback descriptors (`@callback`), and OpenAPI/HTTP endpoint contract descriptors (`adapt_c_mutable_buffer`, `adapt_c_callback_stub`, `adapt_http_openapi_endpoint`).
2. **Phase 3 Maturity — Multi-Worker SaaS Backup, Restore, Schema Migration & Metrics (`#332`, `compiler/stage1/db.src` / `compiler/stage1/net.src`):**
   - Add verifiable schema migration (`db_migrate_schema_v1_to_v2`), cryptographic snapshot backup & point-in-time restore (`db_backup_snapshot_file`, `db_restore_snapshot_file`), and structured Prometheus/JSON health & telemetry endpoints (`saas_metrics_response`).
3. **Phase 4 Maturity — WASM DOM & Reactive Web Component Bridge (`#333`, `compiler/stage1/gui.src`):**
   - Add deterministic WASM DOM virtual-tree diffing, reactive `signal[T]` state-to-DOM patch generation (`wasm_dom_render_vnode`, `wasm_dom_diff_patches`), and event-callback routing for browser/WASM applications.
4. **Phase 5 Maturity — `lume-os` VFS Persistence & Interactive Kernel Shell (`#241`, `compiler/stage1/los.src`):**
   - Add inode-table + block-bitmap VFS persistence with crash-consistent journal replay and interactive kernel shell command execution (`los_vfs_mount`, `los_vfs_write_file`, `los_vfs_read_file`, `los_shell_exec_script`).

---

## Part 3: Out-of-the-Box AI-First Superpowers ("Lume Feita Para IA")

1. **Short-Circuit Boolean Evaluation (`and` / `or` in `05_codegen.src` and `data_asmgen.lume`):**
   - Lower `Bin("and", l, r)` and `Bin("or", l, r)` with conditional short-circuit jumps so guard idioms like `if i < count(s) and at(s, i) == "x"` never evaluate the right-hand side when the left-hand side already determines the result.
2. **CEGIS Counterexample-Guided Function Synthesis from Examples + Contracts (`lcaas.src` / `lume agent synthesize`):**
   - Allow an AI agent to specify I/O examples plus `requires`/`ensures` contracts (`caas_cegis_synthesize`), automatically synthesizing the minimal AST expression that satisfies every example and passes the `QF_LIA` prover.
3. **10x Context-Window Compression via Semantic Skeletons (`lcaas.src` / `lume agent skeleton`):**
   - Extract a compact machine-readable semantic skeleton of any `.src` module containing function signatures, parameter counts, inferred effects, contracts, and per-function SHA-256 body digests so an AI agent can inspect whole subsystems in a fraction of the token budget.
