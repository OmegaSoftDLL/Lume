# Auditoria do dossiê — Parte IV (linhas 510–805)

Dossiê: `C:\Users\Ricardo.Bueno\LUME_DOSSIE_REVERSA_COMPLETO_BIT_A_BIT_PT_BR.md`, linhas 510–805, lidas por inteiro.
**Atualização:** o dossiê foi substituído por `C:\Users\Ricardo.Bueno\LUME_CATALOGO_COMPLETO_IMPLEMENTADO_E_TESTADO_PT_BR.md` (o arquivo antigo não existe mais). A Parte IV está agora nas linhas **514–809**: some **+4** a todo número de linha do dossiê citado abaixo. Conferi o texto novo: as 296 linhas foram mantidas e 21 afirmações-marco continuam idênticas (39,968; 22 casos negativos; 192–750; 87,224; 38 entradas; 33,792 B; 0x16B0; `E9 2F F9 FF FF`; `rd * 100,000`; `beta1=9/10`; soma 118; `37` com `ensures`; `err = 57`; `DOWNGRD`; `lct_tls13_client_new_x509`; `lct_not_trivial32`; 36,864 B; `lume_dom_mount`; WFI…). A única diferença vista é a âncora `<a id="parte-4">` antes do título. Nenhum veredito muda: os erros apontados continuam no texto novo, que se apresenta como "implementado e testado".

Repositório conferido (somente leitura): `C:\Users\Ricardo.Bueno\lume` (`compiler/stage1/*.src`, `tests/harness/*.src`, `docs/`, `CHANGELOG.md`).
Data: 2026-11-13. Método: Grep/Read/sed sobre o código; números de linha `arquivo:linha` referem-se ao estado atual do repositório. As contagens de execução (ex.: 39.968 instruções) só podem vir da saída gravada dos gates (`docs/certification/QUALIFICATION_DOSSIER.md`), porque o código as calcula em tempo de execução.

Vereditos: **CONFIRMADA**, **DIVERGENTE** (com o valor real), **FALSA** (inexistente ou contrária ao código), **NÃO VERIFICÁVEL** (não dá para decidir pelo código).
Coluna Windows: **OK** (Lume puro, sem SO, ou já portado), **PENDENTE** (diz o que falta), **N/A**.

Premissa da coluna Windows: `lumec --win64` troca `syscall` por `call __win_syscall` (camada `build/windows-native/win64_layer.s`, que trata as syscalls 0..231, inclusive 60 = exit, 83 = mkdir, 90 = chmod e 59 = execve via CreateProcessW, e mapeia `/tmp` para o diretório temporário e `/dev/urandom` para BCryptGenRandom). `lasm --pe` grava PE32+. Ainda não existem no Windows: sockets, epoll, io_uring, shm, execução de ELF, QEMU, readelf, GNU as/objcopy/objdump, cc e python3. Também faltam os binários `/bin/chmod`, `/bin/mv` e `/bin/mkdir` chamados via `os_run`.

---

## Cabeçalho da Parte IV (L510–512)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 510 | "34+ targets de compilação" | CONFIRMADA (há 38 entradas) | `ltarget.src:109` (38 triples em `target_list_json`) | N/A |
| 512 | "extração integral, verificada linha a linha" | FALSA | dezenas de divergências documentadas abaixo | N/A |

## 1.1 Montador x86-64 `lasm.src` (L518–551)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 518 | `lasm.src` tem 698 linhas | CONFIRMADA | `wc -l` = 698 | OK |
| 518 | sem `as`/`ld` | CONFIRMADA | `lasm.src:1-3` | OK |
| 520 | `symhash`/`symhash_i`, `(acc*31+ord(ch)) % 256` | CONFIRMADA | `lasm.src:187-188` | OK |
| 520 | buckets `{bucket, entries: Cons({nm, v})}` | CONFIRMADA | `lasm.src:190-196` | OK |
| 520 | `mapsym(syms, nm, v)` / `symput_b` | DIVERGENTE: a assinatura é `mapsym(xs, base)` (monta a tabela a partir de uma lista); `symput_b` não existe, o nome real é `symbucket_put` | `lasm.src:190,198` | OK |
| 520 | `symaddr` devolve −1 quando ausente; `symhas` testa definição | DIVERGENTE: `symaddr` devolve **0** quando ausente (o −1 é interno ao bucket); quem testa definição é `symlocated` (0/1); `symhas` não existe | `lasm.src:200-214` | OK |
| 520 | consulta O(1) amortizado | DIVERGENTE: os buckets formam lista encadeada (até 256 nós) percorrida linearmente | `lasm.src:204-206` | OK |
| 521 | `reslocals` para `N:`/`Nf`/`Nb` com contadores `lget`/`linc` | DIVERGENTE: `reslocals` existe, mas os contadores são `cntget`/`cntinc`/`locname`; `lget`/`linc` não existem | `lasm.src:170-182` | OK |
| 522 | acumuladores `rev_append`, `lt_lines_acc` | DIVERGENTE: `rev_append` existe; `lt_lines_acc` não existe | `lasm.src:19` | OK |
| 524 | passagem 1 `measure`, flag `done`, `needsreloc(op,a1,a2,a3)` | DIVERGENTE: a passagem chama-se `layout`/`layout_go`, a flag é `reloc` e a assinatura é `needsreloc(r)` (1 argumento); a semântica de "codifica uma vez no endereço 0" confere | `lasm.src:310-323` | OK |
| 524 | saltos sempre `rel32` (5 B `E9`, 6 B `0F 8x`) | CONFIRMADA | `lasm.src:16` | OK |
| 525 | passagem 2 `emitcode_stream` recodifica só os relocáveis | CONFIRMADA | `lasm.src:372-374` | OK |
| 526 | `.text` preenchida até 8 B com `int3` (0xCC) | CONFIRMADA (a função é `padbytes`, não `pad_int3`) | `lasm.src:324-328` | OK |
| 526 | `.rodata` alinhada a 16 B com zeros | CONFIRMADA | `lasm.src:328` | OK |
| 526 | `.bss` com `align8` | NÃO VERIFICÁVEL (`align8` não existe; o alinhamento decorre do padding de `.text`/`.rodata`) | `lasm.src:324` | OK |
| 529 | bits VEX `rbit`/`xbit`/`bbit` e fórmula de `b2`, L=1 | CONFIRMADA | `lasm.src:275` | OK |
| 530 | VEX de 2 bytes quando `xbit==0x40 and bbit==0x20 and map==1 and wbit==0` | CONFIRMADA | `lasm.src:275` | OK |
| 531 | `vmovdqu %ymm8-15,%ymm0-7` usa o opcode de store 0x7F | CONFIRMADA (a função é `encvec2`, não `enc3`) | `lasm.src:282-284` | OK |
| 532 | mnemônicos AVX2: `vmovdqa`, `vpcmpeqb`, `vpaddb`, `vpaddd`, `vpmovmskb`, `vpbroadcastb/q`, `vpmulld`… | FALSA: nenhum desses existe (grep = 0). O VEX real cobre `vzeroupper`, `vzeroall`, `vmovdqu`, `vpaddq`, `vpsubq`, `vpxor`, `vpand`, `vpor` | `lasm.src:247-248,251,284`; `lasm_gate.src:148` | OK |
| 535 | EVEX `p0`, `map=1` para `vpaddq/vpsubq/vpxorq/vpandq/vporq/vmovdqu64`, `map=2` para `vpmullq` | CONFIRMADA | `lasm.src:276,284` | OK |
| 536 | EVEX `p1 = 0x80+(15-vvvv)*8+4+pp` | CONFIRMADA | `lasm.src:276` | OK |
| 537 | `p2` = 0x28 (ymm) / 0x48 (zmm) | CONFIRMADA | `lasm.src:276` | OK |
| 538 | `disp8*N` com N=32/64, exceção de rbp/r13 | CONFIRMADA | `lasm.src:272-273` | OK |
| 540 | ELF64 estático: ident, `ET_EXEC`, `EM_X86_64`, entrada 0x400078, phoff 64, 1 phdr, `PT_LOAD` RWX, vaddr 0x400000, cabeçalho de 120 B | CONFIRMADA | `lasm.src:522-526,684` | OK (gera bytes; o ELF não roda no Windows) |
| 540 | `p_align = 0x200000` | DIVERGENTE: `p_align = 4096` | `lasm.src:526` | N/A |
| 541 | ELF dinâmico ativado por `.ffi_lib`/`.ffi_sym` | DIVERGENTE: as diretivas são `.need` e `.extern` | `lasm.src:531-541,679` | N/A |
| 541 | estrutura do ELF dinâmico: 232 B, PT_INTERP/LOAD/DYNAMIC, PLT `FF 25` de 6 B, `.hash` nbucket=1, `.dynsym` 24 B/0x12, `R_X86_64_GLOB_DAT=6`, tags DT_* | CONFIRMADA (também emite `DT_PLTGOT=3`, omitido no dossiê) | `lasm.src:550-564` | OK (gera); execução N/A |
| 542 | PE32+: MZ, `e_lfanew=0x40`, Machine 0x8664, 3 seções, OptHdr 240, Magic 0x20B, ImageBase 0x400000, alinhamentos, Subsystem 3, DllChar 0x8100, commit de 1 MiB, cabeçalho de 512 B, `.text` 0x60000020, `.rdata` 0x40000040, `.bss` 0xC0000080 | CONFIRMADA | `lasm.src:566-639` | OK (caminho usado no porte) |
| 542 | `Characteristics = 0x0022` | DIVERGENTE: o valor é **0x0023** (35, inclui `RELOCS_STRIPPED`) | `lasm.src:639` | OK |
| 542 | `SizeOfStackReserve = 0x40000000` (1 GiB) | DIVERGENTE: **0x100000000 (4 GiB)** | `lasm.src:637`, comentário em `:577` | OK |
| 543 | Mach-O existe em `container_macho64_hdr_p` | CONFIRMADA (o Mach-O existe, ao contrário da suspeita) | `ltarget.src:637` | OK (gera bytes) |
| 543 | magic 0xFEEDFACF, cputype ARM64/X86_64, MH_EXECUTE, flags 0x00200085, attr 0x80000400, LC_MAIN 0x80000028/24 | CONFIRMADA | `ltarget.src:637` | OK |
| 543 | `ncmds = 2`, `sizeofcmds = 232`, `__text` no offset +264, `entryoff = 264` | DIVERGENTE: `ncmds = 12`, `sizeofcmds = 592`, `__text` em 0x100000400 (offset 1024), `entryoff = 1024`. Comandos: `__PAGEZERO`, `__TEXT`, `__LINKEDIT`, chained fixups, exports trie, symtab, dysymtab, dylinker, uuid, build_version, main e libSystem. **Não há `LC_CODE_SIGNATURE`**, então o binário arm64 não é aceito pelo macOS em Apple Silicon sem assinatura posterior | `ltarget.src:637,645` | N/A (execução) |
| 543 | x86_64 com página de 4 KiB | DIVERGENTE: `__TEXT` tem 16 KiB nas duas arquiteturas | `ltarget.src:637` | N/A |
| 545 | MBR: INT 13h AH=42h para 0x8000, PML4/PDPT/PD em 0x1000/0x2000/0x3000 (0x83, 2 MiB), CR4.PAE, EFER.LME, CR0=0x80000001, GDT 0x00AF9A…/0x00CF92…, `55 AA` | CONFIRMADA | `lasm.src:648-656` (bytes de `mbr_part1`) | OK (gera; boot N/A) |
| 545 | início `FA 31 C0` | DIVERGENTE: `FA FC 31 C0` (cli; cld; xor) | `lasm.src:648` | N/A |
| 545 | A20 pela porta 0x92 e fallback CHS (AH=02h) | FALSA: não há `in/out 0x92` nem `mov ah,2` | `lasm.src:648` | N/A |
| 545 | DAP em 0x0500 | DIVERGENTE: `mov si,0x7CF0`, DAP dentro do setor | `lasm.src:648,653-654` | N/A |
| 545 | `ljmp $0x08,$0x7CE0` | DIVERGENTE: `ljmp $0x08,$0x7C80` (`EA 80 7C 08 00`) | `lasm.src:648` | N/A |
| 545 | `RSP = 0x7C000` | DIVERGENTE: `RSP = 0x7C00` (`48 C7 C4 00 7C 00 00`) | `lasm.src:650` | N/A |
| 546 | `asmiso`: setores 0..15 contêm o MBR | FALSA: os setores 0..15 são zeros (`zeros(32768)`); a imagem de boot (variante do MBR + kernel) começa no setor 20 | `lasm.src:666` | N/A |
| 546 | PVD com `"LUME_OS"` | FALSA no lasm: `iso_pvd` não tem identificador (a string está no `pkg_iso9660_image_hex` do ltarget) | `lasm.src:661`; `ltarget.src:1121` | N/A |
| 546 | CD001 no byte 32769, BRVD no setor 17 apontando para o catálogo no LBA 19, terminador no 18, entrada de validação com 55AA, entrada padrão 0x88 com LBA 20 | CONFIRMADA | `lasm.src:658-666` | OK (gera) |
| 548 | DWARF v4: producer `"lasm (Lume)"`, DW_AT_language 36684, parâmetros de `.debug_line` (−5/14/13), 10 `Shdr` | CONFIRMADA | `lasm.src:449-489` | OK |
| 548 | `.debug_abbrev` com 29 B | DIVERGENTE: **35 B** | `lasm.src:449` | OK |
| 550 | `--strict` → `[L0001]` sem bytes emitidos | CONFIRMADA (o strict já é o padrão; `strict_ref.v` não existe) | `lasm.src:9,53,55,494-500,669-674` | OK |
| 550 | `[L0010]` = CLI sem argumentos | FALSA: `[L0010]` = "symbol defined twice"; sem argumento o lasm lê de stdin | `lasm.src:516,669` | OK |
| 551 | 39.968 instruções em 21 famílias, byte a byte contra GNU as + objcopy | CONFIRMADA | `lasm_gate.src:188`; `QUALIFICATION_DOSSIER.md:66`; `CHANGELOG.md:174` | PENDENTE: o gate exige GNU as, objcopy, objdump e execução de ELF |
| 551 | divisão por família (movq/addq… 2.048; AVX2 `vmovdqa/vpmovmskb/vpbroadcast` 2.952…) | FALSA: as famílias reais são `mov_rr, mov_mem, lea, alu_rr_q, alu_rr_lb, alu_mem, alu_imm, test, unary, shift, imul, movimm, misc, xchg, rip, branch, vex, vex_cube, evex512, evex256, evex_cube`; os mnemônicos citados nem existem | `lasm_gate.src:150-189` | N/A |
| 551 | 22 casos negativos `[L0001]` | DIVERGENTE: **176** casos negativos (o dossiê também omite as 1.467 codificações alternativas) | `lasm_gate.src:252-283`; `QUALIFICATION_DOSSIER.md:66` | PENDENTE (mesmo gate) |

## 1.2 Backend AArch64 `larm64.src` (L553–559)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 553 | 149 linhas, sobre `lkir` | CONFIRMADA | `wc -l`; `larm64.src:21` | OK |
| 555 | MOVZ 0xD2800000 / MOVK 0xF2800000 | CONFIRMADA | `larm64.src:25-26` | OK |
| 555 | STP/LDP/RET 0xA9BF7BFD/0xA8C17BFD/0xD65F03C0 | CONFIRMADA | `larm64.src:148` (teste) | OK |
| 555 | registradores de trabalho X9, X10, X11 | DIVERGENTE: máquina de pilha com o valor em X0, o operando esquerdo em X1 e o produto em X2/X3; X9..X12 só aparecem no escritor decimal | `larm64.src:7-13,77,109` | OK |
| 556 | ADDS/SUBS + `B.VS` | CONFIRMADA | `larm64.src:14` | OK |
| 556 | MUL + SMULH + `CMP …, ASR #63` + `B.NE` | CONFIRMADA (registradores X3, X2, não X11, X9) | `larm64.src:43,77` | OK |
| 556 | SDIV precedido de `CBNZ`; checagem `q*b==a \|\| r>=0` | DIVERGENTE: o divisor é testado com `CMP` + `B.EQ div0` e o quociente é multiplicado de volta pela multiplicação checada | `larm64.src:15` | OK |
| 556 | guard elidido quando provado por QF_LIA | FALSA: "no proof is consulted to elide them" | `lkir.src:13` | OK |
| 558 | linux: EM 183, 0x400000, entrada 0x400078, write=64, exit=93, trap sai com 3 | CONFIRMADA | `larm64.src:113,136` | PENDENTE para executar (qemu-aarch64) |
| 558 | exit com X0=0 | DIVERGENTE: sai com o último valor impresso | `larm64.src:17-18` | N/A |
| 559 | bare: 2 PT_LOAD, ROM 0x40000, entrada +176, RAM de 16 KiB em 0x80000, SP=0x84000, `B .`, causa em X17 | CONFIRMADA | `larm64.src:114,138,141` | OK (gera) |
| 559 | resultado gravado em `[0x80000]` e causa em `[0x80008]` | FALSA: nada é gravado na RAM; o resultado fica em X0 e a causa em X17 | `larm64.src:17-19,114` | N/A |

## 1.3 Backend RISC-V `lriscv.src` (L561–565)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 561 | 158 linhas, RV32IM e RV64IM | CONFIRMADA | `wc -l`; `lriscv.src:1` | OK |
| 563 | formatos R/I/S/B/U/J, ECALL 0x73, EBREAK 0x00100073 | CONFIRMADA | `lriscv.src:28-67` | OK |
| 564 | fórmulas de trap de overflow | NÃO VERIFICÁVEL em detalhe (o cabeçalho diz "same overflow tests as the LumePuter compiler") | `lriscv.src:17-18` | OK |
| 565 | ELF32 (52+2×32), ELF64 (64+2×56), pad de 4096, `.bin` plano | CONFIRMADA (o `.bin` sai junto com o ELF, sem um `mode == "bin"`) | `lriscv.src:148-151` | OK |
| 565 | freestanding: ROM 0x40000, RAM de 16 KiB, sp=0x84000, halt `a7=93; ECALL`, trap `EBREAK` | CONFIRMADA | `lriscv.src:10-11` | OK |
| 565 | `riscv64-linux-gnu` em 0x400000 com entrada 0x400078 | DIVERGENTE: o mesmo ELF em **0x40000**, entrada 0x40000 (write 64, exit 93 e trap 3 conferem) | `lriscv.src:142-149,20-22` | PENDENTE para executar (qemu-riscv64) |

## 1.4 Canal B (`lsafety_envelope.src`) e `lrv32_lowered.src` (L567–573)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 568 | Canal B nas linhas 192–750 | DIVERGENTE: `rv_*` 140–290, `cbl_` 309–331, `cbp_` 368–428, `cbt_` 441–508, `cbg_` 526–648, `s2_` 757–776 | grep em `lsafety_envelope.src` | N/A |
| 569 | não faz `use lumec`; compartilha 0 das 3.169 funções | CONFIRMADA | `lsafety_envelope.src:16-19`; `QUALIFICATION_DOSSIER.md:91` | OK |
| 569 | lexer `cbl_*`, parser `cbp_*`, checker `cbt_*`, gerador `cbg_*` | CONFIRMADA | `lsafety_envelope.src:9-12` | OK |
| 569 | AST `CbFn/CbInt/CbBin/CbIf/CbCall` | DIVERGENTE: os nós são `CbLit, CbTru, CbRef, CbPar, CbUn, CbBin, CbIf, CbLet, CbCall, CbFail`; `CbFn` e `CbInt` não existem | `lsafety_envelope.src:333-337` | OK |
| 569 | tipos só `int`/`bool`, literais em i32 | CONFIRMADA ("never" não foi verificado) | `lsafety_envelope.src:31-40` | OK |
| 570 | LumePuter com RAM de 64 KiB em trie de profundidade 5/14 | DIVERGENTE: RAM de **16 KiB** em 0x80000; registradores em trie de profundidade 5 (confere) | `lsafety_envelope.src:13-14,198-205,282` | OK |
| 570 | UART 16550 em 0x10000000; finisher em 0x100000, 0x5555 = pass | CONFIRMADA | `lsafety_envelope.src:273-280` | OK |
| 570 | falha = `(code << 16) \| 0x3333` | FALSA: qualquer valor diferente de 0x5555 vira `test_device_fail` | `lsafety_envelope.src:279` | OK |
| 571 | 2oo2D, 87.224 falhas injetadas e 0 não detectadas | NÃO VERIFICÁVEL no código (consta só no `CHANGELOG.md:39`; o código diz "2oo2 with diagnostics") | `lsafety_envelope.src:1` | PENDENTE (o gate roda o canal A como processo ELF) |
| 571 | `--split` gera `channel_a_x86_64.elf`, `channel_b_rv32im.elf` e `voter_protocol.json` | DIVERGENTE: gera `channel_a_x86_64.elf`, `channel_a_aarch64.elf`, `channel_a_riscv64.elf`, `channel_b_riscv_bare.bin` e `manifest.json` | `lsafety_envelope.src:111-119,1244-1251` | PENDENTE: o canal A gera `.elf` e usa `/bin/mkdir` (`:947`), `/bin/chmod` e `/bin/mv` |
| 572 | `lrv32_lowered.src` tem 132 linhas | CONFIRMADA | `wc -l` | OK |
| 573 | `se_b_compile_ast` | FALSA (não existe; existem `se_b_run` e `rc_*`) | `lrv32_lowered.src:3` | OK |
| 573 | consome `nf_late(lumec_expand(src))` | CONFIRMADA | `lrv32_lowered.src:1` | OK |
| 573 | suporta records, ADTs, arrays e closures | DIVERGENTE: a AST é `Num/Var/Bin/If/LetIn/Call` | `lrv32_lowered.src:5` | OK |
| 573 | usuário: `lneural_cartridge.src` | CONFIRMADA | `lneural_cartridge.src:72-73` | OK |

## 2.1 Targets em `ltarget.src` (L579–620)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 579 | 1.290 linhas | CONFIRMADA | `wc -l` | OK |
| 580 | 38 entradas JSON = 8 de `w12_target_kind` + 30 cláusulas de `target_parse_triple` | CONFIRMADA | `ltarget.src:107` (30 `valid: 1`), `:109` (38), `:1273` (8) | OK |
| 580 | 27 universais + 2 GUI + 1 neural | CONFIRMADA (soma 30) | `ltarget.src:107` | OK |
| 580 | `cli_describe` com 39 strings, incluindo `safetensors` | CONFIRMADA | `lcli.src:140` | OK |
| 580 | 5 empacotadores (`apk\|ipa\|uefi\|iso\|exe`) | CONFIRMADA (`exe` tem o alias `win64-gui`) | `ltarget.src:1123` | OK |
| 580 | `@mir`, `@ui-layout`, `@neural-kernel` | DIVERGENTE: `@ui-layout` e `@neural-kernel` existem; `@mir` não é um modo da ferramenta (existem as funções `mir_compile_or_lower`/`lume_mir_lower`) | `ltarget.src:1105-1107` | OK |
| 581 | sem JVM `CAFEBABE`, CIL ou LLVM IR; interop via `lchameleon`/`lume adapt` | CONFIRMADA | grep `CAFEBABE` = 0; `lmanual.src:386`; `lcli.src:62` | OK |
| T1 | `x86_64-linux-elf` e aliases; ELF de 120 B com entrada 0x400078 | CONFIRMADA (o caminho dinâmico de 232 B é do lasm, não do ltarget; `p_align` 65536) | `ltarget.src:107,634` | OK (gera) / execução N/A |
| T2 | `x86_64-windows-pe`: W^X `.text/.rdata/.bss` com IAT incluindo `VirtualAlloc` | DIVERGENTE: o PE do ltarget tem **2 seções** (`.text` RX, `.idata` RW 0xC0000040), importa só `GetStdHandle`, `WriteFile` e `ExitProcess`, e o arquivo tem 2.048 B. Shadow space de 32 B e cabeçalho de 512 B conferem | `ltarget.src:625,650-660` | OK (roda no Windows) |
| T3 | GUI: 33.792 B limpo / 33.824 B protegido, `e_lfanew=0x80`, 4 seções, Subsystem 2, EP 0x1000, ImageBase 0x400000, 5 DLLs e 35 imports, janela 1400×780, `LumeSovereignWin64Class`, estilos LISTBOX/EDIT com `WS_THICKFRAME`, `RT_ICON` + `RT_GROUP_ICON`, ícone de 1.128 B | CONFIRMADA | `ltarget.src:1177,1185,1189,1222-1234` | OK (PE nativo) |
| T3 | seções `.rdata` 0x3000 e `.rsrc` 0x7000; `DllCharacteristics = 0x8000` | DIVERGENTE: `.text` 0x1000, **`.idata` 0x3000**, `.data` 0x4000 (16 KiB), **`.rsrc` 0x8000**; `DllCharacteristics = 0` | `ltarget.src:1177` | OK |
| T3 | imports por DLL (KERNEL32 12, USER32 15, GDI32 `CreateFontW/CreateSolidBrush/...`, COMDLG32 `...W`, `ShellExecuteW`) | DIVERGENTE: KERNEL32 7, USER32 23, GDI32 2 (`CreateFontA`, `GetStockObject`), COMDLG32 2 (`GetOpenFileNameA`/`GetSaveFileNameA`), SHELL32 1 (`ShellExecuteA`); tudo ANSI | `ltarget.src:1185` | OK |
| T3 | menu de 5 itens (Arquivo, Editar, Executar, Ferramentas, Ajuda) | DIVERGENTE: 6 menus (`&Arquivo`, `&Editar`, `&Navegar`, `&Visualizar`, `E&xecutar (Lume)`, `&Seguranca P33`) | `ltarget.src:1228` | OK |
| T3 | aliases `windows-gui`, `win64-gui` | DIVERGENTE: os aliases são `windows-gui-x86_64`, `win64-gui` e `pe64-gui` | `ltarget.src:107` | OK |
| T3 | (omitido no dossiê) o programa do usuário é compilado no .exe | observação: **não é**. O target é um modelo fixo; do programa só entram strings e checagem de contratos | `ltarget.src:1236` | — |
| T4 | `aarch64-macos-macho`: exit `MOVZ X16,#1; MOVK X16,#0x200,LSL#16; SVC #0x80` | DIVERGENTE: só `MOVZ X16,#1; SVC #0x80` (0xD4001001), sem MOVK; Mach-O conforme L543 | `ltarget.src:430-431` | N/A |
| T5 | `x86_64-macos-macho`: `B8 01 00 00 02 0F 05` | CONFIRMADA (a página de 4 KiB está DIVERGENTE: é 16 KiB) | `ltarget.src:627,637` | N/A |
| T6 | `aarch64-ios-macho` | CONFIRMADA (platform 2) | `ltarget.src:1019-1022` | N/A |
| T7 | `aarch64-linux-elf`: EM 183, 0x400000, write 64, exit 93, `SVC #0` | CONFIRMADA | `ltarget.src:430,634` | N/A |
| T8 | `aarch64-android-elf`: nota `Android`, API 34 | CONFIRMADA | `ltarget.src:1024` | N/A |
| T9 | `aarch64-none-elf`: `WFE; B -4` | FALSA: não há WFE; é `B .` com a causa em X17 | `larm64.src:114` | N/A |
| T10 | Intel HEX com ELA `:020000040000FA` | DIVERGENTE: o ELA é `:020000040001F9` (base 0x10000) | `ltarget.src:691` | OK |
| T11 | `riscv64-linux-elf` em 0x400000 | CONFIRMADA no caminho do ltarget (o `riscv64-linux-gnu` do w12 usa 0x40000) | `ltarget.src:634` | N/A |
| T12 | `riscv64-none-elf` com `WFI = 0x10500073` | FALSA: não há WFI; o halt é `a7=93; ECALL` | `lriscv.src:10`; grep `273678451` = 0 | N/A |
| T13–T16 | `riscv64-none-bin`, `riscv64-none-ihex` (checksum), `riscv32-none-elf`, `riscv32-none-bin` | CONFIRMADA | `ltarget.src:1273-1274,675` | OK |
| T17 | `arm-none-cortexm`: ELF32 `EM_ARM`, Thumb-2 `MOVW/MOVT`, `BKPT #0; B .` | FALSA: o contêiner é binário cru (`cortexm-bin` = tabela de vetores + código), e o código **não é Thumb-2**: são palavras de 32 bits de uma VM de pilha própria (op/sub/arg16), autênticas só no halfword de halt/trap. Tabela de vetores 0x20020000/0x08000009 confere | `ltarget.src:883-896,932` | OK (gera; só roda no `mcu_vm`) |
| T18 | `avr-none-elf`: ELF32 EM 83 com `RJMP/LDI/CLI` | DIVERGENTE: o ELF32 com EM 83 confere; as instruções AVR são FALSAS (palavras da VM; halt = 0x9588 `sleep` no halfword alto) | `ltarget.src:886,891,929` | OK (gera) |
| T19/T21 | Intel HEX de AVR e de Xtensa | CONFIRMADA (o formato; o conteúdo são palavras da VM) | `ltarget.src:1070` | OK |
| T20 | `xtensa-esp32-elf`: EM 94, `ENTRY a1,32`, `MOVI`, `RETW.N` | DIVERGENTE: EM 94 confere; as instruções são FALSAS (palavras da VM; halt = 0xF01D) | `ltarget.src:887,891` | OK |
| T22 | `x86_64-none-raw` = `48 C7 C0 imm32 F4 EB FD` | FALSA: emite o programa completo (ctfail pela serial 0x3F8, escritor decimal, funções) e termina com `out 0xF4` (isa-debug-exit) + `cli; hlt`. Os aliases `x86_64-baremetal` e `bios-mbr` não existem; `x86_64-none-mbr` é alias do raw | `ltarget.src:107,574,625-627` | OK (gera) |
| T23 | MBR com VGA `"LUMEOK"`; ISO de 36.864 B (18 setores) | FALSA: o setor 0 do `pkg_iso9660_image_hex` é só `EB 3C 90 "LUMEBOOT"` + zeros + `55AA`, sem código e sem VGA (grep `LUMEOK` = 0). A ISO tem **21 setores = 43.008 B**; o payload no setor 20 é o PE **UEFI**. CD001 em 32769, BRVD no setor 17 e `LUME_OS`/`LUME_ISO` conferem | `ltarget.src:1121-1123` | OK (gera) |
| T24 | `x86_64-none-ihex` | CONFIRMADA | `ltarget.src:107` | OK |
| T25 | UEFI PE32+ de 1.024 B, Subsystem 10, EP 0x1000 | DIVERGENTE: o arquivo tem **2.048 B**; Subsystem 10 e EP conferem. Defeito: a imagem UEFI carrega diretório de importação de KERNEL32 e o código (ABI win64) chama `ExitProcess`/`WriteFile` pela IAT, o que é inválido em firmware UEFI. O alias `x86_64-unknown-uefi` não existe (o real é `bootx64-efi`) | `ltarget.src:574,650-662,107` | OK (gera) |
| T26 | WASM: export `main`/`lume_dom_mount`, tipo `()->i64`; sandbox `wasm_verify_capabilities` e `## @wasm-allow` | DIVERGENTE: é um módulo WASI real (importa `fd_write`/`proc_exit`, exporta `memory` e `_start`; tipos `(i32×4)->i32` e `(i32)->()`); `lume_dom_mount` não existe em nenhum `.src`; o verificador é `wasm_sandbox_verify` (recusa `path_open`/`sock_*` e memória fora de 1..16 páginas). O magic e o `[I0275]` conferem | `ltarget.src:739,1031-1058` | OK |
| T27 | `lumb`: bytecode com opcodes `0x01 CONST_I64` e `0xFF RET` | FALSA: o contêiner guarda o **resultado avaliado em tempo de compilação** (`LUMB`, versão 1, status, elided, nfns, último valor e o texto de stdout); não é bytecode. O magic `LUMB` confere | `ltarget.src:777` | OK |
| T28 | PTX `.entry lume_kernel(.param .u64 out_ptr)` | DIVERGENTE: a entrada leva o nome da função, o parâmetro é `p_out` e há `.maxntid 128`; a saída é só texto. A VM é `ptx_vm_run` (no ltarget), não `ptx_vm_eval_1d` em `nn.src`. `.version 8.0`/`sm_80` conferem | `ltarget.src:818` | OK |
| T29 | SPIR-V 1.6 com `LocalSize 64 1 1` | DIVERGENTE: é **assembly textual** (fmt `spvasm`), `LocalSize 128 1 1`, entrada com o nome da função | `ltarget.src:845` | OK |
| T30 | Verilog `lume_rtl_core(clk, rst_n, result_out[63:0])`; VHDL `signed(63 downto 0)`; `tg_neural_synth`; `equiv_ptx_verilog_vhdl` | DIVERGENTE: o módulo leva o nome da função, com portas `clk`, `rst` (alto), `done`, `trap` e uma saída por print; o VHDL usa `integer`; a função é `neural_kernel_synthesize` e a chave JSON é `silicon_3way_equivalence`, que compara as VMs Lume de PTX, SPIR-V e Verilog (**o VHDL não é executado**). As fórmulas fwd/bwd conferem | `ltarget.src:993-995,1134` | OK |
| T31 | QASM3 `qubit[8]` com preparação `x q[i]`, acoplado ao `lume_quantum_nexus_engine` | FALSA: é um modelo fixo de Bell com 2 qubits (`h`, `cx`, `cz`, `measure`), independente do programa (só um comentário muda) e não acoplado ao motor | `ltarget.src:1070` | OK |
| T31 | Surface code [[9,1,3]]: máscaras X 27/432/6/192, Z 54/216/9/288, X_L=73, Z_L=7, 27/27 erros | CONFIRMADA (no motor, um modelo clássico) | `lume_quantum_nexus_engine.src:566-612,708-712,862` | OK |
| T32 | DNA com cabeçalho `>LUME_DNA4_STRAND`, sem homopolímeros, GC balanceado | DIVERGENTE: não há cabeçalho (grep = 0); a fita codifica os bytes do `lumb` (o resultado pré-calculado); "sem homopolímeros" confere por construção (`tg_dna_next`); GC balanceado é NÃO VERIFICÁVEL; aliases `dna`/`bio-dna` não existem (o real é `wetware-dna`) | `ltarget.src:1062-1070,107` | OK |
| T33 | LumePuter: manifesto JSON de 13 camadas; aliases `lumeputer`, `lumepu`… | DIVERGENTE: é uma linha de texto `LUMEPUTER_WEIGHTS_V1;k=v;…` (`prepended_layers=16`), montada sobre o `lumb`; os aliases reais são `lumepu-vx-weights`, `lumeputer-weights` e `qwenputer-rv32im`. O `.safetensors` do `lneural_cartridge` confere | `ltarget.src:1070,107` | OK |
| T34 | ZIP: `PK\x03\x04` 30 B, central 46 B, EOCD 22 B, método store | CONFIRMADA | `ltarget.src:1109` | OK |
| T34 | `.apk` com `classes.dex` (`dex\n039`), `AndroidManifest.xml` e `liblume.so`; `.ipa` com `Info.plist` | FALSA: o ZIP tem **uma única entrada** (`lib/arm64-v8a/liblume.so` ou `Payload/LumeApp.app/LumeApp`) cujo conteúdo é uma lista ASCII de nomes + ELF/Mach-O + selo P33. Não há DEX (grep do magic = 0), nem manifesto binário, nem plist separado, nem assinatura: os pacotes não são instaláveis | `ltarget.src:1123` | OK (gera) |
| — | front-end do w12 (`w12_front_check`) | observação: procura `lumec` sem `.exe` e falha fechado com `[T0903]` | `ltarget.src:1280-1282` | PENDENTE: aceitar `lumec.exe` no Windows |

**Saídas que são só texto ou modelo** (não geram código executável de máquina real): `qasm3-quantum` (modelo fixo), `nvptx64-nvidia-cuda` (PTX texto), `spirv64-vulkan-compute` (SPIR-V textual), `verilog-rtl`, `vhdl-rtl`, `dna-quaternary` (texto que codifica o resultado), `lumeputer-rv32im-weights` (manifesto texto) e `lumb` (resultado pré-avaliado). **Pseudo-nativos** (rodam só na VM do próprio ltarget): `arm-none-cortexm`, `avr-none-elf`, `avr-none-ihex`, `xtensa-esp32-elf`, `xtensa-none-ihex`. **Modelo de GUI**: `x86_64-windows-gui[-protected]`, PE nativo mas com código fixo. **Código de máquina real**: os x86_64 (linux, windows-pe, uefi-pe, none-raw, none-ihex, macos), aarch64 (linux, macos, ios, android, none-ihex), riscv64 (linux, none-ihex), os 8 triples do w12 (larm64/lriscv) e o WASM.

## 2.2 Proteção P33 (L622–639)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 623 | `protect.src` tem 212 linhas | CONFIRMADA | `wc -l` | OK |
| 624-627 | identidades MBA em Z/2^64 | DIVERGENTE: as fórmulas conferem, mas operam em 32 bits (`pr_u32_*`) | `protect.src:157-161` | OK |
| 625 | grau 2 em árvore balanceada | NÃO VERIFICÁVEL (não encontrado) | — | OK |
| 628 | CFF `cff_eval_chain`, estados 101→205→309→0 | DIVERGENTE no nome (`cff_step`/`cff_run_flat`); os estados conferem | `protect.src:163-165` | OK |
| 629 | `wb_round`/`wb_derive_tag`, 4 rodadas de S-box de 16 entradas | DIVERGENTE no nome (`wb_generate_table`/`wb_eval_prf`); as 4 tabelas de 16 conferem | `protect.src:195-199` | OK |
| 630 | `secret_wrap`, `secret_ct_eq`, `secret_redact`, `"<REDACTED:std.secret>"` | FALSA: as funções são `secret_new`, `secret_show`, `secret_zeroize` e `secret_expose_bytes`; o texto é `"<redacted:secret>"`; não há `ct_eq` | `protect.src:78-96` | OK |
| 631 | `lprotect.src` tem 228 linhas | CONFIRMADA | `wc -l` | OK |
| 632 | `_L_F1.._L_Fn`, `.lsym` `lume-lsym-v1`, `lume symbolize` | CONFIRMADA | `lprotect.src:146,174`; `lcli.src` | OK |
| 633 | chave FNV-1a, `ek = (k % 251) + 3` | DIVERGENTE: `k = SHA-256("lume-protect-k1\|seed").a % 120 + 131` (131..250); `mkstr_enc` confere | `lprotect.src:104,166` | OK |
| 634 | `movabsq $(V-mask)` + `addq`; `mask = ((k%128)+1)*0x0101…` | DIVERGENTE: usa XOR (`movq $(V^m)`, `movq $m,%r11`, `xorq`) com `m = (k%128)*0x0101…` (sem +1), só para imediatos fora de int32 | `lprotect.src:197-200` | OK |
| 635 | selo checa 2 bytes (`$76` e `$85`); `exit(99)` | DIVERGENTE: checa só o primeiro byte (`$76`); `exit(99)` pela syscall 60 confere | `lprotect.src:170,215` | PENDENTE: confirmar que o `syscall` injetado pelo lprotect passa pela troca `--win64` → `__win_syscall` (a ordem lprotect/win64 decide) |
| 636 | stub GUI-protected em `ltarget.src:465-479` | DIVERGENTE: está em `ltarget.src:1222,1232,1234` | grep | OK |
| 637 | XOR 0xB2 sobre 10.240 B da `.data`; selo `LUME_SEAL:P33_MAX:178:PE64_GUI` de 32 B | CONFIRMADA (a `.data` tem 16 KiB; o XOR cobre os primeiros 10 KiB) | `ltarget.src:1222,1232,1234` | OK |
| 637 | `AddressOfEntryPoint` realocado para 0x16B0 | FALSA: a EP fica em 0x1000 nos dois modos (o cabeçalho é compartilhado) | `ltarget.src:1177,1234` | OK |
| 638 | prólogo de 26 bytes `50 59 48 87 C0 BE 00 40 40 00 B9 00 28 00 00 80 36 B2 48 FF C6 48 FF C9 75 F5` | CONFIRMADA | `ltarget.src:1222` | OK |
| 639 | seguido de `jmp 0x1000` (`E9 2F F9 FF FF`) | FALSA: não existe; o fluxo cai direto no código de início | `ltarget.src:1222` | OK |

## 3. Silício neural e IA (L643–698)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 645 | `lneural_cartridge.src` tem 434 linhas | CONFIRMADA | `wc -l` | OK |
| 646 | `lnc_build`/`lnc_pack_safetensors` | DIVERGENTE (as funções reais são `lnc_compile`, `lnc_header`/`lnc_file_bytes`) | `lneural_cartridge.src:326-335` | OK |
| 647-652 | 5 tensores (gate/up I32 [128,128], down I64 [16,128], rom U32, ballast I64 [16] = 2^36), `\|y\|*4 <= B` | CONFIRMADA | `lneural_cartridge.src:17,22,178` | OK |
| 654-657 | `lnc_unit`, `lnc_alu`, `lnc_select`, `lnc_dn_step` | CONFIRMADA | `lneural_cartridge.src:200,207,263,264` | OK |
| 658 | `source_sha256`, `tensors_sha256`, `proof_status`, `cartridge_sha256`, `lcert_verify_artifact` | CONFIRMADA (`certificate_sha256` está DIVERGENTE: é `lcert_certificate_hash`) | `lneural_cartridge.src:60-63` | OK |
| 659 | LumePU em `lchameleon` 315–465 com `SH1ADD/2/3`, `BMAC`, `lumepu_vdot_int8_int4_mac`, `lumepu_vx_vmat_row_mac_exact`; 13 camadas (11 sem Zba/BMAC) | DIVERGENTE: a seção 1m começa em ~313 e a 1n em 421; `SH*ADD` não aparece; "BMAC" só como `bmac_digit_file_step`; as duas funções `lumepu_*` existem; 13/11 dependem de `vx_wrom_chunks > 0`, não de Zba/BMAC | `lchameleon.src:313-420,393,399,405,416-419` | OK |
| 661 | `lume_opentpu_engine.src` tem 426 linhas | CONFIRMADA | `wc -l` | OK |
| 663 | `word = opcode*1.000.000 + rd*100.000 + rs1*100 + imm2` | DIVERGENTE: `rd*10.000`; a função é `otpu_encode_insn` | `lume_opentpu_engine.src:55-58` | OK |
| 663 | 9 opcodes, com 19 = STREAM | CONFIRMADA | `lume_opentpu_engine.src:23` | OK |
| 664 | R0 fixo, R1..R7 de endereço, R8..R15 de argumento | CONFIRMADA | `lume_opentpu_engine.src:33-42` | OK |
| 666 | replay `ceil(M/MCOLS)` | CONFIRMADA | `lume_opentpu_engine.src:73-76` | OK |
| 667 | 68 bits por 16 pesos FP4 (`otpu_fp4_pack_bits`) | CONFIRMADA (o nome real é `otpu_fp4_storage_bits_16w`) | `lume_opentpu_engine.src:140-143` | OK |
| 668 | `otpu_ksmooth_dot_equiv_check` | FALSA (não existe; existem `otpu_ksmooth_scale_q/k`) | grep | OK |
| 669 | STREAM de 5 estágios `otpu_stream_gated_deltanet_step` | DIVERGENTE no nome (`otpu_stream_deltanet_step`); os estágios conferem | `lume_opentpu_engine.src:195-247` | OK |
| 670 | `otpu_three_way_zero_ulp_gate` com perfis 16×16@350 MHz… | DIVERGENTE: é `otpu_golden_rtl_zero_ulp_verdict`, que compara 3 CRCs de modelos Lume (o "Verilog RTL" é a função Lume `otpu_exec_verilog_rtl_pipe`, não um simulador); os nomes das placas existem, mas tamanhos e frequências não aparecem no código | `lume_opentpu_engine.src:294-307` | OK |
| 673 | `tensor.src` (177 linhas) e todas as funções citadas | CONFIRMADA | grep (todas presentes) | OK |
| 674-677 | seção 1l, linhas 260–314: bf16/fp16 finitos, quire, intervalo | CONFIRMADA (o quire é soma inteira simples, trivialmente associativa; o intervalo usa `±ulp_eps`, não `±1` fixo) | `lchameleon.src:260-300` | OK |
| 680 | `nn.src` (306 linhas): MLP, Wengert, tanh Padé `x(27M+x²)/(27M+9x²)`, safetensors, ONNX ir 9 (`0809…1015`) | CONFIRMADA | `nn.src:177-178,124,158` | OK |
| 680 | Adam com `beta1=9/10`, `beta2=99/100` e correção de viés | FALSA: `adam_step_mlp2` acumula `m + g` (`nn_mom_list`), sem betas e sem correção de viés | `nn.src:37-43` | OK |
| 680 | VMs PTX/SPIR-V 1D em `nn.src` | DIVERGENTE: `nn.src` emite PTX/SPIR-V (`kernel_emit_ptx`); `ptx_vm_eval_1d`/`spirv_vm_eval_1d` não existem (as VMs são `ptx_vm_run`/`spirv_vm_run`, no ltarget) | `nn.src:194-223` | OK |
| 681-682 | DEQ em `lsentience` 196–203, `dl_dw = z*w/(scale-w)` | CONFIRMADA (fórmula e linha 203) | `lsentience.src:203` | OK |
| 682 | ponto fixo resolvido em O(1) por forma fechada; `memory_bytes_saved_pct = 99` | DIVERGENTE: `deq_solve_loop` itera até 100 vezes; `memory_bytes_saved_pct` não existe | `lsentience.src:203` | OK |
| 685 | `ai_runtime.src` tem 166 linhas | CONFIRMADA | `wc -l` | OK |
| 686-689 | `prob_ln_milli`, `prob_hmc_step`, `energy_drift`, `datalog_Closing_2hop`, `llm_parse_invoice`, `lif_simulate` | DIVERGENTE: os nomes reais são `prob_ln`, `infer_mcmc/svi/smc/hmc`, `hmc_leapfrog`, `datalog_closure`, `llm_extract_invoice_repaired` e `lif_run_Currents`; `[V0001]`, `llm_in_weights_lumeputer_exec` e `lif_step` conferem | `ai_runtime.src` (lista de `fn`) | OK |
| 690-693 | `lume_llm_core.src` (332 linhas): MAC de 1 bit e ternário, `llm_pack_5trits` | CONFIRMADA (a chave `zero_fp_mul` não existe) | grep | OK |
| 694 | LFM3 12,5 Hz, 150 tok/s, DSpark `matched_k`, Colibri 6.000 MB | CONFIRMADA | grep | OK |
| 695-698 | roteador `llm_select_tier` com `has_formal_spec`, `vram_mb`, `llm_scrape_price_guard`, `llm_cegis_verify_candidate` | DIVERGENTE/FALSA: a assinatura é `(is_offline, complexity_bps, has_cloud_api_key)`; Tier 0 se complexidade ≤ 3000; Tier 1 se offline, sem chave de API ou ≤ 8000; Tier 2 nos demais; as funções de oráculo citadas não existem | `lume_llm_core.src:142-147` | OK |

## 4. Criptografia (L702–801)

| linha | afirmação | veredito | evidência | Windows |
|---|---|---|---|---|
| 704 | 118 kernels `lct_k_*` `@secret @no_alloc` | CONFIRMADA (118 definições) | `lcrypto_tls.src:196-622`; `QUALIFICATION_DOSSIER.md:115` | OK |
| 704 | linhas 196–624 | CONFIRMADA | primeiro `@secret` em 196, última função em 622 | — |
| 705 | sem saltos, divisões ou chamadas; `[C0011]`, `[E0210]`, `[C0010]` | CONFIRMADA | `lcrypto_tls.src:19-23`; os códigos existem em `lcli/lmanual/lqualify` | PENDENTE: ltv/lstack com `@exec 1` executam vetores nativos (ELF) |
| 705 | ≥ 2.360 vetores nativos de fronteira | CONFIRMADA como limite inferior (a última execução registrou **3.508**) | `QUALIFICATION_DOSSIER.md:115` | PENDENTE (idem) |
| 705 | pilha máxima ≤ 536 B | CONFIRMADA (536 B em `lct_k_fe_m0`) | `QUALIFICATION_DOSSIER.md:115` | PENDENTE (lstack sobre o asm Linux) |
| 707-735 | as 9 categorias (11+9+26+3+25+18+5+17+4) e todos os nomes | CONFIRMADA (os 118 nomes batem um a um) | lista extraída de `lcrypto_tls.src` | OK |
| 708 | `lct_k_is_zero = ((d-1)>>62)&1` | DIVERGENTE: `ct_eq(acc, 0)` | `lcrypto_tls.src:201-204` | OK |
| 736 | 37 kernels com `ensures` | DIVERGENTE: **31** | `QUALIFICATION_DOSSIER.md:115`; contagem em 196–626 | OK |
| 736 | HMAC (RFC 4231), HKDF (RFC 5869), AEAD sem plaintext em falha de tag, X25519 recusando all-zero, Ed25519 estrito | CONFIRMADA (o detalhe do Ed25519 estrito não foi auditado) | `lcrypto_tls.src:689,731-734,897` | OK |
| 738 | dudect: 24 alvos + 2 controles em `tests/harness/crypto_tls_gate.src` | CONFIRMADA. **O dudect existe só no gate**; em `lcrypto_tls.src` aparece apenas em comentários | `crypto_tls_gate.src:272-299,374` | OK para a medição (rdtsc); PENDENTE para o gate inteiro (`cg_kernels` usa `hio_run("mkdir")`, ltv e lstack) |
| 739 | `cpu_rdtsc`, descarte por `__lume_gc_count`, 6 percentis, `\|t\|<4,5`, controles `\|t\|>10`, 16 autotestes | CONFIRMADA | `crypto_tls_gate.src:177-205,372` (16 `dd_near`) | OK (falta confirmar os builtins rdtsc/gc_count no PE) |
| 740-764 | os 24 alvos com nomes e tamanhos (100.000 / 25.000 / 1.000 com gcmode 1) e controles `dd_leaky_eq`/`dd_sqmul` | CONFIRMADA | `crypto_tls_gate.src:265-299` | OK |
| 731 | SHA-512 em metades porque o dudect viu `\|t\|>40` | CONFIRMADA | `lcrypto_tls.src:71,661` | OK |
| 766 | X.509 em `lcrypto_tls` 1258–1445 | DIVERGENTE (aproximado: comentários desde ~1228, funções 1280–1445) | grep | — |
| 767-768 | `lct_der_tlv`/`lct_x509_parse`; ≤ 16.384 B; comprimentos < 65.536; forma indefinida e não mínima recusadas; BIT STRING com 0 bits; unique IDs recusados; Ed25519 sem parâmetros | CONFIRMADA | `lcrypto_tls.src:1250-1258,1280,1374` | OK |
| 768 | `id-X25519` identificado em `lx509.src` | DIVERGENTE: está em `lcrypto_tls.src:1354` (grep em `lx509` = 0) | — | OK |
| 769 | `lx509.src` tem 200 linhas | CONFIRMADA | `wc -l` | OK |
| 770 | `lx_pem_decode_chain`, `lx_verify_pem`, `lx_verify_artifact_sig`, uso em `lume qualify` | FALSA: os nomes reais são `lx_pem_block`, `lx_certs_of_file`, `lx_verify`, `lx_show` e `lx_entropy`; não há ligação com qualify | `lx509.src` (lista de `fn`) | OK |
| 770 | Base64 com bits de padding nulos (`bit_and(b,15)`, `bit_and(c,3)`) | CONFIRMADA | `lx509.src:86` | OK |
| 771-772 | profundidade máxima 8, erros 1..57, regras de BasicConstraints e pathLen | CONFIRMADA | `lcrypto_tls.src:1250-1258,1396` | OK |
| 773 | `keyCertSign` (máscara 1024) e `digitalSignature` | CONFIRMADA | `lcrypto_tls.src:1396` | OK |
| 773 | extensão crítica desconhecida = erro 36 | DIVERGENTE: erro **25** | `lcrypto_tls.src:1254` | OK |
| 774 | issuer ≠ subject = erro 46 | DIVERGENTE: erro **49** (46 = "issuer is not a CA") | `lcrypto_tls.src:1257` | OK |
| 774 | CommonName comparado case-insensitive, erro 57 | FALSA: a verificação de nome de host/subjectAltName **não existe** ("NOT checked"); 57 = "no trust anchors"; o OID [85,4,3] não aparece | `lcrypto_tls.src:1246-1248,1258` | OK |
| 776 | calendário de Hinnant (146.097 dias), janela do UTCTime, caminhada de 3.652.059 dias | CONFIRMADA | `lcrypto_tls.src:1297-1303,1828`; `crypto_tls_gate.src:86` | OK |
| 777 | fuzz de 6.000 cadeias (5.000 fixas + 1.000 do urandom), 0 aceitas | CONFIRMADA | `crypto_tls_gate.src:82-84`; `CHANGELOG.md` | OK (urandom via BCrypt) |
| 779 | `lct_entropy_check2`, linhas 1192–1255 | CONFIRMADA (aprox. 1192–1220) | `lcrypto_tls.src:1205` | OK |
| 780 | dois blocos de `max(n,512)` lidos com `fs_read_bytes` | DIVERGENTE: lê byte a byte com `fs_read_byte("/dev/urandom", 0)`; os dois blocos conferem | `lcrypto_tls.src:1179-1180,1210` | OK (BCryptGenRandom) |
| 781-787 | erros 1..7, RCT com cutoff 6, APT com W=512 e cutoff 19 | CONFIRMADA | `lcrypto_tls.src:1200,1203-1206` | OK |
| 788 | `lct_not_trivial32` em `ed25519_sign`, `x25519_public` e nos peers TLS, recusando valores constantes ou sequenciais | DIVERGENTE/FALSA: a função é `lct_weak_secret` (recusa só "todos os bytes iguais", não sequenciais) e é usada só nas configs TLS | `lcrypto_tls.src:1215-1217,1453,1065` | OK |
| 791 | 0x0303/0x0304, `TLS_CHACHA20_POLY1305_SHA256` 0x1303, x25519, ed25519 0x0807 | CONFIRMADA | `lcrypto_tls.src:935-936` | OK |
| 793 | key schedule `lct_tls13_handshake_keys`/`_master_keys` | DIVERGENTE nos nomes (`lct_tls13_early_secret`, `handshake_secret`, `master_secret`, `key_schedule`, `traffic_keys`); rótulos `"tls13 "` e `"c hs traffic"` conferem | `lcrypto_tls.src:902,913` | OK |
| 794-795 | record layer: cabeçalho de 5 B como AAD, nonce = `iv XOR seq`, `seq < 2^62`, ciphertext ≤ 16.640, remoção de padding, descarte de CCS | CONFIRMADA (nomes reais `lct_tls13_record_seal/record_open/strip`; `open` aceita até 5 + 16.640) | `lcrypto_tls.src:168,923-932,1127` | OK |
| 797 | `ensures result == 99 or (result > state and result <= 16)` | CONFIRMADA | `lcrypto_tls.src:960-963` | OK |
| 798-799 | transições (cliente 0 → 1 com CH(1); servidor 10 → 11 → 12 com SH/EE/CERT/CV) | DIVERGENTE: o cliente vai de START a WAIT_SH no evento local 100 (CH enviado); de WAIT_CERT_CR vai a WAIT_CERT com CR(13) ou a WAIT_CV com CERT(11). Os estados do servidor são RECVD_CH, NEGOTIATED, WAIT_FLIGHT2, WAIT_CERT, WAIT_FINISHED e CONNECTED, com eventos 1, 101, 102, 103/104, 11, 15, 20 | `lcrypto_tls.src:952-958` | OK |
| 800 | zeroização no estado 99, `lct_tls13_holds_nothing` | CONFIRMADA (`lct_tls13_client_fail`/`server_fail` não existem) | `lcrypto_tls.src:950-951,1153` | OK |
| 800 | sentinela de downgrade `DOWNGRD` | FALSA: não há (grep = 0; HRR também não está implementado) | `lcrypto_tls.src:942` | OK |
| 800 | contexto do CertificateVerify (64×0x20 + rótulo) | CONFIRMADA | `lcrypto_tls.src:1019` | OK |
| 801 | `lct_tls13_client_new` (RPK) e `lct_tls13_client_new_x509` + SNI `server_name` 0x0000 | DIVERGENTE/FALSA: os construtores são `lct_tls13_client_config`, `_config_x509` e `_os`; `server_name` é explicitamente "NOT implemented" | `lcrypto_tls.src:937-944` | OK |
| — | TLS é sans-IO ou fala com a rede? | observação: **sans-IO**. O estado é um valor; `lct_tls13_feed` devolve o próximo estado, com `.out` (registros a transmitir) e `.app`; nenhum socket | `lcrypto_tls.src:950-951` | OK como biblioteca; PENDENTE para conexões reais (sockets retornam -ENOSYS no Windows) |

---

## Contagem por veredito (linhas das tabelas)

| veredito | quantidade |
|---|---|
| CONFIRMADA | 104 |
| DIVERGENTE (inclui DIVERGENTE/FALSA) | 67 |
| FALSA | 32 |
| NÃO VERIFICÁVEL | 5 |

(Algumas linhas mistas, como "CONFIRMADA (… DIVERGENTE …)", foram contadas pelo veredito principal. As 4 linhas de "observação" não entram na contagem.)

## Lista consolidada de afirmações falsas ou divergentes (mais relevantes)

1. AVX2 `vmovdqa/vpcmpeqb/vpaddb/vpaddd/vpmovmskb/vpbroadcastb/q/vpmulld` não existem no lasm (L532), e a divisão das 39.968 instruções por família é inventada (L551). Os casos negativos são 176, não 22.
2. PE do lasm: `Characteristics` 0x23 (não 0x22) e stack reserve de 4 GiB (não 1 GiB). ELF estático com `p_align` 4096 (não 0x200000). ELF dinâmico ativado por `.need`/`.extern` (não `.ffi_lib`/`.ffi_sym`). `[L0010]` = símbolo duplicado.
3. MBR do lasm: não há A20 nem fallback CHS; DAP em 0x7CF0, ljmp 0x7C80, RSP 0x7C00. ISO do lasm: setores 0..15 zerados e sem `LUME_OS`. `.debug_abbrev` tem 35 B.
4. Mach-O **existe**, mas com 12 comandos, `sizeofcmds` 592, `entryoff` 1024, `__TEXT` de 16 KiB também no x86_64 e sem `LC_CODE_SIGNATURE`. O exit do arm64 não tem MOVK.
5. larm64: não há elisão por QF_LIA (`lkir.src:13`), não há `CBNZ`, os registradores não são X9..X11 e o bare não grava em RAM. lriscv linux em 0x40000.
6. Envelope: RAM do LumePuter de 16 KiB; não há código de falha `(code<<16)|0x3333`; os arquivos do split e os nós da AST são outros; `se_b_compile_ast` não existe; `lrv32_lowered` não trata records/ADTs/closures.
7. ltarget: Cortex-M, AVR e Xtensa **não geram instruções nativas** (palavras de VM própria). `x86_64-none-raw` não é `48 C7 C0…F4 EB FD`. Não há WFE nem WFI. `lumb` é resultado pré-avaliado, não bytecode. QASM3 é modelo fixo de 2 qubits. PTX e SPIR-V são texto (SPIR-V com LocalSize 128). WASM é WASI (`_start`, `fd_write`), sem `lume_dom_mount`. DNA sem cabeçalho. Manifesto LumePuter em texto `k=v` (16, não 13). ELA do Intel HEX = `0001`. Vários aliases citados não existem.
8. APK/IPA não são pacotes válidos (uma entrada ZIP, sem DEX, manifesto ou plist). ISO do pacote tem 43.008 B, MBR sem código e payload UEFI. UEFI tem 2.048 B e importa KERNEL32 (defeito).
9. GUI: seções `.idata`/`.rsrc` em 0x3000/0x8000, `DllCharacteristics` 0, imports ANSI com outras contagens por DLL, 6 menus. O stub protegido **não** move a EP para 0x16B0 e **não** tem `jmp 0x1000`. O .exe é modelo fixo: o código do usuário não é compilado.
10. P33: MBA em 32 bits; nomes de CFF, white-box e `std.secret` errados; chave por SHA-256 (não FNV-1a); máscara por XOR, sem +1; selo checa 1 byte.
11. IA: codificação OpenTPU `rd*10.000`; perfis de placa ausentes; `otpu_ksmooth_dot_equiv_check` inexistente; Adam sem betas; VMs PTX/SPIR-V não estão em `nn.src`; DEQ iterativo; roteador de tiers com outras entradas e oráculos CEGIS inexistentes; muitos nomes de `ai_runtime` diferentes.
12. Cripto: 31 kernels com `ensures` (não 37). `is_zero` usa `ct_eq`. Erros X.509 25/49 (não 36/46). **Não há verificação de nome de host/CommonName.** `lct_weak_secret` recusa só bytes todos iguais e só é usado nas configs TLS. **Não há sentinela DOWNGRD nem SNI.** Os nomes das funções TLS e PEM (`lx_pem_decode_chain`, `lx_verify_pem`…) estão errados. As transições de estado do servidor são outras.

## O que falta para o Windows ficar igual ao Linux (Parte IV)

1. **`lasm_gate`** (39.968 + 1.467 + 176): depende de GNU `as`, `objcopy` e `objdump` e de executar ELF. Opções: rodar a referência no Linux/WSL e comparar no Windows contra bytes de referência guardados, ou portar um oráculo independente. Sem isso, a paridade não é reverificável no Windows nativo.
2. **`multi_arch_gate`** (larm64/lriscv): exige `qemu-aarch64`/`qemu-riscv64`. Alternativa em Lume puro: emuladores AArch64/RV64 (o RV32 já existe em `rv_*`).
3. **`safety_envelope_gate`/`lsafety_envelope`**: trocar `os_run("/bin/mkdir"…)` (`lsafety_envelope.src:947`) e as chamadas a `/bin/chmod` e `/bin/mv` do split pelos builtins de arquivo. Compilar o canal A com `lumec --win64` + `lasm --pe` (gerar `.exe` em vez de `.elf`) e procurar `lumec.exe`/`lasm.exe`. Os ELF aarch64/riscv64 do split continuam dependendo de QEMU.
4. **`ltarget` (w12)**: `w12_find_lumec` procura `lumec` sem extensão e falha com `[T0903]` no Windows; precisa aceitar `lumec.exe` (o `/tmp` já é mapeado).
5. **`crypto_tls_gate`**: `cg_kernels` usa `hio_run("mkdir")` e roda `ltv`/`lstack` sobre o asm Linux; o `@exec 1` do ltv executa vetores nativos, o que exige ltv/lstack em PE e asm `--win64`. O dudect deve funcionar se `cpu_rdtsc` e `__lume_gc_count` estiverem no runtime PE (confirmar). KATs, X.509, fuzz e entropia são Lume puro ou já portados.
6. **`lprotect --protect max` com `--win64`**: o guard do selo injeta um `syscall` literal; confirmar que a troca `syscall` → `call __win_syscall` acontece depois do lprotect. Se acontecer antes, o binário protegido trava no Windows.
7. **TLS em rede**: a biblioteca é sans-IO e funciona, mas uma conexão real precisa de sockets (hoje -ENOSYS na camada win64).
8. **Execução de artefatos não-Windows** (ELF Linux, Mach-O, kernel MBR/ISO, ELF bare-metal, imagens MCU): N/A no Windows sem VM ou emulador. A geração em si é Lume puro e já funciona.
9. **Defeitos que afetam as duas plataformas**: a UEFI importa KERNEL32 e chama `WriteFile`/`ExitProcess`; APK/IPA não são instaláveis; o Mach-O arm64 não tem assinatura; o MBR do pacote ISO não tem código.
