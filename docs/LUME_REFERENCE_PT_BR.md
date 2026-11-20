# Referencia da Lume (factual) — v1.2.0

Esta e a referencia do que funciona hoje. Ela nao tem roteiro nem material de visao: isso esta em
`lume manual --pt visao` e nos outros capitulos, que misturam os dois. Cada exemplo abaixo e executado por
`tests/docs/ref_examples_gate.src` (na bateria de testes) com a toolchain instalada; o bloco embaixo de cada exemplo
e a saida exata dele.

Estados: **estavel** = Linux x86-64 e Windows x64, mesmo comportamento; **linux** / **windows** = so naquela
plataforma; **experimental** = funciona, a API ainda pode mudar; **privilegiado** = precisa de root (Linux) ou de
processo elevado (Windows).

## 1. Programas e comandos

Um programa e um arquivo `.src`. As linhas `print` de topo rodam em ordem. `lume run f.src [args]` compila e roda,
`lume build f.src -o saida` grava um executavel nativo (`saida.exe` no Windows), `lume test f.src` roda cada
`fn test_*()` que devolve um valor verdade, `lume check f.src` checa os tipos sem rodar, `lume fmt f.src` formata
no lugar (`--check`, `--stdout`), `lume manual [capitulo]` mostra o manual (`--pt` em portugues). `lume run --profile f.src` mostra por funcao o
tempo proprio e total, chamadas e alocacoes, e o tempo do GC, no stderr ao terminar (funcoes expandidas no chamador
contam nele; `LUME_FL=off` as mantem; um laco de cauda e uma chamada).

`lume verify [--jobs=N] a.src b.src ...` roda check, test, prove, fmt --check e certify em muitos arquivos com N processos
(padrao 2); o resultado de cada arquivo fica em cache pelo SHA-256 do pacote inteiro e das ferramentas, entao depois de
uma mudanca so o modulo alterado e os arquivos que o importam rodam de novo.

Pacotes: `lume pkg publish [dir] --store=DIR` roda os testes do pacote e guarda NOME/VERSAO imutavel com o SHA-256;
`lume pkg add NOME@REQ` grava `nome = "REQ"` em `[dependencies]` (REQ: `1.2.3`, `^1.2`, `~1.2.3`, `*`);
`lume pkg install --store=DIR` instala as maiores versoes compativeis em `lume_modules/`, roda os testes delas e grava
versoes e hashes no `lume.lock`; `use NOME` encontra um pacote instalado.

Exemplos oficiais: `examples/topics/*.src` (um arquivo por assunto, cada um rodado por `lume test`) e
`examples/diagnostics/` (para um codigo de diagnostico, `CODIGO_nome.bad` o mostra e `CODIGO_nome.fixed.src` e o
programa corrigido); `tests/docs/examples_gate.src` roda todos a cada versao.

```lume
fn square(x) = x * x
print square(7)
```
```output
49
```

## 2. Sintaxe

- `fn nome(a, b) = expr`, `pub fn` (exportada), `priv fn` (privada do modulo), `const NOME: T = expr`,
  `type T = A(x) | B(x, y)`, `use modulo`, `use modulo as apelido`, `use std/NOME` (sempre o NOME da biblioteca padrao, mesmo que o projeto tenha um NOME.src), `## comentario` (ate o fim da linha).
- Expressoes: `let x = e in corpo`, `if c then a else b`, `match v` com um `Padrao => expr` por linha,
  `fn(x) => expr` (closure; captura variaveis), `{a: 1, b: 2}` (registro), `r.a` (campo), `{ r with a: 3 }`
  (copia com um campo trocado), `[1, 2, 3]` (lista), `Cons(h, t)` / `Nil`.
- Inteiros tem 64 bits; um overflow para o programa (exit 3). `/` trunca em direcao a zero, `%` tem o sinal do
  operando da esquerda. `*` `/` `%` ligam mais forte que `+` `-`. Comparacoes e `and` / `or` / `not` dao
  booleanos, impressos como `1` / `0`.
- Strings sao bytes (UTF-8): `count` conta bytes, `+` junta duas strings e nada converte sozinho (`str(x)` faz uma
  string, `toint(s)` le um numero).

```lume
type Shape = Circle(r) | Rect(w, h)
fn area(s) = match s
    Circle(r)  => 3 * r * r
    Rect(w, h) => w * h
print area(Circle(2))
print area(Rect(3, 4))
let p = {x: 1, y: 2}
print p.x + p.y
let q = { p with y: 10 }
print q.y
print 7 / 2
print 0 - 7 / 2
print 7 % 3
```
```output
12
12
3
10
3
-3
1
```

## 3. Erros em tempo de execucao

O programa para com exit 3 e uma linha no stderr em: overflow de inteiro, divisao por zero, indice fora de uma
lista ou buffer, campo que o registro nao tem, valor do tipo errado para a operacao, `match` sem braco. O
`lume test` mostra essa parada como teste que falhou e segue com os outros. Depois da mensagem vem as chamadas
que levaram ate ali, da mais interna para fora, uma linha `  at NOME (arquivo.src:LINHA)` cada (uma funcao expandida
no chamador e uma chamada de cauda nao deixam linha; `LUME_FL=off` mantem as funcoes pequenas como chamadas).

```lume
print 9223372036854775807 + 1
```
```output
exit 3
stderr: lume: integer overflow
```

## 4. Builtins basicos (estavel)

| Builtin | Resposta | Com argumento errado |
| --- | --- | --- |
| `count(s)` | bytes de uma string, ou elementos de uma lista | para num valor sem tamanho |
| `at(s, i)` | o byte em i como string de um byte | `""` quando i esta fora |
| `slice(s, a, b)` | bytes a..b-1, limitados a string | — |
| `ord_at(s, i)` | o byte em i como int (0..255) | para quando i esta fora |
| `chr(n)` | a string de um byte n (0..255) | para fora de 0..255 |
| `str(v)` | o texto de um valor | — |
| `toint(s)` | o inteiro escrito em s | `0` quando s nao e inteiro (confira o texto antes) |
| `print v` / `emit(s)` / `flush()` | escrevem no stdout | — |

```lume
print count("héllo")
print slice("abcdef", 1, 4)
print ord_at("A", 0)
print chr(66)
print str(42) + "!"
print toint("123") + 1
print bit_and(12, 10)
print bit_shl(1, 4)
print at("ab", 5) == ""
print toint("abc")
print slice("abc", 2, 9)
print count([1, 2, 3])
```
```output
6
bcd
65
B
42!
124
8
16
1
0
c
3
```

## 5. Buffers de bytes (estavel)

`buf_new(n)` (n bytes zerados), `buf_len(b)`, `buf_get(b, i)` (0..255), `buf_set(b, i, v)` (devolve b),
`buf_copy(dst, d_off, src, s_off, n)`, `buf_slice(b, off, n)`, `buf_from_str(s)`, `buf_to_str(b, off, n)`,
`buf_addr(b)` (endereco do byte 0, para chamadas de sistema). Indice fora do buffer ou valor fora de 0..255 para o
programa.

```lume
let b = buf_new(4)
let s = buf_set(b, 0, 255)
print buf_len(b)
print buf_get(b, 0)
print buf_get(b, 1)
```
```output
4
255
0
```

Video e codec (estavel; os argumentos sao buffers, deslocamentos em bytes e strides; cada um devolve -1 com
argumento errado): `buf_bgra_to_i420`, `buf_i420_to_bgra`, `buf_sad16x16 / 8x8 / 4x4 (a, ai, sa, b, bi, sb)` e
`buf_satd4x4 / 16x16 (iguais)` (SSE2), `buf_h264_fdct4x4 / idct4x4 (src, si, dst, di)` (blocos int16),
`buf_h264_quant4x4 (src, si, qp, intra, dst, di)` (devolve os niveis nao nulos), `buf_h264_dequant4x4 (src, si, qp,
dst, di)`, `buf_h264_sub4x4 (a, ai, sa, pred, pi, dst)`, `buf_h264_recon4x4 (pred, pi, res, ri, dst, di)`,
`buf_h264_intra4x4 / intra16x16 (frame, fi, fs, modo, disponivel, dst)` (bits de disponivel: 1 esquerda, 2 topo,
4 topo-direita, 8 topo-esquerda). Com `use h264`: `buf_h264_cavlc4x4 (coef, ci, nc, maxc, out, pos)` codifica
um bloco de maxc (16, 15 ou 4) coeficientes int16 em ordem zigzag com CAVLC (nC -1: DC de croma) em out a partir do
bit pos e devolve {pos, total} (a nova posicao de bit, -1 com argumento errado ou buffer cheio, e o TotalCoeff).

Escrita de bits (estavel; bit mais significativo primeiro): `buf_bits_write(b, pos, v, n)` grava os n bits baixos de
v (1..32) no bit pos e devolve pos + n, `buf_bits_read(b, pos, n)` os le, `buf_bits_ue(b, pos, v)` / `buf_bits_se(b,
pos, v)` gravam codigos Exp-Golomb e devolvem a nova pos; cada um devolve -1 com argumento errado.

## 5a. Ponto flutuante (estavel)

`f64` e um double IEEE 754: `f64(x)` cria um a partir de inteiro, decimal, outro f64 ou texto (`f64("1e-9")`,
`f64("inf")`, `f64("nan")`); `+ - * /` e `< > <= >=` funcionam sobre ele (um operando inteiro ou decimal e
convertido), `==` compara por valor. `print` / `str` dao o texto mais curto que volta ao mesmo double. Funcoes:
`f64_sqrt`, `f64_abs`, `f64_floor`, `f64_ceil`, `f64_round` (meio para longe de zero), `f64_int` (em direcao a zero,
para int), `f64_sin`, `f64_cos`, `f64_tan`, `f64_atan2(y, x)`, `f64_exp`, `f64_log`, `f64_log10`, `f64_pow(x, y)`,
`f64_is_nan`, `f64_str(x, casas)`, `f64_bits` / `f64_from_bits`. Um literal com ponto (`1.5`) e um decimal exato, nao
f64: escreva `f64(1.5)` ou `f64("1.5")`. Comparar com NaN para o programa (teste com `f64_is_nan`). Um parametro declarado `x: f64` converte o que recebe com `f64(x)` na entrada, entao um literal
decimal funciona ali: `fn hyp(a: f64, b: f64) -> f64 = sqrt(a * a + b * b)` e `hyp(3.0, 4.0)`. `use math` da `sqrt exp
log log10 pow sin cos tan atan2 floor ceil round abs_f fmin fmax tofloat is_nan is_inf`, `f32(x)` (precisao simples
mais proxima, empate para o par) e `buf_f32_get(b, off)` / `buf_f32_set(b, off, x)` (4 bytes, little endian). O
`lume check` avisa [W0004] onde um int encontra um f64 (convertido em execucao); o `lume prove` marca um contrato
com f64 como `runtime_checked` com o motivo (o provador de inteiros nao decide ponto flutuante).

```lume
fn hypot(a, b) = f64_sqrt(a * a + b * b)
print hypot(f64(3), f64(4))
print hypot(f64(3), f64(4)) == f64(5)
print f64(1) / f64(3)
print f64_str(f64("2.5"), 2)
print f64_is_nan(f64("nan"))
print f64_int(f64_floor(f64("-2.5")))
print f64_pow(f64(2), f64(10))
```
```output
5.0
1
0.3333333333333333
2.50
1
-3
1024.0
```

## 6. Arquivos e sistema operacional (estavel)

| Builtin | Resposta |
| --- | --- |
| `fs_read_file(p)` | o conteudo, `""` quando nao da para ler |
| `fs_write_sync(p, s)` / `fs_append_sync(p, s)` | 1, ou 0 na falha |
| `fs_path_exists(p)` / `fs_remove(p)` / `fs_mkdir(p)` / `fs_copy(a, b)` | 1, ou 0 |
| `os_getenv(nome)` | o valor, `""` quando nao existe |
| `os_platform()` | `"linux"` ou `"windows"` |
| `os_arg_count()` / `os_arg_at(i)` | os argumentos do programa |
| `os_monotonic_ns()` | relogio monotonico em nanossegundos |
| `os_exit(codigo)` | encerra o programa |

```lume
print fs_write_sync("ref_probe.txt", "hi")
print fs_read_file("ref_probe.txt")
print fs_remove("ref_probe.txt")
print fs_path_exists("ref_probe.txt")
print fs_read_file("no_such_file.txt") == ""
print os_getenv("LUME_SURELY_UNSET_VAR") == ""
```
```output
1
hi
1
0
1
1
```

Rede (estavel): `net_udp_bind_addr(ip, porta)` (socket, -1 na falha), `net_udp_send_to(fd, ip, porta, dados)`
(bytes enviados), `net_udp_recv_from(fd, max)` (o datagrama, `""` sem nada), `net_last_peer_ip()`,
`net_last_peer_port()`, `net_tcp_connect_addr(ip, porta)` (socket, -1 quando recusado), `net_close(fd)`;
`use netctl` acrescenta timeouts e E/S nao bloqueante com epoll.

## 7. Modulos da biblioteca padrao

| Modulo | O que oferece | Estado |
| --- | --- | --- |
| `h264` | `buf_h264_luma_mc(ref, ri, rs, rw, rh, x, y, mx, my, w, h, dst, di, ds)` (luma em 1/4 de amostra, 6 taps, 8.4.2.2.1), `buf_h264_chroma_mc(...)` (mesmos argumentos, croma bilinear em 1/8, 8.4.2.2.2), `buf_h264_deblock_edge(buf, q0, across, along, lines, bs, alpha, beta, tc0, chroma)` (8.7.2.3 / 8.7.2.4; bs e tc0 sao listas, um valor por 4 linhas de luma / 2 de croma); 0, ou -1 com argumento errado; coordenadas presas a figura | estavel |
| `hash` | `crc32`, `adler32`, `md5`, `sha1`, `sha256` (strings; `*_buf` para buffers), `hex32` | estavel |
| `csv` | `csv_parse(texto)` (RFC 4180: aspas, separadores e quebras de linha dentro de campos), `csv_format(linhas)`, `csv_parse_sep` / `csv_format_sep`, `csv_field` | estavel |
| `utf8` | `utf8_len`, `utf8_decode` / `utf8_encode`, `utf8_char`, `utf8_cp`, `utf8_slice`, `utf8_upper` / `utf8_lower` (ASCII + Latin-1), `utf8_reverse`, `utf8_valid` (strings sao bytes; estas contam caracteres) | estavel |
| `datetime` | `dt_from_unix`, `dt_to_unix`, `dt_iso`, `dt_parse_iso`, `dt_weekday`, `dt_add_days` / `dt_add_months`, `dt_offset(fuso, t)` / `dt_local` / `dt_iso_local` (deslocamentos fixos, horario de verao EUA / UE / Sydney) | estavel |
| `regex` | `re_match`, `re_search`, `re_find`, `re_find_all`, `re_groups`, `re_replace` (`$1`), `re_split`: classes, `\d \w \s`, ancoras, grupos, alternancia, quantificadores gulosos e preguicosos | estavel |
| `deflate` | `inflate_buf` / `deflate_buf`, `zlib_decompress` / `zlib_compress`, `gunzip` / `gzip`, `gunzip_str` / `gzip_str` (Adler-32 / CRC-32 conferidos) | estavel |
| `http` | `http_get`, `http_post`, `http_request(metodo, url, cabecalhos, corpo, ms)`, `http_header`: chunked, gzip, redirecionamentos, prazos; `https://` pelo `tls` | estavel |
| `tls` | `tls_request(host, porta, dados, ms)`: cliente TLS 1.3 (X25519, AES-128-GCM / ChaCha20-Poly1305); o certificado do servidor e conferido contra as raizes do sistema (`SSL_CERT_FILE`, o pacote do Linux, os repositorios do Windows pelo `lchameleon`) e o nome do host | estavel |
| `tlspki`, `bignum` | RSA (PKCS #1 v1.5, PSS), ECDSA P-256 / P-384, SHA-384 / SHA-512, parse X.509 e validacao de cadeia, PEM; inteiros de qualquer tamanho com `bn_modexp` de Montgomery | estavel |
| `seq` | `seq_map`, `seq_filter`, `seq_fold`, `seq_loop(a, b, acc, f)` (laco sobre a..b-1 sem lista), `seq_while`, `seq_nth`, `seq_range`, `seq_concat` | estavel |
| `arena` | `heap_stats()`, `gc_collect()`, `gc_count()`, `arena_new / alloc / reset / destroy` | estavel |
| `netctl`, `dns` | TCP com timeout, sockets nao bloqueantes, epoll, DNS | estavel |
| `tun` | interfaces TUN: `tun_open`, `tun_read`, `tun_write`, `tun_wait`, `tun_set_ipv4`, `tun_set_mtu`, `tun_set_up`, `tun_close` | linux + windows, privilegiado; no Windows o Wintun so entra pelo `lchameleon` |
| `lchameleon` | fronteiras externas: `chameleon_c_open(caminho)` (Windows: DLL assinada dentro de System32 / Program Files), `chameleon_c_sym`, `chameleon_c_call` (devolvem `unverified[int]`), `chameleon_verify_boundary` | `chameleon_c_*`: windows; guardas: estavel |
| `winsys` | monitores, captura, entrada, janelas, registro, servicos, sessoes, named pipes | windows |
| `lcrypto_tls` | AES-GCM, ECDSA P-256, X25519, Ed25519, SHA-256 | estavel |

```lume
use seq
print seq_loop(0, 5, 0, fn(i, acc) => acc + i)
print seq_map([1, 2, 3], fn(x) => x * 10)
print seq_fold([1, 2, 3], 0, fn(acc, x) => acc + x)
```
```output
10
Cons(10, Cons(20, Cons(30, Nil)))
6
```

## 8. Contratos

`requires` / `ensures` depois dos parametros; `lume prove` prova o que consegue, o resto e conferido em tempo de
execucao (a violacao para o programa, exit 3). `result` e o valor devolvido, `old(x)` o valor na entrada.

```lume
fn half(x) requires x >= 0 ensures result >= 0 = x / 2
print half(10)
```
```output
5
```

Contratos dos builtins: o provador sabe o que alguns builtins devolvem, quando o resultado da chamada tem nome num
`let` ou e o resultado da funcao: `buf_bits_write(b, p, v, n)` e `p + n` ou `-1`; `buf_get(b, i)` e 0..255 (um
indice fora do buffer para o programa); `buf_len(b)` e `count(s)` sao >= 0; `buf_sad*` / `buf_satd*` sao >= -1;
`buf_h264_quant4x4` e -1..16. Uma clausula que o provador prova nao pode ela mesma parar o programa: `p + n` pode
estourar, entao limite p e n no `requires`.

```lume
fn put3(b: buf, p: int, v: int) -> int
    requires p >= 0 and p <= 1000000000
    ensures result == p + 3 or result == 0 - 1
    = buf_bits_write(b, p, v, 3)
print put3(buf_new(4), 0, 5)
```
```output
3
```

## 9. Convencoes e nomes reservados

Palavras-chave: `if then else elif let in var mut match not and or own with spawn do defer errdefer comptime
quote splice scope shard fn pub priv use as type const law print requires ensures true false`. Nome com inicial
maiuscula e construtor. Builtins do runtime e os prefixos `__rt_` / `__lume_` nao podem nomear funcao ([R0201]).
`ct_` no inicio do nome de uma funcao torna os parametros segredos ([C0009] num desvio sobre eles); parametros
`secret` / `secret_*` sao segredos em qualquer funcao. Funcoes `test_*` sao as que o `lume test` roda. Um
comentario `## Deprecated: <mensagem>` logo acima de uma funcao a marca: uma chamada de outro modulo avisa [W0005]
com a mensagem, e ela continua funcionando por pelo menos uma versao MINOR inteira (versoes, obsolescencia e a linha
de suporte longo: `docs/STABILITY.md`). `grad`,
`value_and_grad`, `jvp`, `vjp` sao operadores de autodiff. Um nome definido em dois modulos da o aviso [W0003].

## 10. Limites conhecidos

- O runtime tem uma thread so.
- No maximo 6 parametros no codigo `--raw` do runtime; funcoes comuns aceitam qualquer numero.
- Listas e registros literais constantes (tambem os aninhados) sao dados estaticos compartilhados: nunca sao alterados (valores Lume sao
  imutaveis).
- O achatamento de registros inlineia funcoes pequenas; `LUME_FL=off` desliga (para medir alocacao ou ler o
  formato das chamadas no assembly).
- Os alvos macOS cobrem so o nucleo verificado (write / exit); `winsys` existe so no Windows.

## 11. Mudou nesta versao

Entrou: `use std/hash`, `csv`, `utf8`, `datetime`, `regex`, `deflate`, `http`, `tls` (HTTPS com TLS 1.3), `tlspki`, `bignum`, versoes de pacotes (`lume pkg publish / add / install`, `[packages]` no lume.lock), `lume verify` (muitos arquivos, N processos, cache por arquivo), a pilha de chamadas (`at NOME (arquivo:LINHA)`) depois de um erro em tempo de execucao, contratos dos builtins no provador (`buf_bits_write`, `buf_get`, `buf_len`, `count`, `buf_sad*`, `buf_satd*`, `buf_h264_quant4x4`), exemplos oficiais (`examples/topics`, `examples/diagnostics`, gate dos exemplos), `use std/NOME`, `buf_bits_write / read / ue / se`, `## Deprecated:` e o aviso [W0005], docs/STABILITY.md (semver, obsolescencia, LTS 1.2), `use math` (funcoes matematicas, f32, buffers f32), parametros f64, W0004, `lume run --profile`, `use h264` (compensacao de movimento, desbloqueio), `buf_sad*`, `buf_satd*` (SSE2), `buf_h264_*`, `use tun`, `lchameleon` `chameleon_c_open / sym / call` e
`chameleon_verify_boundary`, `priv fn`, aviso [W0003], `LUME_FL`, literais constantes em .rodata, cache de campo por
ponto de leitura, ritmo de coleta `max(8 MiB, 3 x vivo)`.
Mudou: o W0004 tambem ve parametros `f64` e resultados de `f64(...)`; `buf_sad4x4` roda em SSE2; o C0009 numa funcao `ct_` diz que o motivo e o prefixo; `lume fmt` se recusa a rodar no Stage-0; no Git
Bash o `lume` roda o `lume.exe` nativo; `fs_copy` mantem as permissoes da origem.
Saiu: nada.
