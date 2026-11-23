# Referencia da Lume (factual) — v1.2.0

Esta e a referencia do que funciona hoje. Ela nao tem roteiro nem material de visao: isso esta em
`lume manual --pt visao` e nos outros capitulos, que misturam os dois. Cada exemplo abaixo e executado por
`tests/docs/ref_examples_gate.src` (na bateria de testes) com a toolchain instalada; o bloco embaixo de cada exemplo
e a saida exata dele.

Estados: **estavel** = Linux x86-64 e Windows x64, mesmo comportamento; **linux** / **windows** = so naquela
plataforma; **experimental** = funciona, a API ainda pode mudar; **privilegiado** = precisa de root (Linux) ou de
processo elevado (Windows); **kernel** = so dentro de um kernel `@freestanding` (secao 7a).

Todo builtin que um programa pode chamar esta aqui (a tabela `compiler/stage1/builtins_table.src`, coluna doc, e
conferida com este arquivo pelo gate de builtins); rotinas do runtime que nenhum programa chama e nomes que so o
compilador produz ficam de fora.

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

Pacotes: `lume pkg publish [dir] --store=DIR` roda as verificacoes do proprio pacote (`lume test` em todo arquivo com
`fn test_`, `lume prove` em todo arquivo com contratos; um pacote com dependencias e verificado junto delas,
resolvidas no mesmo store) e guarda NOME/VERSAO imutavel com o SHA-256. `lume pkg add NOME@REQ` grava
`nome = "REQ"` em `[dependencies]` (REQ: `1.2.3`, `^1.2`, `~1.2.3`, `>=1.2`, `<2`, uma lista com virgulas como
`>=1.2, <2`, ou `*`). `lume pkg install --store=DIR` resolve o manifesto e as dependencias de cada pacote (a versao
que o `lume.lock` cita enquanto ela ainda serve, senao a maior versao do store que atende todos os requisitos; um
conflito cita cada requisito e quem o fez), confere cada copia com o hash publicado e com o hash do `lume.lock`, roda
os testes e as provas de cada pacote e so quando tudo passa preenche `lume_modules/` e grava versoes e hashes no
`lume.lock`. Uma instalacao recusada nao muda nada; `--allow-failing` instala mesmo assim, com um aviso. `--update`
ignora o lock e pega as versoes mais novas; `--locked` recusa qualquer mudanca no lock (CI).
`lume pkg resolve [dir] --store=DIR` mostra as versoes que o install pegaria e nao muda nada. `use NOME` encontra um
pacote instalado, tambem de dentro de outro. O store tambem pode ser dado por `LUME_PKG_STORE`.

Registros remotos: `--registry=https://host/caminho` (ou `[registry] url = "..."` no `lume.toml`, ou
`LUME_PKG_REGISTRY`) indica um registro com indice: o `lume-index.toml` na raiz tem uma tabela `[[package]]` por versao
(`name`, `version`, `archive`, o `sha256` do arquivo, o `hash` dos arquivos do pacote, `deps = ["util ^1.0"]`). O
indice e os arquivos vem pelo `std/http` (HTTPS: TLS 1.3, certificado conferido com as raizes do sistema e o nome do
host; `http://` simples so para esta maquina, salvo `--allow-http`); um caminho de diretorio funciona igual, sem rede.
Cada arquivo (um `.tar.gz` ustar que o `tar` tambem le, so com `lume.toml` e arquivos `NOME.src`) e conferido com o
SHA-256 do indice ANTES de qualquer extracao, guardado no cache (`--cache=DIR`, `LUME_PKG_CACHE`, padrao
`~/.lume/pkg-cache`) e entao preparado, testado, provado e instalado como um pacote do store; o `lume.lock` registra a
URL e o SHA-256 de cada arquivo, e uma versao publicada cujo arquivo mudou e recusada. `--registry=git+URL` le um
registro com indice guardado num repositorio git e fixa o commit no `lume.lock`. Uma dependencia
`nome = { git = "URL", rev = "REV" }` (gravada por `lume pkg add NOME --git=URL [--rev=REV]`) vem pelo `git` do
sistema (iniciado direto, sem shell) e fica fixada no commit no `lume.lock` ate um `--update`. Com `lume.lock` e cache
completos, `--offline` instala sem rede. `lume pkg publish [dir] --registry=DIR` roda as verificacoes do pacote, grava
`DIR/NOME/NOME-VERSAO.tar.gz` e acrescenta a versao em `DIR/lume-index.toml`; sirva DIR com qualquer servidor web
estatico, ou faca commit dele num repositorio git.

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

- `fn nome(a, b) = expr`, `pub fn` (exportada), `priv fn` / `priv const` / `priv law` (privada do modulo), `const NOME: T = expr`,
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
| `K0007` | builtin so de kernel (I/O de porta, MSRs, cli / sti / hlt, CR3, invlpg, IDT, interrupcoes, boot de AP, troca de tarefa, `vga_*`) num programa hospedado | compilador | `K0007_kernel_builtin_in_hosted` |
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
| `ord(s)` | o primeiro byte de s como int (0..255); `0` para `""` | para com um valor que nao e string |
| `utf8_chr(n)` | os bytes UTF-8 (1 a 4) do ponto de codigo n | n <= 0, um surrogate (U+D800..U+DFFF) ou n > U+10FFFF: escreve `lume: utf8_chr requires a non-zero Unicode scalar <= U+10FFFF` no **stdout** e sai com 3 (sem pilha de chamadas, nao e capturado por um try) |
| `slicen(s, x, a, b)` | `slice(s, a, b)`; x nao e usado (qualquer valor) | como `slice` |
| `lidx(v, i)` | `v[i]`: o item i de uma lista, ou o byte i de uma string como string de um byte | para com indice fora (`list index out of bounds`), indice que nao e int, ou valor que nao se indexa |
| `printval(v)` | escreve o texto de v (como `print`) e uma quebra de linha no stdout | a resposta dele nao e um valor Lume: chame so pelo efeito, nunca use o que ele responde |

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

Operacoes de bits (estavel; ints sao de 64 bits em complemento de dois):

| Builtin | Resposta |
| --- | --- |
| `bit_and(a, b)` / `bit_or(a, b)` / `bit_xor(a, b)` | o e / ou / ou exclusivo bit a bit |
| `bit_not(a)` | o complemento bit a bit, `-a - 1` |
| `bit_shl(a, k)` | a deslocado k casas para a esquerda; os bits que saem da palavra de 64 bits se perdem (sem parada por estouro) |
| `bit_shr(a, k)` | a deslocado k casas para a direita, aritmetico (o sinal fica: `bit_shr(-16, 2)` e -4) |

Uma contagem de deslocamento fora de 0..63 para o programa (`lume: shift count outside 0..63`, saida 3); uma
literal e recusada na compilacao ([C0012]).

Falhar e capturar (estavel): `ctfail(s)` falha com a mensagem s do proprio programa. Fora de um try, s vai para o
stderr como esta (sem quebra de linha acrescentada, sem pilha de chamadas) e o programa sai com 3.
`__lume_try_begin()` abre um try e responde 0; quando um erro em tempo de execucao ou um `ctfail` acontece antes do
`__lume_try_end()` correspondente, o controle volta para aquela chamada de `__lume_try_begin()`, que entao responde
1, e `__lume_try_msg()` da a mensagem (o s do `ctfail` como esta, o texto de um erro do runtime com a quebra de
linha dele, `""` quando nada falhou ainda; ela nao e limpa depois). `__lume_try_end()` fecha o try mais interno e
responde 0 (tambem sem try aberto). No maximo 16 trys abertos ao mesmo tempo; o 17o para o programa. `lume test`
roda cada teste dentro de um try assim.

```lume
fn risky(x) = if x > 3 then ctfail("too big") else x * 2
fn guarded(x) = if __lume_try_begin() == 0 then (let r = risky(x) in let e = __lume_try_end() in str(r)) else "failed: " + __lume_try_msg()
print guarded(2)
print guarded(5)
print ord("A")
print utf8_chr(233)
print lidx([10, 20, 30], 1)
print bit_not(5)
print bit_shr(0 - 16, 2)
```
```output
4
failed: too big
65
é
20
-6
-4
```

## 5. Buffers de bytes (estavel)

`buf_new(n)` (n bytes zerados), `buf_len(b)`, `buf_get(b, i)` (0..255), `buf_set(b, i, v)` (devolve b),
`buf_copy(dst, d_off, src, s_off, n)` (src um buffer ou uma string: um quadro que chega como string vai para um
buffer que ja existe, sem criar outro), `buf_slice(b, off, n)`, `buf_from_str(s)`, `buf_to_str(b, off, n)`,
`buf_addr(b)` (endereco do byte 0, para chamadas de sistema). Indice fora do buffer ou valor fora de 0..255 para o
programa. `buf_shared(n)` e um buffer em memoria compartilhada com os processos que `os_fork` criar depois (o que
um escreve, todos leem). Com `use par`: `par_pool(n, fn(k, job) => ...)` cria n processos trabalhadores uma vez,
`par_run(pool, job)` roda a funcao em todos ao mesmo tempo e devolve a soma das respostas (as escritas deles nos
buffers compartilhados ficam visiveis), `par_slice(k, n, total)` e o primeiro item do trabalhador k, `par_queue()` /
`par_reset(q)` / `par_take(q)` entregam numeros de item um a um a quem pedir (nucleos mais rapidos pegam mais),
`par_close(pool)`
os encerra.

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
argumento errado): `buf_bgra_to_i420`, `buf_i420_to_bgra`, `buf_bgra_to_i420_rows(src, stride, w, h, dst, r0, r1)` (so as
linhas r0 .. r1 - 1, r0 par, escritas onde a conversao inteira as poe: cada trabalhador de um pool converte a sua faixa
num unico buffer I420 compartilhado), `buf_sad16x16 / buf_sad8x8 / buf_sad4x4 (a, ai, sa, b, bi, sb)` e
`buf_satd4x4 / buf_satd16x16 (iguais)` (SSE2), `buf_h264_fdct4x4 / buf_h264_idct4x4 (src, si, dst, di)` (blocos int16),
`buf_h264_quant4x4 (src, si, qp, intra, dst, di)` (devolve os niveis nao nulos), `buf_h264_dequant4x4 (src, si, qp,
dst, di)`, `buf_h264_sub4x4 (a, ai, sa, pred, pi, dst)`, `buf_h264_recon4x4 (pred, pi, res, ri, dst, di)`,
`buf_h264_intra4x4 / buf_h264_intra16x16 (frame, fi, fs, modo, disponivel, dst)` (bits de disponivel: 1 esquerda, 2 topo,
4 topo-direita, 8 topo-esquerda). Com `use h264`: `buf_h264_cavlc4x4 (coef, ci, nc, maxc, out, pos)` codifica
um bloco de maxc (16, 15 ou 4) coeficientes int16 em ordem zigzag com CAVLC (nC -1: DC de croma) em out a partir do
bit pos e devolve {pos, total} (a nova posicao de bit, -1 com argumento errado ou buffer cheio, e o TotalCoeff). O
fluxo e escrito em ordem: os bits depois da nova posicao no seu ultimo byte ficam 0 (com 1344 bits ou mais livres o
bloco e codificado sem conferir cada codigo, ~140 ns num bloco de 5 niveis).
`buf_h264_mb_i4 (src, si, ss, rec, ri, cfg)` codifica um macrobloco Intra4x4 inteiro numa chamada: para cada um
dos 16 blocos (ordem luma4x4BlkIdx) as 9 predicoes que os vizinhos permitem, custo SATD + lambda x (1 no modo
previsto, senao 4); a mais barata e transformada, quantizada e reconstruida em rec. cfg (pelo menos 592 bytes,
int32 little endian) traz rs, qp, lambda, os vizinhos do macrobloco (1 esquerda, 2 topo, 4 topo-direita, 8
topo-esquerda; + 65536: decisao rapida, vertical / horizontal / DC e depois so os modos diagonais vizinhos do
vencedor, ~20% mais rapida) e os modos vizinhos (bytes 16..23, 255 = nenhum); devolve os modos (32..47), niveis nao nulos
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
`buf_h264_deblock_mb (y, u, v, cfg)` filtra (deblocking) um macrobloco inteiro no lugar (8.7, macroblocos de quadro
4:2:0), como um decodificador faz quando ele e tudo antes dele em ordem raster estao reconstruidos: bordas verticais
de luma da esquerda para a direita, horizontais de cima para baixo, depois Cb e Cr. bS por segmento de 4 amostras
(8.7.2.1): 4 numa borda de macrobloco com macrobloco intra de um dos lados, 3 dentro de um macrobloco intra, 2 quando
o bloco 4x4 de p0 ou de q0 tem coeficientes, 1 quando as imagens de referencia diferem ou um componente do vetor
difere em 4 quartos de amostra ou mais, senao 0; as bordas de croma usam o bS das bordas 0 e 2 de luma. alpha / beta
/ tC0 das tabelas 8-16 / 8-17 com indexA / indexB = qPav + FilterOffsetA / B (qPav: o QPY dentro, a media
arredondada dos dois macroblocos na borda esquerda / de cima; croma igual com o QPc da tabela 8-15). Bordas na borda
da imagem ficam de fora, bordas de fatia tambem com disable_deblocking_filter_idc 2, tudo com idc 1. y, u, v guardam
os tres planos. cfg (ao menos 400 bytes, int32 little endian): offset de luma da imagem (0), passo de luma (4),
offset de Cb (8), offset de Cr (12), passo de croma (16), mbx (20), mby (24), largura (28) e altura (32) em
macroblocos, idc (36), FilterOffsetA (40) e FilterOffsetB (44) (com sinal: slice_alpha_c0 / beta_offset_div2 x 2),
chroma_qp_index_offset (48, com sinal), flags (52: 1 o macrobloco da esquerda, 2 o de cima esta em outra fatia);
depois 112 bytes para este macrobloco (64), o da esquerda (176) e o de cima (288): intra (int32, nao zero = intra),
QPY (int32 em 4), flags de coeficientes (bytes 8..23), identidades das imagens de referencia (bytes 24..39, p. ex.
ref_idx numa fatia P), vetores (int16 mvx, mvy em 40 + 4 x bloco, quartos de amostra), tudo por bloco 4x4 na ordem
luma4x4BlkIdx (a ordem das contagens de `buf_h264_mb_p`). Responde 0, ou -1 com argumento errado. Toda borda
roda em SSE2 (16 linhas de uma vez, o filtro forte tambem); cerca de 1,7 us por macrobloco em conteudo 1080p, inter
ou intra (h264_dbkmb_ok.src o compara com o procedimento da norma escrito em Lume comum).

Formas empacotadas por tras de `use h264` (estavel; no maximo seis argumentos cada, entao o modulo empacota os
inteiros; um programa pode chama-las direto; cada uma responde -1 com argumento errado): `buf_h264_lmc6(ref, dst, a,
b, g, q)` / `buf_h264_cmc6(ref, dst, a, b, g, q)` sao a compensacao de movimento de luma (quarto de amostra) / croma
(oitavo de amostra) com a = ri x 65536 + rs, b = di x 65536 + ds, g = rw + rh x 2^16 + w x 2^32 + h x 2^40 e q = (qx +
2^29) + (qy + 2^29) x 2^30 (qx, qy: a posicao em quartos ou oitavos de amostra); 0 no sucesso.
`buf_h264_dbk5(buf, q0, a, b, cp)` filtra uma borda: a = across + 2^24 + (along + 2^24) x 2^25, b = lines + 256
(croma) + alpha x 65536 + beta x 2^24, cp os valores bS (4 bits por segmento, no bit 4k) e tC0 (8 bits por segmento,
no bit 16 + 8k); 0 no sucesso. `buf_h264_cavlc6(coef, ci, nc, maxc, out, pos)` codifica um bloco como a funcao CAVLC
do modulo e responde pos x 32 + total (a nova posicao em bits e o TotalCoeff), ou -1.

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

## 5b. Vetores de bits, tempo constante e SIMD

Vetores de bits do tamanho de um byte (estavel; a aritmetica de bytes que o `lume certify` modela; qualquer
argumento int):

| Builtin | Resposta |
| --- | --- |
| `bv_u8(a)` | `a` mascarado para 8 bits (0..255; `bv_u8(-1)` e 255) |
| `bv_not_u8(a)` | o complemento dos 8 bits baixos (0..255) |
| `bv_add_u8(a, b)` / `bv_sub_u8(a, b)` / `bv_mul_u8(a, b)` | a soma / diferenca / produto modulo 256 (0..255) |
| `bv_and(a, b)` / `bv_or(a, b)` / `bv_xor(a, b)` | como `bit_and` / `bit_or` / `bit_xor` (64 bits, sem mascara) |
| `bv_shl(a, k)` / `bv_shr(a, k)` | como `bit_shl` / `bit_shr` (64 bits, a mesma verificacao 0..63 da contagem) |

Tempo constante (estavel): `ct_eq(a, b)` responde 1 quando a == b, senao 0, e `ct_select(m, a, b)` responde, bit a
bit, o bit de a onde m tem 1 e o bit de b onde m tem 0 (`ct_select(-1, a, b)` e a, `ct_select(0, a, b)` e b); os dois
sao calculados sem desvio sobre os argumentos. Dentro de um kernel de tempo constante (`@secret` e `@no_alloc`) eles,
os `bit_*` e `bv_and` / `bv_or` / `bv_xor` / `bv_shl` / `bv_shr` viram codigo em linha reta (contagens de
deslocamento precisam ser literais: 0..62 para `bit_shr`, 0..61 para `bit_shl`); qualquer outra coisa ali e [C0011].

Sondas SIMD (experimental; instrucoes AVX2, entao num processador sem AVX2 o programa cai com instrucao ilegal):
`simd_add4_i64(a, b)` poe a e b nas quatro faixas de 64 bits de dois vetores, soma faixa a faixa e responde a soma
das quatro faixas, `4 * (a + b)`, dando a volta em 64 bits (`simd_add4_i64(9223372036854775807, 0)` e -4);
`simd_sub4_i64(a, b)` responde `4 * (a - b)` do mesmo jeito; `simd_xor4_i64(a, b)` responde `bit_xor(a, b)` (faixa 0).

```lume
print ct_eq(5, 5)
print ct_select(12, 10, 5)
print bv_add_u8(200, 100)
print bv_u8(0 - 1)
print simd_add4_i64(1, 2)
```
```output
1
9
44
255
12
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

Diretorios, trechos, renomeacoes e modos (estavel salvo quando a linha diz outra coisa; um caminho e relativo ao
diretorio atual; no Windows `/` e `\` separam, e a resposta e a mesma do Linux salvo quando a linha diz):

| Builtin | Resposta | Plataformas |
| --- | --- | --- |
| `fs_current_dir()` | o diretorio atual absoluto, `""` quando nao da para ler | estavel; o Windows escreve como `/c/Users/...` (a letra do drive como primeiro componente, separador `/`) |
| `fs_chdir(p)` | 1, ou 0 (diretorio inexistente); os caminhos relativos seguintes e os programas iniciados depois usam o novo diretorio | estavel |
| `fs_read_dir(p)` | os nomes do diretorio, cada um seguido de `"\n"` (arquivos, subdiretorios e nomes ocultos; nunca `.` / `..`), `""` para diretorio vazio, caminho inexistente ou arquivo | estavel; ordem: no Linux a do proprio sistema de arquivos (sem ordenar), no Windows a do NTFS (ordenada) |
| `fs_rmdir(p)` | 1, ou 0 (inexistente, nao vazio, ou arquivo) | estavel |
| `fs_read_byte(p, off)` | o byte no deslocamento off (0..255), -1 quando off e negativo ou passa do fim, ou o arquivo nao pode ser lido (diretorio tambem) | estavel |
| `fs_read_range(p, off, n)` | ate n bytes a partir de off sem ler o arquivo inteiro; menos no fim do arquivo; `""` depois do fim, para n <= 0, off negativo ou arquivo ilegivel | estavel |
| `fs_files_equal(a, b)` | 1 quando os dois arquivos tem os mesmos bytes, 0 quando diferem (tamanho incluido), -1 quando um nao pode ser aberto ou lido (diretorio tambem) | estavel |
| `fs_truncate(p, tam)` | 1 depois de cortar o arquivo para tam bytes (um tamanho maior estende com bytes zero), 0 quando tam < 0 ou o arquivo nao existe (ele nao e criado) | estavel |
| `fs_rename(a, b)` | 1, ou 0 (a inexistente, ou entre volumes); um b existente e substituido | estavel |
| `fs_rename_noreplace(a, b)` | como `fs_rename`, mas 0 quando b ja existe (atomico; sistemas de arquivos Linux sem a opcao de nao substituir usam link + unlink, que recusa do mesmo jeito) | estavel |
| `fs_write_hex_file(p, hex)` | grava os bytes que o texto hex soletra (`0-9 a-f A-F`, quantidade par; `""` cria arquivo vazio), sincronizado no disco: 1, ou 0 para quantidade impar ou digito invalido (o arquivo entao nao e criado) ou gravacao que falha | estavel |
| `fs_mode(p)` | os bits de permissao (0..4095, ex. 420 = 0644, 493 = 0755), -1 quando o caminho nao pode ser lido | estavel; o Windows os deriva: 493 para diretorio, 420 para arquivo, 448 / 384 quando so o dono alcanca, o atributo somente leitura tira os bits de escrita (arquivo nunca mostra bits de execucao) |
| `fs_chmod(p, modo)` | 1, ou 0 para modo fora de 0..4095 ou caminho inexistente | estavel; Windows: o bit de escrita do dono e o atributo somente leitura, um modo sem bits de grupo e outros deixa a DACL so do dono, um com eles restaura as entradas herdadas; bits de execucao nao tem significado |
| `fs_make_executable(p)` | `fs_chmod(p, 493)`: 1, ou 0 | estavel; no Windows a extensao decide o que executa, entao so tira a protecao de dono (`fs_mode` passa a responder 420) |

Arquivos so do dono (estavel; para segredos: no Linux modo 0600 / 0700 deste usuario, no Windows uma DACL protegida
que concede so ao usuario que executa):

| Builtin | Resposta |
| --- | --- |
| `fs_create_private(p, s)` | cria p com a string s, so do dono, sincronizado no disco: 1, ou 0 quando p ja existe ou nao pode ser gravado (um arquivo meio gravado e removido) |
| `fs_write_private(p, s)` | substitui p atomicamente por um arquivo so do dono com s (gravado em `p.~` + 16 digitos hex do id do processo ao lado, depois renomeado): 1, ou 0 |
| `fs_mkdir_private(p)` | um diretorio so do dono (0700); um diretorio existente passa a 0700: 1, ou 0 (arquivo, ou pai inexistente) |
| `fs_is_private(p)` | 1 quando este usuario e o dono de p e ninguem mais recebe nada, 0 quando nao, -1 quando p nao pode ser lido |

Chaveiro do sistema: `os_keychain_put(nome, segredo)` guarda segredo (ate 2560 bytes) em nome e responde 1, senao um
erro negativo; `os_keychain_get(nome)` responde `"+"` seguido do segredo (um segredo vazio e `"+"`), `""` so quando
a entrada nao existe, e `"-"` seguido do numero do erro em qualquer outra falha (um cofre bloqueado ou que recusa
nunca e lido como segredo ausente); `os_keychain_delete(nome)` responde 1 quando removeu, 0 quando a entrada nao
existia, senao um erro negativo; `os_keychain_available()` e 1 quando o cofre pode ser usado. **windows**: o
Gerenciador de Credenciais (credencial generica que persiste para este usuario nesta maquina); uma falha Win32 e vira
-(100000 + e) (nome vazio da -100087) e um segredo acima de 2560 bytes -22. No Linux nao ha chaveiro do sistema:
`os_keychain_available()` e 0, put e delete respondem -38 e get `"-38"`; `use keychain` usa arquivos so do dono la.

Entrada padrao (estavel): `read()` e uma linha sem o `"\n"` (um `"\r"` antes dele fica), lida um byte por vez para
nao consumir nada depois da linha, `""` no fim da entrada (e tambem para uma linha vazia: teste o fim com
`io_read_byte()` ou `readall()`); `readall()` e todo o resto da entrada, `""` quando nao ha nada; `io_read_byte()` e o
proximo byte (0..255), -1 no fim da entrada. Os tres esperam enquanto a entrada e um terminal ou pipe ainda vazio.

```lume
print fs_write_hex_file("ref_a_hex.bin", "48690a")
print fs_read_range("ref_a_hex.bin", 0, 2)
print fs_read_byte("ref_a_hex.bin", 2)
print fs_truncate("ref_a_hex.bin", 1)
print fs_read_file("ref_a_hex.bin")
print fs_rename_noreplace("ref_a_hex.bin", "ref_a_hex2.bin")
print fs_files_equal("ref_a_hex2.bin", "ref_a_missing.bin")
print fs_remove("ref_a_hex2.bin")
```
```output
1
Hi
10
1
H
1
-1
1
```

```lume
print fs_mkdir("ref_a_dir")
print fs_write_sync("ref_a_dir/one.txt", "1")
print fs_read_dir("ref_a_dir")
print fs_rmdir("ref_a_dir")
print fs_remove("ref_a_dir/one.txt")
print fs_rmdir("ref_a_dir")
```
```output
1
1
one.txt

0
1
1
```

### Ambiente e informacoes do sistema (estavel)

| Builtin | Resposta | Plataformas |
| --- | --- | --- |
| `os_cpu_count()` | os processadores em que este processo pode rodar (a mascara de afinidade no Linux, NUMBER_OF_PROCESSORS no Windows), no minimo 1 | estavel |
| `os_fd_write(fd, s)` | escreve os bytes da string `s` no descritor de arquivo `fd` (2 e a saida de erro, 1 a saida padrao), depois de esvaziar o buffer de saida para manter a ordem; devolve a contagem de bytes. Uma escrita curta continua, `EINTR` repete, qualquer outra falha encerra o programa com saida 3 | estavel |
| `os_env_has(nome)` | 1 quando a variavel existe (tambem com valor `""`), senao 0; 0 para `""` | estavel; no Windows os nomes se comparam sem diferenca de caixa ASCII |
| `os_setenv(nome, valor)` | 1; 0 quando nome e `""` ou contem `=` (ou a memoria nao pode ser mapeada). A nova tabela passa a ser o ambiente deste processo (`os_getenv`, `os_env_has`) e todo filho iniciado depois a herda | estavel; veja a nota sobre caixa abaixo |
| `os_unsetenv(nome)` | 1, tambem quando a variavel nao existia; 0 quando nome e `""` ou contem `=` | estavel |
| `os_unix_time()` | segundos desde 1970-01-01 UTC (relogio de tempo real), 0 quando o relogio nao pode ser lido | estavel |
| `os_uname_field(i)` | 0 sistema (`"Linux"`, `"Windows_NT"`), 1 nome da maquina, 2 release (a release do kernel; no Windows no estilo `"10.0.26200"`), 3 versao (o texto de build do kernel no Linux, `""` no Windows), 4 arquitetura (`"x86_64"`); `""` para i fora de 0..4 | estavel |
| `os_getpid()` | o id deste processo | estavel |
| `os_self_maxrss_kb()` | o pico de memoria residente deste processo ate agora, em KiB (getrusage no Linux, o pico do working set no Windows) | estavel |
| `os_dns_servers()` | uma linha `nameserver ENDERECO` por servidor DNS de cada adaptador de rede ativo (servidores IPv6 mantem o `%escopo`; um servidor listado por dois adaptadores aparece duas vezes); `""` quando nao ha nenhum | windows; no Linux responde sempre `""` (leia `/etc/resolv.conf`, como faz `use dns`) |

No Linux os nomes se comparam exatamente. No Windows `os_getenv` / `os_env_has` acham um nome em qualquer caixa
ASCII (`Path` e `PATH`), mas `os_setenv` e `os_unsetenv` so substituem ou removem a entrada escrita na mesma caixa:
depois de `os_setenv("LUME_X", "a")`, `os_setenv("lume_x", "b")` acrescenta uma segunda entrada e
`os_getenv("LUME_X")` continua respondendo `"a"`; use uma grafia so. Todos estes sao para programas hospedados; uma
imagem de kernel `@freestanding` nao tem nenhum deles.

### Processos (estavel)

O **status** de um filho e o status bruto de wait: codigo de saida x 256 numa saida normal (`os_exit(7)` da 1792), o
numero do sinal para um filho encerrado por sinal (9 depois de `os_kill(pid, 9)`, 15 depois de `os_kill(pid, 15)`),
ou -errno quando nao ha o que esperar (-10, ECHILD). Um filho que nao consegue iniciar (programa inexistente, arquivo
de saida que nao pode ser criado) sai com 127: status 32512. Os lancadores recebem `path` (executado como dado: nao
ha busca no PATH; no Windows o `.exe` que falta e acrescentado) e `args`, uma lista de strings que viram argv 1, 2,
... (argv 0 e o path; no maximo 39 argumentos, os excedentes e tudo depois de um elemento que nao e string sao
descartados; uma string vazia vira um argumento vazio). O filho herda o ambiente como `os_setenv` o deixou, e o stdin
salvo indicacao contraria.

| Builtin | Resposta | Plataformas |
| --- | --- | --- |
| `os_fork()` | 0 no filho, o id do filho no pai, -errno na falha. O filho e uma copia do processo (Windows: a camada copia o espaco de enderecos, o filho continua no mesmo ponto); buffers `buf_shared` continuam compartilhados | estavel |
| `os_exec(path, args)` | substitui o processo pelo programa e nao retorna; na falha responde -errno (-2: arquivo inexistente) e o processo continua | estavel |
| `os_run(path, args)` | executa o programa com o stdin, stdout e stderr deste processo, espera, responde o status dele (-errno quando nenhum filho pode ser criado) | estavel |
| `os_run_capture(path, args, out, err)` | como `os_run`, com o stdout gravado no arquivo out e o stderr no arquivo err (cada um criado ou truncado, modo 0644; o mesmo caminho para os dois da um arquivo com as duas saidas) | estavel |
| `os_run_capture_timeout(path, args, out, err, ms)` | como `os_run_capture`, mas depois de ms milissegundos o filho e todo o seu grupo de processos (ele ganha um proprio; no Windows um job) sao mortos: status 9 e `os_last_timed_out()` 1 | estavel |
| `os_run_input_capture_timeout(path, args, inp, out, err, ms)` | como `os_run_capture_timeout`, com o stdin lido do arquivo inp (inp inexistente: status 32512) | estavel |
| `os_spawn_capture(path, args, out, err)` | inicia o programa como `os_run_capture` e responde o id dele na hora, sem esperar (-errno na falha); recolha-o com `os_waitpid_status` | estavel |
| `os_waitpid(pid)` | espera aquele filho, responde pid (o status nao e guardado), ou -errno (-10 quando nao e filho ou ja foi recolhido) | estavel |
| `os_waitpid_status(pid)` | espera aquele filho, responde o status dele, ou -errno | estavel |
| `os_kill(pid, sig)` | envia o sinal: 0, ou -errno (-3, ESRCH: processo inexistente). O sinal 0 so verifica se o processo existe | estavel; o Windows encerra um filho deste processo (qualquer sig diferente de 0, informado pelo wait como aquele sinal) ou o proprio processo |
| `os_sleep_ms(ms)` | dorme ms milissegundos, responde 1 (`0` volta na hora) | estavel; um ms negativo dorme praticamente para sempre no Linux e volta na hora no Windows |
| `os_last_timed_out()` | 1 quando o ultimo `os_run_capture_timeout` / `os_run_input_capture_timeout` matou o filho, 0 quando ele terminou a tempo; os outros lancadores nao o alteram | estavel; leia logo depois da chamada (veja a nota abaixo) |
| `os_last_child_maxrss_kb()` | o pico de memoria residente, em KiB, do ultimo filho esperado por `os_run*`, `os_waitpid_status` (0 antes de qualquer um) | estavel; o Linux informa 0 para um filho pequeno (um programa Lume mediu 0, um filho Python de 50 MB 58468); o Windows informa o pico do working set do filho |

Pipes e memoria compartilhada (estavel): `os_pipe_new()` cria um pipe e responde `rfd * 10000 + wfd` (ponta de
leitura `p / 10000`, de escrita `p % 10000`; as duas pontas sao herdadas pelos filhos de `os_fork` e, no Windows,
pelos programas que eles executam). `os_pipe_write_int(fd, n)` escreve n como 8 bytes e responde 1 (tambem quando a
escrita falha). `os_pipe_read_int(fd)` le 8 bytes (uma leitura, bloqueando ate chegar dado) e responde o inteiro; no
fim do arquivo ou num erro responde o que estava no espaco de 8 bytes do runtime, entao envie antes uma contagem ou um
sentinela. `os_shm_map(n)` mapeia n bytes de memoria de leitura/escrita compartilhada com todo filho que `os_fork`
iniciar depois e responde o endereco (-22 para n = 0, -errno na falha); o endereco e para codigo `--raw` e chamadas de
sistema, `buf_shared(n)` e a mesma memoria como buffer. Nao existe em imagens de kernel `@freestanding`.

io_uring (experimental): `os_io_uring_setup(entradas, flags)` responde um descritor de anel ou -errno (-22 para 0
entradas; -38 ou -1 onde o kernel desativa o io_uring); `os_io_uring_enter(fd, submeter, esperar)` submete ate
submeter entradas e, com esperar > 0, espera esse numero de conclusoes; responde quantas submeteu ou -errno (-9: nao e
um anel); `os_io_uring_register(fd, opcode, nargs)` passa um argumento nulo e responde o que o kernel responde (-14
para o opcode 0). Nenhum builtin mapeia os aneis, entao um programa Lume pode criar, entrar e fechar um anel
(`net_close(fd)`) mas nao preencher as filas: servem para sondar o kernel. Linux: as chamadas de sistema reais;
Windows: uma emulacao que valida o setup (1..32768 entradas) e responde como o Linux 6.18, em que enter nao submete
nada e, se pedido para esperar, bloqueia para sempre.

O runtime guarda o ultimo status de wait, `os_last_timed_out()` e os inteiros do pipe na area de rascunho de 32 bytes
que `print` usa para escrever numeros: imprimir um inteiro de 9 ou mais digitos, ou chamar `os_pipe_new()`, entre um
lancamento com timeout e `os_last_timed_out()` muda o que ele responde. De nome a resposta com `let` logo depois da
chamada.

```lume
print os_setenv("LUME_REF_VAR", "on")
print os_getenv("LUME_REF_VAR")
print os_env_has("LUME_REF_VAR")
print os_unsetenv("LUME_REF_VAR")
print os_env_has("LUME_REF_VAR")
let pid = os_fork()
let w = if pid == 0 then os_exit(7) else 0
print os_waitpid_status(pid)
print os_run("/no/such/tool", Nil)
```
```output
1
on
1
1
0
1792
32512
```

```lume
let p = os_pipe_new()
let pid = os_fork()
let w = if pid == 0 then os_exit(os_pipe_write_int(p % 10000, 42)) else 0
print os_pipe_read_int(p / 10000)
print os_waitpid_status(pid)
```
```output
42
256
```

Rede (estavel): `net_udp_bind_addr(ip, porta)` (socket, -1 na falha), `net_udp_send_to(fd, ip, porta, dados)`
(bytes enviados), `net_udp_recv_from(fd, max)` (o datagrama, `""` sem nada), `net_last_peer_ip()`,
`net_last_peer_port()`, `net_tcp_connect_addr(ip, porta)` (socket, -1 quando recusado), `net_close(fd)`;
`use netctl` acrescenta timeouts e E/S nao bloqueante com epoll.

Sockets locais e epoll (estavel; programas hospedados no Linux e no Windows, onde a camada Win64 da aos sockets
Winsock os mesmos numeros e respostas; efeito `net`, epoll `io`). As formas que recebem so a porta usam 127.0.0.1;
a porta e usada modulo 65536, sem verificacao. Uma falha responde um numero negativo: -1 onde indicado, senao o erro
do sistema negado (`-9` descritor fechado, `-17` fd ja observado).

| Builtin | Resposta |
| --- | --- |
| `net_tcp_listen(porta)` | socket TCP escutando em 127.0.0.1:porta (reuso de endereco ligado, fila de 8), ou -1 (porta ocupada) |
| `net_tcp_listen_addr(ip, porta)` | o mesmo no endereco IPv4 (`"0.0.0.0"`, `"127.0.0.1"`) ou IPv6 (`"::1"`) ip, fila de 128; -1 com endereco malformado, porta fora de 0..65535 ou bind que falha (o socket e fechado) |
| `net_tcp_connect(porta)` | socket TCP conectado a 127.0.0.1:porta, ou -1 quando recusado |
| `net_tcp_accept(fd)` | o socket da proxima conexao no fd que escuta (espera uma), ou erro negativo (Linux `-9` com fd fechado, Windows `-88`) |
| `net_send_str(fd, s)` | escreve os bytes de s; responde quantos escreveu, ou erro negativo (`-9` fechado) |
| `net_recv_str(fd, max)` | uma leitura de no maximo 4095 bytes (max nao e usado: toda chamada le ate 4095); `""` no fim do fluxo ou num erro |
| `net_shutdown_write(fd)` | encerra o sentido de envio (o outro lado le fim de fluxo); responde sempre 1 |
| `net_udp_bind(porta)` | socket UDP ligado a 127.0.0.1:porta, ou -1; um segundo bind numa porta em uso funciona no Linux (reuso de endereco) e responde -1 no Windows |
| `net_udp_sendto(porta, s)` | envia s como um datagrama para 127.0.0.1:porta a partir de um socket novo, que depois fecha; responde os bytes enviados (mesmo sem receptor) |
| `epoll_create_fd()` | um descritor epoll novo (feche com `net_close`), ou erro negativo |
| `epoll_add_in(ep, fd, dado)` | observa a entrada de fd, por nivel; dado (qualquer int) e o que `epoll_wait_one` responde para ele; 0, ou erro negativo (`-17` ja observado, `-9` fd invalido) |
| `epoll_wait_one(ep, ms)` | espera ate ms milissegundos (-1 = sem limite, 0 = so consulta) e responde o dado de um fd pronto, 0 no timeout ou num erro (por isso use dado diferente de 0); fim de fluxo conta como pronto |

```lume
let l = net_tcp_listen(47540)
let c = net_tcp_connect(47540)
let a = net_tcp_accept(l)
print net_send_str(c, "ping")
let ep = epoll_create_fd()
print epoll_add_in(ep, a, 7)
print epoll_wait_one(ep, 1000)
print net_recv_str(a, 4096)
print net_shutdown_write(c)
print net_recv_str(a, 4096) == ""
print net_close(a) + net_close(c) + net_close(l) + net_close(ep)
print net_tcp_connect(47541)
```
```output
4
0
7
ping
1
1
4
-1
```

Primitivas de criptografia (estavel; as rotinas de volume de `lcrypto_tls`, ligadas ao programa so quando ele cita
uma delas; chaves, nonces e pontos sao strings de bytes, little endian como nas RFCs). Uma chave de tamanho errado,
uma saida que nao e buffer (`buf_new`) ou um intervalo fora dos dados para o programa com saida 3 e uma linha
`lume: crypto: ...`; X25519 e Ed25519 falham fechados.

| Builtin | Resposta |
| --- | --- |
| `crypto_x25519(k, u)` | X25519 da RFC 7748 (k ajustado, u a coordenada u de 32 bytes; tempo constante): 32 bytes; k ou u sem 32 bytes da 32 bytes zero. Chave publica: u = `chr(9)` + 31 bytes zero |
| `crypto_ed25519_base(s)` | o ponto Ed25519 empacotado [s]B da RFC 8032 para o escalar s de 32 bytes little endian (tempo constante): 32 bytes; outro tamanho da 32 bytes zero |
| `crypto_ed25519_vpt(pk, k, s)` | o ponto empacotado [s]B + [k](-A), A o ponto empacotado em pk (tempo variavel: as entradas sao publicas); uma assinatura (R, S) e valida quando ele e igual a R. `""` quando pk nao e ponto ou um argumento nao tem 32 bytes |
| `crypto_chacha20_xor(saida, dados, chave, nonce, contador)` | ChaCha20 da RFC 8439 (chave de 32 bytes, nonce de 12, contador de bloco de 32 bits): escreve dados XOR o fluxo de chave nos bytes 0..count(dados)-1 do buffer saida (os seguintes ficam como estavam) e responde saida; para quando saida e menor que dados |
| `crypto_poly1305(chave, msg)` | a etiqueta Poly1305 de 16 bytes da RFC 8439 para a chave de uso unico de 32 bytes |
| `crypto_sha256_blocks(estado, dados, de, ate)` | roda a compressao SHA-256 (FIPS 180-4) sobre os bytes de..ate-1 de dados, um numero inteiro de blocos de 64 bytes (de = ate nao faz nada), no buffer estado (pelo menos 32 bytes: as oito palavras H0..H7, cada uma um int de 32 bits little endian) no lugar, e responde estado; o preenchimento e o resumo final big endian ficam com quem chama (`lcrypto_tls` faz os dois) |

```lume
fn hd(n) = slice("0123456789abcdef", n, n + 1)
fn hex(s, i) = if i >= count(s) then "" else hd(ord_at(s, i) / 16) + hd(ord_at(s, i) % 16) + hex(s, i + 1)
fn zeros(n) = if n == 0 then "" else chr(0) + zeros(n - 1)
let nine = chr(9) + zeros(31)
print hex(crypto_x25519(nine, nine), 0)
print hex(crypto_ed25519_base(chr(1) + zeros(31)), 0)
print count(crypto_poly1305(zeros(32), "msg"))
let out = crypto_chacha20_xor(buf_new(3), "abc", zeros(32), zeros(12), 0)
print hex(buf_to_str(out, 0, 3), 0)
```
```output
422c8e7a6227d7bca1350b3e2bb7279f7897b87bb6854b783c60e80311ae3079
5866666666666666666666666666666666666666666666666666666666666666
16
17da83
```
Formas de loopback e chamadas de sistema (as mesmas respostas no Linux e no Windows): `net_tcp_listen(porta)`,
`net_tcp_connect(porta)`, `net_udp_bind(porta)` (127.0.0.1; um socket, ou -1 quando a porta esta fora de 0..65535 ou
um passo falha, e entao o socket e fechado; uma porta UDP ja ligada e recusada), `net_udp_sendto(porta, dados)`
(bytes enviados, -1 com porta ou socket ruim), `net_recv_str(fd, max)` (no maximo `max` bytes, limitado a 1..65536;
`""` num erro ou no fim), `net_send_str(fd, dados)`, `net_tcp_accept(fd)` (um socket, ou menos o errno do Linux: -9
para descritor nao aberto, -88 para um que nao e socket), `net_shutdown_write(fd)` (1, ou -1). `epoll_create_fd()`,
`epoll_add_in(ep, fd, dado)` (0 ou menos o errno), `epoll_wait_one(ep, ms)` (o `dado` de um descritor pronto, -1
quando o timeout expira, -2 num erro; use dados nao negativos). `os_pipe_new()` (`rfd * 10000 + wfd`, ou -1 quando
pipe falha ou um descritor e 10000 ou mais), `os_pipe_write_int(wfd, n)` (1, ou -1 quando os 8 bytes nao sao
escritos), `os_pipe_read_int(rfd)` (o inteiro, ou -1 no fim dos dados ou num erro: envie -1 so como marca de parada).
`os_sleep_ms(ms)` (1; `ms` negativo ou zero volta na hora). `os_setenv(nome, valor)` / `os_unsetenv(nome)` acham a
entrada antiga como `os_getenv`: exatamente, e no Windows sem distinguir maiusculas ASCII. `printval(v)` imprime `v`
e uma quebra de linha e responde `v`. `utf8_chr(n)` com n <= 0, um surrogate ou n > 0x10FFFF e uma parada de
execucao (stderr, saida 3, capturavel). `mem_crc64(endereco, tamanho)` e o hash FNV-1a de 64 bits (base
14695981039346656037, primo 1099511628211, com wrap) como inteiro de 64 bits com sinal (um hash de 2^63 ou mais fica
negativo). `krn_slot_write(i, v)` / `krn_slot_read(i)`: tabela propria de 1024 posicoes (`i` modulo 1024; 0 numa
posicao nunca escrita). `simd_add4_i64(a, b)` / `simd_sub4_i64(a, b)`: quatro lanes iguais de 64 bits de `a + b` /
`a - b` somadas, isto e `4 * (a op b)` modulo 2^64 com sinal (SSE2, toda CPU x86-64); `simd_xor4_i64(a, b)` e uma
lane, `a xor b`. Builtins que exigem ring 0 (I/O de porta, MSRs, cli / sti / hlt, CR3,
invlpg, a IDT, interrupcoes, boot de AP, troca de tarefa, `vga_*`) sao recusados num programa hospedado com
[K0007].

## 7. Modulos da biblioteca padrao

| Modulo | O que oferece | Estado |
| --- | --- | --- |
| `h264` | `buf_h264_luma_mc(ref, ri, rs, rw, rh, x, y, mx, my, w, h, dst, di, ds)` (luma em 1/4 de amostra, 6 taps, 8.4.2.2.1), `buf_h264_chroma_mc(...)` (mesmos argumentos, croma bilinear em 1/8, 8.4.2.2.2), `buf_h264_deblock_edge(buf, q0, across, along, lines, bs, alpha, beta, tc0, chroma)` (8.7.2.3 / 8.7.2.4; bs e tc0 sao listas, um valor por 4 linhas de luma / 2 de croma); 0, ou -1 com argumento errado; coordenadas presas a figura | estavel |
| `hash` | `crc32`, `adler32`, `md5`, `sha1`, `sha224`, `sha256`, `sha384`, `sha512` (strings; `*_buf` para buffers), `hash_hex` / `hash_raw(nome, s)`, `hmac_md5` / `hmac_sha1` / `hmac_sha256` / `hmac_sha384` / `hmac_sha512(chave, msg)` e `hmac_hex` / `hmac_raw(nome, chave, msg)` (RFC 2104), `pbkdf2_sha256` / `pbkdf2_hex` (RFC 8018), `crc32c`, `fnv1a32`, `fnv1a64` (16 digitos hex), `hex32`; conferidos com os vetores da FIPS 180-4 e das RFC 4231 / 2202 / 2104 / 7914 / 6070 | estavel |
| `encoding` | `hex_encode` / `hex_decode`, `base64_encode` / `base64_decode` (RFC 4648 secao 4, preenchimento e bits finais estritos), `base64url_encode` / `base64url_decode` (secao 5, preenchimento opcional), `base64_decode_mime` (ignora espacos e quebras); os decodificadores respondem `{ok, bytes}` | experimental |
| `json` | `json_parse(texto)` -> `{ok, value, err, pos, line, col}` (RFC 8259 estrita: gramatica dos numeros, todos os escapes, pares substitutos `\u`, substituto isolado e UTF-8 malformado recusados, profundidade 512), valores `{k, s, items, fields}` (numeros guardam o texto exato), `json_get` / `json_has` / `json_at` / `json_len` / `json_keys` / `json_pointer` (RFC 6901), `json_str` / `json_int` / `json_f64` / `json_bool` / `json_is_null`, construtores `jv_*`, `json_set` / `json_remove` / `json_push`, `json_write` / `json_write_ascii` / `json_pretty` / `json_quote` | experimental |
| `csv` | `csv_parse(texto)` (RFC 4180: aspas, separadores e quebras de linha dentro de campos), `csv_format(linhas)`, `csv_parse_sep` / `csv_format_sep`, `csv_parse_checked` / `csv_parse_checked_sep` (estrita: `{ok, rows, err, line}` com aspas sem fechar ou texto depois da aspa de fechamento), `csv_field`, `csv_index` / `csv_get(cabecalho, linha, nome)` | estavel |
| `utf8` | `utf8_len`, `utf8_decode` / `utf8_encode` / `utf8_encode_cp`, `utf8_char`, `utf8_cp`, `utf8_slice`, `utf8_offset`, `utf8_next` / `utf8_fold` (percorre por ponto de codigo sem lista), `utf8_valid` / `utf8_check` (posicao do primeiro byte malformado) / `utf8_sanitize` (U+FFFD), `utf8_to_utf16` / `utf8_from_utf16`, `utf8_upper` / `utf8_lower` (ASCII, Latin-1, Latin Extended-A, grego, cirilico), `utf8_reverse` (strings sao bytes; estas contam caracteres) | estavel |
| `datetime` | `dt_from_unix`, `dt_to_unix`, `dt_iso`, `dt_parse_iso`, `dt_parse` (ISO 8601 / RFC 3339 nas formas estendida e basica, nanossegundos, o deslocamento escrito), `dt_format(t, desl, padrao)` (subconjunto do strftime), `dt_weekday`, `dt_yday`, `dt_iso_week`, `dt_add_days` / `dt_add_months`, `dt_offset(fuso, t)` / `dt_local` / `dt_iso_local` (deslocamentos fixos, horario de verao EUA / UE / Sydney) | estavel |
| `tz` | `tz_zone(spec)`: deslocamento fixo, regra TZ POSIX (`EST5EDT,M3.2.0,M11.1.0`, datas Jn / n / Mm.w.d) ou nome IANA lido do tzdata; `tz_load(nome)` (arquivos TZif, RFC 8536 versoes 1-4, a regra do rodape; `$TZDIR`, `/usr/share/zoneinfo`, ...), `tz_from_tzif(bytes, nome)`, `tz_offset`, `tz_abbr`, `tz_is_dst`, `tz_local`, `tz_iso`, `tz_from_local` (lacunas e sobreposicoes resolvidas) | experimental; o Windows nao tem tzdata: la o `tz_load` precisa de `TZDIR` (deslocamentos fixos e regras POSIX funcionam em todo lugar) |
| `regex` | `re_match`, `re_search`, `re_find`, `re_find_all`, `re_find_all_groups`, `re_groups`, `re_named`, `re_group_names`, `re_replace` (`$1`), `re_split`: classes (faixas entre comprimentos UTF-8 diferentes), `\d \w \s`, `\xHH`, ancoras, `\b \B`, grupos, grupos nomeados `(?<n>...)`, retrorreferencias `\1`..`\9`, lookahead `(?=...)` `(?!...)`, alternancia, quantificadores gulosos e preguicosos, `(?i)` (ASCII); casamento com retrocesso (sem lookbehind) | estavel |
| `deflate` | `inflate_buf` (recusa o que o zlib recusa), `deflate_level(b, off, n, level)` (o algoritmo e os parametros do zlib nos niveis 1-9: cadeias de hash, busca preguicosa a partir do nivel 4, um bloco a cada 16383 simbolos escrito no menor entre armazenado / Huffman fixo / Huffman dinamico; 0 = armazenado), `deflate_buf` (nivel 6), `zlib_decompress` / `zlib_compress` / `zlib_compress_level`, `gunzip` / `gzip` / `gzip_level`, `gunzip_str` / `gzip_str` (Adler-32 / CRC-32 conferidos); tamanhos a 0,1 % do zlib no mesmo nivel | estavel |
| `zstd` | `zstd_decompress(b, n)` -> `{ok, buf, n, err}` (RFC 8878: todo quadro, blocos crus / RLE / comprimidos, Huffman e FSE, offsets repetidos, quadros pulaveis e concatenados, tamanho do conteudo e checksum XXH64 conferidos; dicionarios recusados), `zstd_compress_level(b, n, level)` / `zstd_compress` (nivel 3: um quadro com o tamanho do conteudo e o checksum, blocos crus / RLE / comprimidos de ate 128 KiB; o `zstd -d` le), `zstd_decompress_str` / `zstd_compress_str`, `xxh64_buf` / `xxh64` -> `{hi, lo}`, `xxh64_hex` | estavel |
| `http` | `http_get`, `http_post`, `http_request(metodo, url, cabecalhos, corpo, ms)`, `http_header`: chunked, gzip, redirecionamentos, prazos; `https://` pelo `tls` | estavel |
| `tls` | `tls_request(host, porta, dados, ms)`: cliente TLS 1.3 (X25519, AES-128-GCM / ChaCha20-Poly1305); o certificado do servidor e conferido contra as raizes do sistema (`SSL_CERT_FILE`, o pacote do Linux, os repositorios do Windows pelo `lchameleon`) e o nome do host | estavel |
| `tlspki`, `bignum` | RSA (PKCS #1 v1.5, PSS), ECDSA P-256 / P-384, SHA-384 / SHA-512, parse X.509 e validacao de cadeia, PEM; inteiros de qualquer tamanho com `bn_modexp` de Montgomery | estavel |
| `seq` | `seq_map`, `seq_filter`, `seq_fold`, `seq_loop(a, b, acc, f)` (laco sobre a..b-1 sem lista), `seq_while`, `seq_nth`, `seq_range`, `seq_concat` | estavel |
| `arena` | `heap_stats()`, `gc_collect()`, `gc_count()`, `arena_new / alloc / reset / destroy` | estavel |
| `netctl`, `dns` | TCP com timeout, sockets nao bloqueantes, epoll, DNS | estavel |
| `tun` | interfaces TUN: `tun_open`, `tun_read`, `tun_write`, `tun_wait`, `tun_set_ipv4`, `tun_set_mtu`, `tun_set_up`, `tun_close` | linux + windows, privilegiado; no Windows o Wintun so entra pelo `lchameleon` |
| `lchameleon` | fronteiras externas: `chameleon_c_open(caminho)` (Windows: DLL assinada dentro de System32 / Program Files), `chameleon_c_sym`, `chameleon_c_call` (devolvem `unverified[int]`), `chameleon_verify_boundary` | `chameleon_c_*`: windows; guardas: estavel |
| `winsys` | monitores, captura, entrada, janelas, area de transferencia, foco, arrastar-e-soltar, registro, servicos, sessoes, named pipes | windows |
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

## 7a. Builtins freestanding e de hardware

Estes builtins sao para kernels `@freestanding` (anel 0, iniciados pela imagem que o `lasm` escreve) e para codigo
de runtime e de biblioteca de baixo nivel. Todos tem o efeito `sys`, exceto `cpu_rdtsc` (`time`) e
`hw_scratch_addr`, `static_arena_addr`, `static_arena_cap` (puros). Argumentos inteiros sao palavras de maquina; um
endereco e um int comum (num programa hospedado, obtido com `buf_addr(b)`).

Onde rodam: **kernel** = so dentro de um kernel `@freestanding`; num programa hospedado (Linux ou Windows) a
instrucao e privilegiada ou toca memoria fisica que o processo nao tem, e o programa para com
`lume: invalid memory access` e codigo de saida 139, igual nos dois sistemas. **estavel** = funciona tambem num
programa hospedado, igual no Linux e no Windows.

| Builtin | Resposta | Onde |
| --- | --- | --- |
| `cpu_rdtsc()` | o contador de time-stamp (64 bits, `rdtsc`) | estavel |
| `cpu_pause()` | 1, depois de uma dica de espera ativa (`pause`) | estavel |
| `cpu_mfence()` | 1, depois de uma barreira de memoria completa (`mfence`) | estavel |
| `cpu_cli()` / `cpu_sti()` | 1, depois de mascarar / habilitar interrupcoes | kernel |
| `cpu_hlt()` | 1, depois que o processador acorda do `hlt` com uma interrupcao | kernel |
| `cpu_rdmsr(msr)` | o registrador especifico de modelo msr, 64 bits | kernel |
| `cpu_wrmsr(msr, v)` | v, depois de grava-lo em msr (metade alta = v / 2^32) | kernel |
| `cpu_read_cr3()` | CR3 (a raiz das tabelas de pagina) | kernel |
| `cpu_write_cr3(v)` | v, depois de carrega-lo em CR3 (esvazia a TLB) | kernel |
| `cpu_invlpg(va)` | 1, depois de descartar a entrada da TLB da pagina em va | kernel |
| `cpu_idt_init()` | 1, depois de instalar as portas de interrupcao 14 (falta de pagina) e 32 (timer) e carregar a IDT | kernel |
| `cpu_trigger_irq32()` | a contagem de ticks do timer, depois de gerar a interrupcao 32 por software (`int $32`) | kernel |
| `cpu_wait_timer_irq()` | a contagem de ticks do timer, depois de `sti; hlt; cli` (espera uma interrupcao de hardware) | kernel |
| `cpu_irq32_count()` | a contagem de ticks do timer (0 ate a interrupcao 32 rodar) | estavel (0 fora de um kernel) |
| `cpu_pf14_count()` / `cpu_pf14_addr()` | faltas de pagina tratadas pelo vetor 14 / o ultimo endereco que faltou (CR2) | estavel (0 fora de um kernel) |
| `cpu_run_2tasks(v)` | 2031 + v: v passa por um anel com spinlock para uma segunda tarefa na pilha dela, que soma 31 e volta (duas trocas de contexto x 1000 + a resposta) | kernel |
| `cpu_smp_boot_ap(v)` | 1012 + 2 x v quando a CPU 1 inicia (INIT + SIPI pelo APIC local, trampolim de 16 para 64 bits em 0x7000; o AP calcula 2 x v + 12 sob um spinlock), 0 quando ela nao responde a tempo | kernel (`qemu -smp 2`) |
| `port_in8(porta)` / `port_in16(porta)` / `port_in32(porta)` | o byte / word / dword lido da porta de E/S | kernel |
| `port_out8(porta, v)` / `port_out16(porta, v)` / `port_out32(porta, v)` | v, depois de escrever os 8 / 16 / 32 bits baixos na porta | kernel |
| `mmio_volatile_read8(a)` / `mmio_volatile_read16(a)` / `mmio_volatile_read32(a)` / `mmio_volatile_read64(a)` | os 1 / 2 / 4 / 8 bytes no endereco a, little endian, sem sinal exceto a leitura de 64 bits; antes vem um `mfence` | estavel |
| `mmio_volatile_write8(a, v)` / `mmio_volatile_write16(a, v)` / `mmio_volatile_write32(a, v)` / `mmio_volatile_write64(a, v)` | v, depois de gravar os 1 / 2 / 4 / 8 bytes baixos em a, e entao `mfence`; um endereco em 32768..262143 (o texto do kernel) nao e escrito: um literal e o erro [K0005] dentro de uma funcao, um calculado e ignorado | estavel |
| `mem_set(a, byte, n)` | n, depois de escrever os 8 bits baixos de byte em n bytes a partir de a (nada quando n <= 0) | estavel |
| `mem_copy(dst, src, n)` | n, depois de copiar n bytes para frente, um por vez (nada quando n <= 0) | estavel |
| `mem_crc64(a, n)` | o hash FNV-1a de 64 bits dos n bytes em a, como int com sinal (nao e um CRC) | estavel |
| `atomic_xadd64(a, d)` | o valor antigo da palavra de 64 bits em a, depois de somar d a ela atomicamente (`lock xadd`) | estavel |
| `spinlock_acquire(a)` / `spinlock_release(a)` | 1, depois de pegar (laco de `xchg` com `pause`) / soltar (grava 0) a palavra de trava em a | estavel |
| `krn_slot_write(i, v)` / `krn_slot_read(i)` | v / o valor guardado no slot i mod 1024 (0 quando nunca escrito) de uma tabela que nao usa heap | estavel, veja a nota |
| `hw_scratch_addr()` | o endereco da area de rascunho de 8 KiB por tras dos slots | estavel |
| `static_arena_addr()` / `static_arena_cap()` | o endereco / o tamanho (65536) de uma area estatica zerada de 64 KiB | estavel |
| `vga_puts(linha, col, attr, s)` | 1, depois de escrever s com a cor attr na tela de texto 80x25 em 0xB8000 | kernel |
| `vga_fill_row(linha, attr, ch)` | 1, depois de preencher uma linha com o caractere ch | kernel |
| `vga_scroll_up(topo, fim, attr)` | 1, depois de subir uma linha as linhas topo+1..fim e limpar a linha fim | kernel |
| `vga_set_cursor(linha, col)` | 1, depois de mover o cursor de hardware (portas CRT 0x3D4 / 0x3D5) | kernel |
| `sys_call(nr, a1, a2, a3, a4, a5)` | a chamada de sistema nr com os numeros do Linux x86-64 (sexto argumento 0); a resposta crua, -errno na falha (-38 para um numero desconhecido); no Windows o runtime responde aos mesmos numeros; um argumento nao inteiro para (`lume: type error: this needs an integer`); em codigo de runtime `--raw` e um intrinseco sobre palavras cruas | estavel, nao num kernel |

Notas: os slots de `krn_slot_write` / `krn_slot_read` dividem a area de rascunho que o proprio runtime usa nos builtins de espera,
processos, rede e SIMD, entao num programa hospedado so os slots 160..1023 guardam o valor atraves dessas chamadas
(um slot baixo pode ser sobrescrito, e le-lo depois pode parar o programa). Portas de interrupcao, pilhas de tarefa
e a caixa de correio SMP ficam em enderecos fisicos baixos e fixos da imagem do kernel. A partida do kernel programa
a COM1 para o `print`, e um kernel termina pela porta isa-debug-exit 0xF4 e `cli; hlt`.

```lume
let b = buf_new(24)
let a = buf_addr(b)
print mem_set(a, 65, 3)
print mem_copy(a + 8, a, 3)
print buf_to_str(b, 8, 3)
print atomic_xadd64(a + 16, 5)
print atomic_xadd64(a + 16, 2)
print mmio_volatile_read8(a + 16)
print krn_slot_write(1000, 42)
print krn_slot_read(1000)
print static_arena_cap()
```
```output
3
3
AAA
0
5
7
42
42
65536
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

Entrou: `use std/zstd` (decodificador e codificador Zstandard, XXH64), `deflate_level` / `zlib_compress_level` / `gzip_level` (niveis 1-9 do zlib), entradas para todo builtin que um programa pode chamar (arquivos, arquivos so do dono, o chaveiro do sistema, entrada padrao, ambiente, processos, pipes, memoria compartilhada, io_uring, TCP / UDP e epoll, primitivas de criptografia, try / fail, vetores de bits, tempo constante, SIMD, as formas empacotadas do h264, builtins freestanding e de hardware), `use std/json` (parser RFC 8259 estrito e escritores, JSON Pointer), `use std/tz` (tzdata TZif e regras TZ POSIX), `use std/encoding` (hex, base64, base64url), `sha224` / `sha384` / `sha512`, HMAC, PBKDF2, `crc32c`, `fnv1a32` / `fnv1a64`, `dt_parse`, `dt_format`, `dt_yday`, `dt_iso_week`, `csv_parse_checked`, `csv_index` / `csv_get`, `utf8_next` / `utf8_fold` / `utf8_check` / `utf8_sanitize` / `utf8_offset` / `utf8_encode_cp` / `utf8_to_utf16` / `utf8_from_utf16`, regex `\b \B`, retrorreferencias, lookahead, grupos nomeados, `(?i)`, `\xHH`, `re_named`, `re_group_names`, `re_find_all_groups`, blocos Huffman dinamicos e armazenados no `deflate_buf`, `lume debug --dap` (o depurador pelo Debug Adapter Protocol), `buf_h264_mb_i4`, `buf_h264_mb_i16`, `buf_h264_mb_ic`, `buf_h264_mb_p`, `buf_h264_mb_pc`, `buf_h264_cavlc_luma` / `chroma` (macroblocos Intra4x4, inter luma e inter croma inteiros numa chamada), `buf_h264_me16` (busca de movimento), a tabela de todos os codigos de diagnostico (secao 3a) e exemplos de diagnostico para 68 codigos, `use std/hash`, `csv`, `utf8`, `datetime`, `regex`, `deflate`, `http`, `tls` (HTTPS com TLS 1.3), `tlspki`, `bignum`, versoes de pacotes (`lume pkg publish / add / install`, `[packages]` no lume.lock), `lume verify` (muitos arquivos, N processos, cache por arquivo), a pilha de chamadas (`at NOME (arquivo:LINHA)`) depois de um erro em tempo de execucao, contratos dos builtins no provador (`buf_bits_write`, `buf_get`, `buf_len`, `count`, `buf_sad*`, `buf_satd*`, `buf_h264_quant4x4`), exemplos oficiais (`examples/topics`, `examples/diagnostics`, gate dos exemplos), `use std/NOME`, `buf_bits_write / read / ue / se`, `## Deprecated:` e o aviso [W0005], docs/STABILITY.md (semver, obsolescencia, LTS 1.2), `use math` (funcoes matematicas, f32, buffers f32), parametros f64, W0004, `lume run --profile`, `use h264` (compensacao de movimento, desbloqueio), `buf_sad*`, `buf_satd*` (SSE2), `buf_h264_*`, `use tun`, `lchameleon` `chameleon_c_open / sym / call` e
`chameleon_verify_boundary`, `priv fn`, aviso [W0003], `LUME_FL`, literais constantes em .rodata, cache de campo por
ponto de leitura, ritmo de coleta `max(8 MiB, 3 x vivo)`.
Mudou: `deflate_buf` segue o nivel 6 do zlib (busca preguicosa, um bloco a cada 16383 simbolos) e `inflate_buf` recusa codigos superinscritos e incompletos e mais de 286 / 30 codigos; `dt_parse_iso` recusa texto depois do fuso; `utf8_encode` escreve U+FFFD para um substituto ou valor fora da faixa e um byte NUL para 0 (antes parava); `utf8_upper` / `utf8_lower` tambem mapeiam Latin Extended-A, grego e cirilico; o `csv_parse` tolerante mantem no campo o texto depois da aspa de fechamento (antes comecava outra linha); faixas de classe do regex funcionam entre comprimentos UTF-8 e um casamento vazio no fim nao para mais o `re_find_all`; o [E0305] deixa com o remetente um int ou bool copiado para dentro ou para fora do registro enviado; um delimitador ainda aberto no fim do arquivo e [P0001] (era [P0002]); exemplos de `lume agent kernel` rodam no gate dos exemplos; o W0004 tambem ve parametros `f64` e resultados de `f64(...)`; `buf_sad4x4` roda em SSE2; o C0009 numa funcao `ct_` diz que o motivo e o prefixo; `lume fmt` se recusa a rodar no Stage-0; no Git
Bash o `lume` roda o `lume.exe` nativo; `fs_copy` mantem as permissoes da origem.
Saiu: nada.
