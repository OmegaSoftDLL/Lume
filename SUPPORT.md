<h1>
  <img src="docs/assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="72" height="72" align="left" />
  Getting Support &amp; Help with Lume (<code>v1.1.0</code>)
</h1>

<br clear="left"/>

## 1. Built-In Compiler Oracle & Bilingual Manuals (Fastest)

Before opening an issue, query Lume's built-in documentation and compiler oracle directly from your terminal:

```sh
# Full 10-chapter Programmer's Manual (English or Brazilian Portuguese)
lume manual
lume manual --pt
lume manual chameleon

# Query Sovereign Memory & Compiler-as-Oracle
lume consult "how to prove a bounded ring buffer in QF_LIA"

# Explain any diagnostic code ([E0200], [I0003], [V0001], [C0009], [T1002])
lume explain E0200

# Verify your local installation integrity (SHA-256 manifest + 15 proof batteries)
lume self verify
lume self-prove
```

## 2. Official Documentation & Community Channels

- **GitHub Pages Documentation Portal:** [https://omegasoftdll.github.io/lume/](https://omegasoftdll.github.io/lume/)
- **English Manual:** [`docs/LUME_MANUAL_EN.md`](docs/LUME_MANUAL_EN.md)
- **Manual em Português (`pt-BR`):** [`docs/LUME_MANUAL_PT_BR.md`](docs/LUME_MANUAL_PT_BR.md)
- **LumeLabs R&D Incubator:** [`LUMELABS.md`](LUMELABS.md)
- **Community Hub & Working Groups:** [`COMMUNITY.md`](COMMUNITY.md)
- **Projects & Roadmap:** [`PROJECTS.md`](PROJECTS.md)
- **GitHub Discussions (Q&A, Proof Clinic & `pt-BR`):** [https://github.com/OmegaSoftDLL/lume/discussions](https://github.com/OmegaSoftDLL/lume/discussions)
- **GitHub Wiki:** [https://github.com/OmegaSoftDLL/lume/wiki](https://github.com/OmegaSoftDLL/lume/wiki)

## 3. Reporting Bugs or Security Vulnerabilities

- **Reproducible Compiler/Prover Bugs:** Open a [Bug Report Issue](https://github.com/OmegaSoftDLL/lume/issues/new/choose) with `lume --version`, OS/architecture, and a minimal `.src` reproduction.
- **Security Vulnerabilities:** Never open a public issue for security bugs; follow [`SECURITY.md`](SECURITY.md) to report privately via [GitHub Security Advisories](https://github.com/OmegaSoftDLL/lume/security/advisories/new).
