# Auditoria Técnica Minuciosa do Projeto Lume — Claude Code Max (`claude-fable-5-1` & `claude-opus-4-8` · 1M Context)

> **Data:** 06/11/2026
> **Auditores:** Claude Code Max (`v2.1.318` — `claude-fable-5-1` / `claude-opus-4-8`, janela de 1.000.000 tokens) orquestrado via Antigravity (`@[claude-code-partner]`)
> **Repositório Auditado:** [`C:\Users\Ricardo.Bueno\lume`](file:///C:/Users/Ricardo.Bueno/lume) (`HEAD @ 9c65cf3`)

---

# Parte I — Stream 1: Compilador Self-Hosted, Bootstrap, Assembler (`lasm.src`) e 27 Targets (`ltarget.src`)

## 1. Bootstrap C11 e Compilador Self-Hosted — Arquitetura e Invariante de Fixpoint

### 1.1 Cadeia de Bootstrap
O cabeçalho de [`01_lexer.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lume/01_lexer.src) declara a intenção da cadeia:
> *"Compiled to native by `data_asm_cc` and assembled by `lume0 asm`, no C anywhere."*

A arquitetura é a clássica de três estágios:
- **Stage-0 (C11):** Lexer/parser/codegen mínimo em C que entende o subset funcional de `lume-core` e o `elf.c` que escreve ELF64. É o único ponto onde há C.
- **Stage-1 (`lumec.src`):** O compilador self-hosted escrito no próprio núcleo funcional (sem `var`/`mut`/`while`/`for`; apenas recursão, records imutáveis, `match`, `let-in`, `if`).
- **Assembler ([`lasm.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lasm.src)):** Porte funcional de `elf.c` — substitui `as`/`ld` externos.

O comentário de [`05_codegen.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lume/05_codegen.src) é explícito sobre a relação de porte: o codegen é *"the functional port of `lcgen.lume` (R6a/R6b/R6-match)"* e produz *"same output shape as `agen` in `data_asmgen.lume`"*. Ou seja, o self-hosted foi validado contra um oráculo (`data_asmgen.lume`) produzindo **asm byte-shape idêntico**.

### 1.2 Invariante `stage2 == stage3`
O fixpoint de self-hosting é a propriedade:
```text
stage2 = stage1_binary(fonte_do_stage1)      # stage1 compilado pelo stage0 compila a si mesmo
stage3 = stage2(fonte_do_stage1)             # stage2 recompila a mesma fonte
assert bytes(stage2) == bytes(stage3)        # ponto fixo
```
- Em [`01_lexer.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lume/01_lexer.src), a nota F4 sobre `elif`: *"lumec.src (which uses `else if`, never `elif`) parses unchanged and the self-host fixpoint holds."* — o autor raciocina explicitamente sobre preservar o fixpoint ao estender a sintaxe.
- Determinismo de alocação de labels: todo o estado `{nl, ns, dt, pfx}` é **threaded** e incrementado em ordem fixa de avaliação (`lnext`, `lstrlabel`), o que é pré-condição para saída reprodutível. O prefixo `pfx` por função evita colisão de labels entre funções sem contador global mutável.
- **Risco sutil sobre o invariante:** Na **tabela de símbolos com 256 buckets** (`symbucket_put` em [`lasm.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lasm.src)), a ordem das entradas dentro de um bucket é *"newest first"* (prepend). Como `symaddr_bucket` retorna o **primeiro** match, redefinições de um mesmo nome resolvem para a última inserção. Como a ordem depende apenas da ordem do source, o fixpoint se mantém, mas merece um teste de regressão dedicado para colisão de hash.

---

## 2. Front-End: Lexer (`01_lexer.src`) e Parser (`02_parser.src`)

### 2.1 Lexer — Qualidade
- `lexn_acc(s, n, i, ls, acc)` é **tail-recursiva** e passa `n = count(s)` uma única vez (`lex` → `lexn(s, count(s), i)`), evitando `strlen` por caractere. O rastreamento de coluna via `ls` (início de linha) é limpo.
- Tratamento de decimais com limites de domínio explícitos em `decscan`: aborta com `ctfail` ao exceder 18 dígitos de coeficiente/escala — falha de compilação nomeada, não overflow silencioso.
- Escape de strings em `unescl_acc` + `strval`/`joinall(own ...)` — decodificação correta de `\n\t\r`.
- **Inconsistência a observar:** Coexistem duas famílias de scan numérico: `numend`/`decimalend` (que chamam `count(s)` por caractere → $O(n^2)$ sobre o token) e `numendn`/`decimalendn` (que recebem `n` e são $O(n)$). O lexer ativo usa as versões `*n` (corretas); recomenda-se remover ou marcar as versões sem `n` como spec-only.

### 2.2 Parser — Precedência e Threading
- **Desaçúcar no front-end (F4):** `if/elif/else` vira `If` aninhado (`parseifcore`/`parseifelif`); interpolação de strings `"a{e}b"` vira cadeia `+`/`str(...)` (`strinterp`/`strinterploop2`) gerando **exatamente a mesma AST** que a concatenação explícita.
- **Diagnósticos fail-closed com código:** `parseifcore` rejeita `else else`, `then then`, `else elif` com `[P0002]`.
- **Invariante arquitetural do `match`:** Em [`02_parser.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lume/02_parser.src), `match` aparece apenas como o corpo inteiro de uma função/let-in/print. A delimitação de arms é por lookahead (`isarrow`, `ispatkw`) e por coluna (`parsearms(ts, mincol)` com `headcol`). Como o lexer é layout-blind, a corretude depende de `col = i - ls` e de que arquivos usem LF puro (`\n`).

---

## 3. Codegen x86-64 (`05_codegen.src`) e Runtime

### 3.1 Modelo de Execução e Otimizações Reais
- **Cache de small ints** (`lume_init_small_ints`, `mkint` para `-1..1024`) — evita alocação no heap para os inteiros mais comuns.
- **Join $O(n \log k)$ de asm** (`pairs`/`pairs2`/`joinall(own ...)`) em vez de cadeia `+` right-nested $O(n^2)$.
- **Peephole `ord(at(s,i))`** fundido em `lord_at` — evita duas chamadas e um box intermediário.
- **Intrínsecos bit-vector** (`lbv2`/`lbv1`, `lis_bv2_call`) e **quantificadores** `forall_range`/`exists_range` (`lquant`) compilados inline.
- **Perceus reuse** (`__perceus_reuse_1/2` → `lreuse1`/`lreuse2`): mutação in-place guiada por reference counting.
- **SRA (Stack Record Allocation):** Records locais de forma conhecida viram offsets diretos no frame sem `call mkrec`/`call recget`.

### 3.2 Gargalos do Codegen e Runtime
- **Múltiplas passadas por função:** `lcollect`, `lmdepth` e `lpatbinds` percorrem a AST da função separadamente antes de gerar código ($O(\text{nós} \times \text{passadas})$).
- **`recget` é busca linear** (`rg0`/`streq` sobre as keys) quando a SRA não dispara ($O(\text{campos})$ por acesso).
- **Alocador bump sem GC geral:** `alloc` usa bump pointer com crescimento via `brk`/`mmap` (`alloc_grow`) e recuperação apenas via Perceus e arenas (`with alloc`, `scope`).

---

## 4. Assembler [`lasm.src`](file:///C:/Users/Ricardo.Bueno/compiler/stage1/lasm.src) — Duas Passagens, Hash 256, ELF/PE/Kernel/ISO

- **Pipeline de duas passagens (`layout` + `emitcode2b`):** Faz *encode-once* na Pass 1 (`enc(r, 0, Nil)`) e re-encoda na Pass 2 **apenas** instruções que dependem de relocação (`needsreloc`: jumps/calls/jcc ou `%rip`). Elegante e eficiente.
- **Modo strict fail-closed (`[L0001]`):** `chksym`/`chkinsref`/`chkrefs`/`chkentry` abortam no primeiro símbolo não resolvido antes de emitir qualquer byte ELF.
- **Tabela de símbolos (256 buckets):** `symhash_i` (base-31 mod 256) + `symbucket_put`. Como `lume-core` não tem arrays mutáveis indexáveis, `symaddr_h` percorre a lista de até 256 buckets + a assoc-list do bucket ($O(\text{buckets\_distintos} + \text{profundidade})$).
- **Gargalo transversal mais importante (`G1`):** O binário final é montado via `emitall(app(hdrs, app(code, tail)))`, onde `app` **não é tail-recursiva** (`Cons(h, app(t, ys))`). Para binários grandes, `app(code, tail)` consome pilha nativa proporcional ao número de bytes.

---

## 5. [`ltarget.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/ltarget.src) e [`lume_driver.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lume_driver.src)

- **Assimetria de escopo entre backends (`R2`):** Enquanto `05_codegen.src` compila o Lume-Core completo (`match`, records, construtores, strings, decimais), o front-end embutido em `ltarget.src` (`tg_atom`) rejeita `{`, `[` e `match` com `TUnsupported`, suportando apenas o fragmento aritmético/condicional (`TNum/TStr/TBin/TIf/TLet/TCall/TVar/TTrap`).
- **PE64-GUI (`wgui_*`, `R3`):** É um gerador baseado em template binário parametrizado por slots de string (`app_window_title`, etc.), e não um backend de codegen geral.
- **Preservação de prova (`H5`):** Genuína e bem desenhada dentro do fragmento suportado — elide guards provados (`guards_elided`), emite trap nativo (`__trap__`, exit 3) para `runtime_checked`, e recusa em tempo de compilação (`[V0001]`) contratos refutados.
- **Driver (`lume_driver.src`):** Cache de binário por SHA-256 (`build-fast-v2`) bem isolado, mas `ld_request` usa `/tmp/lume-driver-<pid>` sem contador monotônico, `ld_self_prove_entry` traz algumas contagens como constantes de string no JSON de relatório, e há caminhos absolutos do ambiente local hard-coded.

---

# Parte II — Stream 2: Verificação Formal (`lcaas.src`), Kernel de Provas (`lcert.src`), Segurança P33 e Matriz de Aceitação

## 1. Soundness do Provador `QF_LIA` / `QF_NIA` / `SL` e do Kernel [`lcert.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lcert.src) (`lume-minimal-kernel-v1`)

### 1.1 Arquitetura de Confiança (O Ponto Mais Forte do Design)
O kernel [`lcert.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lcert.src) é um **verificador independente de termos de prova**. Em `lk_verify_pair1`, para cada obrigação `proven`, ele exige `lk_prove_term(t_str) == 1` e **rejeita independentemente do `status` armazenado** se o seu próprio motor não re-derivar o termo:
```lume
else if lk_prove_term(t_str) == 0 then
  {ok:0, ... reason: "independent QF_LIA kernel rejected proof term for '"+o_nm+"': "+t_str}
```
Um certificado forjado só passa se contiver termos de prova genuinamente válidos sob o motor do kernel.

### 1.2 `QF_LIA` — Fourier-Motzkin + Tightening Inteiro: **Sound, Incompleto**
- **`lk_fm_fdiv` / `lk_fm_tighten_h`:** Para hipótese de uma variável $a \cdot x + c_0 \ge 0$, divide por $|a|$ com divisão por piso ($x \ge \lceil -c_0/a \rceil$ para $a>0$; $x \le \lfloor c_0/|a| \rfloor$ para $a<0$). **Tightening inteiro correto (sound).**
- **Resolventes FM (`lk_fm_pair1`):** $c_n \cdot p + c_p \cdot n$ com $c_n, c_p > 0$ — combinação não-negativa de dois fatos $\ge 0$. **Sound.**
- **Contradição (`lk_lin_is_contra`):** Detecta constante $c_0 < 0$ sem variáveis. **Sound.**
- **Bail-outs conservadores:** `lk_fm_pairs` (`>24`) e `lk_fm_unsat1` (`>48`) retornam `0` ("não consegui provar UNSAT"), nunca `1` falso. **Incompletude segura, não unsoundness.**

### 1.3 `QF_NIA` — `lk_nia_enrich_hyps`: **Sound por Construção (Fragmento Positivstellensatz Grau 2)**
- `lk_nia_sq_hyps`: $v \cdot v \ge 0$. ✓
- `lk_nia_all_diff_sq`: $(v_1 \pm v_2)^2 \ge 0$, expandido via `lk_lin_mul` com chaves normalizadas (`lk_mono_key`). ✓
- `lk_nia_prod_hyps` / `lk_nia_prod_pair`: $(v_1 - lb_1)(v_2 - lb_2) \ge 0$ emitido somente quando limites reais são conhecidos (`lb >= 0`, `ub < 999999`). ✓
- `lk_nia_mono_hyps`: $(x - y)(z - lb) \ge 0$ dado $x \ge y, z \ge lb$. ✓

### 1.4 Lacunas Concretas no Kernel (`F1`–`F4`)
1. **`terminates` sintático (`F1` — Alta):** Em `lk_prove_sx`, `else if tag == "terminates" and lk_len(xs) == 3 and lk_svar_name(...) != "" then 1` aceita qualquer termo `(terminates <medida> <...>)` bem-formado sem provar o decréscimo da medida via `QF_LIA`.
2. **Cobertura do conjunto de VCs (`F2` — Alta):** `k_ok` verifica `total = lk_len(obls)` presentes no certificado, mas não confronta esse total com o número canônico de obrigações do código-fonte.
3. **Propriedades temporais (`F3` — Alta):** `temporal-always`/`eventually`/`until` reduzem a implicações locais `QF_LIA` (`lk_prove_all_implies`), funcionando como indução de passo (sem verificação de liveness/fairness sobre traços infinitos).
4. **Separation Logic (`F4` — Média):** `sep_disjoint(a, b)` é provado como `a != b` (distinção de ponteiros/identificadores, não disjunção de intervalos `[base, base+len)`).

---

## 2. Criptografia FIPS 180-4 SHA-256, Proteção P33 e Evidências Portáteis

- **SHA-256 (`lcert.src`, `lprotect.src`, `protect.src`):** IVs (`0x6a09e667..0x5be0cd19`), constantes $K[0..63]$, padding big-endian de 64 bits e funções $\sigma_0, \sigma_1, \Sigma_0, \Sigma_1, \text{Ch}, \text{Maj}$ estão **fiéis ao FIPS 180-4**.
- **Evidências Portáteis ([`levidence.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/levidence.src)):** Design sólido. `ev_build` re-executa `caas_compile(source)`, `ev_counts_verdict` força `UNKNOWN` sempre que `runtime_checked > 0` (preservando a fronteira decidível vs. runtime), e `ev_verify` calcula invalidação incremental por fecho transitivo no grafo de dependências.
- **Proteção P33 ([`lprotect.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lprotect.src) / [`protect.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/protect.src)):**
  - `protect.src` tem identidades MBA algebricamente corretas (`mba_add`, `mba_sub`, `mba_xor`) e uma VM de bytecode com ISA randomizada por seed (`vm_specialize_isa` / `vm_exec`) que é uma técnica legítima de ofuscação.
  - Em `lprotect.src`, `lp_mba_prologue` faz XOR duplo com a mesma máscara (no-op) e a cifra de `.rodata` é XOR de 1 byte (`k ∈ [131, 250]`), portanto deve ser documentada como **ofuscação contra inspeção estática (`strings`)**, e não criptografia forte.

---

# Parte III — Stream 3: Standard Library, Quantum Nexus Engine, Capstones e Ecossistema

## 1. Standard Library e Quantum Nexus Engine

### 1.1 [`db.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/db.src)
- **O que está sólido:** `bm_split_inner` e `bm_insert_rec` propagam o split corretamente (a chave do meio sobe), `bm_balanced` verifica altura uniforme, `db_restore_snapshot_file` valida o SHA-256 do corpo, e `db_replay_wal_lines` descarta transações não commitadas.
- **Achados principais:**
  1. `db_put` usa `btree_insert_node` (seção 1, sem rebalanceamento) em vez da B+Tree balanceada `bm_insert` (seção 4).
  2. `db_migrate_schema_v2`, `db_backup_snapshot_file` e `db_wal_encode` usam `btree_range_scan(..., -1000000, 1000000)`, descartando chaves fora de $\pm 10^6$.
  3. Há dois formatos de WAL (`PUT k v c` em `db_wal_encode` vs. `OP tx k v c ck` em `db_wal_recover_file`).

### 1.2 [`net.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/net.src)
- **O que está sólido:** `ipv4_parse` estrito, `tcp_rfc793_words` monta o pseudo-header corretamente, e há bons testes negativos (UDP adulterado, tag inválida, HTTP malformado).
- **Achados principais:**
  1. As funções `tls13_*` usam hash polinomial mod $10^9+7$ e XOR stream (`k % 251`) — servem como modelo de máquina de estados de protocolo, não criptografia RFC 8446 real.
  2. As provas da seção 7 estão em funções-sombra (`net_ansi50_trip_decision`), separadas das funções principais (`ansi50_instantaneous_overcurrent`).
  3. `sw_p4_pipeline_exec` passa `dis.vlan_id` como VLAN permitida em `sw_vlan_port_admit`, tornando `DROP_VLAN_VIOLATION` inalcançável.
  4. Off-by-one em `iec61850_goose_dissect` (`nb == 19`) e `iec61850_sv_dissect` (`nb == 20`), e `net_isqrt` com 20 passos fixos não converge para $n \gtrsim 10^{12}$.

### 1.3 [`nn.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/nn.src) e [`tensor.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/tensor.src)
- **O que está sólido:** `sha256_hex` validado com vetor `"abc"`, autodiff reverso em fita (`gx == 392`, `gw == 784`) e `mlp2_grad` com hinge loss exatos.
- **Achados principais:**
  1. `nn_le64_hex(v)` faz `if v < 0 then 0 else v`, zerando pesos negativos na exportação binária.
  2. `KIf` em `kernel_lower_ptx_e` e `kernel_lower_spirv_e` avalia ambos os ramos (`selp`/`OpSelect`), podendo dividir por zero se um ramo tiver divisão condicional.
  3. `tensor.src` usa listas encadeadas (`t_nth` $O(n)$ por acesso) sem checagem de shape em `tensor_add`/`matmul`.

### 1.4 [`lume_quantum_nexus_engine.src`](file:///C:/Users/Ricardo.Bueno/lume/compiler/stage1/lume_quantum_nexus_engine.src)
- **O que está sólido:** Regras de conjugação do tableau (`q_stab_row_apply_h`, `_s`, `_cnot`), parameter-shift de $\pm 90^\circ$, reversibilidade $U \cdot U^\dagger$ zerando ancilla, e `q_ergonomics_10_10_pipeline`.
- **Achados principais:**
  1. `q_surface_x_syndrome_for_mask` reutiliza os suportes de $Z$ (cujos pesos 5 e 3 têm interseção ímpar $\{4\}$), e `q_surface_decode_syndrome` é uma tabela de lookup de 9 entradas.

---

## 2. Capstones, Skill Oficial (`skills/lume/SKILL.md`) e Extensão VS Code

- **Capstones (`pix_fraud_trace`, `sentry_uav_guard`, `verified_accounting`, `dfe_pix_bacen`, `omniroute_guard`, `brasil_public_id`):**
  - Todas as contagens de provas batem 100% com os certificados (`8, 7, 5, 7, 6, 6`).
  - `pix_med_freeze_cents` e `omniroute_confidential_sovereignty_law` são exemplos de contratos totais e leis não-triviais; outras leis apenas repetem o `ensures` ou identidades algébricas simples (`x - x == 0`) e podem ser enriquecidas com propriedades de composição (ex.: conectar `compute_tax_retention_cents` com `compute_net_liquid_cents` adicionando `ensures result <= gross_cents`) e testes negativos/de fronteira.
- **Skill Oficial ([`skills/lume/SKILL.md`](file:///C:/Users/Ricardo.Bueno/lume/skills/lume/SKILL.md)):**
  - Documentar explicitamente a lista de builtins (`count`, `at`, `slice`, `ord`, `chr`, `toint`, `fs_*`, `os_*`), o limite de 6 parâmetros no Stage-1 `.src`, e o idioma `if P then Q else 1 == 1` para implicação em `law`.
- **Extensão VS Code ([`editors/vscode-lume/package.json`](file:///C:/Users/Ricardo.Bueno/lume/editors/vscode-lume/package.json)):**
  - Gramática e tema Dracula Lume prontos; próximo passo natural é acoplar um cliente LSP leve invocando `lume lsp` / `lume prove` inline.

---

## Quadro Consolidado de Prioridades de Engenharia (Action Plan)

| Prioridade | Frente | Ação Recomendada |
|---|---|---|
| **P0** | **Assembler (`lasm.src`)** | Substituir `app(hdrs, app(code, tail))` não-tail-recursivo por acumulador reverso tail-recursivo (`rev_append`) ou emissão direta via `emitall` em sequência, eliminando o teto de pilha para binários grandes. |
| **P0** | **Kernel de Provas (`lcert.src`)** | Em `lk_prove_sx`, exigir prova `QF_LIA` de decréscimo da medida para `terminates` (ou marcá-lo `runtime_checked`) e vincular o total canônico de VCs ao certificado. |
| **P0** | **Stdlib (`db.src` / `nn.src` / `net.src`)** | Conectar `db_put` à árvore balanceada `bm_insert`, remover o limite fixo $\pm 10^6$ no scan de backup/migração, corrigir `nn_le64_hex` para pesos negativos (complemento de dois 64-bit), e corrigir o admit de VLAN e off-by-one GOOSE/SV em `net.src`. |
| **P1** | **Capstones & Contratos** | Fortalecer `verified_accounting` (`ensures result >= 0 and result <= gross_cents`), usar as `const` declaradas em `pix_fraud_trace`, e adicionar testes de fronteira em todos os 6 capstones. |
| **P1** | **Catálogo de Targets (`ltarget.src`)** | Explicitar no JSON de `ltarget.src` o `language_subset` de cada target (`full-core` vs `arith-cond-subset` vs `gui-template`). |
| **P2** | **Skill & VS Code** | Adicionar tabela completa de builtins e regras de `.src` vs `.lume` em `skills/lume/SKILL.md` e cliente LSP na extensão `vscode-lume`. |
