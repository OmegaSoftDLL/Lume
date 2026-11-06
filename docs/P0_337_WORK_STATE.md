# P0 #337 & Wave 1 — Operational State, Alpha `v0.3.0-alpha` Release, and Wave 2 Handoff

Last verified: 2026-11-03 22:28 UTC (19:28 BRT).
Repository: `OmegaSoftDLL/lume`.
Consolidated branch: `feat/p0-full-integration` (PR #433) at commit `c44b411`.
Active consolidation worktree: `C:/Users/Ricardo.Bueno/.kimi-work/lume-consol-merge`.

## 1. Executive Status — Phase 0 (`#337` / PR #433) + Wave 1 + Alpha `v0.3.0-alpha` Complete

All Phase 0 (`#337`) consolidation branches and Wave 1 fixes (`#450`, `#451`, `#457`) have been integrated, verified across the remote Linux verification cluster (`notacer` and `dell-g3`), packaged into **`v0.3.0-alpha`**, and installed across all target environments:

- **Consolidated Commit:** `c44b411` on `feat/p0-full-integration` (PR #433), pushed to `origin/feat/p0-full-integration`.
- **Self-Hosted Fixpoint:** `lumec2 == lumec3` bit-identical (`552,168` bytes, SHA-256 `49263865ff670a6ff5f50ef50a2be332de379d15239897be4a04fa9edcc0391f`).
- **Full Stage-0 & Stage-1 Verification (`dell-g3:/root/suite-final.log`):**
  - `make -C bootstrap/lume0 test`: **`393 passed, 0 failed, 0 skipped`** (`DELL_SUITE_FINAL_100_OK`).
  - `make -C bootstrap/lume0 asan`: **`168 passed, 0 failed, 0 skipped`**.
  - All 17 CI gates (`bootstrap`, `zero-c`, `stage0`, `renewable-evidence`, `process-runtime`, `native-cli`, `docs`, `acceptance-matrix`, `semantic-mesh`, `c-adapters`, `native-assembly`, `native-capstones`, `economic-benchmark`, `verified-registry`, `native-orchestration`, `windows-pe`): **100% PASSED**.

## 2. Installed Package `v0.3.0-alpha` (Built from `c44b411`)

- **Linux x86-64 Archive:** `lume-v0.3.0-alpha-linux-x86_64.tar.gz`
  - Archive Size: `3,296,348` bytes
  - Archive SHA-256: `057932f495739107b9d2e66297b167dce713973acca828b7a2d716e1a39083bd`
  - Package `MANIFEST.sha256` SHA-256: `9ea329f81fe828483586e6a6ee202f7e0ff79772b47a0665fa753117c9d21cb0` (20 verified files)
  - Installed & Verified Locations (`lume self verify --prefix /root/.lume` -> `manifest_verified: true, verified_files: 20`):
    - Local WSL on Windows PC: `/root/.lume`
    - Acer (`notacer` WSL Ubuntu): `/root/.lume`
    - Dell G3 (`dell-g3` WSL Ubuntu): `/root/.lume`
- **Windows x86-64 Archive:** `lume-v0.3.0-alpha-windows-x86_64.tar.gz`
  - Archive Size: `2,100,573` bytes
  - Archive SHA-256: `56508ee240309ee3ec250b7a607756d3a1c595216048316701d72d64e4b0b401`
  - Package `MANIFEST.sha256` SHA-256: `1e7d170e33501c78f082bd0980a32992c36de6e20ce548fbebe774fc77b2e94a` (14 verified files)
  - Installed & Verified Location (`lume-target-check.exe` -> `55 / 42`):
    - Windows PC: `C:/Users/Ricardo.Bueno/.lume`
- **Local Dist Mirrors:**
  - `C:/Users/Ricardo.Bueno/lume/dist/`
  - `C:/Users/Ricardo.Bueno/.kimi-work/lume-consol-merge/dist/`

## 3. Summary of Key Fixes in `feat/p0-full-integration` (`52fb3e8` .. `c44b411`)

1. **`#450` (`addv` register preservation across `alloc_grow`):**
   - Saved `%rdi` (`pushq %rdi` / `popq %rdi` in `av_ls`) and `%rsi` (`pushq %rsi` / `popq %rsi` in `av_rs`) on the stack in `compiler/stage1/lume/05_codegen.src` and `compiler/stage1/data_asmgen.lume` instead of clobbering callee-saved `%r15`.
2. **`#451` (`lasm` 32-bit signed PC-relative displacements):**
   - Fixed 32-bit relative offset emission in `compiler/stage1/lasm.src` for negative jumps exceeding 128 KB in `lumec.s`, enabling the self-hosted `lumec2 == lumec3` binary fixpoint.
3. **`#457` (`evolve_driver_gate` 12/12 + `os_argv` propagation):**
   - Fixed CLI argument forwarding in `lume` (`skip 2`) and `compiler/stage1/levolve.src` state transitions.
4. **41x Stage-0 `data_asm_cc.lume` Speedup (`925b925`):**
   - Converted `raw` string once via `raw.chars()` in `sesc` (`compiler/stage1/layout.lume` and `compiler/stage1/data_asmgen.lume`) to use $O(1)$ `V_LIST` indexing instead of $O(N^2)$ UTF-8 `V_STR` rescanning.
5. **Full 393/393 Stage-0 & CLI Parity (`c44b411`):**
   - Registered Separation Logic, `QF_ALIA`, `decimal`, and `money` prover intrinsics in `compiler/stage1/lume/06b_phase3.src` (`ors_special1` / `ors_special2`).
   - Restored one-shot `lcert_mcp_summary` on empty stdin in `compiler/stage1/lcaas.src` while preserving clean termination after interactive JSON-RPC lines.
   - Completed native `lume_driver.src` and `lume` wrapper parity for `certify --json`, `compile` comptime diagnostics, `agent --json`, `intent`, `pkg`, and `*.wasm` builds.

## 4. Next Steps — Wave 2 ("Onda 2")

With Phase 0, Wave 1, and the `v0.3.0-alpha` installation completed across all hosts, the project is ready to begin **Wave 2**:
- **`#436` / `#432` / `#452`–`#456`:** Memory/Arena CI gates, strict verification, and performance work.

## 5. Wave 2 Coordination — Front 3 claimed by Codex

Owner: Codex (requested by Ricardo on 2026-11-03). AgY: please leave this front to Codex and continue coordinating the other Wave 2 fronts. This is a work claim, not a completion or validation claim.

Scope: soundness, strict verification, and build hygiene: #453 (allocation effects); #428 (undefined calls and other soundness findings); #436 (Stage-0 checker panics); #435, #437, #438, and #439 (build atomicity, evolve gate idempotence, line endings, and make gate coverage). Each issue must be checked against its current actual scope before implementation.

Integration: work in an isolated worktree based on the current integration branch; do not modify AgY's worktree or overwrite its changes. Coordinate overlapping compiler files before integration. Validate real behavior and regression cases on the Acer and Dell hosts as applicable, then use a branch and PR with GitHub CI. Do not mark an issue complete until its acceptance criteria and required checks pass. As of this claim, no Front 3 implementation or validation is claimed.

Front 3 update: isolated Windows worktree `C:/Users/Ricardo.Bueno/lume-w2-evolve-437`, branch `fix/w2-evolve-gate-437`, based on `c44b411`; Linux validation copy `/root/lume-codex-w2-439`. #437 and #438 already have implementation and regression coverage in the integration branch; their issue closure still requires validation. #439: extending the make gate to run the actual bootstrap is in progress and unverified. Acer SSH timed out; Dell SSH is reachable. No push has been made, per the Wave 2 cluster-first instruction.

Front 3 constraint update: Ricardo requires all construction to start from the installed Alpha package and Lume-generated Lume. The previously started seed-based validation was interrupted and is not evidence for that constraint. Installed Linux Alpha `lumec` and `lasm` successfully compiled the modified make gate directly; the existing `lume_make bootstrap` still invokes the frozen seed, so the proposed #439 gate must be adapted before its execution can qualify. The Alpha package reports `b204221-dev2-pkg (base 51ac6a9)`; do not assume that equals the integration commit. Acer SSH remains unavailable.

Front 3 progress: #453 has a separate isolated worktree `C:/Users/Ricardo.Bueno/lume-w2-effects-453` (branch `fix/w2-arena-effects-453`). A compiler generated solely with installed Alpha `lumec`/`lasm` rejects direct `__lume_arena_new` and `__lume_arena_alloc` in pure functions; the Lume regression gate passes against that compiler and fails against the original Alpha. Work remains: transitive wrappers, diagnostics parity, broader regression coverage and cluster validation. This is uncommitted WIP; do not treat #453 as complete. #439 gate WIP invokes the seed through existing bootstrap and is not suitable under the newly requested Alpha-only construction constraint until adapted.
