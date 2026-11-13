# Auditoria do dossiê, linhas 1282 a 1833 (Parte VI até o fim)

Data da auditoria: 2026-11-13. Repositório auditado: `C:\Users\Ricardo.Bueno\lume` (somente leitura, nada foi modificado).
Arquivo do dossiê: `C:\Users\Ricardo.Bueno\LUME_DOSSIE_REVERSA_COMPLETO_BIT_A_BIT_PT_BR.md`.

## Como ler este relatório

- **Escopo.** O trecho 1282-1833 cobre a Parte VI (6.1 motores standalone, 6.2 os 8 motores Nexus, 6.3 capstones), a Parte VII (catálogo dos 122 domínios), a Parte VIII (8.1 inventário de `compiler/stage1/`, 8.2 manifesto SHA-256) e o bloco final de revalidação. Li as 552 linhas inteiras antes de começar a conferir.
- **Aviso 1: o dossiê sumiu do disco.** Durante a auditoria o arquivo deixou de existir em `C:\Users\Ricardo.Bueno\` (nem o Git Bash nem o PowerShell o encontram mais). Todo o texto já tinha sido lido, mas não consegui reler nenhuma linha depois disso.
- **Aviso 2: a árvore mudou durante a auditoria.** O porte para Windows seguiu em paralelo. No início, 10 arquivos de `compiler/stage1/` estavam modificados; no fim, eram 22, mais o `hostio.src` novo. Exemplo: `lconcurrency.src` trocou `os_run("/bin/mkdir")` por `hio_run("mkdir")` no meio da auditoria. Contagens de linha e byte valem para o instantâneo medido. Os números de linha citados são os da árvore no momento de cada leitura e podem ter andado ±1 em arquivos que ainda estão sendo editados.
- **Método.** Cada afirmação foi conferida com Grep e Read no fonte. As contagens (linhas, bytes, `fn`, `law`, `test_`) foram recalculadas para os 216 arquivos da tabela 8.1. Os hashes da 8.2 foram comparados com `MANIFEST.sha256` e com `sha256sum -c`. Também rodei `lume prove` (pelo PowerShell, que chama o `lume` do WSL) nos 8 capstones, no `lsp_bridge.src` e em 7 módulos.
- **Vereditos.**
  - CONFIRMADA: o código calcula de verdade o que o dossiê diz.
  - MODELO: existe só como predicado, fórmula muito simplificada, tabela fixa ou texto.
  - DIVERGENTE: o valor ou a estrutura real é outro (informado na linha).
  - FALSA: o que o dossiê descreve não existe.
  - NÃO VERIFICÁVEL: não dá para conferir só lendo o código.
- **Coluna Windows.** OK quando funciona no Windows nativo (arquivos, processos via CreateProcessW, `os_fork` emulado com o filho rodando antes do pai, memória, relógios). PENDENTE quando depende de algo que ainda não existe, com a dependência exata. N/A quando não se aplica (texto ou contagem).
  - O despachante de syscalls do Win64 (`build/windows-native/win64_layer.s:83-153`) trata 0, 1, 2, 3, 8, 9, 10, 11, 13, 22, 28, 33, 35, 39, 57-62, 73, 74, 79, 80, 82-84, 87, 90, 97, 98, 131, 160, 217, 228 e 231. Não trata socket/bind/listen/accept/connect/sendto/recvfrom (41-45, 49, 50), epoll (213, 232, 233) nem io_uring (425-427).
  - `/tmp`, `/dev/null`, `/dev/stdout`, `/dev/stderr`, `/dev/stdin` e `/dev/urandom` são traduzidos (`win64_layer.s:451-510`, `:2531-2545`).
  - `/root/...` não é traduzido. Os motores que tentam `fs_mkdir("/root/.lume_sovereign_memory")` caem no fallback em `/tmp`.

---

## 1. Abertura da Parte VI (linhas 1282-1285)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1285 | "22 motores soberanos completos" | CONFIRMADA | Na contagem: 14 arquivos na 6.1 (gfx, gui, net, db, decimal, vec, los, lconcurrency, lmesh, leconomy, lregistry, levidence, levolve, lsentience) mais 8 `lume_*_engine.src` dão 22. "Completos" não procede (ver abaixo). | N/A |
| 1285 | "formalmente provados via QF_LIA/QF_NIA + lcert" | DIVERGENTE | Saída do `lume prove`:<br>gfx: 77 obrigações, 41 `proven` e 36 `budget_checked`;<br>net: 68, 43 `proven` e 25 `budget_checked`;<br>db: 6, 4 `proven` e 2 `budget_checked`;<br>los: 11/11 `proven`;<br>crypto: 15/15 `proven`;<br>**lconcurrency e ncm: `ok=false`** (R0200: `os_getenv`, `os_platform`, `fs_copy`, `fs_make_executable`, `fs_chmod`, `fs_rename` e `startswith` indefinidos, que chegam via `use hostio`, mais T2001 no ncm).<br>A maioria das `law` é tautológica, como `if x then x else 1 == 1`. | PENDENTE: o `hostio.src` usa builtins que o toolchain instalado no WSL ainda não conhece (`lconcurrency.src:17`, `lume_reversa_engine.src:13`) |

## 2. Seção 6.1, motores de sistema (linhas 1287-1300)

### 2.1 `gfx.src` (linha 1291)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1291 | 356 linhas, 77 fns, 7 leis | CONFIRMADA | 356 linhas; 77 `fn` (incluindo 11 `test_` e o helper `fx_sin_half_sweep`); 7 `law` (149, 152, 208, 247, 268, 283, 304) | N/A |
| 1291 | seno de Bhaskara I `fx_sin_half`, erro <0,16% | CONFIRMADA | `gfx.src:35`; testes em `:329` e `:334` (sen 30 = 500, sen 90 = 1000) | OK |
| 1291 | "denominador **provado** ≥ 32.400 sem código morto" | DIVERGENTE | O próprio comentário em `gfx.src:31-34` diz que a desigualdade é não linear e **não** é `law`. Ela só é **testada** por varredura em [-2000, 2000] (`gfx.src:338-340`). | OK |
| 1291 | rasterizador Bresenham/Bézier | MODELO | `gfx_bresenham_steps` (`:101`) só devolve max(\|dx\|, \|dy\|) e não plota pixel. `gfx_bezier_quad_eval` (`:105`) avalia uma coordenada escalar. | OK |
| 1291 | projeção perspectiva pinhole 3D | CONFIRMADA | `gfx_project_3d_to_2d` (`:125`), rotações (`:121-123`), teste (`:346`) | OK |
| 1291 | exportadores binários .bmp, .ppm e .svg | MODELO | `bmp_header_build_hex` (`:137`) monta só o cabeçalho de 54 bytes, em hex e sem pixels. `ppm_solid_2x2_build` (`:141`) gera um P3 2×2 de cor sólida. `svg_substation_hmi_build` (`:143`) é uma string SVG fixa. Nada é gravado em arquivo. | OK |
| 1291 | IK 7-DOF por Damped Least Squares (`ufe_dls_lambda_sq_milli`, `ufe_dls_denom_nonzero_law`) | MODELO | λ² é um degrau: 0 ou λmax (`:162-165`). O denominador é σ²+λ² (`:168-171`). Não há Jacobiano nem 7 juntas. A lei em `:152` é σ²≥0, λ²≥1 ⇒ σ²+λ²≥1. | OK |
| 1291 | solver Laplace 3D SOR (`ufe_harmonic_maximum_principle_law`) | MODELO | `ufe_laplace_sor_step_milli` (`:203-206`) devolve a média dos vizinhos recebida como argumento, ou o valor de Dirichlet. Não tem ω, malha nem iteração. | OK |
| 1291 | vórtice GNRON | MODELO | `ufe_gnron_swirl_scale_milli` (`:156-159`) devolve 0, 1000, `dist` (só quando ρ0 = 1000) ou a constante 500 | OK |
| 1291 | colisão de cápsulas | MODELO | `:212-215` compara uma distância já dada com r_i+r_j+margem. Não calcula a distância segmento-segmento. | OK |
| 1291 | EKF na forma de Joseph + portão 5σ de Mahalanobis (`ufe_ekf_joseph_cov_pos_milli`) | MODELO | A "covariância de Joseph" devolve `gain_atten + r_meas_noise` (`:218-221`), e não (I−KH)P(I−KH)ᵀ+KRKᵀ. O portão 5σ compara inov² ≤ `s_var_25x`, com o 25 multiplicado pelo chamador (`:180-183`). | OK |
| 1291 | stiction e vida útil remanescente (RUL) | MODELO | stiction é um limiar (`:224-227`). **Defeito:** `ufe_actuator_rul_hours` (`:233`) devolve (crit−est)/2 e ignora `wear_rate_per_hr_milli`. | OK |
| 1291 | vapor IAPWS-IF97 | MODELO | `ufe_if97_region_select` (`:186-189`) só escolhe a região: T>1073 ou P>100 MPa dá 0; saturado dá 4; T≤623 dá 1; senão 2. Não calcula nenhuma propriedade (v, h, s, cp) nem a fronteira B23 e a região 3. | OK |
| 1291 | limite de Carnot (`ufe_carnot_second_law`) | MODELO | `:242-248` compara η_real ≤ η_Carnot, mas η_Carnot vem pronto como argumento; 1−Tc/Th não é calculado | OK |
| 1291 | escalonador 1 kHz | MODELO | só existe `ufe_latency_shedder_step`, um passo de histerese (`:197-200`) | OK |
| 1291 | catenária de risers (`subsea_catenary_top_tension_n`) | CONFIRMADA | T_topo = H + w·d (`:251-254`). É a fórmula da catenária com o TDP no vértice. Simples, mas correta. | OK |
| 1291 | colapso combinado API RP 1111 | MODELO | `subsea_combined_longitudinal_stress_ok` (`:263-266`) faz σ_axial+σ_flexão ≤ admissível. Não é o critério de colapso combinado (pressão/flexão) da API RP 1111. | OK |
| 1291 | triagem de VIV | MODELO | Vr ≤ Vr_onset (`:272-275`) | OK |
| 1291 | fadiga Palmgren-Miner (`subsea_miner_dff_safety_law`) | CONFIRMADA | D·DFF ≤ 1 (`:278-284`), trivial | OK |
| 1291 | guindaste marítimo DNV DAF | MODELO | `marine_dnv_daf_floor_milli` (`:287-290`) é uma tabela em degraus por massa (1,30 a 1,10), sem a fórmula da norma | OK |
| 1291 | descompressão Bühlmann ZH-L16C (`subsea_hypoxia_hyperoxia_rejected_law`) | MODELO | `:299-302` só confere ppO2 entre 16 e 160 cbar, GF baixo ≤ GF alto ≤ 100 e ambiente ≥ teto informado. **Não há** os 16 compartimentos, coeficientes a/b nem meias-vidas. | OK |
| 1291 | controle de poço Well-Kill ICP/FCP | DIVERGENTE | ICP = SCR + SIDPP está certo (`:308-311`) e o peso de lama somado em SG também (`:314-317`). **FCP não existe.** | OK |
| 1291 | dutos corroídos ASME B31G | MODELO | `subsea_b31g_corroded_pipe_safe_ok` (`:320-323`) confere profundidade < 80% e P_op ≤ pressão de ruptura reduzida, que vem pronta como argumento. Não calcula o fator de Folias M nem a P_safe da B31G. | OK |

### 2.2 `gui.src` (linha 1292)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1292 | 167 linhas, 60 fns, 2 leis | CONFIRMADA | contagem refeita; leis em `gui.src:148` e `:151` | N/A |
| 1292 | rasterizador 2D `canvas_new`, `canvas_fill_rect` | CONFIRMADA | `:29-41` (framebuffer em lista de pixels) | OK |
| 1292 | composição alfa Porter-Duff source-over | CONFIRMADA | `:44-46`; alfa global, sem alfa de destino | OK |
| 1292 | layout `vbox`/`hbox` e hit-testing | CONFIRMADA | `:51-69` | OK |
| 1292 | codificadores .ppm e .svg | CONFIRMADA | `:80`, `:86` | OK |
| 1292 | invariantes Wayland COSMIC `xdg-dialog-v1` | MODELO | `ui_modal_z_index` soma 100 ao z do pai; `ui_modal_blocks_parent` é booleano (`:138-152`). Não há protocolo Wayland. | OK |
| (fora do dossiê) | "sessão X11" `x11_window_session_loopback` | MODELO | Não é X11 de verdade: troca frames X11 falsos entre dois processos por TCP loopback (`:118`), testada em `:165`. | PENDENTE: sockets (`net_tcp_listen`/`connect`/`accept`, ausentes de `win64_layer.s:83-153`) e `os_fork` com socket |

### 2.3 `net.src` (linha 1293)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1293 | 579 linhas, 202 fns, 16 leis | CONFIRMADA | contagem refeita | N/A |
| 1293 | IPv4/CIDR | CONFIRMADA | `net.src:20-26` | OK |
| 1293 | checksum RFC 1071 em complemento de um | CONFIRMADA | `net_fold16`, `net_checksum16`, `net_checksum16_verify` (`:28-33`) | OK |
| 1293 | UDP e TCP | CONFIRMADA | montagem e verificação com pseudo-cabeçalho (`:39-50`); FSM do TCP com estados em string (`:51`) | OK |
| 1293 | HTTP/1.1 | CONFIRMADA | parser e serializador simples (`:110-114`) | OK |
| 1293 | sockets de kernel | CONFIRMADA | builtins `net_tcp_listen`, `net_udp_bind` etc. no `runtime_sys_tail` (`lume/05_codegen.src:961`); uso em `net.src:108`, `:116`, `:117`, `:133`, `:136-137` | **PENDENTE:** syscalls 41-45, 49 e 50 não tratadas em `win64_layer.s:83-153` (precisa de camada Winsock) |
| 1293 | dissecador VLAN 802.1Q e MPLS TTL | CONFIRMADA | `:155-163`, `net_vlan_id_valid` (`:380`), `net_mpls_ttl_step` (`:385`) | OK |
| 1293 | relés ANSI 50, 27, 59 e 81 | CONFIRMADA | São comparações de limiar, que é o que esses relés fazem (`:343-370`, `:391-409`) | OK |
| 1293 | replay GOOSE monotônico (`ot_goose_replay_reset_detected_law`) | CONFIRMADA | `ot_goose_state_transition_code` (`:497-501`), lei em `:565`, `iec61850_goose_state_valid` (`:282`). O frame GOOSE (`:277`) é simplificado, sem ASN.1 BER. | OK |
| 1293 | modelo Purdue L0..L4 com passagem obrigatória pela DMZ L3.5 (`iec62443_l4_to_l2_direct_forbidden_law`) | MODELO | `iec62443_purdue_conduit_ok` (`:432-436`) só bloqueia 40↔≤20 quando `via_dmz=0`. A L3.5 não é um nível, é um booleano. | OK |
| 1293 | bloqueio de escrita em DCS read-only | MODELO | `ot_readonly_dcs_guard` (`:438-442`): escrita=1 dá 0 | OK |
| 1293 | timeout administrativo finito | CONFIRMADA | 1 a 15 min (`:480-483`), trivial | OK |
| 1293 | paridade de failover HA | MODELO | igualdade de hash e de contagem de regras, e hold ≥ 3·hello (`:485-489`) | OK |
| 1293 | escalonamento monotônico de severidade | CONFIRMADA | `:491-495`, lei em `:562` (trivial) | OK |
| 1293 | Omega-Mesh: "dedução atômica de taxa dupla" | DIVERGENTE | `mesh_atomic_dual_rate_deduct` (`:521-525`) só debita `ip_tokens`. `node_tokens` é consultado, mas **nunca debitado nem devolvido**. | OK |
| 1293 | cura hierárquica de DHT (`mesh_dht_hierarchy_law`) | MODELO | rank = tier·10⁶ + rtt (`:527-531`). Não há DHT (sem distância XOR, buckets nem lookup). | OK |
| 1293 | interseção de quórum Raft (`mesh_raft_quorum_intersection_law`) | MODELO | maioria 2v>n (`:533-537`); a lei (`:574`) é a aritmética pura 2a>n ∧ 2b>n ⇒ a+b>n. Não há eleição nem replicação de log; o backtrack é idx−1 (`:539-543`). | OK |
| 1293 | verificação TOFU de chaves | MODELO | compara inteiros "fingerprint" e timestamps (`:545-549`); não há chave nem assinatura | OK |
| 1293 | cota de multiplexação de canais | CONFIRMADA | `:551-554` (trivial) | OK |

### 2.4 `db.src` (linha 1294)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1294 | 301 linhas, 116 fns, 2 leis | CONFIRMADA | contagem refeita | N/A |
| 1294 | árvore B+ multinível com divisão recursiva, busca e varredura de intervalo | CONFIRMADA | `bm_split_leaf`, `bm_split_inner`, `bm_insert_rec`, `bm_range_scan`, `bm_balanced` (`db.src:52-149`); teste multinível (`:235`) | OK |
| 1294 | ACID com isolamento MVCC (`db_begin_tx`, `db_commit_tx`, `db_rollback_tx`) | DIVERGENTE | Só existem duas raízes, `committed_root` e `working_root`, num registro imutável (`:152-168`). Uma transação por vez; `begin` aninhado reaproveita a raiz de trabalho (`:154`). Sem versões múltiplas nem leitores concorrentes. É cópia-sombra, não MVCC. | OK |
| 1294 | planejador por custo (IndexPointSeek / IndexRangeScan / SequentialScan) | MODELO | três regras fixas (`:171`) | OK |
| 1294 | Write-Ahead Log durável (`db_wal_ops_strictly_increasing_law`) | CONFIRMADA | Linhas `OP`/`COMMIT` com checksum, replay só das transações com COMMIT (`:186-218`), teste de crash com fork (`:220`, `:237`). O checksum é polinomial módulo 10⁹+7 (`:186`), não CRC. A lei (`:297`) é ops+d > ops. | OK com ressalva: `os_fork` emulado (o filho roda primeiro e sai com 9; confirmar que o pai recebe status ≠ 0); `/tmp` é traduzido |
| 1294 | `db_tx_state_sound_law` | MODELO | tautologia: `in_tx ∈ {0,1}` ⇒ válido (`:285-296`) | OK |

### 2.5 `decimal.src` e `vec.src` (linha 1295)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1295 | 118 linhas, 49 fns, 1 lei | DIVERGENTE | Linhas 94+24 = 118 e lei 1 conferem. Funções: 45+4 contando só `^fn`; o `vec.src` tem mais 4 `pub fn` (`:5`, `:8`, `:11`, `:14`), o que dá **53**. | N/A |
| 1295 | ponto fixo base 10, `c·10^-s`, `decimal(p,s)` | CONFIRMADA | `decimal.src:1-4` em diante | OK |
| 1295 | `money[CCY]` | DIVERGENTE | Não está em `decimal.src` (0 ocorrências). Vive no compilador: `lume/03_comptime.src`, `lcaas.src`. | OK |
| 1295 | `vec_slice_conservation_law` | CONFIRMADA | `vec.src:16`: start + (end−start) == end (trivial) | OK |

### 2.6 `los.src` (linha 1296)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1296 | 300 linhas, 99 fns, 1 lei | CONFIRMADA | contagem refeita | N/A |
| 1296 | pilha de bloco LBA + **CRC-32** | DIVERGENTE | `blk_crc32_word` (`los.src:39`) calcula (a·65599 + b·31 + 5381) mod 10⁹+7. **Não é CRC-32.** | OK |
| 1296 | cache de buffers e journal WAL | CONFIRMADA | modelo em memória (`:41-75`) | OK |
| 1296 | VFS com ramfs e lumefs (mkdir, creat, open, read, write, stat, unlink) | CONFIRMADA | em memória (`:77-133`) | OK |
| 1296 | Ethernet II, ARP, IPv4, ICMP, UDP, handshake TCP e anel DMA de NIC | MODELO | registros em memória (`:139-170`). "DMA" só aparece no cabeçalho (`:3`, `:5`); não há função de anel DMA. | OK |
| 1296 | PCB com CR3, capacidades Ring-3/Ring-0, EACCES=−13, ENOSYS=−38, EBADF=−9 | CONFIRMADA | Simulação: `proc_table_init` com `cr3` (`:184`), `sys_ring_allowed` (`:178`), `sys_dispatch` devolve −13, −38 e −9 (`:207`). O CR3 é só um número. | OK |
| 1296 | shell com pipes `\|` e `>` + **12** coreutils | DIVERGENTE | São **11** comandos em `sh_exec_single` (`:242`): uname, echo, cat, ls, stat, ps, mkdir, rm, ping, wc e grep. O próprio cabeçalho (`:7`) lista 11. Pipe (`:244`) e redirecionamento conferem. | OK |
| 1296 | drivers CMOS RTC 0x70/0x71, PCI Config #1, teclado PS/2 Set-1 | MODELO | Decodificam valores recebidos como argumento (`:213-235`). O PCI é uma tabela estática i440FX/PIIX3 (`:221`). Não há instrução `in`/`out`. | OK |
| 1296 | `os_hybrid_gpu_never_selects_missing_dgpu_law` | CONFIRMADA | `:290-296` (trivial) | OK |

### 2.7 `lconcurrency.src` (linha 1297)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1297 | 334 linhas, 44 fns, 8 leis | CONFIRMADA | contagem refeita no instantâneo inicial (o arquivo foi modificado depois: `+use hostio`) | N/A |
| 1297 | ring-buffer SPSC lock-free com conservação provada | MODELO | Ring funcional sobre lista imutável (`:91-109`), sem atômicos nem memória compartilhada. "Lock-free" é rótulo. As leis (`:50-80`) são aritméticas de índice. | OK |
| 1297 | protocolo linear de posse única | MODELO | `linear_msg_pack`/`consume`, lei em `:128` | OK |
| 1297 | ordens parciais estritas de locks (irreflexiva, assimétrica, transitiva) | CONFIRMADA | Leis aritméticas de rank (`:167-175`) e detector de ciclo real `lconc_has_cycle`/`dag_graph_acyclic_ok` (`:176-195`) | OK |
| 1297 | despachante determinístico multiprocesso Linux (`parallel_dispatch_partitions`) | CONFIRMADA | gera um script `/bin/sh` com `&` e `wait`, roda e reduz as saídas (`:221-276`) | **PENDENTE:** `lconcurrency.src:274` `hio_osrun_ct("/bin/sh", …)`, e o `sh` não é emulado pelo `hostio`; o worker do teste também é script sh. Além disso, `lume prove` dá `ok=false` (R0200) |

### 2.8 `lmesh`, `leconomy`, `lregistry`, `levidence` (linha 1298)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1298 | 866 linhas, 346 fns, 0 leis | CONFIRMADA | 336+125+172+233 linhas (o `lregistry.src` tem 171 `\n` e a última linha sem quebra); 131+49+89+77 fns | N/A |
| 1298 | negociação de intenção e transações AST `[M1001..M3004]` | CONFIRMADA | 13 códigos em `lmesh.src`: M1001-M1004, M2001-M2005, M3001-M3004 | OK |
| 1298 | `lume economy` | CONFIRMADA | `leconomy.src` (SHA de artefatos, valor via git) | **PENDENTE:** `leconomy.src:96` `/usr/bin/git` fixo |
| 1298 | registro endereçado por conteúdo `[R0001..R0005]` com re-derivação de hashes | CONFIRMADA | R0001-R0005 presentes; `sha256_file` (15 usos) | **PENDENTE:** `lregistry.src:108` `/usr/bin/printenv` e `:126` (`hio_osrun_ct` para a suíte de testes); rm, mv, mkdir e chmod agora passam pelo `hostio` |
| 1298 | `lume evidence` | CONFIRMADA | `levidence.src` (38 usos de SHA-256 sobre certificados do lcaas) | OK |

### 2.9 `levolve.src` (linha 1299)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1299 | 377 linhas, 176 fns, 1 lei | CONFIRMADA | contagem refeita (o arquivo já estava modificado pelo porte) | N/A |
| 1299 | reparo determinístico A0001/T1001/T1003/T2002 | CONFIRMADA | `levolve.src:4-5`, `evolve_repair_and_compile` (`:325`) | OK |
| 1299 | 6 gates obrigatórios em memória | CONFIRMADA | `evolve_evaluate_single` (`:325`) monta os gates g1 a g6 | OK |
| 1299 | gate "`stage2 == stage3` fixpoint" | DIVERGENTE | Compara o asm do **candidato** gerado duas vezes (`s2_asm = cand_r.asm` contra `cs_asm_gen(cs_expand(...))`, em `:325`). Não é o ponto fixo stage2==stage3 do bootstrap do compilador. | OK |
| 1299 | Ed25519 RFC 8032 sobre `evolve/maintainers.pub`, `can_merge == 0` sem assinatura | CONFIRMADA | `ed25519_verify_ex` (`:121`) com aritmética de campo, redução mod L (`:100-110`) e Shamir de 4 bits (`:115`); `ev_verify_signed` (`:223`) | OK |

### 2.10 `lsentience.src` (linha 1300)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1300 | 612 linhas, 234 fns, 4 leis | DIVERGENTE | Linhas e leis conferem (`:411-414`). Funções: **238** contando `pub fn` (`:416-422`). | N/A |
| 1300 | "8 Leis Constitucionais Imutáveis" `law_1_obey_creator` .. `law_8_creator_approval_gate` | MODELO | São `fn` triviais, não `law` (`:36-43`). `constitutional_core_guard` (`:46`) as chama com **constantes** e por isso sempre devolve 1. | OK |
| 1300 | saturação de igualdade em E-Graphs (`morph_egraph_saturate`) | FALSA | `:72` conta e remove as substrings `" + 0"`, `"0 + "`, `" * 1"`, `" - 0"` do texto-fonte. Não existe e-graph. | OK |
| 1300 | Inferência Ativa (`sentience_awaken`) | FALSA | `:78` conta ocorrências de `"fn "`, `"law "`, `"requires "` e `"ensures "`; a "energia livre" é razão dessas contagens | OK |
| 1300 | compilador e simulador quântico Bell/Grover (OpenQASM 3.0) | MODELO | `quantum_qasm3_emit` (`:82`) emite um circuito fixo de 2 qubits (H, CX, CZ). O simulador de vetor de estado de 2 qubits em inteiros (`:84-95`) é real, mas mínimo. | OK |
| 1300 | codec quaternário de DNA sem homopolímeros ("DNA4") | CONFIRMADA | `dna_quaternary_encode`/`decode`, `dna_homopolymer_free` (`:106-130`). O nome "DNA4" não aparece no código. | OK |
| 1300 | TMR contra SEU | CONFIRMADA | `cosmic_tmr_vote` (`:134`), voto majoritário de 3 | OK |
| 1300 | memória associativa hiperdimensional (HDC) | CONFIRMADA | `hdc_*` (`:144` em diante): XOR, maioria e vetor pseudoaleatório; dimensão pequena | OK |
| 1300 | debugger causal reverso no tempo (Chronos) | FALSA | `chronos_timetravel_json` (`:186`) faz aritmética fixa (x0=10, t1=x0·3, …) e a "inverte". Não há traço de execução. | OK |
| 1300 | dissecador Wireshark/SCADA | CONFIRMADA | O código real está em `net.src`: `wireshark_dissect_frame` (`:216`), PCAP (`:201-209`), Modbus CRC-16 (`:235-239`, poly 0xA001, init 0xFFFF), DNP3 CRC (`:252`, 0xA6BC refletido, complementado), IEC-104, MMS e SV (`:264-286`) | OK |
| 1300 | registro central dos 122 domínios (#0..#121) | CONFIRMADA | tabela de strings em `:527` (nomes) e `:529` (fórmulas): 121 ramos `d == n` + `else` (#121) | OK |

## 3. Seção 6.2, os 8 motores Nexus (linhas 1302-1313)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1306 | reversa: 1.464 linhas, 90 fns, 4 leis | CONFIRMADA | contagem refeita; leis em `lume_reversa_engine.src:19`, `:22`, `:25`, `:28` | N/A |
| 1306 | pipeline Scout → … → Code City 3D | CONFIRMADA | `reversa_scout_scan` (`:328`), `reversa_synthesize_soul_markdown` (`:485`), `reversa_synthesize_mermaid_artifacts` (`:510`), `reversa_build_code_city_3d_svg` (`:549`), `reversa_run_full_pipeline` (`:1401`). Geram markdown, mermaid e SVG. | PENDENTE: `:350-355` usa `/root/.lume_sovereign_memory/reversa_unpacked` e `/usr/bin/7z` (o 7z não é emulado); saídas em `/tmp` (`:1416-1418`) funcionam |
| 1306 | dissecador nativo ELF64, PE64/MZ/UEFI, Mach-O64 e WASM32 | DIVERGENTE | Só o PE tem parsing de verdade (`rv_pe_sections_loop`, `:132`; `rv_inspect_raw_pe`, `:214`). ELF, Mach-O e WASM são reconhecidos **só pelo número mágico** (`rv_classify_target`, `:306-327`). | OK |
| 1306 | scanner multilinguagem (Lume, C, Rust, Python, SQL, JS/TS) | DIVERGENTE | classifica pela **extensão**: `.src`, `.lume`, `.rs`, `.c`, `.h`, `.py`, `.sql` (`:316-325`); não há JS/TS | OK |
| 1306 | lifter SSA `LumeMIR` | FALSA | só aparece no comentário (`:7`) e no texto gerado (`:506`, `:522`); não há código de lifting | N/A |
| 1306 | classificador epistêmico CONFIRMED/INFERRED/GAP (`reversa_epistemic_partition_conservation`) | CONFIRMADA | `:19`, `reversa_classify_confidence_tier` (`:36`) | OK |
| 1306 | gerador SVG 3D Code City | CONFIRMADA | `:531-569` (barras com perspectiva via `gfx`) | OK |
| 1307 | pingora: 386 linhas, 36 fns, 10 leis | CONFIRMADA | contagem refeita | N/A |
| 1307 | TinyUFO: TinyLFU Count-Min de 4 contadores + S3-FIFO Small 10% / Main 90% / Ghost | MODELO | A "estimativa" é `(hash % 3) + access_boost` nas 4 pistas (`lume_pingora_proxy_engine.src:61-70`). Não há tabela de contadores incrementada. As capacidades 10/90 (`:19-30`) e a promoção (`:47-58`) existem. | OK |
| 1307 | anel consistente Ketama | MODELO | 1 ponto por upstream (`:149-153`), distância no anel (`:115-119`), sem nós virtuais | OK |
| 1307 | Power-of-Two-Choices (`pingora_p2c_never_picks_dead_peer1`) | CONFIRMADA | `pingora_p2c_select` (`:126`), 5 leis (`:134-146`) | OK |
| 1307 | limitador 429, trava anti-stampede, circuit breaker, dreno zero-downtime (`pingora_zero_dropped_connections`) | MODELO | fórmulas inteiras (`:181-256`); a lei em `:251` é aritmética | OK |
| 1307 | pipeline HTTP/TLS 1.3 de 7 fases com métricas Prometheus | MODELO | `pingora_execute_7phase_proxy` (`:258`) usa o TLS de brinquedo do `net.src` (`tls13_key_schedule`, `tls13_wire_encode_aead`, `:284-285`). Não abre socket. O texto Prometheus vai para um arquivo (`:342`). | OK (cai no fallback `/tmp`; trocar `/root` em `:340` por `hio_data_dir`) |
| 1308 | egm: 352 linhas, 28 fns, 7 leis | CONFIRMADA | contagem refeita | N/A |
| 1308 | 8 pilares de Heilmeier (`heilmeier_missing_pillar_blocks_approval`) | CONFIRMADA | pontuação e veredito (`lume_egm_engine.src:40-50`) | OK |
| 1308 | enxame de 6 lentes; isolamento Elephant vs Goldfish (`goldfish_zero_conversation_bias`) | MODELO | `egm_context_isolation_guard` (`:58-64`) confere três inteiros recebidos; nenhum revisor roda | OK |
| 1308 | anti-glazing, auditor de contradições, drift Spec↔Código | MODELO | contagem de substrings (`egm_count_substr`) e diferença absoluta (`egm_compute_drift_score`) | OK (`:296-298` gravam em `out_dir`) |
| 1309 | ncm: 272 linhas, 34 fns, 10 leis | CONFIRMADA | contagem refeita | N/A |
| 1309 | MS-RVQ em 5 escalas, "economiza 59 de 64 passos" (`ncm_5scales_saves_59_steps_on_64_tokens`) | MODELO | A lei é a identidade `ncm_parallel_tokens_saved(64,5) == 59`, ou seja 64−5 (`lume_ncm_engine.src:170-178`); os passos residuais são escalares | PENDENTE: `lume prove` dá `ok=false` porque a cadeia ncm→egm→reversa→hostio usa builtins novos |
| 1309 | tied codebook, máscara causal por escala, RoPE com reset, CFG | MODELO | funções escalares 1D/2D (`:120-170`) | OK |
| 1309 | solver global Sudoku 4×4 / AST | MODELO | `ncm_sudoku4_coarse_to_fine_solve()` (`:233`) não recebe argumento e resolve um tabuleiro fixo; a célula vale 10 − soma (`:207`). Não há solver de AST. | OK |
| 1310 | opentpu: 426 linhas, 49 fns, 8 leis | CONFIRMADA | contagem refeita | N/A |
| 1310 | montador/desmontador openTPU ISA v1 (R0..R15, R0 == 0) | MODELO | A palavra é **decimal**: opcode·10⁶ + rd·10⁴ + rs1·10² + imm (`lume_opentpu_engine.src:55-70`). Não há montador textual. | OK |
| 1310 | MXU sistólica, QACT+FP4 4,25 b/w, K-Smoothing, Stream 0x13, MoE WAITW, Roofline | MODELO | funções aritméticas (`:104-300`); `otpu_exec_mm_systolic_4x4` faz uma multiplicação 4×4; placas YPCB/BCU1525/F2 por fórmula | OK (`:346` usa `/root`, com fallback) |
| 1311 | continuum: 437 linhas, 40 fns, 9 leis | CONFIRMADA | contagem refeita | N/A |
| 1311 | AgentShield, Bend, Billion-Context ACP, AI-Memory | MODELO | predicados inteiros | OK |
| 1311 | roteador LLM com fallback local (`llm_router_exhausted_quota_always_falls_back_to_sovereign_local`) | CONFIRMADA | lei em `lume_continuum_nexus_engine.src:193-196` sobre `llm_router_select_lane` | OK |
| 1311 | sintetizador binário real RIFF/WAVE de 3 locutores | CONFIRMADA | `notebook_synthesize_podcast_wav` (`:226-237`): cabeçalho RIFF/WAVE PCM 16 bits a 22.050 Hz correto. O conteúdo são só 120 amostras de onda quadrada (cerca de 5 ms). | OK |
| 1311 | grafo de cena LWW-Element-Set CRDT (`crdt_lww_merge_is_commutative`) | CONFIRMADA | merge escalar de timestamp e valor, leis de comutatividade e idempotência (`:255-275`) | OK |
| 1312 | quantum: 909 linhas, 119 fns, 3 leis | CONFIRMADA | contagem refeita | N/A |
| 1312 | tipos lineares estilo Silq (no-cloning) + descomputação adjunta | CONFIRMADA | `qlinear_*`, lei em `lume_quantum_nexus_engine.src:74`, `q_uncompute_synthesize_adjoint` | OK |
| 1312 | otimizador ZX-Calculus (fusão de spiders, redução de T-count) | MODELO | reescrita sobre uma lista linear de portas (`:325-437`), sem grafo ZX | OK |
| 1312 | tableau estabilizador Gottesman-Knill estilo Stim | CONFIRMADA | `q_stab_row_apply_h/s/cnot`, tableau e GHZ-8 (`:487` em diante) | OK |
| 1312 | código de superfície [[9,1,3]] com decodificador **MWPM** | DIVERGENTE | O decodificador é uma **tabela** síndrome→qubit (`q_surface_decode_z_syndrome`, `:664` em diante). Não há emparelhamento perfeito de peso mínimo. Para d=3 com um erro, o resultado equivale. | OK |
| 1312 | VQE/QAOA por parameter-shift exato | MODELO | 1 parâmetro, energia analítica −0,5cos − 0,637sen − 0,4 (`:736-740`), deslocamento de ±90° (`:747-751`). Não há QAOA. | OK (`/tmp` e `/dev/stdout` são traduzidos) |
| 1313 | crypto-blockchain: 161 linhas, **27** fns, 6 leis | DIVERGENTE | São **58** funções: 27 `fn` + 31 `pub fn` | N/A |
| 1313 | primitivas **HMAC-SHA256** | FALSA | `crypto_hmac_sha256` (`lume_crypto_blockchain_engine.src:11`) é `sha256("OPAD_0x5c:"+sha256("HMAC_KEY:"+key)+":"+sha256("IPAD_0x36:"+…))` sobre **texto**. Não é RFC 2104 (sem pad XOR 0x36/0x5c, sem blocos de 64 bytes). | OK |
| 1313 | derivação de carteiras HD | FALSA | `hd_derive_wallet` (`:22`) usa o HMAC falso. A "chave pública" é 5^x mod (10⁹+7) (`:17-19`) e o endereço é `"bc1q"` + prefixo de SHA (`:20`). Não há secp256k1, BIP32 nem bech32. | OK |
| 1313 | árvore de Merkle de N folhas | CONFIRMADA | SHA-256 de strings com tags de domínio LEAF/NODE e folha ímpar duplicada (`:46-60`) | OK |
| 1313 | `law_merkle_root_deterministic` | MODELO | a lei é sobre o hash linear de brinquedo 771a + 1285b + 392 (`:32-42`), não sobre o Merkle SHA | OK |
| 1313 | mineração Proof-of-Work multidificuldade | CONFIRMADA | `pow_mine_block` (`:76`): SHA-256 do cabeçalho em texto com N zeros hexadecimais à esquerda | OK |
| 1313 | UTXO, teto de suprimento, AMM x·y=k, Kelly (`bitcoin_supply_cap_invariant`, `utxo_conservation_law`, `defi_amm_lp_fee_growth_law`, `kelly_risk_cap_law`) | MODELO | Leis tautológicas (`:5-8`). Exemplo: "se sats ≤ cap então sats ≤ cap". | OK |
| 1313 | auditor estático de smart contracts contra reentrância e overflow | MODELO | `sc_audit_contract_ops` (`:120-124`) varre uma lista de tokens de operação (`"external_call"`, `"state_write"`); não analisa código | OK |

## 4. Seção 6.3, capstones e IDE (linhas 1315-1327)

Resultado do `lume prove` em cada arquivo, contando os status no JSON:

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1319 | pix_fraud_trace 9/9 | CONFIRMADA | 9 obrigações, 9 `proven` | OK (sem I/O) |
| 1320 | sentry_uav_guard 9/9 | DIVERGENTE | 9 obrigações: **8** `proven`, 1 `runtime_checked` | OK |
| 1321 | verified_accounting 7/7 | DIVERGENTE | 7 obrigações: **6** `proven`, 1 `runtime_checked` | OK |
| 1322 | dfe_pix_bacen 11/11 | DIVERGENTE | 11 obrigações: **7** `proven`, 4 `runtime_checked` | OK |
| 1323 | omniroute_guard 8/8 | DIVERGENTE | 8 obrigações: **6** `proven`, 2 `runtime_checked` | OK |
| 1324 | brasil_public_id 9/9 | DIVERGENTE | 9 obrigações: **8** `proven`, 1 `runtime_checked` | OK |
| 1325 | zero_breach_forensics 8/8 | CONFIRMADA | 8 obrigações, 8 `proven` | OK |
| 1326 | sovereign_llm_router 20/20 | DIVERGENTE | **25** obrigações (15 `ensures` + 10 `law`): 19 `proven`, 6 `runtime_checked`. O número 20/20 vem de `docs/38-lume-manual-and-cli-reference.md:498` e está desatualizado. | OK |
| 1327 | `editors/vscode-lume/lsp_bridge.src` + `extension.js` + `editors/openidea-lume/plugin.toml`, 7/7 | CONFIRMADA | Os arquivos existem; 7 obrigações, 7 `proven` | OK (o bridge roda como processo; não usa sockets) |

## 5. Parte VII, catálogo dos 122 domínios (linhas 1331-1460)

O mapeamento domínio por domínio já está em `build/windows-native/audit/domains_122_map.md`, feito por outra auditoria. Aqui confiro as afirmações estruturais do cabeçalho e as fórmulas que o código desmente.

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1333 | extraído de `sentience_evolve_122_domain_name/_formula` em `lsentience.src:527-535` | CONFIRMADA | Nomes em `:527` e fórmulas em `:529`, na função `sentience_evolve_108_domain_*`. As versões 112 e 122 são apelidos (`:531-534`). | N/A |
| 1333 | suíte de provadores #108..#121 em `lchameleon.src:700-975` | DIVERGENTE | Os #108-#111 estão na seção **1L** (cerca de `:707-755`), os #112-#115 na **1P** (`:757-854`) e a **1Q** (`:855`) cobre #112..#121. Os rótulos "§1P" que a tabela atribui aos #108-#111 estão errados. | N/A |
| 1337-1458 | 122 nomes canônicos (#0..#121) | CONFIRMADA | Os 121 ramos extraídos de `:527` mais o `else` (#121) batem com a tabela do dossiê | N/A |
| 1337-1458 | coluna "Fórmula / Invariante Matemático **Verificado**" | MODELO | São strings descritivas (`:529`), confirmadas por amostragem (#3, #40, #84, #121). O teste agregador (`lsentience.src:611`) confere 3 nomes e procura `"122/122"` num JSON montado à mão; o 122 é um rótulo. | N/A |
| 1340 (#3) | Subsea Catenary + Bühlmann + ASME B31G em `gfx.src` | MODELO | ver 2.1: Bühlmann e B31G são predicados | OK |
| 1349 (#12), 1350 (#13), 1351 (#14) | UFE DLS + SOR, IAPWS-IF97 + Carnot + EKF, DNV-ST-N001 + ICP | MODELO | ver 2.1 | OK |
| 1342 (#5), 1343 (#6), 1353 (#16) | IEC 62443 Purdue, Omega-Mesh Raft/DHT, GOOSE stNum/sqNum | MODELO | ver 2.3; GOOSE confere | OK |
| 1393 (#56) | "RFC 8446 TLS 1.3 AEAD Nonce" (executor declarado: lsentience + levolve) | FALSA | O TLS do `std.net` é um modelo ARX "inspirado em ChaCha", e o próprio comentário admite (`net.src:56-59`): `tls13_hkdf_expand_label` não é HKDF e a tag não é Poly1305 (`:60-76`). Se existe TLS real, é o `lcrypto_tls.src` (fora deste trecho), não o `net.src`. | PENDENTE: o loopback TLS precisa de sockets (`net.src:108`, `:136-137`) |
| 1395 (#58) | ANSI 51 IDMT dentro de "ANSI 50/51/87T/21/27/59/81/79 IED Trip" | DIVERGENTE | `ansi51_inverse_time_trip_ms` (`net.src:351`) usa 6900·TDS/(M−1), que **não** é a curva IEC Standard Inverse (0,14/(M^0,02−1)) anunciada no comentário. 50, 87, 21, 27/59, 81 e 79 conferem como limiares e FSM (`:343-371`). | OK |
| 1397 (#60) | "WAL **CRC32** Recovery" | DIVERGENTE | o checksum do WAL é polinomial mod 10⁹+7 (`db.src:186`); o MVCC é cópia-sombra (ver 2.4) | OK |
| 1344 (#7) | DeFi AMM / UTXO / Merkle / Kelly | MODELO | ver crypto-blockchain na seção 3 (HMAC e HD falsos) | OK |
| 1345 (#8) | surface code [[d²,1,d]] | MODELO | decodificador por tabela (seção 3) | OK |

## 6. Parte VIII, inventário e manifesto (linhas 1464-1827)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 1466 | "Todos os módulos de produção em `compiler/stage1/`" | DIVERGENTE | A tabela tem 216 entradas e todas existem. Faltam `compiler/stage1/lumec.src` (existe, não é versionado e está no MANIFEST como #114) e `hostio.src` (novo, do porte). | N/A |
| 1466 | "54 arquivos de teste `*_ok.src`/`*_fail.src` somando 1.705 linhas" | CONFIRMADA | 54 arquivos `*_ok.src` com 1.705 linhas no total. **Não existe nenhum `*_fail.src`.** | N/A |
| 1468-1683 | linhas por arquivo (216 entradas) | CONFIRMADA | 215 batem com `wc -l`. O `lregistry.src` tem 171 `\n` porque a última linha não termina em quebra; a tabela diz 172, o que é aceitável. | N/A |
| 1468-1683 | bytes por arquivo | DIVERGENTE | 5 diferenças, todas em arquivos do porte. lcaas: 543.409 no dossiê, 543.430 hoje, 543.291 no HEAD. 05_codegen: 130.957 / 130.977 / 130.867. 06b_phase3: 461.474 / 461.495 / 461.356. name_flow: 37.858 / 37.940 / 37.632. runtime_core: 199.561 / 207.710 / 134.008. O dossiê fotografou um estado intermediário que não é nem o HEAD nem a árvore atual. | N/A |
| 1468-1683 | funções por arquivo | DIVERGENTE | 4 diferenças, porque a contagem ignorou `pub fn`: `doc_sample.src` 3 (dossiê 2), `lsentience.src` 238 (234), `lume_crypto_blockchain_engine.src` 58 (27), `vec.src` 8 (4) | N/A |
| 1468-1683 | leis e testes por arquivo | CONFIRMADA | as 216 conferem; a soma da coluna de testes é 414 nos dois lados | N/A |
| 1692 | "MANIFEST.sha256, todos os 134 artefatos" | CONFIRMADA | Os 134 hashes do dossiê são **idênticos** a `MANIFEST.sha256`. Os fontes do MANIFEST batem com o HEAD (conferido com `git show HEAD:… \| sha256sum` em 9 arquivos). | N/A |
| 1692 | "verificados por `./lume self verify`" (hoje) | DIVERGENTE | `sha256sum -c MANIFEST.sha256` na árvore atual **falha em 11**: `build/bin/lasm`, `lume_driver.src`, `lasm.src`, `lcaas.src`, `levolve.src`, `runtime_core.lume`, `lume/05_codegen.src`, `name_flow.src`, `lume/06b_phase3.src`, `lume/07_driver.src` e `lumec.src`. Depois disso o porte alterou mais arquivos do MANIFEST (`lconcurrency`, `lsentience`, `lregistry`, `leconomy`, `ltv`, …), então o número de falhas só cresceu. | PENDENTE: regenerar o MANIFEST ao fim do porte |
| 1829 | `./lume bootstrap && ./lume zero-c` (ponto fixo triplo) | NÃO VERIFICÁVEL | não executado; depende do driver no WSL | PENDENTE: ainda não há driver nativo Windows para essa trilha |
| 1830 | synergy-gate (17 estágios + 36 tampers), cli-parity (114 linhas) | NÃO VERIFICÁVEL | não executado | PENDENTE: idem |
| 1831 | self-prove: 1.682 obrigações, 372 testes, 122 domínios | NÃO VERIFICÁVEL | Não executado. Para comparar: a tabela 8.1 soma 414 `test_` em produção e há 576 `fn test_` em todos os `.src` de stage1. "372" não bate com nenhuma das duas contagens diretas. | PENDENTE: idem |
| 1832 | qualify --verify: 106 probes, 21 gates | NÃO VERIFICÁVEL | não executado | PENDENTE: idem |
| 1833 | self verify, integridade dos 134 artefatos | DIVERGENTE | ver a linha 1692 acima (falha hoje) | PENDENTE |

---

## 7. Lista consolidada: falsas, divergentes e só modelo

### FALSAS (o que o dossiê descreve não existe)

1. `lsentience.src:72` `morph_egraph_saturate`: não há e-graph; o "motor" troca substrings `" + 0"` e `" * 1"` no texto.
2. `lsentience.src:78` `sentience_awaken` ("Inferência Ativa"): conta palavras-chave no fonte.
3. `lsentience.src:186` Chronos ("debugger causal reverso"): aritmética fixa, sem traço de execução.
4. `lume_reversa_engine.src` lifter SSA LumeMIR: só existe em comentário e em texto gerado.
5. `lume_crypto_blockchain_engine.src:11` HMAC-SHA256: concatenação de SHA-256 sobre texto, não RFC 2104.
6. `lume_crypto_blockchain_engine.src:17-22` carteiras HD: chave pública 5^x mod (10⁹+7), endereço `"bc1q"`+SHA; sem secp256k1, BIP32 nem bech32.
7. Domínio #56 "RFC 8446 TLS 1.3" no `std.net`: é um modelo ARX que se declara modelo (`net.src:56-76`).

### DIVERGENTES (valor ou estrutura real diferente)

1. Abertura da Parte VI, "formalmente provados": 36 de 77 obrigações do gfx e 25 de 68 do net são só `budget_checked`; `lconcurrency` e `ncm` dão `ok=false` hoje.
2. `gfx.src:31-34`: o denominador ≥ 32.400 é testado, não provado (o comentário do próprio arquivo diz isso).
3. Well-kill: FCP inexistente (`gfx.src:308-317`).
4. `net.src:521` dedução "dupla": só debita `ip_tokens`.
5. `db.src:152-168` "MVCC": cópia-sombra com uma transação por vez.
6. `decimal`+`vec`: 53 funções, não 49. `money[CCY]` não está em `decimal.src`.
7. `los.src:39` "CRC-32": é hash polinomial mod 10⁹+7.
8. `los.src:242`: 11 coreutils, não 12.
9. `levolve.src:325` gate "stage2==stage3": determinismo do asm do candidato, não o bootstrap.
10. `lsentience.src`: 238 funções, não 234.
11. reversa: ELF, Mach-O e WASM só pelo número mágico; sem JS/TS.
12. quantum: o decodificador "MWPM" é tabela de consulta.
13. crypto-blockchain: 58 funções, não 27.
14. Capstones: sentry 8/9, accounting 6/7, dfe 7/11, omniroute 6/8, brasil 8/9 e sovereign_llm_router 19/25 `proven` (não 9/9, 7/7, 11/11, 8/8, 9/9, 20/20).
15. Parte VII: rótulos §1P/§1Q dos #108-#111; ANSI 51 com curva 6900/(M−1); WAL "CRC32".
16. Parte VIII: `lumec.src` e `hostio.src` ausentes do inventário; 5 contagens de bytes de um estado intermediário; 4 contagens de função sem `pub fn`; MANIFEST não verifica mais na árvore atual.

### Só MODELO (predicado ou fórmula simplificada apresentada como engenharia completa)

- **gfx/UFE:** IK 7-DOF DLS, Laplace SOR, GNRON, colisão de cápsulas, EKF de Joseph, IAPWS-IF97 (só a região), Carnot, escalonador 1 kHz e RUL (com defeito: ignora a taxa de desgaste).
- **Subsea:** API RP 1111, VIV, DNV DAF, Bühlmann ZH-L16C (sem compartimentos) e ASME B31G (sem Folias e sem P_safe). Rasterizador e BMP só geram contagem de passos e cabeçalho.
- **gui:** Wayland/COSMIC; sessão "X11" por TCP loopback.
- **net:** Purdue/IEC 62443, DCS read-only, HA, DHT, Raft, TOFU.
- **db:** planejador; leis tautológicas.
- **los:** rede/DMA e drivers RTC/PCI/PS2 (valores e tabela fixos).
- **lconcurrency:** SPSC "lock-free" e protocolo linear.
- **lsentience:** "8 Leis Constitucionais" (sempre 1) e quântico Bell/Grover (circuito fixo).
- **Motores:** TinyUFO/Count-Min, Ketama, 7 fases do Pingora; EGM (lentes, Goldfish, drift); NCM (MS-RVQ, CFG, Sudoku fixo); openTPU (ISA decimal); Continuum (4 arquiteturas); ZX e VQE; leis UTXO, AMM e Kelly e o auditor de contratos.
- **Parte VII:** a coluna "Fórmula verificada" é toda string.

## 8. O que falta para o Windows ficar igual ao Linux (neste trecho)

1. **Sockets (Winsock) na camada `__win_syscall`.** Faltam as syscalls 41 (socket), 42 (connect), 43 (accept), 44 (sendto), 45 (recvfrom), 49 (bind) e 50 (listen), ausentes de `build/windows-native/win64_layer.s:83-153`. Os builtins estão em `compiler/stage1/lume/05_codegen.src:961`. Dependem disso:
   - em `net.src`: `:108` (loopback TLS), `:116` (`net_http_loopback_exchange`), `:117` (`net_udp_loopback_exchange`), `:133-137` (`test_tls13_rfc8446_wire_records_and_loopback_handshake`);
   - em `gui.src`: `:118` e `:165` (sessão "X11");
   - `track_l_domains_ok.src:71-74`;
   - qualquer servidor do Pingora, se um dia abrir socket de verdade.
2. **Fork com sockets.** `net.src:108/116` e `gui.src:118` fazem `os_fork` e conversam pelo socket entre filho e pai. Com o fork emulado (o filho roda até o fim antes do pai), o filho bloqueia em `connect`/`recv` esperando um `accept` que o pai ainda não chamou. Mesmo com Winsock, esses testes precisam virar processo separado via CreateProcessW, ou thread.
3. **`/bin/sh` sem emulação.** `lconcurrency.src:274` (`parallel_dispatch_partitions`) e o worker de teste (`:325-332`) geram scripts sh. O `hostio` emula mkdir, rm, chmod, mv e cp, mas não `sh`.
4. **Ferramentas Linux fixas** ainda fora do `hostio`:
   - `leconomy.src:96`: `/usr/bin/git`;
   - `lregistry.src:108`: `/usr/bin/printenv`, e `:126` (execução da suíte);
   - `lume_reversa_engine.src:351-355`: `/usr/bin/7z`, com `rm` via `hio_run_capture`.
5. **Caminhos `/root/.lume_sovereign_memory`** fixos em `lume_reversa_engine.src:350-352`, `lume_pingora_proxy_engine.src:340` e `lume_opentpu_engine.src:346`. Hoje funcionam pelo fallback em `/tmp`, mas devem usar `hio_data_dir()` (`hostio.src:23`).
6. **Toolchain e `hostio`.** O `hostio.src` chama builtins (`os_getenv`, `os_platform`, `fs_copy`, `fs_make_executable`, `fs_chmod`, `fs_rename`, `startswith`) que o `lume` instalado no WSL não conhece. Resultado: `lume prove` de `lconcurrency.src` e `lume_ncm_engine.src` (e de quem fizer `use hostio`, direta ou indiretamente) passou a dar `ok=false` com R0200. É preciso reinstalar o driver com os builtins novos antes de dizer que a verificação passa.
7. **`os_fork` emulado no teste de crash do WAL** (`db.src:220`, `:237`). Falta confirmar que `os_exit(9)` no filho emulado devolve status ≠ 0 ao `os_waitpid_status` do pai sem encerrar o processo.
8. **MANIFEST e trilha de revalidação.** Ao fim do porte, regenerar `MANIFEST.sha256` (11 falhas ou mais hoje). Os comandos do bloco final (`bootstrap`, `zero-c`, `synergy-gate`, `cli-parity`, `self-prove`, `qualify`, `self verify`) ainda só rodam pelo driver no WSL.
9. **Sem dependência de SO, já OK no Windows:** gfx/UFE/Subsea, a parte pura do gui, net (codecs, dissecadores, relés, OT, mesh), db (exceto o fork), decimal, vec, los (o `/tmp` é traduzido), levolve, levidence, lmesh, os motores egm, ncm, opentpu, continuum, quantum e crypto, e os 8 capstones e o `lsp_bridge`.
