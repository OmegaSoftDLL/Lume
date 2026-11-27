# 45 — Depth hardening: turning the surface real

Purpose: a single tracked checklist for the gaps between what Lume *claims* and what it *computes/proves today*,
so nothing is lost. Source of truth for the domain classification: `build/windows-native/audit/domains_122_map.md`
(column "Natureza": R = real computation, M = model / toy predicate). The verified core (self-hosting fixpoint,
`prove`/`certify`, runtime-in-Lume, Windows parity 438/0) is strong and is NOT in this list; this document is only the
depth debt around it. Honest framing (owner, 2026-11-27): a model that is labelled a model is fine; a model dressed as
the real thing is the defect to fix.

Status legend: `[ ]` open · `[~]` in progress · `[x]` done. "Real" always means: produces the computation the name
promises, checked against a reference oracle (a published constant, a standard test vector, or a second
implementation), with a `test_` that FAILS if the function is reduced to a stub again.

## P1 — Prune or substantiate the overclaim (cheap, highest credibility gain)

- [ ] **P1.1** Sweep the docs and the language skill; downgrade every claim `lume certify` does not back. Named
  offenders to resolve (each: either prove it, or relabel it "model/demo"): "sovereign sentience", "quantum"
  (domain 8 Quantum_SurfaceCode is mixed/toy), "1-bit / ternary LLM core" (17 LLM_Router_Bonsai_MoE, 18
  Liquid_Audio_LFM3, 88 LLM_Core_AdamW_BPE), "self-evolution / hot-evolve / swarm-evolve / evolve" (103
  Pass_Self_Evolver, 79 Hive_Triad_SelfBuild, 85 LEvolve — 85 is real/CID, keep), "neural-kernel" (55 is real
  autodiff, keep; check the claim), "reveng" (26 Binary_RevEng is mixed), "singularity" (4 Singularity_OTE).
- [ ] **P1.2** Put a header on every model-only and mixed source file: `## MODEL — not the real <X>; see docs/45`.
  Internal honesty first; it makes P2 auditable.
- [ ] **P1.3** Add a gate that fails if a doc uses a strong verb ("proven", "verified", "self-evolving", "quantum")
  for a domain whose Natureza is M and that has no backing `test_`/`certify`. This keeps the prune from regressing.

## P2 — Model-only → real computation (the core of the debt)

`domains_122_map.md:170` lists **39 model-only** domains (no real computation of what the name promises) and **10
mixed** (toy core). Step one for all 49 is P1.2 (label). Then convert, highest-claim-value first.

### P2.A — The 39 model-only (named, so none is lost)
0 EGM_Elephant_Goldfish · 1 Ring0_CR3_PageTable · 2 Posit_Quire_Interval · **3 Subsea_Catenary_B31G** · 4
Singularity_OTE · 5 IEC62443_Purdue · **6 Omega_Mesh_Raft_DHT** · 9 OpenTPU_Systolic · 10 Pingora_TinyUFO · 12
UFE_7DOF_DLS_SOR · **13 IAPWS_IF97_Carnot_EKF** · 14 Marine_DNV_N001 · 15 Bayesian_SPC_PAVA · 16 NetSentinel_GOOSE ·
17 LLM_Router_Bonsai_MoE · 18 Liquid_Audio_LFM3 · 27 ZeroBreach_Forensics · 32 LumePuter_RV32IM_SwiGLU · 33
DeltaNet_RAM · **34 Bignum_BMAC** · 35 LumePU_VX_NPU · 62 Reversa_SDD_CodeCity · 63 Continuum_ACP_CRDT · 64
LumePuter_Stack_LWeights · 65 Octagon_Prover · 66 Iface_Digest_Cache_v2 · 74 HDC_Chronos_DEQ · 76
Pkg_Assimilator_Purity · 78 FlashAttention3_TensorCore · 79 Hive_Triad_SelfBuild · 86 LumeOS_VFS_Shell · 97
Farkas_Dual · 98 BitShift_Bounds · 99 FFI_Callback_Epoch · 100 SSA_Chaitin_AVX512 · 101 OS_FFI_io_uring_Bridge · 102
Horner_Bernstein · 103 Pass_Self_Evolver · 106 AST_Horner_Quadratic.

### P2.B — The 10 mixed (toy core, real shell)
7 DeFi_AMM_UTXO_Merkle · 8 Quantum_SurfaceCode · 11 NCM_RVQ_Sudoku · 20 Chameleon_Polyglot · 25 WCET_Superopt_EGraph ·
26 Binary_RevEng_ELF_PE · 73 DNA_ECC_Cosmic_TMR · 75 Sensory_RIFF_Indexer_Genesis · 88 LLM_Core_AdamW_BPE · 96
Trap_Ecall_Mret.

### P2 work items
- [ ] **P2.1 Triage** all 49 into: (a) convert to real now, (b) convert later, (c) stays a labelled model. Record
  the bucket next to each index. (Labelling via P1.2 already removes the "lies by omission" half of the problem.)
- [ ] **P2.2 Convert the claim-bearing few first**, against a reference oracle:
  - [ ] 13 **IAPWS_IF97** — real steam/thermo from the IF97 regions, vs the published reference values.
  - [ ] 3 **Subsea_Catenary_B31G** — real ASME B31G remaining-strength, vs a worked example.
  - [ ] 6 **Omega_Mesh_Raft** — real Raft log/leader election, not a predicate (test: split-vote + recovery).
  - [ ] 34 **Bignum_BMAC** — real big-number MAC/modmul (ties into P3.1 #24 bn_modexp).
  - [ ] 97 **Farkas_Dual** / 65 **Octagon_Prover** — real duals/octagon domain, vs a solver cross-check.
- [ ] **P2.3 Convert the 10 mixed** cores to the real algorithm, same oracle test.
- [ ] **P2.4** Each conversion lands with a `test_` that fails on a stub, and (where applicable) a `certify`
  obligation, and flips the domain's Natureza M→R in the audit map.

## P3 — Performance debt (measured gaps, not cosmetic)

- [ ] **P3.1** **#24 `bn_modexp` 60× slow** (`compiler/stage1/bignum.src`): rewrite buffer-backed bignums (32/64-bit
  limbs) + Montgomery + sliding window. *Done:* < 10 ms on the dev's target; TLS/SRP/crypto tests still pass. (Big,
  delicate — validate with the crypto/TLS suite.) Related to domain 34/94.
- [ ] **P3.2** **Hot builtins within 1.5× of asm** — close the ones still over (printval/showval and the rest of
  RUNTIME QUEUE item 3). *Done:* measured X25519 and a `buf_set` loop within target before/after.
- [ ] **P3.3** **GC minimum collection limit 64 MiB > the agent's 15 MB target** — lower the floor without
  regressing alloc (8 ns today). *Done:* the LumeDesk loop's peak RSS ≤ 15 MB.
- [ ] **P3.4** **SIMD + unboxed loops** (lasm packed-integer encodings + `--raw` vector intrinsics; type-directed
  loops) to close the 16 ms/1080p-frame budget. *Done:* `buf_bgra_to_i420` within the frame budget with SIMD.

## P4 — macOS / Swift (promise until it runs)

Tracked in full as `docs/42` §10 (C1–C8) and `docs/44`. *Done:* 438/0 on macOS, byte-identical universe, `swiftc`
bridge compiles, perf not below Linux. Blocked on the Mac being on Tailscale.

## Recommended order

P1 (prune — days, recovers credibility immediately) → P2.1 + P1.2 (label the 49 — immediate honesty) → P3.1 (#24,
the perf gap the dev cites most) → P2.2/P2.3 and the rest of P3 → P4 when the Mac is up. Heavy bootstraps go to the
Acer (don't compete with the dev's CPU).

## Nothing-lost master index

4 workstreams · P1 (3 items) · P2 (49 domains named above + 4 sub-work-items) · P3 (4 items) · P4 (8 sub-items in
§10). Every model-only (39) and mixed (10) domain is named here by audit index so none is dropped.
