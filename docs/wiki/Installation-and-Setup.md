<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="76" height="76" align="left" />
  Installation &amp; Toolchain Setup (`v1.1.0`)
</h1>
<br clear="left"/>

Lume `v1.1.0 (Edition 2026)` ships as a self-contained, cryptographically attested Zero-C toolchain (**`134` SHA-256-locked manifest files** in `MANIFEST.sha256` and **`114` table-driven CLI commands** with `0` parity drift) across **Linux (`x86_64`, `aarch64`, `riscv64`)**, **macOS (`aarch64` Apple Silicon &amp; `x86_64` Intel)**, **Windows (`x86_64`)**, **WSL2**, and **OCI containers**.

---

## 1. Linux, macOS &amp; WSL2 (One-Line Installer)

Install the prebuilt, SHA-256-verified release into `~/.lume` and register `~/.lume/bin` on your `PATH`:

```sh
curl -fsSL https://github.com/OmegaSoftDLL/lume/releases/latest/download/install.sh | sh

export PATH="$HOME/.lume/bin:$PATH"
grep -qxF 'export PATH="$HOME/.lume/bin:$PATH"' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.lume/bin:$PATH"' >> ~/.bashrc
[ -f ~/.zshrc ] && (grep -qxF 'export PATH="$HOME/.lume/bin:$PATH"' ~/.zshrc || echo 'export PATH="$HOME/.lume/bin:$PATH"' >> ~/.zshrc)

lume --version
lume self verify
lume self-prove
```

---

## 2. Homebrew (macOS Apple Silicon, macOS Intel &amp; Linux)

```sh
brew install OmegaSoftDLL/lume/lume
lume --version
lume self verify
```

The official formula resides at [`Formula/lume.rb`](https://github.com/OmegaSoftDLL/lume/blob/main/Formula/lume.rb) and verifies every platform tarball against `SHA256SUMS`.

---

## 3. Windows x64 (PowerShell Installer &amp; Direct Archive)

```powershell
# Option A: One-line PowerShell installer (verifies SHA-256 & updates User PATH)
irm https://github.com/OmegaSoftDLL/lume/releases/latest/download/install.ps1 | iex

# Option B: Direct archive extraction + persistent User PATH registration
Invoke-WebRequest -Uri "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-windows-x86_64.tar.gz" -OutFile "lume-win64.tar.gz"
mkdir "$HOME\.lume" -Force | Out-Null
tar -xzf lume-win64.tar.gz --strip-components=1 -C "$HOME\.lume"

$lumeBin = "$HOME\.lume\bin"
$env:PATH = "$lumeBin;$env:PATH"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$lumeBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$lumeBin;$userPath", "User")
}

lume --version
lume self verify
```

---

## 4. Official Container Image (GitHub Container Registry)

```sh
docker pull ghcr.io/omegasoftdll/lume:v1.1.0
docker run --rm ghcr.io/omegasoftdll/lume:v1.1.0 --version
docker run --rm ghcr.io/omegasoftdll/lume:v1.1.0 self-prove
```

---

## 5. Prebuilt Release Archives (`v1.1.0`)

| Platform / Architecture | Release Archive |
| :--- | :--- |
| **Linux x86-64 (`ELF64`)** | [`lume-v1.1.0-linux-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-x86_64.tar.gz) |
| **Linux ARM64 (`aarch64`)** | [`lume-v1.1.0-linux-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-aarch64.tar.gz) |
| **Linux RISC-V 64 (`riscv64`)** | [`lume-v1.1.0-linux-riscv64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-riscv64.tar.gz) |
| **macOS Apple Silicon (`aarch64`)** | [`lume-v1.1.0-macos-aarch64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-aarch64.tar.gz) |
| **macOS Intel (`x86_64`)** | [`lume-v1.1.0-macos-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-x86_64.tar.gz) |
| **Windows x64 (`PE32+`)** | [`lume-v1.1.0-windows-x86_64.tar.gz`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-windows-x86_64.tar.gz) |
| **Cryptographic Checksums** | [`SHA256SUMS`](https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/SHA256SUMS) |

---

## 6. AI Coding Agent Skill (`skills/lume`) &amp; IDE Extensions (`editors/`)

Lume ships an official distributable **AI Agent Skill ([`skills/lume/SKILL.md`](https://github.com/OmegaSoftDLL/lume/blob/main/skills/lume/SKILL.md))** for **Antigravity (AGY)**, **Claude Code**, **Cursor**, **Codex**, and **Windsurf**, plus editor extensions in [`editors/vscode-lume`](https://github.com/OmegaSoftDLL/lume/tree/main/editors/vscode-lume) and [`editors/openidea-lume`](https://github.com/OmegaSoftDLL/lume/tree/main/editors/openidea-lume) powered by `lume lsp --stdio`, `lume dap --stdio`, and `lume mcp`:

```sh
# Install via skills.sh CLI
npx skills add OmegaSoftDLL/lume@lume -g -y

# Or copy directly on Linux / macOS / WSL2
mkdir -p ~/.agents/skills ~/.gemini/config/skills ~/.claude/skills
cp -r skills/lume ~/.agents/skills/lume
cp -r skills/lume ~/.gemini/config/skills/lume
cp -r skills/lume ~/.claude/skills/lume
```

```powershell
# Or copy directly on Windows PowerShell
New-Item -ItemType Directory -Path "$HOME\.agents\skills", "$HOME\.gemini\config\skills", "$HOME\.claude\skills" -Force | Out-Null
Copy-Item -Path ".\skills\lume" -Destination "$HOME\.agents\skills\lume" -Recurse -Force
Copy-Item -Path ".\skills\lume" -Destination "$HOME\.gemini\config\skills\lume" -Recurse -Force
Copy-Item -Path ".\skills\lume" -Destination "$HOME\.claude\skills\lume" -Recurse -Force
```

---

## 7. Bootstrapping from Source (`stage2 == stage3` Zero-C Fixpoint)

To reproduce the self-hosted compiler fixpoint from source and install into `~/.lume`:

```sh
git clone https://github.com/OmegaSoftDLL/lume.git
cd lume

# 1. Assemble modular compiler passes (compiler/stage1/lume/*.src -> lumec.src)
./lume amalgamate

# 2. Verify bit-identical 3-stage self-hosted bootstrap (lumec1 == lumec2 == lumec3, 0 diff)
./lume bootstrap

# 3. Verify Zero-C steady state (cc, clang, as, and ld completely blocked)
./lume zero-c

# 4. Install all 134 manifest-verified files into ~/.lume
./lume self install --prefix "$HOME/.lume"
```

---

## 8. Installed Binary Inventory (`~/.lume/bin`)

| Binary | Role in the Self-Hosted Toolchain |
| :--- | :--- |
| `lume` / `lume_driver` / `lcli` | Table-driven CLI driver (`114` canonical command rows, `226` command &amp; alias names, `0` parity drift) |
| `lumec` | Self-hosted compiler (`01_lexer` .. `07_driver`, `own_flow`, `QF_LIA`/`QF_NIA` prover, Perceus reuse, DWARF v4, SIMD) |
| `lasm` / `larm64` / `lriscv` | Native x86-64 (ELF64/PE32+/Mach-O/VEX/EVEX/DWARF), AArch64 &amp; RISC-V assemblers and machine-code backends |
| `lcaas` / `lproof_cache` | Compiler-as-a-Service JSON verification oracle &amp; `< 10 ms` SHA-256 incremental proof cache |
| `lcert` | Zero-compiler-import standalone proof certificate kernel (`--check-source` AST binding `[K0005]`, `[K0006]`) |
| `ltv` / `ltv_rt` / `ltv_multiarch` | Symbolic x86-64 (`694` fns), runtime-helper (`18/18`), and AArch64/RISC-V translation validators + `[C0010]` CT verifier |
| `lsmt` / `lstack` / `lmcdc` | Clean-room `QF_UFNIA` `.smt2` solver, `@no_alloc` worst-case stack analyzer, and native Masking MC/DC engine |
| `lsafety_envelope` | `2oo2D` dual-channel lockstep voter (native Channel A vs clean-room RV32IM `lrv32_lowered.src` Channel B + `--split`) |
| `lcrypto_tls` / `lx509` | `118` `[C0011]` constant-time crypto kernels, TLS 1.3, Ed25519 X.509v3 path validator, and NIST SP 800-90B entropy |
| `lqualify` / `levidence` | Ed25519 + X.509v3-signed Tool Qualification harness (`106/106` probes, `21/21` gates, TOR, TQP, RTM, Dossier) |
| `lchameleon` / `lneural_cartridge` | 9-ecosystem `[I0003]` polyglot FFI, Singularity $\Omega$, Bayesian SPC, and `.safetensors` `LumePuter` weight VM |
| `ltarget` / `lsentience` | 27-target emitter, Win64 PE32+ GUI, APK/IPA/ISO/UEFI packagers, and AI/Cyber-Physical/Quantum domain engines |
| `lmod` / `lfmt` / `ltest` / `ldoc` / `linteractive` / `lmanual` | Module bundler, canonical formatter, native test runner, doc extractor, LSP/DAP/REPL servers, and 10-chapter EN/PT-BR manual |

---

## 9. Post-Install Health, Proof &amp; Qualification Verification

Run these four commands to verify your installation end to end:

```sh
lume self verify         # Verifies SHA-256 integrity of all 134 installed manifest files
lume cli-parity          # Confirms 0 mismatches across 114 CLI rows, --help, manuals, README & SKILL.md
lume self-prove --json   # Runs OmniProof-v4: 16 batteries, 1,682 formal proofs (0 runtime/refuted), 372 tests, 122 domains
lume qualify --verify    # Verifies SHA-256 hash chain, Ed25519 signature & X.509v3 cert of docs/certification/
```
