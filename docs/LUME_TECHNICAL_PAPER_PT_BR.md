# Engenharia de uma Linguagem de Programação Auto-Hospedada com Verificação `QF_LIA` Integrada e Backend Nativo Zero-C

*Notas de projeto sobre a Lume (`v1.0.0`), como atingimos o ponto fixo de bootstrap idêntico bit a bit (`stage2 == stage3`) e a integração de provas de aritmética linear inteira diretamente no verificador de tipos.*

---

A infraestrutura de software moderna impõe uma divisão incômoda na pilha de engenharia.

Quando você precisa de layout de memória previsível, binários independentes enxutos e acesso direto ao hardware — kernels, protocolos de telemetria industrial, motores de armazenamento — você recorre a C, C++ ou Rust. Quando precisa de aritmética decimal exata para livros-razão financeiros, diferenciação automática sobre pipelines de tensores ou iteração rápida com síntese automatizada de código, acaba recorrendo a Python ou TypeScript, abrindo mão de garantias estáticas e pagando o preço de um runtime pesado.

Adicionar verificação formal a código de produção geralmente agrava essa divisão. A maioria dos fluxos de verificação depende de solvers SMT externos invocados fora do processo de compilação. Uma pequena atualização de versão do solver ou uma mudança de heurística de timeout em um runner de CI costuma ser suficiente para transformar uma compilação aprovada em uma falha intermitente.

A **Lume** (`https://github.com/OmegaSoftDLL/lume`) é uma linguagem de programação de código aberto para sistemas e dados, construída do zero para testar uma hipótese específica de engenharia: *pode um único compilador pequeno e auto-hospedado emitir binários nativos de máquina em múltiplas arquiteturas sem uma toolchain C externa, verificar contratos funcionais de forma determinística em tempo de compilação e suportar sistemas bare-metal, dados financeiros e programação diferenciável sob um mesmo sistema de tipos?*

Com a versão `v1.0.0` publicada no GitHub, este artigo documenta as principais decisões arquiteturais, os gargalos de compilação que enfrentamos no caminho e como a cadeia de ferramentas funciona por dentro.

---

## 1. Arquitetura de Bootstrap e o Ponto Fixo `stage2 == stage3`

A maioria das linguagens contemporâneas depende de LLVM, GCC ou do linker do sistema operacional hospedeiro (`ld`, `link.exe`) para traduzir representações intermediárias em executáveis. Isso acelera o desenvolvimento inicial, mas acopla o compilador a centenas de megabytes de dependências externas em C++ e obscurece a base computacional confiável (*Trusted Computing Base*).

A Lume utiliza um bootstrap em três estágios projetado para atingir um **estado estacionário Zero-C**:

1. **Stage 0 (`lume0`):** Um interpretador de referência mínimo escrito em C11 portável com zero dependências de terceiros. Sua única função é avaliar a árvore de código-fonte do compilador na partida a frio (*cold start*).
2. **Stage 1 (`lumec` + `lasm`):** O compilador auto-hospedado (`lumec`) e o montador/linker nativo (`lasm`), ambos escritos em Lume (`compiler/stage1/`). Em vez de chamar `binutils` ou `clang`, o `lasm` codifica diretamente os formatos executáveis byte a byte: `ELF64` (`x86_64-linux`, `aarch64-linux`, `riscv64-linux`), `PE64` (`x86_64-windows` com Tabela de Endereços de Importação `kernel32.dll` nativa), `Mach-O` (`aarch64-macos`), `WASM` (`wasm32-wasi`) e imagens inicializáveis `.kernel` (bootstrap MBR de 16 bits em modo real fazendo transição para modo longo de 64 bits).
3. **Ponto Fixo Auto-Hospedado (`stage2 == stage3`):** O compilador Stage-1 compila sua própria árvore de código-fonte para produzir o `lumec2`. Em seguida, o `lumec2` compila exatamente a mesma árvore de código-fonte para produzir o `lumec3`. Cada execução de CI verifica que `sha256(lumec2) == sha256(lumec3)` com zero bytes de diferença.

Atingir um ponto fixo idêntico bit a bit sem LLVM expôs problemas clássicos de compiladores que backends de alto nível costumam esconder:

- **Extensão de sinal em deslocamento relativo ao PC de 32 bits (`lasm.src`):** Quando o código assembly amalgamado do compilador (`lumec.s`) ultrapassou 128 KB de distância entre alvos de desvio, as relocações `jmp`/`call` para frente e para trás exigiram emissão little-endian de 32 bits com sinal (`emit_i32_le`) e uma tabela de símbolos particionada em 256 buckets de hash (`symhash`), o que reduziu o tempo de montagem nativa em cerca de 5 vezes.
- **Preservação de registradores durante o crescimento do alocador (`05_codegen.src`):** No caminho de concatenação de strings e listas em tempo de execução (`addv`), disparar uma chamada de crescimento de heap (`alloc_grow`) mantendo ponteiros ativos em registradores *caller-saved* sobrescrevia `%rdi` e `%rsi`. Proteger explicitamente o caminho lento salvando na pilha (`pushq %rdi` / `popq %rdi` em `av_ls` e `pushq %rsi` / `popq %rsi` em `av_rs`) eliminou corrupções sutis de heap durante a auto-compilação sem tocar no registrador *callee-saved* `%r15`.
- **De varredura de strings $O(N^2)$ para fatias com tamanho em cache $O(1)$:** As primeiras versões do lexer e do parser construíam tokens concatenando caractere por caractere. Armazenar em cache o comprimento em bytes no deslocamento `8(%rax)` de cada alocação de string (`mkstr`, `cnts`, `slice`, `slicen`) e limitar a descoberta transitiva de funções auxiliares (`kuses_hop` na profundidade `d <= 1`) reduziu o tempo de auto-compilação `lumec2 -> lumec3` de ~240 segundos para **8 segundos**.

---

## 2. Contratos em Tempo de Compilação e Certificados de Prova (`QF_LIA` + Lógica de Separação)

Em vez de tratar anotações `requires` e `ensures` como asserções de tempo de execução, a Lume incorpora um procedimento de decisão de aritmética linear inteira livre de quantificadores (**`QF_LIA`**) e lógica de separação diretamente dentro do passo de análise semântica (`06b_phase3.src`), pareado com um kernel verificador de provas independente (`lcert.src`, ~394 linhas de código).

Aqui está um exemplo mínimo que compila e prova tanto um contrato de função quanto uma lei algébrica:

```lume
fn clamp_non_neg(x: int, limit: int) -> int
  requires limit >= 0
  ensures result >= 0 and result <= limit
{
  if x < 0 {
    0
  } else {
    if x > limit { limit } else { x }
  }
}

law clamp_idempotent(x: int, limit: int)
  requires limit >= 0
  ensures clamp_non_neg(clamp_non_neg(x, limit), limit) == clamp_non_neg(x, limit)
```

Durante `lume check` ou `lume verify`, o compilador executa inferência de tipos Hindley-Milner (com polimorfismo `let` via `Forall`) e constrói condições de verificação negando a cláusula `ensures` sob a conjunção de `requires` e das guardas de desvio sensíveis ao caminho:

- Se existir um contraexemplo, a compilação falha de forma segura (*fail-closed*) com o diagnóstico `[V0001]` e exibe a atribuição concreta de variáveis que viola a pós-condição.
- Se a negação for insatisfatível, o `lcert` emite um certificado de prova determinístico com hash `SHA-256` (FIPS 180-4) e assinatura `Ed25519`. Consumidores subsequentes podem verificar o pacote de provas de um módulo compilado (`lume evidence verify`) em milissegundos, sem reexecutar a busca de prova.

Para ancorar a solidez (*soundness*) do cálculo central, a semântica operacional e as provas de segurança de tipos do Lume-Core são mecanizadas em **Lean 4** (`formal/lean/LumeCore.lean`).

---

## 3. Modelo de Memória: Ownership, Reuso In-Place Estilo Perceus e Arenas com Escopo

Linguagens de sistemas tipicamente escolhem um de dois extremos: coleta de lixo rastreada com latência de cauda não-determinística, ou anotações de tempo de vida (*lifetimes*) espalhadas por todas as assinaturas de funções.

A Lume combina três mecanismos determinísticos:

1. **Ownership Linear e Borrow Checking (`[O0001]`–`[O0030]`):** Recursos externos — descritores de arquivo (`std.fs.with_file`), sockets de rede e capacidades de hardware (`cap[Page]`, `cap[Port]`, `cap[Irq]`) — são rastreados linearmente. Usar um handle após o fechamento, ou deixar de fechá-lo em todos os caminhos de fluxo de controle, é rejeitado em tempo de compilação.
2. **Reuso Funcional Estilo Perceus (`__perceus_reuse_1/2`) e Cache de Pequenos Inteiros:** Quando o casamento de padrões (*pattern matching*) desestrutura um tipo de dado algébrico cuja contagem de referências é comprovadamente única naquele ponto do programa, o compilador reutiliza a célula de alocação existente *in-place* para o novo valor construído. Combinado com um cache estático para inteiros em `[-1024..1024]` e saltos diretos de chamada em cauda (`.Ltail_<fn>`), transformações funcionais rodam com sobrecarga de alocação próxima de zero.
3. **Arenas com Escopo Léxico (`std.arena`) e Limites Rígidos de Heap (`LUME_HEAP_CAP`):** Cargas de trabalho em lote podem alocar dentro de arenas com escopo (`arena_new`, `arena_enter`, `arena_reset`, `arena_destroy`). Para preservar a transparência referencial, o verificador de efeitos rejeita mutações de arena dentro de funções `/ pure` (`[E0200]`), e a flag `--memory` reporta o pico exato de memória RSS do processo (`os_self_maxrss_kb`).

---

## 4. Dados Financeiros, Tensores Diferenciáveis e Sistemas Bare-Metal em uma Única Linguagem

Uma fonte recorrente de bugs na engenharia de produção é traduzir lógica através de fronteiras de linguagens — prototipar um modelo em Python, reescrever a camada de armazenamento em SQL/Go e reimplementar o parser de pacotes em C. A Lume fornece semântica de primeira classe para os três domínios:

- **Primitivas Financeiras e Relacionais Exatas (`decimal(p,s)`, `money[CCY]`, `table[T]`):** Aritmética decimal de ponto fixo e tipos parametrizados por moeda impedem arredondamentos acidentais de ponto flutuante ou somas entre moedas distintas (`money[USD] + money[EUR]` é um erro de tipo). Tabelas persistentes (`db.src`) utilizam uma árvore B+ recursiva multi-vias (`BMLeaf`/`BMInner`) com log de escrita antecipada (WAL) tolerante a falhas.
- **Tensores com Verificação de Formato e Geração Nativa para GPU (`tensor[DType, ...]`, `[T0300]`):** Diferenciação automática em modo reverso e direto (`grad`, `value_and_grad`, `jvp`, `vjp`) opera nativamente sobre funções Lume. Kernels de computação anotados com `@schedule(...) kernel fn` são compilados diretamente para SSA **CUDA PTX 8.0** e **Vulkan SPIR-V 1.6**, junto com parsers binários nativos para `.safetensors` e `.onnx` (`nn.src`).
- **Kernels Freestanding e Tempo de Execução no Pior Caso (`@freestanding`, `@interrupt`, `@bound(cycles: N)`):** Código de sistemas utiliza mapeamentos de registradores voláteis `@repr(c)`, `@packed` e `@mmio`. Rotinas de interrupção anotadas com `@bound(cycles: N)` passam por verificação estática de orçamento de ciclos de CPU (`[V0002]`) e proíbem alocação no heap.

---

## 5. Compilador como Oráculo (CaaS) para Síntese Automatizada

Como a Lume rastreia efeitos algébricos explícitos (`! {IO, Net, Fs}`) e contratos formais (`requires`/`ensures`), o próprio compilador funciona como um oráculo formal tanto para desenvolvedores humanos quanto para loops de síntese automatizada.

Por meio de seu servidor JSON/MCP embutido (`lume mcp`, `lume certify --json`, `lume agent cegis`, `lume heal`), um desenvolvedor ou agente de código pode escrever a assinatura de uma função com uma pós-condição formal e deixar uma lacuna tipada (`??`) no corpo. Usando Síntese Indutiva Guiada por Contraexemplos (CEGIS), o compilador sintetiza expressões candidatas, verifica-as contra o provador `QF_LIA` e só emite código matematicamente provado para satisfazer a especificação.

---

## 6. Explorando a `v1.0.0`

A Lume `v1.0.0` está disponível sob a Licença MIT com pacotes pré-compilados para **Linux (`x86_64`, `aarch64`, `riscv64`)**, **Windows (`x86_64`)** e **macOS (`aarch64` Apple Silicon e `x86_64`)**, apoiada por uma suíte de conformidade de 393 testes no Stage 0, verificação AddressSanitizer/UBSan e 17 pipelines de integração contínua.

- **Repositório no GitHub:** https://github.com/OmegaSoftDLL/lume
- **Binários da Release `v1.0.0` e `SHA256SUMS`:** https://github.com/OmegaSoftDLL/lume/releases/tag/v1.0.0
- **Código-Fonte do Compilador (`lumec` + `lasm` + `lcert`):** `compiler/stage1/`
- **Mecanização em Lean 4:** `formal/lean/LumeCore.lean`
