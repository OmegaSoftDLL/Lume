# Auditoria: catálogo, Parte IX (linhas 1842–2076)

Arquivo auditado: `C:\Users\Ricardo.Bueno\LUME_CATALOGO_COMPLETO_IMPLEMENTADO_E_TESTADO_PT_BR.md`, linhas 1842 a 2076: referência de sintaxe, operadores e as "220+" funções builtin/intrínsecas.
Repositório conferido: `C:\Users\Ricardo.Bueno\lume`, árvore de trabalho de 2026-11-13. HEAD é `2916735`, e há modificações locais em `compiler/stage1`.
Método: leitura estática de `name_flow.src`, `runtime_core.lume`, `lume/05_codegen.src`, `lume/01_lexer.src`, `lume/02_parser.src`, `lume/03_comptime.src`, `lume/06b_phase3.src`, `lume/07_driver.src`, `arena.src` e `docs/42-windows-native-toolchain.md`. Os números de syscall de cada builtin saem de um script que segue os rótulos do runtime e as chamadas entre eles (fecho transitivo de `movq $N, %rax` antes de `syscall`). Nenhum programa foi executado.

## Convenções

- **CONFIRMADA**: o código faz o que o catálogo diz.
- **DIVERGENTE**: existe, mas a assinatura, a semântica ou um detalhe difere.
- **FALSA**: a afirmação contradiz o código.
- **NÃO VERIFICÁVEL**: afirmação vaga, ou que dependeria de execução.

Abreviaturas das evidências:
- `nf:N`: `compiler/stage1/name_flow.src`, linha N. As linhas 23 (`lis_sys_call`), 24 (`lis_tier_call`), 26–28 (`lis_pack/zip/mem_call`), 29 (`nf_rtbase`), 32–33 (`nf_special1/2`), 36–40 (aridades `nf_ar0..3`, `nf_builtin_arity`) e 42 (`nf_internal`, que gera o erro R0203).
- `core:N`: `compiler/stage1/runtime_core.lume`, linha física N. As linhas são longas e cada uma contém um bloco de assembly.
- `cg:N`: `compiler/stage1/lume/05_codegen.src`. A linha 961 é `runtime_sys_tail` e a 921 é `runtime_tier_tail`.
- `lx:N` é `lume/01_lexer.src`, `ps:N` é `lume/02_parser.src`, `ct:N` é `lume/03_comptime.src`, `p3:N` é `lume/06b_phase3.src`.
- **Windows**: vale para o porte nativo (`lumec --win64`, onde `lw_win64` em `07_driver.src:392` troca `syscall` por `call __win_syscall`). A camada fica em `core:160` (`__win_syscall`).
  - Despacho real extraído do código: 0, 1, 2, 3, 8, 9, 10, 11, 22, 28, 33, 35, 39, 57, 58, 59, 60, 61, 62, 73, 74, 79, 80, 82, 83, 84, 87, 90, 97, 98, 217, 228 e 231.
  - Os números 13, 131 e 160 (rt_sigaction, sigaltstack, setrlimit) são no-ops; as falhas chegam por `__win_veh`.
  - Qualquer outro número retorna -ENOSYS.
  - Valores da coluna: OK, PARCIAL (funciona com semântica reduzida), PENDENTE (syscall faltando), N/A (bare-metal ou instrução privilegiada) e COMPILAÇÃO (intrínseco resolvido pelo compilador, sem código de runtime nem syscall).

## 9.1 Operadores e precedência

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 1842 | título: "220+ funções" | CONFIRMADA (ordem de grandeza) | nf:18–42 têm 333 nomes, dos quais 33 são internos (R0203), restando 300 aceitos, incluindo aliases e formas sintéticas. O catálogo cita cerca de 225 nomes. | — |
| 1844 | "precedência (`02_parser.src`)" | DIVERGENTE (leve) | Os níveis 1 a 7 ficam em ps:62–90. O nível 8 (pós-fixos) fica em lx:167–182 (`postloop`, `postindex`, `post`), não no parser. | — |
| 1848 | `\|>` é o operador de menor precedência, associativo à esquerda, e `x \|> f(a,b)` vira `f(x,a,b)` | CONFIRMADA | ps:84–90: `pipeloop` sobre `orloop`. `mkpipe` insere o lado esquerdo como 1º argumento; `Var` vira `f(x)`, e outra forma vira `_call`. | COMPILAÇÃO |
| 1849 | `or` com curto-circuito | CONFIRMADA | ps:81–83; cg:386 (`lcond_or` por saltos) | COMPILAÇÃO |
| 1850 | `and` com curto-circuito | CONFIRMADA | ps:77–80; cg:386 (`lcond_and`) | COMPILAÇÃO |
| 1851 | `not` liga mais fraco que as comparações | CONFIRMADA | ps:75: `cmp` vê `not` e aplica `notcmp(cmp(...))`, que vira `Bin("==", e, 0)`. Portanto `not a == b` equivale a `not (a == b)`. | COMPILAÇÃO |
| 1852 | comparações não encadeáveis, com erro [P0002] | CONFIRMADA | ps:73–74 (`cmpdone`: "comparisons do not chain") | — |
| 1852 | "comparações estruturais em O(1) de pilha" | NÃO VERIFICÁVEL | Formulação vaga. A igualdade de strings e de estruturas percorre os dados (`eqv`/`streq`), portanto não é O(1) em tempo. | — |
| 1853 | `+ - +% -%` no mesmo nível | CONFIRMADA | ps:66–69 (`addloop`); tokens de dois caracteres em lx:46 | — |
| 1853 | overflow `jo __rt_ovf` termina com exit 3 | CONFIRMADA | `__rt_ovf` e `__rt_die3` (core:66) escrevem em stderr e fazem `exit(3)`. Ressalva: um quadro `__lume_try_begin` ativo captura o erro. | OK |
| 1853 | `+` concatena strings; `+%`/`-%` são wrapping em 64 bits | CONFIRMADA | cg:447 (`lbin_str`); `__rt_wadd` e `__rt_wsub` no runtime | OK |
| 1854 | `* / % *%`; divisão segura contra 0 e contra `INT64_MIN/-1` com exit 3 | CONFIRMADA | ps:62–65; `__rt_idiv`/`__rt_imod` (core:110) testam divisor 0 e fazem `cmp -1` seguido de `sub 1; jo __rt_ovf` | OK |
| 1855 | menos unário verificado | CONFIRMADA | ps:52: `-e` vira `Bin("-", Num(0), e)`, que passa pela subtração verificada | OK |
| 1855 | chamada, `r.campo`, `xs[i]` verificado, `.await` | CONFIRMADA | lx:173 (`.campo`, `.await` vira `AwaitE`, `.m(args)` é UFCS), lx:182 (`xs[i]` vira `lidx`, e `xs["k"]` vira `Field`). `lidx` fora da faixa leva a `__rt_oob_msg` e exit 3 (core:64). | OK |
| — | omissões em 9.1 | — | Faltam a chamada de método UFCS `x.f(a)` (lx:167), a chamada direta de lambda `(fn ...)(x)` e o erro de precedência `-` antes de padrão negativo (`isnegpat`, ps:61). | — |

## 9.2 Builtins: Strings, UTF-8, conversão e I/O padrão

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 1863 | `count(x)`: bytes de str ou número de elementos de lista | CONFIRMADA | nf:29, nf:37 (aridade 1); core:87 (`.Lrt_cnt_len`/`.Lrt_cntc_lp`). Observação: `mklist` é interno e chamá-lo dá R0203 (nf:42). | OK (sem syscall) |
| 1864 | `at(s,i)`: SSO de 1 byte, ou `""` fora da faixa | CONFIRMADA | nf:38 (aridade 2); core:89 (`__rt_at_ch`; `.Lrt_at_oob` retorna o imediato 2, que é a string vazia; índice negativo também dá `""`) | OK |
| 1865 | `slice(s,a,b)` | CONFIRMADA | nf:29, nf:39 (aridade 3); core:89 | OK |
| 1866 | `slicen(s,len,a,b)` | CONFIRMADA | nf:40 (aridade 4); core:89 | OK |
| 1867 | `ord(ch)`: 0..255, ou **-1 se vazia** | **DIVERGENTE** | core:105: `ord` faz `__rt_sv0; movzbq (%rax)`, ou seja, lê o primeiro byte. Para `""` lê o terminador NUL e retorna **0**, não -1. | OK |
| 1868 | `ord_at(s,i)` sem alocar | CONFIRMADA | nf:29 (aridade fixa 2 por `nf_rtbase`; não está em `nf_ar2`); core:105. Fora da faixa retorna 0 (`.Lrt_oa_oob`, que devolve o imediato 1). | OK |
| 1869 | `chr(code)`: SSO de 1 byte, exit 3 fora de 0..255 | CONFIRMADA | nf:37; core:105 (`__rt_chr_bad`, depois `__rt_die3`) | OK |
| 1870 | `utf8_chr(scalar)` de 1 a 0x10FFFF | CONFIRMADA | nf:37; core:85. Rejeita valores ≤0 e substitutos 0xD800–0xDFFF; um valor inválido escreve mensagem e faz `exit(3)` (syscall 60). | OK (60) |
| 1871 | `str(v)` | CONFIRMADA | nf:37; core:91 | OK |
| 1872 | `toint(s)` com sinal | CONFIRMADA | nf:37; core:91 (trata `-` inicial) | OK |
| 1873 | `lidx(coll,i)` = `coll[i]`, exit 3 fora da faixa | CONFIRMADA | nf:38; core:64 | OK |
| 1874 | `printval(v)` com quebra de linha | CONFIRMADA | nf:37; core:97 (`showval` seguido de `wch(10)`) | OK (1) |
| 1875 | `emit(s)` no buffer `.Lrt_emit_buf` | CONFIRMADA | nf:37; core:103 (`.Lrt_emit_buf`/`.Lrt_emit_len`) | OK (1) |
| 1876 | `flush()` | CONFIRMADA | nf:36 (aridade 0); core:103 | OK (1) |
| 1877 | `read()` lê uma linha | CONFIRMADA | nf:36; core:83 (buffer que dobra a partir de 256 bytes) | OK (0; o modo console remove `\r`) |
| 1878 | `readall()` | CONFIRMADA | nf:36; core:85 | OK (0) |
| 1879 | `io_read_byte()`: 0..255, ou -1 em EOF | CONFIRMADA | nf:36; core:83 (`.Lrt_iorb_eof` retorna -1) | OK (0) |
| 1880 | `ctfail(msg)`: aborta na compilação ou em runtime com exit 3 | CONFIRMADA | nf:37; core:112 (escreve em fd 2 e faz `exit(3)`; um `try` ativo captura). Em comptime, quem avalia é `ceval`. | OK |
| 1881 | `assert(cond)` "em comptime **ou runtime**" | **DIVERGENTE** | nf:33 (especial, sem aridade). Só existe o dobramento em comptime: ct:323 `cfoldassert`, que aceita `assert(cond)` ou `assert(cond, msg)`. Não há rebaixamento para runtime em `05_codegen`/`06b` nem rótulo `assert:` no runtime. | COMPILAÇÃO |

## 9.2 Builtins: bitwise, QF_BV e constant-time

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 1887 | `bit_and` (sinônimo `bv_and`) | CONFIRMADA | nf:18, nf:23, nf:38; cg:398 (`lbv2_op`) | OK (inline) |
| 1888 | `bit_or` (`bv_or`) | CONFIRMADA | idem | OK |
| 1889 | `bit_xor` (`bv_xor`) | CONFIRMADA | idem | OK |
| 1890 | `bit_not` | CONFIRMADA | nf:23, nf:37 | OK |
| 1891 | `bit_shl(a,k)`, k em 0..63; fora da faixa falha fechado com [C0012] | CONFIRMADA (com ressalva) | cg:411: um k **literal** fora de 0..63 gera [C0012] na compilação. Um k **calculado** faz `__rt_shc`, que encerra com exit 3 em runtime, sem o código C0012. | OK |
| 1892 | `bit_shr(a,k)` | CONFIRMADA (com ressalva) | cg:398: é **aritmético** (`sarq`), preserva o sinal; o catálogo não diz isso | OK |
| 1893 | `bv_u8` = `a & 0xFF` | CONFIRMADA | nf:19, nf:37; cg:398 | OK |
| 1894 | `bv_not_u8` | CONFIRMADA | nf:19 | OK |
| 1895 | `bv_add_u8` | CONFIRMADA | cg:398 (`addq; andq $255`) | OK |
| 1896 | `bv_sub_u8` | CONFIRMADA | cg:398 | OK |
| 1897 | `bv_mul_u8` | CONFIRMADA | cg:398 (`imulq; andq $255`) | OK |
| 1898 | `ct_select(mask,a,b)` = `wb ^ ((wa^wb)&wm)` | CONFIRMADA | nf:20–22; cg:623 `lctsel_o` (xor, and, xor, sem desvio) | OK |
| 1899 | `ct_eq(a,b)` retorna 1 ou 0 sem desvio | CONFIRMADA | nf:22, nf:38; cg (`lcteq_o`, `shrq $63; xorq $1`) | OK |
| 1883 | título "[C0011]" | CONFIRMADA | Na prática, [C0011] é o diagnóstico de kernels `@secret` + `@no_alloc` (cg `lct_fail`). | — |

## 9.2 Builtins: memória, arenas, GC e LZ1

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 1905 | `__lume_arena_new(cap_hint)` (`arena_new` em `use arena`) | CONFIRMADA | nf:28, nf:37; core:118; arena.src:52. Limite de 4 arenas vivas; `cap_hint ≤ 0` vale 1 MiB. | OK (9) |
| 1906 | `__lume_arena_alloc`, bump O(1) | CONFIRMADA | nf:38; core:118 | OK (10, 11) |
| 1907 | `__lume_arena_reset` | CONFIRMADA | nf:37; core:118 | OK |
| 1908 | `__lume_arena_destroy` devolve a memória ao SO | CONFIRMADA | nf:37; core:118 (munmap 11) | OK (11) |
| 1909 | `arena_freeze`: LZ1 por página de 4 KiB, devolve a RAM, aplica PROT_NONE e faz thaw sob demanda via SIGSEGV | CONFIRMADA | arena.src:65 é wrapper de `__lume_arena_freeze` (core:118, que chama `__rt_az_freeze`, core:68). Páginas zeradas são omitidas; uma página incompressível é guardada crua; segue madvise(DONTNEED) e mprotect. **Não é builtin do compilador**: exige `use arena`, porque `mem_pack`/`arena_freeze` não estão em `nf_rt` (nf:30). | OK (9, 10, 28; a falha chega por `__win_veh`, que leva a `__rt_on_segv`) |
| 1910 | `arena_thaw` | CONFIRMADA | arena.src:67; core:118 | OK |
| 1911 | `arena_compact`: "compacta blocos frios", respeitando [C0009] e [V0002] | **DIVERGENTE** | arena.src:66: `arena_compact(a) = __lume_arena_freeze(a)`, ou seja, é **alias exato de `arena_freeze`** e não faz compactação própria. As guardas são reais: [C0009] por `lis_pack_call` (p3:4268) e [V0002] por custo WCET de 100000 (p3:3128). | OK |
| 1912 | `__lume_arena_secret` bloqueia `LUME_ARENA_COLD` | CONFIRMADA | core:118: grava a flag em 40(%rdx); `__lume_arena_freeze` testa a flag e encerra com `.Lrt_ar_secret` (exit 12). `LUME_ARENA_COLD=` está em `__gc_k_cold`. Ressalva: um freeze explícito numa arena secreta também aborta. | OK |
| 1913 | `__lume_arena_frozen` | CONFIRMADA | nf:28; core:118 | OK |
| 1914 | `mem_pack`: cabeçalho de 20 bytes = `"LZ1\x1a"` + tamanho + checksum de 64 bits | CONFIRMADA | core:68: magic `439441996` = 0x1A315A4C = "LZ1\x1a" em little-endian, tamanho em +4 (8 bytes), `__rt_zsum` em +12 (8 bytes), dados em +20. Wrapper `use arena` (arena.src:63). Nota: o comentário em arena.src:60 diz "LZ4 block format", mas o magic é LZ1. | OK |
| 1915 | `mem_unpack` verifica limites e checksum; exit 3 se corrompido | CONFIRMADA | core:68: `__rt_upb` vai para `__rt_pack_msg` ("packed data is corrupt") e depois `__rt_die3`, que faz exit 3. Também limita o tamanho declarado a ≤ (n−20)·255+32 antes de alocar. | OK |
| 1916 | `__lume_gc_collect`: Mark & Lazy-Sweep + `madvise(MADV_DONTNEED)` | CONFIRMADA | nf:36; core:118; `__gc_flush` (core:43) faz madvise(4) | OK (28) |
| 1917 | `__lume_gc_count` | CONFIRMADA | nf:36; core:118 | OK |
| 1918 | `__lume_heap_stats` retorna `{used, cap, allocs}` | CONFIRMADA | nf:36; core:118; arena.src:16–20 | OK |
| 1919 | `__lume_heap_peak_used` | CONFIRMADA | nf:36; core:118 | OK |
| 1920 | `static_arena_addr`: 64 KiB em `.bss` | CONFIRMADA | nf:23, nf:36; cg:961 (`.Lrt_static_arena, 65536`). Também existe no modo hospedado. | OK (sem syscall) |
| 1921 | `static_arena_cap` = 65536 | CONFIRMADA | cg:961 | OK |
| 1922 | `mem_copy(dst,src,n)` | CONFIRMADA | nf:23, nf:39 (aridade 3); cg:961 (laço de bytes + `mfence`; retorna n) | OK (memória do processo) |
| 1923 | `mem_set(dst,byte,n)` | CONFIRMADA | nf:39; cg:961 | OK |
| 1924 | `mem_crc64(addr,n)`: "CRC-64" | **FALSA** | cg:961: é **FNV-1a de 64 bits** (base 1469598103934665603, primo 1099511628211) e o resultado é **mascarado para 31 bits** (`andq $2147483647`). Não é CRC. `mem_crc64` também não tem aridade em `nf_builtin_arity`, então não há checagem R0202. | OK |

## 9.2 Builtins: ownership, rc/arc/weak, async e sinais

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 1930 | `borrow(x)`, NLL [O0013] | CONFIRMADA | nf:32 (especial); [O0013] em `ownership`/p3 (`oa_loan_chk`) | COMPILAÇÃO |
| 1931 | `borrow_mut(x)` [O0011]/[O0013] | CONFIRMADA | nf:32; [O0011] é "conflicting borrow" | COMPILAÇÃO |
| 1932 | `move(x)` [O0001] | CONFIRMADA | nf:32; [O0001] é "use of moved value" | COMPILAÇÃO |
| 1933 | `clone(x)` | CONFIRMADA | nf:32; p3:3618: `clone`/`rc_clone` vira `__lume_rc_clone` | OK |
| 1934 | `rc_new(v)`: tag 7, contador 1 | CONFIRMADA | nf:32; p3:3618; cg:921 (`movq $7,(%rax); movq $1,8(%rax)`) | OK |
| 1935 | `rc_clone` | CONFIRMADA | cg:921 (`lock xadd` quando a tag é 9) | OK |
| 1936 | `rc_drop` | CONFIRMADA | cg:921 | OK |
| 1937 | `rc_get` | CONFIRMADA | p3:3618 (`get`, `rc_get`, `arc_get`, `promise_await`, `signal_get` e `block_on` viram todos `__lume_rc_get`) | OK |
| 1938 | `rc_strong_count` | CONFIRMADA | cg:921 | OK |
| 1939 | `arc_new`: tag 9 | CONFIRMADA | cg:921 (`movq $9`, `mfence`) | OK |
| 1940 | `weak_downgrade`: tag 11 | CONFIRMADA | cg:921 (`movq $11`) | OK |
| 1941 | `weak_upgrade(w)` retorna `Some(v)` ou `None` | **DIVERGENTE** | p3:3618: aridade **2**, `weak_upgrade(w, fallback)`, mapeada para `__lume_weak_upgrade`. cg:921: retorna o valor interno ou **o `fallback`**, não `Some`/`None`. | OK |
| 1942 | `promise_new()`: tag 13 | **DIVERGENTE** | p3:3618: aridade **1**, `promise_new(v)`. cg:921: tag 13 e a promise **já nasce resolvida** (8(%rax)=1, valor em +16). | OK |
| 1943 | `promise_resolve(p,v)` | CONFIRMADA | p3:3618 (aridade 2); cg:921 | OK |
| 1944 | `promise_await(p)` e `.await` [E0200] | CONFIRMADA | p3:3618 (vira `__lume_rc_get`); [E0200] "'.await' in synchronous function" em p3:487 (`kchk_fn_effs`) | OK |
| 1945 | `block_on(p)` "executa até a conclusão" | DIVERGENTE (leve) | p3:3618: `block_on` só lê o valor (`__lume_rc_get`); o efeito `async` é removido na inferência (`orem("async", ...)`). Não há escalonador: as promises são síncronas. | OK |
| 1946 | `signal_new(v)` | CONFIRMADA | p3:3618; cg:921. Nota: usa a **mesma tag 13** da promise, com versão inicial 0. | OK |
| 1947 | `signal_get(s)` | CONFIRMADA | p3:3618 (vira `__lume_rc_get`) | OK |
| 1948 | `signal_set(s,v)` incrementa a versão | CONFIRMADA | cg:921 (`lock xaddq` na versão) | OK |
| 1949 | `signal_version(s)` | CONFIRMADA | cg:921 | OK |
| 1950 | `shard(xs, body)` | DIVERGENTE (leve) | A forma principal é sintática: `shard v in lo..hi => body` ou `shard v in xs => body` (ps:52, `parseshard` em ps:46–47). A forma de chamada `shard(...)` também é aceita (nf:32, sem aridade). [E0200] proíbe efeitos no corpo. | COMPILAÇÃO (o paralelismo usa processos de trabalho; veja `os_fork`) |

## 9.2 Builtins: sistema de arquivos, processos, rede, epoll, io_uring e SIMD

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 1956 | `fs_read_file(path)` | CONFIRMADA | nf:29, nf:37; core:122 | OK (2, 3, 8, 73) |
| 1957 | `fs_write_sync(path,data)`: aceita NUL pelo tamanho explícito | CONFIRMADA | nf:38; core:122 (`__rt_sv0` dá o tamanho em rcx; open com `O_WRONLY\|O_CREAT\|O_TRUNC`=577, modo 0644) | OK (1, 2, 3) |
| 1958 | `fs_append_sync` | CONFIRMADA | nf:38; core:122 (com flock e fsync) | OK (1, 2, 3, 73, 74) |
| 1959 | `fs_write_hex_file(path,hex)` | CONFIRMADA | nf:38; core:122 | OK (1, 2, 3, 74) |
| 1960 | `fs_read_byte(path,off)`: -1 em EOF ou erro | CONFIRMADA | nf:38; core:122 (`.Lrt_frb_err`) | OK (2, 3, 8) |
| 1961 | `fs_path_exists` retorna 1 ou 0 | CONFIRMADA (com ressalva) | nf:37; core:122. Implementado como `open(O_RDONLY)`: um arquivo que existe mas não pode ser lido retorna 0. | OK (2, 3) |
| 1962 | `fs_read_dir(dir)`: entradas separadas por `\n` | CONFIRMADA | nf:37; core:120 (getdents64; buffer de 196608 bytes) | OK (217) |
| 1963 | `fs_mkdir` | CONFIRMADA | nf:37; core:122 (modo 0755) | OK (83) |
| 1964 | `fs_remove`: arquivo ou diretório vazio | CONFIRMADA | nf:37; core:122 (unlink 87, com rmdir 84 como alternativa) | OK (87, 84) |
| 1965 | `fs_copy(src,dst)` [novo] | CONFIRMADA | nf:29, nf:38; core:122 (buffer mmap de 64 KiB; preserva bytes, não permissões) | OK (1, 2, 3, 9, 11) |
| 1966 | `fs_rename(old,new)`: renomeação "atômica POSIX/Win32" [novo] | DIVERGENTE (leve) | nf:38; core:122 (rename 82). Atômica no Linux. No Windows, `.Lws_rename` (core:160) usa `MoveFileExW`, que substitui o destino mas não é garantidamente atômica. | OK (82) |
| 1967 | `fs_chmod(path,mode)` [novo] | CONFIRMADA | nf:38; core:122 (modo validado em 0..4095, chmod 90) | PARCIAL: `.Lws_chmod` (core:160) só mapeia o bit de escrita do dono (0200) para o atributo READONLY |
| 1968 | `fs_make_executable(path)` com 0755 [novo] | CONFIRMADA | nf:37; core:122 (`movq $493`, que é 0755) | OK (no Windows só confirma que o arquivo existe; a extensão decide se é executável) |
| 1969 | `fs_files_equal` | CONFIRMADA | nf:38; core:122 | OK (2, 3) |
| 1970 | `fs_current_dir()` via getcwd | CONFIRMADA | nf:36; core:120 (79). No Windows, o caminho sai no formato POSIX `/c/...`. | OK (79) |
| 1971 | `fs_chdir(dir)` [novo] | CONFIRMADA | nf:29, nf:37; core:122 (80) | OK (80) |
| 1972 | `os_arg_count()` | CONFIRMADA | nf:36; core:116 | OK |
| 1973 | `os_arg_at(i)` | CONFIRMADA | nf:37; core:116 | OK |
| 1974 | `os_getenv(name)` [novo] | CONFIRMADA | nf:29, nf:37; core:116 percorre `envp` depois de `argv` e retorna `""` se a variável não existir. **Agora tem implementação real**; antes só aparecia em tabelas de efeito (p3:227). | OK (`__win_start` monta o envp no layout do Linux) |
| 1975 | `os_platform()`: `"linux"`, `"windows"` "etc." | DIVERGENTE (leve) | nf:36; core:116 e core:135 (`.Lrt_platform: "linux"`). `lw_win64` (07_driver:392) troca a string por `"windows"`. **Só existem esses 2 valores**; não há "etc.". | OK |
| 1976 | `os_getpid()` | CONFIRMADA | nf:23, nf:36; cg:961 | OK (39) |
| 1977 | `os_fork()`: fork, "ou emulação Win64" | CONFIRMADA | nf:36; cg:961 (57) | PARCIAL: semântica de vfork. O filho roda primeiro, no mesmo espaço de endereços (docs/42 §7). |
| 1978 | `os_waitpid(pid)` | CONFIRMADA | nf:37; cg:961 (wait4 61; retorna o pid) | OK (61) |
| 1979 | `os_waitpid_status(pid)` retorna "código de saída exato" | **DIVERGENTE** | cg:961: retorna o **status bruto** do wait4 (`.Lrt_pbuf`), por exemplo exit 7 dá 1792, sem o equivalente de `WEXITSTATUS`. | OK (61) |
| 1980 | `os_kill(pid,sig)` | CONFIRMADA | nf:38; cg:961 (62) | PARCIAL: só filhos registrados; qualquer sinal diferente de 0 vira `TerminateProcess` (`.Lws_kill`, core:160) |
| 1981 | `os_run(cmd,args)` retorna o código de saída | **DIVERGENTE** | cg:961: devolve o status bruto do wait4 (o docs registra no item 52 que `exit 7` dá 1792) e não procura no PATH. `args` é uma lista de str, até 40 itens. | OK (57, 59, 60, 61) |
| 1982 | `os_exec(prog,args)` via execve | CONFIRMADA | nf:38; cg:961 (59) | OK (59, via `CreateProcessW`) |
| 1983 | `os_run_capture(prog,args,out,err)` | CONFIRMADA | nf:40 (aridade 4); cg:961 | OK (2, 33, 57, 59, 60, 61) |
| 1984 | `os_run_capture_timeout(...,ms)`: coleta o RSS do filho | CONFIRMADA | nf:40 (aridade 5); cg:961 (wait4 com rusage) | OK (2, 33, 35, 57, 59, 60, 61, 62, 228) |
| 1985 | `os_run_input_capture_timeout` (6 argumentos) | CONFIRMADA | nf:40 (aridade 6); cg:961 | OK (idem) |
| 1986 | `os_last_timed_out()` | CONFIRMADA | nf:36; cg:961 | OK |
| 1987 | `os_last_child_maxrss_kb()` | CONFIRMADA | nf:36; cg:961 | OK (no Windows é o pico real do working set; o WSL2 reporta 0) |
| 1988 | `os_self_maxrss_kb()` | CONFIRMADA | nf:36; cg:961 (getrusage 98) | OK (98) |
| 1989 | `os_monotonic_ns()` com `CLOCK_MONOTONIC`/QPC | CONFIRMADA | nf:36; cg:961 (228). A camada Windows importa `QueryPerformanceCounter`. | OK (228) |
| 1990 | `os_sleep_ms(ms)` | CONFIRMADA | nf:37; cg:961 (nanosleep 35) | OK (35) |
| 1991 | `os_exit(code)` | CONFIRMADA | nf:37; cg:961 (60) | OK (60) |
| 1992 | `os_pipe_new()` | CONFIRMADA | nf:36; cg:961 (pipe 22). Nota: retorna **um** inteiro codificado `rfd*10000 + wfd`. | OK (22) |
| 1993 | `os_pipe_write_int(fd,v)` | CONFIRMADA | nf:38; cg:961 (write de 8 bytes) | PARCIAL: com `os_fork` sem exec, um volume acima de 64 KiB trava (docs/42 §7) |
| 1994 | `os_pipe_read_int(fd)` | CONFIRMADA | nf:37; cg:961 (read de 8 bytes) | PARCIAL (idem) |
| 1995 | `os_shm_map(bytes)` com `MAP_SHARED\|MAP_ANONYMOUS` | CONFIRMADA | nf:37; cg:961 (flags 33) | **PENDENTE (semântica)**: `.Lws_mmap` exige `MAP_ANONYMOUS` e **ignora `MAP_SHARED`**, entregando memória privada via VirtualAlloc. Falta `CreateFileMapping`/`MapViewOfFile` (docs/42 §5, "to build"). |
| 1996 | `net_tcp_listen(port)` em `127.0.0.1:port` / `0.0.0.0:port` | **DIVERGENTE** | nf:37; cg:961: `__net_fill_sin` grava `16777343`, que é 127.0.0.1. **Só escuta em loopback** e nunca em 0.0.0.0. | **PENDENTE**: socket 41, setsockopt 54, bind 49, listen 50 |
| 1997 | `net_tcp_accept(fd)` | CONFIRMADA | nf:37; cg:961 | **PENDENTE**: accept 43 |
| 1998 | `net_tcp_connect(port)`, só local | CONFIRMADA | nf:37; cg:961 (127.0.0.1) | **PENDENTE**: 41, connect 42 |
| 1999 | `net_udp_bind(port)` | CONFIRMADA | nf:37; cg:961 | **PENDENTE**: 41, 54, 49 |
| 2000 | `net_udp_sendto(port,payload)` | CONFIRMADA (com ressalva) | nf:38; cg:961: o destino é sempre 127.0.0.1 e o payload é medido com `strlen`, então não é binary-safe | **PENDENTE**: 41, sendto 44 |
| 2001 | `net_send_str(fd,data)` | CONFIRMADA | nf:38; cg:961 (write 1) | **PENDENTE** (o fd só pode vir de um socket, que é a syscall 41) |
| 2002 | `net_recv_str(fd,max)` | CONFIRMADA | nf:38; cg:961 (read 0) | **PENDENTE** (idem, 41) |
| 2003 | `net_shutdown_write(fd)` | CONFIRMADA | nf:37; cg:961 | **PENDENTE**: shutdown 48 |
| 2004 | `net_close(fd)` | CONFIRMADA | nf:37; cg:961 (close 3) | OK na syscall, mas inútil sem sockets |
| 2005 | `epoll_create_fd()` | CONFIRMADA | nf:36; cg:961 (epoll_create1 291) | **PENDENTE**: 291 |
| 2006 | `epoll_add_in(epfd,fd,tag)` | CONFIRMADA | nf:39 (aridade 3); cg:961 (epoll_ctl 233) | **PENDENTE**: 233 |
| 2007 | `epoll_wait_one(epfd,ms)` | CONFIRMADA | nf:38; cg:961 (epoll_wait 232) | **PENDENTE**: 232 |
| 2008 | `os_io_uring_setup(entries,flags_ptr)` (425) | CONFIRMADA | nf:38 (aridade 2); cg:961 | **PENDENTE**: 425 |
| 2009 | `os_io_uring_enter(fd,n,min)` (426) | CONFIRMADA | nf:39 (aridade 3); cg:961 | **PENDENTE**: 426 |
| 2010 | `os_io_uring_register(fd,op,arg)` (427) | CONFIRMADA | nf:39; cg:961 | **PENDENTE**: 427 |
| 2011 | `simd_add4_i64(a,b)`: AVX2 VEX `vpaddq %ymm` / **AVX-512 EVEX**, "4 lanes em paralelo" | **DIVERGENTE** | cg:961: replica os **escalares** `a` e `b` em 4 lanes, executa `vpaddq %ymm1,%ymm0,%ymm0` e devolve só a lane 0, o que equivale a `a+b` com wrapping. O codegen **não emite EVEX/zmm** (0 ocorrências de `zmm`); EVEX existe só no codificador do `lasm`. | OK (exige CPU com AVX2) |
| 2012 | `simd_sub4_i64` (`vpsubq`) | CONFIRMADA (mesma ressalva de escalar replicado) | cg:961 | OK (AVX2) |
| 2013 | `simd_xor4_i64` (`vpxor`) | CONFIRMADA (mesma ressalva) | cg:961 | OK (AVX2) |

## 9.2 Builtins: bare-metal Ring-0

Todos estão em `lis_sys_call` (nf:23). As aridades estão em nf:36–38, exceto `vga_*` e `cpu_*` sem entrada em `nf_ar*`, que ficam sem checagem de aridade (R0202). A implementação está em cg:961.

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 2019 | `port_in8` (+ `port_in16` `inw`, `port_in32` `inl`) | CONFIRMADA | nf:23, nf:37; cg:961 (`inb %dx,%al`) | N/A (privilegiada; o VEH a trata como falha) |
| 2020 | `port_out8/16/32` | CONFIRMADA | nf:38; cg:961 (`outb`) | N/A |
| 2021 | `mmio_volatile_read8/16/32/64` [K0005] | CONFIRMADA | nf:23, nf:37; [K0005] protege a faixa 32768..262144 (p3) | OK em modo usuário sobre endereço válido (arena.src:36 usa `mmio_volatile_write64` no modo hospedado) |
| 2022 | `mmio_volatile_write8/16/32/64` | CONFIRMADA | nf:38; cg:961 (guarda de faixa) | OK (idem) |
| 2023 | `cpu_cli` | CONFIRMADA | nf:36; cg:961 | N/A |
| 2024 | `cpu_sti` | CONFIRMADA | idem | N/A |
| 2025 | `cpu_hlt` | CONFIRMADA | idem | N/A |
| 2026 | `cpu_pause` | CONFIRMADA | idem | OK (instrução de usuário) |
| 2027 | `cpu_mfence` | CONFIRMADA | idem | OK |
| 2028 | `cpu_rdtsc` | CONFIRMADA | idem | OK (permitida em modo usuário) |
| 2029 | `cpu_rdmsr` | CONFIRMADA | nf:37 | N/A |
| 2030 | `cpu_wrmsr` | CONFIRMADA | nf:38 | N/A |
| 2031 | `cpu_read_cr3` | CONFIRMADA | nf:36 | N/A |
| 2032 | `cpu_write_cr3` | CONFIRMADA | nf:37; cg:961 (`movq %rax,%cr3`) | N/A |
| 2033 | `cpu_invlpg` | CONFIRMADA | nf:37; cg:961 | N/A |
| 2034 | `cpu_idt_init` | CONFIRMADA | nf:36; cg:961 (descritores em 20704 e seguintes, com ISR 14 e 32) | N/A |
| 2035 | `cpu_trigger_irq32` | CONFIRMADA | nf:36 | N/A |
| 2036 | `cpu_irq32_count` | CONFIRMADA | nf:36 | N/A |
| 2037 | `cpu_pf14_count` | CONFIRMADA | nf:36 | N/A |
| 2038 | `cpu_pf14_addr` (CR2) | CONFIRMADA | nf:36 | N/A |
| 2039 | `cpu_wait_timer_irq` | CONFIRMADA | nf:36 | N/A |
| 2040 | `cpu_smp_boot_ap(apic_id)` com INIT-SIPI-SIPI | CONFIRMADA | nf:37; cg:961 (trampolim copiado para 0x7000, escrita no LAPIC 0xFEE00300) | N/A |
| 2041 | `cpu_run_2tasks(fn_ptr)` | CONFIRMADA | nf:37; cg:961 (`__krn_task_b`, pilha 499712) | N/A |
| 2042 | `vga_puts(row_col,text)` em 0xB8000 | CONFIRMADA | nf:23 (sem aridade); cg:961 (753664 = 0xB8000) | N/A |
| 2043 | `vga_fill_row` | CONFIRMADA | nf:23 | N/A |
| 2044 | `vga_scroll_up` | CONFIRMADA | nf:23 | N/A |
| 2045 | `vga_set_cursor` nas portas 0x3D4/0x3D5 | CONFIRMADA | cg:961 (980/981) | N/A |
| 2046 | `atomic_xadd64` (`lock xaddq`) | CONFIRMADA | nf:38 | OK (instrução de usuário sobre endereço válido) |
| 2047 | `spinlock_acquire` com *backoff* `pause` | CONFIRMADA (com ressalva) | cg:961: `xchgq` + `pause` em laço, sem backoff exponencial | OK (usuário) |
| 2048 | `spinlock_release` | CONFIRMADA | cg:961 (`mfence; movq $0`) | OK |
| 2049 | `krn_slot_write` | CONFIRMADA | nf:38 | N/A (endereço fixo do kernel) |
| 2050 | `krn_slot_read` | CONFIRMADA | nf:37 | N/A |
| 2051 | `hw_scratch_addr` (`.Lrt_hw_scratch`) | CONFIRMADA | nf:36; cg:961 | OK (também existe no modo hospedado) |
| 2052 | `cap_page_map(cap,vaddr,paddr,flags)` | CONFIRMADA (nome) | nf:32 (especial, consumido pelas passagens de kernel) | N/A |

## 9.2 Builtins: verificação, temporal, separação, decimais, tensores, queries e metaprogramação

| linha | item | veredito | evidência | Windows |
|---:|---|---|---|---|
| 2058 | `old(expr)` em `ensures` | CONFIRMADA | nf:32 e nf:103 (`nf_contract_word`) | COMPILAÇÃO |
| 2059 | `forall_range(v,lo,hi,pred)` | CONFIRMADA | nf:33; cg (`lquant`, aridade 4) | COMPILAÇÃO/OK |
| 2060 | `exists_range` | CONFIRMADA | idem | idem |
| 2061 | `always(init,step,inv)` [V0005] | CONFIRMADA | nf:33; [V0005] "temporal law ... (always) refuted" (p3) | COMPILAÇÃO |
| 2062 | `eventually`, `until`, `leads_to` | CONFIRMADA | nf:33 | COMPILAÇÃO |
| 2063 | `points_to`, `sep_conj`/`sep_disjoint`/`sep_dom`/`sep_valid`, `heap_new/read/write` | CONFIRMADA | nf:33 | COMPILAÇÃO |
| 2064 | `array_new`/`array_const`/`array_select`/`array_store` | CONFIRMADA | nf:33 | COMPILAÇÃO |
| 2065 | `verify`, [A0003], `law_check`, `evolve_approve` | CONFIRMADA | nf:32; [A0003] "unverified AI/probabilistic value" (p3) | COMPILAÇÃO |
| 2066 | `grad`, `jvp`, `vjp`, `vmap`, `value_and_grad`, `jit`, [N0400] | CONFIRMADA | nf:32; [N0400] "autodiff error" (p3) | COMPILAÇÃO |
| 2067 | `tensor_matmul` [T0300], `matmul`, `tensor_add/sub/mul/add_bias` | CONFIRMADA | nf:32; nf:320 (`nf_libmod` resolve para o módulo `tensor`) | OK (biblioteca Lume) |
| 2068 | `decimal(p,s,coef)`, `decimal_*`, `money_*` | CONFIRMADA (nomes) | nf:33; nf:320 (`decimal`, `table`). Aridade não verificada. Faltam no catálogo `dec_add`, `dec_sub`, `dec_eq`, `dec_lt`, `dec_le`, `dec_gt` e `dec_ge`. | OK (biblioteca) |
| 2069 | `query_where/order/join/group`, `comptime table_schema` [D0273] | CONFIRMADA | nf:33, nf:320; [D0273] "table_schema row type" (03/p3) | OK (biblioteca) |
| 2070 | `embed(rel_path)` com [C0271] contra path traversal | CONFIRMADA | nf:33; ct:290 (`c_has_dotdot` leva a [C0271]) | COMPILAÇÃO |
| 2071 | `quote(expr)`, `unquote`, `splice` | CONFIRMADA (com ressalva) | `quote` e `splice` são **palavras-chave** do parser (ct:186–187, `parsequote`/`parsesplice` aplicados a `prim`), não funções de name_flow. `unquote` está em nf:33. | COMPILAÇÃO |
| 2072 | `__lume_try_begin`: quadro de 16 níveis; `__lume_try_end`, `__lume_try_msg` | CONFIRMADA | nf:29, nf:36; core:112 (`cmpq $16, __rt_try_n`) | OK (1, 60) |

## Builtins reais que o catálogo omite

Fonte: `name_flow.src`. O conjunto foi comparado com todos os nomes entre crases das linhas 1842–2076.

- **Novos e ainda não catalogados** (estão na árvore de trabalho agora; nf:29, nf:37, nf:38, core:116):
  - `os_setenv(name, val)`, aridade 2, usa mmap 9.
  - `os_unsetenv(name)`, aridade 1.
  - Os dois têm efeito declarado (p3:227) e funcionam no Windows (OK).
- Aliases de tier e concorrência (nf:32): `rc`, `arc`, `arc_clone`, `arc_drop`, `arc_get`, `arc_strong_count`, `downgrade`, `upgrade`, `strong_count`, `drop`, `get`, `promise`, `resolve`, `signal`, `set`, `version`.
- Bit-vectors (nf:18, nf:33, nf:38): `bv_shl`, `bv_shr`, `bv_and_u8`, `bv_xor_u8`.
- MMIO de 16, 32 e 64 bits: aparecem só citados entre parênteses (linhas 2021–2022), não como entradas.
- Decimais: `dec_add`, `dec_sub`, `dec_eq`, `dec_lt`, `dec_le`, `dec_gt`, `dec_ge` (nf:33). Os `decimal_*` e `money_*` aparecem só entre parênteses (linha 2068).
- IA e probabilísticos (nf:32): `llm_complete`, `llm_prompt`, `prob_sample`, `sample_dist`, `observe_lik`.
- Outros especiais (nf:33): `table_schema` (só citado), `ctor`, `int`, `alloc_heap`, `wasm_call_host_fs`.
- Rotinas `__lume_*` públicas: `__lume_global_get` e `__lume_global_set` (aridades 1 e 2), `__lume_is_err` (aridade 1, inline em cg), `__lume_rec_update` (aridade 2), além de toda a família `__lume_rc_*`, `__lume_weak_*`, `__lume_promise_*`, `__lume_signal_*`, `__lume_mem_pack/unpack` e `__lume_arena_freeze/thaw`.
- Sintéticos (não chamáveis pelo usuário): `_call`, `_tylist_`, `_tyann_`, `_tyapp_*`, `__perceus_reuse_1/2`.
- Wrappers de `use arena` que o catálogo trata como builtins nativos, mas que não estão em `nf_rt`: `arena_new`, `arena_alloc`, `arena_reset`, `arena_destroy`, `arena_freeze`, `arena_thaw`, `arena_compact`, `arena_frozen`, `arena_mark_secret`, `mem_pack`, `mem_unpack`, `gc_collect`, `gc_count`, `heap_stats`, `heap_peak_used`, `peak_rss_kb` e `child_peak_rss_kb` (arena.src:52–74). Os dois últimos não aparecem no catálogo.

## Afirmações falsas ou divergentes (resumo)

1. **FALSA**, linha 1924: `mem_crc64` não é CRC-64. É FNV-1a de 64 bits mascarado para 31 bits (cg:961).
2. **DIVERGENTE**, linha 1867: `ord("")` retorna 0, não -1.
3. **DIVERGENTE**, linha 1881: `assert` existe só em comptime (ct:323); não há asserção em runtime.
4. **DIVERGENTE**, linha 1911: `arena_compact` é alias exato de `arena_freeze` (arena.src:66).
5. **DIVERGENTE**, linha 1941: a assinatura real é `weak_upgrade(w, fallback)`, que retorna o valor ou o fallback, não `Some`/`None`.
6. **DIVERGENTE**, linha 1942: a assinatura real é `promise_new(v)`, com aridade 1, e a promise já nasce resolvida.
7. **DIVERGENTE**, linha 1945: `block_on` só desembrulha o valor; não há executor assíncrono.
8. **DIVERGENTE**, linha 1950: `shard` é sobretudo sintaxe `shard v in ... => body`.
9. **DIVERGENTE**, linhas 1979 e 1981: `os_waitpid_status` e `os_run` retornam o status bruto do wait4 (exit 7 dá 1792), não o código de saída.
10. **DIVERGENTE**, linha 1996: `net_tcp_listen` só escuta em 127.0.0.1, nunca em 0.0.0.0.
11. **DIVERGENTE**, linha 2011: `simd_*` replica escalares e devolve 1 lane; não há EVEX/AVX-512 no codegen.
12. **DIVERGENTE leve**:
    - linha 1975: `os_platform` só retorna "linux" ou "windows";
    - linha 1966: `fs_rename` no Win32 não é garantidamente atômico;
    - linha 1844: o nível 8 de precedência está em `01_lexer.src`;
    - linha 1891: um k calculado dá exit 3, sem [C0012];
    - linha 1892: `bit_shr` é aritmético.

## Builtins PENDENTES no Windows (syscall que falta)

| builtin | syscall(s) que faltam na `__win_syscall` |
|---|---|
| `net_tcp_listen` | socket 41, setsockopt 54, bind 49, listen 50 |
| `net_tcp_accept` | accept 43 |
| `net_tcp_connect` | socket 41, connect 42 |
| `net_udp_bind` | socket 41, setsockopt 54, bind 49 |
| `net_udp_sendto` | socket 41, sendto 44 |
| `net_shutdown_write` | shutdown 48 |
| `net_send_str` / `net_recv_str` | write/read existem, mas o fd só pode vir de socket 41 |
| `epoll_create_fd` | epoll_create1 291 |
| `epoll_add_in` | epoll_ctl 233 |
| `epoll_wait_one` | epoll_wait 232 |
| `os_io_uring_setup` | io_uring_setup 425 |
| `os_io_uring_enter` | io_uring_enter 426 |
| `os_io_uring_register` | io_uring_register 427 |
| `os_shm_map` | não falta syscall (mmap 9 existe), mas `MAP_SHARED` é ignorado e a memória sai privada. Falta seção compartilhada (`CreateFileMapping`/`MapViewOfFile`). |

PARCIAIS no Windows, com syscall presente e semântica reduzida:

- `os_fork` (vfork: o filho roda antes, no mesmo espaço de endereços);
- `os_pipe_write_int` e `os_pipe_read_int` (com fork sem exec, travam acima de 64 KiB);
- `os_kill` (só filhos, via TerminateProcess);
- `fs_chmod` (só o bit de escrita vira READONLY);
- o paralelismo de `shard` com processos de trabalho, que herda os limites de `os_fork`.

N/A no Windows (instrução privilegiada ou endereço físico fixo):

- `port_in*`, `port_out*`;
- `cpu_cli`, `cpu_sti`, `cpu_hlt`, `cpu_rdmsr`, `cpu_wrmsr`, `cpu_read_cr3`, `cpu_write_cr3`, `cpu_invlpg`, `cpu_idt_init`, `cpu_trigger_irq32`, `cpu_irq32_count`, `cpu_pf14_count`, `cpu_pf14_addr`, `cpu_wait_timer_irq`, `cpu_smp_boot_ap`, `cpu_run_2tasks`;
- `vga_*`, `krn_slot_*`, `cap_page_map`.

Todos os demais builtins do trecho (strings, I/O, fs_*, os_* de processo e tempo, arenas, GC, LZ1, rc/arc/weak/promise/signal, try, SIMD com AVX2, atômicos de usuário) usam apenas as syscalls 0, 1, 2, 3, 8, 9, 10, 11, 22, 28, 33, 35, 39, 57, 59, 60, 61, 62, 73, 74, 79, 80, 82, 83, 84, 87, 90, 98, 217 e 228, e todas existem na camada: **Windows OK**.

## Contagens

São 195 linhas julgadas nas tabelas. Cada uma corresponde a uma afirmação do catálogo; os itens que agrupam variantes (por exemplo, `port_in8/16/32`) contam como 1.

- CONFIRMADA: 179, das quais 8 com ressalva;
- DIVERGENTE: 14, das quais 5 leves;
- FALSA: 1 (`mem_crc64`);
- NÃO VERIFICÁVEL: 1 ("O(1) de pilha").

Coluna Windows (linhas da tabela):
- 14 PENDENTES: 13 por syscall faltando (rede, epoll, io_uring) e `os_shm_map` por semântica;
- 5 PARCIAIS: `os_fork`, `os_pipe_write_int`, `os_pipe_read_int`, `os_kill` e `fs_chmod`, além do `shard` multiprocesso;
- 25 N/A (bare-metal);
- o restante é OK ou COMPILAÇÃO.

Ressalva de método: todas as conclusões são estáticas. Nenhum programa foi compilado nem executado nesta auditoria. A árvore de trabalho estava mudando durante a leitura (`os_setenv`/`os_unsetenv` apareceram em nf:29/37/38 enquanto a auditoria corria).
