# ============================================================================
# LINGUAGEM LUME — MANUAL INTERNO PARA HUMANOS E IA (v0.3.0-rc.3 / Onda 10)
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
  6. biblioteca  (stdlib)     Biblioteca Padrao e Modulos Soberanos (fs, db, net, gui, nn...)
  7. alvos       (targets)    27 Alvos Universais, MIR SSA, APK/IPA/ISO/UEFI e RTL
  8. comandos    (commands)   Guia Completo de Comandos CLI (Fases 1-5 e Ondas 1-10)
  9. exemplos    (examples)   6 Programas Completos Prontos para Copiar e Rodar
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
- Interpolacao de Strings:    `f"valor={x}"` ou `"valor=${x}"`
- Condicional (`if..then..else`): `if x > 0 then "positivo" else "zero ou negativo"`
- Operadores logicos (curto-circuito): `a == 1 and b == 2`, `x < 0 or x > 10`, `not ativo`
- Aritmetica: `+`, `-`, `*`, `/`, `%`
- Comparacao: `==`, `!=`, `<`, `<=`, `>`, `>=`
- Concatenacao/interpolacao: `"Valor = " + str(100)` (nota: `{ident}` dentro de strings
                             faz interpolacao automatica; separe `"{" + s + "}"` para chave literal)
- Registros (Structs): `let p = {x: 10, y: 20} in p.x + p.y`
- Listas encadeadas: `Nil` (lista vazia) e `Cons(cabeca, cauda)`
- Comentarios: `## Comentarios comecam com dois sustenidos`

## 2.3 Reconhecimento de Padroes (`match` — DX 10/10)
Voce pode usar `match` de tres formas em qualquer lugar:
1. No topo do corpo de uma funcao:
   ```lume
   fn soma_lista(xs) = match xs
       Nil        => 0
       Cons(h, t) => h + soma_lista(t)
   ```
2. Aninhado por indentacao dentro de `let ... in` ou `if ... then ... else`:
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
REGRA DE OURO: Salve sempre seus arquivos com quebra de linha LF (`\n`), nunca CRLF (`\r\n`).

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

## 4.2 Leis Universais (`law`)
```lume
law simetria_soma(a: int, b: int) = (a + b) == (b + a)
```

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

## 5.2 Memoria sem Pausas de Garbage Collector, SRA Zero-Heap e Arenas (`std.arena`)
A Lume usa reuso estatico Perceus + Escape Analysis / Scalar Replacement of Aggregates
(`lsra_expr`: registros locais `let r = {k1: v1, ...} in corpo` que nao escapam sao
alocados diretamente em slots de pilha `%rbp` `_sra_<r>_<k>` com 0 alocacoes de heap) +
cache de inteiros pequenos (`[-1024..1024]`) + tail-call `jmp` + arenas regionais `O(1)`:
- `let a = arena_new(65536)`   Cria uma arena de 64 KB
- `arena_enter(a)` / `arena_leave(a)` / `arena_reset(a)` / `arena_destroy(a)`
- `heap_stats()`               Retorna estatisticas do heap em tempo real
- `lume run --memory <arq.src>` Mede o pico de memoria fisica (RSS em KB)

## 5.3 E-Capsules Reprodutiveis (`std.capsule`)
- `lume capsule seal <arq.src> -o <saida.lcaps>` Sela codigo, entradas, saidas e SHA-256.
- `lume capsule replay <saida.lcaps>`            Reproduz e audita a execucao selada.

# CAPITULO 6: FUNCOES NATIVAS E BIBLIOTECA PADRAO DA LUME

## 6.1 Funcoes Nativas (Sempre Disponiveis sem `use`)
- Texto (`str`): `count(s)`, `at(s, i)`, `slice(s, ini, fim)`, `slicen(s, ini, tam)`,
                 `ord(c)`, `str_from_byte(n)`, `str(n)`, `toint(s)`
- Arquivos (`fs`): `readall()`, `fs_read_file(caminho)`, `fs_write_sync(caminho, texto)`,
                   `fs_path_exists(caminho)`, `fs_read_byte(caminho, offset)`, `fs_file_size(caminho)`
- Sistema (`os`): `os_arg_count()`, `os_arg_at(i)`, `os_getpid()`, `os_exit(cod)`,
                  `os_run(cmd, args)`, `os_run_capture_timeout(cmd, args, out, err, ms)`
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
- `use fs`             Arquivos seguros com `with_file` (fechamento garantido)
- `use bytes`          Buffers binarios verificados (`bytes_from_str`, `bytes_get`)
- `use map`            Dicionario hash de 256 buckets (`map_empty`, `map_put`, `map_get`)
- `use arena`          Arenas de memoria de alta velocidade (`with_arena`)
- `use capsule`        Capsulas de auditoria e replay deterministico
- `use fs_sha256_file` Hash criptografico FIPS 180-4 (`lc_sha256(s)`, `fs_sha256_file(p)`)
- `use db`             Banco de dados B+Tree + WAL ACID com recuperacao de falhas e SQL
- `use net`            Especialista em Redes TCP/IP, Dissecador Wireshark (`wireshark_dissect_frame`,
                       `wireshark_filter_match`, leitor/gravador `.pcap`), Firmware de Switch/Roteador
                       L2/L3/P4 (VLAN 802.1Q, RSTP 802.1w, tabela CAM/MAC, MPLS, FIB LPM, BGP-4,
                       pipeline P4), Protocolos Industriais e de Subestacao do zero: Modbus RTU/TCP
                       (`CRC-16 0xA001`), DNP3 IEEE 1815 (`0x0564` + `CRC-16/DNP` + SBO + SAv5),
                       IEC 60870-5-104 (`TCP/2404` I/S/U-Format), IEC 61850 (`MMS ISO 9506`,
                       `GOOSE 0x88B8` sub-4ms e `Sampled Values 0x88BA`) e Reles Digitais de Protecao
                       Eletrica (`sv_dft_4sample_phasor` DFT 60 Hz, `ANSI 50`, `ANSI 51`, `ANSI 87`,
                       `ANSI 21`, `ANSI 27/59`, `ANSI 81U/O` e religador `ANSI 79`)
- `use gfx`            Motor Grafico 2D/3D, Matematica de Ponto Fixo (`fx_sqrt`, `fx_sin_deg`,
                       `fx_cos_deg`), Blending RGBA Porter-Duff, Rasterizador 2D Bresenham/Circulo/
                       Bezier, Projecao de Perspectiva 3D, BMP Binario (54B), PPM e Sinoptico SVG HMI
- `use gui`            Cliente grafico binario X11 (`0x42` MSB) e arvore reativa Web
- `use nn`             Redes neurais, serializador binario `.safetensors` e Protobuf `.onnx`
- `use async_rt`       Pool de processos paralelos do SO (`async_run_workers_os`)
- `use protect`        Protecao de software P33 (ofuscacao CFG, criptografia de strings, `[W0002]`)
- `use lgenesis`       Sintetizador autonomo full-stack para 8 alvos simultaneos
- `use lsentience`     Motor Transcendente (Computacao Quantica, DNA, HDC, DEQ, LLM-Forge, Triade)
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
                       Verificador de Tipos Lineares `Qubit` estilo `Silq` (`No-Cloning`/`No-Measure-Reuse`) e
                       Descomputacao Automatica $U^\dagger$ de Ancillas (`qfree_safe == 1`), Fusao de Aranhas
                       ZX-Calculus `QuiZX/PyZX` e Reducao de $T$-Count (`7x` menos portas $T$), Simulador
                       Estabilizador `Google Stim` Gottesman-Knill $O(n^2)$ (`GHZ_8`), Codigo Topologico
                       de Superficie `[[9, 1, 3]]` QEC (`27/27` erros de Pauli corrigidos) e VQE Diferenciavel
                       por Parameter-Shift Exato (`PennyLane/Catalyst`) + sintetizador de pulsos `.qbin`

# CAPITULO 7: 27 ALVOS UNIVERSAIS, LUMEMIR SSA E EMPACOTADORES

## 7.1 Compilacao Cruzada Direta (`lume build --target <alvo> <arq.src> -o <saida>`)
- Desktop/Servidor: `x86_64-linux-elf`, `aarch64-linux-elf`, `riscv64-linux-elf`,
                    `x86_64-windows-pe` (PE64 nativo com IAT `kernel32.dll`), `aarch64-macos-macho`
- Windows GUI Nativo: `x86_64-windows-gui` e `x86_64-windows-gui-protected` (`PE32+` Win32 GUI nativo
                    com IAT `KERNEL32.dll`, `USER32.dll`, `GDI32.dll`, `COMDLG32.dll`, `SHELL32.dll`,
                    `--protect max` P33 Anti-REA `XOR 0xB2 = 178`, prologo `PYXH` MBA e cofre `.lsym`)
- Mobile (Lojas):   `aarch64-android-apk`, `aarch64-ios-ipa`
- Bare-Metal / SO:  `x86_64-uefi-pe`, `x86_64-boot-iso`, `x86_64-baremetal-kernel`, `ihex`
- Web / Bytecode:   `wasm32-wasi` (com `@wasm-sandbox` `[I0275]`), `lumb`
- GPUs / IA:        `nvptx64-nvidia-cuda` (CUDA PTX 8.0), `spirv64-vulkan-shader` (SPIR-V 1.6)
- Silicio / FPGA:   `verilog-rtl-2005` (IEEE 1364), `vhdl-rtl-2008` (IEEE 1076)
- Quantico e Bio:   `qasm3-quantum` (OpenQASM 3.0), `dna-quaternary` (`A,C,G,T`)

## 7.2 Empacotadores de Loja/Boot, LumeMIR e Silicio Diferenciavel
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
  lume genesis <nome_app> [dominio]      Sintetiza sistema full-stack para 8 alvos
  lume heal <src.src>                    Autocura contratos violados usando contraexemplos
  lume equiv <spec.src> <fast.src>       Prova equivalencia algoritmica e superotimiza
  lume morph <arquivo_legado>            Transmuta SQL, Python, C ou OpenAPI para Lume
  lume neural-kernel <src.src>           Sintetiza kernels GPU/FPGA diferenciaveis
  lume evolve list|goals|budgets|propose|verify|apply|grow|approve [id|pasta|bundle] Auto-evolucao governada por assinatura Ed25519

## 8.3 Comandos Transcendentes e Soberanos (Ondas 9 e 10)
  lume morph-ast / awaken / quantum / bio-dna / cosmic-tmr / hologram / chronos
  lume omega-net / llm-forge / consult / laws / memory / replicate / hive / daemon-triad / hot-evolve / live-cockpit
  lume reversa / reverse-engineer / reveng / decompile <alvo> Engenharia reversa unificada binaria + SDD
  lume pingora / proxy / cdn / load-balancer [alvo] Proxy de borda e CDN Pingora-Lume (TinyUFO, Ketama+P2C, TLS 1.3, ProxyHttp)
  lume egm / elephant-goldfish / goldfish-review / drift-report / heilmeier [alvo] Modelo Elefante-Peixe-Dourado (EGM SDD + Deriva Zero)
  lume ncm / next-concept / ncm-quantize / ncm-generate / ncm-solve [alvo] Modelagem de Proximo Conceito Paralela Coarse-to-Fine (NCM-Lume)
  lume opentpu / tpu / otpu-asm / k-smooth / stream-se / tpu-scoreboard [alvo] Acelerador Sistolico de IA e Compilador ISA OpenTPU-Lume
  lume continuum / nexus / billion-context / acp / ecc-shield / bend-laws / ai-memory / notebook / doory [alvo] Motor Lume Continuum Nexus v1.0 (7 Motores de Referencia)
  lume quantum-nexus / qfree / zx-calculus / surface-code / vqe [alvo] Motor Lume Quantum Nexus v1.0 (Silq qfree, QuiZX, Stim, Surface Code QEC, Catalyst VQE)
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
  nativamente dentro do proprio compilador todas as 14 Baterias Soberanas de Provas
  (`LumeCompiler-Embedded-OmniProof-v3`) sem nenhum script externo (`std.net`, `std.gfx`,
  `lume_crypto_blockchain_engine`, `lume_reversa_engine`, `lume_pingora_proxy_engine`,
  `lume_egm_engine`, `lume_ncm_engine`, `lume_opentpu_engine`, `lume_continuum_nexus_engine`,
  `lume_quantum_nexus_engine`, `lsentience`, `lmanual`, `KerneLume` Bare-Metal OS,
  guardas `[K0005]`/`[K0006]`/`[C0009]`/SRA e `MANIFEST.sha256`: 396 obrigacoes formais +
  134 testes unitarios + 98 artefatos verificados).

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
    let m0 = map_empty() in
    let m1 = map_put(m0, "autor", lc_sha256("Ricardo Bueno")) in
    map_get(m1, "autor", "nao_encontrado")

print executar()
```

## Exemplo 4: Banco de Dados B+Tree + WAL ACID (`banco_dados.src`)
```lume
use db
print str(db_btree_self_test())
```

## Exemplo 5: Motor Cripto, Mineracao PoW SHA-256 e DeFi AMM (`cripto.src`)
```lume
use lume_crypto_blockchain_engine
print crypto_blockchain_full_report()
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

# CAPITULO 10: TABELA DE CODIGOS DE ERRO E COMO CORRIGIR

| Codigo    | Categoria            | Causa e Como Resolver |
|-----------|----------------------|-----------------------|
| `[P0002]` | Sintaxe / Parser     | Token inesperado, `let` solto no topo de `.src`, ou `match` sem chaves aninhado. Mova o `match` para `fn aux(x) = match x ...` ou use `match x { ... }`, e garanta quebras de linha LF (`\n`). |
| `[R0200]` | Escopo / Nomes       | Funcao ou variavel nao declarada. Verifique a grafia ou adicione `use <modulo>` no topo do arquivo. |
| `[T0300]` | Tipos / Tensores     | Tipos incompativeis, soma de moedas distintas (`money[BRL]` + `money[USD]`) ou dimensoes invalidas em `tensor[...]`. |
| `[E0200]` | Efeitos Algebricos   | Funcao marcada com `/ pure` tentou fazer I/O, rede, `arena_new` ou `embed`. Remova `/ pure` ou declare o efeito. |
| `[O0001]` | Ownership / Borrow   | Uso de valor apos transferencia de posse (`move`) ou uso de arquivo ja fechado. |
| `[V0001]` | Prova de Contrato    | Contrato `requires`/`ensures` ou `law` refutado pelo solver `QF_LIA`. Veja o contraexemplo impresso ou rode `lume heal <arq.src>`. |
| `[V0002]` | Limite de Ciclos     | Funcao excedeu o orcamento `@bound(cycles: N)` ou possui recursao ilimitada em `@interrupt`. |
| `[I0003]` | Interop C (`adapt c`)| Declaracao C insegura sem tamanho explicito. Adicione anotacoes de tamanho ou `@repr(c)`. |
| `[I0275]` | Sandbox WASM         | Importacao de host proibida dentro de modulo `@wasm-sandbox`. |
| `[C0271]` | Comptime Embed       | Caminho em `comptime embed("...")` tenta sair da raiz do projeto (`..`) ou nao existe. |
| `[D0273]` | Esquema de Tabela    | `comptime table_schema(T)` chamado sobre um tipo que nao e registro. |
| `[K0005]` | Bare-Metal W^X / DMA | `mmio_volatile_write*`, `mem_copy` ou `mem_set` aponta para `.text`/`.rodata` (`[0x8000..0x3FFFF]`), inclusive `base + off` simbolico. Use endereco seguro de RAM (`>= 0x40000`). |
| `[K0006]` | Pilha de Kernel      | Ciclo de recursao mutua ilimitada (`f -> g -> f`) em modulo `@freestanding` / `kernel_boot_entry`. Use loop tail-call ou iteracao limitada. |
| `[C0009]` | Cripto Constant-Time | Branch `if`/`match`, divisao `/` ou `%` ou curto-circuito `and`/`or` dependente de segredo (`secret_*` ou funcao `ct_*`). Use acumulacao bitwise XOR/OR em tempo constante. |
| `[Q0001]` | Linearidade Quantica | Violacao de `No-Cloning` (duplicacao de `Qubit`) ou reuso de qubit medido. Consuma cada fio `Qubit` linearmente. |
| `[Q0002]` | Uncompute `qfree`    | Fio ancilla nao descomputado em funcao `qfree` (`anc_leaked > 0`). Aplique o adjunto $U^\dagger$ (`q_silq_qfree_verify`) antes de retornar. |
| `[L0001]` | Formatacao / Lint    | Codigo fora do padrao canonico; execute `lume fmt <arq.src>`. |
| `[W0002]` | Scanner de Segredos  | Chave privada ou token detectado no codigo-fonte durante `--protect`; remova o segredo literal. |
