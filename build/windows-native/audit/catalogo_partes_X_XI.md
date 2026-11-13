# Auditoria do catálogo Lume — Partes X e XI (linhas 2077–2772)

Arquivo auditado: `C:\Users\Ricardo.Bueno\LUME_CATALOGO_COMPLETO_IMPLEMENTADO_E_TESTADO_PT_BR.md`, linhas 2077 a 2772 (fim).
Repositório conferido: `C:\Users\Ricardo.Bueno\lume`, HEAD `2916735` (2026-11-12 12:18) e árvore de trabalho com o porte Windows não commitado (65 arquivos modificados + `compiler/stage1/hostio.src` novo). Auditoria em 2026-11-13. Nada no repositório foi modificado; este é o único arquivo criado.

## 0. Método e critérios de contagem

- `law`: linhas que começam com `law ` em arquivos `.src`/`.lume` (`git grep -E "^law "` em HEAD e com `--untracked` na árvore).
- `fn`: linhas que começam com `fn`, opcionalmente precedidas de anotações `@...` e dos modificadores `pub`, `total`, `async`, `kernel`, `llm`, `extern`/`extern "c"` (sem esses modificadores a contagem perde funções como `pub total fn bump_job_costs`). "Funções" no catálogo = `fn` **menos** `fn test_*` (critério deduzido: bate arquivo a arquivo em 10.2/10.3).
- `fn test_*`: linhas `^fn test_` / `^pub fn test_`.
- "Arquivos de teste" (409): todos os `.src`/`.lume` sob `tests/**` (255) + `bootstrap/lume0/**` (99) + `compiler/stage1/*_ok.src|.lume` (55). Critério deduzido e confirmado: bate exatamente com HEAD, sem sobra nem falta.
- Coluna Windows: análise estática (grep + fecho transitivo de `use` e, na 11.3, do grafo de chamadas de cada `test_*`) por sockets/epoll (`net_tcp_*`, `net_send*`, `net_recv*`, `epoll_*`), `os_io_uring_*`, `os_shm_map`, `os_fork`/`os_pipe_new` sem `exec`, programas externos em `os_run*` (`/bin/*`, `/usr/bin/*`) e geração/execução de ELF (`.elf`). Programas `/bin/{mkdir,rm,cp,mv,chmod,ls,pwd,printenv,test}` e `/usr/bin/env` contam como resolvidos **só** quando o arquivo chega a `compiler/stage1/hostio.src` (emulação em Lume, existente só na árvore de trabalho). Ferramentas do próprio Lume (`lume`, `lumec`, `lasm`, ...) contam como OK (o porte procura `<prog>.exe`).
- "OK (estático)" quer dizer: nenhuma dependência de SO não portada foi encontrada; não quer dizer que o arquivo foi executado no Windows. Execução real foi feita só na amostra da seção 6.

## 1. Contagens reais vs anunciadas (resumo)

| Métrica | Catálogo | HEAD `2916735` | Árvore de trabalho | Veredito |
|---|---:|---:|---:|---|
| Arquivos `.src`/`.lume` | 694 | 694 | 695 | confere com HEAD |
| `law` (linhas `^law `) | 266 | 268 | 269 | **diverge**: o catálogo omite 2 leis multilinha de `examples/apps/omniroute_guard/main.src` (HEAD) e a lei nova de `hostio.src` (árvore) |
| `fn` total (com modificadores) | — | 19543 | 19690 | — |
| `fn` sem `test_*` ("funções implementadas") | 18.857 | 18856 | 18991 | quase confere (HEAD −1); não existe snapshot que dê exatamente 18.857 |
| `fn` só `^fn ` (sem `pub`/modificadores) | — | 19.291 | 19.438 | — |
| `fn test_*` | 688 | 687 | 699 | **diverge**: 688 = HEAD 687 + `test_ev_unsafe_path_windows_forms` (levolve, só na árvore); não inclui os 11 `test_hio_*` de `hostio.src` |
| `fn test_*` executáveis por `lume test` (sem parâmetros) | 688 | 685 | 697 | **diverge**: `test_helper(x)` (sample_test.src) e `test_match_in_call(x)` (semantic_ergonomics_ok.src) têm parâmetro e não são executados |
| Arquivos de teste dedicados | 409 | 409 | 409 | confere |
| Soma das linhas dos 409 arquivos | 11.467 | 11.454 | 11.492 | diverge (snapshot intermediário da árvore) |
| `test_*` dentro dos 409 arquivos | 138 (tabela 11.1) | 138 | 138 | confere, mas contradiz o título "409 arquivos + 688 testes" (os outros 550 `test_*` estão em módulos, não nos 409) |
| Módulos em 10.3 | 47 | 47 | 47 | confere |
| Funções internas em 10.3 | 10.892 | 10851 | 10904 | diverge; 10.892 é a soma das linhas da própria tabela, que mistura HEAD e árvore |

**Qual estado o catálogo descreve:** nenhum dos dois exatamente. É um retrato da árvore de trabalho em algum momento do porte Windows: já tinha o teste novo de `levolve.src`, `lasm.src` e `runtime_core.lume` no tamanho atual da árvore, mas `07_driver.src` (394 linhas/132 fn) e `lume_driver.src` (1.246/406) num tamanho intermediário (HEAD 376/126 e 1.236/402; árvore atual 394/138 e 1.248/407), e ainda não tinha `compiler/stage1/hostio.src`. As leis e a maioria das contagens por arquivo coincidem com HEAD porque esses arquivos não mudaram.

**Causa sistemática das omissões:** o gerador do catálogo só reconhece assinaturas numa linha. Toda `law nome(` ou `fn nome(` com parâmetros na linha seguinte some da lista (as 2 leis do omniroute; `llm_moe_admission_guard`, `nfe_key_segment_length`, `nfe_access_key_length_valid`, `omniroute_select_provider`, `omniroute_remaining_budget`, `omniroute_reserve_inflight_budget`, `pix_trace_hop_risk_bps`, `uav_safe_altitude_guard_mm`), e `pub llm fn` também (`estimate_job_priority`).

## 2. Seção 10.1 — as 266 leis (linhas 2082–2351)

Todas as 266 entradas foram comparadas com o fonte em HEAD: nome, arquivo, parâmetros e início do enunciado. **266/266 conferem.** Numeração 1–266 contínua. "Provada" não foi verificada (não rodei `lume prove`); o catálogo não aponta evidência de prova por lei.

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 2086 | #1 `db_tx_state_sound_law` | CONFERE | `compiler/stage1/db.src:296` | N/A (prova estática, sem E/S) |
| 2087 | #2 `db_wal_ops_strictly_increasing_law` | CONFERE | `compiler/stage1/db.src:297` | N/A (prova estática, sem E/S) |
| 2088 | #3 `ufe_plummer_force_bounded_law` | CONFERE | `compiler/stage1/gfx.src:149` | N/A (prova estática, sem E/S) |
| 2089 | #4 `ufe_dls_denom_nonzero_law` | CONFERE | `compiler/stage1/gfx.src:152` | N/A (prova estática, sem E/S) |
| 2090 | #5 `ufe_harmonic_maximum_principle_law` | CONFERE | `compiler/stage1/gfx.src:208` | N/A (prova estática, sem E/S) |
| 2091 | #6 `ufe_carnot_second_law` | CONFERE | `compiler/stage1/gfx.src:247` | N/A (prova estática, sem E/S) |
| 2092 | #7 `subsea_catenary_tension_monotonic_law` | CONFERE | `compiler/stage1/gfx.src:268` | N/A (prova estática, sem E/S) |
| 2093 | #8 `subsea_miner_dff_safety_law` | CONFERE | `compiler/stage1/gfx.src:283` | N/A (prova estática, sem E/S) |
| 2094 | #9 `subsea_hypoxia_hyperoxia_rejected_law` | CONFERE | `compiler/stage1/gfx.src:304` | N/A (prova estática, sem E/S) |
| 2095 | #10 `ui_modal_always_above_parent_law` | CONFERE | `compiler/stage1/gui.src:148` | N/A (prova estática, sem E/S) |
| 2096 | #11 `ui_modal_blocks_background_clicks_law` | CONFERE | `compiler/stage1/gui.src:151` | N/A (prova estática, sem E/S) |
| 2097 | #12 `cham_c_align_nonneg_law` | CONFERE | `compiler/stage1/lchameleon.src:23` | N/A (prova estática, sem E/S) |
| 2098 | #13 `cham_rust_borrow_exclusivity_law` | CONFERE | `compiler/stage1/lchameleon.src:28` | N/A (prova estática, sem E/S) |
| 2099 | #14 `cham_python_refcount_conservation_law` | CONFERE | `compiler/stage1/lchameleon.src:33` | N/A (prova estática, sem E/S) |
| 2100 | #15 `cham_wasm_linear_memory_page_law` | CONFERE | `compiler/stage1/lchameleon.src:38` | N/A (prova estática, sem E/S) |
| 2101 | #16 `ote_omega_counterphase_law` | CONFERE | `compiler/stage1/lchameleon.src:159` | N/A (prova estática, sem E/S) |
| 2102 | #17 `ote_nyquist_aliasing_law` | CONFERE | `compiler/stage1/lchameleon.src:164` | N/A (prova estática, sem E/S) |
| 2103 | #18 `ote_power_triangle_conservation_law` | CONFERE | `compiler/stage1/lchameleon.src:181` | N/A (prova estática, sem E/S) |
| 2104 | #19 `ote_cascade_resonance_law` | CONFERE | `compiler/stage1/lchameleon.src:198` | N/A (prova estática, sem E/S) |
| 2105 | #20 `spc_cusum_nonnegative_law` | CONFERE | `compiler/stage1/lchameleon.src:227` | N/A (prova estática, sem E/S) |
| 2106 | #21 `ops_cpm_critical_path_zero_float_law` | CONFERE | `compiler/stage1/lchameleon.src:238` | N/A (prova estática, sem E/S) |
| 2107 | #22 `analytics_k_anonymity_privacy_law` | CONFERE | `compiler/stage1/lchameleon.src:249` | N/A (prova estática, sem E/S) |
| 2108 | #23 `fp_bf16_nan_inf_rejection_law` | CONFERE | `compiler/stage1/lchameleon.src:273` | N/A (prova estática, sem E/S) |
| 2109 | #24 `fp_quire_associativity_law` | CONFERE | `compiler/stage1/lchameleon.src:283` | N/A (prova estática, sem E/S) |
| 2110 | #25 `fp_interval_soundness_enclosure_law` | CONFERE | `compiler/stage1/lchameleon.src:298` | N/A (prova estática, sem E/S) |
| 2111 | #26 `pkg_assimilate_supply_chain_backdoor_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:321` | N/A (prova estática, sem E/S) |
| 2112 | #27 `pkg_mvcc_uncommitted_invisible_law` | CONFERE | `compiler/stage1/lchameleon.src:338` | N/A (prova estática, sem E/S) |
| 2113 | #28 `lumeputer_swiglu_relu_zero_gate_law` | CONFERE | `compiler/stage1/lchameleon.src:354` | N/A (prova estática, sem E/S) |
| 2114 | #29 `lumeputer_norm_absorption_immunity_law` | CONFERE | `compiler/stage1/lchameleon.src:365` | N/A (prova estática, sem E/S) |
| 2115 | #30 `lumeputer_deltanet_zero_drift_retention_law` | CONFERE | `compiler/stage1/lchameleon.src:376` | N/A (prova estática, sem E/S) |
| 2116 | #31 `lumeputer_rv32im_pc_4byte_aligned_law` | CONFERE | `compiler/stage1/lchameleon.src:387` | N/A (prova estática, sem E/S) |
| 2117 | #32 `lumepu_vx_vmat_zero_bf16_drift_law` | CONFERE | `compiler/stage1/lchameleon.src:410` | N/A (prova estática, sem E/S) |
| 2118 | #33 `lumeputer_stack_frame_push_pop_identity_law` | CONFERE | `compiler/stage1/lchameleon.src:435` | N/A (prova estática, sem E/S) |
| 2119 | #34 `prover_octagon_transitivity_soundness_law` | CONFERE | `compiler/stage1/lchameleon.src:452` | N/A (prova estática, sem E/S) |
| 2120 | #35 `prover_loop_ranking_strict_decrease_law` | CONFERE | `compiler/stage1/lchameleon.src:469` | N/A (prova estática, sem E/S) |
| 2121 | #36 `incremental_iface_mismatch_forces_recompile_law` | CONFERE | `compiler/stage1/lchameleon.src:486` | N/A (prova estática, sem E/S) |
| 2122 | #37 `lumeputer_ecall_mret_roundtrip_law` | CONFERE | `compiler/stage1/lchameleon.src:505` | N/A (prova estática, sem E/S) |
| 2123 | #38 `lumeputer_inweights_lcert_soundness_law` | CONFERE | `compiler/stage1/lchameleon.src:516` | N/A (prova estática, sem E/S) |
| 2124 | #39 `prover_farkas_contradiction_soundness_law` | CONFERE | `compiler/stage1/lchameleon.src:533` | N/A (prova estática, sem E/S) |
| 2125 | #40 `prover_bitshift_shl_monotonic_law` | CONFERE | `compiler/stage1/lchameleon.src:542` | N/A (prova estática, sem E/S) |
| 2126 | #41 `ffi_callback_stale_epoch_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:553` | N/A (prova estática, sem E/S) |
| 2127 | #42 `diag_fuzzy_exact_match_zero_score_law` | CONFERE | `compiler/stage1/lchameleon.src:570` | N/A (prova estática, sem E/S) |
| 2128 | #43 `ssa_zero_spill_when_k_colorable_law` | CONFERE | `compiler/stage1/lchameleon.src:581` | N/A (prova estática, sem E/S) |
| 2129 | #44 `ssa_inline_nonnegative_gain_law` | CONFERE | `compiler/stage1/lchameleon.src:592` | N/A (prova estática, sem E/S) |
| 2130 | #45 `avx512_vectorized_strictly_faster_law` | CONFERE | `compiler/stage1/lchameleon.src:603` | N/A (prova estática, sem E/S) |
| 2131 | #46 `ffi_auto_abi_size_mismatch_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:614` | N/A (prova estática, sem E/S) |
| 2132 | #47 `io_uring_backpressure_no_overflow_law` | CONFERE | `compiler/stage1/lchameleon.src:625` | N/A (prova estática, sem E/S) |
| 2133 | #48 `prover_inductive_cycle_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:642` | N/A (prova estática, sem E/S) |
| 2134 | #49 `compiler_pass_wcet_regression_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:653` | N/A (prova estática, sem E/S) |
| 2135 | #50 `vex_simd_hardware_add4_linearity_law` | CONFERE | `compiler/stage1/lchameleon.src:669` | N/A (prova estática, sem E/S) |
| 2136 | #51 `io_uring_kernel_sqe_cqe_conservation_law` | CONFERE | `compiler/stage1/lchameleon.src:680` | N/A (prova estática, sem E/S) |
| 2137 | #52 `ast_native_quadratic_square_completion_law` | CONFERE | `compiler/stage1/lchameleon.src:691` | N/A (prova estática, sem E/S) |
| 2138 | #53 `c_header_unterminated_ifdef_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:702` | N/A (prova estática, sem E/S) |
| 2139 | #54 `lasm_differential_Mismatch_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:718` | N/A (prova estática, sem E/S) |
| 2140 | #55 `prover_unsound_acceptance_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:729` | N/A (prova estática, sem E/S) |
| 2141 | #56 `mutation_surviving_mutant_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:740` | N/A (prova estática, sem E/S) |
| 2142 | #57 `ddc_bootstrap_divergence_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:751` | N/A (prova estática, sem E/S) |
| 2143 | #58 `ltv_value_mismatch_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:772` | N/A (prova estática, sem E/S) |
| 2144 | #59 `ltv_unbalanced_frame_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:777` | N/A (prova estática, sem E/S) |
| 2145 | #60 `soak_ledger_tampered_chain_adds_nothing_law` | CONFERE | `compiler/stage1/lchameleon.src:789` | N/A (prova estática, sem E/S) |
| 2146 | #61 `rtm_orphan_requirement_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:803` | N/A (prova estática, sem E/S) |
| 2147 | #62 `rtm_untested_requirement_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:808` | N/A (prova estática, sem E/S) |
| 2148 | #63 `mcdc_one_sided_condition_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:819` | N/A (prova estática, sem E/S) |
| 2149 | #64 `lockstep_any_divergence_trips_law` | CONFERE | `compiler/stage1/lchameleon.src:833` | N/A (prova estática, sem E/S) |
| 2150 | #65 `lockstep_invalid_certificate_trips_law` | CONFERE | `compiler/stage1/lchameleon.src:838` | N/A (prova estática, sem E/S) |
| 2151 | #66 `lockstep_latch_is_sticky_law` | CONFERE | `compiler/stage1/lchameleon.src:849` | N/A (prova estática, sem E/S) |
| 2152 | #67 `ltv_ast_x86_bisimulation_trap_mismatch_law` | CONFERE | `compiler/stage1/lchameleon.src:868` | N/A (prova estática, sem E/S) |
| 2153 | #68 `soak_telemetry_broken_link_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:879` | N/A (prova estática, sem E/S) |
| 2154 | #69 `do330_uncovered_mcdc_blocks_qualification_law` | CONFERE | `compiler/stage1/lchameleon.src:890` | N/A (prova estática, sem E/S) |
| 2155 | #70 `lumeputer_2oo2d_divergence_veto_law` | CONFERE | `compiler/stage1/lchameleon.src:901` | N/A (prova estática, sem E/S) |
| 2156 | #71 `no_alloc_heap_escape_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:912` | N/A (prova estática, sem E/S) |
| 2157 | #72 `multiarch_fixed_width_misaligned_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:923` | N/A (prova estática, sem E/S) |
| 2158 | #73 `linear_channel_lock_cycle_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:934` | N/A (prova estática, sem E/S) |
| 2159 | #74 `constant_time_tag_forgery_or_leak_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:945` | N/A (prova estática, sem E/S) |
| 2160 | #75 `incremental_proof_cache_stale_deps_miss_law` | CONFERE | `compiler/stage1/lchameleon.src:956` | N/A (prova estática, sem E/S) |
| 2161 | #76 `safetensors_lumeputer_output_drift_rejected_law` | CONFERE | `compiler/stage1/lchameleon.src:967` | N/A (prova estática, sem E/S) |
| 2162 | #77 `spsc_ring_conservation_law` | CONFERE | `compiler/stage1/lconcurrency.src:50` | N/A (prova estática, sem E/S) |
| 2163 | #78 `spsc_ring_empty_iff_cannot_pop_law` | CONFERE | `compiler/stage1/lconcurrency.src:57` | N/A (prova estática, sem E/S) |
| 2164 | #79 `spsc_ring_push_increments_occupancy_law` | CONFERE | `compiler/stage1/lconcurrency.src:64` | N/A (prova estática, sem E/S) |
| 2165 | #80 `spsc_ring_pop_decrements_occupancy_law` | CONFERE | `compiler/stage1/lconcurrency.src:74` | N/A (prova estática, sem E/S) |
| 2166 | #81 `linear_single_owner_conservation_law` | CONFERE | `compiler/stage1/lconcurrency.src:128` | N/A (prova estática, sem E/S) |
| 2167 | #82 `dag_strict_rank_irreflexive_law` | CONFERE | `compiler/stage1/lconcurrency.src:167` | N/A (prova estática, sem E/S) |
| 2168 | #83 `dag_strict_rank_asymmetric_law` | CONFERE | `compiler/stage1/lconcurrency.src:170` | N/A (prova estática, sem E/S) |
| 2169 | #84 `dag_strict_rank_transitive_law` | CONFERE | `compiler/stage1/lconcurrency.src:173` | N/A (prova estática, sem E/S) |
| 2170 | #85 `sentient_auto_conjecture` | CONFERE | `compiler/stage1/levolve.src:367` | N/A (prova estática, sem E/S) |
| 2171 | #86 `os_hybrid_gpu_never_selects_missing_dgpu_law` | CONFERE | `compiler/stage1/los.src:295` | N/A (prova estática, sem E/S) |
| 2172 | #87 `sentient_auto_conjecture` | CONFERE | `compiler/stage1/lsentience.src:411` | N/A (prova estática, sem E/S) |
| 2173 | #88 `self_built_ring0_net_sound` | CONFERE | `compiler/stage1/lsentience.src:412` | N/A (prova estática, sem E/S) |
| 2174 | #89 `ring0_page_4k_aligned` | CONFERE | `compiler/stage1/lsentience.src:413` | N/A (prova estática, sem E/S) |
| 2175 | #90 `swarm_checksum_monotonic` | CONFERE | `compiler/stage1/lsentience.src:414` | N/A (prova estática, sem E/S) |
| 2176 | #91 `std_vec_slice_conservation_law` | CONFERE | `compiler/stage1/lstd.src:148` | N/A (prova estática, sem E/S) |
| 2177 | #92 `std_clamp_idempotent_in_range` | CONFERE | `compiler/stage1/lstd.src:150` | N/A (prova estática, sem E/S) |
| 2178 | #93 `std_lumeputer_deltanet_retention_law` | CONFERE | `compiler/stage1/lstd.src:152` | N/A (prova estática, sem E/S) |
| 2179 | #94 `lasm_differential_Mismatch_rejected_law` | CONFERE | `compiler/stage1/lstd.src:154` | N/A (prova estática, sem E/S) |
| 2180 | #95 `prover_unsound_acceptance_rejected_law` | CONFERE | `compiler/stage1/lstd.src:156` | N/A (prova estática, sem E/S) |
| 2181 | #96 `mutation_surviving_mutant_rejected_law` | CONFERE | `compiler/stage1/lstd.src:158` | N/A (prova estática, sem E/S) |
| 2182 | #97 `ddc_bootstrap_divergence_rejected_law` | CONFERE | `compiler/stage1/lstd.src:160` | N/A (prova estática, sem E/S) |
| 2183 | #98 `ltv_value_mismatch_rejected_law` | CONFERE | `compiler/stage1/lstd.src:162` | N/A (prova estática, sem E/S) |
| 2184 | #99 `soak_ledger_tampered_chain_adds_nothing_law` | CONFERE | `compiler/stage1/lstd.src:164` | N/A (prova estática, sem E/S) |
| 2185 | #100 `rtm_orphan_requirement_rejected_law` | CONFERE | `compiler/stage1/lstd.src:166` | N/A (prova estática, sem E/S) |
| 2186 | #101 `mcdc_one_sided_condition_rejected_law` | CONFERE | `compiler/stage1/lstd.src:168` | N/A (prova estática, sem E/S) |
| 2187 | #102 `lockstep_any_divergence_trips_law` | CONFERE | `compiler/stage1/lstd.src:170` | N/A (prova estática, sem E/S) |
| 2188 | #103 `lockstep_latch_is_sticky_law` | CONFERE | `compiler/stage1/lstd.src:172` | N/A (prova estática, sem E/S) |
| 2189 | #104 `ltv_ast_x86_bisimulation_trap_mismatch_law` | CONFERE | `compiler/stage1/lstd.src:174` | N/A (prova estática, sem E/S) |
| 2190 | #105 `soak_telemetry_broken_link_rejected_law` | CONFERE | `compiler/stage1/lstd.src:176` | N/A (prova estática, sem E/S) |
| 2191 | #106 `do330_uncovered_mcdc_blocks_qualification_law` | CONFERE | `compiler/stage1/lstd.src:178` | N/A (prova estática, sem E/S) |
| 2192 | #107 `lumeputer_2oo2d_divergence_veto_law` | CONFERE | `compiler/stage1/lstd.src:180` | N/A (prova estática, sem E/S) |
| 2193 | #108 `no_alloc_heap_escape_rejected_law` | CONFERE | `compiler/stage1/lstd.src:182` | N/A (prova estática, sem E/S) |
| 2194 | #109 `multiarch_fixed_width_misaligned_rejected_law` | CONFERE | `compiler/stage1/lstd.src:184` | N/A (prova estática, sem E/S) |
| 2195 | #110 `linear_channel_lock_cycle_rejected_law` | CONFERE | `compiler/stage1/lstd.src:186` | N/A (prova estática, sem E/S) |
| 2196 | #111 `constant_time_tag_forgery_or_leak_rejected_law` | CONFERE | `compiler/stage1/lstd.src:188` | N/A (prova estática, sem E/S) |
| 2197 | #112 `incremental_proof_cache_stale_deps_miss_law` | CONFERE | `compiler/stage1/lstd.src:190` | N/A (prova estática, sem E/S) |
| 2198 | #113 `safetensors_lumeputer_output_drift_rejected_law` | CONFERE | `compiler/stage1/lstd.src:192` | N/A (prova estática, sem E/S) |
| 2199 | #114 `ecc_instinct_confidence_monotonic_on_positive_evidence` | CONFERE | `compiler/stage1/lume_continuum_nexus_engine.src:51` | N/A (prova estática, sem E/S) |
| 2200 | #115 `bend_conservation_law_holds_for_any_transfer` | CONFERE | `compiler/stage1/lume_continuum_nexus_engine.src:94` | N/A (prova estática, sem E/S) |
| 2201 | #116 `acp_compression_strictly_reduces_window_footprint` | CONFERE | `compiler/stage1/lume_continuum_nexus_engine.src:123` | N/A (prova estática, sem E/S) |
| 2202 | #117 `continuum_deltanet_ram_zero_drift_law` | CONFERE | `compiler/stage1/lume_continuum_nexus_engine.src:134` | N/A (prova estática, sem E/S) |
| 2203 | #118 `aimem_used_memory_decays_slower` | CONFERE | `compiler/stage1/lume_continuum_nexus_engine.src:161` | N/A (prova estática, sem E/S) |
| 2204 | #119 `aimem_handoff_is_claimed_at_most_once` | CONFERE | `compiler/stage1/lume_continuum_nexus_engine.src:166` | N/A (prova estática, sem E/S) |
| 2205 | #120 `llm_router_exhausted_quota_always_falls_back_to_sovereign_local` | CONFERE | `compiler/stage1/lume_continuum_nexus_engine.src:193` | N/A (prova estática, sem E/S) |
| 2206 | #121 `crdt_lww_merge_is_commutative` | CONFERE | `compiler/stage1/lume_continuum_nexus_engine.src:264` | N/A (prova estática, sem E/S) |
| 2207 | #122 `crdt_lww_merge_is_idempotent` | CONFERE | `compiler/stage1/lume_continuum_nexus_engine.src:270` | N/A (prova estática, sem E/S) |
| 2208 | #123 `bitcoin_supply_cap_invariant` | CONFERE | `compiler/stage1/lume_crypto_blockchain_engine.src:5` | N/A (prova estática, sem E/S) |
| 2209 | #124 `utxo_conservation_law` | CONFERE | `compiler/stage1/lume_crypto_blockchain_engine.src:6` | N/A (prova estática, sem E/S) |
| 2210 | #125 `defi_amm_lp_fee_growth_law` | CONFERE | `compiler/stage1/lume_crypto_blockchain_engine.src:7` | N/A (prova estática, sem E/S) |
| 2211 | #126 `kelly_risk_cap_law` | CONFERE | `compiler/stage1/lume_crypto_blockchain_engine.src:8` | N/A (prova estática, sem E/S) |
| 2212 | #127 `law_merkle_root_deterministic` | CONFERE | `compiler/stage1/lume_crypto_blockchain_engine.src:42` | N/A (prova estática, sem E/S) |
| 2213 | #128 `amm_xy_k_nonnegative` | CONFERE | `compiler/stage1/lume_crypto_blockchain_engine.src:113` | N/A (prova estática, sem E/S) |
| 2214 | #129 `heilmeier_full_8_pillars_scores_100` | CONFERE | `compiler/stage1/lume_egm_engine.src:46` | N/A (prova estática, sem E/S) |
| 2215 | #130 `heilmeier_missing_pillar_blocks_approval` | CONFERE | `compiler/stage1/lume_egm_engine.src:49` | N/A (prova estática, sem E/S) |
| 2216 | #131 `goldfish_zero_conversation_bias` | CONFERE | `compiler/stage1/lume_egm_engine.src:67` | N/A (prova estática, sem E/S) |
| 2217 | #132 `egm_glazing_penalizes_style_score` | CONFERE | `compiler/stage1/lume_egm_engine.src:124` | N/A (prova estática, sem E/S) |
| 2218 | #133 `egm_readiness_blocks_on_unresolved_blocker` | CONFERE | `compiler/stage1/lume_egm_engine.src:153` | N/A (prova estática, sem E/S) |
| 2219 | #134 `egm_contradiction_blocks_file_writes` | CONFERE | `compiler/stage1/lume_egm_engine.src:176` | N/A (prova estática, sem E/S) |
| 2220 | #135 `egm_zero_drift_when_spec_matches_code` | CONFERE | `compiler/stage1/lume_egm_engine.src:197` | N/A (prova estática, sem E/S) |
| 2221 | #136 `llm_ternary_zero_sparsity_identity_law` | CONFERE | `compiler/stage1/lume_llm_core.src:198` | N/A (prova estática, sem E/S) |
| 2222 | #137 `llm_binary_vs_ternary_equivalence_law` | CONFERE | `compiler/stage1/lume_llm_core.src:203` | N/A (prova estática, sem E/S) |
| 2223 | #138 `llm_q8_clamp_idempotent_law` | CONFERE | `compiler/stage1/lume_llm_core.src:209` | N/A (prova estática, sem E/S) |
| 2224 | #139 `llm_pack_unpack_trit0_roundtrip_law` | CONFERE | `compiler/stage1/lume_llm_core.src:214` | N/A (prova estática, sem E/S) |
| 2225 | #140 `llm_pack_5trits_bounds_law` | CONFERE | `compiler/stage1/lume_llm_core.src:219` | N/A (prova estática, sem E/S) |
| 2226 | #141 `llm_dspark_guaranteed_forward_progress_law` | CONFERE | `compiler/stage1/lume_llm_core.src:225` | N/A (prova estática, sem E/S) |
| 2227 | #142 `llm_moe_guard_blocks_low_ram_law` | CONFERE | `compiler/stage1/lume_llm_core.src:231` | N/A (prova estática, sem E/S) |
| 2228 | #143 `llm_offline_sovereignty_never_cloud_law` | CONFERE | `compiler/stage1/lume_llm_core.src:236` | N/A (prova estática, sem E/S) |
| 2229 | #144 `llm_price_oracle_rejects_comma_shift_law` | CONFERE | `compiler/stage1/lume_llm_core.src:241` | N/A (prova estática, sem E/S) |
| 2230 | #145 `llm_price_oracle_rejects_underflow_law` | CONFERE | `compiler/stage1/lume_llm_core.src:246` | N/A (prova estática, sem E/S) |
| 2231 | #146 `llm_availability_repair_positive_price_law` | CONFERE | `compiler/stage1/lume_llm_core.src:251` | N/A (prova estática, sem E/S) |
| 2232 | #147 `llm_out_of_stock_never_available_law` | CONFERE | `compiler/stage1/lume_llm_core.src:256` | N/A (prova estática, sem E/S) |
| 2233 | #148 `llm_lumeputer_deltanet_zero_drift_law` | CONFERE | `compiler/stage1/lume_llm_core.src:261` | N/A (prova estática, sem E/S) |
| 2234 | #149 `llm_lumeputer_deltanet_exact_write_law` | CONFERE | `compiler/stage1/lume_llm_core.src:264` | N/A (prova estática, sem E/S) |
| 2235 | #150 `ncm_msrvq_residual_conservation` | CONFERE | `compiler/stage1/lume_ncm_engine.src:37` | N/A (prova estática, sem E/S) |
| 2236 | #151 `ncm_dead_code_replaces_underused_centroid` | CONFERE | `compiler/stage1/lume_ncm_engine.src:71` | N/A (prova estática, sem E/S) |
| 2237 | #152 `ncm_zero_delta_has_zero_optimality_gap` | CONFERE | `compiler/stage1/lume_ncm_engine.src:93` | N/A (prova estática, sem E/S) |
| 2238 | #153 `ncm_same_scale_bidirectional` | CONFERE | `compiler/stage1/lume_ncm_engine.src:129` | N/A (prova estática, sem E/S) |
| 2239 | #154 `ncm_future_scale_blocked` | CONFERE | `compiler/stage1/lume_ncm_engine.src:134` | N/A (prova estática, sem E/S) |
| 2240 | #155 `ncm_cfg_unit_scale_recovers_cond` | CONFERE | `compiler/stage1/lume_ncm_engine.src:167` | N/A (prova estática, sem E/S) |
| 2241 | #156 `ncm_5scales_saves_59_steps_on_64_tokens` | CONFERE | `compiler/stage1/lume_ncm_engine.src:177` | N/A (prova estática, sem E/S) |
| 2242 | #157 `ncm_lumepu_vx_adds_two_npu_layers_law` | CONFERE | `compiler/stage1/lume_ncm_engine.src:192` | N/A (prova estática, sem E/S) |
| 2243 | #158 `ncm_sudoku4_unit_sum_invariant` | CONFERE | `compiler/stage1/lume_ncm_engine.src:212` | N/A (prova estática, sem E/S) |
| 2244 | #159 `ncm_sudoku4_valid_unit_sums_to_10` | CONFERE | `compiler/stage1/lume_ncm_engine.src:228` | N/A (prova estática, sem E/S) |
| 2245 | #160 `otpu_r0_hardwired_zero_and_addr_disjoint` | CONFERE | `compiler/stage1/lume_opentpu_engine.src:50` | N/A (prova estática, sem E/S) |
| 2246 | #161 `otpu_wider_mxu_reduces_or_keeps_replay_passes` | CONFERE | `compiler/stage1/lume_opentpu_engine.src:86` | N/A (prova estática, sem E/S) |
| 2247 | #162 `otpu_fp4_saves_60_bits_per_16_weights` | CONFERE | `compiler/stage1/lume_opentpu_engine.src:145` | N/A (prova estática, sem E/S) |
| 2248 | #163 `otpu_ksmooth_inner_product_invariant` | CONFERE | `compiler/stage1/lume_opentpu_engine.src:189` | N/A (prova estática, sem E/S) |
| 2249 | #164 `otpu_stream_5stage_saves_3_tmem_passes_per_layer` | CONFERE | `compiler/stage1/lume_opentpu_engine.src:227` | N/A (prova estática, sem E/S) |
| 2250 | #165 `otpu_lumeputer_deltanet_hold_law` | CONFERE | `compiler/stage1/lume_opentpu_engine.src:244` | N/A (prova estática, sem E/S) |
| 2251 | #166 `otpu_moe_overlap_never_slower_than_serial` | CONFERE | `compiler/stage1/lume_opentpu_engine.src:272` | N/A (prova estática, sem E/S) |
| 2252 | #167 `otpu_zero_ulp_transitive_equivalence` | CONFERE | `compiler/stage1/lume_opentpu_engine.src:298` | N/A (prova estática, sem E/S) |
| 2253 | #168 `tinyufo_capacity_partition` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:55` | N/A (prova estática, sem E/S) |
| 2254 | #169 `tinyufo_hot_hit_promotes_to_main` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:58` | N/A (prova estática, sem E/S) |
| 2255 | #170 `pingora_p2c_both_dead_picks_none` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:134` | N/A (prova estática, sem E/S) |
| 2256 | #171 `pingora_p2c_picks_peer2_when_strictly_lighter` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:137` | N/A (prova estática, sem E/S) |
| 2257 | #172 `pingora_p2c_never_picks_dead_peer1` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:140` | N/A (prova estática, sem E/S) |
| 2258 | #173 `pingora_p2c_never_picks_dead_peer2` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:143` | N/A (prova estática, sem E/S) |
| 2259 | #174 `pingora_p2c_picks_lighter_healthy_peer` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:146` | N/A (prova estática, sem E/S) |
| 2260 | #175 `pingora_overload_returns_429` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:196` | N/A (prova estática, sem E/S) |
| 2261 | #176 `pingora_stampede_single_leader` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:218` | N/A (prova estática, sem E/S) |
| 2262 | #177 `pingora_zero_dropped_connections` | CONFERE | `compiler/stage1/lume_pingora_proxy_engine.src:251` | N/A (prova estática, sem E/S) |
| 2263 | #178 `q_nia_mod_bound_law` | CONFERE | `compiler/stage1/lume_quantum_nexus_engine.src:38` | N/A (prova estática, sem E/S) |
| 2264 | #179 `qlinear_self_clone_rejected_law` | CONFERE | `compiler/stage1/lume_quantum_nexus_engine.src:74` | N/A (prova estática, sem E/S) |
| 2265 | #180 `q_surface_even_overlap_commutes_law` | CONFERE | `compiler/stage1/lume_quantum_nexus_engine.src:591` | N/A (prova estática, sem E/S) |
| 2266 | #181 `reversa_epistemic_partition_conservation` | CONFERE | `compiler/stage1/lume_reversa_engine.src:18` | N/A (prova estática, sem E/S) |
| 2267 | #182 `reversa_immutability_hash_invariant` | CONFERE | `compiler/stage1/lume_reversa_engine.src:21` | N/A (prova estática, sem E/S) |
| 2268 | #183 `reversa_prune_reachable_conservation` | CONFERE | `compiler/stage1/lume_reversa_engine.src:24` | N/A (prova estática, sem E/S) |
| 2269 | #184 `reversa_code_city_height_conservation` | CONFERE | `compiler/stage1/lume_reversa_engine.src:27` | N/A (prova estática, sem E/S) |
| 2270 | #185 `net_vlan_lower_bound_sound` | CONFERE | `compiler/stage1/net.src:419` | N/A (prova estática, sem E/S) |
| 2271 | #186 `net_mpls_ttl_decreases` | CONFERE | `compiler/stage1/net.src:420` | N/A (prova estática, sem E/S) |
| 2272 | #187 `net_ansi50_sound` | CONFERE | `compiler/stage1/net.src:421` | N/A (prova estática, sem E/S) |
| 2273 | #188 `net_ansi27_undervoltage_sound` | CONFERE | `compiler/stage1/net.src:422` | N/A (prova estática, sem E/S) |
| 2274 | #189 `net_ansi59_overvoltage_sound` | CONFERE | `compiler/stage1/net.src:423` | N/A (prova estática, sem E/S) |
| 2275 | #190 `net_ansi81_nominal_no_trip` | CONFERE | `compiler/stage1/net.src:424` | N/A (prova estática, sem E/S) |
| 2276 | #191 `net_goose_monotonic_refl` | CONFERE | `compiler/stage1/net.src:425` | N/A (prova estática, sem E/S) |
| 2277 | #192 `iec62443_l4_to_l2_direct_forbidden_law` | CONFERE | `compiler/stage1/net.src:461` | N/A (prova estática, sem E/S) |
| 2278 | #193 `ot_readonly_dcs_never_writes_law` | CONFERE | `compiler/stage1/net.src:464` | N/A (prova estática, sem E/S) |
| 2279 | #194 `conduit_infinite_session_rejected_law` | CONFERE | `compiler/stage1/net.src:556` | N/A (prova estática, sem E/S) |
| 2280 | #195 `conduit_ha_order_mismatch_rejected_law` | CONFERE | `compiler/stage1/net.src:559` | N/A (prova estática, sem E/S) |
| 2281 | #196 `conduit_severity_monotonic_law` | CONFERE | `compiler/stage1/net.src:562` | N/A (prova estática, sem E/S) |
| 2282 | #197 `ot_goose_replay_reset_detected_law` | CONFERE | `compiler/stage1/net.src:565` | N/A (prova estática, sem E/S) |
| 2283 | #198 `mesh_nat_token_preservation_law` | CONFERE | `compiler/stage1/net.src:568` | N/A (prova estática, sem E/S) |
| 2284 | #199 `mesh_dht_hierarchy_law` | CONFERE | `compiler/stage1/net.src:571` | N/A (prova estática, sem E/S) |
| 2285 | #200 `mesh_raft_quorum_intersection_law` | CONFERE | `compiler/stage1/net.src:574` | N/A (prova estática, sem E/S) |
| 2286 | #201 `tensor_relu_idempotent_law` | CONFERE | `compiler/stage1/tensor.src:71` | N/A (prova estática, sem E/S) |
| 2287 | #202 `tensor_relu_nonneg_law` | CONFERE | `compiler/stage1/tensor.src:72` | N/A (prova estática, sem E/S) |
| 2288 | #203 `tensor_deltanet_zero_drift_law` | CONFERE | `compiler/stage1/tensor.src:73` | N/A (prova estática, sem E/S) |
| 2289 | #204 `vec_slice_conservation_law` | CONFERE | `compiler/stage1/vec.src:16` | N/A (prova estática, sem E/S) |
| 2290 | #205 `scale_bonus_sound` | CONFERE | `skills/lume/examples/verified_showcase.src:18` | N/A (prova estática, sem E/S) |
| 2291 | #206 `lct_sha256_pad_fills_block` | CONFERE | `compiler/stage1/lcrypto_tls.src:176` | N/A (prova estática, sem E/S) |
| 2292 | #207 `lct_sha512_pad_fills_block` | CONFERE | `compiler/stage1/lcrypto_tls.src:177` | N/A (prova estática, sem E/S) |
| 2293 | #208 `lct_be16_roundtrip` | CONFERE | `compiler/stage1/lcrypto_tls.src:178` | N/A (prova estática, sem E/S) |
| 2294 | #209 `lct_be16_hi_is_a_byte` | CONFERE | `compiler/stage1/lcrypto_tls.src:179` | N/A (prova estática, sem E/S) |
| 2295 | #210 `lct_rotation_complement` | CONFERE | `compiler/stage1/lcrypto_tls.src:180` | N/A (prova estática, sem E/S) |
| 2296 | #211 `lct_tls13_record_overhead` | CONFERE | `compiler/stage1/lcrypto_tls.src:181` | N/A (prova estática, sem E/S) |
| 2297 | #212 `lct_poly1305_limbs_cover_130_bits` | CONFERE | `compiler/stage1/lcrypto_tls.src:182` | N/A (prova estática, sem E/S) |
| 2298 | #213 `lct_ed25519_limbs_cover_256_bits` | CONFERE | `compiler/stage1/lcrypto_tls.src:183` | N/A (prova estática, sem E/S) |
| 2299 | #214 `lct_ent_rct_cutoff_covers_alpha` | CONFERE | `compiler/stage1/lcrypto_tls.src:1202` | N/A (prova estática, sem E/S) |
| 2300 | #215 `lnc_unit_closed_gate_is_zero` | CONFERE | `compiler/stage1/lneural_cartridge.src:201` | N/A (prova estática, sem E/S) |
| 2301 | #216 `lnc_dn_zero_drift` | CONFERE | `compiler/stage1/lneural_cartridge.src:208` | N/A (prova estática, sem E/S) |
| 2302 | #217 `pc_cache_partition_conservation_law` | CONFERE | `compiler/stage1/lproof_cache.src:34` | N/A (prova estática, sem E/S) |
| 2303 | #218 `pc_single_edit_hits_law` | CONFERE | `compiler/stage1/lproof_cache.src:37` | N/A (prova estática, sem E/S) |
| 2304 | #219 `lsp_wire_frame_monotonic_law` | CONFERE | `editors/vscode-lume/lsp_bridge.src:40` | N/A (prova estática, sem E/S) |
| 2305 | #220 `lsp_full_proof_yields_verified_badge_law` | CONFERE | `editors/vscode-lume/lsp_bridge.src:45` | N/A (prova estática, sem E/S) |
| 2306 | #221 `lsp_oversized_payload_rejected_law` | CONFERE | `editors/vscode-lume/lsp_bridge.src:50` | N/A (prova estática, sem E/S) |
| 2307 | #222 `mod11_single_decimal_digit_law` | CONFERE | `examples/apps/brasil_public_id/main.src:57` | N/A (prova estática, sem E/S) |
| 2308 | #223 `cnpj_alnum_monotonic_law` | CONFERE | `examples/apps/brasil_public_id/main.src:63` | N/A (prova estática, sem E/S) |
| 2309 | #224 `nfe_access_key_exact_44_digits_law` | CONFERE | `examples/apps/brasil_public_id/main.src:68` | N/A (prova estática, sem E/S) |
| 2310 | #225 `qsa_equity_conservation_law` | CONFERE | `examples/apps/brasil_public_id/main.src:73` | N/A (prova estática, sem E/S) |
| 2311 | #226 `dfe_vnf_non_negative_law` | CONFERE | `examples/apps/dfe_pix_bacen/main.src:59` | N/A (prova estática, sem E/S) |
| 2312 | #227 `pix_cobv_positive_settlement_law` | CONFERE | `examples/apps/dfe_pix_bacen/main.src:64` | N/A (prova estática, sem E/S) |
| 2313 | #228 `pix_devolucao_safe_refund_cap_law` | CONFERE | `examples/apps/dfe_pix_bacen/main.src:69` | N/A (prova estática, sem E/S) |
| 2314 | #229 `pix_devolucao_conservation_law` | CONFERE | `examples/apps/dfe_pix_bacen/main.src:75` | N/A (prova estática, sem E/S) |
| 2315 | #230 `npp_other_view_involution` | CONFERE | `examples/apps/notepad_plus_lume/notepad_plus_core.src:84` | N/A (prova estática, sem E/S) |
| 2316 | #231 `omniroute_budget_conservation_law` | CONFERE | `examples/apps/omniroute_guard/main.src:85` | N/A (prova estática, sem E/S) |
| 2317 | #232 `omniroute_concurrent_inflight_safety_law` | CONFERE | `examples/apps/omniroute_guard/main.src:91` | N/A (prova estática, sem E/S) |
| 2318 | #233 `pix_med_conservation_law` | CONFERE | `examples/apps/pix_fraud_trace/main.src:78` | N/A (prova estática, sem E/S) |
| 2319 | #234 `pix_med_cap_law` | CONFERE | `examples/apps/pix_fraud_trace/main.src:83` | N/A (prova estática, sem E/S) |
| 2320 | #235 `uav_geofence_ceiling_law` | CONFERE | `examples/apps/sentry_uav_guard/main.src:54` | N/A (prova estática, sem E/S) |
| 2321 | #236 `uav_geofence_floor_law` | CONFERE | `examples/apps/sentry_uav_guard/main.src:57` | N/A (prova estática, sem E/S) |
| 2322 | #237 `uav_radius_monotonic_law` | CONFERE | `examples/apps/sentry_uav_guard/main.src:60` | N/A (prova estática, sem E/S) |
| 2323 | #238 `uav_safe_altitude_envelope_law` | CONFERE | `examples/apps/sentry_uav_guard/main.src:65` | N/A (prova estática, sem E/S) |
| 2324 | #239 `sovereign_router_offline_airgap_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:134` | N/A (prova estática, sem E/S) |
| 2325 | #240 `sovereign_router_symbolic_tier0_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:139` | N/A (prova estática, sem E/S) |
| 2326 | #241 `bonsai_ternary_sparsity_zero_skip_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:144` | N/A (prova estática, sem E/S) |
| 2327 | #242 `llm_pack_unpack_trit0_roundtrip_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:149` | N/A (prova estática, sem E/S) |
| 2328 | #243 `dspark_speculative_progress_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:154` | N/A (prova estática, sem E/S) |
| 2329 | #244 `colibri_moe_ssd_trap_rejection_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:160` | N/A (prova estática, sem E/S) |
| 2330 | #245 `vkpromos_comma_shift_hallucination_rejected_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:165` | N/A (prova estática, sem E/S) |
| 2331 | #246 `llm_price_oracle_rejects_underflow_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:170` | N/A (prova estática, sem E/S) |
| 2332 | #247 `vkpromos_availability_auto_repair_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:175` | N/A (prova estática, sem E/S) |
| 2333 | #248 `llm_out_of_stock_never_available_law` | CONFERE | `examples/apps/sovereign_llm_router/main.src:180` | N/A (prova estática, sem E/S) |
| 2334 | #249 `vault_never_below_reserve` | CONFERE | `examples/apps/supply_chain_demo/ledger_guard.src:11` | N/A (prova estática, sem E/S) |
| 2335 | #250 `conservation_of_escrow` | CONFERE | `examples/apps/supply_chain_demo/ledger_guard.src:13` | N/A (prova estática, sem E/S) |
| 2336 | #251 `double_entry_zero_imbalance_law` | CONFERE | `examples/apps/verified_accounting/main.src:32` | N/A (prova estática, sem E/S) |
| 2337 | #252 `fiscal_split_conservation_law` | CONFERE | `examples/apps/verified_accounting/main.src:37` | N/A (prova estática, sem E/S) |
| 2338 | #253 `clamped_retention_bounds_law` | CONFERE | `examples/apps/verified_accounting/main.src:42` | N/A (prova estática, sem E/S) |
| 2339 | #254 `zbt_fail_closed_never_clean_law` | CONFERE | `examples/apps/zero_breach_forensics/main.src:44` | N/A (prova estática, sem E/S) |
| 2340 | #255 `zbt_heuristics_alone_never_compromised_law` | CONFERE | `examples/apps/zero_breach_forensics/main.src:49` | N/A (prova estática, sem E/S) |
| 2341 | #256 `zbt_withdrawn_stix_never_active_law` | CONFERE | `examples/apps/zero_breach_forensics/main.src:54` | N/A (prova estática, sem E/S) |
| 2342 | #257 `zbt_evidence_monotonic_law` | CONFERE | `examples/apps/zero_breach_forensics/main.src:59` | N/A (prova estática, sem E/S) |
| 2343 | #258 `settlement_conserves_value` | CONFERE | `examples/interop/sidecar/payment_core.src:10` | N/A (prova estática, sem E/S) |
| 2344 | #259 `rate_limit_monotone_step` | CONFERE | `examples/synergy/critical_pipeline.src:38` | N/A (prova estática, sem E/S) |
| 2345 | #260 `synth_add_comm` | CONFERE | `compiler/stage1/intent_oracle_ok.src:19` | N/A (prova estática, sem E/S) |
| 2346 | #261 `synth_add_zero` | CONFERE | `compiler/stage1/intent_oracle_ok.src:20` | N/A (prova estática, sem E/S) |
| 2347 | #262 `synth_max_idemp` | CONFERE | `compiler/stage1/intent_oracle_ok.src:21` | N/A (prova estática, sem E/S) |
| 2348 | #263 `synth_withdraw_deposit` | CONFERE | `compiler/stage1/intent_oracle_ok.src:22` | N/A (prova estática, sem E/S) |
| 2349 | #264 `withdraw_zero` | CONFERE | `compiler/stage1/track_i_intent_ok.src:9` | N/A (prova estática, sem E/S) |
| 2350 | #265 `ui_split_conservation_law` | CONFERE | `compiler/stage1/win64_gui_and_interp_regression_ok.src:33` | N/A (prova estática, sem E/S) |
| 2351 | #266 `max2_sym` | CONFERE | `tests/llm_gen_eval/tasks/03_max2_law_attempt1.src:3` | N/A (prova estática, sem E/S) |

Leis reais omitidas pelo catálogo:

| arquivo | lei | estado | motivo provável |
|---|---|---|---|
| `examples/apps/omniroute_guard/main.src:62` | `omniroute_confidential_sovereignty_law` | HEAD e árvore | assinatura multilinha |
| `examples/apps/omniroute_guard/main.src:73` | `omniroute_valid_tier_bounds_law` | HEAD e árvore | assinatura multilinha |
| `compiler/stage1/hostio.src` | `hio_status_is_exit_code_law` | só árvore (arquivo novo do porte) | arquivo posterior ao catálogo |

Observações: 20 nomes de lei aparecem duplicados em `lchameleon.src` e `lstd.src`, e 2 em `lume_llm_core.src` e `examples/apps/sovereign_llm_router/main.src` (são leis distintas com o mesmo nome em arquivos diferentes; o catálogo as lista corretamente como entradas separadas). A entrada 266 (`tests/llm_gen_eval/tasks/03_max2_law_attempt1.src`) é uma tentativa de LLM usada como fixture de avaliação, não uma lei da biblioteca.

## 3. Seção 10.2 — catálogo função por função (linhas 2353–2567)

Para cada bloco: as contagens anunciadas (funções sem `test_*`, leis, testes) foram comparadas com o primeiro arquivo do título; todas as assinaturas listadas foram procuradas no fonte. **Nenhuma assinatura listada é inexistente** (0 de 2965). Divergências vêm de assinaturas multilinha/`pub llm fn` omitidas e de títulos que juntam vários arquivos mas contam só o primeiro.

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 2357 | `compiler/stage1/lstd.src` | CONFERE | anunciado (47, 23, 7); HEAD (47, 23, 7); 47 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2361 | `stdlib/std.lume` | CONFERE | anunciado (62, 0, 21); HEAD (62, 0, 21); 62 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2365 | `stdlib/crypto.lume` | CONFERE | anunciado (23, 0, 3); HEAD (23, 0, 3); 23 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2369 | `compiler/stage1/arena.src` | CONFERE parcial | anunciado (17, 0, 0); HEAD (17, 0, 0); 17 assinaturas listadas, 0 ausentes do fonte. título junta `arena.src` e `arena_mem.src`, mas os números são só de `arena.src` | OK (sem dependencia de SO detectada) |
| 2373 | `compiler/stage1/arena_mem.src` | CONFERE | anunciado (7, 0, 0); HEAD (7, 0, 0); 7 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2377 | `compiler/stage1/bytes.src` | CONFERE | anunciado (20, 0, 20); HEAD (20, 0, 20); 20 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2381 | `compiler/stage1/fs.src` | CONFERE parcial | anunciado (16, 0, 11); HEAD (16, 0, 11); 16 assinaturas listadas, 0 ausentes do fonte. título junta `fs.src` e `fs_sha256_file.src`, números só de `fs.src` | OK (sem dependencia de SO detectada) |
| 2385 | `compiler/stage1/fs_sha256_file.src` | CONFERE | anunciado (24, 0, 2); HEAD (24, 0, 2); 24 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2389 | `compiler/stage1/map.src` | CONFERE | anunciado (22, 0, 3); HEAD (22, 0, 3); 22 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2393 | `compiler/stage1/vec.src` | CONFERE | anunciado (4, 1, 4); HEAD (4, 1, 4); 4 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2397 | `compiler/stage1/decimal.src` | CONFERE | anunciado (29, 0, 16); HEAD (29, 0, 16); 29 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2401 | `compiler/stage1/table.src` | CONFERE parcial | anunciado (105, 0, 0); HEAD (105, 0, 0); 105 assinaturas listadas, 0 ausentes do fonte. título junta `table.src` e `query.src`, números só de `table.src` | OK (sem dependencia de SO detectada) |
| 2405 | `compiler/stage1/query.src` | CONFERE | anunciado (31, 0, 0); HEAD (31, 0, 0); 31 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2409 | `compiler/stage1/process.src` | DIVERGE | anunciado (40, 8, 4); HEAD (4, 0, 7); 40 assinaturas listadas, 0 ausentes do fonte. título cita process/concurrency/actor/async_rt/lconcurrency, mas 40/8/4 são só de `lconcurrency.src` (44 fn − 4 testes); os 5 juntos dão 119 fn, 8 leis, 27 testes | OK provavel (os_run so de ferramentas lume) |
| 2413 | `compiler/stage1/concurrency.src` | CONFERE | anunciado (29, 0, 5); HEAD (29, 0, 5); 29 assinaturas listadas, 0 ausentes do fonte | PENDENTE parcial: os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2417 | `compiler/stage1/actor.src` | CONFERE | anunciado (20, 0, 5); HEAD (20, 0, 5); 20 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2421 | `compiler/stage1/async_rt.src` | CONFERE | anunciado (26, 0, 6); HEAD (26, 0, 6); 26 assinaturas listadas, 0 ausentes do fonte | PENDENTE: sockets/epoll (epoll_add_in, epoll_create_fd, epoll_wait_one, net_close); os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2425 | `compiler/stage1/capsule.src` | CONFERE | anunciado (28, 0, 0); HEAD (28, 0, 0); 28 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2429 | `compiler/stage1/interop.src` | CONFERE | anunciado (61, 0, 6); HEAD (61, 0, 6); 61 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2433 | `compiler/stage1/lchameleon.src` | CONFERE | anunciado (114, 65, 19); HEAD (114, 65, 19); 114 assinaturas listadas, 0 ausentes do fonte | PENDENTE: sockets/epoll (net_close); io_uring |
| 2437 | `compiler/stage1/gfx.src` | CONFERE | anunciado (66, 7, 11); HEAD (66, 7, 11); 66 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2441 | `compiler/stage1/gui.src` | CONFERE | anunciado (53, 2, 7); HEAD (53, 2, 7); 53 assinaturas listadas, 0 ausentes do fonte | PENDENTE: sockets/epoll (net_close, net_recv_str, net_send_str, net_tcp_accept, net_tcp_connect, net_tcp_listen); os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2445 | `compiler/stage1/media.src` | CONFERE | anunciado (27, 0, 5); HEAD (27, 0, 5); 27 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2449 | `compiler/stage1/net.src` | CONFERE | anunciado (186, 16, 16); HEAD (186, 16, 16); 186 assinaturas listadas, 0 ausentes do fonte | PENDENTE: sockets/epoll (net_close, net_recv_str, net_send_str, net_tcp_accept, net_tcp_connect, net_tcp_listen, net_udp_bind, net_udp_sendto); os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2453 | `compiler/stage1/db.src` | CONFERE | anunciado (107, 2, 9); HEAD (107, 2, 9); 107 assinaturas listadas, 0 ausentes do fonte | PENDENTE parcial: os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2457 | `compiler/stage1/los.src` | CONFERE | anunciado (91, 1, 8); HEAD (91, 1, 8); 91 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2461 | `compiler/stage1/tensor.src` | CONFERE parcial | anunciado (53, 3, 6); HEAD (53, 3, 6); 53 assinaturas listadas, 0 ausentes do fonte. título cita tensor/nn/ai_runtime/lume_llm_core, números só de `tensor.src`; os 4 juntos dão 253 fn, 17 leis, 20 testes | OK (sem dependencia de SO detectada) |
| 2465 | `compiler/stage1/nn.src` | CONFERE | anunciado (136, 0, 7); HEAD (136, 0, 7); 136 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2469 | `compiler/stage1/ai_runtime.src` | CONFERE | anunciado (47, 0, 6); HEAD (47, 0, 6); 47 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2473 | `compiler/stage1/lume_llm_core.src` | DIVERGE | anunciado (16, 14, 1); HEAD (17, 14, 1); 16 assinaturas listadas, 0 ausentes do fonte. omite `llm_moe_admission_guard` (assinatura multilinha, linha 123) | OK (sem dependencia de SO detectada) |
| 2477 | `compiler/stage1/lmesh.src` | CONFERE | anunciado (131, 0, 0); HEAD (131, 0, 0); 131 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2481 | `compiler/stage1/leconomy.src` | CONFERE | anunciado (49, 0, 0); HEAD (49, 0, 0); 49 assinaturas listadas, 0 ausentes do fonte | PENDENTE: programas externos: git |
| 2485 | `compiler/stage1/lregistry.src` | CONFERE | anunciado (88, 0, 1); HEAD (88, 0, 1); 88 assinaturas listadas, 0 ausentes do fonte | OK provavel (os_run so de ferramentas lume, /bin/* emulado por hostio) |
| 2489 | `compiler/stage1/levidence.src` | CONFERE | anunciado (70, 0, 7); HEAD (70, 0, 7); 70 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2493 | `compiler/stage1/levolve.src` | CONFERE com a árvore (não com HEAD) | anunciado (174, 1, 2); HEAD (174, 1, 1), árvore (174, 1, 2); 174 assinaturas listadas, 0 ausentes do fonte. 2 testes só na árvore (`test_ev_unsafe_path_windows_forms` é do porte); HEAD tem 1 | OK (sem dependencia de SO detectada) |
| 2497 | `compiler/stage1/lsentience.src` | CONFERE | anunciado (203, 4, 35); HEAD (203, 4, 35); 203 assinaturas listadas, 0 ausentes do fonte | PENDENTE: sockets/epoll (net_close@lchameleon.src, net_close@net.src, net_recv_str@net.src, net_send_str@net.src, net_tcp_accept@net.src, net_tcp); io_uring; programas externos: 7z, curl, ip, ping, scp, sh, ss, ssh, tailscale; os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2501 | `compiler/stage1/lume_reversa_engine.src` | CONFERE | anunciado (86, 4, 4); HEAD (86, 4, 4); 86 assinaturas listadas, 0 ausentes do fonte | PENDENTE: programas externos: 7z |
| 2505 | `compiler/stage1/lume_pingora_proxy_engine.src` | CONFERE | anunciado (31, 10, 5); HEAD (31, 10, 5); 31 assinaturas listadas, 0 ausentes do fonte | PENDENTE: sockets/epoll (net_close@net.src, net_recv_str@net.src, net_send_str@net.src, net_tcp_accept@net.src, net_tcp_connect@net.src, net_tcp_); os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2509 | `compiler/stage1/lume_egm_engine.src` | CONFERE | anunciado (24, 7, 4); HEAD (24, 7, 4); 24 assinaturas listadas, 0 ausentes do fonte | PENDENTE: programas externos: 7z |
| 2513 | `compiler/stage1/lume_ncm_engine.src` | CONFERE | anunciado (28, 10, 6); HEAD (28, 10, 6); 28 assinaturas listadas, 0 ausentes do fonte | PENDENTE: programas externos: 7z |
| 2517 | `compiler/stage1/lume_opentpu_engine.src` | CONFERE | anunciado (45, 8, 4); HEAD (45, 8, 4); 45 assinaturas listadas, 0 ausentes do fonte | PENDENTE: programas externos: 7z |
| 2521 | `compiler/stage1/lume_continuum_nexus_engine.src` | CONFERE | anunciado (35, 9, 5); HEAD (35, 9, 5); 35 assinaturas listadas, 0 ausentes do fonte | PENDENTE: programas externos: 7z |
| 2525 | `compiler/stage1/lume_quantum_nexus_engine.src` | CONFERE | anunciado (112, 3, 7); HEAD (112, 3, 7); 112 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2529 | `compiler/stage1/lume_crypto_blockchain_engine.src` | CONFERE parcial | anunciado (49, 6, 9); HEAD (49, 6, 9); 46 assinaturas listadas, 0 ausentes do fonte. contagem 49 confere, mas a lista traz só 46 assinaturas (faltam `ct_tag_xor_diff`, `kelly_optimal_fraction_bp`, `quant_position_size_sats`, linhas 133–137) | OK (sem dependencia de SO detectada) |
| 2536 | `examples/apps/agent/main.src` | CONFERE | anunciado (1, 0, 3); HEAD (1, 0, 3); 1 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2537 | `examples/apps/agent/planner.src` | CONFERE | anunciado (2, 0, 0); HEAD (2, 0, 0); 2 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2538 | `examples/apps/agent/rules.src` | CONFERE | anunciado (2, 0, 0); HEAD (2, 0, 0); 2 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2539 | `examples/apps/agent/schema.src` | CONFERE | anunciado (3, 0, 0); HEAD (3, 0, 0); 3 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2540 | `examples/apps/brasil_public_id/main.src` | DIVERGE | anunciado (3, 4, 1); HEAD (5, 4, 1); 3 assinaturas listadas, 0 ausentes do fonte. omite `nfe_key_segment_length` e `nfe_access_key_length_valid` (multilinha) | OK (sem dependencia de SO detectada) |
| 2541 | `examples/apps/dfe_pix_bacen/main.src` | CONFERE | anunciado (7, 4, 1); HEAD (7, 4, 1); 7 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2542 | `examples/apps/inventory/catalog.src` | CONFERE | anunciado (33, 0, 0); HEAD (33, 0, 0); 33 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2543 | `examples/apps/inventory/invoicing.src` | CONFERE | anunciado (35, 0, 0); HEAD (35, 0, 0); 35 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2544 | `examples/apps/inventory/main.src` | CONFERE | anunciado (0, 0, 10); HEAD (0, 0, 10); 0 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2545 | `examples/apps/inventory/reports.src` | CONFERE | anunciado (14, 0, 0); HEAD (14, 0, 0); 14 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2546 | `examples/apps/job_server/engine.src` | DIVERGE | anunciado (4, 0, 0); HEAD (5, 0, 0); 4 assinaturas listadas, 0 ausentes do fonte. omite `pub llm fn estimate_job_priority` (linha 13) | OK (sem dependencia de SO detectada) |
| 2547 | `examples/apps/job_server/main.src` | CONFERE | anunciado (3, 0, 7); HEAD (3, 0, 7); 3 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2548 | `examples/apps/job_server/protocol.src` | CONFERE | anunciado (9, 0, 0); HEAD (9, 0, 0); 9 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2549 | `examples/apps/job_server/workers.src` | CONFERE | anunciado (24, 0, 0); HEAD (24, 0, 0); 24 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2550 | `examples/apps/lume_os/caps.src` | CONFERE | anunciado (3, 0, 0); HEAD (3, 0, 0); 3 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2551 | `examples/apps/lume_os/ipc.src` | CONFERE | anunciado (3, 0, 0); HEAD (3, 0, 0); 3 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2552 | `examples/apps/lume_os/kernel_qemu.src` | CONFERE | anunciado (7, 0, 0); HEAD (7, 0, 0); 7 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2553 | `examples/apps/lume_os/main.src` | CONFERE | anunciado (1, 0, 3); HEAD (1, 0, 3); 1 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2554 | `examples/apps/lume_os/scheduler.src` | CONFERE | anunciado (3, 0, 0); HEAD (3, 0, 0); 3 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2555 | `examples/apps/mnist/dataset.src` | CONFERE | anunciado (2, 0, 0); HEAD (2, 0, 0); 2 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2556 | `examples/apps/mnist/main.src` | CONFERE | anunciado (1, 0, 3); HEAD (1, 0, 3); 1 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2557 | `examples/apps/mnist/model.src` | CONFERE | anunciado (2, 0, 0); HEAD (2, 0, 0); 2 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2558 | `examples/apps/notepad_plus_lume/notepad_plus_core.src` | CONFERE | anunciado (107, 1, 4); HEAD (107, 1, 4); 107 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2559 | `examples/apps/omniroute_guard/main.src` | DIVERGE | anunciado (1, 2, 1); HEAD (4, 4, 1); 1 assinaturas listadas, 0 ausentes do fonte. omite 3 fn multilinha e 2 leis multilinha (real: 4 fn, 4 leis) | OK (sem dependencia de SO detectada) |
| 2560 | `examples/apps/p0_rtc_kernel/kernel_rtc.src` | CONFERE | anunciado (8, 0, 0); HEAD (8, 0, 0); 8 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2561 | `examples/apps/p0_tenant_ledger/ledger_server.src` | CONFERE | anunciado (24, 0, 0); HEAD (24, 0, 0); 24 assinaturas listadas, 0 ausentes do fonte | PENDENTE: sockets/epoll (net_close, net_close@net.src, net_recv_str, net_recv_str@net.src, net_send_str, net_send_str@net.src, net_tcp_accept, ne); os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2562 | `examples/apps/pix_fraud_trace/main.src` | DIVERGE | anunciado (6, 2, 1); HEAD (7, 2, 1); 6 assinaturas listadas, 0 ausentes do fonte. omite `pix_trace_hop_risk_bps` (multilinha) | OK (sem dependencia de SO detectada) |
| 2563 | `examples/apps/sentry_uav_guard/main.src` | DIVERGE | anunciado (4, 4, 1); HEAD (5, 4, 1); 4 assinaturas listadas, 0 ausentes do fonte. omite `uav_safe_altitude_guard_mm` (multilinha) | OK (sem dependencia de SO detectada) |
| 2564 | `examples/apps/sovereign_llm_router/main.src` | DIVERGE | anunciado (14, 10, 1); HEAD (15, 10, 1); 14 assinaturas listadas, 0 ausentes do fonte. omite `llm_moe_admission_guard` (multilinha) | OK (sem dependencia de SO detectada) |
| 2565 | `examples/apps/supply_chain_demo/ledger_guard.src` | CONFERE | anunciado (2, 2, 2); HEAD (2, 2, 2); 2 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2566 | `examples/apps/verified_accounting/main.src` | CONFERE | anunciado (4, 3, 1); HEAD (4, 3, 1); 4 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |
| 2567 | `examples/apps/zero_breach_forensics/main.src` | CONFERE | anunciado (4, 4, 1); HEAD (4, 4, 1); 4 assinaturas listadas, 0 ausentes do fonte | OK (sem dependencia de SO detectada) |

## 4. Seção 10.3 — os 47 módulos do compilador (linhas 2569–2619)

Colunas conferidas: linhas, funções (sem `test_*`), leis, testes; e se cada uma das 12 "funções chave" existe. **Todas as funções chave existem** (0 ausentes).

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 2573 | `compiler/stage1/lume/01_lexer.src` | CONFERE | anunciado lin/fn/law/test [183, 99, 0, 0]; HEAD [183, 99, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2574 | `compiler/stage1/lume/02_parser.src` | CONFERE | anunciado lin/fn/law/test [127, 74, 0, 0]; HEAD [127, 74, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2575 | `compiler/stage1/lume/03_comptime.src` | CONFERE | anunciado lin/fn/law/test [453, 173, 0, 0]; HEAD [453, 173, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2576 | `compiler/stage1/lume/04_parser_decls.src` | CONFERE | anunciado lin/fn/law/test [721, 254, 0, 0]; HEAD [721, 254, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2577 | `compiler/stage1/lume/05_codegen.src` | CONFERE | anunciado lin/fn/law/test [975, 367, 0, 0]; HEAD [975, 367, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2578 | `compiler/stage1/lume/06_typecheck.src` | CONFERE | anunciado lin/fn/law/test [1257, 402, 0, 0]; HEAD [1257, 402, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2579 | `compiler/stage1/lume/06b_phase3.src` | CONFERE | anunciado lin/fn/law/test [5344, 1345, 0, 0]; HEAD [5344, 1345, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2580 | `compiler/stage1/lume/07_driver.src` | DIVERGE (nem HEAD nem árvore atual: snapshot intermediário) | anunciado lin/fn/law/test [394, 132, 0, 0]; HEAD [376, 126, 0, 0]; árvore [394, 138, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2581 | `compiler/stage1/name_flow.src` | CONFERE | anunciado lin/fn/law/test [356, 115, 0, 0]; HEAD [356, 115, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2582 | `compiler/stage1/own_flow.src` | CONFERE | anunciado lin/fn/law/test [672, 176, 0, 0]; HEAD [672, 176, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2583 | `compiler/stage1/data_asmgen.lume` | CONFERE | anunciado lin/fn/law/test [751, 22, 0, 0]; HEAD [751, 22, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2584 | `compiler/stage1/data_ast.lume` | CONFERE | anunciado lin/fn/law/test [43, 0, 0, 0]; HEAD [43, 0, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2585 | `compiler/stage1/data_codegen.lume` | CONFERE | anunciado lin/fn/law/test [8, 1, 0, 0]; HEAD [8, 1, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2586 | `compiler/stage1/data_eval.lume` | CONFERE | anunciado lin/fn/law/test [754, 40, 0, 0]; HEAD [754, 40, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2587 | `compiler/stage1/data_parser.lume` | CONFERE | anunciado lin/fn/law/test [593, 22, 0, 0]; HEAD [593, 22, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2588 | `compiler/stage1/larm64.src` | CONFERE | anunciado lin/fn/law/test [149, 77, 0, 2]; HEAD [149, 77, 0, 2]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2589 | `compiler/stage1/lasm.src` | CONFERE com a árvore (não com HEAD) | anunciado lin/fn/law/test [698, 342, 0, 0]; HEAD [620, 314, 0, 0]; árvore [698, 342, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2590 | `compiler/stage1/layout.lume` | CONFERE | anunciado lin/fn/law/test [160, 7, 0, 0]; HEAD [160, 7, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2591 | `compiler/stage1/lcaas.src` | CONFERE | anunciado lin/fn/law/test [4564, 1560, 0, 0]; HEAD [4564, 1560, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2592 | `compiler/stage1/lcert.src` | CONFERE | anunciado lin/fn/law/test [1191, 503, 0, 17]; HEAD [1191, 503, 0, 17]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2593 | `compiler/stage1/lcli.src` | CONFERE | anunciado lin/fn/law/test [192, 38, 0, 0]; HEAD [192, 38, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2594 | `compiler/stage1/lcrypto_tls.src` | CONFERE | anunciado lin/fn/law/test [1900, 719, 9, 21]; HEAD [1900, 719, 9, 21]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2595 | `compiler/stage1/lexer.lume` | CONFERE | anunciado lin/fn/law/test [69, 5, 0, 0]; HEAD [69, 5, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2596 | `compiler/stage1/lfmt.src` | CONFERE | anunciado lin/fn/law/test [254, 133, 0, 0]; HEAD [254, 133, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2597 | `compiler/stage1/linteractive.src` | CONFERE | anunciado lin/fn/law/test [78, 68, 0, 1]; HEAD [78, 68, 0, 1]; árvore [79, 68, 0, 1]; funções chave ausentes: 0 | PENDENTE: sockets/epoll (net_close@lchameleon.src); io_uring |
| 2598 | `compiler/stage1/lkir.src` | CONFERE | anunciado lin/fn/law/test [209, 90, 0, 2]; HEAD [209, 90, 0, 2]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2599 | `compiler/stage1/lmanual.src` | CONFERE | anunciado lin/fn/law/test [1835, 40, 0, 4]; HEAD [1835, 40, 0, 4]; funções chave ausentes: 0 | OK provavel (os_run so de ferramentas lume) |
| 2600 | `compiler/stage1/lmcdc.src` | CONFERE | anunciado lin/fn/law/test [571, 178, 0, 0]; HEAD [571, 178, 0, 0]; árvore [572, 178, 0, 0]; funções chave ausentes: 0 | PENDENTE: programas externos: cvc5, sh, z3; gera/executa ELF |
| 2601 | `compiler/stage1/lmod.src` | CONFERE | anunciado lin/fn/law/test [174, 73, 0, 0]; HEAD [174, 73, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2602 | `compiler/stage1/lneural_cartridge.src` | CONFERE | anunciado lin/fn/law/test [434, 170, 2, 7]; HEAD [434, 170, 2, 7]; funções chave ausentes: 0 | PENDENTE: programas externos: sh; gera/executa ELF |
| 2603 | `compiler/stage1/lproof_cache.src` | CONFERE | anunciado lin/fn/law/test [358, 123, 2, 5]; HEAD [358, 123, 2, 5]; árvore [359, 123, 2, 5]; funções chave ausentes: 0 | OK provavel (os_run so de ferramentas lume) |
| 2604 | `compiler/stage1/lprotect.src` | CONFERE | anunciado lin/fn/law/test [228, 110, 0, 2]; HEAD [228, 110, 0, 2]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2605 | `compiler/stage1/lqualify.src` | CONFERE | anunciado lin/fn/law/test [618, 284, 0, 8]; HEAD [618, 284, 0, 8]; árvore [619, 284, 0, 8]; funções chave ausentes: 0 | PENDENTE: programas externos: date, qemu-aarch64, qemu-riscv64, qemu-system-riscv32, readelf, uname, z3; gera/executa ELF |
| 2606 | `compiler/stage1/lriscv.src` | CONFERE | anunciado lin/fn/law/test [158, 87, 0, 2]; HEAD [158, 87, 0, 2]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2607 | `compiler/stage1/lrv32_lowered.src` | CONFERE | anunciado lin/fn/law/test [132, 52, 0, 0]; HEAD [132, 52, 0, 0]; funções chave ausentes: 0 | PENDENTE: programas externos: sh; gera/executa ELF |
| 2608 | `compiler/stage1/lsafety_envelope.src` | CONFERE | anunciado lin/fn/law/test [1286, 560, 0, 0]; HEAD [1286, 560, 0, 0]; árvore [1292, 564, 0, 0]; funções chave ausentes: 0 | PENDENTE: programas externos: sh; gera/executa ELF |
| 2609 | `compiler/stage1/lsmt.src` | CONFERE | anunciado lin/fn/law/test [548, 228, 0, 9]; HEAD [548, 228, 0, 9]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2610 | `compiler/stage1/lstack.src` | CONFERE | anunciado lin/fn/law/test [325, 137, 0, 0]; HEAD [325, 137, 0, 0]; árvore [326, 137, 0, 0]; funções chave ausentes: 0 | PENDENTE: gera/executa ELF |
| 2611 | `compiler/stage1/ltarget.src` | CONFERE | anunciado lin/fn/law/test [1290, 467, 0, 15]; HEAD [1290, 467, 0, 15]; árvore [1291, 468, 0, 15]; funções chave ausentes: 0 | OK provavel (os_run so de ferramentas lume) |
| 2612 | `compiler/stage1/ltest.src` | CONFERE | anunciado lin/fn/law/test [83, 37, 0, 0]; HEAD [83, 37, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2613 | `compiler/stage1/ltv.src` | CONFERE | anunciado lin/fn/law/test [1451, 575, 0, 4]; HEAD [1451, 575, 0, 4]; árvore [1452, 575, 0, 4]; funções chave ausentes: 0 | PENDENTE: programas externos: cvc5, sh, z3; gera/executa ELF |
| 2614 | `compiler/stage1/ltv_multiarch.src` | CONFERE | anunciado lin/fn/law/test [354, 139, 0, 0]; HEAD [354, 139, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2615 | `compiler/stage1/ltv_rt.src` | CONFERE | anunciado lin/fn/law/test [713, 283, 0, 7]; HEAD [713, 283, 0, 7]; árvore [714, 283, 0, 7]; funções chave ausentes: 0 | OK provavel (os_run so de ferramentas lume) |
| 2616 | `compiler/stage1/lume_driver.src` | DIVERGE (nem HEAD nem árvore atual: snapshot intermediário) | anunciado lin/fn/law/test [1246, 406, 0, 1]; HEAD [1236, 402, 0, 1]; árvore [1248, 407, 0, 1]; funções chave ausentes: 0 | PENDENTE: sockets/epoll (net_close@lchameleon.src, net_close@net.src, net_recv_str@net.src, net_send_str@net.src, net_tcp_accept@net.src, net_tcp); io_uring; programas externos: 7z, curl, flock, ip, native_installer, ping, scp, sh, sha256sum, ss, ssh, tailscale; gera/executa ELF; os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2617 | `compiler/stage1/lx509.src` | CONFERE | anunciado lin/fn/law/test [200, 57, 0, 5]; HEAD [200, 57, 0, 5]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2618 | `compiler/stage1/protect.src` | CONFERE | anunciado lin/fn/law/test [212, 81, 0, 5]; HEAD [212, 81, 0, 5]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |
| 2619 | `compiler/stage1/runtime_core.lume` | CONFERE com a árvore (não com HEAD) | anunciado lin/fn/law/test [160, 41, 0, 0]; HEAD [139, 38, 0, 0]; árvore [160, 41, 0, 0]; funções chave ausentes: 0 | OK (sem dependencia de SO detectada) |

Títulos: "47 módulos" confere; "10.892 funções internas" é a soma da coluna do próprio catálogo, mas HEAD dá 10851 e a árvore 10904.

## 5. Parte XI

### 5.1 Seção 11.1 — distribuição por diretório (linhas 2626–2641)

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 2630 | `bootstrap/lume0` | DIVERGE | anunciado arq/linhas/aux/test [99, 1053, 186, 0]; HEAD [99, 1053, 188, 0] | OK: 98, PENDENTE: 1 |
| 2631 | `compiler/stage1` | DIVERGE | anunciado arq/linhas/aux/test [55, 1723, 312, 121]; HEAD [55, 1723, 317, 121] | OK: 52, OK provavel: 1, PENDENTE: 1, PENDENTE parcial: 1 |
| 2632 | `tests/capstones` | CONFERE | anunciado arq/linhas/aux/test [3, 148, 85, 7]; HEAD [3, 148, 85, 7] | OK: 1, PENDENTE: 2 |
| 2633 | `tests/cli` | CONFERE | anunciado arq/linhas/aux/test [6, 1319, 442, 0]; HEAD [6, 1319, 442, 0]; árvore [6, 1322, 442, 0] | OK provavel: 5, PENDENTE: 1 |
| 2634 | `tests/conformance` | DIVERGE | anunciado arq/linhas/aux/test [148, 1015, 333, 5]; HEAD [148, 1015, 334, 5] | OK: 147, PENDENTE: 1 |
| 2635 | `tests/economic_benchmark` | CONFERE | anunciado arq/linhas/aux/test [11, 145, 57, 0]; HEAD [11, 145, 57, 0] | OK: 10, PENDENTE: 1 |
| 2636 | `tests/fixtures` | DIVERGE | anunciado arq/linhas/aux/test [2, 19, 4, 3]; HEAD [2, 19, 6, 3] | OK: 2 |
| 2637 | `tests/harness` | DIVERGE | anunciado arq/linhas/aux/test [25, 5221, 2316, 0]; HEAD [25, 5208, 2309, 0]; árvore [25, 5243, 2316, 0] | OK: 3, OK provavel: 5, PENDENTE: 17 |
| 2638 | `tests/llm_gen_eval` | CONFERE | anunciado arq/linhas/aux/test [6, 19, 6, 0]; HEAD [6, 19, 6, 0] | OK: 6 |
| 2639 | `tests/memory` | CONFERE | anunciado arq/linhas/aux/test [48, 614, 198, 0]; HEAD [48, 614, 198, 0] | OK: 48 |
| 2640 | `tests/registry` | CONFERE | anunciado arq/linhas/aux/test [6, 191, 107, 2]; HEAD [6, 191, 107, 2] | OK: 2, PENDENTE: 4 |
| 2641 | TOTAL | DIVERGE parcial | anunciado 409/11.467/4.046/138; HEAD 409/11454/4049/138; árvore 409/11492/4056/138. O total de `test_*` (138) contradiz o título da Parte XI (688) | — |

Diferenças pequenas em "funções auxiliares" (bootstrap 186→188, compiler/stage1 312→317, conformance 333→334, fixtures 4→6) vêm do mesmo defeito do gerador (modificadores/assinaturas multilinha). `tests/cli` e `tests/harness` batem com a árvore num estado intermediário (arquivos alterados pelo porte).

### 5.2 Seção 11.2 — os 409 arquivos de teste (linhas 2645–2655)

Todos os 409 caminhos existem e estão em HEAD. Os arquivos não têm "aprovado" individual no catálogo; o único registro de execução no repositório é `build/windows-native/seed_test.log` (seed, `make -C bootstrap/lume0 test` no WSL: 410 passed, 0 failed) e `seed_asan.log` (170 passed, 3 skipped), que cobrem os 99 arquivos de `bootstrap/lume0`. Para os demais, não há log de resultado no repositório.

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 2645 | `bootstrap/lume0/tests/gc/interpolation.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 27 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/gc/registry_roots.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 322 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/lexer/bad_dedent.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/lexer/bad_escape.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 2 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/lexer/bad_string.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 2 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/lexer/bad_tab.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/lexer/indent.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 10 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/lexer/literals.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 10 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/parser/bad_block.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 4 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/parser/bad_fn.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/parser/bad_match_arrow.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 4 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/parser/bad_record.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/parser/ok_expr.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 16 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_arity_few.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_arity_few_three_params.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_arity_few_zero_args.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_arity_in_expr.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_arity_many.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_arity_many_three_params.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_arity_many_zero_params.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_arity_nested_call.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_assign_const.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_assign_immutable.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_assign_immutable_compound.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_assign_immutable_in_if.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_assign_immutable_in_loop.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_assign_immutable_minus_eq.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_break_after_loop.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_break_in_fn_if_no_loop.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_break_outside_loop.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 2 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_continue_in_fn_no_loop.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 4 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_continue_outside_loop.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 2 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_dead_after_return.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_dup_fn.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_dup_fn_diff_sig.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_dup_fn_three.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_dup_param.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_dup_param_second_fn.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_dup_param_three.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_dup_record_key.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 4 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_return_outside_fn.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 2 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_return_outside_fn_expr.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_type_bool_to_int.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_type_f64_from_str.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_type_int_from_float.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_type_int_to_bool.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_type_mismatch.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_type_str_from_bool.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_type_str_to_int.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_undefined_call.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_undefined_in_call_arg.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_undefined_in_closure.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 4 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_undefined_in_if_cond.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_undefined_in_loop_body.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_undefined_in_match_arm.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_undefined_nested_expr.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_undefined_var.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_unreachable_arm.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_unreachable_arm_binding.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_unreachable_arm_many_after.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 8 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_unreachable_arm_mid.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/bad_unreachable_arm_second_wild.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_arity_exact.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 8 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_closure_typed.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_closures.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_comprehension.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 4 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_const_use.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_control_flow.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 9 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_defer_and_contracts.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 8 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_enum_constructors.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 16 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_error_propagation.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 13 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_field_access.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 10 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_for_loops.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 9 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_forward_reference.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_impl_traits.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 19 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_loop_keyword.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_map_set_literals.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_match_guard.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_match_guards_multi.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_mutable.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_nested_loops_break.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 10 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_optional_chain.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_pipeline.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_record_literal.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 3 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_recursion_and_mutual.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 14 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_return_in_branch.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 4 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_return_in_nested.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 5 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_scoped.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_shadow_param.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 4 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_shadowing.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_string_interpolation.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_types.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_types_more.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 9 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_ufcs_methods.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 7 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_use_module.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_use_selective.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 6 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_var_assign_in_branches.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 9 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/resolve/ok_while_loop_break.lume` | EXISTE | entrada do seed (consumida por `bootstrap/lume0/tests/run.sh`), 9 linhas | OK como entrada; PENDENTE runner: `tests/run.sh` (sh + make + cc) ou `run_native.src` (executa ELF) |
| 2645 | `bootstrap/lume0/tests/run_native.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 151 linhas | PENDENTE: gera/executa ELF |
| 2646 | `compiler/stage1/ai_authoring_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 42 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/annot_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 23 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/arena_ok.src` | EXISTE | 8 `test_*`, 103 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/arg_infer_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/bytes_ok.src` | EXISTE | 10 `test_*`, 32 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/capsule_ok.src` | EXISTE | 3 `test_*`, 10 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/certificate_hash_producer_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/certificate_hash_verifier_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/compiler_contracts_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 31 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/compiler_effects_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 23 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/compiler_perceus_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 71 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/concurrency_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 28 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/contracts_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 31 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/core_features_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 104 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/data_d4_ok.src` | EXISTE | 4 `test_*`, 34 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/data_runtime_seed_ok.lume` | EXISTE | sem `test_*` (fixture/gate/entrada), 18 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/ed25519_rfc8032_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 52 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/effects_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 72 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/elif_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/evolve_evidence_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 21 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/field_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/field_type_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/fs_hex_file_ok.src` | EXISTE | 13 `test_*`, 33 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/fs_mkdir_ok.src` | EXISTE | 3 `test_*`, 5 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/fs_ok.src` | EXISTE | 9 `test_*`, 28 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/fs_path_exists_ok.src` | EXISTE | 3 `test_*`, 5 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/fs_read_byte_ok.src` | EXISTE | 7 `test_*`, 15 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/fs_read_dir_ok.src` | EXISTE | 3 `test_*`, 11 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/fs_remove_ok.src` | EXISTE | 4 `test_*`, 11 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/fs_sha256_file_producer_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/fs_sha256_file_verifier_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 19 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/gc_ok.src` | EXISTE | 11 `test_*`, 44 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/generics_container_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 39 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/generics_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 12 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/hm_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/infer_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 8 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/intent_hash_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/intent_oracle_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 32 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/let_infer_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/m1_prover_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 105 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/nom_infer_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/os_argv_ok.src` | EXISTE | 4 `test_*`, 4 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/os_run_ok.src` | EXISTE | 13 `test_*`, 25 linhas | PENDENTE parcial: os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2646 | `compiler/stage1/own_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 73 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/p35_ok.src` | EXISTE | 6 `test_*`, 22 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/perceus_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 37 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/phase4_ai_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 100 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/phase5_sys_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 29 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/process_ok.src` | EXISTE | 6 `test_*`, 26 linhas | OK provavel (os_run so de ferramentas lume) |
| 2646 | `compiler/stage1/qflia_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 20 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/track_i_intent_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 33 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/track_l_domains_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 124 linhas | PENDENTE: sockets/epoll (epoll_add_in@async_rt.src, epoll_create_fd@async_rt.src, epoll_wait_one@async_rt.src, net_close@async_rt.src, net_close@); os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2646 | `compiler/stage1/track_o_os_ok.src` | EXISTE | 6 `test_*`, 29 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/types_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2646 | `compiler/stage1/win64_gui_and_interp_regression_ok.src` | EXISTE | 8 `test_*`, 62 linhas | OK (sem dependencia de SO detectada) |
| 2647 | `tests/capstones/gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 37 linhas | PENDENTE: programas externos: env, mkdir, qemu-system-x86_64, rm; os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2647 | `tests/capstones/rtc_assertions.src` | EXISTE | 7 `test_*`, 63 linhas | OK (sem dependencia de SO detectada) |
| 2647 | `tests/capstones/saas_assertions.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 48 linhas | PENDENTE: sockets/epoll (net_close, net_recv_str, net_send_str, net_shutdown_write, net_tcp_connect) |
| 2648 | `tests/cli/arena_effect_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK provavel (os_run so de ferramentas lume) |
| 2648 | `tests/cli/driver_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1155 linhas; modificado na árvore | PENDENTE: programas externos: cli_parity_ghost_tool, objdump, readelf, w14_no_such_lcaas; gera/executa ELF; os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2648 | `tests/cli/evolve_driver_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 41 linhas; modificado na árvore | OK provavel (os_run so de ferramentas lume) |
| 2648 | `tests/cli/incremental_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 69 linhas; modificado na árvore | OK provavel (os_run so de ferramentas lume) |
| 2648 | `tests/cli/interactive_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 25 linhas | OK provavel (os_run so de ferramentas lume) |
| 2648 | `tests/cli/make_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 23 linhas | OK provavel (os_run so de ferramentas lume) |
| 2649 | `tests/conformance/stage1/fail_closed/C0012_shift_count_literal.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/C1001_comptime_add_overflow.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/C1001_comptime_min_div.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/C1001_comptime_mul_overflow.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/D0002_duplicate_fn.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/D0003_duplicate_type.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/D0004_duplicate_field.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/I0004_ffi_seven_params.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/L0001_unterminated_string.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/L0002_nul_escape.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/L0002_unknown_escape.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/L0003_digit_glued_to_name.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/L0003_int_literal.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/L0003_radix_underscore.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/L0003_trailing_underscore.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/L0003_uppercase_radix_prefix.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/L0004_unterminated_block_comment.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_bad_hole.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_chained_comparison.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_chained_equality.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_decimal_pattern.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_dup_lambda_param.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_dup_let_pattern.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_dup_param.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_dup_pattern.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_dup_tuple.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_if_missing_else.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_inline_nested_match.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_let_missing_eq.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_let_missing_in.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_missing_pattern.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_negdec_later_arm.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_overflow_attribute.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_stray_paren.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_unclosed_list.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0002_unclosed_paren_pattern.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0003_two_functions.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0003_two_statements.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0004_attribute_dropped.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0004_misspelt_no_alloc.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/P0004_unknown_attribute.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0200_grad_needs_function.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0200_intrinsic_no_such_form.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0200_module_not_imported.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0200_vmap_needs_function.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0201_runtime_entry.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0201_runtime_prefix.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0202_builtin_args.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0202_cons_one_field.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0202_cons_pattern_one_field.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0202_nil_with_field.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0202_too_few_args.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0202_too_many_args.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0203_internal_routine.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 1 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0204_explicit_type_argument.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0204_index_function.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0205_local_named_like_builtin.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/R0205_param_named_like_intrinsic.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/T0601_int_condition.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/T0602_bool_returned_as_int.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/T0603_bool_argument_for_int.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/T0604_decimal_plus_int.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/T0605_let_annotation.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/T0606_branch_types.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/T0607_int_clause.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/fail_closed/T1002_match_missing_variant.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/alias_before_match_stays_correct.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/alias_in_other_branch_reuse_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/alias_reuse_let.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/alias_reuse_record.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/borrow_escapes_via_ctor.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/borrow_escapes_via_match.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/borrow_escapes_via_record.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/branch_moves_both_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/comptime_record_eq.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/contained_tail_reuse.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/fn_value_own_keeps_caller.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/fresh_result_of_param_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/index_after_move.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/move_alias_of_borrowed_param.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/move_field_alias_of_param.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/move_in_shard_body.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/move_out_of_borrowed_pattern.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/move_part_then_use_whole.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 13 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/move_siblings_of_pattern_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/move_while_borrowed.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/mut_and_shared_live.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/mut_param_aliased_by_shared_arg.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/names_builtin_clash.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/names_forward_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/names_undefined_call.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/names_undefined_in_arm.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/names_undefined_in_lambda.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/names_undefined_var.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/nll_mut_then_read_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/nll_shared_then_move_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/opaque_alias_must_stay_correct.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/pattern_shadowing_moved_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/pub_borrow_in_record_no_from.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/read_while_mut_borrowed_same_call.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_a1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 14 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_a1b.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 15 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_a1c.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 15 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_a2.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 19 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_a3.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_a4.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_a5.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_a6.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 16 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_a7.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_d2.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_d3.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_d5.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_f1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_f2.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_f3.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 12 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_f4.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_s1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 12 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_s2.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 13 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_s3.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_s4.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/redteam_s6.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/resource_consumed_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/resource_consumed_on_one_path.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/resource_deferred_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/resource_dropped_silently.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/resource_from_call_dropped.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/resource_returned_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/shadow_after_move_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/shared_structure_must_stay_correct.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 15 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/two_mut_live.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/two_shared_loans_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/types_base_alias.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/types_exhaustive_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/types_tag_in_two_enums.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/use_after_move_in_ctor.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/ownership/valid_unique_reuse.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/semantic_ergonomics_native_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 65 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/semantic_ergonomics_ok.src` | EXISTE | 5 `test_*`, 112 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/semantic_mesh/assertions.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 116 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/semantic_mesh/gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 21 linhas | PENDENTE: programas externos: env, mkdir, rm |
| 2649 | `tests/conformance/stage1/surfaces/let_chains.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/surfaces/multiline_match.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/surfaces/mutual_recursion.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/surfaces/nested_patterns.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/surfaces/not_and_compare.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/surfaces/records_fields.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/surfaces/string_ops.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2649 | `tests/conformance/stage1/surfaces/strings_escapes.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/assertions.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/assertions_lib.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 103 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/run.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 21 linhas | PENDENTE: programas externos: mkdir, rm |
| 2650 | `tests/economic_benchmark/tasks/clamp_nonnegative/attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/tasks/deposit_fee_spec_change/initial/attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/tasks/deposit_fee_spec_change/revised/attempt2.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/tasks/negative_compile_failure/attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/tasks/negative_execution_failure/attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/tasks/negative_proof_failure/attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/tasks/safe_deposit_repair/attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2650 | `tests/economic_benchmark/tasks/safe_deposit_repair/attempt2.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2651 | `tests/fixtures/c_adapter/buffer_math.src` | EXISTE | 3 `test_*`, 13 linhas | OK (sem dependencia de SO detectada) |
| 2651 | `tests/fixtures/c_adapter/caller_tail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK (sem dependencia de SO detectada) |
| 2652 | `tests/harness/c_adapter_assertions.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 97 linhas | OK (sem dependencia de SO detectada) |
| 2652 | `tests/harness/c_adapter_fixtures.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2652 | `tests/harness/c_adapter_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 34 linhas; modificado na árvore | OK provavel (os_run so de ferramentas lume, /bin/* emulado por hostio) |
| 2652 | `tests/harness/cert_source_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 143 linhas; modificado na árvore | OK provavel (os_run so de ferramentas lume) |
| 2652 | `tests/harness/claude_audit_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 182 linhas; modificado na árvore | PENDENTE: programas externos: cc, clang, sh; gera/executa ELF |
| 2652 | `tests/harness/concurrency_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 312 linhas; modificado na árvore | PENDENTE: programas externos: sh; gera/executa ELF |
| 2652 | `tests/harness/crypto_tls_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 379 linhas; modificado na árvore | OK provavel (os_run so de ferramentas lume) |
| 2652 | `tests/harness/dwarf_cache_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 154 linhas; modificado na árvore | PENDENTE: programas externos: addr2line, nm, readelf; gera/executa ELF |
| 2652 | `tests/harness/gc_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas; modificado na árvore | OK provavel (os_run so de ferramentas lume, /bin/* emulado por hostio) |
| 2652 | `tests/harness/lasm_fixtures.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2652 | `tests/harness/lasm_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 304 linhas; modificado na árvore | PENDENTE: programas externos: as, objcopy, objdump; gera/executa ELF |
| 2652 | `tests/harness/lcaas_scale_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 222 linhas; modificado na árvore | PENDENTE: programas externos: time |
| 2652 | `tests/harness/multi_arch_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 178 linhas; modificado na árvore | PENDENTE: programas externos: aarch64-linux-gnu-as, clang, qemu-aarch64, qemu-riscv64, qemu-system-riscv32, readelf, riscv64-linux-gnu-as, sh; gera/executa ELF |
| 2652 | `tests/harness/ownership_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 36 linhas; modificado na árvore | PENDENTE: gera/executa ELF |
| 2652 | `tests/harness/prover_fuzz.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 299 linhas; modificado na árvore | PENDENTE: gera/executa ELF |
| 2652 | `tests/harness/prover_fuzz_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 18 linhas; modificado na árvore | PENDENTE: gera/executa ELF |
| 2652 | `tests/harness/realtime_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 292 linhas; modificado na árvore | PENDENTE: gera/executa ELF |
| 2652 | `tests/harness/runtime_sync_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 39 linhas; modificado na árvore | OK provavel (os_run so de ferramentas lume, /bin/* emulado por hostio) |
| 2652 | `tests/harness/safetensors_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 139 linhas; modificado na árvore | PENDENTE: programas externos: python3, sh, sha256sum, tail; gera/executa ELF |
| 2652 | `tests/harness/safety_envelope_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 865 linhas; modificado na árvore | PENDENTE: programas externos: lsafety_envelope.bundled.src, sh; gera/executa ELF |
| 2652 | `tests/harness/smt_cert_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 274 linhas; modificado na árvore | PENDENTE: programas externos: ln, lsmt.bundled.src, sh, smt_cert_gate.bundled.src, z3 |
| 2652 | `tests/harness/soak_battle_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 308 linhas; modificado na árvore | PENDENTE: programas externos: date, id, sh, sha256sum; gera/executa ELF; os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| 2652 | `tests/harness/synergy_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 334 linhas; modificado na árvore | PENDENTE: programas externos: addr2line, nm, qemu-aarch64, qemu-riscv64, qemu-system-riscv32, readelf, sh; gera/executa ELF |
| 2652 | `tests/harness/tv_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 343 linhas; modificado na árvore | PENDENTE: programas externos: sha256sum; gera/executa ELF |
| 2652 | `tests/harness/tv_rt_gate.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 236 linhas; modificado na árvore | PENDENTE: gera/executa ELF |
| 2653 | `tests/llm_gen_eval/tasks/01_clamp_nonneg_attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2653 | `tests/llm_gen_eval/tasks/02_safe_deposit_attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2653 | `tests/llm_gen_eval/tasks/03_max2_law_attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2653 | `tests/llm_gen_eval/tasks/04_add_fee_attempt1.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2653 | `tests/llm_gen_eval/tasks/04_add_fee_attempt2.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2653 | `tests/llm_gen_eval/tasks/05_compiles_but_unproven_neg.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/arena_budget_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/arena_busy_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 10 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/arena_cap_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/arena_nopin_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 8 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/at_type_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/atomic_compactor_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 88 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/bool_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 19 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/bound_pack_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/chr_range_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/closure_arity_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/closures_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 35 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/comptime_limits_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 12 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/count_record_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/dir_race_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/div_zero_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/dyn_type_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 12 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/fn_values_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 14 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/freestanding_values_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/gc_cap_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 9 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/gc_frag_cap_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 9 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/gc_stress_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 13 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/handler_lowering_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 21 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/heap_cap_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 8 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/heap_env_bad_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/hof_only_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/index_type_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/int_wrap_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 7 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/list_index_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/list_index_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 18 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/list_index_type_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/pack_corrupt_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/pattern_int_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 17 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/rec_update_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/rec_update_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 14 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/secret_arena_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/secret_pack_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 5 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/shadow_call_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 12 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/slice_type_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/slicen_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 6 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/stack_overflow_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/string_index_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/string_index_neg_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 3 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/toint_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 15 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/toint_overflow_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 4 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/type_error_fail.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 2 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/value_edges_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 75 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/value_matrix_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 85 linhas | OK (sem dependencia de SO detectada) |
| 2654 | `tests/memory/values_ok.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 9 linhas | OK (sem dependencia de SO detectada) |
| 2655 | `tests/registry/acceptance_json.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 88 linhas | OK (sem dependencia de SO detectada) |
| 2655 | `tests/registry/gate.src` | EXISTE | 2 `test_*`, 21 linhas | PENDENTE: programas externos: cp, mkdir, mv, rm |
| 2655 | `tests/registry/gate_adversarial.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 28 linhas | PENDENTE: programas externos: cp, mkdir, mv, rm |
| 2655 | `tests/registry/gate_manifest.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 25 linhas | OK (sem dependencia de SO detectada) |
| 2655 | `tests/registry/gate_process.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 18 linhas | PENDENTE: programas externos: cp, mkdir, mv, rm |
| 2655 | `tests/registry/gate_publish.src` | EXISTE | sem `test_*` (fixture/gate/entrada), 11 linhas | PENDENTE: programas externos: cp, mkdir, mv, rm |

### 5.3 Seção 11.3 — as 688 funções `test_*` (linhas 2657–2771)

Cada linha: arquivo existe? a quantidade e cada nome listado existem? Windows por teste (grafo de chamadas estático). Soma da coluna = 688, nomes listados = 688; 110 arquivos; nenhum arquivo com `test_*` em HEAD ficou de fora. Fora do catálogo: `compiler/stage1/hostio.src` (11 `test_hio_*`, só na árvore).

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 2661 | `acceptance/matrix_assertions.src` | CONFERE | anunciado 14; HEAD 14; árvore 14 | OK (estático) |
| 2662 | `compiler/stage1/actor.src` | CONFERE | anunciado 5; HEAD 5; árvore 5 | OK (estático) |
| 2663 | `compiler/stage1/ai_runtime.src` | CONFERE | anunciado 6; HEAD 6; árvore 6 | OK (estático) |
| 2664 | `compiler/stage1/async_rt.src` | CONFERE | anunciado 6; HEAD 6; árvore 6 | PENDENTE em 1/6: test_async_multiworker_os (sockets/epoll+os_fork/pipe(parcial)) |
| 2665 | `compiler/stage1/bytes.src` | CONFERE | anunciado 20; HEAD 20; árvore 20 | OK (estático) |
| 2666 | `compiler/stage1/concurrency.src` | CONFERE | anunciado 5; HEAD 5; árvore 5 | OK (estático) |
| 2667 | `compiler/stage1/db.src` | CONFERE | anunciado 9; HEAD 9; árvore 9 | PENDENTE em 1/9: test_durable_acid_wal_crash_recovery (os_fork/pipe(parcial)) |
| 2668 | `compiler/stage1/decimal.src` | CONFERE | anunciado 16; HEAD 16; árvore 16 | OK (estático) |
| 2669 | `compiler/stage1/evolve_demo.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2670 | `compiler/stage1/fs.src` | CONFERE | anunciado 11; HEAD 11; árvore 11 | OK (estático) |
| 2671 | `compiler/stage1/fs_sha256_file.src` | CONFERE | anunciado 2; HEAD 2; árvore 2 | OK (estático) |
| 2672 | `compiler/stage1/gfx.src` | CONFERE | anunciado 11; HEAD 11; árvore 11 | OK (estático) |
| 2673 | `compiler/stage1/gui.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | PENDENTE em 1/7: test_x11_native_window_session_and_wasm_dom_reconciler (sockets/epoll+os_fork/pipe(parcial)) |
| 2674 | `compiler/stage1/interop.src` | CONFERE | anunciado 6; HEAD 6; árvore 6 | OK (estático) |
| 2675 | `compiler/stage1/lchameleon.src` | CONFERE | anunciado 19; HEAD 19; árvore 19 | PENDENTE em 1/19: test_wave9_real_vex_simd_kernel_io_uring_ast_horner_and_c_header_parser (sockets/epoll+io_uring) |
| 2676 | `compiler/stage1/lconcurrency.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | PENDENTE em 1/4: test_parallel_multi_worker_dispatch_linux (programas: sh) |
| 2677 | `compiler/stage1/levidence.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2678 | `compiler/stage1/levolve.src` | DIVERGE com HEAD (confere com a árvore) | anunciado 2; HEAD 1; árvore 2; ausentes em HEAD: test_ev_unsafe_path_windows_forms | OK (estático) |
| 2679 | `compiler/stage1/lgenesis.src` | CONFERE | anunciado 2; HEAD 2; árvore 2 | OK (estático) |
| 2680 | `compiler/stage1/los.src` | CONFERE | anunciado 8; HEAD 8; árvore 8 | OK (estático) |
| 2681 | `compiler/stage1/lregistry.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2682 | `compiler/stage1/lregistry_cid_lib.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2683 | `compiler/stage1/lsentience.src` | CONFERE | anunciado 35; HEAD 35; árvore 35 | PENDENTE em 4/35: test_wave10_reverse_engineer_elf_and_pe (programas: 7z,sh); test_wave10_egm_elephant_goldfish_and_drift (programas: 7z); test_wave10_ncm_next_concept_coarse_to_fine (programas: 7z); test_wave10_opentpu_systolic_isa_and_ksmoothing (programas: 7z) |
| 2684 | `compiler/stage1/lstd.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2685 | `compiler/stage1/lume_continuum_nexus_engine.src` | CONFERE | anunciado 5; HEAD 5; árvore 5 | OK (estático) |
| 2686 | `compiler/stage1/lume_crypto_blockchain_engine.src` | CONFERE | anunciado 9; HEAD 9; árvore 9 | OK (estático) |
| 2687 | `compiler/stage1/lume_egm_engine.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | PENDENTE em 1/4: test_egm_bidirectional_drift_with_reversa_sdd (programas: 7z) |
| 2688 | `compiler/stage1/lume_llm_core.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2689 | `compiler/stage1/lume_ncm_engine.src` | CONFERE | anunciado 6; HEAD 6; árvore 6 | PENDENTE em 1/6: test_ncm_full_pipeline_bridge_egm_and_reversa (programas: 7z) |
| 2690 | `compiler/stage1/lume_opentpu_engine.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | PENDENTE em 1/4: test_otpu_full_pipeline_scoreboard_and_ncm_bridge (programas: 7z) |
| 2691 | `compiler/stage1/lume_pingora_proxy_engine.src` | CONFERE | anunciado 5; HEAD 5; árvore 5 | OK (estático) |
| 2692 | `compiler/stage1/lume_quantum_nexus_engine.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2693 | `compiler/stage1/lume_reversa_engine.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | PENDENTE em 1/4: test_reversa_full_pipeline_on_source_and_immutability (programas: 7z) |
| 2694 | `compiler/stage1/map.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2695 | `compiler/stage1/media.src` | CONFERE | anunciado 5; HEAD 5; árvore 5 | OK (estático) |
| 2696 | `compiler/stage1/net.src` | CONFERE | anunciado 16; HEAD 16; árvore 16 | PENDENTE em 1/16: test_tls13_rfc8446_wire_records_and_loopback_handshake (sockets/epoll+os_fork/pipe(parcial)) |
| 2697 | `compiler/stage1/nn.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2698 | `compiler/stage1/ownership.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2699 | `compiler/stage1/process.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2700 | `compiler/stage1/sample_test.src` | CONFERE (contagem), mas 1 não é teste executável | anunciado 4; HEAD 4; árvore 4; `test_helper(x)` tem parâmetro: `lume test` roda 3, não 4 | OK (estático) |
| 2701 | `compiler/stage1/tensor.src` | CONFERE | anunciado 6; HEAD 6; árvore 6 | OK (estático) |
| 2702 | `compiler/stage1/vec.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | OK (estático) |
| 2703 | `docs/install.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2704 | `skills/lume/examples/verified_showcase.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2705 | `stdlib/crypto.lume` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2706 | `stdlib/std.lume` | CONFERE | anunciado 21; HEAD 21; árvore 21 | OK (estático) |
| 2707 | `compiler/stage1/larm64.src` | CONFERE | anunciado 2; HEAD 2; árvore 2 | OK (estático) |
| 2708 | `compiler/stage1/lcert.src` | CONFERE | anunciado 17; HEAD 17; árvore 17 | OK (estático) |
| 2709 | `compiler/stage1/lcrypto_tls.src` | CONFERE | anunciado 21; HEAD 21; árvore 21 | OK (estático) |
| 2710 | `compiler/stage1/linteractive.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2711 | `compiler/stage1/lkir.src` | CONFERE | anunciado 2; HEAD 2; árvore 2 | OK (estático) |
| 2712 | `compiler/stage1/lmanual.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | OK (estático) |
| 2713 | `compiler/stage1/lneural_cartridge.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2714 | `compiler/stage1/lproof_cache.src` | CONFERE | anunciado 5; HEAD 5; árvore 5 | OK (estático) |
| 2715 | `compiler/stage1/lprotect.src` | CONFERE | anunciado 2; HEAD 2; árvore 2 | OK (estático) |
| 2716 | `compiler/stage1/lqualify.src` | CONFERE | anunciado 8; HEAD 8; árvore 8 | OK (estático) |
| 2717 | `compiler/stage1/lriscv.src` | CONFERE | anunciado 2; HEAD 2; árvore 2 | OK (estático) |
| 2718 | `compiler/stage1/lsmt.src` | CONFERE | anunciado 9; HEAD 9; árvore 9 | OK (estático) |
| 2719 | `compiler/stage1/ltarget.src` | CONFERE | anunciado 15; HEAD 15; árvore 15 | OK (estático) |
| 2720 | `compiler/stage1/ltv.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | OK (estático) |
| 2721 | `compiler/stage1/ltv_rt.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2722 | `compiler/stage1/lume_driver.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | PENDENTE em 1/1: test_ld_wave10_and_ui_layout_dispatch (programas: 7z,curl,sh,sha256sum) |
| 2723 | `compiler/stage1/lx509.src` | CONFERE | anunciado 5; HEAD 5; árvore 5 | OK (estático) |
| 2724 | `compiler/stage1/protect.src` | CONFERE | anunciado 5; HEAD 5; árvore 5 | OK (estático) |
| 2725 | `editors/vscode-lume/lsp_bridge.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2726 | `examples/apps/agent/main.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2727 | `examples/apps/brasil_public_id/main.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2728 | `examples/apps/dfe_pix_bacen/main.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2729 | `examples/apps/inventory/main.src` | CONFERE | anunciado 10; HEAD 10; árvore 10 | OK (estático) |
| 2730 | `examples/apps/job_server/main.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2731 | `examples/apps/lume_os/main.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2732 | `examples/apps/mnist/main.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2733 | `examples/apps/notepad_plus_lume/notepad_plus_core.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | OK (estático) |
| 2734 | `examples/apps/omniroute_guard/main.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2735 | `examples/apps/pix_fraud_trace/main.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2736 | `examples/apps/sentry_uav_guard/main.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2737 | `examples/apps/sovereign_llm_router/main.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2738 | `examples/apps/supply_chain_demo/ledger_guard.src` | CONFERE | anunciado 2; HEAD 2; árvore 2 | OK (estático) |
| 2739 | `examples/apps/verified_accounting/main.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2740 | `examples/apps/zero_breach_forensics/main.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2741 | `examples/interop/sidecar/host_lume.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2742 | `scripts/amalgamate.src` | CONFERE | anunciado 1; HEAD 1; árvore 1 | OK (estático) |
| 2743 | `scripts/bootstrap.src` | CONFERE | anunciado 10; HEAD 10; árvore 10 | OK (estático) |
| 2744 | `scripts/docs_ci.src` | CONFERE | anunciado 18; HEAD 18; árvore 18 | OK (estático) |
| 2745 | `scripts/install.src` | CONFERE | anunciado 5; HEAD 5; árvore 5 | PENDENTE em 1/5: test_manifest_line_binds_exact_file_bytes (programas: sha256sum) |
| 2746 | `scripts/linguist_grammar.src` | CONFERE | anunciado 8; HEAD 8; árvore 8 | OK (estático) |
| 2747 | `scripts/llm_gen_eval.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | OK (estático) |
| 2748 | `scripts/zero_c.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | OK (estático) |
| 2749 | `compiler/stage1/arena_ok.src` | CONFERE | anunciado 8; HEAD 8; árvore 8 | OK (estático) |
| 2750 | `compiler/stage1/bytes_ok.src` | CONFERE | anunciado 10; HEAD 10; árvore 10 | OK (estático) |
| 2751 | `compiler/stage1/capsule_ok.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2752 | `compiler/stage1/data_d4_ok.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | OK (estático) |
| 2753 | `compiler/stage1/fs_hex_file_ok.src` | CONFERE | anunciado 13; HEAD 13; árvore 13 | OK (estático) |
| 2754 | `compiler/stage1/fs_mkdir_ok.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2755 | `compiler/stage1/fs_ok.src` | CONFERE | anunciado 9; HEAD 9; árvore 9 | OK (estático) |
| 2756 | `compiler/stage1/fs_path_exists_ok.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2757 | `compiler/stage1/fs_read_byte_ok.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2758 | `compiler/stage1/fs_read_dir_ok.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2759 | `compiler/stage1/fs_remove_ok.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | OK (estático) |
| 2760 | `compiler/stage1/gc_ok.src` | CONFERE | anunciado 11; HEAD 11; árvore 11 | OK (estático) |
| 2761 | `compiler/stage1/os_argv_ok.src` | CONFERE | anunciado 4; HEAD 4; árvore 4 | OK (estático) |
| 2762 | `compiler/stage1/os_run_ok.src` | CONFERE | anunciado 13; HEAD 13; árvore 13 | PENDENTE em 3/13: test_os_exec_replaces_child_process (os_fork/pipe(parcial)); test_os_exec_missing_tool_returns_error (os_fork/pipe(parcial)); test_os_kill_and_waitpid_status_report_sigterm (os_fork/pipe(parcial)) |
| 2763 | `compiler/stage1/p35_ok.src` | CONFERE | anunciado 6; HEAD 6; árvore 6 | OK (estático) |
| 2764 | `compiler/stage1/process_ok.src` | CONFERE | anunciado 6; HEAD 6; árvore 6 | OK (estático) |
| 2765 | `compiler/stage1/track_o_os_ok.src` | CONFERE | anunciado 6; HEAD 6; árvore 6 | OK (estático) |
| 2766 | `compiler/stage1/win64_gui_and_interp_regression_ok.src` | CONFERE | anunciado 8; HEAD 8; árvore 8 | OK (estático) |
| 2767 | `tests/capstones/rtc_assertions.src` | CONFERE | anunciado 7; HEAD 7; árvore 7 | OK (estático) |
| 2768 | `tests/conformance/stage1/semantic_ergonomics_ok.src` | CONFERE (contagem), mas 1 não é teste executável | anunciado 5; HEAD 5; árvore 5; `test_match_in_call(x)` tem parâmetro, não é executado | OK (estático) |
| 2769 | `tests/fixtures/c_adapter/buffer_math.src` | CONFERE | anunciado 3; HEAD 3; árvore 3 | OK (estático) |
| 2770 | `tests/registry/gate.src` | CONFERE | anunciado 2; HEAD 2; árvore 2 | OK (estático) |
| 2771 | TOTAL 688 "100% executáveis e auditadas" | FALSO | 688 = 687 de HEAD + 1 da árvore; 2 deles têm parâmetro e não são executados (686 executáveis no retrato do catálogo); a amostra da seção 6 tem falhas reais; a árvore atual tem 699 (697 executáveis) | ver seção 7 |

## 6. Execução por amostragem (5 arquivos pequenos)

Rodados em 2026-11-13 a partir da raiz do repositório, de duas formas: `lume test` no PowerShell (que resolve para `C:\Users\Ricardo.Bueno\.lume\bin\lume.cmd` → `wsl -d Ubuntu ... /root/.lume/bin/lume-win` → toolchain **Linux** no WSL), e o binário nativo do porte `build\windows-native\inst\bin\lume.exe test` (PE32+, sem WSL).

| arquivo | catálogo | WSL (Linux) | Windows nativo (`inst/bin/lume.exe`) | observação |
|---|---|---|---|---|
| `compiler/stage1/vec.src` | 4 testes | 4 passed, 0 failed | 4 passed, 0 failed | confere |
| `compiler/stage1/sample_test.src` | 4 testes | 3 passed, 0 failed | 3 passed, 0 failed | `test_helper(x)` tem parâmetro e não é teste: o catálogo conta 1 a mais |
| `examples/apps/supply_chain_demo/ledger_guard.src` | 2 testes | 2 passed, 0 failed | 2 passed, 0 failed | confere |
| `compiler/stage1/fs_path_exists_ok.src` | 3 testes | 2 passed, **1 FAIL** (`test_fs_path_exists_present`) | 2 passed, **1 FAIL** (mesmo teste) | o teste usa o caminho relativo `../../compiler/stage1/fs_path_exists_ok.src`, que só existe se o diretório corrente estiver dois níveis abaixo da raiz; rodado da raiz, falha nos dois sistemas. Não é defeito do porte |
| `tests/registry/gate.src` | 2 testes | 4 passed, **1 FAIL** (`test_replace_once_does_not_duplicate_text`) | **não compila**: `lmod: module 'lregistry_cid_lib' not found (native bundling cannot resolve module: lregistry_cid_lib)` | no WSL roda 5 testes (3 vêm de `use lregistry_cid_lib`) e 1 falha. No nativo, a resolução de módulos fora do diretório do arquivo ainda não funciona: PENDENTE no Windows |

Conclusão: o selo "aprovado"/"100% executáveis" da Parte XI não tem evidência no repositório (não há log de execução dos 688 testes) e é desmentido pela amostra: 2 de 5 arquivos têm teste falhando, e 1 não roda no Windows nativo. Os únicos logs de resultado presentes são `build/windows-native/seed_test.log` (seed, 410 passed) e `seed_asan.log` (170 passed, 3 skipped), ambos do WSL.

## 7. Itens falsos ou divergentes

1. **"266 leis" (linhas 2077, 2080, 2082):** HEAD tem 268 e a árvore, 269. Faltam `omniroute_confidential_sovereignty_law` e `omniroute_valid_tier_bounds_law` (`examples/apps/omniroute_guard/main.src:62,73`, assinatura multilinha) e `hio_status_is_exit_code_law` (`compiler/stage1/hostio.src`, só na árvore). As 266 listadas existem todas, com parâmetros e enunciado idênticos.
2. **"provados estaticamente pelo lumec/lcaas/lcert" (linha 2080):** não verificado; o catálogo não aponta certificado por lei.
3. **"18.857 funções" (linhas 2077, 2080):** com o critério `fn` (com modificadores) menos `test_*`, HEAD dá 18.856 e a árvore, 18.991. Contando só `^fn `, são 19.291 em HEAD. Nenhum dos últimos 40 commits dá exatamente 18.857.
4. **"688 fn test_* distribuídas em 694 arquivos" (linha 2080):** os `test_*` estão em 110 arquivos; 694 é o total de `.src`/`.lume`. 688 = 687 (HEAD) + 1 do porte (`levolve.src`). Dois deles (`test_helper(x)`, `test_match_in_call(x)`) têm parâmetro e não são executados pelo `lume test`. A árvore atual tem 699: `hostio.src` passou de 9 para 11 testes durante a auditoria (o briefing citava 9).
5. **"git ls-files" como fonte (linha 2080):** os números não são de HEAD puro. `levolve.src` (2 testes), `lasm.src` (698 linhas/342 fn) e `runtime_core.lume` (160/41) só batem com a árvore de trabalho; `07_driver.src` (394/132) e `lume_driver.src` (1.246/406) não batem nem com HEAD nem com a árvore atual.
6. **10.2, títulos com vários arquivos (linhas 2369, 2381, 2401, 2409, 2461):** os números são só de um dos arquivos citados. Ex.: a linha 2409 anuncia 40 fn/8 leis/4 testes para "process, concurrency, actor, async_rt, lconcurrency"; isso é só `lconcurrency.src`; os 5 juntos têm 119 fn, 8 leis e 27 testes.
7. **10.2, "100% das assinaturas" (linha 2355):** faltam as assinaturas multilinha e `pub llm fn`: `llm_moe_admission_guard` (2×), `nfe_key_segment_length`, `nfe_access_key_length_valid`, `estimate_job_priority`, `omniroute_select_provider`, `omniroute_remaining_budget`, `omniroute_reserve_inflight_budget`, `pix_trace_hop_risk_bps`, `uav_safe_altitude_guard_mm`. Em `lume_crypto_blockchain_engine.src` a contagem é 49, mas só 46 assinaturas aparecem.
8. **10.3, "10.892 funções internas" (linha 2569):** é a soma da própria tabela; HEAD dá 10.851. As linhas 2580 e 2616 não batem com nenhum estado.
9. **11.1, totais (linha 2641):** linhas 11.467 (HEAD 11.454; árvore 11.492); funções auxiliares 4.046 (HEAD 4.049; árvore 4.056). O total de 138 `test_*` contradiz o título de 688.
10. **11.3, "100% executáveis via ./lume test e auditadas em ./lume self-prove" (linha 2771):** falso como afirmação geral: 2 não são executáveis, a amostra tem 2 falhas reais e não há registro de execução no repositório.
11. **Parte XI, "Testes implementados e aprovados" (linha 2624):** "aprovados" sem evidência (ver seção 6).

## 8. O que está PENDENTE no Windows

Dependências não portadas (situação da árvore de trabalho, `docs/42-windows-native-toolchain.md` §6):

- sockets/TLS/epoll (`net_*`, `epoll_*`) e janelas X11 → Winsock/IOCP, *a construir*;
- `os_io_uring_*` → IoRing/IOCP, *a construir*;
- `os_shm_map` → `CreateFileMapping`, *a construir*;
- `os_fork` sem `exec` → funciona só em modo sequencial (filho antes do pai, mesmo espaço de endereço; trava se o filho escrever mais de 64 KiB no pipe);
- execução de ELF e programas Linux externos (`sh`, `cc`/`clang`, `as`, `objdump`/`objcopy`/`readelf`/`nm`/`addr2line`, `qemu-*`, `z3`/`cvc5`, `python3`, `git`, `curl`, `sha256sum`, `7z`, `time`, `date`, `id`, `ln`, `tail`, `tar`, `mktemp`, `ip`/`ping`/`ss`, `ssh`/`scp`, `tailscale`) → sem equivalente;
- os `/bin/{mkdir,rm,cp,mv,chmod,ls,pwd,printenv,test}` e `/usr/bin/env` só estão resolvidos nos arquivos que passam por `hostio.src`;
- o `lume.exe` nativo ainda não resolve módulos `use` fora do diretório do arquivo (`tests/registry/gate.src`).

### 8.1 Arquivos de teste/gate (11.2) PENDENTES no Windows

| arquivo | dependência exata |
|---|---|
| `bootstrap/lume0/tests/run_native.src` | PENDENTE: gera/executa ELF |
| `compiler/stage1/os_run_ok.src` | PENDENTE parcial: os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| `compiler/stage1/track_l_domains_ok.src` | PENDENTE: sockets/epoll (epoll_add_in@async_rt.src, epoll_create_fd@async_rt.src, epoll_wait_one@async_rt.src, net_close@async_rt.src, net_close@); os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| `tests/capstones/gate.src` | PENDENTE: programas externos: env, mkdir, qemu-system-x86_64, rm; os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| `tests/capstones/saas_assertions.src` | PENDENTE: sockets/epoll (net_close, net_recv_str, net_send_str, net_shutdown_write, net_tcp_connect) |
| `tests/cli/driver_gate.src` | PENDENTE: programas externos: cli_parity_ghost_tool, objdump, readelf, w14_no_such_lcaas; gera/executa ELF; os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| `tests/conformance/stage1/semantic_mesh/gate.src` | PENDENTE: programas externos: env, mkdir, rm |
| `tests/economic_benchmark/run.src` | PENDENTE: programas externos: mkdir, rm |
| `tests/harness/claude_audit_gate.src` | PENDENTE: programas externos: cc, clang, sh; gera/executa ELF |
| `tests/harness/concurrency_gate.src` | PENDENTE: programas externos: sh; gera/executa ELF |
| `tests/harness/dwarf_cache_gate.src` | PENDENTE: programas externos: addr2line, nm, readelf; gera/executa ELF |
| `tests/harness/lasm_gate.src` | PENDENTE: programas externos: as, objcopy, objdump; gera/executa ELF |
| `tests/harness/lcaas_scale_gate.src` | PENDENTE: programas externos: time |
| `tests/harness/multi_arch_gate.src` | PENDENTE: programas externos: aarch64-linux-gnu-as, clang, qemu-aarch64, qemu-riscv64, qemu-system-riscv32, readelf, riscv64-linux-gnu-as, sh; gera/executa ELF |
| `tests/harness/ownership_gate.src` | PENDENTE: gera/executa ELF |
| `tests/harness/prover_fuzz.src` | PENDENTE: gera/executa ELF |
| `tests/harness/prover_fuzz_gate.src` | PENDENTE: gera/executa ELF |
| `tests/harness/realtime_gate.src` | PENDENTE: gera/executa ELF |
| `tests/harness/safetensors_gate.src` | PENDENTE: programas externos: python3, sh, sha256sum, tail; gera/executa ELF |
| `tests/harness/safety_envelope_gate.src` | PENDENTE: programas externos: lsafety_envelope.bundled.src, sh; gera/executa ELF |
| `tests/harness/smt_cert_gate.src` | PENDENTE: programas externos: ln, lsmt.bundled.src, sh, smt_cert_gate.bundled.src, z3 |
| `tests/harness/soak_battle_gate.src` | PENDENTE: programas externos: date, id, sh, sha256sum; gera/executa ELF; os_fork/os_pipe sem exec (no Windows o filho roda antes do pai) |
| `tests/harness/synergy_gate.src` | PENDENTE: programas externos: addr2line, nm, qemu-aarch64, qemu-riscv64, qemu-system-riscv32, readelf, sh; gera/executa ELF |
| `tests/harness/tv_gate.src` | PENDENTE: programas externos: sha256sum; gera/executa ELF |
| `tests/harness/tv_rt_gate.src` | PENDENTE: gera/executa ELF |
| `tests/registry/gate.src` | PENDENTE: programas externos: cp, mkdir, mv, rm |
| `tests/registry/gate_adversarial.src` | PENDENTE: programas externos: cp, mkdir, mv, rm |
| `tests/registry/gate_process.src` | PENDENTE: programas externos: cp, mkdir, mv, rm |
| `tests/registry/gate_publish.src` | PENDENTE: programas externos: cp, mkdir, mv, rm |
| `bootstrap/lume0/tests/**/*.lume` (98 arquivos) | runner POSIX: `make -C bootstrap/lume0 test` → `tests/run.sh` (sh, make, cc); a alternativa `tests/run_native.src` gera/executa ELF |

### 8.2 Funções `test_*` (11.3) PENDENTES no Windows

| arquivo | teste | dependência exata |
|---|---|---|
| `compiler/stage1/async_rt.src` | `test_async_multiworker_os` | sockets/epoll+os_fork/pipe(parcial) |
| `compiler/stage1/db.src` | `test_durable_acid_wal_crash_recovery` | os_fork/pipe(parcial) |
| `compiler/stage1/gui.src` | `test_x11_native_window_session_and_wasm_dom_reconciler` | sockets/epoll+os_fork/pipe(parcial) |
| `compiler/stage1/lchameleon.src` | `test_wave9_real_vex_simd_kernel_io_uring_ast_horner_and_c_header_parser` | sockets/epoll+io_uring |
| `compiler/stage1/lconcurrency.src` | `test_parallel_multi_worker_dispatch_linux` | programas: sh |
| `compiler/stage1/lsentience.src` | `test_wave10_reverse_engineer_elf_and_pe` | programas: 7z,sh |
| `compiler/stage1/lsentience.src` | `test_wave10_egm_elephant_goldfish_and_drift` | programas: 7z |
| `compiler/stage1/lsentience.src` | `test_wave10_ncm_next_concept_coarse_to_fine` | programas: 7z |
| `compiler/stage1/lsentience.src` | `test_wave10_opentpu_systolic_isa_and_ksmoothing` | programas: 7z |
| `compiler/stage1/lume_egm_engine.src` | `test_egm_bidirectional_drift_with_reversa_sdd` | programas: 7z |
| `compiler/stage1/lume_ncm_engine.src` | `test_ncm_full_pipeline_bridge_egm_and_reversa` | programas: 7z |
| `compiler/stage1/lume_opentpu_engine.src` | `test_otpu_full_pipeline_scoreboard_and_ncm_bridge` | programas: 7z |
| `compiler/stage1/lume_reversa_engine.src` | `test_reversa_full_pipeline_on_source_and_immutability` | programas: 7z |
| `compiler/stage1/net.src` | `test_tls13_rfc8446_wire_records_and_loopback_handshake` | sockets/epoll+os_fork/pipe(parcial) |
| `compiler/stage1/lume_driver.src` | `test_ld_wave10_and_ui_layout_dispatch` | programas: 7z,curl,sh,sha256sum |
| `scripts/install.src` | `test_manifest_line_binds_exact_file_bytes` | programas: sha256sum |
| `compiler/stage1/os_run_ok.src` | `test_os_exec_replaces_child_process` | os_fork/pipe(parcial) |
| `compiler/stage1/os_run_ok.src` | `test_os_exec_missing_tool_returns_error` | os_fork/pipe(parcial) |
| `compiler/stage1/os_run_ok.src` | `test_os_kill_and_waitpid_status_report_sigterm` | os_fork/pipe(parcial) |

Total: 19 funções `test_*` com dependência não portada detectada estaticamente, de 688.

Resumo dos 409 arquivos (11.2), sem contar a ressalva do runner do seed: OK: 369, OK provavel: 11, PENDENTE: 28, PENDENTE parcial: 1.
