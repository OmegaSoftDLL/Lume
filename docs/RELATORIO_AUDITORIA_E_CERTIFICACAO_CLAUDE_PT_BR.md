# Relatorio Tecnico de Auditoria e Certificacao — Lume v1.1.0 (Ondas 10, 11, 12 e 13)

- **Data da campanha:** 2026-11-11 (WSL2 Ubuntu, `Linux 6.18.33.2-microsoft-standard-WSL2 x86_64`)
- **Autor da auditoria:** Claude (Anthropic), a pedido de Ricardo Bueno
- **Escopo:** fechamento das Ondas 10 a 13, com todos os numeros medidos nesta campanha
- **Pacote gerado e assinado:** [`docs/certification/`](certification/)

> **O que este documento e.** E o relato do que foi construido, executado e medido. Nao e uma certificacao. Uma
> qualificacao de ferramenta (DO-330, IEC 61508, IEC 62304) e concedida por projeto, por autoridade ou avaliador
> independente. Tudo aqui foi executado pelo proprio desenvolvedor da ferramenta. A secao 9 lista os limites.

## 1. Resultado em uma pagina

| Item | Resultado medido |
|---|---|
| Bootstrap auto-hospedado | `stage 2 == stage 3` bit a bit; SHA-256 de `lumec`, `lumec2` e `lumec3`: `dfe2e624b020a3635bdfa004775571f025266fdd6bce8a34ee947fd001897adf` |
| `lume self-prove --json` | `"ok":true`; 1677 obrigacoes em 13 baterias certificadas; `obligations_runtime_checked_or_refuted: 0`; 338 testes unitarios; 70 funcoes de `lstd.src` validadas por traducao |
| `lume qualify` (campanha completa, sem `@quick`, sem `@skip-gates`, 1620 s) | **`Result of this run: PASS`** |
| Sondas | 70 de 70 |
| Gates dentro da qualificacao | 16 de 16 |
| Requisitos | 9 de alto nivel, 31 de baixo nivel, 31 totalmente rastreados; **`Traceability matrix: VERIFIED`** (0 sem rastro, 0 sem filho, 0 teste sem citacao; controle negativo do verificador: PASS) |
| `ltv` nos 4 modulos certificados | 691 funcoes validadas, **0 rejeitadas**, 3 fora do fragmento, 7794 vetores nativos concordando |
| Estado das provas nesses modulos | 665 provadas, 416 por orcamento (`@bound`), **0 `runtime_checked`, 0 `refuted`** |
| MC/DC total | 9538 obrigacoes: 8605 cobertas, 863 teorema-falso, 48 inviaveis (provadas), 22 nao cobertas |
| MC/DC `lstd.src` | 972 obrigacoes, 924 cobertas, 46 teorema-falso, 2 inviaveis, **0 nao cobertas** |
| MC/DC `critical_kernels.src` | 112 obrigacoes, 112 cobertas, **0 nao cobertas** |
| Evidencia | encadeada por SHA-256 e assinada com Ed25519; `lume qualify --verify`: `ok: true`, chave do repositorio confere |
| Gates fora da qualificacao | todos com `rc=0` (secao 4) |
| Evolver 24/7 | atualizado para 122 dominios, com guardas de disco e de memoria, compilado e testado; **parado**, por ordem do proprietario |

As 22 obrigacoes MC/DC nao cobertas estao todas em `lsentience.src`, que nao pertence ao conjunto qualificado para
MC/DC. Elas continuam abertas e estao listadas em `QUALIFICATION_EVIDENCE.json` (`uncovered_list`).

## 2. O que cada onda entregou

### Onda 10 — garantia independente

- `lasm` contra o GNU `as`: 39.968 linhas de instrucao em 21 familias, byte a byte identicas; 1.467 codificacoes
  alternativas conferidas por desmontagem; 176 linhas invalidas rejeitadas com `[L0001]`.
- Fuzzer de teoremas falsos (`prover_fuzz_gate`): 1.570 teoremas falsos barrados pelo cheque em runtime, 203 refutados
  em compilacao, **0 provados** por `lumec`, `lcaas` ou pelo kernel `lcert`. Uma campanha fixa e outra com semente
  nova de `/dev/urandom` a cada execucao, em 6 dominios (inteiros, records, arrays, separacao, quantificadores, leis).
- `claude_audit_gate`: fuzzer diferencial de 4 vias, mutantes de programa e 6 mutantes do compilador mortos,
  compilacao dupla diversa (semente em C contra o compilador auto-hospedado) bit a bit identica.

### Onda 11 — ferramentas de certificacao (Dominios `#112..#115`)

- **`ltv`**: executa simbolicamente a AST rebaixada e o x86-64 emitido de cada funcao inteira e so aceita quando os
  dois chegam a `ctfail` nos mesmos casos, devolvem o mesmo valor, fazem as mesmas divisoes e chamadas e respeitam o
  frame. `tv_gate`: 1.126 mutantes de codigo, 602 mudam o comportamento nativo, **602 de 602 rejeitados, 0 aceitacoes
  incorretas**.
- **`lmcdc`**: obrigacoes de decisao e MC/DC por mascaramento, cada testemunha executada no binario real.
- **`lsafety_envelope` (LumePuter, arquitetura `2oo2D`)**: o canal A e o x86-64 nativo; o canal B e o mesmo kernel
  compilado para RV32IM por um segundo compilador e executado no interpretador LumePuter. O valor so sai como
  `VerifiedActuatorCommit` quando os dois canais terminam, dentro do orcamento de ciclos, com a mesma palavra e com
  certificado `ltv` valido. Qualquer outro caso trava `SAFE_STATE_TRIP` ate `--reset`. No `self-prove`:
  `infusion_dose_clamp(700, 500)` liberou 500 em 99 ciclos RV32IM, de um orcamento de 512. `safety_envelope_gate`:
  todas as falhas injetadas viraram trip, 0 falsos negativos.
- **Ledger de soak**: 8 entradas encadeadas, 5.746 execucoes e 13.008 invariantes acumulados.
- **`lqualify`**: descrito na secao 5.

### Onda 12 — ferramentas industriais (Dominios `#116..#121`)

| Dominio | Entrega | Gate | Medido |
|---|---|---|---|
| `#116` | `@no_alloc` (`[E0210]`, transitivo), `--keep-proven-checks` / `--critical` | `realtime_gate` | 7 rejeicoes; 0 alocacoes medidas por `heap_stats()` em 200.000 chamadas e uma recursao de cauda de profundidade 100.000 |
| `#117` | Back ends AArch64, RV64 e RV32 do fragmento de kernel inteiro, com validador proprio | `multi_arch_gate` | codificacoes iguais as do assembler do LLVM; mesmos resultados em x86-64, `qemu-aarch64`, `qemu-riscv64` e LumePuter; mutantes de 1 bit: RV64 6302 de 6368 mortos, os demais provados equivalentes |
| `#118` | Canais lineares (`[E0305]`), ordem de locks e ciclos de espera (`[E0306]`) | `concurrency_gate` | 4 + 4 rejeicoes; 22 obrigacoes e 14 orcamentos provados |
| `#119` | `lcrypto_tls.src`: SHA-256/512, HMAC, HKDF, ChaCha20-Poly1305, Ed25519, X25519, TLS 1.3 | `crypto_tls_gate` | 574 cheques, 275 deles contra vetores oficiais e rejeicoes |
| `#120` | DWARF v4 e cache incremental de provas | `dwarf_cache_gate` | acerto quente de 20 funcoes em 8,6 ms no processo e 12,3 ms por linha de comando (limite: 30 ms) |
| `#121` | Cartuchos neurais `.safetensors` | `safetensors_gate` | 9 funcoes; forward pass igual ao nativo e ao LumePuter; arquivos adulterados rejeitados |

### Onda 13 — fechamento (esta campanha)

Itens que faltavam e foram implementados:

1. **X25519 (RFC 7748) e a maquina de estados do handshake TLS 1.3** em `lcrypto_tls.src`: escada de Montgomery de
   255 passos com trocas mascaradas; estados de cliente e servidor do Apendice A da RFC 8446; 11 transicoes e 44
   rejeicoes fail-closed no gate; handshake completo em memoria com 540 bytes de fio. Os vetores vieram dos textos
   das RFCs e foram conferidos contra o OpenSSL fora do repositorio.
2. **`lcert --check-source`**: o kernel le os contratos do proprio fonte e recusa certificado cujas obrigacoes nao
   sejam as daquele arquivo. `cert_source_gate`: 10 certificados forjados que o kernel simples aceita sao recusados.
   `lstd.src`: **117 de 117 obrigacoes vinculadas**.
3. **`[C0010]` no `tv_gate`**: funcao `@secret` sem desvio validada; a mesma soma aceita em funcao publica e
   rejeitada em funcao secreta; 3 vazamentos injetados (desvio, memoria, divisao) rejeitados.
4. **Front-end do `lumec` antes do rebaixamento multi-ISA**: `[T0902]` quando o `lumec` rejeita o kernel, `[T0903]`
   quando o `lumec` nao e encontrado.
5. **`realtime_gate`**: `@no_alloc` e `--keep-proven-checks` nao tinham nenhum teste.
6. **`lqualify`**: mais 7 gates, 1 requisito de alto nivel, 10 de baixo nivel e 24 sondas; cadeia SHA-256 e assinatura Ed25519 da evidencia; modo
   `@verify`.
7. **Driver**: `lume build --dwarf|-g`, `--keep-proven-checks|--critical`, `--target safetensors`,
   `lume proof-cache`, `lume qualify --verify` e os gates como comandos. A ajuda anunciava essas opcoes antes de o
   driver implementa-las.
8. **Instalador**: binarios, fontes e `stdlib/` das Ondas 11 e 12 instalados e com hash no manifesto.

## 3. Defeitos encontrados e corrigidos nesta campanha

| Defeito | Efeito | Correcao |
|---|---|---|
| `lsentience.src` chamava 7 kernels da Onda 12 com aridade errada | `lsentience` e `lume_driver` nao compilavam (`[R0202]`) | chamadas corrigidas conforme as assinaturas |
| `lcaas.src` tinha perdido `@mode bind-raw` | `lume adapt c --preprocess` falhava; `c_adapter_gate` falhava | codigo restaurado |
| `@no_alloc` e `--keep-proven-checks` sem teste | recurso sem evidencia | `realtime_gate` |
| A ajuda citava `[E0300]` / `[E0301]` para `@no_alloc` | codigo de diagnostico errado no texto | o compilador emite `[E0210]`; textos corrigidos |
| A ajuda anunciava opcoes que o driver nao tinha | comandos documentados inexistentes | implementados e testados |
| Inferencia de efeitos do `lcaas` exponencial na profundidade de chamadas | `lume prove lcrypto_tls.src` levava 180 s e estourava o limite de 120 s do driver | memo por programa: 4 s; saida identica byte a byte em 8 modulos |
| Termo de certificado do `lcaas` capturava variavel | o termo falava da variavel errada quando um `let` do chamado tinha o nome de um parametro do chamador | binder renomeado; regressao no `cert_source_gate` e nas sondas `P-CAP-POS` / `P-CAP-NEG` |
| `lcert --check-source` nao seguia os intrinsecos SIMD | `lstd.src` vinculava 115 de 117 | leitura de `simd_add4_i64` / `simd_sub4_i64` como o `lcaas` os rebaixa |

Sobre a captura de variavel: o veredito do provador nunca foi afetado. O provador de `06b_phase3.src` liga variaveis
por ambiente e nao reescreve `let`; ele refuta o contrato falso do caso de teste com `[V0001]`. O defeito estava
apenas no texto do termo que o `lcaas` gravava no certificado.

## 4. Gates executados (todos `rc=0`)

| Gate | Tempo | Resultado |
|---|---|---|
| `ownership_gate` | 34 s | 70 fixtures de ownership, 48 fail-closed, 54 programas iguais entre `lumec` e `lcaas` |
| `runtime_sync_gate` | 3 s | um unico fonte de runtime, 8 programas iguais |
| `gc_gate` | 20 s | saida identica com o coletor ligado, desligado e sob estresse |
| `c_adapter_gate` | 6 s | geracao, rejeicao, proveniencia e interoperabilidade real |
| `dwarf_cache_gate` | 1 s | DWARF v4 e cache de provas |
| `concurrency_gate` | 1 s | `[E0305]` / `[E0306]` |
| `crypto_tls_gate` | 7 s | 574 cheques |
| `safetensors_gate` | 36 s | 9 cartuchos |
| `lasm_gate` | 14 s | 39.968 linhas identicas ao GNU `as` |
| `realtime_gate` | 1 s | 7 rejeicoes `[E0210]`, 0 alocacoes |
| `cert_source_gate` | 2 s | 10 falsificacoes recusadas; `lstd.src` totalmente vinculado |
| `claude_audit_gate` | 247 s | fuzzer diferencial, mutantes, DDC |
| `safety_envelope_gate` | 110 s | 0 falsos negativos |
| `prover_fuzz_gate` | 120 s | 0 teoremas falsos provados |
| `soak_battle_gate` | 86 s | 498 invariantes, 38 controles negativos |
| `native_driver_gate` | 73 s | driver nativo |
| `native_incremental_gate` | 6 s | build incremental |
| `native_interactive_gate` | 3 s | LSP, DAP, REPL |
| `multi_arch_gate` | 7 s | AArch64 / RV64 / RV32 |
| `capstones_gate` | 3 s | SaaS/WAL e RTC em QEMU |
| `native_make_gate` | 77 s | semente e amalgamacao |
| `lume_make test` | 31 s | suite nativa |
| `tv_gate` | 896 s dentro do `lqualify` | 602 de 602 mutantes rejeitados |

O `tv_gate` nao cabe no limite de 600 s pedido para comandos pesados. Ele rodou com limite maior: 1.659 s em
paralelo com outros gates e 896 s sozinho.

## 5. Qualificacao (`lqualify`)

Arquivos em `docs/certification/`: `TOR_TOOL_OPERATIONAL_REQUIREMENTS.md`, `TQP_TOOL_QUALIFICATION_PLAN.md`,
`RTM_TRACEABILITY_MATRIX.md`, `QUALIFICATION_DOSSIER.md`, `QUALIFICATION_EVIDENCE.json`,
`QUALIFICATION_EVIDENCE.sig.json`, `QUALIFICATION_SIGNING_KEY.pub`.

Modulos certificados (colunas do dossie):

| Modulo | `ltv` validadas / rejeitadas / fora | Provadas / orcamento / runtime / refutadas | MC/DC obrigacoes | Cobertas | Nao cobertas |
|---|---|---|---|---|---|
| `compiler/stage1/lstd.src` | 70 / 0 / 0 | 70 / 47 / 0 / 0 | 972 | 924 | **0** |
| `examples/safety_envelope/critical_kernels.src` | 5 / 0 / 0 | 5 / 5 / 0 / 0 | 112 | 112 | **0** |
| `compiler/stage1/lchameleon.src` | 160 / 0 / 0 | 160 / 96 / 0 / 0 | 2386 | 2112 | 0 |
| `compiler/stage1/lsentience.src` | 456 / 0 / 3 | 430 / 268 / 0 / 0 | 6068 | 5457 | 22 |

Integridade da evidencia:

| Item | Valor |
|---|---|
| SHA-256 de `QUALIFICATION_EVIDENCE.json` | `9a7a62cb0565ed5d64e8662aa6da92e61c96af9ee3a13c5c4cb2ba9a593c6a98` |
| Cabeca da cadeia (sondas, gates, modulos, base confiavel, resumo) | `4d9e69686da5833e1c56ed5e3dbcb5a9deff13a5eef1556f7183f1cb52ec67b3` |
| Chave publica Ed25519 | `6e347b57673e049b11485c85789a6d60edf49a8c3217b73c3c777116c1886b6d` |
| Verificacao apos a gravacao | PASS |
| Copia alterada rejeitada | PASS |

Para reconferir: `./lume qualify --verify`, ou
`printf '@verify %s/docs/certification\n@root %s\n' "$PWD" "$PWD" | build/bin/lqualify`.

A chave privada fica em `/root/.lume/keys/qualification_ed25519.seed`, fora do repositorio, com modo 600. Ela foi
gerada pela propria ferramenta nesta campanha. A assinatura mostra que o detentor desse arquivo produziu a evidencia.
Ela nao e atestado de terceiro.

## 6. Os 122 Dominios Soberanos

- As tabelas de dominios do `lsentience.src` e do evolver foram enumeradas para os ids `0..121`: **122 nomes, 122
  distintos, 0 vazios, 0 diferencas entre as duas tabelas**.
- Os kernels de dominio vivem em `lstd.src` e `lchameleon.src` (espelhados em `stdlib/std.lume`). Estado medido:
  `lstd.src` 117 obrigacoes (70 provadas, 47 por orcamento), `lchameleon.src` 256 (160 provadas, 96 por orcamento),
  **0 `runtime_checked`, 0 `refuted`** em ambos; `lsentience.src` 430 provadas e 268 por orcamento, 119 testes.
- `lume_driver.src`, `lcli.src` e `linteractive.src` citam os dominios em textos de ajuda e de autocompletar; eles
  nao carregam obrigacoes de dominio proprias.
- Dominios novos: `#112` validacao de traducao, `#113` ledger de soak, `#114` qualificacao RTM + MC/DC, `#115`
  envelope lockstep, `#116` `@no_alloc`, `#117` back ends multi-ISA, `#118` concorrencia linear, `#119` tempo
  constante e AEAD, `#120` cache de provas, `#121` cartuchos `.safetensors`.

O que um "dominio provado" significa: cada dominio tem uma pequena funcao de decisao com contrato e leis provados. A
funcao enuncia a regra de aceitacao de uma ferramenta. O comportamento da ferramenta em si e estabelecido pelo gate
dela, nao pelo kernel de dominio.

## 7. Prefixos instalados

Os dois prefixos (`/root/.lume` e `/mnt/c/Users/Ricardo.Bueno/.lume`) foram atualizados por `scripts/install.src`
depois da qualificacao, e `lume self verify` passa em cada um e na arvore do repositorio. Os hashes dos manifestos
estao no resumo final da entrega e no `MANIFEST.sha256` de cada prefixo.

## 8. Evolver 24/7

- Fonte atualizado nos dois locais (`/root/.lume_sovereign_memory/sanctuary/` e
  `/mnt/c/Users/Ricardo.Bueno/.lume/`): 122 dominios, geracoes `4086..4091` assimilam os dominios `#116..#121`, depois
  selecao `gen * 53 % 122`.
- Guardas novas: nenhuma geracao e gravada com menos de 2048 MiB livres em qualquer dos dois volumes, nem com menos
  de 4096 MiB de memoria disponivel.
- Verificado a seco: os modulos das geracoes 4091, 4155 e 4219 foram sintetizados e passaram por `prove` (278
  provadas), `test` (136 de 136), build e execucao (saida 136).
- **O daemon nao foi iniciado**, por instrucao do proprietario. Nenhum processo do evolver esta em execucao.
- Os contadores acumulados que o evolver grava no seu ledger (`laws_proven`, `qflia_obligations_proven`) sao
  calculados por formula a partir do numero da geracao. O que cada ciclo realmente prova e a janela ativa de 64
  geracoes.

## 9. Limites reais

1. **Independencia.** Tudo foi executado pelo desenvolvedor. Nenhuma autoridade revisou o pacote.
2. **`ltv`.** Cobre o fragmento inteiro e execucoes sem trap de overflow i64. Os helpers de runtime sao axiomas,
   conferidos contra a maquina real e pelo gate de mutacao, nao provados. Os certificados Lean 4 e SMT-LIB2 sao
   exportados; so sao checados quando ha solver instalado.
3. **MC/DC.** Medido sobre a AST rebaixada, nao sobre o codigo objeto. 22 obrigacoes de `lsentience.src` seguem
   abertas.
4. **LumePuter.** O canal B e um interpretador RV32IM em software no mesmo host: diversidade de projeto, nao
   independencia fisica. O front-end e comum aos dois canais.
5. **Multi-ISA.** So o fragmento de kernel inteiro. Execucao em emuladores, nao em silicio. A imagem AArch64 bare e
   validada mas nao executada.
6. **`[C0010]`.** Varre as instrucoes da propria funcao `@secret`. Os helpers alcancados por `call` ficam fora.
   Na pratica uma funcao `@secret` com `+` e rejeitada nesse nivel.
7. **Criptografia.** Testada contra vetores oficiais e contra falsificacoes; nao verificada formalmente. Tempo
   constante por construcao no nivel do fonte, sem medicao. TLS 1.3: uma suite, um grupo, chave Ed25519 crua fixada,
   sem X.509, sem PSK, 0-RTT, HelloRetryRequest, certificado de cliente ou KeyUpdate. A aleatoriedade vem do chamador.
8. **`lcert --check-source`.** Vincula o fragmento que o leitor do kernel entende. O resto e `unbound` e o veredito
   nao e ok. A igualdade e sintatica. `simd_add4_i64(a, b) = 4 * (a + b)` e um axioma sobre o helper.
9. **`@no_alloc`.** Zero alocacoes e medido nas chamadas do gate e decorre do cheque estatico. Nao ha calculo de
   profundidade maxima de pilha em bytes nem medicao de tempo.
10. **Cartuchos neurais.** Aritmetica matricial inteira avaliada por esta cadeia. Nada e afirmado sobre motores de
    inferencia em ponto flutuante.
11. **Assinatura.** Chave de desenvolvedor em arquivo, sem hardware e sem certificado de identidade.
12. **`lcaas`.** A copia de analises do compilador dentro do `lcaas` tinha uma inferencia exponencial (corrigida).
    Nao foi feita uma revisao de desempenho das demais passagens.

## 10. Como reproduzir

```sh
./lume amalgamate && ./lume bootstrap
./lume self-prove --json
printf '@root %s\n' "$PWD" | build/bin/lqualify      # cerca de 27 minutos; sem ulimit -v por causa do qemu
./lume qualify --verify
build/bin/native_installer --prefix /root/.lume --from-local "$PWD" && /root/.lume/bin/lume self verify
```
