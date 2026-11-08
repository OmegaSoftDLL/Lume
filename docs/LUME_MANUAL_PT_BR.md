# ============================================================================
# LINGUAGEM LUME — MANUAL INTERNO PARA HUMANOS E IA (v1.1.0 / Onda 10)
# Edicao 2026 | Zero-C Self-Hosted | "Lume gera Lume"
# ============================================================================

Bem-vindo ao Manual Interno da Lume! Embora a Lume tenha sido projetada como
AI-First (onde a propria linguagem sintetiza, prova e evolui codigo), ela foi
construida para que qualquer programador humano possa programar com clareza,
seguranca matematica e controle total da maquina.

## COMO USAR ESTE MANUAL NO TERMINAL
  lume manual --pt                Mostrar este indice em Portugues (pt-BR)
  lume manual --pt <capitulo>     Ler um capitulo (ex: lume manual --pt sintaxe)
  lume manual --pt tudo           Ler todos os 10 capitulos completos de uma vez
  lume manual <chapter>           Ler o manual em Ingles (EN)
  lume manual --json [capitulo]   Emitir manual estruturado em JSON
  lume manual --pt --export <f>   Exportar o manual completo em Markdown (.md)
  lume help <capitulo>            Atalho direto para qualquer capitulo

## CAPITULOS DO MANUAL (10 CAPITULOS)
  1. visao-geral (overview)   Arquitetura (.lume vs .src), Inicio Rapido e Fluxo
  2. sintaxe     (syntax)     Gramatica Completa, fn/type/match/let e Regras do Compilador
  3. tipos       (types)      Tipos Primitivos, Registros, ADTs, Ownership, Decimal, Tensor
  4. contratos   (contracts)  Verificacao Formal (requires, ensures, law, QF_LIA, WCET)
  5. efeitos     (effects)    Efeitos Algebricos (/ pure), Arenas de Memoria e E-Capsules
  6. biblioteca  (stdlib)     Biblioteca Padrao e Modulos Soberanos (`lume manual --pt camaleao`)
  7. alvos       (targets)    27 Alvos Universais, MIR SSA, APK/IPA/ISO/UEFI e RTL
  8. comandos    (commands)   Guia Completo de Comandos CLI (`lume chameleon` / `lume camaleao`)
  9. exemplos    (examples)   6 Programas Completos + Exemplo 7 (`chameleon_demo.src`)
 10. erros       (errors)     Tabela de Codigos de Erro ([P0002]..[W0002]) e Solucoes

# CAPITULO 1: VISAO GERAL E INICIO RAPIDO PARA HUMANOS

## 1.1 O Que e a Linguagem Lume?
Lume e uma linguagem de programacao auto-hospedada (Zero-C: o compilador `lumec`,
o montador `lasm` e o driver `lcli` sao escritos 100% em Lume e compilam a si
mesmos de forma bit-identica `stage2 == stage3`).

Ela possui duas camadas de sintaxe:
1. `.src` (Lume-Core): A sintaxe funcional/expressiva canonica compilada diretamente
   pelo compilador nativo `lumec`. E a forma mais direta e recomendada para programar.
2. `.lume` (Surface Lume): Sintaxe de blocos/indentacao que desce para Lume-Core.

## 1.2 Seu Primeiro Programa em 30 Segundos
1. Crie o arquivo `ola.src` (sempre com quebras de linha LF `\n`):
   ```lume
   fn dobro_positivo(x: int) -> int
     requires x >= 0
     ensures result >= x
   = x * 2

   fn test_dobro() = dobro_positivo(21) == 42

   print "Resultado: " + str(dobro_positivo(21))
   ```
2. Executar imediatamente:
   `lume run ola.src`             -> imprime `Resultado: 42`
3. Rodar os testes unitarios (`fn test_*()`):
   `lume test ola.src`            -> executa todas as funcoes `test_*`
4. Provar matematicamente os contratos (`requires`/`ensures`):
   `lume prove ola.src`           -> gera a prova formal `QF_LIA` em JSON
5. Compilar um executavel nativo independente (ELF64 / PE64):
   `lume build ola.src -o ola`

# CAPITULO 2: SINTAXE, GRAMATICA E REGRAS DO COMPILADOR

## 2.1 Declaracoes de Topo em Arquivos `.src`
Em um arquivo `.src`, tudo no nivel de topo deve ser uma das seguintes declaracoes:
- `use <modulo>`               Importa um modulo (ex: `use fs`, `use map`, `use db`).
- `type Nome = ...`            Define um Tipo Algebrico (ADT) ou registro.
- `fn nome(a, b) = expr`       Define uma funcao.
- `pub fn nome(a, b) = expr`   Define uma funcao publica exportada.
- `const NOME: T = expr`       Define uma constante de modulo (disponivel em funcoes e contratos).
- `law nome(a: int) = expr`    Define uma lei matematica universal provada pelo compilador.
- `print <expr>`               Ponto de entrada executavel do programa.

## 2.2 Expressoes, Desestruturacao e Operadores Ergonomicos (DX 10/10)
- Variavel local (`let..in`): `let a = 10 in let b = 20 in a + b`
- Desestruturacao de tupla:   `let (a, b) = (10, 20) in a + b`
- Desestruturacao de record:  `let {x, y} = ponto in x + y`
- Operador Pipe (`|>`):       `x |> etapa1(5) |> etapa2`
- Record Update (`with`):     `{ estado with contador: estado.contador + 1 }`
- Interpolacao de Strings:    `f"valor={x}"`, `"valor=${x}"` ou `"valor={x}"`
                              (JSON bruto `"{\"a\":{\"b\":1}}"` preserva todas as chaves; escape chaves
                              literais com `"\{x}"`, `"{{x}}"` ou `"custo: \${x}"`; escapes `\n`, `\r`, `\t`, `\b`, `\f`, `\0`, `\'`, `\"`, `\\`)
- Condicional (`if..then..else` ou chaves): `if x > 0 then 1 else 0` ou `if x > 0 { 1 } else { 0 }`
- Operadores logicos (curto-circuito): `a == 1 and b == 2`, `x < 0 or x > 10`, `not (a == b)` (`not` tem precedencia menor que `==`/`<`)
- Aritmetica: `+`, `-`, `*`, `/`, `%`
- Comparacao: `==`, `!=` (igualdade estrutural em pilha `O(1)` para listas/ADTs/records profundos), `<`, `<=`, `>`, `>=`
- Registros (Structs): `let p = {x: 10, y: 20} in p.x + p.y`
- Literais de lista e ADTs: `[]` (`Nil`), `[1, 2, 3]` (`Cons(1, Cons(2, Cons(3, Nil)))`), `count([1, 2, 3]) == 3`
- Comentarios: `## Comentarios comecam com dois sustenidos`

## 2.3 Reconhecimento de Padroes (`match` — DX 10/10)
Voce pode usar `match` em qualquer lugar (corpo de funcao, `let ... in`, `if`, argumentos de chamada, campos de record e bracos de `match`):
1. No topo do corpo de uma funcao:
   ```lume
   fn soma_lista(xs) = match xs
       Nil        => 0
       Cons(h, t) => h + soma_lista(t)
   ```
2. Aninhado por indentacao dentro de `let ... in`, `if`, argumentos de funcao ou bracos de `match`:
   ```lume
   fn cabeca_ou_zero(xs) =
       let y = match xs
           Nil        => 0
           Cons(h, _) => h
       in y + 1
   ```
3. Inline com chaves `match expr { Padrao => corpo, ... }`:
   ```lume
   fn tamanho_um(xs) = let r = match xs { Nil => 0, Cons(_, Nil) => 1, Cons(_, _) => 2 } in r
   ```
REGRA DE OURO:
1. Salve sempre seus arquivos com quebra de linha LF (`\n`), nunca CRLF (`\r\n`).
2. Qualquer Aridade de Parametros + TCO: O codegen nativo SysV AMD64 (`05_codegen.src`)
   passa os primeiros 6 parametros em `%rdi, %rsi, %rdx, %rcx, %r8, %r9` e parametros 7+
   na pilha com otimizacao de tail-call (`jmp`) segura para trocas de argumentos.
3. Validacao Fail-Closed de Patterns e Bindings: Nomes duplicados em parametros/patterns/
   desestruturacao, patterns decimais (`1.5 =>`) e `match` aninhado sem chaves na mesma linha
   falham fechado com `[P0002]`.
4. Nunca edite `compiler/stage1/lumec.src` diretamente: edite `compiler/stage1/lume/NN_*.src`
   e execute `scripts/amalgamate.sh`.

# CAPITULO 3: SISTEMA DE TIPOS, OWNERSHIP, FINANCAS E TENSORES

## 3.1 Tipos Fundamentais
- `int`               Inteiro de 64 bits com sinal
- `bool`              Booleano (`true` / `false`, ou `1` / `0` em Lume-Core)
- `str`               String UTF-8 imutavel com tamanho em cache `O(1)` (`count(s)`)
- `bytes`             Buffer de bytes seguro com verificacao de limites (`std.bytes`)
- `List[T]`           Lista imutavel (`Nil` | `Cons(h, t)`)
- `Option[T]`         `None` | `Some(v)`
- `Result[T, E]`      `Ok(v)` | `Err(e)`

## 3.2 Tipos de Dados Algebricos (`type`)
```lume
type Pagamento =
    Pix(int)
  | Cartao(int, int)

fn taxa(p) = match p
    Pix(valor)            => 0
    Cartao(valor, tarifa) => tarifa
```

## 3.3 Tipos Financeiros e de Dados (`decimal`, `money`, `table`)
- `decimal(p, s)`     Decimal exato de ponto fixo (sem erros de ponto flutuante IEEE 754).
- `money[BRL]`        Dinheiro tipado por moeda (`money[BRL]`, `money[USD]`). Somar moedas
                      diferentes sem conversao explicita gera erro em tempo de compilacao!
- `table[T]`          Tabela relacional tipada com suporte a `persist table` (WAL duravel).

## 3.4 Tensores Verificados e Diferenciacao Automatica (`tensor`)
- `tensor[f32, 64, 128]` Verifica dimensoes em tempo de compilacao (`[T0300]`).
- Suporta autodiff reverso e direto (`grad`, `value_and_grad`, `jvp`, `vjp`).

## 3.5 Ownership, Borrow Checker e Capacidades de Hardware
- `own T` (posse linear), `ref T` (emprestimo compartilhado), `mut T` (emprestimo exclusivo)
  verificados em tempo de compilacao (`[O0001]`..`[O0030]`) com reuso Perceus.
- Capacidades lineares de hardware para sistemas operacionais: `cap[Page]`, `cap[Port]`, `cap[Irq]`.

# CAPITULO 4: CONTRATOS, LEIS MATEMATICAS E VERIFICACAO FORMAL

## 4.1 Pre-condicoes (`requires`) e Pos-condicoes (`ensures`)
Qualquer funcao em Lume pode carregar contratos provados matematicamente pelo solver
`QF_LIA` embutido no compilador:
```lume
fn sacar(saldo: int, valor: int) -> int
  requires saldo >= valor and valor > 0
  ensures result >= 0 and result < saldo
= saldo - valor
```
Se houver qualquer possibilidade de `result < 0`, o compilador rejeita o codigo com
`[V0001]` e mostra o contraexemplo exato!

## 4.2 Leis Universais (`law`) e Idioma de Implicacao Logica
```lume
law simetria_soma(a: int, b: int) = (a + b) == (b + a)
law implicacao_clamp(x: int, lo: int, hi: int) =
  if lo <= hi then clamp(x, lo, hi) >= lo else 1 == 1
```
- Idioma de Implicacao (`if P then Q else 1 == 1`): Expresse implicacoes logicas $P \implies Q$
  dentro de `law` usando `if P then Q else 1 == 1`, reduzindo diretamente para ramos
  decidiveis `QF_LIA` tanto no `lcaas.src` quanto no kernel independente `lcert.src`.
- Terminacao Composta e Kernel de Prova (`lcert.src`): Verifica obrigacoes compostas
  `terminates` (`lk_prove_term_cond` com `and`/`or`) e executa autoteste criptografico
  NIST FIPS 180-4 SHA-256 KAT (`sha256("abc")`).

## 4.3 Limite de Ciclos de Tempo Real (`@bound(cycles: N)`)
Garante Worst-Case Execution Time (WCET) em kernels e drivers (`[V0002]`).

## 4.4 Comandos de Prova e Autocura
- `lume prove <arquivo.src>`           Prova todos os contratos e leis.
- `lume certify <arquivo.src> --json`  Gera certificado criptografico de prova.
- `lume heal <arquivo.src>`            Repara automaticamente contratos violados!
- `lume equiv <spec.src> <rapido.src>` Prova que duas funcoes fazem a mesma coisa.
- `lume agent cegis <arquivo.src>`     Sintetiza lacunas `??` usando CEGIS.

# CAPITULO 5: EFEITOS ALGEBRICOS, MEMORIA DETERMINISTICA E ARENAS

## 5.1 Efeitos Algebricos (`/ pure`, `/ {io, fs, net}`)
- Funcoes marcadas com `/ pure` sao matematicamente puras: nao podem acessar disco,
  rede, processos ou mutar estado externo. Qualquer violacao gera `[E0200]`.

## 5.2 Memoria Automatica, SRA Zero-Heap e Arenas (`std.arena`)
A Lume recupera memoria sozinha: o runtime nativo tem um coletor mark-sweep nao movel que
devolve memoria ao sistema. A pausa e proporcional ao heap vivo, nao ao lixo; um programa
abaixo de 64 MiB nunca coleta. `own`, borrows e `resource type` sao regras de compilacao e nao
dependem do coletor (`docs/38-memory-management.md`). Ele nao substitui as otimizacoes abaixo:
reuso estatico Perceus onde a unicidade e provada + Escape Analysis / Scalar Replacement of
Aggregates (`lsra_expr`: registros locais `let r = {k1: v1, ...} in corpo` que nao escapam sao
alocados diretamente em slots de pilha `%rbp` `_sra_<r>_<k>` com 0 alocacoes de heap) +
palavras de valor (inteiro de 63 bits e string de ate 7 bytes dentro da palavra, sem heap; `int`
continua com 64 bits) + tail-call `jmp` + arenas regionais `O(1)`:
- `let a = arena_new(65536)`   Cria uma arena de 64 KB
- `mem_pack(s)` / `mem_unpack(b)`   Comprime dados frios (formato de bloco LZ4; dado corrompido para)
- `arena_freeze(a)` / `arena_thaw(a)`   Comprime uma arena; a pagina volta no primeiro toque
- `arena_mark_secret(a)`, `@secret fn`   Segredos nunca chegam ao compactador ([C0009])
- `arena_reset(a)` / `arena_destroy(a)`
- `heap_stats()`               Retorna estatisticas do heap em tempo real
- `gc_collect()` / `gc_count()` Forca uma coleta / conta as coletas
- `lume run --memory <arq.src>` Mede o pico de memoria fisica (RSS em KB)
- `LUME_HEAP_CAP=<bytes>`, `LUME_GC=on|off`, `LUME_GC_STRESS=<n>` Controlam o heap

## 5.3 E-Capsules Reprodutiveis (`std.capsule`)
- `lume capsule seal <arq.src> -o <saida.lcaps>` Sela codigo, entradas, saidas e SHA-256.
- `lume capsule replay <saida.lcaps>`            Reproduz e audita a execucao selada.

# CAPITULO 6: FUNCOES NATIVAS E BIBLIOTECA PADRAO DA LUME

## 6.1 Funcoes Nativas (Sempre Disponiveis sem `use`)
- Texto (`str`): `count(s)`, `at(s, i)`, `slice(s, ini, fim)`, `slicen(s, n, start, end)`,
                 `ord(c)`, `chr(cod)`, `str(n)`, `toint(s)`
- Arquivos (`fs`): `readall()`, `fs_read_file(caminho)`,
                   `fs_write_sync(caminho, texto)`, `fs_path_exists(caminho)`,
                   `fs_read_byte(caminho, offset)`
- Sistema (`os`): `os_arg_count()`, `os_arg_at(i)`,
                  `os_getpid()`, `os_exit(cod)`, `os_run(cmd, args)`,
                  `os_run_capture_timeout(cmd, args, out, err, ms)`
- Hardware, Kernel Bare-Metal e Console Nativo (`@freestanding` / `.kernel` / `.iso`):
  - Portas I/O (8/16/32 bits): `port_out8(p, v)`, `port_in8(p)`, `port_out16(p, v)`, `port_in16(p)`,
                               `port_out32(p, v)`, `port_in32(p)`
  - MMIO Volatil (8/16/32/64 bits): `mmio_volatile_write8(a, v)`, `mmio_volatile_read8(a)`,
                                    `mmio_volatile_write16(a, v)`, `mmio_volatile_read16(a)`,
                                    `mmio_volatile_write32(a, v)`, `mmio_volatile_read32(a)`,
                                    `mmio_volatile_write64(a, v)`, `mmio_volatile_read64(a)`
  - Console VGA Nativo (`0xB8000` + CRT `0x3D4`/`0x3D5`): `vga_puts(row, col, attr, texto)`,
    `vga_fill_row(row, attr, ch_ascii)`, `vga_scroll_up(top_row, bot_row, attr)`,
    `vga_set_cursor(row, col)`
  - CPU, MSR e SMP: `cpu_cli()`, `cpu_sti()`, `cpu_hlt()`, `cpu_pause()`, `cpu_mfence()`,
                    `cpu_rdtsc()`, `cpu_rdmsr(msr)`, `cpu_wrmsr(msr, val)`, `cpu_read_cr3()`,
                    `cpu_write_cr3(v)`, `cpu_invlpg(va)`, `cpu_idt_init()`, `cpu_smp_boot_ap(v)`
  - Bitwise de 64 bits em Hardware: `bit_and(a, b)`, `bit_or(a, b)`, `bit_xor(a, b)`,
                                    `bit_not(a)`, `bit_shl(a, n)`, `bit_shr(a, n)`
  - Bloco de Memoria, Integridade e Estado O(1): `mem_copy(dst, src, len)`, `mem_set(dst, b, len)`,
    `mem_crc64(addr, len)` (auditoria anti-rootkit FNV-1a de 64 bits), `krn_slot_write(idx, val)`,
    `krn_slot_read(idx)` (tabela de estado de kernel de 1024 slots com zero alocacoes de heap)
- Falha Segura:   `ctfail(msg)` (imprime erro no `stderr` e encerra com codigo != 0)

## 6.2 Modulos da Biblioteca Padrao (`use <modulo>`)
- `use fs`             Arquivos seguros com `sfile_with` (fechamento garantido)
- `use bytes`          Buffers binarios verificados (`bnew`, `bpush`, `bget`, `bslice`, `bto_str`)
- `use vec`            Invariantes genericos de colecoes e decimais provados por `QF_LIA` (`vec.src`,
                       `decimal.src`, `stdlib/std.lume`: `vec_clamp_index`, `vec_checked_slice_len`,
                       `map_checked_slot`, `decimal_clamp`)
- `use map`            Dicionario hash de 256 buckets (`map_new`, `map_put`, `map_get`, `map_get_or`,
                       `map_checked_slot`)
- `use arena`          Arenas de memoria de alta velocidade (`arena_new`, `arena_alloc`, `arena_reset`)
- `use capsule`        Capsulas de auditoria e replay deterministico
- `use fs_sha256_file` Hash criptografico FIPS 180-4 (`lc_sha256(s)`, `fs_sha256_file(p)`, `fs_file_size(p, i)`)
- `use db`             Banco de dados B+Tree + WAL ACID com recuperacao de falhas e SQL
                       (limites de scan de 64 bits `+/- 10^12`, guarda de `db_begin_tx` aninhado e
                       poda de subarvore separadora `BMInner`, `6/6` provas `QF_LIA`)
- `use net`            Especialista em Redes TCP/IP, Dissecador Wireshark (`wireshark_dissect_frame`,
                       `wireshark_filter_match`, leitor/gravador `.pcap`), Firmware de Switch/Roteador
                       L2/L3/P4 (admissao VLAN 802.1Q corrigida, RSTP 802.1w, tabela CAM/MAC, MPLS,
                       FIB LPM, BGP-4, pipeline P4), Protocolos Industriais e de Subestacao do zero:
                       Modbus RTU/TCP (`CRC-16 0xA001`), DNP3 IEEE 1815 (`0x0564` + `CRC-16/DNP` +
                       SBO + SAv5), IEC 60870-5-104 (`TCP/2404` I/S/U-Format), IEC 61850 (`MMS ISO 9506`,
                       `GOOSE 0x88B8` sub-4ms e `Sampled Values 0x88BA` com guardas exatos de tamanho) e
                       Reles Digitais de Protecao Eletrica (`sv_dft_4sample_phasor` DFT 60 Hz,
                       `net_isqrt` ate `10^16`, contratos diretos `ansi50`/`ansi27_59`, `ANSI 51`,
                       `ANSI 87`, `ANSI 21`, `ANSI 81U/O` e religador `ANSI 79`, `23/23` provas `QF_LIA`)
- `use gfx`            Motor Grafico 2D/3D, Matematica de Ponto Fixo (`fx_sqrt`, `fx_sin_deg`,
                       `fx_cos_deg`), Blending RGBA Porter-Duff, Rasterizador 2D Bresenham/Circulo/
                       Bezier, Projecao de Perspectiva 3D, BMP Binario (54B), PPM e Sinoptico SVG HMI
- `use gui`            Cliente grafico binario X11 (`0x42` MSB), arvore reativa Web, Layout Declarativo
                       de 4 Paineis (`lume ui-layout` / `@ui-layout`) para Win64 PE32+ e Web/WASM com
                       redimensionamento `WS_THICKFRAME` e selecao de mouse `LBS_NOTIFY | LBS_HASSTRINGS`
                       simultaneos (`1412694337` / `0x54340141` e `1412698308` / `0x543410C4`) +
                       conservacao de geometria `QF_LIA` (`ui_split_conservation_law`), e System76 COSMIC
                       1.11 Wayland `xdg-dialog-v1` com empilhamento modal z-index e bloqueio de clique
                       no pai (`ui_modal_blocks_parent`, `ui_modal_z_index`, `4/4` provas `QF_LIA`)
- `use los`            Camada de Sistema Operacional Track O + politica deterministica de selecao
                       PCI de GPU hibrida (`iGPU` vs `dGPU`) estilo System76 COSMIC 1.11
                       (`os_select_hybrid_gpu`, `11/11` provas `QF_LIA`)
- `use nn`             Redes neurais, serializador binario `.safetensors` e Protobuf `.onnx` com pesos
                       negativos em complemento de dois de 64 bits (`nn_le64_hex`), `model_content_hash`
                       sobre todo o CSV e guarda `KIf` PTX/SPIR-V contra divisao por zero em `tensor.src`
                       (`16/16` provas `QF_LIA`)
- `use async_rt`       Pool de processos paralelos do SO (`async_run_workers_os`)
- `use protect`        Protecao de software P33 (ofuscacao CFG, criptografia de strings, prologo MBA
                       algebrico multi-etapas `addq`/`xorq`/`subq` em `lprotect.src`, `[W0002]`)
- `use lgenesis`       Sintetizador autonomo full-stack para 8 alvos simultaneos
- `use lsentience`     Motor Transcendente (Computacao Quantica, DNA, HDC, DEQ, LLM-Forge, Triade)
- `use lume_llm_core`  Nucleo Soberano LLM 1-Bit/Ternario e Roteador Hibrido em 3 Camadas (`21/21` provas):
                       MAC inteiro zero-float PrismML `Bonsai` 1-bit (`{-1, +1}`) e `BitNet b1.58`
                       ternario (`{-1, 0, +1}`) + empacotamento de 5 trits por byte (`3^5 = 243 <= 255`),
                       recorrencia de espaco de estados $O(1)$ Liquid AI `LFM3` + codec de audio 24 kHz
                       `LiquidCodec` (`12` tokens / `80 ms`), verificador de decodificacao especulativa
                       `DSpark`, guarda de admissao SSD MoE `Colibri` (`llm_moe_admission_guard`) e
                       Roteador Hibrido 3-Tier (`Tier 0` Lume Puro -> `Tier 1` Local `Gemma4-E2B`/`Ministral-3B-Q4`/`Bonsai-1bit`
                       -> `Tier 2` API Cloud) com oraculo anti-alucinacao de precos/contratos `QF_LIA`
- `use lume_crypto_blockchain_engine` Criptomoedas, SHA-256 PoW, UTXO, DeFi AMM e Kelly Criterion
- `use lume_reversa_engine` Motor Reversa-Lume SDD v1.0: Engenharia reversa hibrida em 7 fases
                       para binarios (`ELF64`, `PE64`, `UEFI`, `Mach-O`, `WASM`), desempacotador de
                       instaladores NSIS/7z e multiplas linguagens, guarda de imutabilidade SHA-256,
                       taxonomia epistemica (`CONFIRMED`/`INFERRED`/`GAP`), `reversa_soul.md`, Mermaid
                       `stateDiagram-v2` e C4 `flowchart TD`, `reversa_code_city_3d.svg` via `std.gfx`
                       e reconstrucao modular completa em `.src` Lume-Core
- `use lume_pingora_proxy_engine` Motor Pingora-Lume Edge Proxy v1.0: Cache de borda `TinyUFO`
                       (`S3-FIFO` + `Count-Min Sketch` de 4 hashes), anel de hash consistente
                       `Ketama` 64 bits + balanceamento `P2C`, rate limiter de janela deslizante
                       dupla (`429`), stampede lock de coalescencia, pool keepalive + sessao
                       TLS 1.3 RFC 8446, circuit breaker de 3 estados + hot-upgrade zero-downtime
                       e pipeline `ProxyHttp` completo de 7 fases
- `use lume_egm_engine` Motor EGM-Lume Elephant-Goldfish Model v1.0: Validador formal dos 8
                       pilares do Catecismo de Heilmeier + Shootdown de 6 Lentes, isolamento
                       epistemico Elefante (memoria profunda) vs Peixe-Dourado (`hist == 0,
                       bias == 0`), teste de compreensao por parafrase cega (Estagio 6), scanner
                       lexico Anti-Glazing, revisao antagonica de 5 estagios (Estagios 5 a 9),
                       auditor de contradicoes e detector bidirecional de deriva Spec <-> Codigo
                       integrado ao `lume_reversa_engine`
- `use lume_ncm_engine` Motor NCM-Lume Next-Concept Modeling v1.0 (Stanford Hazy Research arXiv:2610.14162):
                       Quantizador Vetorial Residual Multiescala (`MS-RVQ` escalas `[4, 8, 16, 32, 64]`,
                       downsampling por area, upsampling linear, commitment loss, centroides EMA,
                       reinicializacao de codigos mortos), Cabeca de Logits por Distancia Euclidiana
                       Emparelhada (`2*<z,E_i> - ||E_i||^2`), Mascara de Atencao Bloco-Diagonal
                       Escala-Causal + RoPE com Reset por Escala (`wle`), Decodificador Paralelo
                       Coarse-to-Fine em K Escalas + Classifier-Free Guidance (`CFG`), Solucionador
                       Global de Restricoes Sudoku 4x4 e Ponte Simbiotica com `LLM-Forge`,
                       `lume_egm_engine` e `lume_reversa_engine`
- `use lume_opentpu_engine` Motor OpenTPU-Lume Systolic AI Accelerator & ISA v1.0 (`OmegaSoftDLL/openTPU`):
                       Montador/desmontador `openTPU ISA v1`, registradores escalares com posse linear
                       (`R0..R15`), Unidade Matricial Sistolica (`MXU`) com replay estacionario de linhas
                       (`ceil(M / MCOLS)`), quantizador em dois niveis (`QACT` `Sa * 2^-da` int8 + `FP4`
                       4.25 bits/peso), migracao formal de outliers *K-Smoothing* (`<Q*2^s, K*2^-s> == <Q,K>`),
                       Stream Engine (`SE`, opcode `0x13` `STREAM`) de 5 estagios fundidos para `Gated DeltaNet`,
                       cache LRU de experts MoE em DRAM + escalonador `WAITW` com sobreposicao compute/PCIe-DMA,
                       Scoreboard e Roofline analitico de hardware (`YPCB`, `BCU1525`, `AWS F2`, `ASIC`) e
                       equivalencia `0 ULP` (Golden == ISA-Sim == SystemVerilog RTL) com `lume_ncm_engine`
- `use lume_continuum_nexus_engine` Motor Lume Continuum Nexus v1.0 (7 Arquiteturas de Referencia):
                       `ECC AgentShield` scanner red-team/blue-team e evolucao bayesiana de instintos
                       (`0.30..0.99`), superposicao em arvore `Bend` (`bend/fold`) e leis de conservacao,
                       `Billion-Context` Active Context Pruning (`ACP`) compressao hierarquica reversivel
                       (`96%` cache hit, restauracao sem perda), `AI-Memory` retencao ponderada por acesso
                       + handoff `claim-once` + Dreaming Wiki (`ai_memory_wiki.md`), Roteador Soberano
                       Multi-Provedor LLM consciente de quota, `Open-Notebook` grounding de citacoes e
                       podcast RIFF/WAVE PCM de 3 vozes (`open_notebook_podcast.wav`), e `Doory` CRDT
                       `LWW-Element-Set` + slide vetorial (`doory_continuum_slide.svg`)
- `use lume_quantum_nexus_engine` Motor Quantico Soberano Lume Quantum Nexus v1.0 (5 Inovacoes Quanticas):
                       Verificador de Tipos Lineares `Qubit` estilo `Silq` (`No-Cloning`/`No-Measure-Reuse`),
                       guarda contra adjunto de medicao nao-unitaria (`q_is_reversible_unitary`) e
                       Descomputacao Automatica $U^\dagger$ de Ancillas (`qfree_safe == 1`), Fusao de Aranhas
                       ZX-Calculus `QuiZX/PyZX` e Reducao de $T$-Count (`7x` menos portas $T$ + equivalencia
                       de vetor de estado pre/pos-ZX `q_sv2_equiv_tol`), Simulador Estabilizador `Google Stim`
                       Gottesman-Knill $O(n^2)$ (`GHZ_8`), Codigo Topologico de Superficie `[[9, 1, 3]]` QEC
                       (`27/27` erros de Pauli corrigidos) e VQE Diferenciavel por Parameter-Shift Exato
                       (`PennyLane/Catalyst`) + sintetizador de pulsos `.qbin`
- `use lchameleon`     Motor Universal Camaleao de Interoperabilidade Poliglota v1.0 (`28/28` provas
                       `QF_LIA`, `8/8` testes): Fronteira fail-closed `[I0003]` (`unverified[T] ->
                       verified[T]` sob `/ {ffi}`) nos 9 ecossistemas: `c_abi` (C/C++ `.h`/`.dll`/`.so`
                       Win64/SysV shadow-space e alinhamento), `rust_cdylib` (Cargo `extern "C"`
                       exclusividade de borrow Perceus e unwind guard), `python_capi` (`PyObject*`
                       conservacao de refcount e tensores DLPack zero-copy), `node_napi_wasm`
                       (Node-API e limites de pagina WASM 64 KiB), `go_cshared` (`cgo` pointer-pinning),
                       `java_jni` (`JNIEnv*` frame local e Panama FFM), `dotnet_pinvoke` (`P/Invoke` e
                       layout blittable NativeAOT), `sql_relational` (`DDL`/`DML` -> `table[T]`) e
                       `openapi_rpc` (HTTP/1.1, TLS 1.3 e gRPC com payload limitado)

## 6.2.1 Motor Universal Camaleao de Interoperabilidade Poliglota (`use lchameleon` — 9 Ecossistemas)
- **9 Ecossistemas Estrangeiros Verificados:** `c_abi` (C/C++ `.h`/`.dll`/`.so` Win64 shadow space de 32 bytes e SysV ABI),
  `rust_cdylib` (Rust `cdylib` transferencia linear Perceus e guarda de unwind), `python_capi` (CPython
  `PyObject*` conservacao de refcount e tensores DLPack zero-copy), `node_napi_wasm` (Node-API e limites
  de memoria linear WASM de 64 KiB), `go_cshared` (Go `-buildmode=c-shared` guarda de pointer-pinning),
  `java_jni` (Java JNI capacidade de frame local e Project Panama `MemorySegment`), `dotnet_pinvoke`
  (C#/.NET P/Invoke e layout blittable NativeAOT), `sql_relational` (PostgreSQL/SQLite/DuckDB
  `DDL`/`DML` -> invariantes de linha `table[T]`) e `openapi_rpc` (OpenAPI 3.1 / JSON Schema / gRPC).
- **Contratos de Fronteira Fail-Closed `[I0003]`:** Entradas externas ingressam como `unverified[T]` sob a
  capacidade `/ {ffi}` e so sao promovidas a `verified[T]` apos `chameleon_verify_boundary` provar
  ponteiros nao-nulos, alinhamento e limites `QF_LIA` (`28/28` obrigacoes formais provadas).
- **Integracao CLI, REPL e LSP:** Execute `lume chameleon [eco]`, `lume camaleao [eco]`, `lume polyglot`,
  `lume ffi-bridge`, `lume adapt <c|rust|python|js|go|java|dotnet|sql|openapi> [file]` ou
  `lume morph <legacy_file>`; dentro do `lume repl`, use `:chameleon [eco]` ou `:camaleao [eco]`.
- **Mascote Oficial (Lumi — O Camaleao Bioluminescente de Cristal):** Embutido nativamente como icone
  `16x16` 32-bit BGRA `RT_ICON` (`Type=3, ID=1`) + `RT_GROUP_ICON` (`Type=14, ID=1`) em `--target x86_64-windows-gui`.

## 6.2.2 Layout Declarativo de UI (`@ui-layout`) e Invariantes Verificados de Colecoes (`vec.src`, `decimal.src`, `stdlib/std.lume`)
- **Layout Declarativo de UI (`lume ui-layout` / `@ui-layout`):** Compila layouts declarativos de 4 paineis
  para Win64 PE32+ nativo (`--target x86_64-windows-gui`) e arvores DOM Web/WASM com redimensionamento de
  borda `WS_THICKFRAME` e selecao de mouse `LBS_NOTIFY | LBS_HASSTRINGS` simultaneos (`1412694337` /
  `0x54340141` para paineis Listbox e `1412698308` / `0x543410C4` para paineis Edit multilinhas), protegidos
  pela lei de conservacao geometrica `QF_LIA` (`ui_split_conservation_law`).
- **Invariantes Genericos de Colecoes Provados Formalmente (`vec.src`, `decimal.src`, `stdlib/std.lume`):**
  Funcoes de indexacao, fatia e clamp verificadas por `QF_LIA`: `vec_clamp_index`, `vec_checked_slice_len`,
  `map_checked_slot` e `decimal_clamp`.

## 6.2.3 Motor de Campo Unificado (`lume unified-field` / `lume ufe`), Motor Dinamico de Transicao e Singularidade (`lume singularity` / `lume ote`) e NetSentinel IEC 62443 (`lume net-sentinel` / `lume iec62443`)
- **Motor de Campo Unificado (`lume unified-field` / `lume ufe` em `std.gfx`, `35/35` provas `QF_LIA`, `12/12` testes):**
  - **Cinematica 7-DOF Damped Least-Squares (DLS) Livre de Singularidade:** `ufe_dls_lambda_sq_milli` e
    `ufe_dls_safe_denom_milli` garantem denominador estritamente positivo (`sigma_sq + lambda_sq >= 1`)
    proximo a singularidades cinematicas.
  - **Solver Harmonico 3D de Laplace Red-Black SOR e Principio do Maximo:** `ufe_laplace_sor_step_milli`
    e `ufe_harmonic_maximum_principle_law` resolvem $\nabla^2 \phi = 0$ em grades 3D sem minimos locais
    fora do atrator alvo.
  - **Atenuacao de Vortice GNRON, Auto-Colisao de Capsulas e Guarda IEEE-754:** `ufe_gnron_swirl_scale_milli`
    atenua rotacao nao-conservativa, `ufe_self_collision_capsule_ok` garante distancia segura entre elos
    7-DOF, e `ufe_ieee754_f32_finite_guard` bloqueia expoente `255` (`NaN`/`Inf`) antes da escrita em
    registradores fisicos de atuadores.
  - **EKF Dual-State ($5\sigma$ Mahalanobis + Covariancia de Joseph), Agarramento (Stiction) e RUL:**
    `ufe_ekf_mahalanobis_5sigma_ok` impõe `innov_sq <= 25 * S` (`5-sigma`),
    `ufe_ekf_joseph_cov_pos_milli` garante positividade na atualizacao de covariancia,
    `ufe_actuator_stiction_detect` detecta agarramento/banda morta de valvulas, e
    `ufe_actuator_rul_hours` estima a Vida Util Remanescente (`RUL`).
  - **Separacao de Enxame Multi-Robo, Regioes IAPWS-IF97, Vapor Umido e Limite de Carnot:**
    `ufe_swarm_separation_ok` garante distancia segura entre agentes, `ufe_if97_region_select` classifica
    as regioes termodinamicas (`1..4`), `ufe_turbine_wet_steam_guard` protege contra erosao de palhetas,
    e `ufe_carnot_efficiency_bound_ok` verifica o limite da 2a Lei de Carnot.
  - **`LatencyMonitor` Deterministico de 1 kHz com Histerese de 100 Ciclos:** `ufe_latency_shedder_step`
    descarta carga nao-critica imediatamente em caso de estouro de janela e exige 100 ciclos
    consecutivos limpos a 1 kHz antes de restaurar a carga.
- **Motor Dinamico de Transicao de 2a Ordem e Fronteira de Singularidade $\Omega$ (`lume singularity` / `lume ote` / `lume transition-engine` em `lchameleon.src`, `63/63` provas `QF_LIA`, `12/12` testes):**
  - **Identificacao em Dois Regimes e Estimador Quantitativo de $\zeta$:** `ote_select_damping_regime`
    e `ote_estimate_zeta_milli` despacham entre o regime subamortecido ($0 < \zeta < 1$ via sobressinal
    $M_p$ e periodo $T_d$) e o regime criticamente amortecido / superamortecido ($1 \le \zeta \le 100$
    via razao adimensional `t_80 / t_20`).
  - **Triangulo de Potencias Operacional (`S, P, Q, cosPhi`) e Coerencia de Fase:** `ote_power_factor_milli`,
    `ote_reactive_waste_ratio_milli` e `ote_phase_coherence_ok` medem o fator de potencia util vs.
    retrabalho reativo e verificam a coerencia de fase (`|Phi - Phi_tau| <= 10 deg`).
  - **Fronteira de Singularidade $\Omega$ (`tau_max = T_m / 4`), Zonas de Margem e Guarda de Nyquist:**
    `ote_singularity_tau_max_ms`, `ote_omega_boundary_crossed` e `ote_singularity_margin_zone` detectam
    entrega em contrafase alem de $\Omega$ (`omega_env * tau > pi / 2`), enquanto `ote_nyquist_status_code`
    verifica $N_y = T_m / (2 T_s)$ (`NYQ-ALIAS` $< 1.0$, `NYQ-LIMIT` $< 2.0$).
  - **Desacoplamento de Cascata, Reajuste de Ganho e 9 Prescricoes Normativas:**
    `ote_cascade_bandwidth_decoupled_ok` impõe separacao temporal $\ge 3\times$ entre malhas,
    `ote_retune_kp_scale_milli` calcula a escala segura de ganho proporcional, e
    `ote_diagnose_primary_code` avalia na ordem imutavel de alavancagem fisica
    (Amostragem $\to$ Atraso/Fronteira $\to$ Ganho $\to$ Inercia):
    `NYQ-ALIAS` $\to$ `NYQ-LIMIT` $\to$ `OMEGA-CROSS` $\to$ `PF-LOW` $\to$ `MF-LOW` $\to$
    `CASCADE-DEEP` $\to$ `ZETA-LOW` $\to$ `ZETA-HIGH` $\to$ `QAMP-HIGH` / `TUNED`.
- **NetSentinel IEC 62443 e Telemetria OT Somente-Leitura (`lume net-sentinel` / `lume iec62443` em `std.net`, `38/38` provas `QF_LIA`, `12/12` testes):**
  - **Modelo Purdue (`L0..L4`) e Guarda de Conduite DMZ (`L3.5`):** `iec62443_purdue_conduit_ok`
    impõe isolamento estrito entre zonas e proibe travessia direta entre rede corporativa e controle.
  - **Auditoria de Politica de Firewall OT e Guarda Estrutural DCS Somente-Leitura:**
    `netsentinel_fw_policy_audit_ok` valida regras default-drop e `ot_readonly_dcs_guard` recusa
    estruturalmente qualquer permissao de escrita (`CurrentWrite` / `HistoryWrite`) ou nivel Purdue `< 3`.
  - **Qualidade Tri-State e Sentinela Finito `1e12`:** `ot_tristate_quality_code` classifica amostras
    `Good`/`Uncertain`/`Bad` sem interpolacao artificial, e `ot_finite_sentinel_clamp` limita telemetria
    ao intervalo finito `+/- 10^12`.

## 6.3 Todos os 8 Capstones Soberanos e Brasileiros Verificados (`examples/apps/`)
- `pix_fraud_trace` (`9/9` provas `QF_LIA`): Rastreamento de fraude e taint em grafos Pix em tempo real.
- `sentry_uav_guard` (`9/9` provas `QF_LIA`): Guarda autonomo de geofence, bateria e atitude para VANT/UAV.
- `verified_accounting` (`7/7` provas `QF_LIA`): Razao contabil de partidas dobradas com conservacao provada.
- `dfe_pix_bacen` (`11/11` provas `QF_LIA`): NF-e/NFC-e SEFAZ Modulo-11, ICMS/DIFAL e Pix BACEN EMV CRC-16.
- `omniroute_guard` (`8/8` provas `QF_LIA`): Roteador multi-provedor LLM e gateway de pagamento com failover.
- `brasil_public_id` (`9/9` provas `QF_LIA`): CPF, PIS/PASEP, Titulo Eleitoral e CNPJ Alfanumerico RFB/SERPRO Julho 2026 (`ord(ch) - 48`).
- `zero_breach_forensics` (`8/8` provas `QF_LIA`): Scanner forense anti-spyware (Pegasus/Predator/Candiru) e IOC STIX 2.1.
- `sovereign_llm_router` (`20/20` provas `QF_LIA`): MAC 1-Bit/Ternario, audio `LFM3` LiquidCodec 24 kHz, guarda SSD `Colibri` MoE e roteador hibrido 3-tier.

## 6.4 Integracoes de IDE (`editors/`)
- `editors/vscode-lume/`: Extensao VS Code (`extension.js` + `lsp_bridge.src` com `7/7` provas `QF_LIA`)
  com diagnosticos em tempo real, CodeLens de provas `QF_LIA` e inspecao de obrigacoes.
- `editors/openidea-lume/plugin.toml`: Manifesto do plugin soberano Lume para OpenIDEA / JetBrains.

# CAPITULO 7: 27 ALVOS UNIVERSAIS, LUMEMIR SSA E EMPACOTADORES

## 7.1 Compilacao Cruzada Direta (`lume build --target <alvo> <arq.src> -o <saida>`)
- Desktop/Servidor: `x86_64-linux-elf`, `aarch64-linux-elf`, `riscv64-linux-elf`,
                    `x86_64-windows-pe` (PE64 nativo com IAT `kernel32.dll`), `aarch64-macos-macho`
- Windows GUI Nativo: `x86_64-windows-gui` e `x86_64-windows-gui-protected` (`PE32+` Win32 GUI nativo
                    com IAT `KERNEL32.dll`, `USER32.dll`, `GDI32.dll`, `COMDLG32.dll`, `SHELL32.dll`,
                    lowering declarativo `@ui-layout` de 4 paineis com `WS_THICKFRAME` + `LBS_NOTIFY | LBS_HASSTRINGS`
                    estilos `1412694337` / `0x54340141` e `1412698308` / `0x543410C4`, `ui_split_conservation_law`,
                    `--protect max` P33 Anti-REA `XOR 0xB2 = 178`, prologo `PYXH` MBA e cofre `.lsym`)
- Mobile (Lojas):   `aarch64-android-elf`, `aarch64-ios-macho`
- Bare-Metal / SO:  `x86_64-uefi-pe`, `x86_64-none-raw`, `x86_64-none-mbr`, `x86_64-none-ihex`
- Web / Bytecode:   `wasm32-wasi` (com `@wasm-sandbox` `[I0275]`), `lumb`
- GPUs / IA:        `nvptx64-nvidia-cuda` (CUDA PTX 8.0), `spirv64-vulkan-compute` (SPIR-V 1.6)
- Silicio / FPGA:   `verilog-rtl` (IEEE 1364), `vhdl-rtl` (IEEE 1076)
- Quantico e Bio:   `qasm3-quantum` (OpenQASM 3.0), `dna-quaternary` (`A,C,G,T`)

## 7.2 Empacotadores de Loja/Boot, LumeMIR, Classificacao `subset` e Codegen Tail-Recursive
- `lasm.src` e `ltarget.src` usam acumuladores 100% tail-recursive (`rev_append` / `lt_lines_acc`)
  para fontes de multiplos megabytes sem estouro de pilha, e `lume targets --json` expoe
  a classificacao explicita `subset` (`"full-core"`, `"pe64-gui-template"`,
  `"verified-core-subset"`).
- `lume mir <alvo> <arq.src>`                     Inspeciona a IR SSA universal `LumeMIR`.
- `lume package apk|ipa|iso|uefi <src> -o <out>`  Gera pacotes prontos para Android/iOS/BIOS/UEFI.
- `lume neural-kernel [--json] <arq.src>`         Sintetiza PTX + SPIR-V + Verilog + VHDL com
                                                  prova de equivalencia de hardware em 3 vias.

# CAPITULO 8: REFERENCIA COMPLETA DE COMANDOS CLI (FASES 1-5 E ONDAS 1-10)

## 8.1 Comandos Essenciais do Programador
  lume build [--incremental] [--memory] [--protect [hardened|max]] [--target <t>] <src> [-o <out>]
  lume run [--memory] <src> [args...]    Compila e executa imediatamente
  lume test <src.src>...                 Executa todos os testes `fn test_*()`
  lume check <src.src> [--json]          Verifica tipos, ownership e efeitos
  lume fmt <src.src> [--check|--stdout]  Formatador canonico de codigo
  lume doc <src.src> [--json]            Gera documentacao e executa doctests
  lume repl [--stdio|--kernel]           REPL interativo com verificacao de contratos
  lume lsp / lume dap                    Servidores de IDE (LSP e Debug Adapter)
  lume manual [--pt] [capitulo]          Abre este Manual Interno da Linguagem Lume

## 8.2 Verificacao Formal, Superpoderes IA e Evolucao (Ondas 1-8)
  lume prove <src.src>                   Prover matematico `QF_LIA` / Logica de Separacao
  lume certify / verify-cert <src.src>   Emite e audita certificados de prova formal
  lume patch-fn <src> <fn_name> <patch>  Substitui uma unica funcao na AST cirurgicamente
  lume trace <src.src>                   Rastreamento estruturado de execucao em JSON
  lume diff-semver <antigo> <novo>       Calcula impacto SemVer (MAJOR/MINOR/PATCH)
  lume symbolize <arq.lsym> <consulta>   Desofusca simbolos e enderecos P33
  lume pack / lume unpack <in> -o <out>  Compressor atomico de blocos LZ1 e capsulas
  lume genesis <nome_app> [dominio]      Sintetiza sistema full-stack para 8 alvos
  lume heal <src.src>                    Autocura contratos violados usando contraexemplos
  lume equiv <spec.src> <fast.src>       Prova equivalencia algoritmica e superotimiza
  lume adapt <c|rust|python|js|go|java|dotnet|sql|openapi> [file] Gera adaptadores poliglotas FFI fail-closed `[I0003]`
  lume morph <file>                      Transmuta SQL, Python, C ou OpenAPI para Lume (`lume morph <arquivo_legado>`)
  lume neural-kernel <src.src>           Sintetiza kernels GPU/FPGA diferenciaveis
  lume evolve list|goals|budgets|propose|verify|apply|grow|approve [id|pasta|bundle] Auto-evolucao governada por assinatura Ed25519

## 8.3 Comandos Transcendentes e Soberanos (Ondas 9 e 10)
  lume morph-ast / awaken / quantum / bio-dna / cosmic-tmr / hologram / chronos
  lume omega-net / llm-forge / consult / laws / memory / replicate / hive / daemon-triad / hot-evolve / live-cockpit
    - `lume daemon-triad [src]`: Sentinela P2P sempre-ativa sincronizando a Triade (Este PC + Dell G3 + Acer) em <100ms
    - `lume hot-evolve [src]`:   Auto-recompilacao E-Graph e hot-swap binario atomico zero-downtime
    - `lume live-cockpit [src]`: Loop multimodal ao vivo (voz 22050 Hz + visao DEQ + telemetria de rede/Ring-0)
  lume ui-layout [src]     Lowering declarativo `@ui-layout` de 4 paineis Win64 PE32+ (`1412694337` / `1412698308`) e Web/WASM (`ui_split_conservation_law`)
  lume reversa / reverse-engineer / reveng / decompile <alvo> Engenharia reversa unificada binaria + SDD
  lume pingora / proxy / cdn / load-balancer [alvo] Proxy de borda e CDN Pingora-Lume (TinyUFO, Ketama+P2C, TLS 1.3, ProxyHttp)
  lume egm / elephant-goldfish / goldfish-review / drift-report / heilmeier [alvo] Modelo Elefante-Peixe-Dourado (EGM SDD + Deriva Zero)
  lume ncm / next-concept / ncm-quantize / ncm-generate / ncm-solve [alvo] Modelagem de Proximo Conceito Paralela Coarse-to-Fine (NCM-Lume)
  lume opentpu / tpu / otpu-asm / k-smooth / stream-se / tpu-scoreboard [alvo] Acelerador Sistolico de IA e Compilador ISA OpenTPU-Lume
  lume continuum / nexus / billion-context / acp / ecc-shield / bend-laws / ai-memory / notebook / doory [alvo] Motor Lume Continuum Nexus v1.0 (7 Motores de Referencia)
  lume quantum-nexus / qfree / zx-calculus / surface-code / vqe [alvo] Motor Lume Quantum Nexus v1.0 (Silq qfree, QuiZX, Stim, Surface Code QEC, Catalyst VQE)
  lume chameleon|camaleao|polyglot|ffi-bridge [target_or_file] (ou `lume chameleon`) Motor Universal Camaleao de Interop Poliglota nos 9 ecossistemas (`c_abi`, `rust_cdylib`, `python_capi`, `node_napi_wasm`, `go_cshared`, `java_jni`, `dotnet_pinvoke`, `sql_relational`, `openapi_rpc`)
  lume unified-field|ufe [alvo]                      Motor de Campo Unificado em `std.gfx` (`ufe_dls_lambda_sq_milli`, `ufe_dls_safe_denom_milli`, `ufe_laplace_sor_step_milli`, `ufe_harmonic_maximum_principle_law`, `ufe_gnron_swirl_scale_milli`, `ufe_self_collision_capsule_ok`, `ufe_ieee754_f32_finite_guard`, `ufe_ekf_mahalanobis_5sigma_ok`, `ufe_ekf_joseph_cov_pos_milli`, `ufe_actuator_stiction_detect`, `ufe_actuator_rul_hours`, `ufe_swarm_separation_ok`, `ufe_if97_region_select`, `ufe_turbine_wet_steam_guard`, `ufe_carnot_efficiency_bound_ok`, `ufe_latency_shedder_step`)
  lume singularity|ote|transition-engine [alvo]      Motor Dinamico de Transicao de 2a Ordem e Fronteira Omega em `lchameleon.src` (`ote_select_damping_regime`, `ote_estimate_zeta_milli`, `ote_power_factor_milli`, `ote_reactive_waste_ratio_milli`, `ote_phase_coherence_ok`, `ote_singularity_tau_max_ms`, `ote_omega_boundary_crossed`, `ote_singularity_margin_zone`, `ote_nyquist_status_code`, `ote_cascade_bandwidth_decoupled_ok`, `ote_retune_kp_scale_milli`, `ote_diagnose_primary_code`)
  lume net-sentinel|iec62443 [alvo]                  NetSentinel IEC 62443 e Telemetria OT Somente-Leitura em `std.net` (`iec62443_purdue_conduit_ok`, `netsentinel_fw_policy_audit_ok`, `ot_readonly_dcs_guard`, `ot_tristate_quality_code`, `ot_finite_sentinel_clamp`)
  lume run compiler/stage1/lume_llm_core.src         Nucleo Soberano LLM 1-Bit/Ternario, Audio LFM3 LiquidCodec, Guarda MoE Colibri e Roteador 3-Tier (`21/21` provas)
  lume run examples/apps/sovereign_llm_router/main.src Roteador LLM Hibrido Edge/Local/Cloud e Oraculo Anti-Alucinacao de Precos (`20/20` provas)
  lume os-control / bios-core / web-research / crypto-engine
  lume sensory-cortex / multimodal / file-indexer / interface / self-build
  lume wireshark / switch-fabric / scada-ics / modbus / dnp3 / iec104 / iec61850
  lume gfx / render-3d / scada-hmi / ied-protection / recall / synapse / orchestrate

## 8.4 Orquestrador Universal de Modulos (`LumeSynapse`) e Memoria Proativa
- `lume synapse <arq.src>` (ou `lume orchestrate <arq.src>`): Coordena todos os modulos
  da Lume (`lmod`, `lumec`, `lasm`, `lcaas`, `lcert`, `ltest`, `lprotect`, `lsentience`)
  como um unico organismo vivo atraves do barramento em tempo real (`synapse_bus.json`),
  com Alimentacao Cruzada Instantanea (`prove -> check`, `certify -> prove + check`) e
  Reflexo Sinaptico Compilador <-> Autocura (`synapse_last_diagnostic.json`).
- `lume recall <arq.src>`: Consulta a Memoria Soberana Proativa O(1) com selos
  criptograficos `.sha256` anti-adulteracao (provas ate 91x mais rapidas e builds 20x
  mais rapidos).
- `lume self-prove` (ou `lume prove-all` / `lume verify-all` / `lume self prove`): Executa
  nativamente dentro do proprio compilador todas as 15 Baterias Soberanas de Provas
  (`LumeCompiler-Embedded-OmniProof-v3`) sem nenhum script externo (`std.net`, `std.gfx`,
  `lume_crypto_blockchain_engine`, `lume_reversa_engine`, `lume_pingora_proxy_engine`,
  `lume_egm_engine`, `lume_ncm_engine`, `lume_opentpu_engine`, `lume_continuum_nexus_engine`,
  `lume_quantum_nexus_engine`, `lchameleon`, `lsentience`, `lmanual`, `KerneLume` Bare-Metal OS,
  guardas `[K0005]`/`[K0006]`/`[C0009]`/SRA e `MANIFEST.sha256`: 482 obrigacoes formais +
  150 testes unitarios + 99 artefatos verificados).

# CAPITULO 9: 6 EXEMPLOS PRATICOS PRONTOS PARA COPIAR E RODAR

## Exemplo 1: Listas, Recursao e Pattern Matching (`lista.src`)
```lume
fn dobrar_todos(xs) = match xs
    Nil        => Nil
    Cons(h, t) => Cons(h * 2, dobrar_todos(t))

fn somar(xs) = match xs
    Nil        => 0
    Cons(h, t) => h + somar(t)

fn test_soma() = somar(dobrar_todos(Cons(5, Cons(10, Nil)))) == 30
print str(somar(dobrar_todos(Cons(5, Cons(10, Nil)))))
```

## Exemplo 2: Transferencia Bancaria com Prova Formal (`banco.src`)
```lume
fn transferir(origem: int, destino: int, valor: int) -> int
  requires origem >= valor and valor >= 0 and destino >= 0
  ensures result == origem + destino
= (origem - valor) + (destino + valor)

law conserva_total(o: int, d: int, v: int) = ((o - v) + (d + v)) == (o + d)
print str(transferir(1000, 500, 250))
```

## Exemplo 3: Dicionario Hash (`std.map`) e SHA-256 (`dicionario.src`)
```lume
use fs_sha256_file
use map

fn executar() =
    let m0 = map_new() in
    let m1 = map_put(m0, "creator", lc_sha256("Ricardo Bueno")) in
    map_get_or(m1, "creator", "missing")

print executar()
```

## Exemplo 4: Banco de Dados B+Tree + WAL ACID (`banco_dados.src`)
```lume
use db

fn run_db() =
    let d0 = db_open(2) in
    let tx = db_put(db_begin_tx(d0), 1, 100, 1) in
    let d1 = db_commit_tx(tx) in
    db_read(d1, 1, 0)

print str(run_db())
```

## Exemplo 5: Motor Cripto, Mineracao PoW SHA-256 e DeFi AMM (`cripto.src`)
```lume
use lume_crypto_blockchain_engine

fn crypto_sha256_rounds(msg: str) = crypto_hmac_sha256("lume-key", msg)
print crypto_sha256_rounds("block-0")
```

## Exemplo 6: Kernel Bare-Metal com Limite de Ciclos WCET (`rtc_kernel.src`)
```lume
@bound(cycles: 128)
fn bcd_para_binario(bcd: int) -> int
  requires bcd >= 0 and bcd <= 153
  ensures result >= 0
= ((bcd / 16) * 10) + (bcd % 16)

print str(bcd_para_binario(35))
```

## Exemplo 7: Interoperabilidade Poliglota Camaleao (`chameleon_demo.src`)
```lume
use lchameleon

fn run_chameleon_demo() =
    let ok = chameleon_verify_boundary(1, 1, 1, 64, 4096) in
    let r = chameleon_adapt_ecosystem("rust") in
    str(ok) + ":" + r.id

print run_chameleon_demo()
```

# CAPITULO 10: TABELA DE CODIGOS DE ERRO E COMO CORRIGIR

| Codigo    | Categoria            | Causa e Como Resolver |
|-----------|----------------------|-----------------------|
| `[P0002]` | Sintaxe / Parser     | Token inesperado, `let` solto no topo de `.src`, ou `match` sem chaves aninhado. Mova o `match` para `fn aux(x) = match x ...` ou use `match x { ... }`, e garanta quebras de linha LF (`\n`). |
| `[R0200]` | Escopo / Nomes       | Funcao ou variavel nao declarada. Verifique a grafia ou adicione `use <modulo>` no topo do arquivo. |
| `[R0201]` | Escopo / Nomes       | Funcao com o nome de uma rotina do runtime (`count`, `at`, ...) ou com um prefixo reservado a ele (`__rt_`, `__gc_`, `__lume_`, `__c_`, `__k_`, `__r_`, `__isr_`, `__cpu_`, `__krn_`, `__net_`). Renomeie. |
| `[T0300]` | Tipos / Tensores     | Tipos incompativeis, soma de moedas distintas (`money[BRL]` + `money[USD]`) ou dimensoes invalidas em `tensor[...]`. |
| `[E0200]` | Efeitos Algebricos   | Funcao marcada com `/ pure` tentou fazer I/O, rede, `arena_new` ou `embed`. Remova `/ pure` ou declare o efeito. |
| `[O0001]` | Ownership / Borrow   | Uso de valor apos transferencia de posse (`move`) ou uso de arquivo ja fechado. |
| `[V0001]` | Prova de Contrato    | Contrato `requires`/`ensures` ou `law` refutado pelo solver `QF_LIA`. Veja o contraexemplo impresso ou rode `lume heal <arq.src>`. |
| `[V0002]` | Limite de Ciclos     | Funcao excedeu o orcamento `@bound(cycles: N)` ou possui recursao ilimitada em `@interrupt`. |
| `[I0003]` | Interop Poliglota/C  | Declaracao C/poliglota insegura sem guarda explicita (`lume adapt c` / `lchameleon`). Promova `unverified[T] -> verified[T]` com limites `QF_LIA` ou `@repr(c)`. |
| `[I0275]` | Sandbox WASM         | Importacao de host proibida dentro de modulo `@wasm-sandbox`. |
| `[C0271]` | Comptime Embed       | Caminho em `comptime embed("...")` tenta sair da raiz do projeto (`..`) ou nao existe. |
| `[D0273]` | Esquema de Tabela    | `comptime table_schema(T)` chamado sobre um tipo que nao e registro. |
| `[K0005]` | Bare-Metal W^X / DMA | `mmio_volatile_write*`, `mem_copy` ou `mem_set` aponta para `.text`/`.rodata` (`[0x8000..0x3FFFF]`), inclusive `base + off` simbolico. Use endereco seguro de RAM (`>= 0x40000`). |
| `[K0006]` | Pilha de Kernel      | Ciclo de recursao mutua ilimitada (`f -> g -> f`) em modulo `@freestanding` / `kernel_boot_entry`. Use loop tail-call ou iteracao limitada. |
| `[C0009]` | Cripto Constant-Time | Branch `if`/`match`, divisao `/` ou `%` ou curto-circuito `and`/`or` dependente de segredo (`secret_*` ou funcao `ct_*`). Use acumulacao bitwise XOR/OR em tempo constante. |
| `[Q0001]` | Linearidade Quantica | Violacao de `No-Cloning` (duplicacao de `Qubit`) ou reuso de qubit medido. Consuma cada fio `Qubit` linearmente. |
| `[Q0002]` | Uncompute `qfree`    | Fio ancilla nao descomputado em funcao `qfree` (`anc_leaked > 0`). Aplique o adjunto $U^\dagger$ (`q_silq_qfree_verify`) antes de retornar. |
| `[L0001]` | Formatacao / Lint    | Codigo fora do padrao canonico; execute `lume fmt <arq.src>`. |
| `[L0010]` | Ligacao              | Um simbolo definido duas vezes na mesma imagem, o que mandaria chamadas para a rotina errada. |
| `[L0002]` | Escape de String     | Sequencia de escape desconhecida em string (validos: `\n`, `\r`, `\t`, `\b`, `\f`, `\0`, `\'`, `\"`, `\\`, `\{`, `\}`, `\$`). |
| `[W0002]` | Scanner de Segredos  | Chave privada ou token detectado no codigo-fonte durante `--protect`; remova o segredo literal. |
