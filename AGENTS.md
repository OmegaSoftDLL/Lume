# AGENTS.md — read this before working on Lume

Any agent (Claude, Auggie/agy, or other) working on this repo must read
**[`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md)** first. It holds the full state, the
architecture, the DO / DO-NOT rules, the PR workflow, and the hard-won pitfalls. This file
is the short version.

## Non-negotiable rules

- **Converse in Portuguese (pt-BR). Write all code, docs, comments, filenames, commits and
  PRs in English.**
- **Golden rule: Lume generates Lume, with zero bugs in Lume's own toolchain.** Every fix ships with a regression test. Implementation and test logic must be in Lume. Existing non-Lume artifacts are migration liabilities, not precedent; remove them only after a verified Lume replacement exists.
- **Do not use Rust** to implement Lume.
- **Edit the self-hosted compiler in `compiler/stage1/lume/NN_*.src`, never the generated
  `compiler/stage1/lumec.src`.** `lumec.src` is a build artifact (git-ignored), amalgamated
  from the modules in numeric order by `scripts/amalgamate.src` (`build/bin/lume_make amalgamate`); the
  concatenation is byte-identical to the historical monolith. See `docs/13-module-split-plan.md`.
- **Do not fake completion.** The triple self-build (`stage 2 == stage 3`, SHA-256 `2a32911ee74c39b146cba4976ae12644725e8414d262a89847a5328ebfd386e6` + Wheeler DDC `cc` vs `clang`) **is done** and verified in CI — never regress it, and never claim a milestone that is not real. In `v1.1.0`, `OmniProof-v4` (`16` batteries, `1,682` proven obligations, `0` runtime/refuted, `372` unit tests, `122` domains, `134` SHA-256 manifest files), `ltv`/`ltv_rt`/`lsmt` (`694` functions + `18/18` runtime helpers + `100%` `.smt2` `unsat`), `0/9,618` uncovered Masking MC/DC, `118` `@secret @no_alloc` `[C0011]` constant-time crypto kernels (`24/24` `dudect`, Ed25519 X.509v3, NIST SP 800-90B, TLS 1.3), `2oo2D` clean-room RV32IM + `--split` safety envelope, signed `lume qualify` `PASS` (`106/106` probes, `21/21` gates), `synergy-gate` (`17/17`), `cli-parity` (`114` rows, `0` drift), 9-ecosystem Chameleon FFI, 4-Tier Atomic Memory (`31.8×`), and all 27 compilation targets (`56/56` certified issues on GitHub Project `#5`) are complete and verified in CI. State features at their real level: shipped, a model/stub, or planned.
- **Public `README.md` & Golden Git Rules:** Keep `README.md` and `docs/index.md` written strictly as an institutional programming-language manual (`0` internal `Wave`/`Phase`/`Round` sprint jargon, `0` `cli-parity` mismatches), never commit/push to GitHub without explicit owner authorization, and keep the local 24/7 Sanctuary evolver **stopped (`0` processes)** unless explicitly requested.
- **The hosted runtime has one source: `compiler/stage1/runtime_core.lume`.** Every instruction in it must
  assemble with both `lasm` and the seed (`lume0 asm`, no shifts, no unsigned jumps). The memory model is in
  `docs/38-memory-management.md`.
- **`lcaas` runs the real compiler** (`use lumec`), and `lfmt` proves each rewrite with the same parser. Change the grammar and the checks in `compiler/stage1/lume/`; the `cs_*` parser only recovers from broken input.
- **C is the disposable seed only.** The end state is no C and no external `as`/`ld` (Lume
  emits native ELF itself — see `lume0 asm`). Move work toward native, not toward C.
- For each feature borrowed from another language, make ours **superior**, not a shallow clone.
- Keep all 9 `examples/0*.lume` passing `lume0 check` cleanly (the semantic checker must stay
  zero-false-positive).

## Delivery hardening — no theater (run this checklist on EVERY PR, before opening it)

The repeated failure mode on this project is shipping impressive machinery whose **trust/soundness
primitive is theater** (a prover that samples, a "signature" that is a hash of public data, a
certificate that rubber-stamps, a one-shot JSON labelled a "server", a model labelled "done").
Self-review every PR against this before opening it — the same scrutiny a reviewer applies. Full
detail: `docs/28-delivery-rules.md`.

1. **State the real level: shipped / model / planned.** Never label a stub, one-shot, in-language
   model, or placeholder as working/done. The words must match what runs: don't write "serve",
   "interactive", "ACID", "durable", "proven", "sound", or "✅ done" beyond what actually executes.
   Update the docs **and** CLI help to the real level in the *same* PR.
2. **"Done" means it does the real thing**, not that it emits the right shape/label. A target or
   kernel brick is done only when a real program **runs on real hardware or QEMU**, guarantees intact.
3. **Trust/soundness primitives must be genuine:** `proven` only from a sound decision procedure
   (QF_LIA/Fourier–Motzkin), never sampling; never silently return a wrong result (diagnose, e.g.
   `[N0400]`); signatures are **asymmetric** (public key in repo, private off-repo), never a hash over
   public data, with no unsigned bypass; certificates/verifiers **re-derive independently**, never
   rubber-stamp the compiler's own verdict; crypto/decision procedures are validated against the
   **official test vectors** (e.g. RFC 8032 §7.1), not self-generated ones; an analysis that cannot be
   sound is labelled honestly (e.g. `budget_checked`), never "proven".
4. **Write tests that FAIL if the primitive is theater** — not just happy-path. Include the negative
   case (forged signature rejected, false contract refuted *with the counterexample*, out-of-fragment
   → `runtime_checked`), asm asserts ("no residual `call …`"), behaviour-identical-across-levels,
   official vectors, and runs-on-QEMU. **A green CI does not prove soundness.**
5. **GOLDEN RULE preserved:** `stage 2 == stage 3`, `build/bin/lume_make zero-c`, and the oracle byte-equivalence
   stay green; new features/backends are in Lume, not new C in the frozen seed (`#205`); every fix
   ships a regression test. If a shortcut is unavoidable, it ships labelled `model`/`planned` — never
   as a guarantee. Zero theater inside Lume.
6. **Deliver the real construct, not a mock of it.** A typed feature is the compiler type
   (`rc[T]` = the real ownership tier, not user functions `rc_new`/`rc_drop` returning records); a
   `[CODE]` diagnostic must come from the real analysis, **never faked** with a hardcoded
   `ctfail("...[CODE]...")` string or hand-returned JSON; the test must exercise the real syntax, not
   a stand-in (`fn rc_drop(x: int) = x`). A mock that only works inside its own test and imitates a
   feature the compiler lacks does not ship and must **not** close the feature's issue — label it
   `planned` and keep the issue open. Build what the issue asks, not an easier look-alike.
   **Regenerate expected output from a real run and verify it against a trace — never tune the
   program/inputs to match a stale expected, and assert each behaviour on its own rather than hiding
   many in one opaque sum (a bug in one term must not be maskable by fitting another).**
7. **Zero placeholders — everything documented must run, exhaustively tested.** No placeholder/
   stub/mock/fixed-output/one-shot ships in a claimed feature's path, even labelled — if it isn't
   real it's an open issue, referenced as working nowhere (not in docs, CLI, status, tests, or a
   closed issue). Every docs/spec/README/CLI claim is a promise CI must prove on a real target;
   docs match reality **both ways** (fix stale "not implemented" too). Tests are exhaustive and
   generalising — surface + adversarial + negatives, regenerate expected from a real run (never tune
   inputs to a target), run on **every** claimed platform — and the full suite is re-run on every
   change. **Closing an issue needs the real, run-verified, exhaustively-tested deliverable, never a
   partial — premature close is a defect** (#192/#197/#206/#227 had to be reopened). Large items ship
   incrementally, each increment real. When unsure, it is `planned`, not done.

## Workflow

- One change → one branch → one green PR → merge. Keep CI green (`gh`).
- Before committing: `make -C bootstrap/lume0 test` and `make -C bootstrap/lume0 asan`, both
  `0 failed`. The build is strict: `-Werror -Wconversion -Wpedantic -Wshadow`.
- There is no top-level Makefile. `./lume` is a thin bootstrap shim: the first call on a
  fresh clone builds the frozen seed and the native toolchain, then execs
  `build/bin/lume_driver` (which implements every command natively). Build orchestration is
  `build/bin/lume_make amalgamate|bootstrap|zero-c|seed|test|asan|clean`; `make` remains only
  inside the frozen seed (`bootstrap/lume0/Makefile`, frozen). On non-native hosts (macOS,
  Windows, qemu) the shim routes to `scripts/lume_legacy.sh` — keep that file read-only
  unless you are migrating a piece of it to Lume.
- Commit messages end with `Co-Authored-By: ...` (see the session's attribution note); PR
  bodies end with the Claude Code generation line. Use `git commit -F <file>` to avoid shell
  quoting issues.

## Build & run

```
make -C bootstrap/lume0                          # build the frozen seed (the only make left)
./lume --version                                 # bootstrap the native toolchain (fresh clone)
build/bin/lume_make bootstrap                    # staged self-host, asserts stage 2 == stage 3
build/bin/lume_driver build <file.src> -o <out>  # compile Lume-Core to a native ELF
bootstrap/lume0/lume0 check  <file.lume>         # lex + parse + name/type/duplicate checks
bootstrap/lume0/lume0 run    <file.lume>         # interpret
bootstrap/lume0/lume0 emit-asm <f.lume> f.s      # x86-64 (integer subset)
bootstrap/lume0/lume0 asm    f.s  out            # assemble+link to native ELF, NO as/ld/cc
bootstrap/lume0/lume0 describe --json            # self-description for a model
```

See `docs/PROJECT_STATE.md` §9 for the pitfalls (reserved keywords, `{{`/`}}` escaping, flat
`if/elif` AST, conformance test naming, strict-flag gotchas) — do not rediscover them.
