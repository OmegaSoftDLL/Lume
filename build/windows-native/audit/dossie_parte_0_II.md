# Auditoria do dossiê: linhas 1 a 411 (Visão geral, Parte I, Parte II)

Dossiê auditado: `C:\Users\Ricardo.Bueno\LUME_DOSSIE_REVERSA_COMPLETO_BIT_A_BIT_PT_BR.md`, linhas 1 a 411, lidas na íntegra.
Observação: durante a auditoria o arquivo do dossiê **sumiu do disco** (foi movido ou apagado por outro processo). A leitura completa das 411 linhas foi feita antes disso, e as citações abaixo vêm dela.

**Arquivo novo (substituto).** O dossiê foi trocado por `C:\Users\Ricardo.Bueno\LUME_CATALOGO_COMPLETO_IMPLEMENTADO_E_TESTADO_PT_BR.md` (2.772 linhas). Comparei o novo trecho, linhas 1 a 415, com o que eu tinha lido:
- Mudou só o cabeçalho, linhas 1 a 6. O título passou a ser "Especificação Técnica Oficial & Catálogo Completo". Entraram linhas de autoria e o repositório `https://github.com/OmegaSoftDLL/Lume` (confere com `git remote`: `OmegaSoftDLL/lume`). O escopo agora inclui também "220+ builtins, 266 leis, 18.857 funções, 409 arquivos de teste", que são as Partes IX a XI, fora deste trecho.
- Do §0 em diante o texto é **idêntico**, com deslocamento de **+4 linhas**: a linha N do antigo é a linha N+4 do novo. Por exemplo: a tabela §0.1 está em 31-43, o TOTAL em 99, a tabela §2.1 em 187-199, o mapa `freef` em 224-232, o catálogo em 291-411 (#121 W0064 em 411) e a Parte III começa em 415.
- Nenhuma das afirmações falsas ou divergentes abaixo foi corrigida no texto novo. Conferi uma a uma por busca: `10.674.828` (34), `Árvore Git limpa` (34), `305 | 9.932` (158), `@gc`/`@soa` (227), `VSig(nm` (219), `pat_scrutinee_safe` (193, 249), `prover_farkas_dual_rhs_sum` (279), `3037000000` (280, 282), `Mach-O64` (65), `518-536` (250), "deslocamento aritmético" (270), "Hindley-Milner (`[T0300]`)" (194), "verificação freestanding [W0064]" (196), `lumec.src:4689` (376, 378), totais 10,482 / 964,123 (199).
- As tabelas abaixo usam a **numeração do arquivo antigo**. Para localizar no novo, some 4 (a partir da linha 7).

Repositório: `C:\Users\Ricardo.Bueno\lume`, branch `windows-native-toolchain`, `HEAD = 2916735192bf95f7f8fa5068438d628743606de1` (é o `origin/main` citado; a tag `v1.1.0` aponta mesmo para `abf32840c7164cd41b400a930fa1ac72fad87cb2`).

**Base da verificação.** A árvore de trabalho está **suja e sendo alterada ao vivo** pelo porte Windows: 22 arquivos modificados no início da auditoria, mais de 40 no fim, e há um `compiler/stage1/hostio.src` não rastreado. Por isso, a referência é o `HEAD` (via `git show HEAD:`), e a árvore de trabalho (WT) aparece quando o dossiê claramente a usou. Vários números do dossiê não batem com nenhuma das duas: por exemplo, bytes de `05_codegen.src`, `06b_phase3.src` e `name_flow.src`. Ou seja, o dossiê foi gerado a partir de um **instantâneo intermediário da WT**, nem `HEAD` nem o estado atual.

Vereditos: **CONFIRMADA** (o código bate) · **CONF-DOC** (o número só existe em README, PROJECT_STATE ou evidências e não foi reexecutado aqui; é coerente com a documentação) · **DIVERGENTE** (existe, mas o número ou detalhe difere; o valor real está indicado) · **FALSA/INEXISTENTE** (não há código) · **NÃO VERIFICÁVEL**.
Coluna Windows: **OK** (sem dependência de SO ou já portado) · **PENDENTE** (diz o que falta) · **N/A**.

---

## Seção 0: cabeçalho e §0.1 (linhas 1 a 39)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 4 | `origin/main @ 2916735…`, `v1.1.0 @ abf3284…` | CONFIRMADA | `git rev-parse HEAD`, `git rev-parse v1.1.0^{commit}` | OK |
| 4 | "34+ alvos", "118 kernels", "17 estágios + 36 tampers", "9 ecossistemas", "114 comandos", "122 domínios" | CONF-DOC | README.md:57-59, 321, 341, 533, 536 | ver as partes IV a VII (fora deste trecho) |
| 29 | Versão v1.1.0 (CHANGELOG, PROJECT_STATE) | CONFIRMADA | CHANGELOG.md:353 `## [1.1.0] - 2026-11-08` | OK |
| 30 | 1.196 arquivos rastreados | CONFIRMADA | `git ls-files \| wc -l` = 1196 | OK |
| 30 | 237.638 linhas | DIVERGENTE | `wc -l` sobre os blobs de HEAD = **180.759** linhas. Dentro do próprio dossiê o número já é inconsistente: a linha 95 diz 237.649 | N/A |
| 30 | 10.674.828 bytes | DIVERGENTE | soma dos blobs de HEAD = **27.885.212 B**. A linha 95 do dossiê diz 27.972.945 B: contradição interna | N/A |
| 30 | "Árvore Git limpa (0 modificados)" | DIVERGENTE / NÃO VERIFICÁVEL | hoje há mais de 40 modificados e 1 não rastreado (porte Windows). No momento do dossiê também já não estava limpa, como mostram os números colhidos da WT | N/A |
| 31 | SHA-256 do ponto fixo `2a32911e…86e6` | CONFIRMADA | `sha256sum build/bin/lumec build/bootstrap/lumec1 lumec2 lumec3` dá o mesmo hash nos quatro; MANIFEST.sha256:7; AGENTS.md:18 | PENDENTE: o hash é do ELF Linux. Não existe ponto fixo PE32+ (`--win64`) registrado |
| 31 | Wheeler DDC `cc` vs `clang` | CONFIRMADA (com ressalva) | tests/harness/claude_audit_gate.src:166-171 (`cag_ddc_diverse`). A comparação é feita sobre `stage1_lumec` | PENDENTE: precisa de `/usr/bin/clang`, `cc`, `/bin/sh` e `sha256sum` |
| 31 | Fonte: 07_driver.src, lume_make.src | DIVERGENTE | o ponto fixo está em `scripts/bootstrap.src:41-47` (`bs_stages`, `bs_fixpoint`), não em 07_driver | — |
| 32 | 16 baterias, 1.682 obrigações, 0 runtime/refutadas, 372 testes, 122 domínios | CONF-DOC | README.md:321, 536. A evidência do `lqualify` mostra outra campanha: `obligations_proven 668`, `budget_checked 416` (docs/certification/QUALIFICATION_EVIDENCE.json) | PENDENTE: o `self-prove` roda o compilador (OK), mas as baterias que executam ELF não rodam |
| 33 | ltv: 694 funções validadas, 0 rejeitadas | CONFIRMADA | QUALIFICATION_EVIDENCE.json `functions_translation_validated:694, functions_rejected:0` (e `functions_outside_fragment:3`, que o dossiê omite) | PENDENTE: o ltv lê ELF, e o desempate usa `/usr/bin/z3` e `/usr/bin/cvc5` (ltv.src) |
| 33 | 687/687 correlações, 18/18 helpers, 100 % unsat | CONF-DOC | README.md:57; PROJECT_STATE | PENDENTE (ELF, z3) |
| 34 | MC/DC 0/9.618 descobertos (980 + 112 + 2.392 + 6.134) | CONFIRMADA | evidência `mcdc_obligations:9618, mcdc_uncovered:0`; a soma das parcelas fecha em 9.618 | PENDENTE: as testemunhas nativas executam ELF |
| 35 | 2oo2D: 0/3.169 funções, 87.224 falhas | CONF-DOC | README.md:45-57 | PENDENTE (gates com ELF) |
| 36 | 118 kernels CT, lstack ≤ 536 B, dudect 24/24 \|t\| ≤ 2.690, X.509 6.000/6.000 | CONF-DOC | README.md:59, 341, 343 | OK para compilar os kernels; PENDENTE para medir dudect, ltv e lstack (ELF) |
| 37 | 17/17 estágios + 36/36 tampers; 114 linhas de CLI / 226 nomes | CONF-DOC | README.md:533; tests/harness/synergy_gate.src existe | PENDENTE: o synergy-gate encadeia ferramentas ELF |
| 38 | 31,8×, 2.733×, 445 ms / 115 MB | CONF-DOC | docs/39-memory-saga-and-atomic-compactor-dossier.md | OK em memória (compactador nível 3 verificado igual ao Linux). Os tempos não foram medidos no Windows |
| 39 | qualify PASS: 10 HLR, 44 LLR, 106/106 probes, 21/21 gates, Ed25519 + X.509 DER | CONFIRMADA | QUALIFICATION_EVIDENCE.json `probes 106/106, gates 21/21, hlr 10, llr 44`; lqualify.src tem 10 `q_h("HLR-…")` e 44 `q_l("LLR-…")` | PENDENTE: o lqualify executa ELF e ferramentas Linux |
| 32-39 | todos os arquivos-fonte citados existem | CONFIRMADA | `git cat-file -e HEAD:<arquivo>` OK nos 20 citados | — |

## §0.2: diagrama (linhas 41 a 69)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 46 | sementes `*.c` C11; `lume0 check/run/emit-asm/asm` | CONFIRMADA | bootstrap/lume0/main.c:43-112 | PENDENTE: a semente é C e só roda como lume0 Linux ou lume0.exe |
| 47 | `compiler/stage1/*.lume` (lexer, layout, data_parser, data_asmgen) | CONFIRMADA | arquivos existem | OK (via semente) |
| 51 | `lumec.src` com 10.634 linhas | DIVERGENTE | `lumec.src` é derivado e **não é rastreado**. A WT atual tem 10.642 linhas | OK |
| 51 | "01..07 + own_flow + name_flow → amalgamate" | CONFIRMADA (ver ressalva em §1.3) | scripts/amalgamate.src:1 | OK |
| 52-54 | lume0 → lumec1 → lumec2 → lumec3 | DIVERGENTE | bootstrap.src usa lumec0 (semente, **ou cópia de `build/bin/lumec` se ela existir**, bootstrap.src:31-32) → lumec1 → lumec2 → lumec3 | PENDENTE |
| 55 | runtime: palavra de 64 bits, GC com 43 classes, LZ1, Win64 | CONFIRMADA / DIVERGENTE | 43 classes: docs/38. "Win64" (`__win_syscall`) **só existe na WT** (runtime_core.lume, não commitado) | OK no WT |
| 59 | lcaas QF_LIA/QF_NIA/CEGIS/MCP | CONFIRMADA | lcaas.src: 39 ocorrências | OK |
| 60 | lcert com 0 imports + `--check-source` | CONFIRMADA | lcert.src: 0 linhas `use`, 9 ocorrências de `--check-source` | OK |
| 61 | lasm: ELF64 / PE32+ / Mach-O64, VEX/EVEX, DWARF v4 | DIVERGENTE | lasm@HEAD: ELF64, VEX, EVEX e DWARF 4 sim. **Mach-O: 0 ocorrências** (o escritor Mach-O e PE fica em `ltarget.src`). PE32+ via `lasm --pe` **só na WT** | PE: OK (porte). DWARF→PDB: PENDENTE |
| 63 | lsmt QF_UFNIA clean-room | CONFIRMADA | lsmt.src: 6 ocorrências | OK (não precisa de z3) |
| 64-67 | lstack, lmcdc, lsafety_envelope, lqualify | CONFIRMADA (existência) | arquivos existem | PENDENTE (ELF) |

## §0.3: radiografia por diretório (linhas 71 a 95)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 75-94 | número de arquivos por diretório (docs 139, compiler 270, root 31, wiki 25, assets 7, tests 450, bootstrap 121, scripts 11, examples 78, editors 13, .github 11, skills 6, acceptance 6, stdlib 2, evolve 15, contrib 7, grammar 1, bin 1, Formula 1, .devcontainer 1) | CONFIRMADA | `git ls-tree -r HEAD`: os 20 batem | N/A |
| 75-94 | linhas por diretório | DIVERGENTE (parcial) | batem compiler (51.487 contra 51.488), tests 10.503 (contra 10.505), bootstrap 8.706 e scripts 3.692. Divergem docs (**50.118** contra 72.838), wiki (**15.353** contra 25.023), assets (**12.990** contra 23.133) e root (**18.948** contra 32.615) | N/A |
| 75-94 | bytes por diretório | DIVERGENTE (leve) | HEAD: compiler 5.655.645 (o dossiê diz 5.733.742), docs 9.052.873 (9.053.691), root 4.145.300, scripts 182.785, .github 60.776, tests 1.535.070. Os demais batem | N/A |
| 95 | total: 237.649 linhas, 27.972.945 B | DIVERGENTE | HEAD: 180.759 linhas e 27.885.212 B | N/A |

## Parte I: §1.1, semente e SEED_FREEZE (linhas 99 a 146)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 104 | nenhuma funcionalidade nova em C (`#205`) | CONFIRMADA | AGENTS.md:56; PROJECT_STATE.md:206 | N/A |
| 104 | sementes travadas por SEED_FREEZE e gate de CI | CONFIRMADA | claude_audit_gate.src:169 (`sha256sum -c`), lqualify.src:184 (`q_do_seed`), zero_c.src:13 | PENDENTE: o gate usa `sha256sum` e `/bin/sh`. O `q_do_seed` em Lume é portável, mas o lqualify inteiro não roda |
| 106 | DDC: semente compilada por gcc/cc e clang **com** `-std=c11 -O2 -Wall -Wextra -Werror -Wconversion -Wpedantic -Wshadow` | DIVERGENTE | o build do DDC usa **só** `-std=c11 -O2` (claude_audit_gate.src:169). As flags estritas estão no Makefile, que também tem `-Wno-sign-conversion` (omitido no dossiê) | PENDENTE (cc, clang) |
| 106 | DDC no domínio `#111` | NÃO VERIFICÁVEL aqui | Parte VII | — |
| 112-127 | linhas e bytes dos 16 arquivos da semente | CONFIRMADA | os 16 batem exatamente com `git show HEAD:` + `wc -lc` | N/A |
| 117 | interp.c: interpretador tree-walk | CONFIRMADA | arquivo e papel | PENDENTE (C) |
| 121 | main.c: `check, run, emit-asm, asm, describe --json` | CONFIRMADA | main.c:43-112 (tem também `tokens` e `parse`) | PENDENTE |
| 122 | Makefile: alvos `test` (410/410) e `asan` (170/170 ASan+UBSan) | DIVERGENTE / CONF-DOC | os alvos existem (`test` → `test-legacy` → `tests/run.sh`; `asan` → `asan-legacy`), mas as contagens não estão no Makefile. "170 passed" vem de docs/39:57, 184. Os relatórios de auditoria dizem "170 aprovados, 0 falhas, **3 pulados**" | PENDENTE (cc, sanitizers) |
| 126 | Value de 64 B (antes 200 B) + mark-sweep | CONF-DOC | docs/39:57 | N/A |
| 133-146 | 14 hashes SHA-256 congelados | CONFIRMADA | `sha256sum` dos arquivos = SEED_FREEZE.sha256 = dossiê, nos 14 | OK (os hashes são estáveis; os arquivos estão com LF) |

## Parte I: §1.2, pipeline `.lume` e wrapping (linhas 148 a 163)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 150 | despacho `LUME_FORCE_SEED=1`, semente em hosts não ELF | CONFIRMADA | scripts/lume_legacy.sh:79 (o nativo só roda em Linux x86_64 sem `LUME_FORCE_SEED`) | PENDENTE: no Windows nativo a semente só roda via lume0.exe |
| 154 | lexer.lume: 305 linhas, 9.932 B | DIVERGENTE | **69 linhas, 2.319 B** | — |
| 155 | layout.lume: 189 / 6.879 | DIVERGENTE | **160 / 6.068** | — |
| 156 | data_ast.lume: 96 / 2.662; tipos DExpr, DStmt, DPat | DIVERGENTE (números) | **43 / 1.173**. DExpr e DStmt existem (data_ast.lume:8+) | — |
| 157 | data_parser.lume: 711 / 25.636; operadores `+%` | DIVERGENTE (números) | **593 / 25.892**. `+%` confirmado (data_parser.lume:62) | — |
| 158 | data_eval.lume: 418 / 15.920 | DIVERGENTE | **754 / 32.324** | — |
| 159 | data_codegen.lume: 184 / 6.809, "camada de abaixamento intermediário" | DIVERGENTE | **8 linhas / 320 B**: só reencaminha para `agen()` de data_asmgen | — |
| 160 | data_asmgen.lume: 751 / 27.641, `use runtime_core`, `out: [str]` | DIVERGENTE (bytes) | 751 linhas confirmadas, **33.684 B**. `use runtime_core` (:10) e `out: [str]` (:110) confirmados | — |
| 163 | `+% -% *%` nativos via `__rt_wadd/__rt_wsub/__rt_wmul` | CONFIRMADA | runtime_core.lume:81; 05_codegen.src:368 (`lbin_rt`) | OK |
| 163 | data_eval decompõe em **4 limbs de 16 bits** | DIVERGENTE (parcial) | `w64_add` e `w64_sub` usam um corte **48 + 16 bits** (`w64_lo48`/`w64_hi16`); só `w64_mul` usa 4 limbs de 16 bits (data_eval.lume:362-400). O objetivo de evitar UB está confirmado | OK |
| 163 | `make asan` → 170/170 no Linux e no macOS | CONF-DOC (Linux) / NÃO VERIFICÁVEL (macOS) | docs/39:184 | PENDENTE |

## Parte I: §1.3, ponto fixo (linhas 165 a 172)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 167 | amalgamação concatena `runtime_core.lume`, `own_flow`, `name_flow`, `01..07`, nessa ordem | DIVERGENTE | ordem real (scripts/amalgamate.src:1): 01, 02, 03, 04, **runtime_core**, 05, 06, **own_flow, name_flow**, 06b, **06c_phase4, 06d_phase5**, 07. **06c e 06d não existem** no repositório (lista morta; `fs_read_file` devolve vazio) | OK |
| 168 | estágio 1: a semente compila lumec.src → lumec1, "com vestígios da semente" | DIVERGENTE | o estágio da semente gera **lumec0**. Quando `build/bin/lumec` existe, ele é **copiado** como lumec0, sem passar pela semente (bootstrap.src:31-32, `bs_seed_tool`). No build atual `lumec1 == lumec2 == lumec3` (mesmo SHA): não há "vestígios" | PENDENTE |
| 169-170 | lumec2 e lumec3 via lasm nativo, sem C e sem GNU as/ld | CONFIRMADA | bootstrap.src:38-47 | OK (lumec + lasm rodam no Windows), mas o bootstrap.src@HEAD usa `/bin/cp` (a WT troca por `hio_run_capture`) |
| 172 | SHA(lumec) = SHA(lumec2) = SHA(lumec3) = 2a32911… | CONFIRMADA | sha256sum de build/bin/lumec e build/bootstrap/lumec{1,2,3} | PENDENTE: falta registrar um ponto fixo PE32+ |

---

## Parte II: §2.1, módulos do compilador (linhas 179 a 195)

Contagens: linhas/bytes de `git show HEAD:` e da WT atual; funções por `^(pub |total |async |extern )*fn `.

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 181 | edita-se só os módulos; `lumec.src` é derivado | CONFIRMADA | lumec.src não é rastreado (`git ls-files`) | OK |
| 185 | 01_lexer 183 / 24.590 / 99 fns; `slicen`, `0x/0b/0o`, `[L0002..L0004]` | CONFIRMADA | números exatos. L0002 (:41), L0003 (:20-24), L0004 (:65) | OK |
| 186 | 02_parser 127 / 19.757 / 74; `\|>`, comparações que não encadeiam `[P0002]`, `isbadholech`, `isjsblock`, `strplainchunk` | CONFIRMADA (exceto `{x:04x}`) | números exatos. P0002 "comparisons do not chain" confirmado. `\|>` funciona (`lume run` de `3 \|> f(4)` imprimiu 7). O especificador `{x:04x}` não aparece no parser (só em `win64_gui_and_interp_regression_ok.src` e no claude_audit_gate) | OK |
| 187 | 03_comptime 453 / 36.535 / 173; `quote`, `unquote`, `splice`, `_hyg_`, `C0271`, `C1001` | CONFIRMADA | números exatos. C0271 (:289), C1001, `chygiene` | OK |
| 188 | 04_parser_decls 721 / 74.606 / 254; P0004, `expand_prog_sugar`, `invariant`, `terminates` | CONFIRMADA | números exatos. `resource type` só aparece em own_flow (o parser trata `resource` como declaração de tipo) | OK |
| 189 | 05_codegen 975 / 130.957 / 367 | DIVERGENTE (bytes) | HEAD 130.867 B; WT 130.977 B. Linhas e funções batem | OK |
| 189 | camada `--win64` no 05_codegen | DIVERGENTE | **não existe em HEAD**. Na WT, `--win64` está em 07_driver.src:375-392 e runtime_core (`__win_syscall`), não no 05 | OK (WT) |
| 189 | inteiros imediatos 2n+1, SSO ≤ 7 B `…010`, `jo __rt_ovf` em `+ - *` | CONFIRMADA | 05_codegen.src:146 (`lfits63b`); runtime_core.lume:81 (addv/__rt_sub/__rt_mul com `jo __rt_ovf`). O `jo` fica no **runtime**, não no codegen | OK |
| 189 | SRA `lsra_expr` | CONFIRMADA | 05_codegen.src:478-528 | OK |
| 189 | reuso Perceus `pat_scrutinee_safe` | FALSA (nome) | `pat_scrutinee_safe` não existe no repositório. O portão real é `pu_*` em 06b_phase3.src:3260-3310 | OK |
| 189 | lowering CT `ct_select`/`ct_eq` | CONFIRMADA | 05_codegen.src:620-718 (`lct_*` de :645 a :718) | OK |
| 189 | SIMD VEX/EVEX (AVX2/AVX-512) | DIVERGENTE | o codegen emite **só AVX2** (`vmovdqu/vpaddq %ymm`, `simd_add4_i64`…). Não há `zmm`/EVEX no 05; EVEX existe só no codificador do lasm | OK (Win64 preserva só ymm6-15 parcialmente; o código usa ymm0/1 + `vzeroupper`) |
| 189 | syscalls io_uring 425..427 | CONFIRMADA | 05_codegen.src: `movq $425/$426/$427, %rax` | PENDENTE: io_uring retorna -ENOSYS no Windows |
| 189 | DWARF v4 (`-g`) | CONFIRMADA (local diferente) | as diretivas `.loc/.file` vêm de 07_driver.src:357-371 (`--dwarf`), e o lasm gera `.debug_line/.debug_info` (DWARF 4) | PENDENTE: DWARF→PDB |
| 189 | `--critical` | CONFIRMADA | 06b_phase3.src:4343-4347 | OK |
| 190 | 06_typecheck 1.257 / 97.171 / 402; T0601..T0607 | CONFIRMADA | números exatos. T0601 em :101, T0602 em :153 etc. | OK |
| 190 | "inferência Hindley-Milner (`[T0300]`)" | DIVERGENTE | T0300 é **forma de tensor** (06b_phase3.src:2892, 2955). A unificação HM é **T0500** (06_typecheck.src:812) | OK |
| 190 | exaustividade de enum `[T1002]`, registros nominais `[T1003]`, `[T3001]` no 06_typecheck | DIVERGENTE | T1002 é emitido em **name_flow.src:190, 196**. T1001/T1003/T3001 **não aparecem em nenhum módulo do lumec**: só no serviço `lcaas.src:768-808`. O lumec emite esses erros **sem código** (06_typecheck.src:615-636 "type error: record type … is not declared") | OK |
| 191 | 06b_phase3 5.344 / 461.474 / 1.345 | DIVERGENTE (bytes) | HEAD 461.356 B; WT 461.495 B. Linhas e funções batem | OK |
| 191 | O0001..O0030, A0001-3, E0200, E0210, E0305, E0306, C0009, C0011, V0002, T0400..T0403 no 06b | CONFIRMADA (exceto T0402/T0403) | todos têm ocorrência no 06b. **T0402/T0403 estão no 04_parser_decls.src:526-528** | OK |
| 191 | provador QF_LIA (Fourier-Motzkin) + QF_NIA "quadrático de Horner" | DIVERGENTE | Fourier-Motzkin confirmado (06b:1510). QF_NIA é "Positivstellensatz / monotonicidade" (06b:1680). **"Horner" não aparece no provador**, só em lchameleon/lstd/stdlib (funções de biblioteca) | OK |
| 192 | 07_driver 394 / 38.983 / 138 | DIVERGENTE (base) | bate com a **WT** (não commitada). Em HEAD: **376 / 36.215 / 126** | OK |
| 192 | SHA-256 FIPS 180-4 da AST (`--ast-hash`), `--module`, `--link` | CONFIRMADA | 07_driver.src:15-19, 354, 393 | OK |
| 192 | "verificação freestanding (`[W0064]`)" | FALSA/DIVERGENTE | W0064 **não existe em HEAD**. Na WT (07_driver.src:379, 392) significa "`--win64` precisa de programa hospedado (imagem `.kernel` não tem forma Windows)", não verificação freestanding | OK (é do porte) |
| 193 | own_flow 672 / 42.192 / 176; `rid`, NLL, O0001..O0021 | CONFIRMADA (parcial) | números exatos. NLL: "live loans … last use" (:302). O próprio own_flow cita só **O0004 e O0013**; os demais são emitidos no 06b | OK |
| 194 | name_flow 356 / 37.858 / 115; D0002-4, R0201..R0205, O(n log n) | DIVERGENTE (bytes) | HEAD 37.632 B; WT 37.940 B. Os códigos D0002-4 e R0200-5 estão confirmados; "n log n" em :242 | OK |
| 195 | total 10.482 linhas / 964.123 B / 3.143 fns | DIVERGENTE (base) | a soma bate com o instantâneo misto. HEAD = **10.464 linhas / 961.271 B / 3.131 fns** | OK |

## §2.2: AST, `freef`, interpolação e higiene (linhas 197 a 232)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 201-209 | construtores Num, Str, Var, Bin, If, LetIn, VarIn, Call, Rec, RecT, Field, Match, LambdaE(ps,tys,rt,body), OwnE, MutE, CT, AwaitE, SpawnE, ScopeE(snm,b); padrões PWild, PInt, PStr, PBind, PCons | CONFIRMADA | todos aparecem como braço de `match` nos módulos (por exemplo `LambdaE(ps, tys, rt, b) =>`). A lista omite `ShardE(vnm, lo, hi, b)` | OK |
| 205 | `x \|> f(a,b)` vira `Call("f", x::a::b)` | CONFIRMADA (funcional) | teste `3 \|> f(4)` = 7 | OK |
| 211 | `Fn(nm, items, body)` | CONFIRMADA | `Fn(fnm, ps, body)` | OK |
| 212 | `Sig(nm, paramnames, paramtypes, rettype)` | CONFIRMADA | `Sig(nm, ps, ts, rt)` | OK |
| 213 | `GSig(...)` com `cf = 1` | CONFIRMADA | `GSig(nm, pl, rt)`, 04_parser_decls.src:55-58 | OK |
| 214 | `OSig(nm, pubf, freef, pl, rty, fromp)` | CONFIRMADA | 04_parser_decls.src:39 | OK |
| 215 | `VSig(nm, params, reqs, enss, wcet, term_measures)` | FALSA (forma) | **não existe `VSig`**. São três construtores: `VContractSig(nm, ps, reqs, enss)` (04:43), `WcetSig(nm, bound)` e `VTermSig(nm, ps, ms)` | OK |
| 218 | atributo desconhecido → `[P0004]` com sugestão Levenshtein | CONFIRMADA | 04_parser_decls.src:100-122 (`attr_hint`, `attr_near`) | OK |
| 222 | bit 0 (1) = `@freestanding`; O0030; `.kernel` "validado por [W0064]" | CONFIRMADA / DIVERGENTE | bit 1 = freestanding (06b:20 `ois_free`). A ligação com W0064 é falsa (ver linha 192) | N/A (`.kernel` não tem forma Windows) |
| 223 | bits 1..6 (2..64) = `@interrupt, @export, @protect, @gc, @soa, @schedule` | **FALSA** | mapa real (06b_phase3.src:20-30; 04_parser_decls.src:123-134): **2 = `total fn`**, **4 = `llm`/`extern fn`**, **8 = kernel**, **16 = @interrupt**, **32 = @export/FFI**, **64 = @protect**. `@gc` e `@soa` são **tipos** (`gc type`, `soa type`), não bits de `freef`; `@schedule` não é bit | OK |
| 224 | bit 7 (128) = `@secret`; taint C0009; bloqueia LZ1 (Decomp+Time) | CONFIRMADA | 04:123; 06b:4221-4264 (`cz_fail`: "would compress secret data … (Decomp+Time)") | OK |
| 225 | bit 8 (256) = `async fn`; promise com tag 13 | CONFIRMADA | 04:40 e :134; 06b:28-30; runtime_core.lume:56 "13 promise" | OK |
| 226 | bit 9 (512) = `@no_alloc`; requires em todos os parâmetros, prova de 63 bits, só cauda | CONFIRMADA | 06b_phase3.src:4716-4730 | OK |
| 227 | 640 = modo CT [C0011]: proíbe requires, if, match, `/`, `%`, recursão | CONFIRMADA | 06b_phase3.src:4845-4858 | OK |
| 228 | `wcet > 0` = `@bound`, [V0002]; proíbe compactação LZ1 | CONFIRMADA (exceto LZ1) | 06b:3131-3138. A proibição de LZ1 sob `@bound` não foi encontrada no código | OK |
| 231 | `strplainchunk` com `slicen`, `isbadholech`, `isjsblock`, `{x:04x}`, R0200 nos buracos | CONFIRMADA (exceto `{x:04x}` no parser) | 02_parser.src; `findcolon` em parsehole (:43) trata o especificador | OK |
| 232 | `quote`/`unquote`/`splice`, `_hyg_<step>_<name>`, `chygiene` | CONFIRMADA | 03_comptime.src (`_hyg_` 6×, `chygiene` 5×) | OK |

## §2.3: tipos, ownership, Perceus, SRA (linhas 234 a 247)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 237-238 | modo dinâmico sem `type`; com `type` liga T1001, T1002, T1003 | DIVERGENTE (códigos) | o comportamento existe (06_typecheck.src:615-636, `tt.decl == 1`), mas o lumec emite **sem código**. T1001/T1003 só no lcaas | OK |
| 239 | regra estrita §19.5: T0601..T0607 | CONFIRMADA | 06_typecheck.src:29-32, 99-154 | OK |
| 240 | traits T0400..T0403, despacho monomórfico | CONFIRMADA | 06b:3706-3806; 04:526-528 | OK |
| 242 | `rid` e move preservando campos irmãos [O0001] | CONFIRMADA | own_flow.src (18 ocorrências de `rid`) | OK |
| 243 | NLL [O0011]/[O0013], [O0002], [O0020]/[O0021] | CONFIRMADA | own_flow.src:302; 06b (códigos) | OK |
| 244 | `resource type` linear [O0004]; `defer`/`errdefer` | CONFIRMADA (O0004) | own_flow.src cita O0004 | OK |
| 245 | Perceus: todos os pontos de chamada passam valor profundamente único (`pu_uses <= 1`) e `pat_scrutinee_safe` | CONFIRMADA / FALSA (nome) | 06b:3260-3310 ("EVERY call site … deeply unique"). `pat_scrutinee_safe` **não existe** | OK |
| 246 | `lsra_expr` em 05_codegen.src:518-536 | DIVERGENTE (faixa) | família `lsra_*` em **478-528**; `fn lsra_expr` em **:528** | OK |
| 247 | heap do registro = 0 bytes | NÃO VERIFICÁVEL estaticamente | — | OK |

## §2.4: efeitos, @no_alloc, concorrência, CT (linhas 249 a 267)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 251 | `/ pure` [E0200], transitivo sem limite de profundidade | CONFIRMADA | 06b:476-486: `kdepth() = 2` com marcador `?deep` que cai em `kreach` (fecho completo do grafo) | OK |
| 254 | prova de \|t\| ≤ 2^40 e depois ≤ 2^62; `.Lrt_mkint_box` | CONFIRMADA | 06b:4747 (`na_range` com 1099511627776 = 2^40); runtime_core (`jo .Lrt_mkint_box`) | OK |
| 255 | proíbe strings, listas, registros, closures, não-@no_alloc, recursão fora da cauda; `na_chk` em `--critical` | CONFIRMADA | 06b:4716-4728; `na_chk` 3× | OK |
| 257 | `chan_send_linear` [E0305] | CONFIRMADA | 06b:5019-5072 | OK |
| 258 | `lock_acquire/release(rank)` crescente, `actor_link` acíclico [E0306] | CONFIRMADA | 06b:5193-5200 | OK |
| 259 | [C0011] em 05_codegen.src:625-715 e 06b:4845-4995 | CONFIRMADA (faixas aproximadas) | `lct_*` 645-718; `cti_*` 4947-4981 | OK |
| 260 | `@secret` com `+` genérico é recusado pelo ltv com [C0010] | CONFIRMADA | lqualify.src:338 (LLR-SEC-02), :140 (probe `ctadd` → `[C0010]`) | PENDENTE: o ltv lê ELF |
| 262 | palavras imediatas `w = 2v+1` | CONFIRMADA | 05_codegen.src:642-643 | OK |
| 264-265 | `ct_select = wb ^ ((wa ^ wb) & wm)`, as tags se cancelam | CONFIRMADA | 05_codegen.src:621, 643 | OK |
| 266 | `ct_eq` = `xorq` + `negq/sbbq` ou **deslocamento aritmético** de 63 bits | DIVERGENTE | real: `x = wa^wb; (x \| -x) >>logical 63; xorq $1` (05:620, 642). O deslocamento é **lógico**, não aritmético, e não há `sbbq` | OK |
| 267 | análise intervalar `cti_*` em [-2^62, 2^62-1] | CONFIRMADA | 06b:4858-4870, 4947-4981 | OK |
| 267 | "ltv confirma zero desvios no ELF" | CONF-DOC | ltv.src | PENDENTE (ELF; validar o PE seria trabalho novo) |

## §2.5: provador "OmniProof-v4" (linhas 269 a 281)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 271 | motor em 06b_phase3 + lcaas, checagem independente em lcert/lsmt | CONFIRMADA | arquivos e funções | OK (o desempate do ltv com z3/cvc5 fica PENDENTE) |
| 271 | nome "OmniProof-v4" | CONF-DOC | aparece só em lmanual, lproof_cache e lume_driver (marca), não no provador | — |
| 273 | Fourier-Motzkin sobre ¬C | CONFIRMADA | 06b:1510-1551 | OK |
| 274 | obrigações de ausência de trap nas cláusulas | CONFIRMADA | 06b:2250-2261 | OK |
| 275 | certificados de Farkas `prover_farkas_dual_rhs_sum` | **FALSA (atribuição)** | a função existe só em **lchameleon.src:522** (e lmanual): é um kernel de biblioteca de 4 inteiros, não parte do provador. Não há certificado de Farkas em 06b, lcaas, lcert ou lsmt | — |
| 277 | Horner `ast_native_horner_quadratic_eval` e completar quadrados | **FALSA (atribuição)** | a função existe só em lchameleon.src:686, lstd e stdlib/std.lume (função de domínio). O provador usa Positivstellensatz e quadrados (06b:1680-1714) | — |
| 278 | guarda `3037000000` | DIVERGENTE | o provador usa **3037000499** (06b:1714; lcaas; lcert). O número 3037000000 não aparece no código | OK |
| 280 | octógonos `prover_octagon_transitive_upper` | **FALSA (atribuição)** | só em lchameleon.src:447, lstd e stdlib (kernel de biblioteca). O provador não tem domínio de octógonos | — |
| 280 | `x << k` (QF_BV), `terminates` lexicográfico [A0002], `always` [V0005] | CONFIRMADA | 06b:1680 (QF_BV), 4397-4487 (lexicográfico), 2788 (always) | OK |
| 281 | fora do fragmento → `runtime_checked` ou `refuted` | CONFIRMADA | 06b:2261 | OK |

## §2.6: catálogo dos 121 diagnósticos (linhas 283 a 407)

**Resumo do catálogo**
- Dos 121 códigos, **120 existem em HEAD**. O **`[W0064]` não existe em HEAD**: aparece só na WT não commitada (07_driver.src:379/392), com significado de porte Windows.
- **Faltam no catálogo**, apesar de existirem no código:
  - **`[R0300]`**, módulo não encontrado em `lume agent` (compiler/stage1/lume_driver.src:287; CHANGELOG.md:271, 332).
  - **95 códigos da semente Stage-0** (bootstrap/lume0/*.c): D0001, L0011, L0020-L0022, L0030, L0040, L0050, L0060, M0001, P0010-P0018, P0020-P0021, P0030-P0033, P0040-P0042, P0050-P0053, P0060-P0065, P0070, P0080-P0083, P0090, P0100, P0110, P0120-P0123, P0130, P0140-P0143, P0150-P0153, P0160-P0161, P0170-P0180, P0190-P0192, P0999, R0100, U0001, U0002.
  - Portanto, "todos os 121" é falso: o compilador Stage-1 tem 121 (com R0300 e sem W0064 em HEAD) e a semente tem outros.
- **Local primário**: o número de linha citado contém o código em todos os 121 casos (em HEAD; para R0203-R0205 só na WT, ver abaixo). Mas em **cerca de 45 casos** a linha é comentário `##`, tabela do manual (`lmanual.src`), texto de ajuda (`lcli.src`), arquivo de teste (`*_ok.src`) ou tabela de outro módulo (`arena.src`, `lcrypto_tls.src`), e não o ponto de emissão. Na tabela abaixo esses casos são DIVERGENTE, com o local real.
- **R0203/R0204/R0205** citam `lumec.src:4689/4872`, artefato derivado e não rastreado. A fonte é **name_flow.src:141 e :324** (HEAD).
- **Coluna "mensagem"**: em cerca de 40 linhas não é mensagem, e sim um trecho de código (`fn cs_name_phase(...)`, `fn ms_validate(...)`, `Cons(...)`) ou uma célula de tabela cortada. Exemplos: 4, 6, 15, 16, 19, 20, 39, 45-57, 64, 69, 78-82, 86-88, 108-110, 113, 116, 117.
- **Famílias**: "T0300 Tensor Shape" está certa no catálogo, mas a §2.1 a chama de HM. T0001 é de fato erro de tipo de argumento de construtor (06_typecheck.src:561); no catálogo aparece o texto de outro uso.

| # | código | local citado | veredito | evidência (local real de emissão, HEAD) | Windows |
|---:|---|---|---|---|---|
| 1 | A0001 | lcaas:1402 | CONFIRMADA | lcaas.src:1402; 06b | OK |
| 2 | A0002 | lcaas:1439 | DIVERGENTE (comentário) | lcaas.src:1488; 06b | OK |
| 3 | A0003 | lcaas:1501 | DIVERGENTE (comentário) | lcaas.src:1538; 06b | OK |
| 4 | A0004 | lcaas:4208 | CONFIRMADA (msg = código) | lcaas.src:4208 `caas_patch_json` | OK |
| 5 | C0001 | 05_codegen:5 | DIVERGENTE (comentário) | name_flow.src:328; 05_codegen | OK |
| 6 | C0002 | 05_codegen:241 | CONFIRMADA (msg = código) | 05_codegen.src:241 | OK |
| 7 | C0009 | arena.src:59 | DIVERGENTE (comentário/tabela) | 06b:4197-4264; lcaas.src:3236 | OK |
| 8 | C0010 | lcrypto_tls:21 | DIVERGENTE (comentário) | ltv.src (rejeição); lqualify.src:139 (probe) | PENDENTE (ltv sobre ELF) |
| 9 | C0011 | lcli:105 | DIVERGENTE (texto de ajuda) | 06b_phase3.src:4915 `ctk_fail` | OK |
| 10 | C0012 | 05_codegen:403 | DIVERGENTE (comentário) | 05_codegen.src:411 | OK |
| 11 | C0271 | lmanual:895 | DIVERGENTE (manual) | 03_comptime.src:289 | OK |
| 12 | C0430 | capsule:7 | DIVERGENTE (comentário) | capsule.src:21, 41, 57 | OK |
| 13 | C1001 | lcaas:831 | CONFIRMADA | lcaas.src:831; 03_comptime | OK |
| 14 | D0002 | lcaas:3498 | DIVERGENTE (classificador) | 04_parser_decls.src:441; name_flow | OK |
| 15 | D0003 | lcaas:3498 | DIVERGENTE (classificador) | name_flow.src (nf_check :315) | OK |
| 16 | D0004 | lcaas:3498 | DIVERGENTE (classificador) | name_flow.src:152 | OK |
| 17 | D0273 | lmanual:154 | DIVERGENTE (manual) | 03_comptime.src:299 | OK |
| 18 | D0405 | lprotect:156 | CONFIRMADA | lprotect.src:156 | OK |
| 19 | E0001 | lcaas:3503 | CONFIRMADA (código-padrão genérico de `cs_real_dflt`) | lcaas.src:3503 | OK |
| 20 | E0002 | lcaas:3530 | CONFIRMADA | lcaas.src:3530 | OK |
| 21 | E0200 | core_features_ok:5 | DIVERGENTE (arquivo de teste) | 06b:382-487; lcaas.src:1649 | OK |
| 22 | E0210 | lcli:106 | DIVERGENTE (ajuda) | 06b_phase3.src:4730 `na_fail` | OK |
| 23 | E0305 | lcli:76 | DIVERGENTE (ajuda) | 06b_phase3.src:5072 | OK |
| 24 | E0306 | lcli:76 | DIVERGENTE (ajuda) | 06b_phase3.src:5200 | OK |
| 25 | I0002 | interop:101 | CONFIRMADA | interop.src:101 | OK |
| 26 | I0003 | interop:159 | CONFIRMADA | interop.src:159 | OK |
| 27 | I0004 | 05_codegen:855 | CONFIRMADA | 05_codegen.src:855 ("at most 6 … x86-64") | PENDENTE: o ABI Win64 tem 4 registradores; a fronteira C FFI precisa de regra própria |
| 28 | I0275 | lmanual:538 | DIVERGENTE (manual) | ltarget.src:1056 | OK |
| 29 | K0005 | lcaas:3125 | CONFIRMADA | lcaas.src:3125 | N/A (kernel bare-metal) |
| 30 | K0006 | lcaas:3279 | CONFIRMADA | lcaas.src:3279 | N/A |
| 31 | K0010 | lcert:581 | DIVERGENTE (comentário) | lcert.src:1066 | OK |
| 32 | K0011 | lcert:581 | DIVERGENTE (comentário) | lcert.src:1044 | OK |
| 33 | K0012 | lcert:581 | DIVERGENTE (comentário) | lcert.src:1038 | OK |
| 34 | K0013 | lcert:582 | DIVERGENTE (comentário) | lcert.src:1026 | OK |
| 35 | K0014 | lcert:570 | DIVERGENTE (comentário) | lcert.src:1026 | OK |
| 36 | K0015 | lcert:583 | DIVERGENTE (comentário) | lcert.src:1066 | OK |
| 37 | K0016 | lcert:583 | DIVERGENTE (comentário) | lcert.src:1040 | OK |
| 38 | K0017 | lcert:584 | DIVERGENTE (comentário) | lcert.src:1039 | OK |
| 39 | K0400 | lcaas:4123 | CONFIRMADA (só no lcaas; nenhum módulo do lumec emite K0400) | lcaas.src:4123 | N/A |
| 40 | L0001 | lasm:9 | DIVERGENTE (comentário) | lasm.src:55/86 | OK |
| 41 | L0002 | lcaas:3503 | DIVERGENTE (classificador) | 01_lexer.src:41 | OK |
| 42 | L0003 | 01_lexer:20 | DIVERGENTE (comentário) | 01_lexer.src:24 | OK |
| 43 | L0004 | lcert:609 | DIVERGENTE (outro módulo) | 01_lexer.src:65 | OK |
| 44 | L0010 | lasm:516 | CONFIRMADA | lasm.src:516 | OK |
| 45-57 | M1001-M1004, M2001-M2005, M3001-M3004 | lmesh:25..315 | CONFIRMADA (13/13; msg = código) | lmesh.src nas linhas citadas | OK |
| 58 | N0400 | lcaas:3047 | CONFIRMADA | lcaas.src:3047 | OK |
| 59-68 | O0001, O0002, O0004, O0010, O0011, O0012, O0013, O0020, O0021, O0030 | lcaas:1104..1247 | CONFIRMADA (10/10 no lcaas) | lcaas.src nas linhas citadas; no lumec o local é 06b/own_flow | OK |
| 69 | P0001 | lcaas:727 | CONFIRMADA | lcaas.src:727 | OK |
| 70 | P0002 | lcaas:3499 | DIVERGENTE (tabela) | 02_parser.src:51 e seguintes; 01_lexer; 04 | OK |
| 71 | P0003 | 01_lexer:58 | DIVERGENTE (comentário) | 04_parser_decls.src:145 | OK |
| 72 | P0004 | 04:102 | DIVERGENTE (comentário) | 04_parser_decls.src:122-124 | OK |
| 73 | PC0001 | lproof_cache:181 | CONFIRMADA (HEAD) | lproof_cache.src:181 (WT: :182). A mensagem citada é a de :236 | OK |
| 74 | PC0002 | lmanual:705 | DIVERGENTE (manual) | lproof_cache.src:285, 291 | OK |
| 75 | PC0003 | lmanual:706 | DIVERGENTE (manual) | lproof_cache.src:309 | PENDENTE: `pc_find_lcaas` precisa achar o `.exe` |
| 76 | PC0004 | lproof_cache:314 | CONFIRMADA (HEAD) | lproof_cache.src:314 | OK |
| 77 | PC0005 | lmanual:706 | DIVERGENTE (manual) | lproof_cache.src:332 | OK |
| 78-82 | R0001-R0005 | lregistry:117..127 | CONFIRMADA (HEAD; a WT deslocou +1 com `use hostio`) | lregistry.src | PENDENTE: em HEAD usa `/bin/ls`, `/usr/bin/printenv`, `/bin/rm`; a WT está migrando para hostio |
| 83 | R0200 | lcaas:1902 | DIVERGENTE (tabela) | name_flow.src; 04_parser_decls.src:421 | OK |
| 84 | R0201 | lcaas:3498 | DIVERGENTE (classificador) | name_flow.src:100 | OK |
| 85 | R0202 | lcaas:3498 | DIVERGENTE (classificador) | 07_driver.src:304; name_flow | OK |
| 86 | R0203 | lumec.src:4689 | DIVERGENTE (artefato derivado) | name_flow.src:141 | OK |
| 87 | R0204 | lumec.src:4872 | DIVERGENTE (artefato derivado) | name_flow.src:324 | OK |
| 88 | R0205 | lumec.src:4689 | DIVERGENTE (artefato derivado) | name_flow.src:141 | OK |
| 89 | S0001 | lcaas:1907 | DIVERGENTE (comentário) | lcaas.src:1930 | OK |
| 90 | T0001 | lcaas:3525 | CONFIRMADA | lcaas.src:3525; 06_typecheck.src:561 | OK |
| 91 | T0300 | lcaas:3009 | CONFIRMADA | lcaas.src:3009; 06b:2955 | OK |
| 92 | T0400 | 06b:3706 | DIVERGENTE (comentário) | 06b_phase3.src:3734 | OK |
| 93 | T0401 | 06b:3706 | DIVERGENTE (comentário) | 06b_phase3.src:3806 | OK |
| 94 | T0402 | 04:528 | CONFIRMADA | 04_parser_decls.src:528 | OK |
| 95 | T0403 | 04:526 | CONFIRMADA | 04_parser_decls.src:526 | OK |
| 96 | T0500 | 06_typecheck:812 | CONFIRMADA | 06_typecheck.src:812 | OK |
| 97-103 | T0601-T0607 | 06_typecheck:29-32 | DIVERGENTE (comentário) | 06_typecheck.src:99-154 (`tsx_fail`) | OK |
| 104 | T0900 | ltarget:21 | DIVERGENTE (comentário) | ltarget.src:1072 | OK |
| 105 | T0901 | lmanual:692 | DIVERGENTE (manual) | ltarget.src | OK (diagnóstico); PENDENTE (execução em qemu) |
| 106 | T0902 | lmanual:691 | DIVERGENTE (manual) | ltarget.src | OK |
| 107 | T0903 | lmanual:691 | DIVERGENTE (manual) | ltarget.src:1284 | OK |
| 108 | T1001 | lcaas:768 | CONFIRMADA (só no lcaas) | lcaas.src:768 | OK |
| 109 | T1002 | lcaas:769 | CONFIRMADA (lcaas); no lumec fica em name_flow.src:190 | — | OK |
| 110 | T1003 | lcaas:773 | CONFIRMADA (só no lcaas) | — | OK |
| 111 | T2001 | lcaas:780 | CONFIRMADA | lcaas.src:780 | OK |
| 112 | T2002 | lcaas:824 | CONFIRMADA | lcaas.src:824 | OK |
| 113 | T3001 | lcaas:808 | CONFIRMADA (só no lcaas) | lcaas.src:808 | OK |
| 114 | V0001 | ai_runtime:131 | DIVERGENTE (tabela) | lcaas.src:2782 | OK |
| 115 | V0002 | lcaas:2841 | DIVERGENTE (comentário) | lcaas.src:2844; 06b:3138 | OK |
| 116 | V0003 | lcaas:4157 | CONFIRMADA | lcaas.src:4157 | OK |
| 117 | V0004 | lcaas:4283 | CONFIRMADA | lcaas.src:4283 | OK |
| 118 | V0005 | lcaas:2901 | CONFIRMADA | lcaas.src:2901; 06b:2788 | OK |
| 119 | W0001 | lcaas:1232 | CONFIRMADA | lcaas.src:1232; 06b:36 | OK |
| 120 | W0002 | lmanual:40 | DIVERGENTE (manual) | lprotect.src:161 | OK |
| 121 | W0064 | 07_driver:379 | **INEXISTENTE em HEAD** (só na WT: :379 é comentário, a emissão está em :392) | 07_driver.src(WT):392 | OK (é do porte) |

Contagem do catálogo: CONFIRMADA 63 · DIVERGENTE (local, classificador ou artefato) 57 · INEXISTENTE em HEAD 1 (W0064) · faltando no catálogo: R0300 + 95 da semente.

---

## Lista consolidada de afirmações falsas e divergentes

**Falsas ou inexistentes**
1. L223: bits 2..64 de `freef` = `@interrupt, @export, @protect, @gc, @soa, @schedule`. O real é 2 = total, 4 = llm/extern, 8 = kernel, 16 = interrupt, 32 = export/FFI, 64 = protect. `@gc`/`@soa` são tipos.
2. L215: `VSig(nm, params, reqs, enss, wcet, term_measures)` não existe. São `VContractSig`, `WcetSig` e `VTermSig`.
3. L189/L245: `pat_scrutinee_safe` não existe em lugar nenhum do repositório.
4. L275/L277/L280: `prover_farkas_dual_rhs_sum`, `ast_native_horner_quadratic_eval` e `prover_octagon_transitive_upper` **não fazem parte do provador**. São funções de biblioteca em lchameleon/lstd/stdlib. O provador não tem certificados de Farkas, Horner nem domínio de octógonos.
5. L192/L222/L407: `[W0064]` como "verificação freestanding". Não existe em HEAD; na WT é a recusa de `--win64` para imagem `.kernel`.
6. L283: "todos os 121 códigos". Falta R0300, e a semente tem mais 95 códigos.
7. L61: `lasm` com Mach-O64. Mach-O só existe em `ltarget.src`.

**Divergentes (valor real)**
- L30/L95: 180.759 linhas e 27.885.212 B (HEAD). O dossiê se contradiz (10.674.828 contra 27.972.945 B; 237.638 contra 237.649 linhas). "Árvore limpa" também não confere.
- L75-94: linhas de docs, wiki, assets e root muito diferentes; bytes de compiler, scripts e .github levemente diferentes.
- L106: o DDC compila a semente só com `-std=c11 -O2`; o Makefile tem `-Wno-sign-conversion`.
- L122: 410/410 e 170/170 não estão no Makefile (são de docs); o ASan tem 3 testes pulados.
- L154-160: os 7 módulos `.lume` estão com linhas/bytes errados (por exemplo lexer.lume 69/2.319, data_eval 754/32.324, data_codegen 8/320).
- L163: add/sub usam corte 48+16; só a multiplicação usa 4 limbs de 16.
- L167: ordem real da amalgamação (runtime_core depois do 04; own/name_flow depois do 06), com 06c/06d inexistentes listados.
- L168: o estágio da semente gera lumec0, que é copiado de `build/bin/lumec` quando ele existe. lumec1 == lumec2 (não há "vestígios").
- L51: lumec.src é derivado e tem hoje 10.642 linhas.
- L189/191/194/195: bytes de 05 (HEAD 130.867), 06b (461.356) e name_flow (37.632); 07_driver do dossiê = WT, sendo HEAD 376/36.215/126; total em HEAD 10.464 / 961.271 / 3.131.
- L189: `--win64` não está em 05_codegen (só na WT, em 07_driver/runtime_core); SIMD é só AVX2 no codegen (EVEX só no lasm); `jo __rt_ovf` fica no runtime.
- L190: HM é T0500, não T0300; T1002 está em name_flow; T1001/T1003/T3001 só no lcaas (o lumec emite sem código).
- L191: T0402/T0403 em 04_parser_decls; "QF_NIA de Horner" não existe (é Positivstellensatz).
- L193: own_flow emite só O0004/O0013.
- L246: `lsra_*` em 478-528.
- L266: o `ct_eq` usa deslocamento **lógico**, sem `sbbq`.
- L278: guarda = 3037000499, não 3037000000.
- L31: o ponto fixo está em scripts/bootstrap.src, não em 07_driver.
- Catálogo: 57 locais primários apontam para comentário, manual, ajuda, teste ou artefato derivado (lista na tabela); cerca de 40 "mensagens" são trechos de código.

---

## O que falta para o Windows ficar igual ao Linux (escopo destas seções)

1. **Ponto fixo PE32+**: registrar `lumec.exe == lumec2.exe == lumec3.exe` (com `--win64` + `lasm --pe`) e um hash de referência próprio. Portar `scripts/bootstrap.src` (`/bin/cp` em HEAD; a WT está trocando por hostio) e permitir o estágio 0 a partir de `build/bin/lumec.exe` (o código já copia o `lumec` existente, então só falta a variante `.exe`).
2. **Semente Stage-0 e DDC**: a semente é C. No Windows só roda o `lume0.exe` pré-compilado. O DDC (`cc` contra `clang`), `make test`, `make asan` e `sha256sum -c` exigem toolchain C, `/bin/sh` e sanitizers: PENDENTE (ou reimplementar o portão de SEED_FREEZE em Lume, como `lqualify q_do_seed` já faz).
3. **io_uring (syscalls 425-427)**: hoje retorna -ENOSYS. Precisa de um equivalente (IOCP) na camada `__win_syscall`.
4. **DWARF v4 → PDB/CodeView**: `lume build -g` no Windows não gera símbolos utilizáveis.
5. **ltv / ltv_rt / lmcdc / lstack / lsafety_envelope / synergy-gate / lqualify**: leem ELF e executam binários Linux, e o ltv chama `/usr/bin/z3` e `/usr/bin/cvc5`. É preciso ensinar o ltv a ler PE32+ (ou validar o `.s` antes do `lasm --pe`), trocar z3/cvc5 por lsmt (já clean-room) e portar os gates para hostio.
6. **lregistry (R0001-R0005)**: em HEAD usa `/bin/ls`, `/usr/bin/printenv`, `/bin/rm`. A migração para `hostio` está em andamento na WT.
7. **lproof_cache [PC0003]**: `pc_find_lcaas` precisa localizar `lcaas.exe`.
8. **FFI C [I0004]**: a regra "até 6 parâmetros" é SysV. O ABI Win64 tem 4 registradores + shadow space e ymm6-15 não voláteis; é preciso uma regra e um lowering próprios para `--win64`.
9. **Kernels freestanding (`@freestanding`, `@interrupt`, `.kernel`, K0005/K0006/K0400)**: N/A no Windows (W0064 recusa, corretamente).
10. **T0901 (execução em qemu-aarch64/riscv64)**: PENDENTE (qemu Linux).
11. **Medições (dudect, 445 ms / 115 MB, 31,8×)**: refazer no Windows; o compactador já está verificado byte a byte.

Tudo o que é frente-fim, tipos, ownership, efeitos, `@no_alloc`, CT, provador QF_LIA/QF_NIA, lcert e lsmt não depende do SO: **OK** no Windows nativo, porque o compilador roda nativo.
