<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Lume Mascot" width="76" height="76" align="left" />
  Installation &amp; Sovereign Toolchain Setup
</h1>
<br clear="left"/>

Lume `v1.1.0 (2026 Edition)` ships as a self-contained, cryptographically attested toolchain (`99` manifest files verified by SHA-256) across **Linux (`x86_64`, `aarch64`, `riscv64`)**, **macOS (`aarch64` Apple Silicon & `x86_64`)**, **Windows (`x86_64`)**, and **WSL2**.

---

## 1. One-Line Installers (Recommended)

### Linux, macOS & WSL2 (`install.sh`)

```bash
curl -fsSL https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/scripts/install.sh | sh
```

By default, `install.sh` installs the verified toolchain into `~/.lume` and adds `~/.lume/bin` to your shell profile (`~/.bashrc`, `~/.zshrc`, or `~/.profile`).

### Windows PowerShell (`install.ps1`)

```powershell
irm https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/scripts/install.ps1 | iex
```

`install.ps1` downloads `lume-v1.1.0-windows-x86_64.tar.gz`, verifies its SHA-256 digest against the official release manifest, extracts it to `$HOME\.lume`, and registers `$HOME\.lume\bin` in your User `PATH`.

---

## 2. Homebrew (macOS & Linux)

```bash
brew install OmegaSoftDLL/lume/lume
lume --version
```

The official formula lives at [`Formula/lume.rb`](https://github.com/OmegaSoftDLL/lume/blob/main/Formula/lume.rb) and is automatically synchronized with `SHA256SUMS` on every release.

---

## 3. Official Container Image (GitHub Container Registry)

```bash
docker pull ghcr.io/omegasoftdll/lume:v1.1.0
docker run --rm ghcr.io/omegasoftdll/lume:v1.1.0 lume self-prove
```

---

## 4. Building & Bootstrapping from Source (`Zero-C` Fixpoint)

To build Lume from source and verify the self-hosted `stage2 == stage3` bit-identical fixpoint:

```bash
git clone https://github.com/OmegaSoftDLL/lume.git
cd lume

# 1. Verify bit-identical 3-stage self-hosted bootstrap (stage2 == stage3)
./lume bootstrap

# 2. Verify Zero-C steady state (compiles and assembles with PATH="" and no C toolchain)
./lume zero-c

# 3. Run the embedded OmniProof v3 formal verification suite (582 obligations, 155 unit tests)
./lume self-prove

# 4. Install locally into ~/.lume
./lume self install --prefix "$HOME/.lume"
```

---

## 5. Installed Binary Inventory (`~/.lume/bin`)

| Binary | Role |
| :--- | :--- |
| `lume` / `lume_driver` | Unified sovereign CLI driver (`run`, `build`, `prove`, `test`, `fmt`, `chameleon`, `manual`, `self-prove`) |
| `lumec` | Self-hosted Stage-2 Lume compiler (`QF_LIA` prover + Perceus reuse + native x86-64/ELF/PE/Mach-O codegen) |
| `lasm` | 100%-Lume native x86-64 machine-code assembler & linker (ELF64, PE32+, Mach-O 64 — zero `as`/`ld`) |
| `lcaas` | Compiler-as-a-Service persistent daemon & 4-way differential verification oracle |
| `lcert` | Standalone proof-certificate verifier (`SHA-256` + `Ed25519` + hybrid post-quantum `ML-DSA-65`) |
| `ltest` | Native unit & property-based test runner |
| `lfmt` | Canonical source code formatter (`lume fmt` / `lume fmt --check`) |
| `lmod` | Content-addressed sovereign package manager & capability verifier |
| `ltarget` | 27-target cross-compiler, Clean Generic Win64 Native GUI emitter (`x86_64-windows-gui`), & store packager |
| `lsentience` | Sovereign Domain & Sentience Engine (Kernelume OS, OpenTPU, Quantum, Continuum, Reversa, Pingora, EGM) |
| `lchameleon` | Universal Chameleon 9-Ecosystem Polyglot Interop Engine (`[I0003]` boundary contract verifier) |

---

## 6. Post-Install Health Check

Run these three commands to confirm your installation is 100% healthy and cryptographically verified:

```bash
lume self status
lume self verify
lume self-prove
```

Expected output from `lume self-prove`:

```json
{
  "ok": true,
  "command": "self-prove",
  "engine": "LumeCompiler-Embedded-OmniProof-v3",
  "zero_external_scripts": true,
  "total_formal_obligations_verified": 582,
  "total_unit_tests_passed": 154
}
```
