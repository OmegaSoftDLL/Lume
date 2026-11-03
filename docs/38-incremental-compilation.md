# 38 — Incremental compilation (Wave 1, #310)

Status: **shipped increment** — opt-in per-module compile cache behind `lume build --incremental`.
Default builds are byte-for-byte unchanged (the bootstrap fixpoint and zero-C gates do not pass
`--incremental`, and lumec's default codegen path is byte-identical to before).

## Model

A `lume build` compiles a *bundle*: the driver resolves `use` imports, the bundler (`lmod`)
flattens modules in topological order, `lumec` compiles the whole flattened bundle in one
process, and `lasm` assembles the result. Recompiling after a one-line change to one leaf module
re-runs `lumec` over the *entire* bundle.

With `--incremental`, the driver instead:

1. Resolves the module graph itself (topological order identical to `lmod`'s flattened order).
2. Asks `lumec --ast-hash` for a **content hash of each module's parsed AST** (a canonical
   S-expression serialization, SHA-256). Formatting-only or comment-only edits hash equal and
   hit the cache.
3. Compiles each module independently with `lumec --module <name> <entry|lib>` into a
   **module fragment**: the module's functions and its string/constructor rodata, with all code
   labels scoped by the module name (content-addressed, position-independent). Fragments are
   cached in `build/cache/<key>.frag` where the key covers the lumec binary SHA-256 (compiler
   version), the target triple, the module name, and the module AST hash.
4. Links with `lumec --link`: emits the whole-program header/footer (bss, fixed rodata, runtime,
   `_start`, heap init, the entry module's top-level `print`/expression statements) from the
   fragment headers' flags, then `lasm` assembles as before. A full-cache-hit build spawns no
   per-module compilation at all.

Because fragments are content-addressed, a change to module M recompiles **only M**; unchanged
modules hit the cache (the final link always runs). Import changes do not cascade: fragments are
self-contained by construction (see below), so dependents' fragments remain valid; only the
fragment list at link changes.

## Soundness: the self-containment predicate

Split compilation is sound only when a module's compilation is independent of other modules'
content. The compiler enforces this per module (AST-level, in `lumec --ast-hash`): a module is
**not self-contained** — and the driver falls back to the ordinary whole-bundle build for that
invocation — when it declares or uses any cross-module-coupling construct:

- gradual types / signatures (`type`, `enum`, `record` decls, `Sig`, parameter or return
  annotations — whole-bundle gradual checking would see other modules),
- `pub fn` (public effect-row enforcement and osig inference are whole-program),
- `trait` / `impl`, `effect` declarations and `with handler` (handler lowering inlines
  callee bodies across functions),
- `comptime(...)`, `quote` / `unquote` / `splice` (comptime can call functions defined in
  other modules),
- typed holes (`_`), `requires` / `ensures` / `invariant` / `law` (verification is
  whole-program),
- AD (`grad`, `value_and_grad`, `jvp`, `vjp`, `jit`), `shard` / `vmap` (call-site lowering
  needs the callee body),
- `extern "c" fn` / `OSig` (FFI stub generation depends on whether the function is defined
  elsewhere in the bundle).

The fallback is real and tested: such bundles build exactly as they do without `--incremental`.
Modules the serializer cannot encode also fall back (the serializer fails loudly rather than
hashing two different ASTs the same).

Known, documented limitations of this increment (wave 1):

- Cross-module checks that whole-bundle compilation performs are skipped for self-contained
  modules (they compile against unknown callee signatures): cross-module gradual-type
  argument checks, per-parameter borrow-mode checks, and effect-row inference across modules.
  These return with a later wave (interface signatures in the cache key).
- The runtime tier selection (`has_sys`/`has_tier`/`uses_fs`/FFI links/ISR/kernel entry) is
  recomputed at link from per-module fragment flags; function layout order and code labels
  differ from a non-incremental build of the same source (byte-identical output is guaranteed
  *within* the incremental mode: cold cache vs warm cache produce the same bytes).
- Only `lume build --incremental` uses the cache; `run`/`test` and the bootstrap/zero-C gates
  are unchanged.
