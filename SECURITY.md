# Security Policy

## Supported versions

Security updates are applied to the current `1.0.x` release series and the `main` branch. Before reporting an issue, please verify that it reproduces against `v1.0.0` or current `main`.

| Version | Status |
| --- | --- |
| `1.0.x` (latest release) | Supported |
| `main` | Supported |
| `< 1.0.0` | Unsupported |

## Reporting a vulnerability

Report suspected vulnerabilities privately through
[GitHub Security Advisories](https://github.com/OmegaSoftDLL/lume/security/advisories/new).
Do not open a public issue, pull request, or discussion containing an exploitable reproduction.

Include:

- the affected release or commit, operating system, and architecture;
- the security impact and any affected trust boundary;
- a minimal, self-contained reproduction with exact commands;
- relevant diagnostics or logs, with credentials and personal data removed; and
- a suggested mitigation, if available.

Maintainers will review the report, assess its scope and severity, and coordinate a fix and
disclosure with the reporter. Do not disclose the issue publicly before a coordinated resolution.

## Scope notes

- Compilers and assemblers (`lumec`, `lasm`, and the frozen `lume0` bootstrap seed) emit and execute native machine code when invoked with `run` or `build`. When evaluating untrusted third-party code, use isolated execution modes (`@wasm-sandbox`, capability-restricted modules, or OS containerization).
- P33 software-protection profiles (`--protect standard|hardened|max`) provide symbol stripping, string literal encryption, and control-flow/arithmetic obfuscation for intellectual-property defense, but are not a substitute for cryptographic key management.
