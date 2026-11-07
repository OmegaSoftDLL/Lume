# Dossiê Técnico Oficial: A Saga da Memória e o Compactador Atômico de 4 Camadas da Lume

**Status:** Em Produção na `main` (`fa9a3ea`, ponto fixo Zero-C `stage2 == stage3`)  
**Hardware de Referência:** Intel Core Ultra 5 135U (WSL2 x86-64 Linux & Windows 11 x64 PE32+)  
**Implementação 100% Lume:** [`compiler/stage1/runtime_core.lume`](../compiler/stage1/runtime_core.lume), [`compiler/stage1/lume/05_codegen.src`](../compiler/stage1/lume/05_codegen.src), [`compiler/stage1/data_asmgen.lume`](../compiler/stage1/data_asmgen.lume), [`compiler/stage1/own_flow.src`](../compiler/stage1/own_flow.src), [`compiler/stage1/name_flow.src`](../compiler/stage1/name_flow.src), [`compiler/stage1/arena_mem.src`](../compiler/stage1/arena_mem.src)

![Evolução da Saga da Memória e Compactador Atômico da Lume](assets/lume-memory-evolution-animated.svg)

---

## 1. Sumário Executivo — A Jornada ("Lume gera Lume")

Ao longo de três gerações arquiteturais — **Geração 1 (Baseline Bump Allocator)**, **Geração 2 (Rodada 5: Coletor Mark & Lazy-Sweep Segregado, Ownership v2 e Paridade In-Process)** e **Geração 3 (Rodada 6: Compactador Atômico de Memória em 4 Camadas — Etapa 0 + Níveis 1, 2 e 3)** — a linguagem Lume transformou radicalmente seu modelo de valores, memória e velocidade:

* **`31,8×` mais rápida em loops de inteiros (`b_loop`, 100 milhões de iterações):** o tempo despencou de **`2.796 ms` para `88 ms`**, as alocações no heap caíram de **`200.000.000` para `1`** e o pico de RAM caiu de **`68 MB` para `0,39 MB` (`390 KB`)**;
* **`10,1×` menos RAM e `4,3×` mais rápida na autocompilação do `lumec`:** o pico de memória caiu de **`1.165 MB` para `115 MB`** e o tempo de compilação caiu de **`1.908 ms` para `445 ms`** (reduzindo o binário ELF do `lumec` em **`34%`**, de `1,52 MB` para `1,01 MB`);
* **`23,6×` menos RAM e `9,0×` mais rápida no bootstrap completo a partir da semente C:** caiu de **`200 s / 12,7 GB` para `22 s / 537 MB`**;
* **`2.733×` menos RAM em cargas intensivas de strings (`b_str`):** caiu de **`6.013 MB` para `74 MB` (R5) e `2,2 MB` (R6)**, reduzindo `42.600.000` alocações para apenas **`17`**;
* **`3,9×` mais rápida na suíte completa de `410` testes:** caiu de **`529 s / 2,49 GB` para `136 s / 537 MB`**, blindada por **`75.512` casos na matriz diferencial de valores**, **`317/317` programas adversários de Red-Team (`0 crashes`)**, **`159/159` na bateria semântica** e **`1.500/1.500` testes de fuzzing no descompressor Nível 3**.

---

## 2. Geração 1: Diagnóstico Empírico e Radiografia do Heap Vivo de `830,9 MB`

### 2.1 Por que a Geração 1 Consumia Gigabytes de RAM?
Antes da Rodada 5, tanto a semente interpretada (`lume0`) quanto o runtime nativo x86-64 usavam alocação linear sem coleta e colocavam praticamente todo valor em células no heap:
1. **Semente Stage-0 (`bootstrap/lume0/value.h`):** Cada struct `Value` ocupava **`200 bytes`**, fazendo a compilação do `lumec.src` pela semente gastar **`102,0 s` e `12,5 GB` de RAM**.
2. **Células Nativas Desalinhadas no Heap:**
   - Cada `int` fora de `[-1, 1024]` alocava uma célula de **`24 bytes`**.
   - Em `05_codegen.src:141` (`fn lstr`), cada avaliação de literal de string (`"0"`, `"a"`, `"9"`, `"z"`) chamava `mkstr` em tempo de execução, alocando **`24 bytes`** no heap para apontar para uma string que já estava em `.rodata`.
   - Cada variante de Enum de aridade 0 (`Nil`, `None`, `True`, `False`) alocava **`40 bytes`** no heap a cada uso.
   - Cada `Cons(int, cauda)` consumia **`80 bytes` vivos** (`56 B` do construtor + `24 B` do inteiro) mais `48 B` de lixo temporário.
   - Cada registro de 3 inteiros `{a, b, c}` consumia **`160 bytes`** (`88 B` + `72 B`) e copiava os ponteiros das chaves em toda instância, fazendo busca linear com `streq`.
   - O alocador `alloc` não alinhava em 8 bytes (`87,8%` das células ficavam desalinhadas).

### 2.2 Radiografia Real do Heap do `lumec` (`830.963.712` bytes via `/proc/<pid>/mem`)
Durante o projeto do Compactador Atômico, uma sonda (`snap.py` + `ana.py`) capturou e classificou um retrato real de **`830,9 MB`** do heap do `lumec` compilando a si mesmo (`600.558` bytes de fonte $\rightarrow$ `6.165.320` bytes de assembly):

| Classe de Objeto no Heap do `lumec` | Quantidade de Objetos | Bytes Ocupados | % do Heap | Descoberta Empírica Decisiva |
|---|---:|---:|---:|---|
| **1. Cabeçalhos de Literais de String em `.rodata` (`str_ro`)** | `11.861.855` | `284.684.520 B` (**285 MB**) | **34,3%** | `lstr` chamava `mkstr` em cada comparação de caractere do lexer (`"0"` alocado `469.180` vezes; `"a"` `444.817` vezes; `"9"` `344.352` vezes; `"z"` `289.856` vezes; `"\n"` `236.420` vezes!). |
| **2. Bytes Brutos de Conteúdo de Strings (`rawbyte`)** | `312.873.913` | `312.873.913 B` (**313 MB**) | **37,7%** | Buffers intermediários de concatenação de strings durante a geração de assembly. |
| **3. Construtores de ADTs (`ctor`)** | `1.734.448` | `69.377.920 B` (**69 MB**) | **8,3%** | Aridades: `aridade 0` = `502.012` (**20,1 MB** só de `Nil`/`None`!), `aridade 1` = `81.793`, `aridade 2` = `1.087.077` (`Cons`), `aridade 3` = `63.541`. **`96,3%` têm aridade $\le 2$**. |
| **4. Cabeçalhos de Strings Dinâmicas no Heap (`str_heap`)** | `2.510.376` | `60.249.024 B` (**60 MB**) | **7,2%** | **`74,9%` a `94,9%` das strings curtas no heap têm $\le 7$ bytes** (cabem inteiras dentro de 1 palavra de 64 bits!). |
| **5. Vetores de Ponteiros (`ptrword`)** | `6.737.396` | `53.899.168 B` (**54 MB**) | **6,5%** | Vetores de campos de construtores e chaves/valores de registros. |
| **6. Registros (`rec`)** | `655.845` | `26.233.800 B` (**26 MB**) | **3,2%** | Repetiam os ponteiros dos nomes dos campos em cada instância. |
| **7. Inteiros Encaixotados (`int`)** | `985.222` | `23.645.328 B` (**24 MB**) | **2,8%** | **`100,0%` (`985.222 / 985.222`) cabem em 62 bits assinados** (`89,2%` cabem em 31 bits), mas cada um ocupava `24 B` no heap. |
| **Total Radiografado** | **17.747.746 células** | **`830.963.673 B` (831 MB)** | **100,0%** | Alinhamento antes da R5: `15.578.321` desalinhadas (`87,8%`) vs. `2.169.425` alinhadas em 8 bytes (`12,2%`). |

---

## 3. Geração 2: Rodada 5 — Coletor Mark & Lazy-Sweep Segregado, Ownership v2 e Oráculo Real

A Rodada 5 construiu os alicerces de coleta de memória, alinhamento e segurança estática/dinâmica:

1. **Compactação da Semente C e Coletor Stage-0 (`bootstrap/lume0/value.h`, `value.c`, `interp.c`):**
   - Reduziu `Value` de **`200 bytes` para `64 bytes`** e adicionou coletor Mark-Sweep próprio validado sob **ASan + UBSan (`170 passed, 0 failed`)**, derrubando a compilação do `lumec.src` pela semente de **`102,0 s / 12,5 GB` para `5,5 s / 472 MB`**.
2. **Runtime Nativo Unificado e Coletor Mark & Lazy-Sweep ([`compiler/stage1/runtime_core.lume`](../compiler/stage1/runtime_core.lume)):**
   - Fonte única de verdade compartilhada por `05_codegen.src` e `data_asmgen.lume` (verificada por `runtime_sync_gate.src`).
   - Alocador alinhado em 8 bytes sobre chunks de **64 KiB** em **43 classes de tamanho** até 32 KiB, separando objetos com ponteiros (`__gc_map_s`) de objetos atômicos sem ponteiros (`__gc_map_a`).
   - Varredura preguiçosa por classe de tamanho (`__gc_sweep_chunk`) e devolução imediata de páginas livres ao kernel Linux via **`sys_madvise(..., MADV_DONTNEED)`**, além de arenas `mmap` independentes que nunca travam o heap principal.
   - Isolamento completo dos rótulos internos do runtime sob o prefixo `.Lrt_*` (`0` colisões com código de usuário).
3. **Ownership v2 e Unicidade Perceus Estrita ([`compiler/stage1/own_flow.src`](../compiler/stage1/own_flow.src), [`compiler/stage1/name_flow.src`](../compiler/stage1/name_flow.src)):**
   - Classes de equivalência de aliases (`rid`), caminhos sensíveis a campo (`r.a` vs `r.b`), empréstimos NLL (`&x`, `&mut x`), recursos lineares obrigatórios em todos os ramos (`[O0004]`) e reuso Perceus exclusivo quando a unicidade é provada (`pu_uses <= 1`).
   - Novos diagnósticos fail-closed: `[R0201..R0205]`, `[D0002..D0004]`, `[L0003]`, `[L0010]`, `[P0002]`, `[C1001]` e `[T1002]`.
4. **Aritmética de 64 Bits Verificada em Hardware e `lumec` In-Process no `lcaas` e `lfmt`:**
   - `+`, `-`, `*` disparam `jo __rt_ovf` (`lume: integer overflow`, exit 3) e `rt_idiv` protege `INT64_MIN / -1` e `% -1` sem `SIGFPE`, enquanto `+%`, `-%`, `*%` realizam wrapping explícito.
   - `lcaas.src` e `lfmt.src` passaram a rodar o compilador `lumec` real dentro do processo sob `__lume_try_begin`, zerando as divergências do oráculo (`0/547`) e a corrupção do formatador (`0/233`).

---

## 4. Geração 3: Rodada 6 — O Compactador Atômico de Memória (Etapa 0 + Níveis 1, 2 e 3)

### 4.1 A Inovação Central: Compactação Algébrica de 0–1 Ciclo vs. Compressão de Fluxo de Bytes
O estudo de viabilidade provou por que o caminho quente da RAM deve usar **empacotamento algébrico/estrutural em registrador (Opção A)** enquanto a compressão de blocos (Opção B) deve atuar apenas em **arenas frias, cápsulas e blobs (Nível 3)**:

| Métrica | **Opção A: Compactador Atômico em Palavra de 64 Bits (Níveis 0–2)** | **Opção B: Compressão LZ4 por Objeto em Cada `alloc`/Leitura** |
|---|---|---|
| **Custo para Empacotar (`pack`)** | **0 a 1 ciclo de CPU** (`leaq 1(%rax,%rax), %rax` / bit-shift em registrador) | **~83 ns (250 a 330 ciclos de CPU)** por célula de 64 B |
| **Custo para Descompactar (`unpack`)** | **0 a 1 ciclo de CPU (0,25–0,33 ns)** (`sarq $1, %rax` em registrador) | **~13 ns (40 a 50 ciclos de CPU)** + cópia em memória |
| **Impacto no Cache L1 (32 KiB)** | **Multiplica a capacidade efetiva da L1 por `3× a 5×`** (valores vivem em registradores / 8 B) | **Reduz a capacidade da L1** (precisa guardar a cópia comprimida + a descomprimida) |
| **Loop de 100M de Inteiros (`b_loop`)** | **`88 ms` (`0,88 ns/iter`, `1` alocação, `0,39 MB` de RAM)** | **~9.000 ms (`90 ns/iter`)** — `102×` mais lento |
| **Segurança (`[C0009]` e `@bound` `[V0002]`)** | **Tempo constante (1 ciclo), imune a *Decomp+Time* e 100% determinístico** | Vulnerável ao ataque *Decomp+Time* (IEEE S&P, vaza 49 bits/min) e quebra WCET |

### 4.2 As 4 Camadas do Compactador Atômico da Lume

#### Etapa 0: Literais, Descritores e Formas Endereçados por Conteúdo em `.rodata`
- Literais de string, descritores de construtores, formas (`shapes`) de registros e chaves internadas residem em `.rodata` sob rótulos calculados a partir do seu conteúdo (com suporte a `.quad <rotulo>` em [`lasm.src`](../compiler/stage1/lasm.src) e [`elf.c`](../bootstrap/lume0/elf.c)), com **uma única cópia por conteúdo**.
- Dois textos distintos que gerem o mesmo rótulo abortam a compilação imediatamente (colisão nunca vira dado errado).
- Em builds protegidos (`--protect hardened/max` em [`lprotect.src`](../compiler/stage1/lprotect.src)), literais estáticos e strings curtas são criptografados para não expor texto em claro no binário.
- Construtores sem carga (`Nil`, `None`, etc.) usam o próprio descritor estático `[self][(0<<8)|2][name]` como célula única — alocando **`0 bytes`** em tempo de execução.

#### Nível 1: Palavra Marcada de 64 Bits (Imediatos em Registrador e Aritmética Inline)
Como todas as células e descritores estão alinhados em 8 bytes (3 bits baixos `000`), qualquer valor da linguagem é representado por uma única palavra de 64 bits (`8 bytes`):

```text
63                                                             3   2   1   0
+---------------------------------------------------------------+---+---+---+
|            Inteiro Assinado de 63 bits (word >> 1)            |   |   | 1 |  --> Tag ...1   : Inteiro de 63 bits (0 B no heap)
+---------------------------------------------------+-----------+---+---+---+
|     bytes [7..1]: ate 7 bytes UTF-8 inline        | tam[5..3] | 0 | 1 | 0 |  --> Tag ...010 : String curta SSO <= 7 B (0 B no heap)
+---------------------------------------------------+-----------+---+---+---+
|           Endereco alinhado em 8 bytes (celula / .rodata)     | 0 | 0 | 0 |  --> Tag ...000 : Ponteiro para Celula / Descritor
+---------------------------------------------------------------+---+---+---+
```

- **Semântica Completa de 64 Bits Mantida:** Inteiros que cabem em 63 bits (`100%` dos inteiros do compilador) ficam diretamente na palavra (`...1`). Valores que usam o 64º bit (`INT64_MIN` / `INT64_MAX`) usam automaticamente uma célula compacta de `16 bytes` `[3][valor]`, e qualquer overflow além de 64 bits para o programa com `jo __rt_ovf`.
- **Forma Canônica Única:** Um inteiro que cabe em 63 bits *nunca* é encaixotado em célula, e uma string de até 7 bytes *nunca* vai para o heap. Por isso, `x == "a"`, `c >= "0"` e `x == 5` compilam para **uma única instrução `cmpq` de registrador**, e `at(s, i)` / `chr(n)` devolvem a string de 1 byte diretamente no registrador com **`0 bytes` alocados no heap** (**superando a `String` do Rust**, que exige 24 B + alocação no heap!).
- **Codegen Inline (`05_codegen.src` e `data_asmgen.lume`):** Soma, subtração (`subq` preservando flags), comparações que viram salto condicional direto e carregamento de literais sem tocar na pilha.

#### Nível 2: Células Compactas de ADTs e Registros com Shape Compartilhado
A primeira palavra de qualquer célula no heap diferencia células primitivas/atômicas (tag ímpar) de células estruturadas (ponteiro par para o descritor/shape estático em `.rodata`):

| Tipo de Valor / Célula | Tamanho Antes (Gen 1 / R5) | **Tamanho Agora (Rodada 6 `fa9a3ea`)** | Economia de Memória |
|---|---|---|---|
| **`int` de 63 bits** | `24 B` no heap | **`0 B` no heap** (na própria palavra `...1`) | **-100% de heap (`24 B -> 0 B`)** |
| **`int` de 64º bit (`INT64_MIN/MAX`)** | `24 B` no heap | **`16 B`** `[3][valor]` | **-33,3% (`24 B -> 16 B`)** |
| **String curta de até 7 bytes (`at`, `chr`)** | `~40 B` (`24 B` + texto) | **`0 B` no heap** (inline na palavra `...010`) | **-100% de heap (vence `String` do Rust!)** |
| **Literal de string estático** | `24 B` por avaliação | **`0 B` no heap** (célula estática deduplicada) | **-100% de heap (`285 MB -> 0 B` no `lumec`)** |
| **String longa dinâmica (`> 7` bytes)** | `24 B` hdr + `8 B` ptr + tam | **`9 B + tamanho`** `[(len<<8)\|1][bytes][NUL]` (atômica, não varrida pelo GC) | **-23 B por string** |
| **`Nil` e variantes sem campos** | `40 B` por uso | **`0 B` no heap** (uma célula estática compartilhada) | **-100% de heap (`20,1 MB -> 0 B` no `lumec`)** |
| **Construtor de ADT (`n` campos)** | `40 B + 8 B * n` | **`8 B + 8 B * n`** `[descritor][campos...]` | **`Cons(int, cauda)`: `80 B -> 24 B` (-70%)** |
| **Registro (`n` campos)** | `40 B + 16 B * n` (+ ints) | **`8 B + 8 B * n`** `[shape_compartilhado][valores...]` | **Registro de 3 ints: `160 B -> 32 B` (-80%)** |
| **Lista (`n` elementos)** | `40 B + 8 B * n` | **`16 B + 8 B * n`** `[(len<<8)\|5][elementos...]` | **-24 B no cabeçalho** |

#### Nível 3: Compactador de Arenas Frias (Paginação sob Demanda) e Cápsulas/Bytecode `LZ1`
Para dados frios, arenas congeladas, cápsulas `.lcaps` e pacotes de bytecode `.lumb`:
- **`mem_pack(s)` e `mem_unpack(blob)`:** Usam o formato de bloco LZ4 atrás de um cabeçalho de 20 bytes (`magic = "LZ1\x1a"`, comprimento original de 64 bits e checksum de 64 bits dos bytes originais), operando a **`~355 MB/s` na compressão** e **`~975 MB/s` na descompressão**. Qualquer corrupção de tamanho, offset ou checksum para imediatamente com `lume: packed data is corrupt` (exit 3), validado contra **1.500 blobs corrompidos de fuzzing**.
- **`arena_freeze(a)`, `arena_thaw(a)` e `arena_compact(a)` com Descongelamento Transparente no Primeiro Toque:**
  - `arena_freeze(a)` comprime a arena página por página (páginas zeradas custam zero), devolve a memória física ao SO e protege o intervalo com `PROT_NONE`.
  - **Os ponteiros continuam válidos:** o primeiro toque de leitura ou escrita em uma página congelada aciona o tratador de falha de página (`SIGSEGV` em `sigaltstack`), que descomprime e restaura apenas aquela página na hora e retoma a instrução!
  - `LUME_ARENA_COLD=<n>` congela automaticamente arenas que passam `n` coletas sem `arena_alloc`.
- **`.lcaps`, `.lumb` e CLI (`lume pack` / `lume unpack`):** Cápsulas e bytecodes `.lumb` são gravados empacotados quando ficam menores (`lumec.src`: de `787 KB` para `307 KB`), e todos os leitores aceitam ambos os formatos transparentemente.
- **Proteção Formal de Segredos (`[C0009]`) e Tempo Real (`[V0002]`):**
  - `mem_pack`, `arena_freeze` e `arena_compact` rejeitam em tempo de compilação (`[C0009]`) valores vindos de `@secret fn`, `secret_new`, parâmetros `secret_*` ou funções `ct_*`, e `arena_mark_secret` bloqueia em tempo de execução, eliminando o ataque de canal lateral *Decomp+Time*.
  - Sob `@bound(cycles: N)`, o compactador é recusado com `[V0002]` para preservar o WCET determinístico.

---

## 5. Tabela Completa da Evolução da Memória, Alocações e Velocidade

Todas as medições foram executadas no mesmo **Intel Core Ultra 5 135U** em WSL2 x86-64 Linux (mediana pareada de 7 execuções alternadas para os benchmarks; `/usr/bin/time -v` para pico de RSS).

### 5.1 Evolução de Tempo e Pico de Memória (RSS) nas 3 Gerações

| Benchmark / Operação | Geração 1: Baseline (Pré-R5) | Geração 2: Rodada 5 (`3a296cd`, Mark-Sweep GC) | **Geração 3: Rodada 6 (`fa9a3ea`, Compactador Atômico Níveis 0–3)** | Ganho de Velocidade (R6 vs. R5 / vs. Gen 1) | Redução Total de RAM (R6 vs. Gen 1) |
|---|---:|---:|---:|---|---|
| **Bootstrap Completo desde a Semente C** | `194,8 s` / `12.700 MB` | `200,0 s` / `2.500 MB` | **`22,0 s` / `537 MB`** | **`9,0×` mais rápido** | **`23,6×` menos RAM (`-95,8%`)** |
| **Semente C Compilando `lumec.src`** | `102,0 s` / `12.500 MB` | `5,5 s` / `472 MB` | **`5,5 s` / `472 MB`** | **`18,5×` mais rápido** | **`26,5×` menos RAM (`-96,2%`)** |
| **Autocompilação do `lumec` (`stage2 == stage3`)** | `1.820 ms` / `1.165 MB` | `1.908 ms` / `228 MB` | **`445 ms` / `115 MB`** | **`4,3×` mais rápido** | **`10,1×` menos RAM (`-90,1%`)** |
| **Suíte Completa de Testes (`410` testes)** | `> 600 s` / `12.700 MB` | `529 s` / `2.490 MB` (`404` testes) | **`136 s` / `537 MB` (`410` testes)** | **`3,9×` mais rápido** | **`23,6×` menos RAM (`-95,8%`)** |
| **Loop de Inteiros (`b_loop`, 100M iterações)** | `~4.800 MB` (sem coleta) | `2.796 ms` / `68 MB` | **`88 ms` / `0,39 MB` (`390 KB`)** | **`31,8×` mais rápido** | **`174×` menos RAM vs. R5 (`~12.000×` vs. Gen 1)** |
| **Registros (`b_rec`, 20M registros)** | `~6.000 MB` (sem coleta) | `3.270 ms` / `67 MB` | **`429 ms` / `66 MB`** | **`7,6×` mais rápido** | **Limitado pelo teto inicial de 64 MiB do GC** |
| **Pattern Matching em ADTs (`b_match`, 20M)** | Sem coleta | `1.617 ms` / `72 MB` | **`235 ms` / `68 MB`** | **`6,9×` mais rápido** | **Limitado pelo teto inicial de 64 MiB do GC** |
| **Listas Encadeadas (`b_list`, 30 × 1M `Cons`)** | Sem coleta | `2.747 ms` / `239 MB` | **`480 ms` / `67 MB`** | **`5,7×` mais rápido** | **`3,6×` menos RAM vs. R5** |
| **Carga de Strings (`b_str`)** | `5.090 ms` / `6.013 MB` | `679 ms` / `74 MB` | **`131 ms` / `2,2 MB`** | **`5,2×` mais rápido vs. R5 (`38,8×` vs. Gen 1)** | **`2.733×` menos RAM (`-99,96%`)** |
| **`fib(38)` Recursivo (`b_fib`)** | `1.190 ms` | `1.042 ms` | **`273 ms`** | **`3,8×` mais rápido vs. R5 (`4,4×` vs. Gen 1)** | **`0 B` no heap** |
| **Tamanho do Binário ELF do `lumec`** | `1,46 MB` | `1,52 MB` | **`1,01 MB` (`1.006.576 B`)** | — | **`-34%` menor** |
| **Tamanho do Assembly Gerado pelo `lumec`** | `7,35 MB` | `7,35 MB` | **`4,29 MB`** | — | **`-41,6%` menor** |
| **Vazão do Compactador Nível 3 (`LZ1`)** | — | — | **`~355 MB/s` pack / `~975 MB/s` unpack** | `lumec.src`: `787 KB -> 307 KB` (`2,56×`) | **Descongelamento sob demanda no 1º toque** |

### 5.2 Colapso no Número de Alocações no Heap (Rodada 5 vs. Rodada 6)

| Benchmark | Alocações na Rodada 5 | **Alocações na Rodada 6 (`fa9a3ea`)** | Fator de Redução de Alocações |
|---|---:|---:|---|
| **`b_loop` (100.000.000 de iterações de inteiros)** | `200.000.000` | **`1`** | **`200.000.000×` menos alocações (`-99,9999995%`)** |
| **`b_str` (Manipulação intensiva de strings)** | `42.600.000` | **`17`** | **`2.505.882×` menos alocações (`-99,99996%`)** |
| **`b_rec` (20.000.000 de registros de 3 campos)** | `240.000.000` | **`20.000.000`** | **`12,0×` menos alocações (`-91,7%`)** |
| **`b_list` (30 × 1.000.000 de células `Cons`)** | `180.000.000` | **`30.000.000`** | **`6,0×` menos alocações (`-83,3%`)** |
| **`b_match` (20.000.000 de `match` em ADTs)** | `80.000.000` | **`20.000.000`** | **`4,0×` menos alocações (`-75,0%`)** |

---

## 6. Matriz de Validação e Auditoria Independente (`fa9a3ea`)

| Bateria / Gate de Verificação | Escopo Auditado | Resultado Final (`fa9a3ea`) |
|---|---|---|
| **Fixpoint Zero-C (`lume_make bootstrap` & `zero-c`)** | Semente C $\rightarrow$ `lumec1` $\rightarrow$ `lumec2` $\rightarrow$ `lumec3` | **`stage2 == stage3` idêntico byte a byte em assembly e ELF (`1.006.576 B`)** |
| **Semente Nativa Windows (`lume0.exe`)** | Compilação completa do `lumec.src` no Windows 11 real | **Assembly idêntico byte a byte ao do Linux em `17 s`** |
| **Suíte Oficial Completa (cópia limpa)** | Todas as fases da linguagem e stdlib | **`410 passed, 0 failed, 0 skipped` (`136 s / 537 MB`)** |
| **ASan + UBSan na Semente Stage-0** | Suíte da semente sob `-fsanitize=address,undefined` | **`170 passed, 0 failed, 0 relatórios do sanitizer`** |
| **Matriz Diferencial de Valores (`value_matrix_ok`, `value_edges_ok`)** | `10.530` + `75.512` expressões testando limites de 63/64 bits, strings com NUL, SSO, listas, registros e builtins | **`75.512 / 75.512` aprovadas (`0 crashes`, `0 divergências aritméticas`)** |
| **Bateria Adversária Red-Team (`317` programas `b1..b5`)** | Closures, recursão mútua, ownership, `LUME_GC_STRESS=1` e oráculo `lcaas` | **`317 / 317` (`0 crashes`, `0 diffs sob GC stress`, `0 erros de link`)** |
| **Bateria de Casos de Borda Semânticos (`159` programas)** | Verificação de `[R0200..R0205]`, `[P0002]`, `[C1001]`, `toint` negativo, bounds de strings/listas e `slicen` | **`159 / 159` (`100%` dentro do esperado)** |
| **Gates de Runtime, Ownership e GC (`runtime_sync`, `ownership`, `gc`)** | `148` verificações de paridade `lumec` vs. `lcaas` + sincronia de runtime + coleta sob teto de heap | **`3 / 3` gates (`148/148` em `ownership_gate.src`)** |
| **Fuzzing do Descompressor Nível 3 (`pack_corrupt_fail.src`)** | `1.500` blobs `LZ1` corrompidos/truncados submetidos ao `mem_unpack` | **`1.500 / 1.500` rejeitados de forma controlada (`exit 3`)** |
| **Kernel Freestanding em QEMU (`freestanding_values_ok.src`)** | Imagem `.kernel` x86-64 testando palavras marcadas e indexação em modo freestanding | **`PASS`** |
| **Passos de CI Executados Localmente** | Todos os 44 passos locais do workflow de CI, incluindo validação JSON (`economy`, `registry`, `onnx`, `egm`, `ncm`) | **`44 / 44 PASS`** |
