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
contam nele; `LUME_FL=off` as mantem; um laco de cauda e uma chamada). `lume debug [--commands ARQ] [-x CMD]... f.src`
roda no depurador: pontos de parada numa funcao ou ARQUIVO:LINHA, `step` / `next` / `finish` / `continue` de chamada
em chamada, `bt` com os argumentos de cada quadro, `args`, `locals`, `print NOME`, `frame N`, `up`, `down`, `mark`
(fecha uma resposta), `output ARQ` (escreve em ARQ, anexando), e parada
num erro em tempo de execucao; comandos de texto, saida no stderr (uma IA o conduz com `-x`). `lume debug --dap`
serve o mesmo depurador pelo Debug Adapter Protocol no stdin / stdout (Content-Length ou um JSON por linha): launch,
pontos de parada por linha ou funcao, stackTrace, scopes, variables, evaluate, continue, next, stepIn, stepOut; eventos
stopped (breakpoint, step, exception num erro em tempo de execucao), output, exited, terminated.

`lume verify [--jobs=N] a.src b.src ...` roda check, test, prove, a checagem de formato e certify em muitos arquivos com N processos
(padrao 2); o resultado de cada arquivo fica em cache pelo SHA-256 do pacote inteiro e das ferramentas, entao depois de
uma mudanca so o modulo alterado e os arquivos que o importam rodam de novo. Cada linha mostra o tempo de cada etapa
(`ok   a.src  (check 0.030 s, test 0.124 s, prove 0.014 s, fmt 0.017 s, certify 0.027 s)`), entao uma etapa lenta
aparece; um arquivo sem contratos nao tem o que certificar e passa nessa etapa.

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

## 3a. Codigos de diagnostico

Todo diagnostico traz um codigo entre colchetes (`[T0604]`) ou, em JSON (`lume agent check`), o campo `"code"`.
"compilador" = `lume build / run / test / check`; "analisador" = `lume check` e `lume agent check`. Um codigo com
exemplo tem em `examples/diagnostics/` o programa que o produz (`.bad`) e o corrigido (`.fixed.src`), conferidos
pelo gate dos exemplos a cada versao.

| Codigo | Significado | Quem informa | Exemplo |
|---|---|---|---|
| `A0001` | buraco tipado `_` nao preenchido em `pub fn`; a correcao propoe um candidato | analisador | `A0001_typed_hole` |
| `A0002` | `total fn` cuja recursao nao se prova decrescente | analisador | `A0002_not_terminating` |
| `A0003` | valor de `llm fn` chega sem verificacao ao resultado de `pub fn` ou a um destino confiavel | analisador | `A0003_unverified_ai_value` |
| `A0004` | patch semantico de AST com funcao inexistente ou expressao malformada | lume agent patch | - |
| `C0001` | interno: construcao sem traducao (chamada por valor dentro de contrato) | compilador | - |
| `C0002` | interno: nome sem valor na geracao de codigo | compilador | - |
| `C0009` | desvio ou match sobre valor secreto (vazamento por tempo) | analisador | `C0009_secret_branch` |
| `C0010` | codigo emitido de funcao `@secret` desvia, divide ou le fora do seu quadro | ltv (lume tv) | - |
| `C0011` | o que um kernel de tempo constante (`@secret` + `@no_alloc`) nao traduz sem desvios | compilador | `C0011_secret_kernel_shift` |
| `C0012` | deslocamento literal fora de 0..63 | compilador | `C0012_shift_count_literal` |
| `C0271` | `comptime embed`: caminho invalido, vazio, com `..` ou inexistente | compilador | - |
| `C0430` | capsula aberta sem a permissao, ou adulterada | lume capsule | - |
| `C1001` | erro na avaliacao comptime (overflow, `unquote` fora de `quote`...) | compilador | `C1001_comptime_overflow` |
| `D0002` | duas funcoes com o mesmo nome | compilador | `D0002_duplicate_function` |
| `D0003` | dois tipos com o mesmo nome | compilador | `D0003_duplicate_type` |
| `D0004` | literal de registro com um campo repetido | compilador | `D0004_field_given_twice` |
| `D0273` | `comptime table_schema(T)` de tipo que nao e registro suportado | compilador | `D0273_table_schema_of_int` |
| `D0405` | simbolo ou endereco ausente do `.lsym` | lume symbolize | - |
| `E0001` | interno: erro do compilador que o analisador nao classificou | analisador | - |
| `E0002` | interno: uma analise parou (reporte com o programa) | analisador | - |
| `E0200` | efeito que a assinatura nao declara (`/ pure`, kernel, ISR, shard, capacidade) | compilador | `E0200_effect_of_pure_fn` |
| `E0210` | codigo `@no_alloc` que pode alocar (int sem limite, chamada que aloca) | compilador | `E0210_no_alloc_unbounded` |
| `E0305` | valor usado depois de movido por `chan_send_linear` (imediatos copiados ficam) | compilador | `E0305_linear_used_after_send` |
| `E0306` | locks fora da ordem, lock retido no retorno, ou ciclo de espera entre atores | compilador | `E0306_lock_never_released` |
| `I0002` | funcao exportada para WASM fora do fragmento escalar i64 | analisador | - |
| `I0003` | declaracao C nao suportada ou repetida no cabecalho | lume adapt | - |
| `I0004` | funcao C FFI com mais de 6 parametros | compilador | - |
| `I0275` | recusa de interoperabilidade do alvo | ltarget | - |
| `K0005` | escrita fisica na faixa de texto/rodata do kernel [32768..262143] | analisador | `K0005_write_into_kernel_text` |
| `K0006` | recursao mutua em kernel freestanding | analisador | `K0006_kernel_mutual_recursion` |
| `K0010` | certificado de outra fonte (hash diferente) | lcert | - |
| `K0011` | obrigacao da fonte sem entrada no certificado | lcert | - |
| `K0012` | entrada do certificado sem obrigacao na fonte | lcert | - |
| `K0013` | termo do certificado nao e a obrigacao da fonte | lcert | - |
| `K0014` | declaracao ou expressao fora do fragmento certificavel | lcert | - |
| `K0015` | fonte ilegivel como um todo | lcert | - |
| `K0016` | tipo de obrigacao fora do fragmento | lcert | - |
| `K0017` | declaracao ou entrada de certificado repetida | lcert | - |
| `K0400` | corpo de kernel GPU fora de aritmetica escalar, let e if | lume agent kernel | `K0400_kernel_outside_fragment` |
| `L0001` | string nao terminada | compilador | `L0001_unterminated_string` |
| `L0002` | outro erro lexico (escape desconhecido, caractere invalido) | compilador | `L0002_bad_escape` |
| `L0003` | numero malformado (digito colado a nome, base invalida, `_` no fim) | compilador | `L0003_digit_glued_to_name` |
| `L0004` | comentario de bloco `#[` nao fechado | compilador | `L0004_unterminated_block_comment` |
| `L0010` | simbolo definido duas vezes no assembly | lasm | - |
| `M1001` | payload nao e ASCII imprimivel | lume mesh | - |
| `M1002` | campo do payload ausente, repetido ou desconhecido | lume mesh | - |
| `M1003` | operacao de transacao desconhecida | lume mesh | - |
| `M1004` | construcao fora do fragmento do protocolo semantico | lume mesh | - |
| `M2001` | compilador recusou o AST canonico sem diagnostico | lume mesh | - |
| `M2002` | funcao ou assinatura repetida, orfa ou ambigua | lume mesh | - |
| `M2003` | alvo semantico nao suportado | lume mesh | - |
| `M2004` | capacidades fora do conjunto negociado | lume mesh | - |
| `M2005` | pedido alem dos limites negociados | lume mesh | - |
| `M3001` | aceitacao `prove` com obrigacao nao provada | lume mesh | - |
| `M3002` | alvo do contrato ausente ou ambiguo | lume mesh | - |
| `M3003` | substituicao de contrato inexistente | lume mesh | - |
| `M3004` | indice de linhagem inexistente | lume mesh | - |
| `N0400` | `grad` / `jvp` / `vjp` de funcao fora do fragmento diferenciavel | compilador | `N0400_autodiff_division` |
| `O0001` | uso de valor movido | compilador | `O0001_use_after_move` |
| `O0002` | mover de um parametro emprestado | compilador | `O0002_move_from_borrowed` |
| `O0004` | recurso nunca liberado, devolvido ou repassado | compilador | `O0004_resource_dropped` |
| `O0010` | ligacao imutavel emprestada como `mut` | compilador | `O0010_immutable_to_mut` |
| `O0011` | valor emprestado `mut` e lido na mesma chamada | compilador | `O0011_conflicting_borrows` |
| `O0012` | parametro `own` recebeu argumento sem `own` | compilador | `O0012_missing_own` |
| `O0013` | mover ou mutar com emprestimo ativo | compilador | `O0013_move_while_borrowed` |
| `O0020` | emprestimo de local escapa da funcao | compilador | `O0020_borrow_escapes` |
| `O0021` | `pub fn` devolve emprestimo sem `from PARAM` | compilador | `O0021_borrow_without_origin` |
| `O0030` | alocacao em codigo `@freestanding` sem `with alloc` | compilador | - |
| `P0001` | delimitador ainda aberto no fim do arquivo | compilador | `P0001_unclosed_at_end` |
| `P0002` | outro erro de sintaxe | compilador | `P0002_parse_error` |
| `P0003` | duas instrucoes ou funcoes na mesma linha | compilador | `P0003_two_functions` |
| `P0004` | atributo desconhecido (erro em `@no_alloc`, `@secret`...) | compilador | `P0004_unknown_attribute` |
| `PC0002` | entrada do cache de provas recusada (versao, esquema ou digest) | lproof_cache | - |
| `PC0003` | binario do provador ausente para as obrigacoes nao cacheadas | lproof_cache | - |
| `PC0005` | falhas de cache onde todas deviam acertar | lproof_cache | - |
| `R0001` | artefato do componente ausente ou vazio | lume registry | - |
| `R0002` | o kernel de prova independente recusou o certificado | lume registry | - |
| `R0003` | toolchain do registro incompleta | lume registry | - |
| `R0004` | alvo diferente de x86_64-linux-elf | lume registry | - |
| `R0005` | outro erro do registro (a mensagem diz qual) | lume registry | - |
| `R0200` | chamada a funcao inexistente | compilador | `R0200_undefined_function` |
| `R0201` | funcao com nome de builtin do runtime | compilador | `R0201_builtin_clash` |
| `R0202` | builtin chamado com numero errado de argumentos | compilador | `R0202_builtin_arguments` |
| `R0203` | chamada a rotina interna do runtime | compilador | `R0203_internal_routine` |
| `R0204` | `f[...]` sobre uma funcao | compilador | `R0204_index_a_function` |
| `R0205` | local com nome de builtin e chamado (a chamada vai ao builtin) | compilador | `R0205_local_named_like_builtin` |
| `S0001` | spawn fora de scope, ou capturando valor nao Send ou `var` | compilador | `S0001_spawn_captures_var` |
| `T0001` | erro de tipo (argumento, ramo ou retorno de outro tipo) | compilador | `T0001_type_error` |
| `T0300` | formas de tensor que nao concordam | compilador | `T0300_tensor_shape` |
| `T0400` | impl sem um metodo do trait | compilador | `T0400_impl_missing_method` |
| `T0401` | metodo chamado em tipo sem impl | compilador | `T0401_method_without_impl` |
| `T0402` | metodo do impl que nao esta no trait | compilador | - |
| `T0403` | metodo do impl com tipos diferentes do trait | compilador | - |
| `T0500` | funcao generica de let usada em tipo incompativel | compilador | `T0500_polymorphic_let_misuse` |
| `T0601` | condicao de `if` que nao e bool | compilador | `T0601_int_condition` |
| `T0602` | bool devolvido onde se declarou int, ou o contrario | compilador | `T0602_bool_returned_as_int` |
| `T0603` | argumento de tipo diferente do declarado no parametro | compilador | `T0603_argument_type` |
| `T0604` | `+` (e `and`/`or`) entre tipos diferentes: `+` nunca converte | compilador | `T0604_plus_never_converts` |
| `T0605` | let anotado com um tipo recebe outro | compilador | `T0605_let_annotation` |
| `T0606` | ramos de `if` / `match` de tipos diferentes | compilador | `T0606_branch_types` |
| `T0607` | `requires` / `ensures` / law que nao e bool | compilador | `T0607_clause_not_bool` |
| `T0900` | construcao fora do fragmento do alvo escolhido | ltarget | - |
| `T0901` | fonte fora do fragmento de kernel para alvo bare-metal | ltarget | - |
| `T0902` | o front end lumec recusou a fonte (o diagnostico segue) | ltarget | - |
| `T0903` | lumec ausente | ltarget | - |
| `T1001` | construtor que nenhum enum declara | compilador | `T1001_unknown_constructor` |
| `T1002` | match sem uma variante, ou construtor com aridade errada | compilador | `T1002_match_missing_variant` |
| `T1003` | tipo de registro nao declarado, ou campo que ele nao tem | analisador | `T1003_unknown_record_field` |
| `T2001` | tipo do argumento difere do parametro (inclui moedas de money) | analisador | `T2001_money_currency` |
| `T2002` | funcao devolve tipo diferente do declarado | analisador | `T2002_return_type` |
| `T2101` | leitura de campo que o registro nao tem | compilador | `T2101_missing_field` |
| `T3001` | parametro `comptime T: type` recebeu um valor (aviso) | analisador | `T3001_comptime_needs_type` |
| `V0001` | contrato refutado, com contraexemplo | prove | `V0001_contract_refuted` |
| `V0002` | acima do orcamento `@bound(cycles: N)` | analisador | `V0002_wcet_budget` |
| `V0003` | obrigacao mais fraca que na versao base | lume proof-diff | - |
| `V0004` | contratos entre modulos ou leis relacionais que nao compoem | analisador | - |
| `V0005` | lei temporal (`always`, `eventually`, `until`, `leads_to`) refutada | prove | `V0005_temporal_law_refuted` |
| `W0001` | credencial literal na fonte (`sk-`, `ghp_`, `AKIA`, PEM) | compilador | `W0001_hardcoded_secret` |
| `W0002` | segredo literal achado pela varredura de protecao | lume protect | - |
| `W0003` | funcao do programa com nome de uma importada | compilador (aviso) | `W0003_duplicate_name` |
| `W0004` | f64 e int misturados numa expressao | compilador (aviso) | `W0004_f64_int_mix` |
| `W0005` | chamada a funcao marcada `## Deprecated:` em outro modulo | compilador (aviso) | - |
| `W0064` | programa sem a partida hospedada (imagem de kernel) para Windows | lumec --win64 | - |

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
`buf_h264_mb_i4 (src, si, ss, rec, ri, cfg)` codifica um macrobloco Intra4x4 inteiro numa chamada: para cada um
dos 16 blocos (ordem luma4x4BlkIdx) as 9 predicoes que os vizinhos permitem, custo SATD + lambda x (1 no modo
previsto, senao 4); a mais barata e transformada, quantizada e reconstruida em rec. cfg (pelo menos 592 bytes,
int32 little endian) traz rs, qp, lambda, os vizinhos do macrobloco (1 esquerda, 2 topo, 4 topo-direita, 8
topo-esquerda) e os modos vizinhos (bytes 16..23, 255 = nenhum); devolve os modos (32..47), niveis nao nulos
(48..63), os niveis em zigzag prontos para o CAVLC (64 + 32 x bloco) e os codigos de modo (576..591, 255 =
previsto). Responde o custo total ou -1. Mesmo resultado dos builtins de bloco; um quadro luma 1080p leva cerca
de 120 ms (conteudo de tela) a 230 ms (texturizado).
`buf_h264_mb_p (src, si, ss, ref, rec, cfg)` codifica um macrobloco inter 16x16 inteiro com um vetor de movimento:
a predicao em quarto de amostra a partir de ref (como `buf_h264_luma_mc`, nos bytes 640..895 de cfg), depois cada
bloco 4x4 e subtraido, transformado, quantizado com o arredondamento inter e reconstruido em rec (ref e rec: plano
luma no offset 0, linhas a rs bytes). cfg (pelo menos 896 bytes, int32): rs, qp, largura e altura da imagem, x e y
do macrobloco, mvx e mvy (quartos de amostra, com sinal); sai a contagem de niveis nao nulos por bloco (32..47),
os niveis em zigzag (64 + 32 x bloco) e o coded_block_pattern luma (int32 em 576). Responde o total de niveis nao
nulos (0: candidato a P_Skip) ou -1. Mesmo resultado de `buf_h264_luma_mc` com os builtins de bloco; cerca de 8 us
por macrobloco.
`buf_h264_mb_pc (src, si, ss, ref, rec, cfg)` codifica um plano de croma (8x8) de um macrobloco inter com o vetor
luma: predicao em oitavo de amostra (como `buf_h264_chroma_mc`, em cfg 256..319), os 4 blocos transformados, os
coeficientes DC pela Hadamard 2x2 e a quantizacao de DC de croma, os AC pela 4x4, e a reconstrucao em rec; qPc vem
de QPY + chroma_qp_index_offset (tabela 8-15). cfg (512 bytes): rs, QPY, offset, largura, altura do plano, x, y do
bloco, mvx, mvy; sai contagens AC (40..43), contagem DC (44), os 4 niveis DC (48..55), os niveis em zigzag por bloco
(64 + 32 x bloco, posicao DC 0: CAVLC a partir de + 2 com maxc 15) e a parte do cbp do plano (200: 0, 1 DC, 2 AC).
Cerca de 4 us por plano e macrobloco.
`buf_h264_me16 (src, si, ss, ref, cfg)` acha o vetor de um macrobloco 16x16: (0, 0) e o vetor previsto, um losango
pequeno sobre SAD + lambda x bits do vetor dentro do alcance, depois (nivel 1 / 2) os 8 vizinhos de meia e de quarto
de amostra pelo SATD da predicao interpolada. cfg (1088 bytes): rs, largura, altura, x, y do macrobloco, previsto
pmx, pmy (quartos de amostra), alcance, lambda, nivel; sai mvx, mvy (40, 44), o custo (48) e a predicao do vetor
(640..895). Cerca de 1 us por macrobloco em amostras inteiras com o vetor previsto certo, 2 us com quarto.
`buf_h264_mb_i16 (src, si, ss, rec, ri, cfg)` codifica um macrobloco Intra16x16 inteiro: o modo (vertical,
horizontal, DC, plano, conforme os vizinhos) de menor SATD; sem o flag de so decidir, os 16 blocos sao
transformados, os coeficientes DC passam pela Hadamard 4x4 e pela quantizacao de DC luma, os AC pela 4x4, e a
decodificacao de 8.5.10 vai para rec. cfg (896 bytes): rs, qp, flags (1 = so decidir: responde o custo e nao mexe
em rec, para comparar antes com `buf_h264_mb_i4`), vizinhos (1 esquerda, 2 topo, 8 topo-esquerda); sai o modo (16),
contagem DC (20), os 16 niveis DC em zigzag (24..55), contagens AC por bloco (64..79), niveis em zigzag por bloco
(96 + 32 x bloco, CAVLC a partir de + 2, maxc 15), cbp (608: 0 ou 15) e a predicao (640..895). Responde o SATD.
`buf_h264_mb_ic (srcu, srcv, recu, recv, cfg)` codifica a croma intra de um macrobloco: o intra_chroma_pred_mode
(0 DC com as regras por bloco de 8.3.4, 1 horizontal, 2 vertical, 3 plano) de menor SATD sobre Cb e Cr juntos,
depois os dois planos como `buf_h264_mb_pc` faz mas com o arredondamento intra (salvo so decidir). cfg (1344 bytes):
rs, ss, QPY, offset de croma, si, ri (os dois planos), vizinhos (1 esquerda, 2 topo, 8 topo-esquerda), flags (1 so
decidir); sai o modo (32) e o custo (36), as saidas de Cb em 512 + os offsets de `buf_h264_mb_pc` (predicao
768..831), as de Cr em 1024 + os mesmos (predicao 1280..1343). Responde o custo.
`buf_h264_cavlc_luma (lev, ctx, out, pos)` / `buf_h264_cavlc_chroma (lev, ctx, out, pos)` gravam o residuo de um
macrobloco inteiro com CAVLC, a partir dos niveis como os builtins de macrobloco deixam: o nC de cada bloco por
9.2.1 (dentro do macrobloco pelos blocos ja gravados, nas bordas pelo TotalCoeff dos macroblocos vizinhos em ctx,
255 = indisponivel), a ordem e o coded_block_pattern de 7.3.5.3. ctx luma (64 bytes): modo (0: 16 blocos de 16, 1:
Intra16x16 DC depois 15 AC por bloco), cbp (4), offset do bloco 0 (8), offset do DC (12), TotalCoeff da esquerda
(16..19) e do topo (20..23); sai o TotalCoeff de cada bloco (32..47). ctx croma: cbp (0..2), bases de saida de Cb e
Cr (4, 8), TotalCoeff da esquerda (16..19: Cb 2, Cr 2) e do topo (20..23); sai o TotalCoeff AC (32..39). Respondem
a nova posicao de bit ou -1.

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

Entrou: `lume debug --dap` (o depurador pelo Debug Adapter Protocol), `buf_h264_mb_i4`, `buf_h264_mb_i16`, `buf_h264_mb_ic`, `buf_h264_mb_p`, `buf_h264_mb_pc`, `buf_h264_cavlc_luma` / `chroma` (macroblocos Intra4x4, inter luma e inter croma inteiros numa chamada), `buf_h264_me16` (busca de movimento), a tabela de todos os codigos de diagnostico (secao 3a) e exemplos de diagnostico para 68 codigos, `use std/hash`, `csv`, `utf8`, `datetime`, `regex`, `deflate`, `http`, `tls` (HTTPS com TLS 1.3), `tlspki`, `bignum`, versoes de pacotes (`lume pkg publish / add / install`, `[packages]` no lume.lock), `lume verify` (muitos arquivos, N processos, cache por arquivo), a pilha de chamadas (`at NOME (arquivo:LINHA)`) depois de um erro em tempo de execucao, contratos dos builtins no provador (`buf_bits_write`, `buf_get`, `buf_len`, `count`, `buf_sad*`, `buf_satd*`, `buf_h264_quant4x4`), exemplos oficiais (`examples/topics`, `examples/diagnostics`, gate dos exemplos), `use std/NOME`, `buf_bits_write / read / ue / se`, `## Deprecated:` e o aviso [W0005], docs/STABILITY.md (semver, obsolescencia, LTS 1.2), `use math` (funcoes matematicas, f32, buffers f32), parametros f64, W0004, `lume run --profile`, `use h264` (compensacao de movimento, desbloqueio), `buf_sad*`, `buf_satd*` (SSE2), `buf_h264_*`, `use tun`, `lchameleon` `chameleon_c_open / sym / call` e
`chameleon_verify_boundary`, `priv fn`, aviso [W0003], `LUME_FL`, literais constantes em .rodata, cache de campo por
ponto de leitura, ritmo de coleta `max(8 MiB, 3 x vivo)`.
Mudou: o [E0305] deixa com o remetente um int ou bool copiado para dentro ou para fora do registro enviado; um delimitador ainda aberto no fim do arquivo e [P0001] (era [P0002]); exemplos de `lume agent kernel` rodam no gate dos exemplos; o W0004 tambem ve parametros `f64` e resultados de `f64(...)`; `buf_sad4x4` roda em SSE2; o C0009 numa funcao `ct_` diz que o motivo e o prefixo; `lume fmt` se recusa a rodar no Stage-0; no Git
Bash o `lume` roda o `lume.exe` nativo; `fs_copy` mantem as permissoes da origem.
Saiu: nada.
