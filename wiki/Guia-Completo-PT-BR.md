<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Mascote Oficial da Lume" width="76" height="76" align="left" />
  Guia Completo da Linguagem Lume v1.1.0 (Português — PT-BR)
</h1>
<br clear="left"/>

<div align="center">
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-social-banner.jpg" alt="Banner Oficial da Arquitetura da Linguagem Lume v1.1.0" width="100%" />
  <br />
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-hero-animated.svg" alt="Programação Verificada ao Vivo, Provador OmniProof-v4 e 27 Alvos Nativos na Lume v1.1.0" width="100%" />
</div>

---

## 1. Visão Geral — O Que é a Lume e Como Ela Foi Construída

<img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot.jpg" alt="Lumi — Mascote Camaleoa Bioluminescente Oficial da Lume" width="240" align="right" />

A **Lume (`v1.1.0`, Edição 2026)** é uma linguagem de programação estaticamente tipada e formalmente verificada para **sistemas críticos, inteligência artificial, controle ciberfísico e computação quântica**, criada por **Ricardo Bueno ([`@OmegaSoftDLL`](https://github.com/OmegaSoftDLL))**. Foi projetada desde os primeiros princípios para ser escrita com fluidez tanto por engenheiros humanos quanto por agentes autônomos de IA, garantindo correção matemática verificada por máquina desde os contratos do código-fonte até o código de máquina nativo emitido.

Diferentemente de *toolchains* tradicionais que dependem de *backends* externos em C/C++, montadores de terceiros ou bibliotecas de *runtime* não verificadas, **toda a cadeia de produção da Lume é escrita 100% na própria Lume (`compiler/stage1/`)**:

1. **Semente Auditável &amp; *Diverse Double-Compilation* (`bootstrap/lume0/`):** O *bootstrap* parte de uma semente mínima congelada em C11 (~4,8 mil linhas, travada por `SEED_FREEZE.sha256`). Pelo método **Diverse Double-Compilation (DDC)** de David A. Wheeler, compilar o compilador auto-hospedado a partir de compiladores C independentes (`cc` e `clang`) converge para exatamente o mesmo binário nativo SHA-256 (`0` bytes de diferença).
2. **Ponto Fixo Auto-Hospedado Zero-C (`lumec1 == lumec2 == lumec3`):** Em regime permanente, a Lume compila, monta, liga, formata, testa, prova e empacota a si mesma em **`~3,8 s`** com `cc`, `clang`, `as` e `ld` totalmente bloqueados (`lume zero-c`), verificada em **`134` arquivos travados por SHA-256** (`MANIFEST.sha256`) e **`114` comandos CLI orientados por tabela (`226` nomes e apelidos, `0` divergências em `lume cli-parity`)**.
3. **Verificação Mútua *Clean-Room*:** As provas do compilador (`lcaas.src`) são revalidadas por um kernel independente sem importações do compilador (`lcert.src --check-source`); o código de máquina x86-64, AArch64 e RISC-V é validado simbolicamente contra a semântica da AST (`ltv.src`, `ltv_rt.src`, `ltv_multiarch.src`) e auditado em `.smt2` tanto pelo solucionador nativo *clean-room* (`lsmt.src`) quanto pelo `z3`; a cobertura estrutural atinge **`0/9.618` condições Masking MC/DC descobertas** (`lmcdc.src`); funções críticas rodam em *lockstep* duplo **`2oo2D`** (`lsafety_envelope.src`) contra um compilador RV32IM *clean-room* (`lrv32_lowered.src`) que compartilha **`0/3.169` funções** com o `lumec`; e toda a evidência é consolidada no **Dossiê de Qualificação assinado com Ed25519 + X.509v3 (`lume qualify` — `PASS`)**.

<br clear="right"/>

---

## 2. Instalação e Configuração da Toolchain (`v1.1.0`)

### 1. Linux, macOS e WSL2 (Instalador de 1 Linha)
```sh
curl -fsSL https://github.com/OmegaSoftDLL/lume/releases/latest/download/install.sh | sh
export PATH="$HOME/.lume/bin:$PATH"

lume --version
lume self verify
lume self-prove
```

### 2. Homebrew (macOS Apple Silicon, macOS Intel e Linux)
```sh
brew install OmegaSoftDLL/lume/lume
lume --version
```

### 3. Windows x64 (PowerShell e Arquivo Direto)
```powershell
# Opção A: Instalador automático PowerShell (valida SHA-256 e configura o PATH do usuário)
irm https://github.com/OmegaSoftDLL/lume/releases/latest/download/install.ps1 | iex

# Opção B: Extração direta do arquivo tar.gz oficial + registro no PATH
Invoke-WebRequest -Uri "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-windows-x86_64.tar.gz" -OutFile "lume-win64.tar.gz"
mkdir "$HOME\.lume" -Force | Out-Null
tar -xzf lume-win64.tar.gz --strip-components=1 -C "$HOME\.lume"
```

### 4. Container OCI (`GHCR`) e Skill Oficial para Agentes de IA (`skills/lume`)
```sh
docker pull ghcr.io/omegasoftdll/lume:v1.1.0
docker run --rm ghcr.io/omegasoftdll/lume:v1.1.0 --version

# Instalar a Skill oficial para Antigravity (AGY), Claude Code, Cursor, Codex e Windsurf
npx skills add OmegaSoftDLL/lume@lume -g -y
```

---

## 3. Guia Rápido — Contratos, Tempo Real (`@no_alloc`) e Tempo Constante (`[C0011]`)

```lume
## Kernel de tempo real estrito sem alocação de heap ([E0210]) e orçamento WCET ([V0002])
@no_alloc
@bound(32)
fn limitar_atuador(dose: int, min_v: int, max_v: int) -> int
  requires dose >= 0 and dose <= 10000 and min_v >= 0 and min_v <= max_v and max_v <= 5000
  ensures result >= min_v and result <= max_v
= if dose < min_v then min_v else if dose > max_v then max_v else dose

## Multiplexador criptográfico branch-free em tempo constante ([C0011] fonte + [C0010] binário)
@secret
@no_alloc
fn ct_mux_u32(mascara: int, a: int, b: int) -> int =
  let ma = bit_and(a, 4294967295) in
  let mb = bit_and(b, 4294967295) in
  ct_select(ct_eq(bit_and(mascara, 1), 1), ma, mb)

print limitar_atuador(700, 100, 500)
```

```sh
lume prove kernel.src                                             # Prova estática QF_LIA, @bound, @no_alloc e [C0011]
lume certify kernel.src > kernel.cert.json                        # Emite certificado criptográfico SHA-256
lume verify-cert --check-source kernel.src kernel.cert.json       # Revalida no kernel isolado lcert + AST
lume stack kernel.src --json                                      # Limite exato de pilha em bytes no assembly emitido
lume tv kernel.src --exec                                         # Equivalência simbólica x86-64 + tempo constante [C0010]
lume mcdc kernel.src --exec                                       # Execução nativa de testemunhas Masking MC/DC
lume safety-envelope kernel.src --fn limitar_atuador --args 700,100,500 # Lockstep 2oo2D vs RV32IM clean-room
lume build --critical -g kernel.src -o kernel                     # Binário nativo retendo guardas + debug DWARF v4
```

---

## 4. Provador `OmniProof-v4`, Garantia Binária, Criptografia CT e Qualificação (`PASS`)

| Subsistema de Garantia | Implementação (`compiler/stage1/`) | Evidência Verificada em `v1.1.0` |
| :--- | :--- | :--- |
| **Provador Embarcado `OmniProof-v4`** | `06_typecheck.src`, `06b_phase3.src`, `lcaas.src`, `lproof_cache.src` | **`16` baterias, `1.682` obrigações formais provadas (`0` em runtime ou refutadas), `372` testes unitários, `122` domínios**; `QF_LIA` (Fourier-Motzkin, planos de corte, duais de Farkas), `QF_NIA` (Horner/Bernstein, completamento de quadrados), `QF_BV`, Octógonos, Lógica de Separação e cache SHA-256 **`< 10 ms`** |
| **Kernel Independente de Certificados** | `lcert.src` (`--check-source`) | Zero importações do compilador; vincula cada prova à AST e ao SHA-256 do fonte (`[K0005]` DMA `W^X`, `[K0006]` recursão mútua, `[K0010]`–`[K0013]` recusa de certificados adulterados ou enfraquecidos) |
| **Validação Simbólica de Código de Máquina** | `ltv.src`, `ltv_rt.src`, `ltv_multiarch.src`, `lsmt.src` | **`694` funções validadas** (`687/687` correlação 1-para-1 de desvios AST-objeto, `600/600` mutantes eliminados), **`18/18` helpers inteiros de runtime provados** (`268` caminhos / `462` obrigações), equivalência AArch64/RISC-V e **`100%` `unsat` em `.smt2`** no `lsmt` e no `z3` (**`3.820` mutantes rejeitados**) |
| **Cobertura MC/DC &amp; Pilha Estática** | `lmcdc.src`, `lstack.src` | **`0/9.618` condições Masking MC/DC descobertas** nos 4 módulos certificados (`lstd` `0/980`, `critical_kernels` `0/112`, `lchameleon` `0/2.392`, `lsentience` `0/6.134`) e limite exato de bytes de pilha para grafos `@no_alloc` |
| **Criptografia *Constant-Time*, X.509v3 &amp; TLS 1.3** | `lcrypto_tls.src`, `lx509.src` | **`118` kernels `@secret @no_alloc` `[C0011]`** sem desvios (`cmov`), validados em código de máquina (`ltv` `[C0010]`, `lstack <= 536 B`, **`24/24` alvos `dudect` com `\|t\| <= 2,690 < 4,5`**), SHA-256/512, HMAC, HKDF, ChaCha20-Poly1305, X25519, Ed25519, TLS 1.3, X.509v3 (**`6.000/6.000` cadeias adulteradas recusadas**) e entropia NIST SP 800-90B |
| **Envelope `2oo2D` &amp; Dossiê `lume qualify`** | `lsafety_envelope.src`, `lrv32_lowered.src`, `lqualify.src` | Canal A nativo vs. Canal B *clean-room* RV32IM (**`0/3.169` funções compartilhadas**, **`87.224` falhas injetadas → `0` não detectadas**, pacotes multi-placa `--split`) e Dossiê **`lume qualify` `PASS`** (**`106/106` sondas, `21/21` gates, `10` HLR e `44/44` LLR `VERIFIED`**) assinado com Ed25519 e X.509v3 |

---

## 5. Arquitetura de Memória de 4 Níveis (`31,8×` Mais Rápido &amp; `2.733×` Menos RAM)

<div align="center">
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-memory-evolution-animated.svg" alt="Painel de Benchmarks da Arquitetura de Memória de 4 Níveis da Lume" width="100%" />
</div>

O *runtime* nativo (`compiler/stage1/runtime_core.lume`) combina **reuso linear Perceus em tempo de compilação** (`own_flow.src`), coletor **Mark &amp; Lazy-Sweep segregado em 43 classes de tamanho** (`MADV_DONTNEED`) e representação em **4 níveis**:
1. **Nível 0 (`.rodata`):** Literais deduplicados e *singletons* `Nil`/`None` com `0 B` de *heap*.
2. **Nível 1 (Registradores Tagged de 64 Bits):** Inteiros *unboxed* de **63 bits** (`...iiii1`, `0 B` de *heap*, *trap* de *overflow* via hardware `jo __rt_ovf`) e **strings curtas UTF-8 de até 7 bytes *inline*** (`...ss|lll|010`, `0 B` de *heap*, eliminando `74,9%–94,9%` das alocações de strings curtas).
3. **Nível 2 (Células Compactas):** `Cons` em **`24 B`** (`-70%`) e registros de 3 campos com *shape* internado em **`32 B`** (`-80%`).
4. **Nível 3 (Compactador `LZ1` Sob Demanda):** Compacta arenas frias e cápsulas a **`~355 MB/s` (pack) / `~975 MB/s` (unpack)** com restauração *lazy* por página (`PROT_NONE` + `SIGSEGV`) e bloqueio estático sobre dados `@secret` (`[C0009]`) e rotas `@bound` (`[V0002]`).

Nos benchmarks em Intel Core Ultra 5 135U (WSL2 x86-64), `b_loop` (`100M` iterações) caiu de `2.796 ms` / `200M` alocações para **`88 ms` / `0,39 MB` / `1` alocação (`31,8×` mais rápido)**, e `b_str` reduziu o pico de RAM de `6,0 GB` para **`2,2 MB` / `17` alocações (`2.733×` menos RAM)**.

---

## 6. Motor Camaleão Poliglota (`9` Ecossistemas) e 27 Alvos Universais

<div align="center">
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-chameleon-showcase.svg" alt="Motor Camaleão Poliglota Universal da Lume — 9 Ecossistemas Verificados" width="100%" />
</div>

- **Motor Camaleão (`lchameleon.src` — `256/256` obrigações certificadas, `160/160` `ltv`, `0/2.392` MC/DC descobertas, `19/19` testes):** Conecta **`c_abi`** (com pré-processador C integrado `lume adapt c --preprocess <h>` e `io_uring`), **`rust_cdylib`**, **`python_capi`** (tensores **DLPack *zero-copy***), **`node_napi_wasm`** (`[I0275]`), **`go_cshared`**, **`java_jni`** (Panama FFM), **`dotnet_pinvoke`** (`NativeAOT`), **`sql_relational`** (`table[T]`/`decimal` ACID) e **`openapi_rpc`** (TLS 1.3), além da VM neural **`LumePuter`** (`.safetensors` `RV32IM_Zba` + Gated-DeltaNet) e da **Fronteira de Singularidade $\Omega$ + SPC Bayesiano / CUSUM / PAVA** (`lume singularity`).
- **27 Alvos de Compilação e Empacotadores (`ltarget.src`):** Compila diretamente para Linux (`x86_64`, `aarch64`, `riscv64`), bare-metal (`riscv32-none-elf`, Cortex-M, AVR, ESP32, Ring-0 `.kernel`), macOS (`aarch64`, `x86_64`), Windows Console (`PE32+`) e **GUI Nativa Windows 64-bit (`--target x86_64-windows-gui`, `33.792` bytes `Subsystem 2` com ícone oficial da Lumi em `.rsrc` e 4 painéis redimensionáveis/roláveis)**, WebAssembly (`wasm32-wasi`), cartuchos neurais `.safetensors`, GPUs (`nvptx64`, `spirv64`), silício sintetizável (`verilog-rtl`, `vhdl-rtl`), circuitos quânticos (`qasm3-quantum`, `qir`, `stim-clifford`), DNA quaternário e pacotes `apk`, `ipa`, `iso` e `uefi`.

---

## 7. Referência Rápida de Comandos e Manuais

```sh
lume manual --pt                   # Índice completo do manual em Português (10 capítulos)
lume self verify                   # Verifica os 134 arquivos SHA-256 instalados
lume cli-parity                    # Verifica paridade total das 114 linhas da CLI (0 divergências)
lume synergy-gate                  # Pipeline crítico de 17 estágios + 36/36 testes anti-adulteração
lume qualify --verify              # Verifica assinatura Ed25519 + X.509v3 do Dossiê de Qualificação
```

- **Manual Completo em Português (`pt-BR`):** [`docs/LUME_MANUAL_PT_BR.md`](https://github.com/OmegaSoftDLL/lume/blob/main/docs/LUME_MANUAL_PT_BR.md)
- **Relatório de Auditoria e Qualificação (`pt-BR`):** [`docs/RELATORIO_AUDITORIA_E_CERTIFICACAO_CLAUDE_PT_BR.md`](https://github.com/OmegaSoftDLL/lume/blob/main/docs/RELATORIO_AUDITORIA_E_CERTIFICACAO_CLAUDE_PT_BR.md)
- **Dossiê de Qualificação Assinado (`PASS`, EN):** [`docs/certification/QUALIFICATION_DOSSIER.md`](https://github.com/OmegaSoftDLL/lume/blob/main/docs/certification/QUALIFICATION_DOSSIER.md)
