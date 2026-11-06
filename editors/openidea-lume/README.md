# Lume Sovereign Language & Dracula Theme for OpenIDEA

Official [OpenIDEA](https://github.com/openidea-dev/openidea) WASM/WIT plugin (`openidea:plugin@1.2.0`) for the **Lume Sovereign Programming Language**.

## Features

- **File Associations:** `.src`, `.lume`, `.intent`, `.mesh`
- **Syntax Highlighting & Grammar:** Full TextMate grammar (`syntaxes/lume.tmLanguage.json`) highlighting `law`, `requires`, `ensures`, algebraic effects, linear capabilities (`cap[Page|Port|Irq]`), and kernel attributes (`@freestanding`, `@interrupt`, `@bound`).
- **LSP & DAP Integration:** Native integration with `lume lsp --stdio` and `lume dap --stdio`.
- **Built-in Run & Proof Actions:**
  - `Lume: Run File` (`lume run`)
  - `Lume: Run Tests` (`lume test`)
  - `Lume: Prove QF_LIA Obligations` (`lume prove`)
  - `Lume: Emit Proof Certificate (lcert)` (`lume certify`)
- **Theme:** Ships with the **Dracula Lume Sovereign** dark theme (`themes/dracula-lume-color-theme.json`).

## Installation

Copy or symlink `editors/openidea-lume` into your OpenIDEA plugins directory:

```bash
ln -s /path/to/lume/editors/openidea-lume ~/.config/openidea/plugins/dev.lume-lang.openidea
```
