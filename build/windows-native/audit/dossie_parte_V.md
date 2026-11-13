# Auditoria da Parte V do dossiê, conferida contra o código

- **Dossiê auditado:** primeiro em `C:\Users\Ricardo.Bueno\LUME_DOSSIE_REVERSA_COMPLETO_BIT_A_BIT_PT_BR.md`, linhas 806 a 1281, lidas por inteiro. No meio da auditoria esse arquivo foi substituído por `C:\Users\Ricardo.Bueno\LUME_CATALOGO_COMPLETO_IMPLEMENTADO_E_TESTADO_PT_BR.md`, onde a Parte V ocupa as linhas **810 a 1285** (deslocamento de +4). Conferi o texto novo por amostragem: o cabeçalho, a tabela de módulos, os estágios S06 e S09, as tabelas da CLI (167 linhas de tabela, a mesma contagem), as seções 4.3, 4.5 e 4.6 e todas as afirmações apontadas abaixo como divergentes. **Não achei diferença de conteúdo.** As referências de linha deste relatório seguem o **arquivo novo**.
- **Repositório:** `C:\Users\Ricardo.Bueno\lume`, branch `windows-native-toolchain`, HEAD `2916735`, que é o mesmo `origin/main` citado pelo dossiê. Nada no repositório foi modificado.
- **Árvore de trabalho em movimento.** Durante a auditoria, outro agente migrou chamadas `/bin/mkdir|rm|cp|mv|chmod|ls|pwd|sha256sum|printenv|test` para `compiler/stage1/hostio.src`, por meio de `hio_run` e `hio_osrun*`. Isso aconteceu entre 00:10 e 00:22 do dia 13/11/2026. Por isso:
  - as contagens de linhas e `fn` foram conferidas **no HEAD** com `git show HEAD:...`; na árvore de trabalho, os módulos migrados têm +1 linha, o `use hostio`;
  - a coluna Windows usa o **retrato das 00:21**;
  - as linhas `arquivo:N` da árvore de trabalho podem se deslocar.
- **Legenda dos vereditos:**
  - CONFIRMADA: o código bate com a afirmação.
  - DIVERGENTE: o valor real é outro, e a coluna de evidência traz esse valor.
  - FALSA/INEXISTENTE: o identificador, nome ou fato não existe no repositório.
  - NÃO VERIFICÁVEL: é uma medição de execução que o código não fixa. Quando existe, indico o documento que traz o número.
- **Legenda da coluna Windows:**
  - OK: roda no Windows nativo com `lume.exe`, que é a cópia de `lume_driver.exe` feita em `build/windows-native/build_inst_win64.sh:25`.
  - PENDENTE: a dependência exata vem indicada.
  - N/A: a afirmação não envolve execução.
  - OK\*: roda, mas há uma diferença indicada.

## 0. Fatos transversais para a coluna Windows

1. **Entrada.** O `./lume` da raiz é POSIX sh. Fora de Linux x86_64 ele entrega **tudo** a `scripts/lume_legacy.sh` (`lume:43-45`), que também é POSIX sh e usa o `lume0` Stage-0. No Windows nativo, a única entrada nativa é `lume.exe` (= `lume_driver.exe`).
   - As rotas que o shim manda ao legado **mesmo no Linux** não têm caminho nativo no Windows. São elas (`lume:53-90`):
     - `build|check|test` com `*.lume|*.lbe|*.intent|*.so|*.a`;
     - alvo `*.wasm`;
     - `pkg publish|audit`;
     - `run` de superfícies `.lume/.lbe/.intent/.lumb/.wasm/.ptx/.spvasm/.v/.vhd/...`;
     - `fmt` de arquivo que não é `.src`;
     - `self` com `LUME_HOME`.
2. **Só `lume_driver.src` (`ld_host_cflags`/`ld_host_aflags`, `lume_driver.src:19-20`) e `lasm_gate.src` conhecem a plataforma.** Todas as outras ferramentas que compilam e executam programas chamam `lumec` sem `--win64` e `lasm` sem `--pe`, e portanto geram **ELF**, que o Windows não executa:
   - `ltv` com `@exec`;
   - `lmcdc` com `@exec`;
   - `lsafety_envelope`, no canal A;
   - `linteractive`;
   - `lregistry`;
   - `lqualify`;
   - a maioria dos gates.
3. **Bug encontrado:** `ld_w12_native` (`lume_driver.src:974`) chama `lumec` com `largs`, **sem** `ld_host_cflags()`, e depois `ld_assemble`, que **com** `--pe` no Windows. O resultado é um PE com instruções `syscall` Linux cruas. Isso afeta `lume build --critical | -g | --dwarf | --keep-proven-checks` no Windows. Além disso, o DWARF não tem forma PE (`docs/42-windows-native-toolchain.md` §5).
4. **Binários de gate não construídos para Windows.** `build/windows-native/inst/bin/` tem as 41 ferramentas e mais `lume`, `lume_make`, `amalgamate` e `native_installer`. **Nenhum** gate foi construído: `tv_gate`, `soak_battle_gate`, `synergy_gate`, `native_driver_gate`, `smt_cert_gate`, `lcaas_scale_gate` e os demais.
5. **Programas externos ainda chamados (retrato das 00:21)** sem equivalente em hostio:
   - `/bin/sh -c`, `/usr/bin/env`, `date`, `uname`, `id`, `tail`, `ln` e `/usr/bin/time`;
   - `timeout`, como argumento do `sh`;
   - `readelf`, `nm`, `addr2line`, `objdump`, `objcopy`, GNU `as` e os `as` cruzados;
   - `clang`, `cc`, `git`, `curl`, `7z`, `python3` e `qemu-*`;
   - `z3` e `cvc5`, opcionais: entram só se existirem;
   - `flock`, opcional;
   - `ss`, `ip`, `ping`, `tailscale`, `ssh` e `scp`, só inventariados.

## 1. Cabeçalho e tabela de módulos (L810-831)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 812 | origin/main @ 2916735 | CONFIRMADA | `git rev-parse --short origin/main` = 2916735 | N/A |
| 812 | MANIFEST.sha256 com 134 artefatos | CONFIRMADA | `MANIFEST.sha256`: 134 linhas | N/A |
| 812 | 1.196 arquivos no git | CONFIRMADA | `git ls-files \| wc -l` = 1196 | N/A |
| 820 | lumec.src 10.634 linhas / 3.177 fns | DIVERGENTE (não verificável no HEAD) | `lumec.src` é um amálgama gerado e **não versionado**; na árvore atual tem 10.642 linhas e 3.184 fns | N/A |
| 820 | ponto fixo lumec==lumec2==lumec3 + DDC cc vs clang | CONFIRMADA | G-BOOT (`lqualify.src:299`), DDC em `claude_audit_gate.src:172,177` (`clang`, `cc`) | PENDENTE: o bootstrap gera estágios ELF; DDC precisa de `cc` e `clang` |
| 821 | lcaas 4.564 / 1.560 | CONFIRMADA | wc / grep `fn` | OK |
| 821 | MCP com 15 tools | CONFIRMADA | `lcaas.src:3822` (15 nomes `lume_*`) | OK |
| 822 | lproof_cache 358 / 128 | CONFIRMADA (HEAD) | | N/A |
| 822 | domínio `lume-proof-cert-v1` | DIVERGENTE | as strings reais são `lume-proof-cache-cert`, `lume-proof-cert-seal-v1` e `lume-proof-digest-v1`; ver 1.2 | N/A |
| 823 | lcert 1.191 / 520, `lume-minimal-kernel-v1`, K0010..K0017 | CONFIRMADA | `lcert.src:558,581-584` | OK |
| 824 | lstack 325 / 137 | CONFIRMADA (HEAD) | | N/A |
| 825 | ltv 1.451 / 579 | CONFIRMADA (HEAD) | | N/A |
| 825 | 694 fns validadas, 687/687 | NÃO VERIFICÁVEL no código | medição; `docs/certification/QUALIFICATION_EVIDENCE.json` traz validated 160+459+5+70 = 694 e `uncorrelated` 0; `docs/PROJECTS.md:73` traz 687/687 | N/A |
| 825 | [C0010] transitivo em 118 kernels CT | NÃO VERIFICÁVEL no código | `QUALIFICATION_DOSSIER.md:115` traz 118/118 | N/A |
| 826 | ltv_rt 713 / 290, 18/18 helpers | CONFIRMADA | os 18 helpers estão listados em `ltv_rt.src:33-48` | N/A |
| 826 | 268 caminhos, 462 obrigações | NÃO VERIFICÁVEL no código | `QUALIFICATION_EVIDENCE.json` traz `runtime_helper_paths` 268 e `obligations` 462 | N/A |
| 827 | ltv_multiarch 354 / 139; lkir 209 / 92 | CONFIRMADA | | N/A |
| 828 | lsmt 548 / 237 | CONFIRMADA | | N/A |
| 829 | lmcdc 571 / 178 | CONFIRMADA (HEAD) | | N/A |
| 829 | 0/9.618 descobertos | NÃO VERIFICÁVEL no código | evidência: `mcdc_obligations` 9618, `mcdc_uncovered` 0 | N/A |
| 830 | lsafety_envelope 1.286 / 560 | CONFIRMADA (HEAD) | | N/A |
| 830 | 0/3.169 funções compartilhadas | NÃO VERIFICÁVEL no código | `QUALIFICATION_DOSSIER.md:91` | N/A |
| 830 | 87.224 falhas → 0 não detectadas | NÃO VERIFICÁVEL | aparece **só** em material de divulgação (`docs/assets/*.svg`, `docs/LUMELABS.md:62`); não está no dossiê de qualificação nem no código | N/A |
| 831 | lqualify 618 / 292; 10 HLR / 44 LLR / 106 probes / 21 gates | CONFIRMADA | `lqualify.src`: `q_h` HLR-01..10, 44 LLR distintos, 106 `q_p("P-...")`, 21 `q_g` | PENDENTE (ver 4.5) |

## 1.1 lcaas e lcaas_scale_gate (L833-854)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 835 | `__lume_try_begin`, `cs_diags_spanned` | CONFIRMADA | `lcaas.src:525,740` | OK |
| 836 | `FtX`, `cs_kt_*`, `cs_km_*` | CONFIRMADA | `lcaas.src:631,1703,1710` | OK |
| 837 | `cs_kx_*`, `cs_kmemo_build` | CONFIRMADA | `lcaas.src:1742,1904` | OK |
| 838 | LTL `leads_to`, `vwcet_verdict`, `tot_result`, `?rec` | CONFIRMADA | `lcaas.src:295,2839,2925,2933` | OK |
| 838 | `cs_cw_e`, tetos de 20.000 e 40.000, oversize | CONFIRMADA | `lcaas.src:2709-2720` | OK |
| 840 | `cs_collect_holes_stmts`, `cs_fill_prog_holes`, `cs_filter_proven_es`, [A0001] | CONFIRMADA | `lcaas.src:1394-1432` | OK |
| 841 | `caas_cegis_synthesize` | CONFIRMADA | `lcaas.src:4379` | OK |
| 841 | intervalo a,b ∈ [-8..8] | NÃO VERIFICÁVEL | não conferido em detalhe | OK |
| 842 | `@lume-intent-cache: v1`, [V0005] | CONFIRMADA | `lcaas.src:4340,2901` | OK |
| 843 | `lume-oracle-mcp`, 2024-11-05, 15 tools com os nomes listados | CONFIRMADA | `lcaas.src:3822,3864` | OK |
| 843 | [K0400], PTX 8.0, SPIR-V 1.6 | CONFIRMADA | `lcaas.src:3937,4123` | OK |
| 844 | lcaas_scale_gate com 222 linhas | CONFIRMADA (HEAD) | | PENDENTE: `/usr/bin/time` e `timeout` em `lcaas_scale_gate.src:221`; binário não construído |
| 845 | limiar de dobra 2.80, 7.84, ×1.4, 20.000 ms, 1.572.864 KB, 4.0x+150 ms, 8.0x | CONFIRMADA | `lcaas_scale_gate.src` (constantes presentes; o 280 aparece em cada linha de `lsg_gate_rows`) | idem |
| 845 | controles `lsg_ref_quad` e `lsg_ref_fib` | CONFIRMADA | | idem |
| 845 | 9 checagens bitwise | CONFIRMADA | 9 chamadas `lsg_bit(c, ...)` | idem |
| 845 | controles de regressão `c_header_comments` e `oversize_cert_term` | DIVERGENTE | esses nomes não existem; os reais são `lsg_sem1` "shr-contract", "control-trunc" e "oversize-certificate" | idem |
| 846-854 | 28 células (19 prove, check, 3 certify, lsp, dap, replay, hashes, bind) e os N base | CONFIRMADA | `lcaas_scale_gate.src:176-177` (28 `lsg_g`); N base `fam == ... then` (fns 300, strlit 2000, cheader 600, inline_fan 8, ...) | idem |

## 1.2 lproof_cache (L856-871)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 858 | `.cert` em `<cache>/proofs/<digest>.cert` | CONFIRMADA | `lproof_cache.src` | OK |
| 860-864 | domínios `lume-contract-v1`, `lume-body-v1`, `lume-fn-digest-v1` | DIVERGENTE | os reais são `lume-fn-contract-v1`, `lume-callees-v1`, `lume-fn-body-v1` e `lume-proof-digest-v1`; `lume-iface-contracted-v1` e `lume-iface-transparent-v1` estão certos (`lproof_cache.src:259`) | N/A |
| 864 | selo `lume-proof-seal-v1` | DIVERGENTE | o real é `lume-proof-cert-seal-v1` | N/A |
| 864 | comparação em tempo constante `pc_ct_eq_str` | CONFIRMADA | `lproof_cache.src:112` | N/A |
| 865 | self-test com 5 testes | CONFIRMADA | 5 `fn test_` a partir de `lproof_cache.src:337` | OK |
| 865 | `--require-all-hits` | CONFIRMADA | `lproof_cache.src:333` | OK |
| 866-871 | PC0001..PC0005 | CONFIRMADA | `lproof_cache.src:182..333` | OK: mkdir e rm já migrados para hostio |

## 1.3 lcert (L873-888)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 874 | `lc_sha256` próprio, kernel_id | CONFIRMADA | `lcert.src:72,558` | OK |
| 876 | rejeita inteiros com mais de 18 dígitos | CONFIRMADA | o comentário "at most 18 digits" está em `lcert.src` | OK |
| 877 | `lk_fm_unsat`, `lk_nia_enrich_hyps`, bitwise, `sep_disjoint`/`points_to`/`heap_*`, `forall_range`/`exists_range` ≤ 256, `terminates`, `wcet_budget` | CONFIRMADA | `lcert.src:206,267,288,296,301,445` | OK |
| 879 | `sb_*`, `sb_aeq`, `sb_cw_cap` 20.000/40.000, `simd_add4_i64` | CONFIRMADA | `lcert.src:764,819-822,876` | OK |
| 879 | renomeação `?K<d>.<nm>` | DIVERGENTE | o real é `?L<d>.<nm>` | N/A |
| 880-888 | K0010..K0017 com exit 3 | CONFIRMADA | `lcert.src:581-584` | OK |

## 1.4 a 1.11 (L890-953)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 891-897 | lstack: `.Ltail_`, `call *`, rejeitado com exit 3, `max_stack_bytes_all_paths`/`proven_paths`, A1/A2, E0210 | CONFIRMADA | `lstack.src:22,30,49,291` | PENDENTE (verificar): o lstack analisa o `.s` de `lume_driver build` (`lstack.src:317`); no Windows esse `.s` contém `call __win_syscall` e a camada Win64 |
| 897 | regras "R1,R2,R6" e "R3,R5" | NÃO VERIFICÁVEL | as regras não estão no texto com essa grafia | N/A |
| 901-904 | ltv: `tv_dsimp`, (T)(V)(E)(F), `uncorrelated` | CONFIRMADA | `ltv.src:110,306` | OK sem `--exec`; PENDENTE com `--exec`: `tv_exec` (`ltv.src:~1075`) monta ELF sem `--pe` e o executa |
| 906 | [C0010], recusa `divq`/`idivq`; verificação na origem com [C0011] | CONFIRMADA ([C0011] é do lumec) | `ltv.src:51,1325` | idem |
| 907 | invoca ltv_rt e lsmt em processo; gera `.smt2` + `.lean` | CONFIRMADA | `ltv.src:33,62,66` | z3/cvc5 opcionais (`ltv.src:1009`); `/bin/sh` em `ltv.src:1015` só quando há solver externo |
| 911-912 | ltv_rt: lista dos 18 helpers | CONFIRMADA | `ltv_rt.src:33-48` | OK |
| 913 | "bignums heap de 2 limbs h·2^31+l" | DIVERGENTE | `h*2^31+l` é a aritmética "wide" interna do verificador (`ltv_rt.src:90-91`), não bignum | N/A |
| 913 | divisão euclidiana flooring | DIVERGENTE | `__rt_div` e `__rt_mod` são `tdiv`/`tmod` truncados (`ltv_rt.src:39-45`) | N/A |
| 914 | preserva `__gc_pop_str`, `__gc_save`, `__gc_UN`; stubs `__lume_trap_div0/oom/stk/contract/bounds` | FALSA/INEXISTENTE | ltv_rt cobre o caminho rápido `__gc_pop..__gc_refill` (`ltv_rt.src:84`) e os stubs `__rt_ovf`/`__rt_div0` → `__rt_die3`; os nomes citados não existem | N/A |
| 915 | tv_rt_gate com 236 linhas; 21 bugs e 21 regiões | CONFIRMADA (linhas, HEAD) / NÃO VERIFICÁVEL (21/21) | | PENDENTE: gate não construído; `lasm` sem `--pe` |
| 918-919 | ltv_multiarch: `tvm_a_dec`, `tvm_r_dec`, `tvm_mutants`, 4.096 caminhos | CONFIRMADA | `ltv_multiarch.src:18,200,256,354` | OK (análise pura) |
| 918 | larm64 com 149 linhas e lriscv com 158 | CONFIRMADA | | N/A |
| 922-924 | lsmt: `forged`, R1..R7, 200.000 passos | CONFIRMADA | `lsmt.src:18,47,70,73` | OK (sem `os_run`) |
| 924 | funções `f_div`/`f_mod`/`f_shl`/`f_band`/`f_call_*` | DIVERGENTE | o lsmt aceita qualquer `f_*` declarado, com stand-ins `f___bit_*` (`lsmt.src:24-36`); os nomes citados não estão no código | N/A |
| 925 | smt_cert_gate com 274 linhas e 46.656 conjunções | CONFIRMADA | `smt_cert_gate.src` (46656) | PENDENTE: `/bin/sh` em `:93,271`, `/bin/ln` em `:271`, `timeout`; z3 opcional |
| 925 | 19 classes de mutação | NÃO VERIFICÁVEL | | |
| 928-933 | lmcdc: Masking MC/DC, `theorem_false`, `infeasible` via lcert, `kernel_proof_term`, `native_witnesses_agreeing` | CONFIRMADA | `lmcdc.src:45,53,464,569` | `--exec` PENDENTE: `lmcdc.src:541-545` monta e executa ELF |
| 930 | orçamento `@budget` padrão 320 | DIVERGENTE | o padrão é **6000** (`mc_or(mc_get(input,"budget"),"6000")` em `lmcdc.src`) | N/A |
| 933 | os 4 módulos certificados | CONFIRMADA | ver `QUALIFICATION_EVIDENCE.json` | N/A |
| 937-938 | canal B com `cbl_`/`cbp_`/`cbt_`/`cbg_`, VM `rv_*`, `ebreak`, orçamento N·16 | CONFIRMADA | `lsafety_envelope.src:74,141,171,310,369,442,527` | PENDENTE: o canal A é ELF montado sem `--pe` (`se_a_link`/`se_a_run`, `lsafety_envelope.src:~844-851`) |
| 941 | `VerifiedActuatorCommit`, `SAFE_STATE_TRIP`, `safety_envelope_events.jsonl` | CONFIRMADA | `lsafety_envelope.src:25,26,91` | idem |
| 943 | split: os 4 artefatos, boot em 0x80000000, UART 0x10000000, qemu-system-riscv32 | CONFIRMADA | `lsafety_envelope.src:113-129` | PENDENTE: qemu |
| 944 | split-run com quadros de 160 hex, `@seq`, 3 ISAs (`cmd_c`) | CONFIRMADA | `lsafety_envelope.src:115,760` | PENDENTE: `/bin/sh -c` em `lsafety_envelope.src:1266` (`ss_chan`) |
| 945 | safety_envelope_gate com 865 linhas | CONFIRMADA (HEAD) | | PENDENTE: `/bin/sh` em `safety_envelope_gate.src:396`; gate não construído |
| 945 | 87.224 falhas | NÃO VERIFICÁVEL | só em material de divulgação | |
| 949-953 | os 5 artefatos em `build/certification/`, Ed25519, DER X.509v3, OID 1.3.101.112, validade 2026-2036, KeyUsage, `q_verify` | CONFIRMADA | `lqualify.src` ("260101000000Z" e "360101000000Z"; `QUALIFICATION_*`) | PENDENTE (4.5) |
| 949 | HLR-01 "Determinismo Léxico", HLR-08 "Envelope 2oo2D" etc. | DIVERGENTE | os títulos reais (`q_h`) são outros: HLR-01 é a semântica do código objeto, HLR-07 é o envelope dissimilar, HLR-08 é kernel certificado e MC/DC, HLR-10 é a cadeia de ferramentas num só driver | N/A |
| 950 | TQP cobre ISO 26262 ASIL D / TCL3 | FALSA | "ISO 26262" e "TCL" não aparecem em `lqualify.src`; só DO-330/DO-178C, IEC 61508 e IEC 62304 | N/A |
| 951 | RTM com 106 probes `q_probes_a..j`, 21 gates, `rtm_requirement_fully_traced`, controle `q_orphan` | CONFIRMADA | `lqualify.src:98,108,359,382` | |
| 952 | hash de 30 arquivos TCB | CONFIRMADA | `q_tcb_files` (`lqualify.src:453`) tem 30 entradas | |
| 952 | cadeia c1=tcb, c2=rtm, c3=mcdc, c4=gates, head=verdict | DIVERGENTE | a cadeia real é c1 = previous + **probes**, c2 = **gates**, c3 = **modules**, c4 = **trusted_computing_base**, head = **summary** | N/A |

## 2.1 Os 17 estágios do synergy_gate (L959-981)

O `synergy_gate.src` define 17 IDs: S01, S02, S03, S04, S04-PAR, S05, S06, S07, S07-RT, S07-SMT, S08, S09, S09-SPLIT, S09-ISA, S09-STN, S10 e S11. Ficam em `sy_s01..sy_s11` (`synergy_gate.src:172-241`). **CONFIRMADA (17)**. O gate todo está **PENDENTE no Windows**: binário não construído, `readelf`/`nm`/`addr2line` em `:194,327`, `qemu-*` em `:327`, `ls` em `:130-131` (emulado), e ELF com DWARF em S06.

| linha | estágio | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|---|
| 959 | intro | artefatos `critical_pipeline.src` e demo com as funções listadas; saídas `synergy_gate_summary`, `.manifest` e `.sig.json` | CONFIRMADA | `examples/synergy/critical_pipeline.src` (5 fn + 1 law) | |
| 965 | S01 | 3 proven, 2 budget_checked, 0 refuted/runtime | CONFIRMADA | `synergy_gate.src:172` | OK (lcaas) |
| 966 | S02 | 5/5 a frio, depois 5/5 hits, `all_cached` | CONFIRMADA | `:173` | OK |
| 967 | S03 | `kernel_verified`, 3+2=5 | CONFIRMADA | `:174` | OK |
| 968 | S04 | ok, 5 obrigações vinculadas, `unbound` vazio | CONFIRMADA | `:175` | OK |
| 969 | S04-PAR | paridade `bit_contract` | CONFIRMADA | `:182` | OK |
| 970 | S05 | 5/5 bounded | CONFIRMADA | `:190`; `sy_stack_names` tem 5 nomes | PENDENTE (verificar) |
| 971 | S06 | stdout exato `150, 4500, 11, 29` | **DIVERGENTE** | `sy_demo_out()` = `150\n4500\n120\n9000\n1\n7\n9\n0\n6\n` | PENDENTE: `ld_w12_native` sem `--win64`; DWARF; `readelf`/`nm`/`addr2line` (`:194`) |
| 972 | S07 | 6/6 funções, `[C0010]` 3/3, 12 arquivos, `smt2_checked_native` 6, `uncorrelated` 0 | CONFIRMADA | `:196` | PENDENTE: `@exec` (ELF) |
| 973 | S07-RT | `helpers_rejected` 0 | CONFIRMADA | `:197` | OK (análise) |
| 974 | S07-SMT | 6/6 unsat, `forged` 0 | CONFIRMADA | `:198` | OK |
| 975 | S08 | 3/3, `uncovered` 0, testemunhas nativas | CONFIRMADA | `:199` | PENDENTE: `--exec` |
| 976 | S09 | 3 commits **150, 4500, 9800** | **DIVERGENTE** | `:209`: o terceiro commit é **120** (`sy_commit(r.out,"100,120,50",120)`) | PENDENTE: canal A em ELF |
| 977 | S09-SPLIT | `split-verify` e `split-run` com qemu-system-riscv32 e `lumeputer:` | CONFIRMADA | `:220` | PENDENTE: qemu, `/bin/sh -c` |
| 978 | S09-ISA | 3 ISAs comitando 150 | CONFIRMADA | `:222` | PENDENTE: qemu-aarch64/riscv64 |
| 979 | S09-STN | safetensors com 150 e 4500 | CONFIRMADA | `:223` | OK (em processo) |
| 980 | S10 | ed25519 e cadeia X.509 no instante 1794398400; entropia | CONFIRMADA | `:226,238` | OK: entropia via BCryptGenRandom |
| 981 | S11 | `boundary_ok`/`bad`, I0003 | CONFIRMADA | `:241` | OK |

## 2.2 Os 36 tamper checks (L987-1022)

O `synergy_gate.src` tem 36 IDs distintos de T-A1 a T-M2. **CONFIRMADA (36).** As três divergências da tabela já estão indicadas: S06, S09 e a ausência de 9800. Conferi os detalhes um a um por grep. Todos herdam o PENDENTE do gate inteiro no Windows.

| linha | ID | afirmação | veredito | evidência |
|---|---|---|---|---|
| 987 | T-A1 | `step <= 500` → 501 | CONFIRMADA | `:301` (`sy_ta`, `:249`) |
| 988 | T-A2 | 9000 → 9001 | CONFIRMADA | `:301` |
| 989 | T-B1 | `(<= ... 10000)` → 9000 com novo hash | CONFIRMADA | `:253` |
| 990 | T-B2 | → 10500 e K0013 | CONFIRMADA | `:254` |
| 991 | T-C1 | 1 dígito de `contract_digest` e PC0002 | CONFIRMADA | `:256` |
| 992 | T-C2 | 4 hits e 1 miss em `actuator_cmd` | CONFIRMADA | `:257` |
| 993 | T-D1 | `addq %rsi, %rax` → `subq` | CONFIRMADA | `:261` |
| 994 | T-D2 | `$18001` → `$18003` | CONFIRMADA | `:262` |
| 995 | T-E1 | `jz` em `ct_select32` e C0010 | CONFIRMADA | `:260-266` |
| 996 | T-E2 | `leak_ct` e C0009 | CONFIRMADA | `:267` |
| 997 | T-E3 | `if mask == 0` e C0011 | CONFIRMADA | `:268` |
| 998 | T-E4 | `if 1 == 1` e C0011 | CONFIRMADA | `:269` |
| 999-1000 | T-F1, T-F2 | `val_x86` e `(assert false)` forjado | CONFIRMADA | `:271` |
| 1001 | T-G1 | `jo` → `jno .Lrt_av_big` | CONFIRMADA | `:275` |
| 1002 | T-H1 | `subq $64` → `$80` | CONFIRMADA | `:277` |
| 1003 | T-H2 | `call rate_limit` em `.Ltail` | CONFIRMADA | `:278` |
| 1004 | T-H3 | `count(str(req))` e E0210 | CONFIRMADA | `:279` |
| 1005 | T-I1 | `req*(180-req) > 40500`, `uncovered` 2 | CONFIRMADA | `:281` |
| 1006-1010 | T-J1..T-J5 | injeções `a_src:arith:0`, `b_src:arith:0`, `b_cg:reg:0`, `a_asm:addsub:1`, `b_rom:60:20`, cada uma com seu motivo | CONFIRMADA | `:302` |
| 1011 | T-J6 | `a_frame_crc` | CONFIRMADA | `:284` |
| 1012 | T-J7 | `a_frame_sequence` e `sequence_not_fresh` | CONFIRMADA | `:285` |
| 1013 | T-J8 | manifesto `channel_b_riscv_bare` | CONFIRMADA | `:286` |
| 1014 | T-K1 | bit em safetensors | CONFIRMADA | `:288` |
| 1015-1020 | T-L1..T-L6 | erros 50/43/51, 1893456000, defeitos 2 e 6 | CONFIRMADA | `:294-295` |
| 1021-1022 | T-M1, T-M2 | `rate_limit_never_moves`, `result <= 9000` | CONFIRMADA | `:297-299` |

## 3. Universal Chameleon (L1028-1072)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1028 | lchameleon com 1.058 linhas | CONFIRMADA | wc | N/A |
| 1028 | 160 declarações = 133 fn + 27 law | **DIVERGENTE** | 133 fn (correto), mas **65** `law` → 198 declarações | N/A |
| 1028 | 114 kernels `@bound` | **DIVERGENTE** | 98 ocorrências de `@bound` | N/A |
| 1028 | 19 testes | CONFIRMADA | 19 `fn test_` | N/A |
| 1028 | interop.src com 165 linhas e 67 fns | CONFIRMADA | | N/A |
| 1028 | binder `lcert_bind` / `lcert_bind_raw` | CONFIRMADA | `lcaas.src:3700` | OK |
| 1031-1052 | `cham_detect_ecosystem`, `cham_extract_symbol`, `cham_synthesize_adapter`, `cham_synthesize_all_9_bundle` e os kernels e pontes dos 9 ecossistemas | CONFIRMADA | dos ~125 identificadores citados, todos existem em `lchameleon.src` ou `interop.src` (`wasm_export_wat`, `adapt_http_openapi_endpoint`), **exceto** os listados abaixo | OK (em processo) |
| 1036 | binder: `int64_t`, ≤ 6 parâmetros, `const char*`, `borrowed_read_only`, `c_buf` | CONFIRMADA | `lcaas.src:3658-3680` | OK |
| 1036 | pré-processador `lc_preprocess_c_lines_st`, `bind-raw`, CUDAAPI/WINAPI/`__stdcall`, `ssize_t`/`ptrdiff_t`/`intptr_t`/`long long` | CONFIRMADA | `lcaas.src:3704-3720` | OK |
| 1042 | I0002 e E0200 em interop | CONFIRMADA | `interop.src` | OK |
| 1050 | `cham_sql_fk_integrity_law` | **FALSA/INEXISTENTE** | não existe em nenhum `.src` | N/A |
| 1062 | OTE: 12 fn + 4 law | CONFIRMADA | 12 `fn ote_` e 4 `law ote_` | N/A |
| 1062 | nomes das 4 leis OTE | **DIVERGENTE** | os nomes reais são `ote_omega_counterphase_law`, `ote_nyquist_aliasing_law`, `ote_power_triangle_conservation_law` e `ote_cascade_resonance_law`; os 4 nomes do dossiê não existem | N/A |
| 1063-1072 | demais kernels, das seções 1k a 1Q | CONFIRMADA (nomes) | grep de cada nome em `lchameleon.src` | N/A |
| 1063-1072 | contagens por seção (5 fn + 3 law, 10 + 5, 23 + 10, 32) | NÃO VERIFICÁVEL | o arquivo não marca as seções de forma inequívoca | N/A |

## 4.1 As 114 linhas da CLI (L1078-1196)

| linha | afirmação | veredito | evidência |
|---|---|---|---|
| 1078 | `ld_cmd_table_text` nas linhas 1008-1121 | DIVERGENTE | no **HEAD** fica em `lume_driver.src:997-1111`; na árvore atual, em `:1010-1123`; o **conteúdo é idêntico** nas duas versões (diff vazio) |
| 1079 | 114 linhas | CONFIRMADA | 114 linhas `"...\n"` |
| 1079 | é a fonte única de `ld_entry`, `ld_run_handler`, help e describe | CONFIRMADA | `lume_driver.src:1137` (`ld_cmd_table`), `:1242-1244` |
| 1079 | também alimenta o Apêndice A do lmanual | CONFIRMADA | `ld_manual_entry` passa `ld_tab_reference(rows)` a `man_render_cli` (`:851`); o lmanual em si não lê a tabela |
| 1079 | `cli-parity` = `tests/cli/driver_gate.src` com TOTAL MISMATCHES | CONFIRMADA | o campo de ferramenta real é `native_driver_gate`, compilado de `tests/cli/driver_gate.src` (`:944`) |
| 1079 | formato de 7 campos | DIVERGENTE | são **8 campos**: `nomes;handler;flags;subs;valores;ferramenta;modo;args` (`ld_trow`, `:1131`) |

**Comparação linha a linha:** os 114 conjuntos de nomes e aliases e os 114 handlers do dossiê batem exatamente com a tabela real. **Não há comando faltando nem sobrando.** As diferenças estão só na coluna "Binário/Motor", que o dossiê inferiu:

- o campo `tool` real fica vazio em `manual`, `build`, `run`, `compile`, `adapt`, `lsp`, `dap`, `repl`, `mcp`, `self`, `self-prove`, `capsule`, `pack`, `genesis`, `bundle` e em todos os `sentience`;
- os gates aparecem como nome de binário (`tv_gate`), não como caminho `tests/harness/...`;
- `cli-parity` → `native_driver_gate`.

Os comandos `sentience` rodam **dentro do processo** do `lume_driver`, que importa `lsentience`, e este importa os motores `lume_*_engine`, `net`, `gfx` e `lchameleon` (`lume_driver.src:1-7`, `lsentience.src:13-26`). Não são binários separados. Também ficaram de fora do dossiê os enums de `build` (`none|standard|hardened|max|debug|release|ship`) e de `help`.

Handler executado (`ld_run_handler`, `lume_driver.src:1242`) e situação no Windows:

| # | comando | handler → função | Windows |
|---:|---|---|---|
| 1 | --version | version → `ld_request(lcli)` | OK |
| 2 | help | help → lcli / `ld_tab_json` / `ld_manual_entry` | OK |
| 3 | manual… | manual → `ld_manual_entry` (lmanual em processo) | OK |
| 4 | describe | describe → `ld_describe` (lcli) | OK |
| 5 | targets | targets → `ld_request(ltarget)` | OK |
| 6 | build | build → `ld_build_entry` (lumec `--win64` + lasm `--pe`) / `ld_w12_build_entry` | OK no caminho padrão. **PENDENTE:** `--critical`/`-g`/`--dwarf`/`--keep-proven-checks` (`ld_w12_native`, `:974`, chama lumec sem `--win64`; DWARF não tem forma PE); `.lume`/`.wasm` caem no legado (`lume:55-66`) |
| 7 | run | run → `ld_run_entry` | OK para `.src`; as superfícies `.lume`… caem em `lume_legacy.sh` (N/A no Windows) |
| 8 | test | test → `ld_test_entry` | OK\*: sem `/usr/bin/flock` (`:233,238`), roda sem lock entre processos |
| 9 | check | check → lcaas | OK (`.lume` cai no legado) |
| 10 | compile | compile → lumec (cflags do host) + lcaas | OK |
| 11 | fmt | fmt → lfmt | OK (arquivo que não é `.src` cai no legado) |
| 12 | doc | doc → ldoc | OK |
| 13 | prove | prove → lcaas | OK |
| 14 | certify | certify → lcaas | OK |
| 15 | verify-cert | certify → lcert | OK |
| 16 | proof-cache | proof-cache → `build/bin/lproof_cache` | OK (mkdir e rm migrados) |
| 17 | pkg | pkg → `ld_pkg` (lmod) | OK para init/check/manifest/lock/verify/tree; **PENDENTE:** `~publish`/`~audit` → `scripts/lume_legacy.sh` (`lume:72-74`) |
| 18 | registry | registry → lregistry | PENDENTE: `lregistry.src:~125` compila com lumec/lasm sem `--pe` e executa o binário; `printenv`/`ls` emulados |
| 19 | agent | agent → lcaas; `@sentience` em processo | OK |
| 20 | adapt | adapt → lcaas bind/bind-raw; polyglot/all em processo | OK |
| 21-22 | lsp, dap | protocol → `ld_protocol` (lcaas) e linteractive | lsp OK; dap com execução PENDENTE (`linteractive.src:57-58`: lasm sem `--pe`, executa) |
| 23 | repl | repl → `ld_protocol` | PENDENTE quando avalia compilando (`linteractive.src:57-58`) |
| 24 | mcp | mcp → `lcaas @mcp-server` | OK |
| 25 | intent | intent → lcaas | OK |
| 26 | mesh | mesh → lmesh | OK |
| 27 | economy | economy → leconomy | PENDENTE: `/usr/bin/git` (`leconomy.src:96`), `timeout` (`:50`) |
| 28 | evolve | evolve → levolve + `lume_driver test` | OK |
| 29 | self | self → status/verify (sha256sum opcional, com fallback para lsha/`fs_sha256_file`, `:537`), update, prove | status/verify/prove OK; **update PENDENTE**: `scripts/install.src:12-35` (`/bin/cp`, `/bin/mkdir`, `/bin/chmod`, `/usr/bin/sha256sum` ainda diretos) |
| 30 | self-prove | self-prove → `ld_self_prove_entry` (`:836`) | PENDENTE: bloco wave11 (canal A do lsafety_envelope em ELF); ver 4.4 |
| 31 | capsule | capsule → `ld_build` + execução | OK |
| 32 | pack | pack → `ld_pack_cmd` | OK |
| 33 | package | package → ltarget, lprotect, lasm `--iso` | OK (gera arquivos; não testado) |
| 34 | mir | mir → ltarget | OK |
| 35 | genesis | genesis → lgenesis em processo | OK |
| 36 | neural-kernel | neural-kernel → ltarget | OK |
| 37 | symbolize | symbolize → lprotect | OK |
| 38-43 | patch-fn, trace, diff-semver, heal, equiv, morph | → lcaas (`ld_agent*`) | OK |
| 44 | tv | tool → ltv (modo B) | OK sem `--exec`; `--exec` PENDENTE (`ltv.src:~1075`) |
| 45 | mcdc | tool → lmcdc | `--exec` PENDENTE (`lmcdc.src:541-545`) |
| 46 | bundle | bundle → lmod | OK |
| 47 | safety-envelope | envelope → lsafety_envelope / safety_envelope_gate | PENDENTE: ELF do canal A; `/bin/sh -c` (`lsafety_envelope.src:1266`); qemu; gate não construído |
| 48 | stack | stack → lstack | PENDENTE (verificar): o `.s` do Windows contém a camada `__win_syscall` (`lstack.src:317`) |
| 49 | smt-check | smt-check → lsmt | OK |
| 50 | tv-rt | tv-rt → ltv_rt | OK (lumec sem `--win64` gera o `.s` Linux; a camada Win64 fica sem verificação, como diz o doc 42 §5) |
| 51 | x509 | x509 → lx509 | OK |
| 52 | entropy | entropy → lx509 | OK (BCryptGenRandom) |
| 53 | tv-gate | tool → tv_gate | PENDENTE: gate não construído; lasm sem `--pe` (8 chamadas); `sha256sum` (`:227`, emulado) |
| 54 | soak | tool → soak_battle_gate | PENDENTE: `/bin/sh` (`:183,188,211,212`), `/usr/bin/env` (`:156,188`), `date` (`:299`), `id` (`:300`), `/proc`, uid 0 |
| 55 | prover-fuzz | tool → prover_fuzz_gate + prover_fuzz | PENDENTE: monta e executa ELF; gate não construído |
| 56 | qualify | tool → lqualify | PENDENTE (ver 4.5): `lqualify.src:163` (env), `:189` (readelf), `:272` (z3), `:280,610` (qemu), `:521,616` (date), `:616` (uname) |
| 57 | realtime-gate | tool → realtime_gate | PENDENTE: lasm sem `--pe` e execução |
| 58 | concurrency-gate | tool → concurrency_gate | PENDENTE: `lconcurrency.src:274` (`/bin/sh`; workers ELF bifurcados) |
| 59 | crypto-gate | tool → crypto_tls_gate | PENDENTE: binário não construído (sem programa POSIX identificado; depende de ltv e lstack) |
| 60 | multi-arch-gate | tool → multi_arch_gate | PENDENTE: clang e `as` cruzados (`:58`), readelf (`:62`), `/bin/sh` (`:95`), qemu (`:99,100,173`) |
| 61 | safetensors-gate | tool → safetensors_gate | PENDENTE: `/bin/sh`, `tail`, `sha256sum` (`:71`), `python3` (`:126-127`) |
| 62 | dwarf-cache-gate | tool → dwarf_cache_gate | PENDENTE: readelf/nm/addr2line (`:44,46`); DWARF em ELF |
| 63 | cert-source-gate | tool → cert_source_gate | PENDENTE: só falta construir (mkdir e rm migrados) |
| 64 | tv-rt-gate | tool → tv_rt_gate | PENDENTE: binário não construído; lasm sem `--pe` |
| 65 | smt-cert-gate | smt-cert-gate → `ld_smt_gate_entry` | PENDENTE: `smt_cert_gate.src:93,271` (sh, ln, timeout) |
| 66 | lcaas-scale-gate | lcaas-scale-gate → `ld_lcaas_scale_entry` | PENDENTE: `/usr/bin/time` (`lcaas_scale_gate.src:221`) |
| 67 | cli-parity | cli-parity → native_driver_gate `@only cli_parity` | PENDENTE: binário não construído; o caminho `cli_parity` só chama `lume_driver` (`driver_gate.src:23`); o resto do gate usa readelf/objdump (`:171-173`) |
| 68 | synergy-gate | tool → synergy_gate | PENDENTE (ver 2.1) |
| 69 | bootstrap…clean | make → lume_make | clean e amalgamate OK; **bootstrap** PENDENTE (estágios ELF); **seed/test/asan** PENDENTE: `cc` (`lume_make.src:22`); **zero-c** PENDENTE: `as`/`cc`/`clang` (`zero_c.src:8,46`) |
| 70 | lumeputer… | sentience → `ld_lumeputer_exec_entry` (exec/run, VM no lsafety_envelope) / `ld_sentience_entry` | OK (não testado) |
| 71 | ui-layout | sentience → ltarget `@ui-layout` | OK |
| 72 | unified-field… | sentience (em processo) | OK |
| 73-80 | consult, laws, replicate, bios-core, daemon-triad, hot-evolve, self-build | sentience (em processo) | OK |
| 79 | live-cockpit | sentience → `net_omni_probe` | OK\*: o inventário de executáveis de rede usa o caminho fixo `/mnt/c/Windows/System32` (`lsentience.src:375`), que no Windows nativo não encontra nada; deveria usar `hio_win_system32()` |
| 81 | reverse-engineer… | sentience → `sentience_reverse_engineer_json` | PENDENTE: `/bin/sh -c` (`lsentience.src:441`), `/usr/bin/7z` (`lume_reversa_engine.src:351,355`) |
| 82-88 | pingora, egm, ncm, opentpu, continuum, quantum-nexus, chameleon | sentience (motores em processo) | OK |
| 89-97 | interface, crypto-engine, sensory-cortex, file-indexer, wireshark, gfx, memory, recall, synapse | sentience (em processo; synapse chama `ld_prove` e `ld_certify`) | OK |
| 98 | os-control… | sentience → `net_omni_probe` | OK\* (mesma observação da linha 79) |
| 99 | web-research… | sentience → `web_live_fetch` | PENDENTE: `/usr/bin/curl` (`lsentience.src:382`) |
| 100-105 | hive, saturate-contracts, fuse-mir-neural, triad-orchestrate, evolve-all, multimodal | sentience | OK |
| 106-114 | awaken…llm-forge | sentience (em processo) | OK |

## 4.2 Ferramentas (L1198-1208)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1199 | lcli com 192 linhas e 38 fns; "lume 1.1.0 (edition 2026)"; compile-json/pkg-init/pkg-lock/pkg-tree/evolve-propose | CONFIRMADA | `lcli.src` | OK |
| 1199 | describe com 39 identificadores | NÃO VERIFICÁVEL | | |
| 1200-1203 | linteractive com 78 linhas e 69 fns; lsp/3.17, dap/1.65, Jupyter 5.3, `lume-kernel-v1`, stepBack, reverseContinue, `kernel_info_request`/`is_complete_request`, comandos `:` | CONFIRMADA | `linteractive.src` | lsp OK; dap e repl com execução PENDENTE |
| 1203 | `execute_request` | DIVERGENTE | não aparece em `linteractive.src` | |
| 1201 | completion com mais de 60 símbolos | NÃO VERIFICÁVEL | | |
| 1205 | lmod com 174 linhas e 73 fns; `@manifest`/`@pkg-*`; E0200; `hardened` | CONFIRMADA | `lmod.src` | OK |
| 1206 | lfmt com 254 linhas e 133 fns; `lf_real_ast` com `parseprogram` | CONFIRMADA | `lfmt.src` | OK |
| 1207 | ltest com 83 linhas e 37 fns; `hw_scratch_addr()+4096`; "passed, failed" | CONFIRMADA | `ltest.src` | OK |
| 1208 | lmanual com 1.835 linhas, 44 fns e 10 capítulos | CONFIRMADA | `lmanual.src` (os 10 tópicos) | OK |

## 4.3 Biblioteca padrão (L1210-1215)

| linha | afirmação | veredito | evidência |
|---|---|---|---|
| 1211 | lstd com 208 linhas e 70 declarações certificadas | CONFIRMADA (70) | 47 fn não-teste + 23 law = 70 |
| 1211 | 48 `pub fn` + 22 `law`, 6 testes, 54 fn | **DIVERGENTE** | não há nenhum `pub fn`; são 47 `fn` com `@bound` (47 `@bound`), 23 `law`, **7** testes e 54 fn no total |
| 1212 | `std_abs`, `std_min`, `std_max`, `std_in_range`, `std_div_ceil`, `std_lerp_num`, `vec_valid_index`, `vec_growth_cap`, `map_probe_slot`, `map_needs_rehash`, `decimal_scale_add`, `decimal_fee_bps`, `decimal_clamp` | **FALSA/INEXISTENTE** | nenhum existe em `lstd.src`; existem `std_clamp`, `std_vec_clamp_index`, `std_vec_checked_slice_len`, `std_map_checked_slot` |
| 1213 | kernels LumePuter, Octagon, Farkas … #112..#121 | CONFIRMADA | `lstd.src:202-206` |
| 1214 | std.lume com 418 linhas e 83 fns = 58 `pub fn` + 25 testes | **DIVERGENTE** | 418 linhas e 83 fns, mas **62** `pub fn` (62 `@bound`) + **21** testes |
| 1214 | `std_money_split_lo`/`hi` | FALSA/INEXISTENTE | não existem |
| 1215 | crypto.lume com 212 linhas e 26 fns = 23 + 3 | CONFIRMADA | |
| 1215 | nomes `crypto_x25519_clamp_b0`/`b31`, `crypto_tls13_next_state`, `crypto_sp800_90b_rct_ok`/`apt_ok`, `crypto_dudect_pass_milli` | **DIVERGENTE** | os reais são `crypto_x25519_clamp_first`/`last`, `crypto_tls13_hs_next`, `crypto_entropy_rct_fail`/`apt_fail` e `crypto_dudect_pass`; o limiar 4500 existe |

## 4.4 As 16 baterias do self-prove (L1217-1237)

`ld_sp_list` (`lume_driver.src:825`; no HEAD, `:813`) tem 15 baterias. A 16ª é `kernelume_sovereign_os` (`ld_sp_kernelume`, `:832`). **CONFIRMADA (16)**. Engine `LumeCompiler-Embedded-OmniProof-v4` e `zero_external_scripts`: CONFIRMADA (`:836`).

Cada bateria roda `ld_certify` (lcaas, `nopen = total - proven - budget`) e `ld_test_quiet`. No Windows, `ld_test_quiet` executa o teste com `fs_chdir` (`ld_run_in_dir`, `:242-243`). No Linux, usa `/bin/sh -c 'cd …'` com `flock`.

| # | bateria (linha 1219-1234) | caminho e certify | veredito | Windows |
|---:|---|---|---|---|
| 1 | std_net | net.src, 1 | CONFIRMADA | OK (testes computacionais; nenhum teste usa sockets) |
| 2 | std_gfx | gfx.src, 1 | CONFIRMADA | OK |
| 3 | crypto_blockchain_defi | lume_crypto_blockchain_engine.src, 1 | CONFIRMADA | OK |
| 4 | reversa_sdd_engine | lume_reversa_engine.src, 1 | CONFIRMADA | OK (os 4 testes não chamam 7z) |
| 5 | pingora_edge_proxy | 1 | CONFIRMADA | OK |
| 6 | egm_spec_driven_engine | 1 | CONFIRMADA | OK |
| 7 | ncm_next_concept_engine | 1 | CONFIRMADA | OK |
| 8 | opentpu_systolic_isa_engine | 1 | CONFIRMADA | OK |
| 9 | continuum_nexus_engine | 1 | CONFIRMADA | OK |
| 10 | quantum_nexus_engine | 1 | CONFIRMADA | OK |
| 11 | chameleon_polyglot_engine | lchameleon.src, 1 | CONFIRMADA | OK |
| 12 | lume_standard_library | lstd.src, 1 | CONFIRMADA | OK |
| 13 | safety_critical_kernels | examples/safety_envelope/critical_kernels.src, 1 | CONFIRMADA | OK |
| 14 | lsentience_synapse | lsentience.src, 0 | CONFIRMADA | OK\*: `test_wave10_os_control_and_net_omni` (`lsentience.src:571`) passa, mas o inventário usa `/mnt/c` fixo |
| 15 | lmanual_and_sha256 | lmanual.src, 0 | CONFIRMADA | OK |
| 16 | kernelume_sovereign_os | `../kernelume/init/main.src` + `boot/kernelume_qemu.src`, ou in-tree | CONFIRMADA | OK (lcaas) |
| — | `kernel_and_crypto_laws`: K0005 (base 32768), K0006, C0009, SRA sem `mkrec`/`recget` | CONFIRMADA (a faixa `[32768..262143]` não foi verificada) | `ld_sp_guards`, `:831` | OK |
| — | wave11: ltv sobre lstd (`rejected` 0) e `infusion_dose_clamp(700,500)` → 500 pelo envelope | CONFIRMADA | `ld_sp_wave11`, `:835` | **PENDENTE**: o lsafety_envelope monta o canal A em ELF sem `--pe` e o executa (`lsafety_envelope.src:~844-851`) |
| 1218 | 372 testes unitários, 1.682 obrigações | NÃO VERIFICÁVEL | contagem de execução; só aparece em `docs/wiki/LumeLabs-and-Community-Hub.md:64` | |
| 1218 | certificação "via kernel lcert" | DIVERGENTE (parcial) | o driver chama só o lcaas (`@mode certify`); o lcert não é chamado pelo self-prove | |

## 4.5 Os 21 gates do lqualify e os 25 harnesses (L1239-1262)

`q_gates` = `q_gates_a` + `q_gates_b` + `q_gates_c` (`lqualify.src:267-299`, 21 `q_g`). **CONFIRMADA (21 IDs, todos com o nome certo).** Os rótulos entre parênteses do dossiê (`bootstrapStage2EqualsStage3`, `selfProveOmniBattery`, `cliTableParityGate` etc.) **não existem** no repositório: FALSA/INEXISTENTE. O executor do gate é `q_run` (`lqualify.src:90-91`) sobre `build/bin/<bin>`.

| # | gate | o que o código executa (`q_g`) | veredito da descrição do dossiê | Windows |
|---:|---|---|---|---|
| 1 | G-BOOT | `lume_make bootstrap` | CONFIRMADA | PENDENTE: estágios ELF; seed `lume0` |
| 2 | G-TESTS | `lume_make test` (suíte de conformidade nativa) | **DIVERGENTE**: o dossiê diz "suítes unitárias de lstd/lchameleon/lsentience/critical_kernels" | PENDENTE: `cc` (`lume_make.src:22`) |
| 3 | G-SELFPROVE | `lume_driver self-prove --json` | CONFIRMADA | PENDENTE (wave11) |
| 4 | G-LASM | lasm_gate | CONFIRMADA | PENDENTE: GNU `as`/`objcopy`/`objdump` (`lasm_gate.src:60,201-289`) |
| 5 | G-PFUZZ | prover_fuzz_gate | CONFIRMADA | PENDENTE (ELF) |
| 6 | G-TV | tv_gate | CONFIRMADA (o 694 e o 687/687 são medições) | PENDENTE |
| 7 | G-SOAK | soak_battle_gate | CONFIRMADA | PENDENTE (`sh`, `env`, `date`, `id`, `/proc`) |
| 8 | G-ENV | safety_envelope_gate | CONFIRMADA (o 87.224 não é verificável) | PENDENTE |
| 9 | G-AUDIT | claude_audit_gate | CONFIRMADA | PENDENTE: `/bin/sh`, `clang`, `cc` (`:17,171-177`) |
| 10 | G-DWARF-CACHE | dwarf_cache_gate | CONFIRMADA | PENDENTE (readelf etc.; DWARF) |
| 11 | G-CONC | concurrency_gate | CONFIRMADA | PENDENTE (sh; workers bifurcados) |
| 12 | G-CRYPTO | crypto_tls_gate | CONFIRMADA (24 alvos dudect; o \|t\| 2.690 e o 6.000/6.000 vêm de documentos) | PENDENTE (binário não construído) |
| 13 | G-MARCH | multi_arch_gate | CONFIRMADA | PENDENTE |
| 14 | G-SAFETENSORS | safetensors_gate | CONFIRMADA | PENDENTE (`python3`, `sh`) |
| 15 | G-REALTIME | realtime_gate | CONFIRMADA | PENDENTE (ELF) |
| 16 | G-CERTSRC | cert_source_gate | CONFIRMADA | PENDENTE (só falta construir) |
| 17 | G-TVRT | tv_rt_gate | CONFIRMADA | PENDENTE |
| 18 | G-SMT | smt_cert_gate (`@require_z3` se `/usr/bin/z3` existir, `lqualify.src:272`) | CONFIRMADA | PENDENTE |
| 19 | G-SCALE | lcaas_scale_gate | CONFIRMADA | PENDENTE (`/usr/bin/time`) |
| 20 | G-SYNERGY | synergy_gate | CONFIRMADA | PENDENTE |
| 21 | G-CLI | native_driver_gate | CONFIRMADA | PENDENTE (não construído) |

O lqualify em si também tem pendências no Windows:

- usa `/usr/bin/env` (`:163`), `readelf` (`:189`), `qemu-*` (`:280,610`), `date` (`:521,616`) e `uname` (`:616`);
- usa `ls` (`:193,232`), que é emulado;
- a chave de assinatura fica em `/root/.lume/keys` (doc 42 §5).

| linha | afirmação | veredito | evidência |
|---|---|---|---|
| 1262 | 25 arquivos em `tests/harness/` | CONFIRMADA | `ls tests/harness \| wc -l` = 25 (todos `.src`) |
| 1262 | c_adapter_gate 34, assertions 97, fixtures 5, ownership 36, runtime_sync 39, gc 10, lasm_fixtures 5, prover_fuzz 299 | CONFIRMADA (HEAD) | `git show HEAD:… \| wc -l`; na árvore atual, os gates migrados têm +1 linha |

## 4.6 Decomposição do repositório (L1264-1281)

| linha | afirmação | veredito | evidência |
|---|---|---|---|
| 1265-1269 | MANIFEST: 2 entrypoints, 41 binários, 89 fontes (80 `.src` + 8 em `lume/` + `runtime_core`), 2 stdlib | CONFIRMADA | contagem por prefixo: `lume` + `bin/lume`, 41 `build/bin`, 81 + 8 `compiler/stage1`, 2 `stdlib`; a lista dos 41 nomes bate |
| 1271 | tests 450, compiler 270, docs 139, bootstrap 121, examples 78, wiki 25, evolve 15, editors 13 | CONFIRMADA | `git ls-files` por diretório |
| 1272 | "200 `.src` em compiler/stage1" | DIVERGENTE | **199** `.src` versionados no primeiro nível (o `lumec.src` não é versionado) |
| 1274 | SEED_FREEZE.sha256 | CONFIRMADA | `bootstrap/lume0/SEED_FREEZE.sha256` |
| 1279 | `.github`: 11 workflows | **DIVERGENTE** | são 11 arquivos, mas só **4 workflows** (ci, codeql, linguist-grammar, release); o resto é template, CODEOWNERS e dependabot |
| 1279 | 22 check-runs + 4 release jobs | NÃO VERIFICÁVEL | o `ci.yml` do HEAD tem cerca de 18 chaves de job; matriz não analisada |
| 1280 | scripts: 11 utilitários de higiene (`.sh`) | DIVERGENTE (descrição) | são 11 arquivos, dos quais 9 são `.src` Lume e só 2 são `.sh` (`check-version-coherence.sh`, `lume_legacy.sh`) |
| 1281 | contrib 7, assets 7, skills 6, acceptance 6, stdlib 2, Formula 1, bin 1, grammar 1, .devcontainer 1, raiz 31 | CONFIRMADA | |

## 5. Lista consolidada de afirmações falsas ou divergentes

1. **S06 (L971):** o stdout esperado é `150 4500 120 9000 1 7 9 0 6`, não `150, 4500, 11, 29` (`synergy_gate.src`, `sy_demo_out`).
2. **S09 (L976):** os commits são 150, 4500 e **120**, não 9800 (`synergy_gate.src:209`).
3. **lproof_cache (L822, L860-864):** os domínios reais são `lume-fn-contract-v1`, `lume-callees-v1`, `lume-fn-body-v1`, `lume-proof-digest-v1`, `lume-proof-cert-seal-v1` e `lume-proof-cache-cert`; `lume-proof-cert-v1`, `lume-contract-v1`, `lume-body-v1`, `lume-fn-digest-v1` e `lume-proof-seal-v1` não existem.
4. **lcert (L879):** a renomeação é `?L<d>.`, não `?K<d>.`.
5. **ltv_rt (L913-914):** `__gc_pop_str`, `__gc_save`, `__gc_UN` e `__lume_trap_{div0,oom,stk,contract,bounds}` não existem. "Bignum de 2 limbs" é, na verdade, a aritmética wide do verificador. A divisão é truncada, não flooring.
6. **lsmt (L924):** não há `f_div`/`f_mod`/`f_shl`/`f_band`/`f_call_*` no código; os stand-ins são `f___bit_*`.
7. **lmcdc (L930):** o orçamento padrão é 6000, não 320.
8. **lqualify (L949-952):** os títulos de HLR divergem; "ISO 26262 ASIL D / TCL3" é falso; a ordem da cadeia SHA é probes → gates → modules → TCB → summary, não tcb → rtm → mcdc → gates → verdict; os rótulos camelCase dos gates (`bootstrapStage2EqualsStage3`…) não existem; G-TESTS é `lume_make test`, não as suítes de lstd/lchameleon/lsentience/kernels.
9. **lcaas_scale_gate (L845):** os controles `c_header_comments` e `oversize_cert_term` não existem; os reais são "shr-contract", "control-trunc" e "oversize-certificate".
10. **lchameleon (L1028):** são 65 leis, não 27, e portanto 198 declarações, não 160; são 98 `@bound`, não 114.
11. **Chameleon (L1050, L1062):** `cham_sql_fk_integrity_law` não existe; os 4 nomes de leis OTE estão errados.
12. **lstd (L1211-1212):** a divisão é 47 fn + 23 law (não há `pub fn`) e 7 testes, não 48 + 22 e 6; 13 nomes de funções listados não existem (`std_abs`, `std_min`, …, `decimal_clamp`).
13. **std.lume (L1214):** são 62 `pub fn` + 21 testes, não 58 + 25; `std_money_split_lo`/`hi` não existem.
14. **crypto.lume (L1215):** os 6 nomes de funções divergem dos reais.
15. **CLI (L1078-1079):** a tabela fica nas linhas 997-1111 (HEAD) ou 1010-1123 (árvore atual), não 1008-1121; o formato tem 8 campos, não 7. Os 114 nomes e handlers estão corretos.
16. **linteractive (L1203):** não tem `execute_request`.
17. **self-prove (L1218):** o lcert não é chamado; a certificação é só pelo lcaas.
18. **Repositório:** 199 `.src`, não 200; `.github` tem 4 workflows, não 11; `scripts/` não é composto de scripts `.sh` de higiene.
19. **Números só de divulgação:** "87.224 falhas" (L830, L945, L1243) aparece apenas em SVG e LUMELABS, sem respaldo no dossiê de qualificação nem no código. É NÃO VERIFICÁVEL; tratar como não comprovado.
20. **lumec.src (L820):** 10.634 / 3.177 não pode ser conferido no HEAD (arquivo gerado, não versionado); a árvore atual tem 10.642 / 3.184.

## 6. O que falta para o Windows ficar igual ao Linux

**Driver (`lume_driver.src`)**

- `ld_w12_native` (`:974`): passar `ld_host_cflags()` ao lumec. Hoje gera PE com `syscall` Linux.
- Dar a `-g`/`--dwarf` uma forma em PE (CodeView/PDB) ou recusá-los com diagnóstico no Windows.
- `ld_test_serial` (`:233`): `flock` só existe no Linux. Falta um lock nativo no Windows para os testes serializados (`mem_record_learning`).
- Entrada: as rotas legadas do shim não existem no Windows nativo e precisam de implementação nativa:
  - superfícies `.lume/.lbe/.intent` em build/check/test/run;
  - alvo `.wasm`;
  - `pkg ~publish/~audit`;
  - fmt fora de `.src`;
  - `self` com `LUME_HOME`.

**Ferramentas que compilam e executam (todas geram ELF)**

- `ltv @exec`;
- `lmcdc @exec`;
- `lsafety_envelope`, no canal A e no `split-run`, que usa `/bin/sh -c` em `:1266`;
- `linteractive` (`:57-58`);
- `lregistry` (`:~125`).

Solução comum: usar `--win64`/`--pe` conforme `os_platform()`, ou chamar `lume_driver build`.

**Comandos com programas externos**

- `economy`: `git` em `leconomy.src:96`; `timeout`.
- `self update`: `scripts/install.src:12-35`, onde cp/mkdir/chmod/sha256sum ainda são diretos.
- `make`: `bootstrap` (estágios ELF), `seed`/`test`/`asan` (`cc`, `lume_make.src:22`), `zero-c` (`as`/`cc`/`clang`, `zero_c.src:8,46`).
- `web-research`: `curl` em `lsentience.src:382`; o Windows tem `curl.exe` no System32.
- `reverse-engineer`: `sh` em `lsentience.src:441`; `7z` em `lume_reversa_engine.src:351,355`.
- `live-cockpit` e `os-control`: trocar o `/mnt/c/Windows/System32` fixo por `hio_win_system32()` (`lsentience.src:375`).
- `stack`: confirmar que o lstack aceita o `.s` com `call __win_syscall`.

**Gates (nenhum binário de gate foi construído para Windows)**

- **G-BOOT:** estágios PE e prova de stage2 == stage3 no Windows.
- **G-TESTS:** `cc` do seed. O `lume0.exe` existe; falta o caminho nativo.
- **G-SELFPROVE:** wave11, por causa do canal A em ELF.
- **G-LASM:** GNU `as`/`objcopy`/`objdump` (`lasm_gate.src:60-289`).
- **G-PFUZZ, G-REALTIME, G-TV, G-TVRT:** montam com lasm sem `--pe` e executam.
- **G-SOAK:** `sh`/`env`/`date`/`id`/`test`, `/proc`, uid 0 (`soak_battle_gate.src:156-300`).
- **G-ENV:** `sh` em `safety_envelope_gate.src:396`; canal A em ELF; qemu.
- **G-AUDIT:** `sh`/`clang`/`cc` (`claude_audit_gate.src:17,171-177`).
- **G-DWARF-CACHE:** readelf/nm/addr2line e DWARF (`dwarf_cache_gate.src:44-46`).
- **G-CONC:** `lconcurrency.src:274`, com `/bin/sh` e workers bifurcados.
- **G-CRYPTO, G-CERTSRC, G-CLI:** sem dependência POSIX identificada; falta construir e rodar.
- **G-MARCH:** clang, `as` cruzados, qemu, readelf e sh (`multi_arch_gate.src:58-173`).
- **G-SAFETENSORS:** sh, tail, sha256sum e python3 (`safetensors_gate.src:71,126-127`).
- **G-SMT:** sh, ln e timeout (`smt_cert_gate.src:93,271`).
- **G-SCALE:** `/usr/bin/time` para o max RSS (`lcaas_scale_gate.src:221`).
- **G-SYNERGY:** readelf/nm/addr2line e qemu (`synergy_gate.src:194,327`), S06 com DWARF, S09-SPLIT e S09-ISA com qemu.
- **lqualify:** env, readelf, z3, qemu, date e uname (`lqualify.src:163,189,272,280,521,610,616`); assinatura com a chave em `/root/.lume/keys`; pacote de evidência separado para Windows (doc 42 §5).
