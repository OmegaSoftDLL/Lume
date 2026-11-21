# Changelog

All notable changes to the **Lume** programming language and self-hosted toolchain are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **`buf_h264_deblock_edge` without per-edge list work; `buf_h264_deblock_edge_packed`; CAVLC Baseline by default (LumeDesk).**
  The wrapper packs bS / tC0 unrolled (it recursed over the lists with a recursive power: about 1 us of each edge);
  `buf_h264_deblock_edge_packed(buf, q0, across, along, lines, bstc, alpha, beta, chroma)` takes the word that
  `h264_bs_pack(bs0, bs1, bs2, bs3, tc0, tc1, tc2, tc3)` builds once. `buf_h264_cavlc4x4` (and the macroblock CAVLC)
  keep the stream valid for Baseline / Main / Extended: a level that would need level_prefix above 15 answers pos -1;
  nc + 4096 allows those escapes (High profiles).
- **Every public builtin is in the factual reference** (151 more entries, EN and PT, with runnable examples; status
  per builtin incl. kernel-only); builtins_regress_ok.src calls each documented builtin (54 tests).

### Changed
- **Integer loops run 30-40 % faster in ordinary code.** A function that loops by calling itself in tail position
  (literals, variables, operators, if, let and calls only; at most 6 parameters) is emitted twice: a specialized body
  entered when its integer parameters are small ints and its buffer parameters are buffers (one test), with no tag
  tests on values known small, plain compares instead of cmpv / eqv, buf_get / buf_set without the index tag and
  header checks, slow paths placed after the epilogue; and the ordinary body. Any operation that leaves the small-int
  range (a boxed result, a float, a string) calls the same runtime routine and continues in the ordinary body at the
  same point, so results and stops (overflow past 64 bits, bad index) are unchanged. Sum to 1e8: 1.75 -> 1.23 ns per
  iteration; a buf_get sum 3.75 -> 2.31 ns per byte; a SAD loop 6.98 -> 4.17 ns per byte.
- **`lumec --raw` (the compiler of the runtime written in Lume) is easier to write correctly.** Operands are computed left
  to right, as in ordinary Lume (the right one went first); functions and calls take more than 6 parameters /
  arguments (the 7th on in the caller's stack words, System V; such routines are never leaf routines); gen_runtime
  refuses a runtime whose code names a symbol nothing in the runtime defines (a typo, or a builtin the code generator
  emits only on demand), naming it, instead of a link error in the compiler's next generation. Every runtime source
  (compiler/stage1/rt/*.src) is laid out by `lume fmt`, one `let` per line; the generated runtime is byte-identical.
  Gate tests/harness/raw_abi_gate.src (left-to-right order, 8 and 9 parameters in a leaf, a framed routine and a loop).

### Fixed
- **Captured output lost on Windows while another process reads it.** The Win64 layer emulated flock with a
  mandatory byte-range lock over the whole file, so a child's writes into its capture file failed while a reader
  (fs_read_file takes LOCK_SH) held it; flock now locks one byte at offset 2^62, beyond any data, so it stays
  advisory as on Linux. And on every system os_run_capture / os_spawn_capture (and the timeout / input forms) with
  the same path for out and err opened it twice, the two streams overwriting each other; the child now duplicates
  the one descriptor. Test tests/runtime/spawn_capture_concurrent_ok.src.

### Added
- **`lume dev selfbuild` and `lume dev sync-check`: the toolchain's self-rebuild as a Lume command.** selfbuild
  (compiler/stage1/ldev.src) replaces the shell scripts that rebuilt the compiler by hand: it regenerates
  runtime_lume.lume, amalgamates the compiler and builds lumec generation after generation until two successive
  generations emit byte-identical assembly from the same runtime text; every generation must compile, assemble and
  run a smoke program before it may replace build/bin/lumec (a generation whose embedded runtime is incomplete never
  does). The tools (`--tools`, default lume_driver lcli lmanual lcaas lcert lmod lprotect ldapdbg lasm) are built
  aside and moved in only when all of them were built; on any failure the compiler, runtime_lume.lume and the
  amalgamated source are put back byte for byte and no tool is moved. `--check` stops at the fixpoint and reports
  whether the tree was current; `--root`, `--verbose`; an interrupted run is recovered by the next one. sync-check
  lists the files of compiler/ and tests/ that differ from another tree (the stale-tree trap). Tests:
  compiler/stage1/ldev_ok.src.
- **Compression at zlib level, and Zstandard (LumeDesk item 19), in Lume.** `use std/deflate`: `deflate_level(b, off,
  n, level)`, `zlib_compress_level` and `gzip_level` follow zlib's algorithm for levels 1-9 (level 0: stored blocks):
  hash chains over the 32 KiB window, zlib's good / lazy / nice / chain table, greedy matching with short-match
  insertion for levels 1-3 and lazy evaluation from level 4 (a length-3 match farther than 4096 is dropped, as zlib
  does), a block every 16383 symbols, each written in the smallest of stored / fixed / dynamic Huffman; the zlib header
  names the level (FLEVEL) and gzip's XFL marks levels 1 and 9. `deflate_buf` / `zlib_compress` / `gzip` are level 6.
  Measured against Python's zlib on 1 MB of text, 1 MB of Lume source, an ELF binary and skewed bytes: within 0.1 % of
  zlib at levels 1, 3, 4, 6 and 9 (smaller on 19 of the 20 level / input pairs, 0.01 % larger on the other), and
  Python's zlib decompresses every output. The
  Huffman code lengths are now built by the two-queue method over the sorted frequencies with the Kraft sum repaired
  after clamping (was a quadratic merge and frequency halving). `inflate_buf` decodes through 10-bit first-level tables
  and refuses what zlib refuses: more than 286 / 30 codes, over-subscribed or incomplete codes (except a single one-bit
  code), a missing end-of-block code, distances before the output, truncated data. About 1.5 MB/s compressing at level
  6 (5 MB/s at level 1) and 12-20 MB/s decompressing (were 0.34 and 1.5 MB/s).
  `use std/zstd` (new): `zstd_decompress` reads every RFC 8878 frame the zstd tool writes (raw, RLE and compressed
  blocks; raw, RLE, Huffman 1- and 4-stream and treeless literals; predefined, RLE, FSE-compressed and repeated
  sequence tables; repeat offsets; skippable and concatenated frames; the content size and the XXH64 checksum checked;
  frames that need a dictionary are refused), checked byte for byte against zstd 1.5.7 output at levels 1-19 and
  `--ultra -22`, `--long`, streamed input and corrupted frames (refused, never a crash). `zstd_compress_level(b, n,
  level)` (`zstd_compress`: level 3) writes one frame with the content size and the checksum, blocks of up to 128 KiB
  each raw, RLE or compressed (Huffman literals with direct or FSE-compressed weights, FSE sequences with the predefined
  or the block's own tables, repeat offsets), matched through hash chains over a 1 MiB window with lazy evaluation and a
  cost rule for short far matches; `zstd -d` decompresses every output. Level 3 is smaller than `zstd -3` on text,
  source, binary and skewed data, and level 9 is within 0.5 % of `zstd -9` on text, source and binary (1 MB/s compressing, about 10 MB/s decompressing).
  `xxh64_buf` / `xxh64` / `xxh64_hex` (XXH64, checked against xxh64sum). Tests: deflate_ok.src (20), zstd_ok.src (13).
- **Remote package registries (item 19, part C).** `lume pkg install|resolve --registry=https://host/path` (or
  `[registry] url = "..."` in lume.toml, or `LUME_PKG_REGISTRY`) reads an index registry: `lume-index.toml` holds one
  `[[package]]` table per version (name, version, archive, the archive's sha256, the package hash, deps). The index
  and the archives come through `std/http` (HTTPS with TLS 1.3 and certificate checks; plain http only to a loopback
  host unless `--allow-http`); a directory path works the same way. Archives are ustar `.tar.gz` files written
  reproducibly by Lume (`tar` reads them) and holding only lume.toml and NAME.src files; each is checked against the
  index's SHA-256 before anything is extracted, kept in a content-addressed cache (`--cache=DIR`, `LUME_PKG_CACHE`,
  default ~/.lume/pkg-cache), then staged, tested, proved and installed like a store package. lume.lock lines gained
  a source word (`URL#sha256=HEX`, `git+URL#COMMIT`), and a published version whose archive changed since the lock is
  refused. `--registry=git+URL` reads an index registry kept in a git repository (its commit pinned in lume.lock); a
  dependency `name = { git = "URL", rev = "REV" }` (`lume pkg add NAME --git=URL [--rev=REV]`) is fetched with the
  system git through os_run (no shell) and pinned to its commit until `--update`. `--offline` installs from a complete
  lume.lock and the cache without the network. `lume pkg publish [dir] --registry=DIR` writes
  DIR/NAME/NAME-VERSION.tar.gz and updates DIR/lume-index.toml (static hosting). The code is
  `compiler/stage1/lpkgreg.src`; tests `tests/registry/pkg_remote_ok.src` (index parser, archive round trip and
  refusals, `tar` interoperability, a tampered archive refused before extraction, a changed published version refused,
  an install over HTTP from a Lume server on 127.0.0.1, offline reinstalls, git pins and a git registry).
- **Package resolver and a lock that is honoured (item 19, part A).** The versions, the resolver and the lock format
  moved into `compiler/stage1/lpkg.src` (pure, tested by `tests/registry/pkg_resolve_ok.src`). `lume pkg install`
  now resolves the dependencies of dependencies too: each round picks, for every package named by the manifest or by
  a package picked before, the version lume.lock names while it still meets every requirement, else the highest
  stored version that meets all of them, until the picks settle; a conflict names each requirement and who made it
  (there is no search over older versions of a package whose own dependencies conflict). Requirements gained `>=`,
  `>`, `<=`, `<`, `=` and comma-joined lists (`">=1.2, <2"`); `lume pkg add` refuses a malformed one. Installs are
  reproducible: a later install keeps the locked versions, `--update` takes the newest, `--locked` refuses any change
  to lume.lock (CI), and a copy whose hash differs from lume.lock's is refused. Each picked package is staged under
  build/ and its own checks run there (`lume test` on every file with `fn test_`, now also `lume prove` on every file
  with contracts); a failure refuses the install and changes nothing (no lume_modules/ or lume.lock change) unless
  `--allow-failing`. Packages no longer required leave lume_modules/. `lume pkg resolve` prints the plan without
  changing anything. `lume pkg publish` runs the proofs too and checks a package with dependencies beside them,
  resolved from the same store.
- **`use par` and `buf_shared(n)`: data-parallel work on all cores (item 15).** buf_shared(n) is a buffer of n zero
  bytes in memory shared with the processes os_fork starts afterwards (outside the heap: never moved or freed).
  compiler/stage1/par.src starts a pool of worker processes once (`par_pool(n, fn(k, job) => ...)`); `par_run(pool,
  job)` runs the function in every worker at the same time and returns the sum of their answers once all are done, so
  their writes into shared buffers are visible; `par_slice(k, n, total)` cuts work into runs; `par_close` stops and
  waits for the workers. A video frame cut into slices (one per worker) encodes on every core. Test par_ok.src.
- **A larger standard library (item 19, part B), in Lume with tests next to each module:**
  `use std/json` (new, experimental): a strict RFC 8259 parser (number grammar, every escape, `\u` surrogate pairs,
  lone surrogates and ill-formed UTF-8 refused, `\u0000` kept as a NUL byte, depth limit 512, errors with line and
  column), values that keep each number's exact text, accessors, RFC 6901 JSON Pointer, builders, and compact /
  ASCII-only / pretty writers (json_ok.src, 32 tests). `use std/tz` (new, experimental): IANA zones from tzdata TZif
  files (RFC 8536 v1-v4 with the footer rule; `$TZDIR`, `/usr/share/zoneinfo`, ...), POSIX TZ rules (Jn / n / Mm.w.d,
  quoted names, times up to 167 h), fixed offsets, abbreviations, DST flag, and wall-clock to instant with gaps and
  overlaps resolved; checked against the system tzdata and against std/datetime's own rules over 20 years
  (tz_ok.src). `use std/encoding` (new, experimental): hex, base64 and base64url (RFC 4648 vectors, strict padding and
  trailing bits, MIME white space). `hash` gains SHA-224, SHA-384, SHA-512, HMAC (MD5 / SHA-1 / SHA-2), PBKDF2,
  CRC-32C and FNV-1a 32/64, checked against the FIPS 180-4 and RFC 4231 / 2202 / 2104 / 7914 / 6070 vectors. `deflate_buf`
  now writes the smallest of a dynamic Huffman block (length-limited codes, run-length coded header), the fixed code
  or stored blocks; Python's zlib reads its output, and random data grows by only 5 bytes per 64 KiB. `datetime` gains
  `dt_parse` (extended and basic ISO 8601 / RFC 3339, nanoseconds, the written offset), `dt_format` (strftime
  subset), `dt_yday`, `dt_iso_week`. `regex` gains `\b \B`, backreferences, lookahead, named groups, `(?i)`, `\xHH`,
  `re_named`, `re_group_names`, `re_find_all_groups`. `utf8` gains `utf8_next` / `utf8_fold` (walking by code point
  without a list), `utf8_check`, `utf8_sanitize`, `utf8_offset`, `utf8_encode_cp`, UTF-16 conversion, and case mapping
  for Latin Extended-A, Greek and Cyrillic. `csv` gains the strict `csv_parse_checked` and `csv_index` / `csv_get`;
  quoted fields are sliced instead of copied byte by byte.
- **Machine-readable diagnostics, one shape for every command.** `--json` on `lume check`, `prove`, `build`, `run`,
  `test` and `verify` prints `{"ok":bool,"diagnostics":[{"code","severity","file","line","col","message","fix"}],
  ...}` plus the command's own fields (build: source, output, exit, ms, log; run: exit, ms, stdout, stderr; test:
  tests with name, status, ms, message, output; verify: files with status, cached, detail). The compiler front end
  (lcaas) writes the flat fields itself next to its span and fixit; `fix` is the concrete fix-it of the message
  (`(fix-it: ...)`), and the driver maps bundle lines back to the user's files. A failure only lumec or lasm sees
  becomes one diagnostic from the located error text (the build runs in a forked child that captures it).
  `lume check --json` now prints the JSON on success too.
- **`lume test --filter <text>` and `--jobs <n>`.** The harness ltest generates selects its tests at run time
  (environment set by the driver): `--filter` runs only the tests whose name contains the text (one that matches
  nothing is an error); `--jobs n` runs one file's tests in n processes (test i in process i % n) or several files
  in n forked workers, and prints the report in source order, byte-identical to a serial run. Measured on Linux,
  warm cache: 8 test files 4.7 s -> 1.85 s with `--jobs 4`; tests/cli/json_and_test_ok.src 5.2 s -> 2.0 s (Windows
  145 s -> 48 s). `lume verify` also accepts `--jobs N` besides `--jobs=N`.
- **`lume query`: definitions, callers, callees and outlines for AI agents (compiler/stage1/lquery.src).** On large
  Lume code (the compiler's one-line functions run to thousands of characters) a grep hit is a whole function; `lume
  query defs NAME [PATH]` answers file:line, the signature (parameters, annotated types, requires / ensures) and the
  `##` doc comment; `lume query callers NAME [PATH]` every definition whose body calls NAME, with the line and column
  of each call and about 80 characters around it; `lume query calls NAME [PATH]` the names its body calls, each with
  where it is defined (the caller's file first); `lume query outline FILE` one line per definition (line, kind,
  name(params), first doc line). `--json` gives an array of objects (file, line, name, kind, signature, excerpt; doc,
  call_line / call_col, count, defined_at where they apply). PATH is a .src / .lume file with the modules it `use`s,
  or a directory (recursive; the amalgamated lumec.src next to lume/ is skipped); the default is the current one. The
  tokens come from the compiler's own lexer, so a name in a string, a comment, a """...""" string or a #[ ]# block
  never matches, and the calls inside string interpolation holes count. Only the items whose text holds the name are
  lexed (a file is cut at the declarations that lie outside strings and comments): `callers rt_int` over the 345
  files of compiler/stage1 in about 0.2 s, `outline` of 05_codegen.src (705 definitions) in 45 ms. Tests:
  compiler/stage1/lquery_ok.src.
- **One table of the builtins, and a gate that holds the compiler to it.** `compiler/stage1/builtins_table.src` lists
  every builtin once (name, arity, effect, name_flow lists, where its code is defined, reference and regression
  status). `tests/harness/builtins_gate.src` (run by the battery) reports every disagreement between the table and
  name_flow.src (arity lists and runtime groups), the effect lists of 06b_phase3.src and lcaas.src, the runtime text
  (runtime_core.lume, rt/*.src and runtime_lume.lume, 05_codegen.src), the factual reference in both languages and
  builtins_regress_ok.src; `@mode gen` rewrites those name_flow, 06b_phase3 and lcaas list functions from the table
  (plain `==`/`or` chains, the form the frozen seed compiles), so a new builtin is one table row plus its code, docs
  and test. Tests: tests/harness/builtins_sync_ok.src (reader, checker and generator on hand-made inputs, and the
  compiler on the defects below).
- **`lume debug --dap`: the real debugger over the Debug Adapter Protocol (item 21).** A DAP server on stdin / stdout
  (Content-Length framing or one JSON object per line) for editors and AI agents: launch (program, args, stopOnEntry)
  builds the program with the debugger's hooks and runs it under a monitor process; setBreakpoints (by line: the
  reply gives the line where it stops), setFunctionBreakpoints, configurationDone, stackTrace (each frame with its
  arguments, file and line), scopes, variables, evaluate, continue, next, stepIn, stepOut, disconnect / terminate;
  events stopped (breakpoint, step, entry, exception with the run-time error's message), output (the program's stdout
  and stderr), exited (its exit code) and terminated. The run-time debugger gained a followed command file (a path
  starting with `+`: at its end it waits for more lines) and the `mark` command that ends an answer. In the battery
  (compiler/stage1/ldapdbg.src).
- **The H.264 block pipeline in SSE2 (item 15, step 2 of 2):** residual, quantization, dequantization, inverse
  transform and reconstruction of every block builtin and macroblock builtin now run through `vec_res4`,
  `vec_quant4`, `vec_dequant4`, `vec_idct4` and `vec_rec4`: residual 136 -> 57 ns, dequantization 272 -> 65 ns, inverse
  transform 217 -> 46 ns, reconstruction 147 -> 59 ns, quantization 175 -> 127 ns per block; a chroma plane of a
  macroblock 4.2 -> 2.0 us. compiler/stage1/h264_blocks_ok.src now compares them with the formulas over the whole
  int16 range (-32768, saturation, 16-bit wrap). The scalar routines they replace are gone.
- **`lume verify` times every step:** each report line ends with the wall time of check, test, prove, the format check
  and certify for that file (also in the cached line), so the slow step of a slow file stands out; "1 file" in the
  summary. In the battery now (a passing file, a refuted contract, the cache).
- **lasm and `--raw`: the SSE2 the block pipeline needs (item 15, step 1 of 2).** lasm encodes `punpckldq`,
  `punpckhdq`, `punpckhqdq`, `pcmpgtw`, `pcmpeqw`, `pmulhuw`, `paddsw` and `psraw` / `psrad` / `psllw` / `pslld` with
  the count in an xmm register (byte-identical to GNU as, in the lasm gate's packed family). `--raw` gains
  `vec_res4`, `vec_rec4`, `vec_idct4`, `vec_quant4` and `vec_dequant4` (residual, reconstruction with saturation, inverse
  transform in 32-bit lanes, quantization with exact 32-bit products, dequantization), each equal to the scalar routine
  including the 16-bit wrap. The runtime starts using them in the next commit (a primitive must reach the installed
  lumec before the runtime can name it).
- **`buf_h264_cavlc_luma` / `buf_h264_cavlc_chroma(lev, ctx, out, pos)`: CAVLC of a whole macroblock (item 15).**
  From the levels as the macroblock builtins leave them: nC of each block by 9.2.1 (inside the macroblock from the
  blocks already written, at the edges from the neighbours' TotalCoeff passed in ctx), the coded_block_pattern and the
  order of 7.3.5.3 (Intra16x16 DC then AC; chroma DC of Cb and Cr with nC -1, then the AC blocks); each block's
  TotalCoeff comes back as the next macroblocks' context. Equal to the blocks coded one by one with
  `buf_h264_cavlc6` (compiler/stage1/h264_cavlcmb_ok.src).
- **Faster chroma motion compensation and DC-only blocks:** a chroma window inside the plane is interpolated from
  direct reads with the four weights computed once per block (no clamping per tap); a chroma or Intra16x16 block
  without AC levels is reconstructed as prediction + (d0 + 32) >> 6, its exact inverse transform, without the
  dequantization and inverse transform passes. Same results (all macroblock tests).
- **`buf_h264_mb_ic(srcu, srcv, recu, recv, cfg)`: intra chroma of a macroblock (item 15).** One
  intra_chroma_pred_mode for Cb and Cr (DC with the per-4x4 rules of 8.3.4, horizontal, vertical, plane) chosen by
  SATD over both planes, then each plane coded as `buf_h264_mb_pc` does with the intra rounding (the inter chroma and
  the intra chroma now share one plane coder). Checked against the predictions and the DC path written from the
  standard (compiler/stage1/h264_mbic_ok.src). With it a keyframe is complete in macroblock calls: luma by
  `buf_h264_mb_i16` / `buf_h264_mb_i4`, chroma by this one.
- **`buf_h264_mb_i16(src, si, ss, rec, ri, cfg)`: a whole Intra16x16 macroblock (item 15).** The mode of least SATD
  among those the neighbours allow, then the 16 residual blocks with the luma DC through the 4x4 Hadamard and its
  quantization, the AC levels, and the decoding of 8.5.10 (both sides of the qp 36 rule) into rec; a decide-only flag
  answers the cost without touching rec, so an encoder compares it with `buf_h264_mb_i4` before coding either. Checked
  against `buf_h264_intra16x16`, the block builtins and the DC formulas (compiler/stage1/h264_mbi16_ok.src). On a
  1080p screen keyframe 40% of the macroblocks choose it (the flat areas, far fewer bits).
- **`buf_h264_me16(src, si, ss, ref, cfg)`: motion search of a 16x16 macroblock (item 15).** (0, 0) and the
  predicted vector, a small diamond on SAD (SSE2) + lambda x vector bits within the range, then optionally the 8 half
  and quarter neighbours on the SATD of the interpolated prediction; deterministic, ties keep the earlier candidate, and
  a ring is skipped when no candidate can be cheaper (same result). Equal to the same search written with
  `buf_sad16x16`, `buf_h264_luma_mc` and `buf_satd16x16` (compiler/stage1/h264_me_ok.src). 1080p scroll with the right
  predicted vector: ~8 ms per frame at whole samples, ~19 ms with quarter refinement; a 320x200 window ~0.3 ms.
- **`buf_h264_mb_pc(src, si, ss, ref, rec, cfg)`: one chroma plane of an inter macroblock (item 15).** Eighth-sample
  prediction, the 2x2 DC Hadamard with the chroma DC quantization and scaling (8.5.11), the AC levels, qPc from table
  8-15 with chroma_qp_index_offset, and the reconstruction; DC levels, zigzag AC levels, counts and the plane's part of
  the coded_block_pattern come back in cfg. Checked against the standard's formulas (compiler/stage1/h264_mbpc_ok.src).
  ~4 us per plane and macroblock.
- **`buf_h264_mb_p(src, si, ss, ref, rec, cfg)`: a whole inter 16x16 macroblock in one call (item 15).** The
  quarter-sample luma prediction for one motion vector (as `buf_h264_luma_mc`), then the 16 blocks are subtracted,
  transformed, quantized with the inter rounding and reconstructed into rec; nonzero counts, zigzag levels and the
  luma coded_block_pattern come back in cfg, and the answer 0 marks a P_Skip candidate. Exactly the result of
  `buf_h264_luma_mc` plus the block builtins (compiler/stage1/h264_mbp_ok.src: integer and every quarter position,
  vectors pointing outside the picture, QP 0 and 51, a static block). About 8 us per macroblock with residual in
  every block: a 320x200 changed window (260 macroblocks) in ~2.2 ms.
- **`buf_h264_mb_i4(src, si, ss, rec, ri, cfg)`: a whole Intra4x4 macroblock in one call (item 15).** For each of
  the 16 blocks in decoding order it makes the predictions the neighbours allow, costs each with SATD + lambda x the
  mode bits (1 predicted, 4 otherwise), transforms, quantizes and reconstructs the cheapest into rec, and writes the
  modes, nonzero counts, zigzag levels (ready for `buf_h264_cavlc6`) and mode codes into cfg. It gives exactly the
  result of the block builtins called one by one (compiler/stage1/h264_mb_ok.src checks modes, levels, codes and the
  reconstruction on interior, edge and corner macroblocks and at QP 0 and 51) and replaces 16 x 9 calls and their
  glue. The diagonal modes are filled from one edge line per block through an offset table, a block without nonzero
  levels is reconstructed by copying its prediction, and the mode search stops when no remaining mode can win (same
  decisions). A 1080p luma frame, Intra4x4 everywhere: ~120 ms on screen content, ~230 ms on textured content
  (keyframe today: ~2 s in the encoder).
- **Diagnostic codes, all of them, with examples (item 20):** the reference (section 3a, EN and PT, also in
  `lume manual ref`) lists every code the tools report: what it means, which tool reports it and its example.
  `examples/diagnostics/` grew from 14 to 68 codes (`.bad` gives the code, `.fixed.src` is the corrected program);
  `tests/docs/examples_gate.src` runs all of them on every release and accepts `## command: lume agent kernel`.
- **`lume debug [--commands FILE] [-x CMD]... f.src [args]` (item 21):** the program is built with a call of the
  debugger at the start and at the return of each function (nothing inlined, variables start unset) and run. Text
  commands from the file, from each `-x` or from standard input: `break NAME` / `break FILE:LINE`, `delete [NAME]`,
  `continue`, `step`, `next`, `finish`, `bt` (each frame with its arguments), `args`, `locals` (parameters and every
  `let`, a record kept as fields shown as `r.f`), `print NAME`, `frame N`, `up`, `down`, `quit`, `help`. A run-time
  error stops in the debugger on the function where it happened, before the call stack is printed. Output on stderr,
  the program's own output unchanged; when the commands run out the program runs to its end, so an AI drives a whole
  session with `-x`. The run-time half is Lume (compiler/stage1/rt/rt_debug.src, in the optional runtime part); the
  code generator writes a table per function (start, name, file, line, each variable's name and frame slot).
- **Builds under `--profile` or `lume debug` skip the build cache:** its key did not include LUME_PROFILE, so a
  profiled binary could be reused by a plain `lume run` of the same source (and the other way round).
- **H.264 CAVLC (item 15):** `buf_h264_cavlc4x4(coef, ci, nc, maxc, out, pos)` in `use h264` codes one residual block
  (16, 15 or 4 int16 coefficients in zigzag order, nC 0..1 / 2..3 / 4..7 / 8+ / -1 chroma DC) into bits and answers
  {pos, total}; level escapes with level_prefix 15 and 16+, all coeff_token / total_zeros / run_before tables. The
  core is the runtime routine `buf_h264_cavlc6` (a 16-bit nonzero mask instead of coefficient scans): about 320 ns
  for a typical block and 60 ns for an empty one. Checked against the LumeDesk encoder's 12 vectors, whose streams
  ffmpeg decodes (h264_cavlc_ok.src).
- **H.264 luma motion compensation in SSE2 (item 15):** `buf_h264_luma_mc` computes the half-sample planes (b, h, j)
  8 pixels at a time and every quarter position as one plane or the rounded average of two. A 16x16 block now takes
  about 0.6-0.8 us instead of 3.6-6.6 us (8x8 centre 1.8 -> 0.36 us, 4x4 0.7 -> 0.2 us), with the same results
  (every fraction and every w, h in 4 / 8 / 16, inside and across the picture edges: h264_mc_ok.src). New `--raw`
  vector intrinsics `vec_hp6h`, `vec_hp6v`, `vec_hp6c`, `vec_avg8`, `vec_avg4`; lasm encodes `psubd` and `pslld`.
- **Standard library (item 19), in Lume with tests:** `use std/hash` (CRC-32, Adler-32, MD5, SHA-1, SHA-256 against the
  published vectors), `csv` (RFC 4180), `utf8` (characters over byte strings), `datetime` (civil dates, ISO 8601,
  US / EU / Sydney daylight rules), `regex` (backtracking: groups, alternation, lazy quantifiers, replace with $1),
  `deflate` (inflate of stored / fixed / dynamic blocks, LZ77 deflate, zlib and gzip with checked trailers; zlib and
  Python read what it writes), `http` (HTTP/1.1 client: chunked, gzip, redirects, deadlines) and HTTPS through `tls`:
  a TLS 1.3 client (X25519, AES-128-GCM / ChaCha20-Poly1305) whose server certificates are checked by `tlspki` (RSA
  PKCS #1 v1.5 and PSS, ECDSA P-256 / P-384, SHA-384 / SHA-512, X.509 chains, host names with wildcards) against the
  system roots: SSL_CERT_FILE, the Linux bundle, or the Windows ROOT / AuthRoot stores read through `lchameleon`
  (when a root is not there yet, Windows is asked to fetch it and the chain is checked again in Lume). `bignum`:
  integers of any size with Montgomery arithmetic. Checked against example.org, google.com and github.com on Linux and
  Windows, and against local TLS 1.3 servers: a wrong host and an untrusted root are refused.
- **Package versions (item 19):** `lume pkg publish [dir] --store=DIR` runs the package's tests and stores
  NAME/VERSION immutably with the SHA-256 of its files; `lume pkg add NAME[@REQ]` writes the dependency into
  lume.toml (REQ `1.2.3`, `^1.2`, `~1.2.3` or `*`); `lume pkg install --store=DIR` resolves each dependency to the
  highest stored version it allows, copies it to lume_modules/, checks its hash, runs its tests there and adds a
  `[packages]` block (name, version, hash) to lume.lock, which `lume pkg verify` checks; `use NAME` finds an installed
  package. The store can also be named by LUME_PKG_STORE (tests/registry/pkgver).
- **`lume verify [--jobs=N] <file.src>...`:** check, test, prove, fmt --check and certify for many files in N worker
  processes (os_fork, default 2). Each file's result is cached under build/cache/verify by the SHA-256 of its whole
  bundle (the file and every module it imports) and of the tools, so an unchanged file never runs again and a change
  re-verifies only the changed module and the files that import it (LumeDesk: 130 files, 1 h 16 per full run).
- **Call stack on run-time errors:** after the message, one `  at NAME (file.src:LINE)` line per frame, innermost
  first. The code generator emits a table of the program's functions (address, name, file and line from the bundle
  markers and the map the driver names in LUME_SRC_MAP); `rt_trace` (compiler/stage1/rt/rt_trace.src, Lume) walks the
  frame chain with every frame checked before it is read. Inlined functions and tail calls leave no line.
- **Codec builtins without allocation:** `buf_h264_luma_mc`, `buf_h264_deblock_edge`, `buf_h264_intra4x4` and
  `buf_h264_idct4x4` use a static 4 KiB scratch block of the runtime instead of an allocation per call.
- **Builtin contracts in the prover:** `lume prove` knows that `buf_bits_write(b, p, v, n)` answers `p + n` or `-1`,
  `buf_get` 0..255, `buf_len` / `count` >= 0, `buf_sad*` / `buf_satd*` >= -1 and `buf_h264_quant4x4` -1..16, when the
  call's result is named with `let` or is the function's result (each `let` gets a variable of its own; a disjunctive
  contract is proved case by case). `tests/prove/builtin_contracts_ok.src`.
- **Official examples:** `examples/topics/` (basics, lists, records, types, strings, contracts, buffers, floats,
  modules, files; each passes `lume test`) and `examples/diagnostics/` (for 14 diagnostic codes the failing program
  `CODE_name.bad` and the corrected `CODE_name.fixed.src`); `tests/docs/examples_gate.src` runs them in the battery.
- **`buf_sad4x4` in SSE2** (`vec_sad4`, one psadbw per row) instead of a byte loop.

- **Screen, capture, input and windows on Windows (`use winsys`):** `win_displays()` (rectangle, effective DPI, scale,
  rotation, primary, refresh; the process becomes Per-Monitor-V2 aware), `win_virtual_screen()`; Desktop Duplication
  capture through Direct3D 11 written in Lume over COM vtables (`win_capture_open/frame/frame_into/close`: BGRA frames,
  dirty rectangles, pointer position, "lost" on a desktop switch), GDI BitBlt fallback and `win_capture_gdi`;
  `win_cursor()` and `win_cursor_shape()`; SendInput (`win_send_key` with Set-1 scancodes, `win_send_vk`,
  `win_send_text`, absolute mouse moves on the virtual desktop, buttons, wheel in 1/120), `win_key_state`,
  `win_async_key_down`, `win_send_sas`; a viewer window without callbacks (`win_window_open`, `win_window_events`,
  `win_window_draw` with StretchDIBits); the WH_KEYBOARD_LL hook (`win_kbhook_*`, layer pseudo call 1016).
- **Video colour conversion:** `buf_bgra_to_i420` and `buf_i420_to_bgra` (BT.601 limited range), runtime routines
  written in Lume (`compiler/stage1/rt/rt_video.src`).
- **TUN interfaces (`use tun`):** layer-3 virtual interfaces for VPNs, written in Lume: Linux `/dev/net/tun`
  (TUNSETIFF, address / netmask / MTU / up through socket ioctls, epoll-able descriptor) and Windows Wintun
  (wintun.dll over the generic Win32 call, address through the IP Helper API). `compiler/stage1/tun_ok.src` sends a UDP
  datagram into the interface and reads it back as an IPv4 packet (Linux as root); without the privilege the open fails
  with its reason.
- **Block distortion for encoders:** `buf_sad16x16`, `buf_sad8x8`, `buf_sad4x4`, `buf_satd4x4`, `buf_satd16x16`
  (SAD and 4x4 Hadamard SATD between two blocks of byte buffers with their own strides), runtime routines written
  in Lume, checked against a reference in `compiler/stage1/video_sad_ok.src`. SAD uses SSE2 `psadbw`: the sixteen-by-
  sixteen SAD of every macroblock of a 1080p frame takes 1.3 ms (25 ms without the vector instruction).
- **SSE2 in lasm and --raw:** `movdqu`, `psadbw`, `paddq`, `paddd`, `paddw`, `psubw`, `pxor`, `psrldq` (byte-identical
  to GNU as) and the --raw vector intrinsics `vec_sad16(p, q)` / `vec_sad8(p, q)`. Routines that use them
  (`rt/rt_simd.src`) are linked only into programs that name them, so the frozen seed assembler never meets them.

- **SSE2 forward transform:** `buf_h264_fdct4x4` runs in SSE2 through the --raw intrinsic `vec_fdct4` (butterflies
  and word transposes, exact mod 2^16): 375 -> 36 ns per block on Linux, 29 ns on Windows, same results (random
  blocks in h264_blocks_ok.src).
- **Bit writing for entropy coders:** `buf_bits_write(b, pos, v, n)`, `buf_bits_read(b, pos, n)`, `buf_bits_ue` /
  `buf_bits_se` (Exp-Golomb), runtime routines in Lume (bits_ok.src checks them against a bit-by-bit reference).
- **lasm:** packuswb, packssdw, pavgb, pmullw, psrad and psllw by an immediate; the assembler gate gained the family
  `packed` (25 families byte-identical to GNU as).
- **Version stability:** docs/STABILITY.md states the 1.x promise (a stable item is never removed or changed in
  1.x), the deprecation period (at least one whole MINOR release), the per-release checks on Linux and Windows and
  the 1.2 long-term-support line. A comment `## Deprecated: <message>` directly above a function marks it; every
  call from another module warns [W0005] with the message (the bundler reads the comment, so no tool changes).
- **Floating point in the language:** a parameter declared `: f64` converts its argument with `f64(x)` (a
  decimal literal such as `3.0` is accepted there by both checkers); f64 arithmetic and comparisons pass `lume check`;
  `use math` adds sqrt, exp, log, log10, pow, sin, cos, tan, atan2, floor, ceil, round, abs_f, fmin, fmax, tofloat,
  is_nan, is_inf, f32 (single-precision rounding, ties to even) and buf_f32_get / buf_f32_set; warning [W0004] where
  an int meets an f64; `lume prove` gives the reason when a contract over f64 is runtime_checked.
- **H.264 motion compensation and deblocking** (`use h264`, runtime routines in Lume): `buf_h264_luma_mc` (quarter-
  sample 6-tap luma, 8.4.2.2.1), `buf_h264_chroma_mc` (eighth-sample bilinear chroma, 8.4.2.2.2) and
  `buf_h264_deblock_edge` (weak and strong filters of one edge, 8.7.2.3 / 8.7.2.4), checked against a reference
  written from the standard's formulas (`compiler/stage1/h264_mc_ok.src`).
- **Profiler:** `lume run --profile f.src [args]` compiles the program with counters (rdtsc at each function entry
  and after each return to a caller) and prints on stderr at exit, also after a trap or `os_exit`: per function the
  self and total time, calls and allocations, plus the GC runs and time, sorted by self time. Same numbers on Linux
  and Windows.
- **Factual reference manual:** `lume manual ref` (`lume manual --pt referencia`) and `docs/LUME_REFERENCE_{EN,PT_BR}.md`
  list only what works today, with a status per builtin and module (stable / linux / windows / experimental /
  privileged), known limits and a "changed in this version" section; every example in it is run by
  `tests/docs/ref_examples_gate.src` with the exact output written under it. `lume manual vision` marks the design
  and research material of chapters 1-10 as such.
- **Builtins regression test:** `compiler/stage1/builtins_regress_ok.src` calls every documented builtin family; a
  builtin missing from a release fails to compile there. It runs on Linux and Windows.
- **H.264 building blocks** (runtime routines in Lume, `rt/rt_codec.src`): `buf_h264_fdct4x4` / `idct4x4`,
  `quant4x4` / `dequant4x4`, `sub4x4`, `recon4x4`, `intra4x4` (9 modes), `intra16x16` (4 modes), checked against a
  reference written from the standard's formulas (`compiler/stage1/h264_blocks_ok.src`).
- **Module-private functions:** `priv fn` is renamed per module by the bundler, so other modules cannot call it and
  it never collides with their names; one name defined in two modules gives warning [W0003].
- **The chameleon's C ABI door on Windows:** `chameleon_c_open(path)` loads a DLL only from an absolute path inside
  System32 or Program Files with a valid Authenticode signature (WinVerifyTrust), dependencies resolved from its
  folder and System32; `chameleon_c_sym` / `chameleon_c_call` answer `unverified[int]`; `chameleon_verify_boundary`
  (documented before, now real) promotes a value. `use tun` on Windows loads Wintun only through it.
- **Record flattening:** small functions (builtins only) and functions returning a record literal are inlined, and
  a record whose fields only are read lives in locals: `consome(produz(z))` 1.3 s -> 64 ms. `LUME_FL=off` turns it
  off (it is part of the driver's cache key).

### Changed
- **Standard library behaviour (item 19, part B):** `dt_parse_iso` refuses text after the zone; `utf8_encode` writes
  U+FFFD for a surrogate or an out-of-range code point and a NUL byte for 0 (it stopped before); lenient `csv_parse`
  keeps text after a closing quote in the field (`"a"b` gives `ab`; it started a new row before); regex class ranges
  work across UTF-8 lengths (`[a-ž]`), and `re_find_all` no longer stops on an empty match at the end of the text.
- **Runtime in Lume: try / fail and the runtime stops** (new compiler/stage1/rt/rt_fail.src, ordinary programs only):
  __lume_try_begin / end / msg, __rt_try_fail, ctfail, __rt_die3, __rt_die_now and the error stops (__rt_not_str,
  __rt_not_int, __rt_need_int, __rt_ovf, __rt_div0 ...), over the frame_ptr / long_jump intrinsics. Same messages,
  stack traces, nesting limit and recovery on 18 more cases (176 in all).
- **Code alignment is on** under `lume run` / `build` / `test`: every runtime routine, every function and its tail-call
  loop head start on a 32-byte boundary (lasm learned the directives in the previous step). The runtime text carries
  a comment as the mark (`#p2align`), turned into `.p2align 5` only then: plain `lumec < file` stays byte-identical to
  the seed's oracle and assembles to the same ELF with the frozen seed assembler (the gate that caught it).
- **Fixed: `--protect hardened` / `max` missed conditional jumps** to renamed routines (`js __rt_goob` in the runtime's
  assembly reaching a stop now written in Lume: "undefined symbol"): lprotect renames the target of every jump
  (jmp and jcc); unit test.
- **Record field lookup, the match / heap-cap / out-of-memory stops in Lume** (rt_text.src __rt_recfind; rt_fail.src
  __rt_no_match, __rt_env_cap reading LUME_HEAP_CAP, __rt_cap_oom, __rt_alloc_oom). The groups rt_fail, rt_records,
  rt_die, rt_env and rt_cstr hold no assembly any more; three unreachable routines (__rt_mc1, .Lrt_rg_miss,
  .Lrt_rup_miss) were removed. Same messages and exit codes as before.
- **The whole f64 runtime is Lume** (rt/rt_f64.src; rt_f64 is now only its generated group, 1061 lines of assembly
  gone): f64(x) with the text reader (sign, nan / inf, 18 significant digits, e / E exponent), f64_sin / cos / tan /
  log / log10 / exp / atan2 / pow (x87 extended precision, the same 2^t path and special cases), f64_sqrt / abs /
  floor / ceil / round / int / is_nan / bits / from_bits and f64_str(v, k); identical results on 13 more cases, math_ok
  passes.
- **f64 runtime in Lume: __rt_fstr** (str and print of an f64: the shortest text that reads back to the same double,
  x87 extended precision through the raw intrinsics, the same search and layout as the assembly); identical digits
  from subnormals to inf, -0.0, nan and 140 values in scientific notation.
- **f64 runtime in Lume, first part** (new compiler/stage1/rt/rt_f64.src, the rt_lume_f64 group that only programs
  using f64 get): + - * / with an f64 on either side (SSE2 on the bits), the comparison (NaN stops as before), equality,
  and an int or decimal turned into a double (a decimal through x87 extended precision, the same powers of ten);
  identical on 7 more cases, math_ok passes. rebuild_core cuts what rt_f64.src defines only inside rt_f64 (rt_f64_stub
  keeps the same labels), and a cut no longer drops a local routine that the part of the segment it keeps still uses.
- **`lumec --raw` floating-point intrinsics** (for f64 in Lume, the next step): IEEE doubles as their 64 bits in
  general registers (fp_add / sub / mul / div / sqrt, fp_of_int, fp_trunc, fp_cmp with 2 for unordered) and x87 values
  of extended precision in 16-byte memory slots (x87_ldi / ldd / std / sti, x87_add / sub / mul / div, x87_rnd, x87_yl2x,
  x87_f2xm1, x87_scale, x87_sin / cos / tan / atan2, x87_const, x87_getcw / setcw): each one loads, works and stores, so
  no x87 register is held across Lume code. 27 checks in a standalone raw program. lasm encodes fldt / fstpt
  (identical to GNU as).
- **The stop on a run-time error starts at the user function again:** runtime routines now written in Lume keep frames
  of their own on the way to a stop (__rt_div, rt_divi, __rt_div0), so __rt_die_now walks up to the first frame whose
  return address is in the program's code (__rt_fntab) before the trace and `lume debug`'s stop on the error (the
  battery's debugger tests caught it).
- **Runtime in Lume: mkstr, __rt_mkstrn, __rt_stralloc, mklist** (short strings packed in the value, longer ones in a
  string cell). Fixed: the assembly mklist wrote r13 without saving it.
- **Runtime in Lume: mkint** (the most used routine: a leaf whose ordinary path touches only %rax and takes no jump;
  the boxed case is __rt_mkbox); crypto, H.264 and all 264 runtime cases unchanged.
- **Runtime in Lume: __lume_rec_update** ({r with k: v}); 5 more cases, 261 in all.
- **Runtime in Lume: recget and lidx** (r.k, xs[i], s[i] on arrays, strings and Cons lists, with the same stops);
  14 more cases, 256 in all.
- **Runtime in Lume: addv, addvs, __rt_sub / mul / div / mod, +% -% *%, __rt_qnext**: overflow found without the
  flag (signs of a sum, a product divided back), division by zero and MIN / -1 stop as before, f64 / decimal hooks
  through global names; 21 more cases, 242 in all. Fixed: the assembly addvs (string +) wrote r12-r14 without saving
  them.
- **Runtime in Lume: eqv** (equality of strings, boxed ints, lists, records, constructors, decimals, f64): nested
  values recurse and the last field goes on as a loop of leaf routines (jumps), so a Cons list of any length keeps the
  stack flat and no work-list cell is allocated any more; the decimal check moved out of the assembly (.Lrt_deqv is
  gone); 11 more cases, 221 in all.
- **Runtime in Lume: cmpv and cmpvi** (comparisons of strings, boxed ints, decimals, f64): the f64 and decimal
  hooks got global names (__rt_anyf, __rt_fcmp, __rt_anyd, __rt_dcmp) next to their local ones; 10 more cases.
- **Runtime in Lume: __rt_memcpy, wstr, __rt_write and __rt_decstr** (decimals as text: 1.20, -0.125, 0.05; the
  string is sized first and filled from the end, no temporary buffer); 12 more cases, 200 in all. The dead
  __rt_chr_bad went with chr.
- **Runtime in Lume: the LZ compressor and decompressor, the pack checksum, `mem_pack` / `mem_unpack`** (new
  compiler/stage1/rt/rt_pack.src). Packed bytes identical to the assembly's (compared byte by byte), damaged packs
  stop the same way; packing is faster than the assembly (match ends compared eight bytes at a time). Each loop is one
  routine calling itself in tail position (a jump), so the stack never grows with the data.
- **`lumec --raw`: a loop's tail self-call leaves alone the arguments that pass a parameter on unchanged** (no push /
  pop for them).
- **`lumec --raw` intrinsics `frame_ptr()` and `long_jump(sp, fp, addr, v)`** for the try / fail runtime: the
  routine's own %rbp (a routine that reads it keeps its frame), and a jump that sets %rsp / %rbp / %rax (written
  as `pushq; ret`, which the frozen seed assembler also knows).
- **Runtime in Lume: showval and printval** (rt_text.src): every value print shows (ints, strings, lists, records,
  constructors, decimals, f64, nested values, opaque ones) comes out the same on 18 more cases.
- **Runtime in Lume: wch, wint, print_int, emit, flush and __rt_write_fd1** (compiler/stage1/rt/rt_buf.src, the
  part of the runtime that only ordinary programs get, never a `@freestanding` kernel; the buffer builtins and
  utf8_chr moved there too, where their assembly lived). Same output on 11 more cases (emit buffering, direct string
  writes, flush, big outputs). Fixed: the assembly print_int wrote %rbx without saving it.
- **Fixed: `--protect hardened` / `max` broke a tail call between two runtime routines** (`jmp rt_fs_put` kept the
  old name after the routines were renamed; "undefined symbol"): lprotect renames the target of a `jmp` to a
  renamed function like a `call`'s; unit test in lprotect.src.
- **Runtime in Lume: str, strni and utf8_chr** (rt_text.src), same results on 17 more cases (both ends of the int
  range, boxed ints, f64, values shown by __rt_show_str, every UTF-8 length and the invalid code points).
- **Runtime in Lume: slice, slicen and toint** (rt_text.src), same results and errors on 31 more cases (ranges out of
  bounds, boxed indexes, toint at both ends of the int range and past them).
- **Fixed: the assembly `slice` overwrote r12, r13 and r14** without saving them (registers its caller may keep values
  in); the Lume version keeps the calling convention.
- **Runtime in Lume: ord, ord_at, at, chr and count** are Lume source now (rt_text.src); same results and errors on
  81 cases against the assembly; `at` is faster than the assembly, ord_at/count on par in loops.
- **`lumec --raw` code quality** (every runtime routine written in Lume): a leaf routine may make up to three calls
  (a call in tail position is a jump, any other saves the leaf registers around itself); in a leaf's tail position
  each branch ends in its own `ret` and a branch that only calls a runtime stop (`__rt_*`) is laid out after the
  ordinary path, so the ordinary path takes no jump; `bit_and(x, m) == 0` is one `testq`; a comparison or a load
  uses a value where its register holds it; `load8(b + d + x)` uses the `d(b,x)` addressing form; a right operand
  waits in %rcx instead of the stack when the left one leaves %rcx alone.
- **Code alignment:** lasm accepts `.balign N` and `.p2align K` in code (filled with the recommended multi-byte NOPs,
  aligned to the real load address of each output format) and the `nop` instruction. The compiler starts using them
  in the next step (a toolchain built before this one could not assemble them): every raw runtime routine, and under
  `lume run` / `build` / `test` every function and its tail-call loop head, on a 32-byte boundary. A small hot loop
  ran at half or full speed depending on where the code before it ended (the same ord_at loop: 32 or 65 ms per 10
  million calls).
- **Runtime in Lume: buf_new, buf_copy, buf_slice, buf_from_str and buf_to_str** are Lume source now (rt_text.src),
  same results and errors on 44 cases (overlapping copies too); copies go eight bytes at a time, so buf_copy of 4 KiB
  is 1.7x and buf_slice 1.5x faster than the assembly. rt_slen, rt_sptr and rt_copyn moved from rt_fs to rt_text.
- **Runtime in Lume: buf_len, buf_get and buf_set** are Lume source now (compiler/stage1/rt/rt_text.src), cut from
  the runtime's assembly text. Same messages and exit codes on every error path; buf_len through the runtime routine
  went from 2.0 to 1.6 ns per call.
- **`lumec --raw`: `a and b` / `a or b` in a condition compile to jumps only** (no boolean is built and tested
  again); every runtime routine written in Lume gains from it.
- **English only, as the language always was:** the Portuguese alias `lume guia` is gone (`lume manual --pt`,
  `manual-pt` and `man-pt` stay); the English manual header says "Lume builds Lume"; every message, page and reply
  `lsentience` writes (the cockpit page, the consult / talk / replicate / self-build texts, the approval words it
  recognizes: approve / disapprove) is English, and `voice_language` is `en-US`. The manual and help stay bilingual.
- **Faster buffer and arithmetic loops:** `buf_get` / `buf_set` compile to inline machine code on the common path
  (the runtime routine only for a boxed index, a wrong value or an out-of-range index, with the same diagnostics);
  `x % k` and `x / k` by a literal k >= 2 divide in place. A 1080p-sized buffer copy loop: 51 -> 10 ms on Linux,
  20 -> 7 ms on Windows.
- **Faster allocation:** the collector keeps the whole chunks a collection frees mapped and zeroed for reuse, up to
  the collection limit, instead of returning each to the OS and faulting it in again (peak RSS unchanged; everything
  is still returned under `LUME_HEAP_CAP`). Steady allocation: 20 -> 8 ns per object, system time 0.16 -> 0.02 s on a
  5-million-record loop.
- **Faster field reads:** `r.name` checks a per-field cache inline (record shape -> field offset) and calls the
  runtime only for another shape; misses still go through the full checks. A record build-and-read loop: 31 -> 19 ms
  per million, closures 16 -> 8 ms.
- **Runtime split:** the file-system part of the Lume runtime (`rt_fs`, `rt_io`) is no longer linked into
  `@freestanding` kernels; text and video routines stay shared.

- **Constant literals allocate nothing:** a list literal of constants (`[10, 11, 13]`) and a record literal of constants
  are static cells in .rodata, shared by every evaluation (2 million `seq_nth([...], i)`: 154 -> 24 ms; a constant
  `if` chain takes 15 ms). `compiler/stage1/const_list_ok.src` checks equality, strings, shared tails, `with` copies
  and that a million evaluations leave the heap unchanged.
- **Collector pacing:** the next collection comes after `max(8 MiB, 3 x live)` bytes instead of `max(64 MiB, 3 x
  live)`: a small service stays near 9 MB of RSS (68 MB before) at the same allocation speed.

### Fixed
- **Builtin lists that disagreed (found by the first run of the builtins table gate):** `ord_at`, `mem_crc64`,
  `vga_puts`, `vga_fill_row`, `vga_scroll_up`, `vga_set_cursor` and `bv_add_u8` / `bv_sub_u8` / `bv_mul_u8` had no
  arity, so a call with the wrong argument count compiled and read stale registers (now [R0202]); 14 names of runtime
  routines that no longer exist (`std`, `stl`, `stp`, `stro`, `strcmpv`, `cnts`, `mkctor`, `mkrec`, `alloc_grow`,
  `cmpvgt`, `cmpvlt`, `eqvc`, `eqvi`, `eqvs`) were still reserved, so a program's own `fn std(...)` was refused with
  [R0201]; `vga_*` and `mem_crc64` drive or read hardware memory but had no effect, so a `/ pure` function could call
  them (now `sys`, like the MMIO and port builtins); the lcaas oracle had no effect for 62 builtins the compiler gives
  one (ports, MMIO, CPU, `sys_call`, io_uring, pipes, `printval`, `fs_write_hex_file`, `gc_collect`, ...) and a
  different one for `epoll_*`, `os_exit`, `os_sleep_ms` and `fs_sha256_file`, so it reported those effect errors only
  through the compiler's fallback message, without a span; its stale `os_wall_sec` entry is gone. The reference names
  `buf_sad8x8`, `buf_sad4x4`, `buf_satd16x16`, `buf_h264_idct4x4` and `buf_h264_intra16x16` in full, and
  builtins_regress_ok.src now calls every documented builtin but `os_exit` (`buf_slice`, `buf_bits_se`, `emit`,
  `flush`, `fs_mkdir`, `net_last_peer_ip` and `os_arg_at` were missing).
- **buf_get / buf_set with a boxed (huge) index crashed** with "invalid memory access" (exit 139): the assembly
  read it as a small int. Now the runtime's own out-of-bounds error (exit 3); battery test.
- **A build with the debugger could come back from the build cache as a normal build:** `lume build` (the path
  with options) cached a binary built under LUME_DEBUG, keyed only by the source and the tools, so the next plain
  build of the same source (after `lume debug --dap` or `LUME_DEBUG=... lume build`) got the debugger and its command
  file. Builds under LUME_DEBUG are never cached now (the other path already excluded them), and the key moved to build-v7 so
  entries cached before are not served; battery test.
- **CI (Native CLI driver job), found by running the CI jobs locally while the GitHub account is locked:** the seed's
  `len()` change (a2e014b) did not update `bootstrap/lume0/SEED_FREEZE.sha256`, so the audit gate's diverse double
  compilation refused to rebuild the frozen seed; the hash of interp.c is updated (seed-maintenance change, same
  output). The driver gate's LSP fixture `fn broken(` now expects [P0001], the code of a delimiter still open at the
  end of the file since a2e014b.
- **The standard library passes `lume verify`:** bignum, csv, datetime, deflate, h264, hash, http, regex, tls,
  tlspki, utf8 and math were not in canonical `lume fmt` form, so `lume verify` on them failed at the format step;
  they are formatted now (no change of meaning; every module's tests pass) and all 13 modules pass verify.
- **`lume verify` no longer fails a file that has no contracts:** with 0 obligations `certify` answers
  "unverified", and verify took that as the file failing; a file with nothing to certify passes that step.
- **CI: the seed's `len()` of a string built a list of its characters on every call** (bootstrap/lume0/interp.c):
  `len()` of a 2 MiB source allocated 128 MiB, so on macOS (where the cross-platform checks run the compiler in the
  seed interpreter) each such check took about 40 minutes and the job hit the 6-hour limit. The count is now taken in
  place and cached in the string (strings are immutable), with a one-to-one index for all-ASCII text: 1589 -> 6 ms
  for 30 calls on a 2 MiB string.
- **CI: `lume cli-parity` (Native CLI driver job):** both manuals are again exactly what `lume manual --export`
  writes; they mention `lume pkg ... [--store=DIR]` and `lume pkg audit`; "fmt --check" in the text of `lume verify`
  (read as an option of verify) became "the format check"; the gate knows that only `lume pkg audit` and
  `pkg publish --store DIR` go to the legacy script now.
- **`crc32` of `std/hash` no longer builds its 1 KiB table on every call:** messages under 2048 bytes are computed
  bit by bit (no table), longer ones keep the table; a test checks both paths agree around the switch.
- **[E0305] no longer moves an immediate:** an int literal or a bool put into a record sent with
  `chan_send_linear`, or read out of it before the send, is a copy and stays usable by the sender (it was rejected
  as a use of the moved value). A heap part, an alias or a computed int (it may be a boxed cell) still moves with the
  record. tests/runtime/linear_imm_ok.src.
- **A delimiter still open at the end of the file is [P0001]** (`expected ')' at end of input`), as the code was
  documented; it was reported as [P0002], so P0001 could never appear.
- **`lume check` named the bundle's line in a lex error's text:** the message said "(started at line 11, col 7)" for
  what the span correctly gave as `main.src:4:7` (the bundle puts imported modules first). A diagnostic with a span
  no longer repeats the compiler's own place in its text.
- **Intra prediction on the picture edge:** `buf_h264_intra4x4` and `buf_h264_intra16x16` answered -1 for every block of
  the first row, even when the mask did not declare the neighbours above. Only the neighbours the mask declares must
  lie inside the buffer now (an undeclared one outside reads as 128, a declared one outside is still -1); interior
  blocks are unchanged (8640 predictions compared byte for byte). LumeDesk report.
- **A call through a parameter checked against a global function:** `fn name_of(env) = env("A")` was typed against
  another module's `fn env(n: int, body)` ([T0500]); a call through a parameter or a let-bound name is now the local
  value's call (tests/namespaces/localcall/localcall_ok.src).
- **Item 15, faster codec blocks:** `buf_h264_quant4x4` computes qbits, f and the multipliers once per block and
  handles two levels per 32-bit read and write (488 -> 288 ns per block); `buf_h264_intra4x4` vertical, horizontal and
  DC write four 32-bit rows straight from the frame (250 / 236 / 136 -> 66 / 86 / 68 ns).
- **Item 15, inverse transform and diagonal intra modes:** `buf_h264_idct4x4` works a row at a time from 32-bit reads
  (513 -> 238 ns); the six diagonal Intra4x4 modes read every sample from one edge line and its 2- and 3-tap filters,
  computed once per block (674 -> 375 ns); `h264_blocks_ok.src` checks all six with and without the top-right samples.
- **macOS Stage-0 job (6 hours, 9 time-outs):** the frozen interpreter computed `len()` of a string by building a list
  of its characters (64 bytes each); once the bundled checker source passed 2 MiB every `len` of it allocated 128 MiB
  and forced a full collection. `len` and string indexing now count in place with a cached codepoint count (an
  all-ASCII string indexes in O(1)): the interpreted `lume agent check` takes 55 s instead of more than 1000 s. The
  generated runtime text is also split into functions of at most 400 lines, and lmod's deprecation scan skips lines
  that cannot hold a marker.
- **W0004** never fired on parameters typed `f64`: the checker did not type `f64(...)`, the parameter wrapper.
- **`lume fmt` and `priv fn`:** the syntax check before formatting refused `priv fn` ([P0003]); it is accepted, and
  the formatter keeps the `priv` of every private function.
- **buf_h264_luma_mc and the collector:** the luma window and the b1 table were separate allocations reached only
  through a block the collector does not scan; a collection inside the call could free them, and the same call gave
  different blocks. One allocation now holds all three (h264_mc_ok.src keeps the reproduction).
- **`use std/NAME`:** a project module called h264.src hid the standard library's `use h264`; `use std/NAME` always
  names the library module.
- **W0003 and `priv fn`:** a name the entry file declares `priv fn` no longer counts as defined in two modules.
- **Nested constant literals:** a list of constant lists (`[[10, 16, 13], [11, 18, 14]]`) and a record holding
  records or lists were rebuilt on every call (6 million allocations per million calls); they are static data now,
  like flat ones.
- **Windows launcher at the prefix:** `C:\Lume\lume.exe` (next to `bin\`) found its tools one folder too high
  ("native driver tool failed: lcli status 32512").
- **Git Bash:** the POSIX `lume` runs the native `lume.exe` when it is there; on the Stage-0 fallback `lume fmt`
  refuses instead of rewriting a file wrongly (it dropped `+%` and contracts).
- **Bootstrap guard:** the stage-0 compiler built by the seed must pass a smoke program before anything is built with
  it (shim, `lume bootstrap`, Zero-C); a miscompiling seed stops the bootstrap with the cause.
- **Manuals:** the reserved-names table (2.1.1) and loops with `seq_loop` in both languages; `use tun` describes the
  chameleon rule (the old text suggested a DLL next to the program).
- **Field reads, two record shapes:** the inline field cache is one per read site, no longer one per field name. A
  producer reading its input and a consumer reading the producer's output (different shapes, same field names)
  evicted each other on every read: `consome(produz(z))` took 1.3 s for 500 000 rounds, now 148 ms, the sum of its
  parts (LumeDesk report).
- **C0009 and the `ct_` prefix:** a C0009 inside a function named `ct_*` now says that the prefix made its
  parameters secrets (all of them, or only those named `secret` / `secret_*`), and the manuals (EN / PT) document the
  convention with an example.
- **Types:** a value typed `any` (a `-> any` result) is accepted by any parameter, and a parameter typed `any`
  accepts any value; both were refused once the checker had seen another type.
- **Shared libraries:** `lasm --shared` writes section headers (`.dynsym`, `.dynstr`, `.dynamic`, ...), so GNU ld
  and lld can link a C host against a `.so` built by Lume; static `.a` builds go through the archive path again.
- **Driver:** a tool that fails without printing anything (or is missing) is reported with its path and status, never
  as an empty error.
- **hostio:** `env -C DIR program` runs the program in DIR (the capstone gate's health check used it).
- **hostio / fs_copy:** a bare program name (`env PATH=dir cc`) is looked up through `$PATH`, as execvp does, and
  `fs_copy` gives a new file the permission bits of its source, as `cp` does (a copied program stays executable);
  the Zero-C gate's toolchain blockers were not found, then not executable.
- **Runtime:** `os_getenv` of an unset variable returned the next string of the runtime's data when the runtime was
  assembled by the seed (`.byte 0` was dropped); the empty string is written as `.asciz ""`.
- **Formatter:** `compiler/stage1/f4_core.src` and `lfmt.src` are in canonical form again after the line-breaking
  formatter; incremental link mode records the f64 / decimal / crypto runtime flags.
- **Windows:** programs run by `lume run` / `lume test` that create a Direct3D device no longer die at exit
  (0xC0000005 in the graphics driver, reported as status 139): scratch binaries are named `.exe`.
- **CI:** the frozen seed (`lume0`) compiles the compiler again (a parameter was named `as`); the release workflow
  checks the version of the tag instead of a fixed 1.1.0.

## [1.2.0] - 2026-11-17

Native Windows toolchain (`lumec --win64`, `lasm --pe`, the Win64 runtime layer) with results identical to Linux on
the full test universe, and the requests of the first production application (LumeDesk).

### Added
- **Native Windows x86-64 toolchain:** every tool built as a PE executable by Lume itself; Win64 layer with fd table,
  lazy memory, VEH, real fork, Winsock, epoll and io_uring emulation, C FFI with the Win64 ABI, DLLs written by Lume
  (`lasm --pe --shared`), a native installer. Test files and programs give the same results on Linux and Windows.
- **Runtime in Lume:** strlen/streq, 31 `fs_*`/`os_*`/`io_*` builtins, `read`/`readall`, X25519 and Ed25519 point
  math are Lume source (`compiler/stage1/rt/*.src`, `lumec --raw` with register allocation and leaf routines).
- **Files:** `fs_read_range(path, offset, n)`, `fs_truncate(path, size)`, `fs_rename_noreplace(from, to)`.
- **Processes (`use process`):** `os_spawn_pipes`, `os_fd_read_some`, `os_wait_nohang`, `os_kill_tree`,
  `os_run_capture_limit` (bounded output, the tree killed at the deadline); `os_run_capture_timeout` kills the whole
  tree (a new process group on Linux, a Job Object created suspended on Windows).
- **Inventory (`use sysinfo`):** `fs_statvfs(path)` and `net_interfaces()` (name, MAC, addresses with prefix).
- **Windows system (`use winsys`):** registry reads (`reg_get_string`, `reg_get_dword`, `reg_key_exists`,
  `reg_value_exists`), sessions (`wts_active_console_session`, `wts_sessions`, `wts_session_user`,
  `process_session_id`), `services_running`; service management and the service dispatcher (events through an
  epoll-able descriptor), processes in a user's session (`win_spawn_as_session`), local named pipes (non-blocking,
  epoll-able, SDDL DACL, client pid), input desktop and the capture-excluded privacy window.
- **Crypto (`use lcrypto_tls`):** AES-128/256 and AES-GCM, ECDSA P-256 (RFC 6979), X25519/Ed25519 over strs,
  incremental `lcs_sha256_init/update/final` and `lcs_hmac_sha256_init/update/final`.
- **Network:** IPv4/IPv6 interfaces, socket local address, non-blocking `net_tcp_connect_start/result`.
- **`map`:** HalfSipHash-2-4 keyed per map with splitting buckets (collision-resistant), `map_keys`, `map_fold`.
- **`lume fmt`:** long lines broken to the end of the expression (one `let` per line, `if` branches indented),
  lambdas, `{r with ...}`, contracts and match arms included; idempotent and compiler-checked.
- **`lume check --lex`**, record update `{r with f: v}`, module aliases and relative module resolution.

### Changed
- **Prover:** bounded products (McCormick, bounds up to 2^62, from `requires` or from the path, inside `let`/`if`),
  booleans used as values proved as 1/0, laws that use the callee's proven `ensures`.
- **Certificate kernel (`lcert`):** the four McCormick inequalities, linear-expression factors, division by a variable
  with a positive lower bound, boolean equality, let/if lifted out of comparisons.
- **Checks:** `[T2101]` follows records through functions and both branches of an `if`; `+` with a list is `[T0604]`
  with the `seq_concat` fix-it; reserved words are refused as names at the declaration.
- **Keychain error contract:** `not_found` only when the entry does not exist (`access_denied`, `unavailable`,
  `corrupt`, `not_private`); the Win64 layer reports `ENOTDIR` like Linux.


### Added (Wave 14 -- clean-room verification, `[C0011]` constant-time crypto kernels, `2oo2D` split envelope, cross-module synergy & qualification `PASS`)
- **`OmniProof-v4` & signed Tool Qualification Dossier `PASS` (`compiler/stage1/lqualify.src`, `compiler/stage1/lume_driver.src`):**
  `lume self-prove` runs `16` self-hosted proof batteries discharging `1,682` formal obligations (`0` runtime-checked or
  refuted), `372` unit tests, `122` sovereign evolution domains (`#0..#121`), and `134` verified `MANIFEST.sha256`
  files. `lume qualify` achieves `PASS` across `106/106` diagnostic/adversarial probes, `21/21` end-to-end verification
  gates, and `10` HLR + `44/44` LLR (`VERIFIED`), emitting `docs/certification/QUALIFICATION_DOSSIER.md` signed with
  Ed25519 and X.509v3 (`docs/certification/QUALIFICATION_SIGNING_CERT.der`, verified by `lume qualify --verify`) alongside
  `docs/RELATORIO_AUDITORIA_E_CERTIFICACAO_CLAUDE_PT_BR.md`.
- **Translation-validation hub, runtime helper verification & clean-room SMT checker (`compiler/stage1/ltv.src`, `compiler/stage1/ltv_rt.src`, `compiler/stage1/lsmt.src`):**
  `lume tv` validates `694` functions from `.src` down to emitted x86-64 (`0` rejected, `7,846` native boundary vectors,
  `687/687` 1-to-1 AST-to-object branch correlation). `lume tv-rt` (`tv_rt_gate` / `lume tv-rt-gate`) symbolically
  verifies all `18/18` integer runtime helpers across `268` paths / `462` obligations. `lume smt-check`
  (`smt_cert_gate` / `lume smt-cert-gate`) checks `100%` of `.smt2` proof obligations with a self-contained clean-room
  `QF_LIA`/`QF_BV` solver in full `unsat` agreement with external `z3` (`94` certificates, `3,820` mutants rejected).
- **Complete native MC/DC closure & static stack byte analyzer (`compiler/stage1/lmcdc.src`, `compiler/stage1/lstack.src`):**
  `lume mcdc` reaches `0/9,618` uncovered MC/DC conditions on compiled native binaries across all four certified modules
  (`compiler/stage1/lstd.src` `0/980`, `examples/safety_envelope/critical_kernels.src` `0/112`,
  `compiler/stage1/lchameleon.src` `0/2,392`, and `compiler/stage1/lsentience.src` `0/6,134`). `lume stack` statically
  bounds worst-case stack bytes on emitted x86-64 for `@no_alloc` `[E0210]` kernels (`K0010..K0013` diagnostics on frame
  overflow, indirect calls, stack cycles, or dynamic `rsp`), paired with p99.99 jitter measurement in
  `tests/harness/realtime_gate.src`.
- **`118` `[C0011]` constant-time crypto kernels, `Ed25519 X.509v3` & NIST SP 800-90B OS entropy (`compiler/stage1/lcrypto_tls.src`, `compiler/stage1/lx509.src`):**
  `118/118` `@secret @no_alloc` `[C0011]` branch-free cryptographic kernels in `compiler/stage1/lcrypto_tls.src` pass
  transitive `[C0010]` machine-code constant-time validation and `lstack` stack bounding (max `536 B`), backed by a
  `24`-target `dudect` Welch $t$-test harness (`|t| <= 2.690 < 4.5`). `lume x509 verify` and `lume x509 show` enforce
  Ed25519 X.509v3 DER/PEM path validation (`6,000/6,000` tampered certificate chains rejected) and X.509v3 TLS 1.3 peer
  authentication; `lume entropy` wraps OS CSPRNG reads behind NIST SP 800-90B repetition-count and adaptive-proportion
  health checks.
- **`2oo2D` clean-room RV32IM Channel B & multi-board split bundle (`compiler/stage1/lsafety_envelope.src`, `compiler/stage1/lrv32_lowered.src`):**
  Channel B executes on a clean-room RV32IM image sharing `0/3,169` compiler functions in the gate bundle (`87,224`
  injected faults -> `0` false negatives) and supports multi-board cross-architecture bundle generation, hash/signature
  verification, and split frame execution (`--split`, `--split-verify`, `--split-run`, documented in
  `docs/41-safety-envelope-split-bundle.md`).
- **Cross-module synergy gate, scale gate & CLI parity (`tests/harness/synergy_gate.src`, `tests/harness/lcaas_scale_gate.src`, `tests/cli/driver_gate.src`):**
  `lume synergy-gate` (`synergy_gate`) executes `17/17` chained cross-module stages on
  `examples/synergy/critical_pipeline.src` (`lcaas` -> `lcert` -> `lproof_cache` -> `lumec --critical` -> `ltv` ->
  `ltv_rt` -> `lsmt` -> `lstack` -> `lmcdc` -> `lx509` + `lcrypto_tls` -> `lsafety_envelope` -> `ltv_multiarch`) and
  rejects `36/36` cross-tamper scenarios (`0` undetected). `lume lcaas-scale-gate` (`lcaas_scale_gate`) verifies deep
  `lcaas` scaling, and `lume cli-parity` (`native_driver_gate`) checks `114` dispatch-table rows (`226` command/alias
  names) across `9` documentation and CLI surfaces with `0` mismatches.

### Security (Wave 14 hostile audit, round 3 -- `[C0011]` precedence, interprocedural `@secret` taint, JSON brace escapes, source-tree hygiene & `lcert` integration)
- **`R3-1` (`[C0011]` vs `[C0009]` precedence on `@secret @no_alloc` kernels):** Both `compiler/stage1/lume/06b_phase3.src`
  and `compiler/stage1/lcaas.src` delegate `@secret @no_alloc` functions directly to `ctk_chk_fn` rather than running the
  generic `@secret` branch check first, ensuring secret-dependent `if` / `match` / `&&` / `||` inside constant-time
  kernels deterministically emit `[C0011]` (aligned with `synergy_gate` tamper probes `T-E2` and `T-E3`).
- **`R3-2` & `R3-2b` (interprocedural `@secret` taint & branch-free primitives):** Added cycle-guarded interprocedural
  `@secret` taint propagation (`[C0009]`) through unannotated helper callees in `compiler/stage1/lume/06b_phase3.src` and
  `compiler/stage1/lcaas.src`, `secret_*` / `ct_*` taint roots on `@asm` kernels in `compiler/stage1/ltv.src`,
  branch-free `bit_and` / `bit_xor` / `bit_or` MBA helpers in `compiler/stage1/protect.src`, and promoted
  `ct_tag_xor_diff` in `compiler/stage1/lume_crypto_blockchain_engine.src` to a branch-free `@secret @no_alloc` kernel
  validated by `ltv` `[C0010]`.
- **`R3-3`..`R3-5` (JSON string-interpolation brace escapes & structural validation):** Fixed depth-0 `"}}"` brace
  collapses in `tests/harness/safety_envelope_gate.src`, `compiler/stage1/lchameleon.src` (`lume chameleon --json`),
  `compiler/stage1/lsentience.src` (`lume crypto-engine --json`), and `tests/cli/driver_gate.src` (`dg_mcp_call`),
  enforced end-to-end by tail-recursive `json_well_formed` parsers in `compiler/stage1/lqualify.src`,
  `tests/harness/safety_envelope_gate.src`, and `tests/cli/driver_gate.src`.
- **`R3-6` (clean-tree invariant under `--json` domain commands):** `lume quantum-nexus --json` writes its temporary
  pulse artifact to `/tmp/lume_quantum_pulse.qbin` rather than leaving untracked artifacts in `compiler/stage1/`.
- **Real `lcert` kernel invocation & driver soundness:** `lume certify` invokes the standalone `compiler/stage1/lcert.src`
  kernel for its `"kernel_verified"` verdict (never hardcoded), `compiler/stage1/lcert.src` supports disequality
  splitting alongside `06b_phase3.src` and `lcaas.src`, `compiler/stage1/ltv.src` enforces mandatory JSON report fields,
  bundle-cache digests hash transitive imports, `lume test` isolates concurrent temp binaries by PID, and
  `build` / `check` / `prove` / `certify` / `test` / `run` never write to `$HOME`.

### Security (Wave 14 hostile audit, round 1 -- prover, termination, effects, `@bound`)
Each item is a reproducible unsound verdict of the released toolchain, with its reproducer among the fixed cases of
`tests/harness/prover_fuzz.src` (`pf6_fixed_a` / `pf6_fixed_b`, run by `prover_fuzz_gate` and `claude_audit_gate`) and in
`bootstrap/lume0/tests/run_native.src` (`w14_*`).
- **The prover took every parameter for an integer.** `fn cat(a, b) ensures result == b + a = a + b` was `proven` and
  its check elided; `cat("x", "y")` returned `"xy"`. `a + b` concatenates when an operand is a string, `<` orders two
  strings, and a declared `: int` is not checked on a dynamically typed call path (`f(hd(xs))`). A name is now an
  integer of the linear model only on EVIDENCE: an evaluated use that traps on every non-integer (`- * / %`, the
  wrapping and bit operators, an ordering against an integer), on the path where that evaluation happened. Until then
  it is a handle: it can be passed, projected, compared with itself and ORDERED against another handle (so
  `imax(a, b)` is still proven, for strings too), and no arithmetic is built from it. A declared `int` parameter is a
  second attempt only, and the compiler then guards the parameter on entry (`let _vty_ok = p - 0`).
- **`total fn` over untyped values.** `total fn lp(a, b) terminates (b - a) = if a < b then lp(a + 1, b) else 0` was
  accepted; `lp("a", "b")` never returns. Same rule as above, with the evidence of the path to each recursive call.
- **`total fn` recursing through its own contract.** `total fn f(n) requires f(n) > 0 = 1` was "not recursive" and
  overflowed the stack. A clause that reaches the function again is refused (`[A0002]`); a callee's clauses count as
  part of that callee.
- **`simd_add4_i64` / `simd_sub4_i64` were modelled as `4 * (a + b)` with no range.** The lanes wrap:
  `requires a >= 0 ... ensures result >= 0` was proven and `f(2^61, 0)` returned `-2^63` with exit status 0. The model
  now needs `-2^61 <= a + b < 2^61` entailed.
- **Effects under `/ pure`.** (1) A callee defined ABOVE its caller's callee was invisible to the inference (the callee
  body was inferred against the tail of the function list): `fn w() = <effect>`, `fn k() = w()`,
  `fn top() / pure = k()` was accepted. (2) Nothing was seen more than 24 calls down. (3) A parameter or `let` named like
  a pure program function hid an effectful closure (`fn h(g, x) / pure = g(x)`). (4) `with handler panic { ... }`
  discharged the builtin effect of `os_exit`. (5) 72 runtime builtins that act on the world carried no effect at all
  (`fs_write_hex_file`, `os_fork`, `os_monotonic_ns`, `printval`, `port_out8`, ...). All five are fixed; a declared row is
  now checked against the primitive effects of everything the function can reach. Consequence, stated plainly: the
  compiler's own passes were declared `/ pure` and are not (`lumec_check` reads the command line, `lumec_expand` reads
  the files of `comptime embed`); `07_driver.src` now declares `/ {io}` and `/ {io, fs}`.
- **`@bound(cycles: N)` did not count a `match` arm or a record field.** A 300000-step function passed
  `@bound(cycles: 20)`. (A call through a parameter was already charged 100000 cycles; that path is only made explicit.)
- **The compiler aborted with `integer overflow`** on `requires x - 9223372036854775807 - 1 >= 0` (the prover negated
  the minimum integer).
- **Lexer:** `12abc`, `1e3`, `0x1G`, `0b12`, `1_` lexed as a number followed by another token. Where that token was a
  defined name or a digit the statement grammar accepted the pair (`print 12abc` printed 12, `print 0b12` printed 1);
  otherwise the program died on an unrelated name error. `[L0003]` now.

### Security (Wave 14 hostile audit, round 2 -- operand keys, `@secret`, the sampling refuter)
Reproducers: `pf6_fixed_c`, `pf6_kernel` and `pf6_wide_check` in `tests/harness/prover_fuzz.src`; the compiler mutant
`bv_key` of `claude_audit_gate`.
- **One prover variable named two different bit operations.** The opaque term of `bit_and` / `bit_or` / `bit_xor`
  joined the keys of its operands with `*`, the separator of a product, so `bit_and(a, b * c)` and
  `bit_and(a * b, c)` were both the variable `bv_and(a*b*c)`:
  `fn g(a: int, b: int, c: int) -> int ensures result == bit_and(a * b, c) = bit_and(a, b * c)` was `proven` by
  `lumec` (check elided, `g(1, 2, 3)` returned 0 where the clause wants 2), by `lcaas`, and its proof term was
  re-derived by the `lcert` kernel ("Lume Verified"). The operands are now separated by a comma in all three engines
  (`vbv_key`, `lk_bv_key`).
- **`@secret fn` returned a promise.** `ois_async` tested bit 128 of the function flags, which is `@secret`; `async fn`
  is bit 256. `@secret fn f(a: int) -> int = a` printed `<opaque>` and `f(1) + 1` died with a type error, while an
  `async fn` returned its plain value. Behaviour change to note: the value of a call of an `async fn` that is not
  awaited is now a promise (`print s(3)` prints `<opaque>`; `block_on` / `.await` are unchanged).
- **The sampling refuter built 16^n environments.** A function of eight parameters bounded 0..100 took `lumec` 4.9 s
  with no `ensures` and more than 100 s with one; `lume prove` ran out of memory. Both engines now
  keep the full product only up to 65536 environments and otherwise sample the diagonals (every parameter at its c-th
  smallest / largest point, so the corners of a box of bounds are always tried) and a bounded sub-product. Measured
  after the fix: 0.12 s for 8, 12 and 16 parameters; the false bound `result <= 100` is still refuted with `[V0001]`
  at the corner `p1 = ... = p8 = 100`. The refuter only finds counterexamples: sampling less never proves anything.
- **`lcaas` reported `proven` where `lumec` kept the check**, for a contract over `simd_add4_i64` / `simd_sub4_i64`
  without a range and for a callee whose name is a parameter: its second attempt proves the cleaned certificate term,
  which reads the intrinsic as `4 * (a + b)` and inlines the program function of that name. Where a contract can reach
  either, only the verdict of the compiler's engine counts now (`cs_w14_unclean`).
- `vnia_split_star` split an opaque key at a `*` inside its parentheses. Examined: that was incomplete, not unsound
  (the two halves are unbalanced strings that no row mentions, so their lemmas constrain fresh variables only); it now
  splits at depth 0.

### Security (Red Team Round 4 — prover, certificate kernel and assembler soundness)
Each item below was a reproducible FALSE theorem reported as `proven` (the compiler elided the runtime check and the
program printed a wrong answer), found by an oracle-checked fuzzer and by adversarial review. Every fix ships a
regression in `tests/harness/claude_audit_gate.src` (`cag_check_redteam_r4`) and, where a guard was added, a compiler
mutant that the gate must kill (`cag_check_compiler_mutants`).
- **`ensures` read a body-level `let` that shadowed a parameter** (`fn f(x, y) ensures result == x = let x = y in x` was
  proven). Postconditions are now resolved in the parameter scope only; certificate terms rename body binders apart.
- **`requires` was no longer checked at run time once `ensures` was proven.** A proof of `requires => ensures`
  discharges the postcondition check only; the precondition check stays (callers are not all verified).
- **`bit_shl` was modelled as multiplication without a range guard** (it wraps at 64 bits) and **`bit_shr` of a negative
  constant was folded with truncation** (it is an arithmetic shift: `bit_shr(-9, 1) == -5`); the sampler had the same bug.
- **Quantifiers:** the prover's internal symbol `_q<d>_<name>` could be spelled by a parameter; an `exists_range`
  witness was substituted under a `forall_range` that rebinds the witness's variable. Quantified symbols are now
  unspellable and substitution is capture-avoiding and binder-aware (compiler and kernel).
- **Name-based models:** a program function called `clone`, `verify`, `dec_add`, ... was verified as the builtin of that
  name while the generated code called the user's function; `old`, `forall_range`, `exists_range` could be redefined
  (`[R0201]` now). The array / separation-logic theories apply only when the definitions present are the canonical model.
- **`lcaas` carried a second, diverging copy of the decision procedure.** Its `proven` verdict now comes from the
  compiler's prover (`use lumec`), so there is one engine to audit.
- **`lcert` kernel:** accepted two false proof terms (witness capture, quantifier-symbol collision); fixed, with
  regression tests in `compiler/stage1/lcert.src` and in-process fuzzing of the kernel.
- **Fourier–Motzkin** now eliminates the cheapest variable first and drops trivially true / duplicate rows (sound: it only
  weakens the system), which restores the bounded non-linear proofs of `self-prove`.
- New `tests/harness/prover_fuzz.src` / `prover_fuzz_gate.src`: random expressions over a box, brute-force oracle, false
  contracts one past the true extrema; lumec must keep the check, lcaas and the kernel must not prove.
- **Kept `requires` checks found two real precondition violations in shipped code:** the OpenTPU pipeline called
  `otpu_qact_dequant_subblock` with shift 4 (specified for 0..3; callers now saturate through `otpu_qact_da_sat`), and
  `lumeputer_stack_pop_frame_sp` rejected the stack pointer its own `push` produces (precondition restated as
  `sp_bytes + frame_words * 4 <= 32768`).
- **`lasm` (differential against GNU as, `tests/harness/lasm_gate.src`):** five instructions were encoded with different
  bytes than GNU as (`movzbl %sil/%dil`, `testq`/`testb` and `xchgq` with a memory source, `vmovdqu` from `%ymm8-15` to
  `%ymm0-7`, `int $3`), and a large class of input was accepted and silently mis-assembled (operands on zero-operand
  instructions, `pushq $imm`/`pushq mem`, unknown suffixes such as `addw` encoded as 64-bit, immediates and displacements
  that do not fit, `%rsp` as index, invalid scales, hex/octal literals, unknown directives dropped with their data, ...).
  All of it is now a hard `[L0001]` error with no output bytes. The gate generates 39,968 instruction lines in 21
  families and compares them byte for byte with GNU as on every run, checks 1,467 documented alternate encodings by
  disassembly, and requires 176 invalid lines to be rejected. Compiler output is byte-identical before and after.
- `compiler/stage1/m1_prover_ok.src`: `bv_shift_scale` claimed `bv_shl(x, 3) == x * 8` for every `x >= 0`, which is false
  past 2^60; it now carries the bound that makes it true.

### Added (Wave 11 — certification tools, Domains `#112..#115`)
- **`ltv`** (`compiler/stage1/ltv.src`, `lume tv`): translation validation of the x86-64 text `lumec` emits, per integer
  function, against the lowered AST (trap equivalence, value in `%rax`, division / modulo / call effects, frame
  discipline). `tests/harness/tv_gate.src` mutates every instruction of a fixture and requires every
  behaviour-changing mutant to be rejected.
- **`lmcdc`** (`lume mcdc`): decision and masking MC/DC obligations of the lowered AST, every witness run on the real
  binary; obligations without a witness are reported as theorem-false, infeasible (proved by the `lcert` kernel) or
  uncovered.
- **`lsafety_envelope`** (`lume safety-envelope`): 2oo2 lockstep of the native x86-64 channel against the LumePuter
  RV32IM monitor under a cycle budget and a valid `ltv` certificate; any other outcome latches `SAFE_STATE_TRIP`.
  `examples/safety_envelope/critical_kernels.src` holds the kernels, `safety_envelope_gate` the fault injections.
- **`soak_battle_gate`** (`lume soak`): collector stress, OS fault injection, concurrent determinism, and a
  hash-chained telemetry ledger.
- **`lqualify`** (`lume qualify`): probes, module batteries and gates behind a bidirectional traceability matrix; writes
  the TOR, TQP, RTM, evidence and dossier to `build/certification/`. It is developer evidence, not a qualification.

### Added (Wave 12 — industrial tools, Domains `#116..#121`)
- **`@no_alloc`** (`[E0210]`, transitive over the call graph), **`--keep-proven-checks` / `--critical`**, linear
  channels (`[E0305]`) and lock-rank / wait-cycle checks (`[E0306]`) in `06b_phase3.src`; `lconcurrency.src` and
  `tests/harness/concurrency_gate.src`.
- **DWARF v4** from `lumec --dwarf` and `lasm` (`.debug_abbrev`, `.debug_info`, `.debug_line`, `.symtab`, `.strtab`)
  and the **incremental proof cache** `lproof_cache.src` (`[PC0001]`..`[PC0005]`); `dwarf_cache_gate`.
- **`lcrypto_tls.src`** + `stdlib/crypto.lume`: SHA-256/512, HMAC, HKDF, ChaCha20-Poly1305, Ed25519, the TLS 1.3 key
  schedule and record layer, checked against the official vectors by `crypto_tls_gate`.
- **AArch64 / RV64 / RV32 kernel back ends** (`larm64.src`, `lriscv.src`, `lkir.src`) with their own translation
  validator (`ltv_multiarch.src`); `multi_arch_gate` compares encodings with LLVM's assembler and executions on
  `qemu-aarch64`, `qemu-riscv64` and the LumePuter.
- **Neural cartridges** (`lneural_cartridge.src`, `--target safetensors`): a `/ pure` integer function as RV32IM words
  and integer SwiGLU weights in a `.safetensors` file; `safetensors_gate`.

### Added (Wave 13 — closure audit)
- **X25519 (RFC 7748) and the TLS 1.3 handshake state machine** in `lcrypto_tls.src`, with their vectors and
  fail-closed negatives in `crypto_tls_gate`.
- **`lcert --check-source <file.src>`** (`lume verify-cert --check-source`): the certificate kernel reads the contracts
  of the source itself and refuses a certificate whose obligations are not those of that file;
  `tests/harness/cert_source_gate.src` forges re-hashed certificates that the plain kernel accepts and the binding
  check must refuse.
- **`[C0010]` in `tv_gate`**: a branch-free `@secret` function is validated, the same `+` that is validated in a
  public function is rejected in a secret one, and three injected leaks (branch, memory access, division) are each
  rejected with their reason.
- **`lumec` front end before the multi-ISA lowering**: `ltarget` releases no AArch64 / RISC-V image for a kernel that
  `lumec` rejects (`[T0902]`; `[T0903]` when `lumec` cannot be found); `multi_arch_gate` checks it on three triples.
- **`tests/harness/realtime_gate.src`**: `@no_alloc` and `--keep-proven-checks` had no test. Seven `[E0210]`
  rejections, zero allocations measured with `heap_stats()` over the accepted kernels, and the kept `ensures` check.
- **`lqualify`**: seven more gates (`G-DWARF-CACHE`, `G-CONC`, `G-CRYPTO`, `G-MARCH`, `G-SAFETENSORS`, `G-REALTIME`,
  `G-CERTSRC`; 16 gates, 70 probes, 31 low-level requirements in all),
  their requirements and positive / negative probes, a ninth high-level requirement (traceability and binding of
  records), a SHA-256 chain over the sections of `QUALIFICATION_EVIDENCE.json`, a detached Ed25519 signature
  (`QUALIFICATION_EVIDENCE.sig.json`, developer key outside the repository) and `@verify <dir>` to re-check a package.
- **Driver**: `lume build --dwarf|-g`, `--keep-proven-checks|--critical`, `--target safetensors [--entry <fn>]`,
  `lume proof-cache`, `lume qualify --verify`, and the Wave 12 gates as commands. The help text listed these options
  before the driver implemented them.
- **Installer** (`scripts/install.src`): the Wave 11-12 binaries, their sources and `stdlib/` are installed and hashed
  in `MANIFEST.sha256`.
- `docs/certification/`: the generated TOR, TQP, RTM and dossier of the qualification run, with the public signing key.

### Fixed (Wave 13 — closure audit)
- `lsentience.src` called seven Wave 12 domain kernels with the wrong number of arguments, so `lsentience` and
  `lume_driver` no longer compiled (`[R0202]`).
- `lcaas.src` had lost `@mode bind-raw` / `bind-raw-source` (`lume adapt c --preprocess`), so `c_adapter_gate` failed;
  restored.
- Help and domain texts named `[E0300]` / `[E0301]` for `@no_alloc`; the compiler emits `[E0210]`.
- **`lcaas` effect inference was exponential in call depth**: it re-inferred the body of every callee without a
  declared effect row at every call site. `lume prove compiler/stage1/lcrypto_tls.src` took 180 s (past the driver's
  120 s budget) against 3 s in `lumec`; with a per-program memo it takes 4 s. Output is byte-identical on eight
  modules compared before and after.
- **`lcaas` certificate terms could capture a variable**: flattening `let y = (let t = v in b1) in b` moved `b` and
  the postcondition under the callee's binder `t`, so a caller parameter called `t` was captured. The verdict was
  never affected (the prover binds through environments, `06b_phase3.src` has no such rewriting), but the term in
  the certificate stated something about the wrong variable. The binder is now renamed; `cert_source_gate` and the
  `lqualify` probes `P-CAP-POS` / `P-CAP-NEG` hold the regression.
- `lcert --check-source` reads the SIMD intrinsics `simd_add4_i64` / `simd_sub4_i64` as `lcaas` lowers them, so
  `compiler/stage1/lstd.src` binds 117 of 117 obligations.

### Added
- **Compact values.** A value is one word: an integer of 63 bits and a string of at most 7 bytes live in it and never touch the heap, and `int` keeps its full 64-bit range through a 16-byte cell used only past 63 bits. A constructor without fields is one static cell, a string literal is a static cell, `at` and `chr` never allocate. A constructor costs 8 bytes plus its fields (`Cons` went from 56 to 24), a record 8 bytes plus its values with one static shape (3 fields went from 88 to 32). `match` compares one word and field access compares interned keys.
- **Direct code.** The code generator keeps the value in `%rax`, loads literals and locals straight into registers, does tagged arithmetic inline with one overflow test, and turns a comparison inside `if` into a compare-and-jump.
- **The compactor.** `mem_pack`/`mem_unpack` (LZ4 block format, bounds-checked decoder, corrupt input stops) and `arena_freeze`/`arena_thaw`: an arena is compressed page by page, its memory goes back to the OS, pointers stay valid and a frozen page returns on first touch. `LUME_ARENA_COLD=<n>` freezes an arena unused for `n` collections. `.lcaps` and `.lumb` are stored packed when that is smaller, `lume pack` and `lume unpack` work on any file.
- **`@secret fn`** and **`arena_mark_secret`:** a secret never reaches the compactor, because decompression time depends on the bytes (`[C0009]`, secret arenas stop at run time). The compactor also has no place under `@bound` (`[V0002]`).
- `tests/memory/atomic_compactor_ok.src` holds the cell sizes, the zero-allocation paths and the compactor to measured numbers.
- `tests/memory/value_matrix_ok.src` runs every operation over the boundary values of the word and pins one digest per group to the answers of the cell representation. `value_edges_ok.src` holds the cases where an earlier answer was wrong, and `freestanding_values_ok.src` runs `xs[i]`, `s[i]` and `count` on the kernel runtime in QEMU.
- **`[R0201]` covers the prefixes of the runtime** (`__rt_`, `__gc_`, `__lume_`, `__c_`, `__k_`, `__r_`, `__isr_`, `__cpu_`, `__krn_`, `__net_`), and the runtime's internal labels are `.Lrt_*`, which no Lume name can spell. A probe with one function per runtime label found 396 of 450 labels free to be replaced by a user function, silently.
- **`[L0010]`:** `lasm` rejects a symbol defined twice. It used to keep one of them, which is how a stale routine could survive a merge.
- **Native memory reclamation.** The hosted runtime now collects garbage: a non-moving mark-sweep collector with lazy sweeping that returns memory to the OS. `LUME_GC=on|off`, `LUME_GC_STRESS=<n>`, and `gc_collect()`/`gc_count()` in `use arena`. Limits are stated in `docs/38-memory-management.md`.
- **`[O0004]`:** a `resource type` value held by a `let` must be consumed on every path.
- **`[O0013]`:** a move, mutable borrow, or use that conflicts with a borrow used later is rejected. Borrows end at their last use.
- **`lume: stack overflow (recursion too deep)`, exit 12,** instead of a silent SIGSEGV. The stack limit is capped at 4 GiB.
- `tests/harness/ownership_gate.src`, `runtime_sync_gate.src` and `gc_gate.src`, also run in CI. The ownership gate also holds every fail-closed fixture and every `compiler/stage1/*_ok.src` to the same verdict from `lumec` and `lcaas`.
- **`lcaas` runs the real compiler.** It imports `lumec.src` and compiles every request in process, so the oracle can no longer accept what `lumec` rejects. Its own parser only recovers an AST from a broken program. Over the 547 programs in the repository the two now agree on every verdict and every error code; before this change they disagreed on 115.
- **`ctfail` and the runtime's own stops can be caught in process** with `__lume_try_begin()`, `__lume_try_end()` and `__lume_try_msg()`, nested up to 16 deep, which is how a compile error becomes a diagnostic instead of ending the oracle.
- **`compiler/stage1/name_flow.src`:** name resolution shared by `lumec` and `lcaas`. The oracle lists every undefined name at once, and `[R0201]` rejects a function named after a runtime routine.
- **`lume agent` resolves `use`.** A program with imports is compiled as the bundle the build would use, while analyses and spans stay on your file. A module that cannot be found is `[R0300]`, in JSON.
- **Integer overflow stops the program** (`lume: integer overflow`, exit 3) for `+`, `-` and `*`. `+%`, `-%` and `*%` wrap on request. This is what makes contract proofs over the integers hold on real machine integers.
- **`xs[i]` in native code,** on any value on the same line (`f()[0]`, `"s"[1]`, `[1, 2][0]`), for lists and strings. Past the end stops the program.
- **First-class functions:** a named function can be passed, stored and returned as a value, in a list, a record or a constructor, and closures work at any arity. A call result can be called (`mk(1)(2)`), an immediately called lambda works with no arguments, a higher-order function needs no closure elsewhere in the program, a top-level `let` can hold a function, and functions with `own` or `mut` parameters can be used as values. Before, only arities 1 and 2 were dispatched, and any other answered 0.
- **`[R0202]` covers builtins,** so `slice("abc", 1)` is rejected instead of reading a garbage register. **`[R0203]`** rejects a call to an internal routine of the runtime, such as `strlen`. **`[C0002]`** stops the build on a name with no storage, which used to read an arbitrary stack slot.
- **A program that passes `lume check` links.** A call that lowering left unresolved is rejected before code is generated: a routine from a module the program did not import (`[R0200]`, naming the `use` to add), a form of a compiler intrinsic that has no meaning, and `f[i]` on a function (`[R0204]`). These used to stop at link time.
- **`[R0205]`** rejects a call whose name is both a local and a builtin or intrinsic. `fn f(get) = get(1)` used to ignore its parameter and return 1.
- **Comparisons do not chain.** `3 > 2 > 1` compared a boolean with 1 and printed 0. It is now `[P0002]`.
- **`[R0202]` covers `Cons` and `Nil`,** in expressions and in patterns, unless the program declares its own. A `Cons(a)` arm used to match nothing, silently.
- **Comptime arithmetic reports overflow** as `[C1001]`, in `lumec` and in the oracle, including `min / -1`. It used to stop the compiler with no code.
- **`true` and `false` are values.** `print true` used to crash, and `fn f() -> bool = true` printed nothing.
- **`type Name = str`** names a base type. It used to declare an enum with a variant called `str`.
- **`[R0202]`** rejects a call with the wrong number of arguments. It found three such calls in `lcaas`, each of which read garbage from a register.
- **`[D0002]`, `[D0003]` and `[D0004]`** reject a name or a type defined twice in a bundle, which used to let one silently replace the other, and a record field given twice.
- **`[T1002]`** rejects a `match` that names variants of a declared enum, has no catch-all, and leaves one out.
- **Declared types are checked on every branch.** `-> int` is enforced on each `if` and `match` arm, where one fitting branch used to excuse another, and a typed record literal has to give every field.
- **`[L0003]`** rejects an integer literal that does not fit in 64 bits, which used to wrap.
- `tests/memory/`: `values_ok`, `list_index_ok`, `list_index_fail`, `list_index_type_fail`, `int_wrap_ok`, `type_error_fail`, `div_zero_fail`, `dyn_type_fail`, `closures_ok`, `closure_arity_fail`, `fn_values_ok`.

### Fixed
- **`exists_range` and `forall_range` ending at the top of `int`** stepped past it, wrapped, and answered with the wrong value. They now stop at the last integer of the range.
- **Strings with a NUL byte** compared as C strings: `<=` and `>=` could both hold while `==` did not, and a `match` on `"a"` took `"a" + chr(0)`. Equality, order and patterns now compare the whole string, length included.
- **Five generators emitted JSON one closing brace short:** the report of `lume economy`, the registry errors, `model_export_onnx` and the traces of the EGM and NCM engines. Each closed an object opened by an earlier piece of a concatenation with `}}`, and a literal outside an open `{` reads that pair as one brace. They now write `\}\}`.
- **`chr(n)` outside 0..255** kept the low byte. It now stops the program.
- **`bit_and`, `bit_or`, `bit_xor`, `bit_shl`, `bit_shr`, `bit_not`, `os_arg_at`, `fs_read_file`, `fs_read_dir` and `fs_path_exists` read a value of the wrong kind** as if it were the right one and answered anyway. They now stop with a type error. `xs[i]` and `at` check the kind of the value before the position, so a wrong kind reads the same whatever the index.
- **`"abc"[3]` printed nothing and went on.** `xs[i]` on a string now stops past the end, as it does on a list, and `at(s, i)` keeps its `""` for scanners.
- **`toint("-42")` was 0.** `toint` now reads a sign, and reaches the most negative integer.
- **An index or a position that is not an integer** used to read the object as if it were one. `xs[i]`, `at`, `slice`, `slicen` and `chr` now stop with a type error.
- **Value corruption through Perceus reuse:** `let b = a in let c = f(own a) in b` could observe the cell overwritten in place. Reuse now requires every call site to pass a provably unique value, and otherwise allocates.
- **Ownership holes:** moves now reach aliases, containers, parts and closures; moving out of a borrowed value is caught through aliases and match patterns; borrows can no longer escape through records, constructors or match results.
- **Heap corruption with C code:** the runtime no longer uses `brk`, which `malloc` shares. The same fix makes a Lume `.so` safe to load next to another Lume runtime.
- **`cell[T]` aliasing:** cells lived in a 240-entry ring and silently overwrote each other. Each cell is now its own heap slot, and holds any value.
- **String interpolation overflow in the seed:** an interpolated value longer than the literal wrote past its buffer.
- **`fs_read_dir` overflow:** a directory growing between the two passes overran the listing buffer. The listing is now truncated to what was counted.
- **`lcaas` nested patterns:** `Cons(a, Cons(b, t))` produced a corrupted AST and reported success. The oracle now parses nested patterns and shares the ownership analysis with `lumec`.
- **`lume fmt` corrupted source files.** Its own parser knows only part of the language: of 234 valid programs, 96 stopped compiling or changed meaning, and the file was rewritten with exit 0. A statement is now replaced only when the compiler's parser reads the same program from both texts and it holds no comment. Everything else stays as written.
- **`fn f(x: int) -> bool = x > 0` compiled to an error.** A comparison, `and`, `or` and `not` now have type `bool`, which is still accepted where an `int` is expected.
- **`{ r with a: 1 }` on a value of unknown shape lost fields.** The compiler guessed a record with that key, so `{a, b, c}` came back as `{a, b}`, or as `{a}` when it found none. The update now happens at run time and keeps every field.
- **Integer patterns past 32 bits matched the wrong value.** `4294967297 => ...` was truncated, so it matched `1`, and never matched itself.
- **A local now shadows a top-level function when called.** The call used to go to the top-level function, so `fn g(f) = f(1)` ignored its parameter whenever a function `f` existed.
- **`with handler` and `with alloc` bodies skipped lowering.** Constants, `xs[i]`, record updates, generics, closures and function values inside them read garbage or failed at link. They now go through every pass, and type checks reach handler bodies.
- **`slicen` trusted its length argument** and could read past the end of the string. The length now comes from the string.
- **`INT64_MIN / -1` and `% -1`** report `lume: integer overflow`, and division by zero reports `lume: division by zero`. Neither depends on SIGFPE any more, so the oracle survives them.
- **`[T1002]` no longer rejects a `match` whose tags are in two enums** when it covers one of them.
- **Untyped code fails closed.** These used to continue with a made-up value and now stop with a message and exit 3: a `match` with no arm for the value (was 0), a missing record field (was 0), arithmetic or `<` on a non-integer (read the object's length), a condition that is not a boolean, `toint` past 64 bits.
- **Field access on a non-record** read the value's bytes as pointers, so `x.b` on a string dereferenced its text. It now reports a missing field.
- **`print` of a tag-4 list** printed `<opaque>` after the closing bracket and crashed, on the seed path.
- **Records at compile time:** `comptime({a: 1, b: 2} == {b: 2, a: 1})` was false while the same expression is true at run time.
- **`lcaas` `result`:** a `print` the evaluator could not compute was dropped silently, and `str()` of a compound value or a record comparison could give a wrong line. A line it cannot compute now reads `<runtime>`.
- **`str()` of a list, record or constructor** returned a fragment of the value. It now gives the text `print` shows.
- **Top-level `let`** with a side effect ran at every use. It now runs once, in source order. Pure constants stay inlined.
- **String builtins given a non-string** read the wrong object. They now stop with `lume: type error: this operation needs a string`, exit 3.
- **Division by zero** died with a bare SIGFPE. It now reports `lume: division by zero or integer overflow`, exit 3.
- **`print` of a string with a NUL byte** stopped at the NUL.
- **Perceus uniqueness:** exemptions in the use count let a value reach two owners. A use now counts exactly once on each path, with no exemptions.

### Changed
- **Runtime source:** the hosted runtime moved out of two diverging copies into `compiler/stage1/runtime_core.lume`, one instruction per line.
- **Arenas no longer pin the heap.** Each is its own mapping and `arena_destroy` returns it to the OS. The `heap ceiling pinned` error is gone.
- **Perceus reuse narrowed:** the compiler's own AST passes now allocate, because the parser's output is not provably unique.
- **Bootstrap and tool builds pay for the embedded compiler:** every tool that imports `lcaas` also carries `lumec`, so building them takes longer. See `docs/PROJECT_STATE.md` for the measured cost.
- **`lume agent check` on a `.lume` Stage-0 file** used to answer `ok:true` from a garbage parse. It now reports what the self-hosted front end sees, usually `[R0300]` for `use io`. Use `lume check` for Stage-0 files.
- **Seed:** 64-byte values and a collected heap. `SEED_FREEZE.sha256` updated; output on `lumec.src` is byte-identical to the previous seed.
- `lume: out of memory (heap exhausted)` replaces the `brk failed` wording.
- **Stricter `.src` parsing (may reject code that previously compiled):** `let` requires `=`; a `let` body on the same line requires `in` or `;` (a new line still works); duplicate binders are rejected in function and lambda parameters, tuple/record `let` and patterns; `match` arms require a pattern (`=> 1` is `[P0002]`); decimal patterns are `[P0002]` in every arm position and in Stage-0; stray top-level tokens are `[P0002]`.
- **`[L0002]` for unsupported string escapes:** `\q`-style escapes no longer silently drop the backslash. `\0` is rejected natively because native strings are NUL-terminated. `\b` and `\f` now decode to the real control bytes (they previously became the letters `b` and `f`).
- **`not` precedence:** `not` binds looser than comparison and tighter than `and`, so `not 1 == 2` is `1`, in both native and Stage-0.
- **`\$` escape:** `"\${x}"` is a literal `$` in front of a hole. `${x}` itself stays an alias of the hole `{x}`.

### Added
- **List literals in `.src`:** `[]`, `[a]` and `[a, b, c]` lower to `Nil`/`Cons` chains; `count` measures a `Cons` chain.
- **Stage-0 parity:** next-line function and branch bodies parse in `data_parser.lume` (they silently evaluated to `0` before); unknown atoms are errors rather than `0`; `data_asmgen.lume` lowers `forall_range`/`exists_range` and preserves lexical shadowing for `let`, `match` and quantifier binders.
- **Gates:** `semantic_ergonomics_native_ok`, `tests/conformance/stage1/fail_closed/<code>_*.src` (each fixture must be rejected with `<code>`), and `docs/install.sh` in `scripts/check-version-coherence.sh`.

### Fixed
- **String braces:** interpolation now scans the raw token, so `\{` and `\}` can never open or close a hole (`"{\{x}"` is `{{x}`, `"{x\}"` is `{x}`), and `}}` is an escape only outside an open literal `{`, so `"{\"a\":{\"b\":1}}"` keeps both braces. This also repairs JSON constants in the toolchain that were losing a closing brace. The `[P0002]` hole diagnostic prints the `{{`/`}}` escape correctly.
- **Structural equality** (`==` on constructors, records and lists) runs in constant native stack on any shape, in all three runtimes.
- **`./lume` fresh-clone bootstrap** reports compiler errors and stops instead of exiting silently with an empty `lume_driver.s`.
- **Stale binaries after a compiler change:** the `lume build` and `lume test` caches are keyed on the `lumec`, `lasm` and `ltest` binary hashes as well as the source, so an upgraded compiler can no longer return a binary built by the previous one.
- **Protected builds are never served from the binary cache,** so `--profile=release` always emits its `.lsym` sidecar.
- **`.gitattributes`:** restored the Linguist and binary rules alongside the repo-wide LF default. **`docs/install.sh`** defaults to `v1.1.0`.

## [1.1.0] - 2026-11-08

### Added
- **Sovereign Cyber-Physical Unified Field & Subsea Engine (`lume unified-field` / `lume ufe` / `lume subsea` in `compiler/stage1/gfx.src`, `77/77` proofs, `15/15` tests), 2nd-Order Dynamical Transition Engine, Singularity Boundary $\Omega$ & Bayesian SPC / PAVA (`lume singularity` / `lume ote` / `lume transition-engine` in `compiler/stage1/lchameleon.src`, `68/68` proofs, `12/12` tests), and NetSentinel IEC 62443, Conduite HA/GOOSE/Storm & Omega-Mesh P2P (`lume net-sentinel` / `lume iec62443` / `lume conduite` / `lume omega-mesh` in `compiler/stage1/net.src`, `68/68` proofs, `27/27` tests):**
  - **Unified Field & Subsea Engine (`std.gfx`):** 7-DOF singularity-free Damped Least-Squares (`ufe_dls_lambda_sq_milli`, `ufe_dls_safe_denom_milli`), 3D Harmonic Laplace Red-Black SOR solver & maximum principle (`ufe_laplace_sor_step_milli`, `ufe_harmonic_maximum_principle_law`), GNRON swirl attenuation (`ufe_gnron_swirl_scale_milli`), link-capsule self-collision (`ufe_self_collision_capsule_ok`), hardware IEEE-754 finite register guard (`ufe_ieee754_f32_finite_guard`), dual-state actuator EKF with $5\sigma$ Mahalanobis gate + Joseph covariance positivity + valve stiction + RUL (`ufe_ekf_mahalanobis_5sigma_ok`, `ufe_ekf_joseph_cov_pos_milli`, `ufe_actuator_stiction_detect`, `ufe_actuator_rul_hours`), multi-robot swarm separation (`ufe_swarm_separation_ok`), IAPWS-IF97 steam regions & wet-steam guard + Carnot bound (`ufe_if97_region_select`, `ufe_turbine_wet_steam_guard`, `ufe_carnot_efficiency_bound_ok`), deterministic 1 kHz `LatencyMonitor` (`ufe_latency_shedder_step`), Subsea Catenary & API RP 1111 / DNV-OS-F101 stress (`subsea_catenary_top_tension_n`, `subsea_catenary_tdp_bend_ok`, `subsea_combined_longitudinal_stress_ok`), Free-Span VIV & Palmgren-Miner fatigue (`subsea_viv_screening_ok`, `subsea_miner_fatigue_safe_ok`), Offshore Heavy-Lift DAF floor (`marine_dnv_daf_floor_milli`, `marine_heavy_lift_feasible_ok`), Hyperbaric Bühlmann ZH-L16C decompression (`subsea_hyperbaric_decompression_safe_ok`), Wait & Weight Well-Kill (`subsea_well_kill_icp_kpa`, `subsea_well_kill_mud_sg_milli`), and ASME B31G corroded pipeline burst guard (`subsea_b31g_corroded_pipe_safe_ok`).
  - **Singularity Transition Engine & Bayesian SPC / PAVA (`lchameleon.src`):** Underdamped ($0 < \zeta < 1$) and critically/overdamped ($1 \le \zeta \le 100$ via $t_{80}/t_{20}$ ratio) step identification & quantitative $\zeta$ estimator (`ote_select_damping_regime`, `ote_estimate_zeta_milli`), Operational Power Triangle ($S, P, Q, \cos\Phi$) & phase coherence (`ote_power_factor_milli`, `ote_reactive_waste_ratio_milli`, `ote_phase_coherence_ok`), Singularity Boundary $\Omega$ ($\tau_{\max} = T_m/4$, `ote_singularity_tau_max_ms`, `ote_omega_boundary_crossed`, `ote_singularity_margin_zone`), Nyquist guard (`ote_nyquist_status_code`), cascade bandwidth decoupling (`ote_cascade_bandwidth_decoupled_ok`), quantitative gain retuning (`ote_retune_kp_scale_milli`), 9 normative prescriptions ordered by physical leverage (`ote_diagnose_primary_code`), Bayesian Beta-Binomial conjugate SPC (`spc_beta_binomial_posterior_num`), Page's tabular upper CUSUM (`spc_cusum_upper_step_milli`), CPM total float (`ops_cpm_total_float_hours`), and $k$-anonymous monotonic PAVA (`analytics_k_anonymity_release_ok`, `analytics_pava_monotonic_pair_hi`).
  - **NetSentinel IEC 62443, Conduite & Omega-Mesh P2P (`std.net`):** Purdue Model (`L0..L4`) & DMZ (`L3.5`) conduit isolation guard (`iec62443_purdue_conduit_ok`), OT firewall policy audit (`netsentinel_fw_policy_audit_ok`), structural read-only DCS guard (`ot_readonly_dcs_guard`), tri-state quality (`ot_tristate_quality_code`), finite `1e12` sentinel (`ot_finite_sentinel_clamp`), Conduite admin timeout, HA failover parity, severity escalation, IEC 61850 GOOSE state transition, posture traffic confirmation & broadcast storm mitigation (`conduit_admin_timeout_ok`, `conduit_ha_failover_parity_ok`, `conduit_severity_escalate_rank`, `ot_goose_state_transition_code`, `netsentinel_posture_traffic_confirmed`, `netsentinel_broadcast_storm_code`), and Omega-Mesh P2P frame bounds, atomic NAT dual-bucket rate deduction, Kademlia DHT healing rank, Raft quorum & log backtrack, TOFU verification & channel mux quota (`mesh_frame_bounds_ok`, `mesh_atomic_dual_rate_deduct`, `mesh_dht_healing_rank`, `mesh_raft_quorum_ok`, `mesh_raft_backtrack_index`, `mesh_tofu_verify_code`, `mesh_channel_mux_quota_ok`).
- **Universal Chameleon Polyglot Interop Engine, Wave 4 Zero-Limitation Tensor/Quire/Assimilator & Waves 5–10 `LumePuter`/`LumePU` Weight-Compiled RV32IM_Zba/VX NPU, Trap/CSR & In-Weights `lcert` Verifier, Octagon/Farkas/Bit-Shift/Horner-Bernstein/Inductive-Graph/AST-Quadratic Prover, Incremental Cache v2, `#334` FFI Callback Arena Epoch Guard, `#407` Fuzzy Symbol/Arity Repair, Deep SSA/Chaitin RegAlloc/AVX2-VEX & AVX-512-EVEX Hardware SIMD, Automated OS/Socket/CUDA + Real Linux Kernel `io_uring` Syscalls, Industrial C Header Preprocessor/Auto-Parser, Structural Compiler Pass Self-Evolution Engine & Critical Production-Assurance Suite (`compiler/stage1/lchameleon.src`, `200/200` proven obligations, `19/19` unit tests including Singularity $\Omega$, Bayesian SPC/PAVA, Wave 4, Wave 5, Wave 6, Wave 7, Wave 8, Wave 9 & Wave 10 across `17` modules & `112` autonomous domains `#0..#111`, `Lume Verified ✓`):**
  - Native self-hosted polyglot bridge (`lume chameleon [eco]`, `lume camaleao`, `lume polyglot`, `lume ffi-bridge`, `lume adapt <c|c-raw|rust|python|js|go|java|dotnet|sql|openapi> [file]`, `lume adapt c --preprocess <header.h>`, and `lume morph <file>`) across 9 verified ecosystems (`c_abi`, `rust_cdylib`, `python_capi` with DLPack zero-copy tensors, `node_napi_wasm`, `go_cshared`, `java_jni`, `dotnet_pinvoke`, `sql_relational`, and `openapi_rpc`) enforcing Principle P30 and `[I0003]` fail-closed `QF_LIA` boundary contracts (`unverified[T] -> verified[T]` under capability `/ {ffi}`).
  - **Wave 4 Zero-Limitation Tensor/Quire, `QF_FP_Interval` & Autonomous Ecosystem Assimilator (`lchameleon.src` & `lsentience.src`):** Added `fp_bf16_is_finite_ok`, `fp_fp16_is_finite_ok` (`fp_bf16_nan_inf_rejection_law`), `fp_quire_exact_dot_accum` (`fp_quire_associativity_law`), `fp_interval_add_lo`/`fp_interval_add_hi` (`fp_interval_soundness_enclosure_law`), `fp_tensor_core_mma_m16n8k16_waves` & `fp_flash_attention_o1_sram_tiles` (PTX/SPIR-V GPU Tensor Cores), `pkg_assimilate_purity_gate_ok` (`pkg_assimilate_supply_chain_backdoor_rejected_law`), `pkg_omni_stdlib_btree_split_mid`, and `pkg_omni_stdlib_mvcc_visibility_ok` (`pkg_mvcc_uncommitted_invisible_law`).
  - **Wave 5 `LumePuter` & `LumePU` Weight-Compiled `RV32IM_Zba` + Bignum + Vector/Matrix NPU (`VDOT`/`SMAQA`/`VX VMAT`) & Zero-Drift Gated-DeltaNet RAM Engine (`lchameleon.src`, `lsentience.src`, `ltarget.src` `--target lumeputer-rv32im-weights`, and 17 integrated modules):** Added `lumeputer_swiglu_exact_relu_unit`, `lumeputer_ballast_rmsnorm_guard_ok`, `lumeputer_deltanet_ram_step_exact`, `lumeputer_rv32im_pc_step`, `lumeputer_bmac_digit_file_step`, `lumepu_vdot_int8_int4_mac`, `lumepu_vx_vmat_row_mac_exact`, and `lumeputer_compile_rv32_vx_to_weights_layers`, plus 112-domain 24/7 autonomous self-evolution (`#0..#111` in `lume_autonomous_24x7_evolver.src`).
  - **Wave 6 `LumePuter` Recursive Stack `.lweights` Compiler, Relational Octagon/Interval Loop Prover & Incremental Interface Cache v2 (`lchameleon.src` & `lsentience.src`):** Added `lumeputer_stack_push_frame_sp`, `lumeputer_compile_src_bundle_lweights`, `prover_octagon_transitive_upper`, `prover_loop_ranking_steps_remaining`, `incremental_module_iface_digest`, and `incremental_can_reuse_downstream_mod`.
  - **Wave 7 `LumePuter` Trap/CSR (`ecall`/`mret`) & In-Weights `lcert` Proof Certificate Verifier, `G5_PROVER_THEORIES v2` Farkas Lemma Linear Dual Certificate & Exact Bit-Shift (`shl`) Linear Bounds, `#334` Fail-Closed FFI Callback Arena Epoch Guard & `#407` AI-First Fuzzy Symbol/Arity Repair (`Section 1o` in `lchameleon.src`, `ltarget.src`, `lsentience.src`, `lstd.src`, `stdlib/std.lume`):**
    1. **Front 7A — `LumePuter` Trap/CSR (`ecall`/`mret`) & In-Weights `lcert` Proof Certificate Verifier:** `lumeputer_ecall_save_mepc`, `lumeputer_mret_restore_pc`, `lumeputer_ecall_mret_roundtrip_law`, `lumeputer_inweights_lcert_check`, and `lumeputer_inweights_lcert_soundness_law`.
    2. **Front 7B — `G5_PROVER_THEORIES v2` — Farkas Lemma Linear Dual Certificate & Exact Bit-Shift (`shl`) Linear Bounds:** `prover_farkas_dual_rhs_sum`, `prover_farkas_unsat_witness_ok`, `prover_farkas_contradiction_soundness_law`, `prover_bitshift_shl_exact_bound`, and `prover_bitshift_shl_monotonic_law`.
    3. **Front 7C — `#334` Fail-Closed FFI Callback Arena Epoch Guard & `#407` AI-First Fuzzy Symbol/Arity Repair:** `ffi_callback_arena_epoch_safe`, `ffi_callback_stale_epoch_rejected_law`, `diag_fuzzy_repair_distance_score`, `diag_fuzzy_repair_suggest_ok`, and `diag_fuzzy_exact_match_zero_score_law`.
  - **Wave 8 Industrial-Scale SSA/Register/AVX-512 Optimizer, Automated OS/Socket/CUDA `io_uring` FFI Bridge, Non-Linear Horner/Inductive Graph Prover & Structural Compiler Pass Self-Evolution (`lchameleon.src`, `lsentience.src`, `lstd.src`, `stdlib/std.lume`, and 108-Domain Evolver `#0..#107`):**
    1. **Front 8A — Deep SSA, Chaitin Register Allocation, Interprocedural Inlining & AVX-512 Auto-Vectorizer (`#100` `SSA_Chaitin_RegAlloc_Interprocedural_Inline_AVX512`):** `ssa_chaitin_register_spill_cost`, `ssa_zero_spill_when_k_colorable_law`, `ssa_interprocedural_inline_gain`, `ssa_inline_nonnegative_gain_law`, `avx512_autovec_loop_speedup_lanes`, and `avx512_vectorized_strictly_faster_law`.
    2. **Front 8B — Automated Native OS/Socket/CUDA FFI Bindings & Zero-Copy `io_uring` Kernel I/O Bridge (`#101` `Automated_OS_POSIX_CUDA_FFI_ZeroCopy_IoUring_Bridge`):** `ffi_auto_header_abi_layout_ok`, `ffi_auto_abi_size_mismatch_rejected_law`, `io_uring_zero_copy_ring_submit`, and `io_uring_backpressure_no_overflow_law`.
    3. **Front 8C — Non-Linear Polynomial Horner/Bernstein Envelope & Inductive Graph DAG Rank Prover (`#102` `NonLinear_Horner_Bernstein_Inductive_Graph_Prover`):** `prover_nonlinear_horner_lower_bound`, `prover_nonlinear_horner_monotonic_law`, `prover_inductive_graph_dag_rank_ok`, and `prover_inductive_cycle_rejected_law`.
    4. **Front 8D — Structural Compiler Pass & Prover Rule Self-Evolution Gate (`#103` `Structural_Compiler_Pass_EGraph_WCET_Self_Evolver`):** `compiler_pass_evolve_verified_promote` and `compiler_pass_unverified_or_slower_rejected_law`.
  - **Wave 9 Real Hardware VEX/EVEX SIMD Codegen, Linux Kernel `io_uring` Syscalls (`425..427`), Native AST `x * x` Quadratic Horner Square-Completion Prover & Industrial C Header Preprocessor/Auto-Parser (`lasm.src`, `runtime_core.lume`, `06b_phase3.src`, `lcaas.src`, `lchameleon.src`, `lsentience.src`, `lume_driver.src`, and 108-Domain Evolver `#0..#107`):**
    1. **Front 9A — Real x86-64 VEX (`AVX2` `%ymm0..%ymm15`) & EVEX (`AVX-512` `%zmm0..%zmm15`) Machine-Code Encoding (`#104`):** Hardware VEX (`0xC4`/`0xC5`) and EVEX (`0x62`) encoder in `lasm.src` + hardware SIMD intrinsics (`simd_add4_i64`, `simd_sub4_i64`, `simd_xor4_i64`, `vex_simd_hardware_add4_sum`).
    2. **Front 9B — Real Linux Kernel `io_uring` Syscalls (`#105`):** Direct kernel syscall wrappers (`os_io_uring_setup` = 425, `os_io_uring_enter` = 426, `os_io_uring_register` = 427) and `io_uring_kernel_syscall_sqe_batch_safe`.
    3. **Front 9C — Native AST `x * x` Quadratic Horner Square-Completion Prover (`#106`):** AST-level quadratic square-completion in `06b_phase3.src` and `lcaas.src` (`ast_native_horner_quadratic_eval`, `ast_native_quadratic_square_completion_law`).
    4. **Front 9D — Industrial C Header Preprocessor & Auto-Parser (`#107`):** Macro/comment/typedef stripping in `lume adapt c --preprocess <header.h>` and `lume adapt c-raw <header.h>` (`c_header_preprocessor_macro_strip_ok`).
  - **Wave 10 Critical Production-Assurance & Independent Verification Suite (`lasm_gate.src`, `claude_audit_gate.src`, `lasm.src`, `lchameleon.src`, `lstd.src`, `stdlib/std.lume`, `lsentience.src`, and 112-Domain Evolver `#0..#111`):**
    1. **Front 10A — Byte-for-Byte Differential Assembler Oracle vs GNU `/usr/bin/as` (`#108` `LASM_Differential_Assembler_Oracle`):** Differential verification of `lasm` scalar x86-64, AVX2 VEX (`0xC5`/`0xC4`), and AVX-512 EVEX (`0x62` compressed `disp8*N` & `disp32`) machine-code bytes against GNU `/usr/bin/as` + `objcopy -O binary` (`lasm_vs_gnu_as_differential_byte_eq`, `lasm_differential_Mismatch_rejected_law`).
    2. **Front 10B — Adversarial False-Theorem Prover Soundness Fuzzer (`#109` `Adversarial_Prover_False_Theorem_Fuzzer`):** Deterministic PRNG & 25+ adversarial false-theorem families across `QF_LIA`, negative modulo, bit-shifts, wrapping `+%`/`-%`/`*%`, non-linear `x*x`, and shadowed quantifiers under `let`, proving 0 false positives accepted across `lumec` and `lcaas` (`prover_adversarial_false_theorem_rejected`, `prover_unsound_acceptance_rejected_law`).
    3. **Front 10C — Active Semantic Gate Mutation-Kill Verifier (`#110` `Gate_Mutation_Testing_Kill_Verifier`):** Active mutation-testing harness injecting contract, ownership, `@secret`, `/ pure`, SIMD register, C header `void*`, and ISO boot-sector mutants and verifying a 100% mutation kill ratio (`mutation_testing_kill_ratio_verified`, `mutation_surviving_mutant_rejected_law`).
    4. **Front 10D — David A. Wheeler Diverse Double-Compilation (`#111` `Wheeler_Diverse_Double_Compilation_DDC`):** Verifies that the independent C11 `lume0` bootstrap chain (`GCC -> lume0 -> stage1 -> stage2`) produces a bit-for-bit identical compiler binary to the self-hosted `lumec -> stage3` chain (`ddc_diverse_double_compilation_bit_identical`, `ddc_bootstrap_divergence_rejected_law`).
- **Clean Generic Win64 Native GUI Backend & Declarative `@ui-layout` Lowering (`--target x86_64-windows-gui` in `compiler/stage1/ltarget.src` & `compiler/stage1/gui.src`):**
  - Emits 33,792-byte native PE32+ GUI (`Subsystem 2`) with zero hardcoded Notepad++ strings, `hMenu=0` (`wgui_rsp_imm(72, 0)`), `Segoe UI -12` font (`4220992`), `1400x780` window (`1366px` full-width bottom console & status bar), wide buttons (`116px-142px`), and 4 resizable/scrollable `WS_CLIPSIBLINGS | WS_THICKFRAME | WS_HSCROLL | WS_VSCROLL` panes (`1412694337` / `0x54340141` with `LBS_NOTIFY | LBS_HASSTRINGS` mouse selection and `1412698308` / `0x543410C4` multiline Edit panes) with `LB_SETHORIZONTALEXTENT = 680`, 14-line scrollable telemetry log, and declarative `lume ui-layout` / `@ui-layout` split-pane geometry conservation (`ui_split_conservation_law`).
- **Formally Verified Generic Collection Invariants & Wave 10 Self-Evolution Commands (`vec.src`, `decimal.src`, `stdlib/std.lume`, `lsentience.src`):**
  - Added machine-checked `QF_LIA` collection and numeric helpers (`vec_clamp_index`, `vec_checked_slice_len`, `map_checked_slot`, and `decimal_clamp`) alongside Wave 10 self-evolution commands (`lume daemon-triad`, `lume hot-evolve`, and `lume live-cockpit`).
- **Hardened String Interpolation & $O(1)$ Plain-Chunk Scanner (`02_parser.src`, `lcaas.src`, `lfmt.src`, `compiler/stage1/win64_gui_and_interp_regression_ok.src`, `8/8` tests):**
  - Rejects `;`, `'`, `#`, `$`, `@`, and `` ` `` in `isbadholech`, rejects JS blocks (`return `, `var `, `const `, `function`, `if(`, `for(`, `while(`) in `isjsblock`, treats `/ {ffi}` effect annotations inside strings as literal `{`, supports format specifiers (`{x:04x}`), and scans plain string chunks via `strplainchunk`/`cs_strplainchunk` in $O(1)$ without per-character `Cons` heap pressure.
- **Expanded `lume self-prove` & Red Team Round 3 (`compiler/stage1/lume_driver.src`, `tests/harness/claude_audit_gate.src`):**
  - `LumeCompiler-Embedded-OmniProof-v3` expanded to `15` Sovereign Proof Batteries (`700` formal obligations, `+287` across Waves 1–10, `162` unit tests, `99` verified manifest files, `112` autonomous evolution domains `#0..#111`, `17` `LumePuter`/`LumePU` integrated modules) and Round 3 + Waves 4–10 verification (`win64_gui_and_interp_regression_ok.src` + `lchameleon.src`) in `tests/harness/claude_audit_gate.src`.
- **Sovereign Local LLM Hybrid Router & Liquid Audio Voice Engine (`compiler/stage1/lume_llm_core.src`, `7/7` tests, `QF_LIA` proven):**
  - Native 1.58-bit Ternary (`{-1, 0, +1}`) matrix-vector inference (`llm_ternary_matvec_dot`, `llm_bonsai_1bit_profile`), zero-copy MoE SSD page-cache expert streaming (`llm_moe_ssd_bandwidth_audit`, flagging `12.6 GB/tok` bandwidth traps on 8 GB edge nodes), deterministic `QF_LIA` Financial Scraping Guard (`llm_verify_scraped_offer`, rejecting `Q3` comma-shift price corruption and unavailable items), and Liquid AI `LFM3-Audio-2B` (`LiquidCodec` 12 tokens/80 ms @ 24 kHz, 50 ms TTFT, `pt-BR` ASR/TTS prompt locking, `<|mixed_start|>` spoken `<tool_call>` dispatch).
- **COSMIC 1.11 Wayland Compositor & Reactive Desktop (`compiler/stage1/gui.src`, `compiler/stage1/los.src`, `9/9` + `11/11` tests):**
  - Native Wayland binary wire protocol (`wl_display`, `wl_registry`, `xdg_wm_base`, `xdg_surface`, `xdg_toplevel`), `COSMIC 1.11` Iced-inspired Elm `Model -> Message -> update -> view` reactive compositor (`cosmic_desktop_session_loopback`), multi-monitor auto-tiling layout solver (`cosmic_tile_windows`), and `lume-os` desktop session orchestration.
- **Sovereign Forensics, OmniRoute & OpenIDEA Engines (`compiler/stage1/lume_forensics_engine.src`, `compiler/stage1/lume_omniroute_engine.src`, `compiler/stage1/lume_openidea_engine.src`):**
  - Zero-Breach spyware forensics (`Pegasus`/`Predator`/`Candiru` iOS Shutdown.log, DataUsage.sqlite, and Android APK package/certificate hunting with `QF_LIA` risk proofs), resilience-scored LLM API gateway routing (`OmniRoute` circuit-breaker + token-bucket + fallback routing), and multi-agent literature-grounded scientific hypothesis synthesis (`OpenIDEA`).
- **Official GitHub Packages OCI Container Distribution (`ghcr.io/omegasoftdll/lume`) & Cross-Platform Installers (`install.sh`, `install.ps1`):**
  - Published verified OCI packages (`ghcr.io/omegasoftdll/lume:1.1.0`, `ghcr.io/omegasoftdll/lume:1.0.0`, `ghcr.io/omegasoftdll/lume:latest`) linked to `OmegaSoftDLL/lume` alongside all 6 platform `.tar.gz` archives (`linux-x86_64`, `linux-aarch64`, `linux-riscv64`, `macos-aarch64`, `macos-x86_64`, `windows-x86_64`), raw bootstrap binaries (`lumec-linux-x86_64`, `lasm-linux-x86_64`, `lume0-linux-x86_64`, `lume0-windows-x86_64.exe`), `install.sh`, `install.ps1`, and `SHA256SUMS`.

### Fixed
- **4-Axis Claude Opus 5.5 (`claude-fable-5-1`) Bit-by-Bit Security, Soundness & Verification Audit (`docs/CLAUDE_OPUS_AUDIT.md`, `9a846d3`..`abcc4fe`):**
  - **Axis 1 (Stage-0 C11 Seed `bootstrap/lume0/`):** Replaced dynamic `alloca()` stack allocations with checked heap allocations in `main.c`, added bounds checks to `asmgen.c`, `elf.c`, `interp.c`, `lexer.c`, `parser.c`, and `resolve.c`, and hardened `lbe.c` cryptographic helpers.
  - **Axis 2 (Stage-1 Self-Hosted Compiler `compiler/stage1/lume/01..07` & `lasm.src`):** Enforced `mmap` return check (`jb alloc_oom` -> `exit(137)`) in `05_codegen.src` and `data_asmgen.lume`, eliminated command injection in `07_driver.src` (`lumec_quote_sh`), bounded lexer/parser recursion depth (`[P0099]`), enforced strict `QF_LIA` division-by-constant semantics in `06b_phase3.src`, and hardened `lasm.src` against negative alignment arguments.
  - **Axis 3 (Proof Kernel `lcert.src`, `lcaas.src`, `levolve.src`, `lprotect.src`, `formal/lean/LumeCore.lean`):** Eliminated vacuous certificate acceptance (`cert_has_obligations`, `ev_proofs_ok` requiring `"obligations_total":0` only when no obligations exist), enforced mandatory Ed25519 signature checks (`lc_ed25519_verify`), replaced constant seeds in `lprotect.src` with entropy-mixed `lp_prng_seed`, and proved `eval_binop_add_comm`, `progress_pure_expr`, and `preservation_val` in `formal/lean/LumeCore.lean` with zero `sorry`/`admit`.
  - **Axis 4 (Standard Library & Domain Engines):** Hardened path traversal checks in `fs.src` (`fs_is_safe_relpath`), `EAGAIN`/`EINTR` socket loops and TLS 1.3 constant-time tag comparison (`tls13_ct_eq`) in `net.src`, overflow-checked tensor element counts (`tensor_safe_numel`) in `tensor.src` and `nn.src`, SQL identifier sanitization in `db.src`, and 128-bit intermediate multiplication (`dec_CheckedMul`) in `decimal.src`.

## [1.0.0] - 2026-11-05

### Added
- **Official `v1.0.0` Production Release (`Edition 2026 — 10/10`):**
  - 6-platform official release tarballs (`linux-x86_64`, `linux-aarch64`, `linux-riscv64`, `macos-aarch64`, `macos-x86_64`, `windows-x86_64`) with native Apple Silicon Mach-O 64 (`aarch64-macos-macho`) and Intel macOS Mach-O 64 (`x86_64-macos-macho`) `lume-target-check` / `lume-target-trap` binaries.
  - **27Universal Compilation Targets (`compiler/stage1/ltarget.src`, `16/16` tests):** Added `qasm3-quantum`, `qir-llvm`, `quil-rigetti`, `iqm-json`, `stim-qec`, and `dna-quaternary`, plus native `lume quantum-nexus` (`compiler/stage1/lume_quantum_nexus_engine.src`, `15/15` tests, `13/13` `QF_LIA` proofs) with stabilizer QEC, QAOA/VQE, Clifford+T ZX-calculus synthesis, and neutral-atom FPQA AOD routing.
  - **Scalar Replacement of Aggregates (`SRA`) & Zero-Allocation Fast Paths (`compiler/stage1/lume/05_codegen.src`):** Stack-slot field promotion for non-escaping records (`mk_pair`), inlined 16-byte string equality (`s_eq`), `[-4096..4096]` static small-int table, and $O(1)$ dynamic string builder (`compiler/stage1/bytes.src`).
  - **waves 1–10 Line-by-Line Engineering Audits, Fixes & Upgrades (`docs/WAVE_01_AUDIT.md` .. `docs/WAVE_10_AUDIT.md`):**
  - **Wave 1 (`docs/WAVE_01_AUDIT.md`, `543dac7`):** Full line-by-line audit and live execution proof across all 7 Wave 1 subsystems plus full non-mock implementation of `compiler/stage1/lume_crypto_blockchain_engine.src` (`9/9` tests passing, `8/8` `QF_LIA` obligations proven by `lcert`).
  - **Wave 2 (`docs/WAVE_02_AUDIT.md`, `8ae6618`):** Full line-by-line audit and live execution proof across `capsule.src` (`2/2`), `capsule_ok.src` (`5/5`), `arena_ok.src` (`8/8`), `lume build/run --memory`, `small_ints` cache, self-tail-call lowering (`100,000` depth in $O(1)$ stack), and `[E0200]` rejection of `__lume_arena_new` in `/ pure`.
  - **Wave 3 (`docs/WAVE_03_AUDIT.md`, `af4a532`):** Full line-by-line audit and fix in `compiler/stage1/lprotect.src` (`lp_scan_lsym` and `lp_collect_ufns` stopping at `alloc:` and `_start:` so runtime labels like `alloc_done:` are not obfuscated during `lume build --protect standard --lsym`), verified end-to-end with `lume symbolize` and `scripts/llm_gen_eval.src` (`124/250` tokens, `100%` proof coverage).
  - **Wave 4 (`docs/WAVE_04_AUDIT.md`, `8835f9c`):** Full line-by-line audit across `scripts/amalgamate.src` (`1/1`), `scripts/zero_c.src` (`15/15`), `comptime embed("path")` (`[E0200]`/`[C0271]`), `comptime table_schema(RecordType)` (`[D0273]`), `compiler/stage1/p35_ok.src` (`6/6`), and `compiler/stage1/lprotect.src` (`[W0002]` `2/2`), plus upgrade of `wasm_sandbox_verify` in `compiler/stage1/ltarget.src` (`11/11`) to decode binary WebAssembly Section 2 (Import Section) and Section 5 (Memory Section `1..16` pages) via ULEB128 (`[I0275]`).
  - **Wave 5 (`docs/WAVE_05_AUDIT.md`, `2f4737d`):** Full line-by-line audit across `async_rt.src` (`6/6`), `db.src` (`8/8`), `nn.src` (`11/11`), `net.src` (`7/7`), `gui.src` (`6/6`), `media.src` (`5/5`), `levidence.src` (`7/7`), `scripts/install.src` (`5/5`), `acceptance/matrix_assertions.src` (`14/14`), `scripts/docs_ci.src` (`17/17`), and `track_l_domains_ok.src` (`0 diff`), plus fixes in `scripts/docs_ci.src` (`fs_mkdir("build")` before writing `"build/docs-ci-empty-required"`) and `compiler/stage1/ltest.src` (single-evaluation test harness accumulating pass counts in `hw_scratch_addr() + 4096` instead of evaluating each `test_*()` function 3 times).
  - **Wave 6 (`docs/WAVE_06_AUDIT.md`, `e055fab`):** Full line-by-line audit and upgrades across `compiler/stage1/net.src` (`7/7`, binary RFC 8446 `ClientHello`/`ServerHello` + client-side AEAD socket verification), `compiler/stage1/gui.src` (`6/6`, binary X11 Core Wire Protocol `ConnectionSetup`/`CreateWindow`/`MapWindow`/`Expose`/`ButtonPress` + WASM DOM reconciler), `compiler/stage1/interop.src` (`6/6`), `compiler/stage1/db.src` (`8/8`, FIPS 180-4 SHA-256 `SNAP_SHA256` snapshot header + tamper rejection), `compiler/stage1/los.src` (`7/7`), `acceptance/matrix_assertions.src` (`14/14`), short-circuit `and`/`or`, and `compiler/stage1/lcaas.src` (`lume agent skeleton` `param_count` + `body_sha256` and `lume agent cegis` candidate search + counterexample pruning).
  - **Wave 7 (`docs/WAVE_07_AUDIT.md`, `c1de3cf`):** Full line-by-line audit and upgrades across `compiler/stage1/map.src` (`3/3`), `compiler/stage1/capsule.src` (`2/2`) & `capsule_ok.src` (`5/5`), `compiler/stage1/lprotect.src` (`2/2` + `lume build --protect max`), `compiler/stage1/ltarget.src` (`11/11`, `mir_compile_or_lower`, `mir_build_ssa_text`, and full PKZIP Local/Central-Directory/EOCD `pkg_zip_wrap`), `>6` parameter stack spilling + inline braced `match x { ... }`, and `compiler/stage1/lcaas.src` (`cs_skip_indented_lines` for multi-line `lume patch-fn`, `lume trace`, and `lume diff-semver`).
  - **Wave 8 (`docs/WAVE_08_AUDIT.md`, `68cc450`):** Full line-by-line audit and upgrades across `compiler/stage1/lgenesis.src` (`4/4`, domain-parameterized SQL/GUI + E-Capsule V2 sealing), `compiler/stage1/lcaas.src` (generalized constant/symbolic bound extraction `cs_extract_ens_bound` + column-0 `= <rhs>` flattening for `lume heal`, multi-parameter symbolic binding `cs_equiv_bind_ps` + superoptimization telemetry for `lume equiv`, and input-driven SQL/Python/C identifier extraction `cs_morph_ident_after` for `lume morph`), and `compiler/stage1/ltarget.src` (`11/11`, dynamic user kernel compilation + 3-way GPU/FPGA output parsing for `lume neural-kernel`).
  - **Wave 9 (`docs/WAVE_09_AUDIT.md`, `e5685a4`):** Full line-by-line audit, bug fix, and upgrades across `compiler/stage1/lsentience.src` (`21/21` tests: fixed missing `dl_dw` field in `deq_infinite_forward_and_grad`, added 2-qubit gate matrix simulator `qsim_h_q0`/`qsim_cx_01`/`qsim_cz_01`/`qsim_grover_diffuse`, added large-input prefix rewriting in `morph_egraph_saturate`, and wired `hdc_bundle3` + input-parameterized `cosmic-tmr`/`chronos`) and `compiler/stage1/ltarget.src` (`11/11` tests: real `lumb`-bytecode-to-DNA codon encoder `tg_dna_encode_bytes` for `--target dna-quaternary`).
  - **Wave 10 (`docs/WAVE_10_AUDIT.md`, `40a9716`):** Full line-by-line audit, fixes, and upgrades across all 14 Wave 10 capabilities (`compiler/stage1/lsentience.src` `31/31` tests) and all 5 synthesized Lume modules (`lume_crypto_blockchain_engine.src` `9/9`, `lume_sensory_cortex.src` `4/4`, `lume_universal_file_indexer.src` `4/4`, `lume_interface_portal.src` `2/2`, `staged_self_build.src` `4/4`, all 5 proven via `lume prove`): binary 44-byte RIFF/WAVE 16-bit 22050 Hz PCM audio synthesis (`mm_synthesize_lume_wav`), sanctuary full-source preservation (`sanctuary_resolve_full_src`), ELF64/PE64 header parsing + 2048-byte `.text` opcode disassembly (`rev_parse_headers`, `rev_scan_opcodes`), PCM `RMS`/`ZCR` & formant distance in `lume sensory-cortex`, and live directory enumeration + 16-format magic-byte classification + 128-bit HDC recall in `lume file-indexer`.
  - **Built-In Human & AI Programmer's Manual (`compiler/stage1/lmanual.src`, `docs/LUME_MANUAL_PT_BR.md`, `docs/LUME_MANUAL_EN.md`):** Added 10-chapter bilingual (**Portuguese `pt-BR`** and **English `en`**) internal programmer's manual and interactive help (`lume manual [--pt|--json|--export <file.md>] [chapter]`, `lume help [chapter]`, `3/3` unit tests passing in `compiler/stage1/lmanual.src`).
- **Waves 2–6 native consolidation (`v0.3.0-alpha.2` through `v0.3.0-alpha.6`, #433):**
  - **Wave 2 (Memory, Arenas, E-Capsules & Runtime Telemetry — #404, #432, #436, #450–#456):** Added `compiler/stage1/capsule.src` (`use std.capsule`, tamper-evident e-capsules with `capsule_seal`/`capsule_verify`/`capsule_open`) and `compiler/stage1/arena.src` (`use std.arena`, scoped bump arenas `arena_new`/`arena_enter`/`arena_leave`/`arena_reset`/`arena_destroy`, `__lume_heap_stats`, `LUME_HEAP_CAP` fail-closed diagnostics), rejected `__lume_arena_new`/`__lume_arena_alloc` inside `/ pure` functions with `[E0200]`, added `lume build --memory` and `lume run --memory` (`os_self_maxrss_kb`, `os_last_child_maxrss_kb`), pre-allocated small integer cache `[-1024..1024]`, and lowered self-tail-recursive functions to constant-stack `jmp`.
  - **Wave 3 (Compiler-as-Oracle, `lume symbolize`, Native `llm_gen_eval` & Hardware Oracle Equivalence):** Added `lume symbolize <file.lsym> <addr>` (`lsym_symbolize` in `lprotect.src`) resolving crash instruction pointers and `E#N` trap codes against `.lsym` sidecars, wired `scripts/llm_gen_eval.src` and `lume symbolize` into `nt_wave3_gates` (`bootstrap/lume0/tests/run_native.src`), and verified bit-for-bit equivalence across `lume0` (C11 seed), `lumec` (self-hosted native compiler), and `gcc -O2`.
  - **Wave 4 (P35 Hardware/Freestanding Verification, Software Protection, Zero-C Gate, `comptime embed`/`table_schema` & Full Manifest — #188, #205):** Added `comptime embed("path")` (requiring `@capability fs` or `{fs}` effect row, rejecting missing capability with `[E0200]` and missing files with `[C0010]`) and `comptime table_schema(RecordType)` (emitting `"TypeName(f1:t1,...)"` and rejecting undeclared record types with `[D0273]`) across `03_comptime.src`, `06_typecheck.src`, and `06b_phase3.src`, wired `p35_ok.src`, `lprotect.src`, `scripts/zero_c.src`, and comptime reflection into `nt_wave4_gates`, and expanded `scripts/install.src` (`MANIFEST.sha256`) to cryptographically track all 54 core compiler, driver, and standard library `.src` modules plus `levidence`.
  - **Wave 5 (Track L Domain Completeness & Acceptance Matrix — #257, #336):** Added concurrent multi-worker OS process execution with work-stealing over kernel pipes (`async_run_workers_os` in `compiler/stage1/async_rt.src`), arbitrary-height recursive multi-way B+Tree internal-node splitting (`BMLeaf`/`BMInner` in `compiler/stage1/db.src` reaching height 4 with verified leaf-depth balance) and file-backed `fsync` ACID WAL crash recovery across child process termination (`db_wal_recover_file`, `db_crash_recovery_probe`), binary `.safetensors` and binary Protobuf `.onnx` wire-format writers and independent byte-level parsers (`safetensors_write_bin`, `safetensors_parse_bin_file`, `onnx_write_bin`, `onnx_parse_bin_file` in `compiler/stage1/nn.src`), and full RFC 793 / RFC 1071 16-bit one's-complement TCP checksum generation and verification over the 12-byte IPv4 pseudo-header, 20-byte TCP header, odd-byte zero-padded payload, and multi-carry folding (`tcp_rfc793_build`, `tcp_rfc793_verify` in `compiler/stage1/net.src`). Promoted the 6 corresponding Track L claims in `acceptance/matrix.json` and `docs/acceptance-matrix.md` to `PASS` and wired all suites into `nt_wave5_gates`.
  - **Wave 6 (24/24 Acceptance Matrix `PASS`, Product Maturity Increments & AI-First Superpowers — #241, #332, #333, #334, #336):** Added RFC 8446 TLS 1.3 binary record framing (`tls13_wire_encode_aead`, `tls13_wire_decode_aead`) and Linux TCP loopback handshake + encrypted application-data exchange (`tls13_loopback_handshake_exchange` in `compiler/stage1/net.src`, promoting `L.NET.TLS13_INTEROP` to `PASS`), native X11 Core Wire Protocol loopback window session (`x11_window_session_loopback`) and WASM DOM virtual-tree diffing & reactive patch bridge (`wasm_dom_vnode`, `wasm_dom_diff_nodes`, `wasm_dom_encode_patches` in `compiler/stage1/gui.src`, promoting `L.GUI.NATIVE_WINDOWING` to `PASS` so `acceptance/matrix.json` reaches **24/24 `PASS`, `0 UNKNOWN`, `0 FAIL`**), mutable C buffer/callback/OpenAPI adapters (`adapt_c_mutable_buffer`, `adapt_c_callback_stub`, `adapt_http_openapi_endpoint` in `compiler/stage1/interop.src`), SaaS schema migration, snapshot backup/restore, and Prometheus metrics (`db_migrate_schema_v2`, `db_backup_snapshot_file`, `db_restore_snapshot_file`, `db_metrics_prometheus` in `compiler/stage1/db.src`), `lume-os` VFS disk image persistence and multi-command script runner (`los_persist_image`, `los_restore_image`, `los_exec_script` in `compiler/stage1/los.src`), short-circuit `and`/`or` evaluation across `03_comptime.src`, `05_codegen.src`, and `data_asmgen.lume`, and AI-first `lume agent skeleton` (`caas_module_skeleton`) and `lume agent cegis` (`caas_cegis_synthesize`) in `compiler/stage1/lcaas.src` and `compiler/stage1/lume_driver.src`.

### Fixed
- **Toolchain soundness: fail closed instead of silent wrong-code (#428).** Three classes of
  "garbage in, crash later" now produce named compile-time errors: (1) `lasm --strict` (invoked by
  the native driver and the bootstrap shims; default mode keeps byte-compatible address-0
  resolution) fails the build with `[L0001]` naming the first unresolved jump/call/`%rip` symbol —
  no more call-to-address-0 segfaults from a typo'd callee (#417, #420); (2) the `lumec` gradual
  checker performs real name resolution for the first time (`orscheck` in `06b_phase3.src`):
  an undefined variable — including a string-interpolation hole naming an unbound name (#423) — is
  `[R0200]`, and a call with no visible definition in the bundle (user function, declared
  signature, effect operation, trait operation, impl method, runtime builtin, or lowering
  intrinsic) is `[R0200]`, both before any code is emitted; (3) the parser rejects duplicated or
  misplaced branch keywords — `else else`, `else elif`, `else then`, `then then` — with `[P0002]`
  instead of silently parsing the second keyword as a variable (the #417-merge `lume_driver`
  port bug). The driver also stops killing slow compiles with an empty stderr: the hardcoded 120 s
  build timeout defaults to 10 min for known-large inputs and is configurable with
  `lume build --build-timeout-ms <n>`, and a timed-out child reports
  "killed by timeout after Ns" naming the tool. Regression negatives live in
  `bootstrap/lume0/tests/run_native.src` (`nt_negative_soundness`, `nt_lasm_strict`),
  `tests/harness/lasm_gate.src` (`la_strict_undefined`), and a CI step in
  `.github/workflows/ci.yml`; `stage2 == stage3` stays byte-identical.

### Added
- **Incremental module compile cache (#310, wave 1):** Opt-in `lume build --incremental` compiles
  self-contained bundle modules separately (new `lumec --ast-hash` / `--module` / `--link` modes),
  caches content-addressed module fragments under `build/cache/` keyed by parsed-AST SHA-256 +
  module name + lumec binary hash, and reuses unchanged modules on rebuild (formatting-only edits
  hit; a semantic change recompiles exactly the changed module). Not self-contained bundles fall
  back to the whole-bundle build; fragments are SHA-256 integrity-checked at link with one
  self-healing recompile; byte-identical output within the mode; `tests/cli/incremental_gate.src`.
  See `docs/38-incremental-compilation.md`.

### Changed
- Replaced the self-hosted assembler's linear symbol scan with 256 hash buckets while preserving
  byte-identical ELF output, colliding-label behavior, native execution, and the assembler fixpoint.

### Added
- **Safe stdlib byte buffers `std.bytes` (#406 / #407-adjacent):** Added `compiler/stage1/bytes.src` (`use std.bytes`) — a NUL-safe byte-buffer record `{data, len, cap}` holding bytes as lowercase hex (the runtime str is strlen-sized, so raw bytes with embedded NUL cannot live in it), with `bnew`/`bpush`/`bextend`/`bget`/`blen`/`bslice`/`bto_str` returning structured `{ok, ..., err}` records (`bad_byte`/`out_of_bounds`/`not_ascii`/`not_found`/`write_failed`, never silent), deterministic doubling growth with observable `cap` (amortized O(1) appends, no unbounded copy chains), exact `bget`/`blen` for every byte value including 0 and 255, ASCII-only `bslice`/`bto_str` decode that fails closed on byte 0 or >= 128 (utf8_chr cannot carry them faithfully), and NUL-safe binary persistence `bload_file`/`bwrite_file` composing `fs_read_byte`/`fs_write_hex_file`. No new runtime builtins — the `stage2 == stage3` fixpoint is untouched. Ships inline `fn test_*()` tests plus native conformance `bytes_ok.src` diffed against `tests/conformance/stage1/bytes_ok_asm.expected` in `bootstrap/lume0/tests/run.sh`, and dogfoods as the driver gate's artifact string scan (`tests/cli/driver_gate.src` `dg_binary_contains`), replacing per-byte `fs_read_byte` syscall chains with one buffer load plus in-memory scans.
- **Safe stdlib I/O modules `std.fs` / `std.process` (#406):** Added `compiler/stage1/fs.src` (`use std.fs`) — structured file errors (`sfile_read`/`sfile_write`/`sfile_append`/`sfile_size` fail closed with `not_found`/`write_failed`/… instead of a silent `""`), and `sfile_with(path, mode, body)` guaranteeing the close transition on success and error values (the explicit `defer` lowering, closed handle returned for audit) with use-after-close rejected; and `compiler/stage1/process.src` (`use std.process`) — `sprc_run_collect` / `sprc_run_input` composing `os_run_capture` / `os_run_input_capture_timeout` into `{status, stdout, stderr, timed_out, err}` records, fail-closed on missing binaries (`not_found`, never spawned) with `sprc_exit_code` wait-status decoding. Both ship inline `fn test_*()` tests plus native conformance `fs_ok.src` / `process_ok.src` (with the `process_probe` child fixture) diffed against `tests/conformance/stage1/fs_ok_asm.expected` / `process_ok_asm.expected` in `bootstrap/lume0/tests/run.sh`. Documented limits: text-oriented (`fs_write_sync` sizes by `strlen`; NUL-safe bytes stay with `fs_write_hex_file`/`fs_read_byte`), no `fs_remove` builtin yet (cleanup is deterministic scratch reuse), and close-on-panic is not claimed until a native `panic` statement exists.
- **Verified component registry (#337):** Added local `lume registry publish|resolve|discover` with CIDs bound to real adapter/source/proof/test artifacts, independent `lcert` verification, native test re-execution, AST-derived capability/contract discovery, and fail-closed stale, tamper, malicious-recompute, and target/toolchain checks on `x86_64-linux-elf`.
- **Stage 5 (Phase 5 — `docs/25-phase5-plan.md`, `docs/20-interop.md`, `docs/22-adoption.md`, `docs/23-horizon.md`): Systems, Interop, Realtime, Proof Certificates & `lume-os` Microkernel:**
  - **Verifiable C adapters (#334):** Added `lume adapt c` with strict fail-closed prototype parsing, source/ownership/capability/provenance metadata, and real read-only `const char *name, int64_t name_len` buffer adapters whose lengths are derived with `count(name)`. Added adversarial CLI tests and real shared-library execution; mutable buffers, general pointers, callbacks, HTTP/OpenAPI, and adaptive MMIO remain open.
  - **Track M5 / Interop (`04_parser_decls.src`, `06b_phase3.src`, `lcaas.src`, `interop.src`):** Added `@repr(c)`, `@packed`, `@bits`, `@mmio`, `@export("C")`, `extern "c" fn` (requiring `"ffi"` effect `[E0200]` and enforcing foreign provenance taint `[A0003]` until verified via `verify(...)` or `ensures`), `pub extern "c" fn` reverse C-ABI & WAT export (`ffi_export_c_header`, `wasm_export_wat`), `lume agent bind <header.h>` AI C-header binding generator, and `std.wasm` reference sandbox model (`wasm_module_new`, `wasm_grant_cap`, `wasm_call_add`, `wasm_store32`, `wasm_load32`, `wasm_call_host_fs` requiring both `"wasm"` and `"fs"` capabilities `[E0200]`).
  - **Track K5 — Realtime, Interrupts, Structural Cycle-Budget Checker (`@bound`) & Linear Hardware Capabilities (`06b_phase3.src`, `lcaas.src`, `interop.src`, `phase5_sys_ok.src`):** Added `@interrupt(irq: N)` (`[E0200]` rejecting heap allocation or blocking I/O inside ISRs), `@bound(cycles: N)` static structural cycle-budget analyzer (`WcetSig`, emitting `"kind":"wcet"` obligations with `"status":"budget_checked"` in `lume prove` and failing with `[V0002]` when `est_cycles > bound`), and linear hardware capabilities `cap[Page]`, `cap[Port]`, `cap[Irq]` (`[O0001]` on double consumption of `cap_page_map`).
  - **Track G1/G3/H3 — Standalone Independent Proof Certificate Kernel & MCP (`lcert.src`, `./lume`, `#183`):** Added `lume certify`, `lume verify-cert` (standalone zero-dependency proof-certificate verifier in `lcert.src` with cryptographic FIPS 180-4 SHA-256 tamper verification, its own S-expression parser + Fourier–Motzkin `QF_LIA` solver over $\mathbb{Z}$ independently re-deriving every obligation's formula, and `wcet` budget verification issuing `"badge":"Lume Verified ✓"`), and `lume mcp <file.src>` Model Context Protocol server.
  - **P33 Software Protection & Anti-Reverse-Engineering (`docs/06-software-protection.md`, `#188` — Bricks W1–W5):** Added `compiler/stage1/protect.src` (`use protect`), `compiler/stage1/lprotect.src`, `.byte` directive in `lasm.src`/`elf.c`, `@protect` attribute, `[W0001]` secret-hygiene diagnostic in `06b_phase3.src` and `lcaas.src`, `protect = "none" | "standard" | "hardened" | "max"` in `lume.toml` (`lmod.src`), and `lume build --protect <standard|hardened|max> [--profile <debug|release|ship>] [--lsym <file.lsym>]` providing `.lsym` crash-symbolication sidecars, panic message stripping, `.rodata` string/constant stream encryption with in-memory decrypt-on-use (`mkstr_enc`), `std.secret`, `std.protect.guard`, `@protect model` weight & prompt encryption, Mixed Boolean-Arithmetic (MBA), control-flow flattening (`cff_run_flat`), per-seed randomised bytecode virtualisation (`protect.vm`), FIPS 180-4 SHA-256 tamper seals, enclave capability (`std.protect.enclave`), and white-box PRF tables.
  - **Stage 5 Capstone (`examples/apps/lume_os/`):** Capability-based microkernel (`caps.src`, `scheduler.src`, `ipc.src`, `main.src`) with `QF_LIA`-verified page allocation, `@bound` budget-checked scheduler & `@interrupt` timer ISR, reference WASM driver, and the Stage-4 neuro-symbolic agent running in user space over capability-badged IPC.
- **Stage 4 (Phase 4 — `docs/24-phase4-plan.md`): AI, Tensors, Autodiff, Kernels, Probabilistic Programming, Datalog Rules, `extern llm fn` & Spiking Neuro:**
  - **Track N1 — Shape-Typed Tensors & `std.tensor` (`04_parser_decls.src`, `06_typecheck.src`, `06b_phase3.src`, `lcaas.src`, `tensor.src`):** Added `tensor[DType, D1, ...]` with compile-time symbolic shape unification (`[T0300]` diagnostics on mismatched `matmul`, `einsum`, `tensor_add_bias`, elementwise ops, and `if` branches) and native `std.tensor` kernels (`matmul`, `tensor_add_bias`, `tensor_relu`, `tensor_relu_backward`, `tensor_transpose`, `einsum_ij_jk`, `einsum_ij_j`).
  - **Track N2 — Differentiable Programming (`grad`, `value_and_grad`, `jvp`, `vjp`, `jit`), `QF_LIA` Gradient Verification, `kernel fn` & `std.nn` (`06b_phase3.src`, `lcaas.src`, `nn.src`):** Added `type Name = model { ... }`, compile-time symbolic/reverse-mode autodiff (`grad`, `value_and_grad`, `jvp`, `vjp`, `jit`) over the polynomial fragment (`+`, `-`, `*`, `if`, `let`, `relu`, `sq`) emitting `[N0400]` on non-polynomial ops/calls and integrated directly into `QF_LIA` (`lume prove` proves postconditions over `grad(f, x)` and elides runtime guards with `call ctfail == 0`), accelerator `kernel fn` (`@schedule`, `@autotune`, PTX/SPIR-V codegen, `[E0200]` host/heap effect rejection), and `std.nn` (`mlp2_*`, `sgd_step_mlp2`, `adam_step_mlp2`, cryptographic FIPS 180-4 SHA-256 `model_content_hash` for `safetensors` and `onnx` export).
  - **Track N3 — `std.prob`, Semi-Naive Datalog (`rule`), `extern llm fn` (`std.llm`) & Spiking `std.neuro` (`04_parser_decls.src`, `06b_phase3.src`, `lcaas.src`, `ai_runtime.src`):** Added `prob` effect (`dist_beta`, `dist_bernoulli`, `dist_normal`, `infer_mcmc`, `infer_svi`, `infer_smc`), declarative `rule` items and semi-naive Datalog fixpoint engine (`datalog_closure`), `extern llm fn` with `ensures` provenance discharge and BAML-style contract repair loop (`llm_extract_invoice_repaired`), and deterministic LIF spiking neural networks (`lif_neuron_new`, `lif_step`, `lif_run_Currents`).
  - **Stage 4 Capstones (`examples/apps/mnist/` & `examples/apps/agent/`):** Added end-to-end 2-layer MLP trainer reaching 100% accuracy (`loss 120 -> 0`) with `safetensors`/`onnx` export, and a neuro-symbolic agent combining LLM extraction + contract repair, Datalog policy reachability, Bayesian MCMC reliability, and a spiking LIF anomaly watchdog.
- **Inflection Plan (`docs/21-inflection-plan.md` — P0 & Stages A–D):** Dogfooded Phase-3 capabilities directly into the self-hosted compiler (`compiler/stage1/lume/*.src`) while preserving the `stage2 == stage3` fixpoint and Zero-C steady state:
  - **P0 (#167 / PR #171):** Root-caused and fixed inter-procedural algebraic effect handler lowering (`olowercall_fn`, `kuses_hop`, `ksubst_e`, `kbind_hop_args`, `klower_eff_ops`) across effect-polymorphic function boundaries, covered by cross-platform conformance tests.
  - **Stage A (PR #172):** Dogfooded 9 V1 `requires` / `ensures` contracts across Lexer (`numend`, `decimalend`, `decscan`), Parser (`findcloseb`, `parsevariantend`, `parsetypedecimal2`), and Typecheck (`tifn3`, `henv0`, `hbind`) passes (`compiler/stage1/compiler_contracts_ok.src`).
  - **Stage B (#173 / PR #174):** Replaced bounded sampling with a sound `QF_LIA` decision procedure over $\mathbb{Z}$ via Fourier–Motzkin variable elimination (`vqflia_prove_fn`, `vqflia_prove_law`) and constraint-driven counterexample extraction (`vpts_from_hyps`, `vfm_trace_hyps`). Only obligations genuinely decided by `QF_LIA` are marked `proven` and elide runtime guards (including `imax` dogfooded in `05_codegen.src`); nonlinear obligations remain `runtime_checked` (`compiler/stage1/qflia_ok.src`).
  - **Stage C (PR #175):** Modeled the compiler CLI I/O boundary (`07_driver.src`) as `effect CompilerIO { fn read_source() -> str }` with `lumec_drive() / {CompilerIO}` handled at the CLI entry point, while marking all 5 core passes (`lumec_lex`, `lumec_parse`, `lumec_check`, `lumec_expand`, `lumec_compile`) explicitly `/ pure` (`compiler/stage1/compiler_effects_ok.src`).
  - **Stage D (PR #176):** Annotated hot compiler data structures with `own` (`joinall`/`pairs`/`pairs2` in `05_codegen.src` and `gerase`/`gestmts`/`gestmt`/`geexpr`/`geargs`/`gerec`/`gearms` + `cfold`/`cfoldstmts`/`cfoldstmt` in `03_comptime.src`) so `lumec` exercises Perceus in-place constructor reuse (`__perceus_reuse_1` / `__perceus_reuse_2`) with zero `call alloc` in `gestmts`, `geargs`, and `cfoldstmts` (`compiler/stage1/compiler_perceus_ok.src`).
- **Compiler-as-Oracle, Intent-as-Source Synthesis Loop & Autonomous `lume evolve` (`docs/19-intent-as-source.md`, `#178`, `#194`, `#195`, `#203`, `#204`, `#205`):**
  - Upgraded hole-guided synthesis (`06b_phase3.src`, `lcaas.src`, `levolve.src`) to generate linear and conditional AST candidates, prune refuted candidates via counterexample search, rank `QF_LIA`-proven candidates (`proven_candidates`) against `requires`/`ensures` contracts and `law` (`P34`) declarations, elide runtime contract guards on proven synthesized bodies (`compiler/stage1/intent_oracle_ok.src`), and auto-repair `A0001` holes in `lume evolve` (`evolve/proposals/0002_intent_oracle/proposal.bundle`).
  - Added `lume agent witness`, `lume agent repair`, and `lume agent impact` (`caas_witness_json`, `caas_repair_json`, `caas_impact_json` in `lcaas.src` + `lume_witness`/`lume_repair`/`lume_impact` in `lume mcp`, `#195`) returning refuted contract counterexample witnesses, `QF_LIA`-proven contract-body repairs (`"kind":"contract_body_repair"`, `"proven":true`), and per-symbol `"direct_callers"` + `"affected_proofs"` impact sets.
  - Upgraded `lume evolve` governance and autonomous self-evolution loop (`levolve.src`, `./lume`, `evolve/maintainers.pub`, `#194`, `#203`): replaced the forgeable SHA-256 digest and removed the `approved:<name>` bypass in favor of full RFC 8032 Ed25519 + RFC 6234 SHA-512 asymmetric signature verification (`ed25519_verify` over `proposal_id + ":" + sha256_hex(candidate_src)` against public keys committed in `evolve/maintainers.pub`), added `lume evolve apply <proposal>` to apply verified and Ed25519-signed proposals directly to `@target` in the source tree and run the target's test suite, and evolved `compiler/stage1/decimal.src` (`decimal_clamp` + unit test) via `evolve/proposals/0003_decimal_clamp/proposal.bundle`.
  - Ported the Lume CLI control plane (`version`, `help`, `describe`, `compile --json`, `pkg init`, `pkg lock`, `pkg tree`, `evolve propose`, and surface `check`/`test`) to self-hosted Lume in `compiler/stage1/lcli.src` (`#204`), verified in the `stage2 == stage3` bootstrap fixpoint (`lcli2 == lcli3`), and froze the Stage-0 C seed via `bootstrap/lume0/SEED_FREEZE.sha256` enforced by the Lume-native `scripts/zero_c.src` gate (`#205`).
- **Release Engineering & Security Automation (Lotes 1–3):**
  - Added `.github/CODEOWNERS`, `.github/pull_request_template.md`, `.github/dependabot.yml`, `.github/workflows/codeql.yml`, and `.github/workflows/release.yml` (automated self-hosted release artifacts + `SHA256SUMS`).
  - Enforced `make zero-c` and dynamic `find`-based `./lume fmt --check` inside required CI gates.

## [0.3.0] - 2026-10-26 — Stage 3: Ownership, AI-Native Authoring, Effects, Concurrency & Verification

### Added
- **Track O — Ownership, Borrow Checker, `from` Regions & Memory Tiers (`06b_phase3.src`, `ownership.src`, `own_ok.src`):**
  - Single-owner move semantics (`O0001` use-after-move, `O0002` move out of borrow) and deterministic LIFO `defer` / `errdefer`.
  - Borrow modes (`shared` default, `mut` exclusive borrow with `O0010`/`O0011`, `own` transfer with `O0012`).
  - Intra-module region inference and `pub fn ... from <param>` return-origin clauses (`O0020`, `O0021`).
  - Explicit shared/region tiers (`rc[T]`, `arc[T]`, `weak[T]`, `cell[T]`, `arena_new`/`arena_alloc`, `@gc`, `@freestanding` + `with alloc` `O0030`).
- **Track A — AI-Native Authoring (`06b_phase3.src`, `lcaas.src`, `ai_authoring_ok.src`):**
  - Typed holes (`_`, `_hole*`) with expected-type & scope inference, `lume agent fill` candidate synthesis, and `[A0001]` rejection in `pub fn`.
  - `total fn` / `pub total fn` structural and arithmetic measure termination checking (`[A0002]`).
  - Provenance & uncertainty tracking (`unverified[T]`, `llm fn`, `prob_sample`) enforcing `[A0003]` at `pub fn` returns and effectful sinks until discharged via `verify`, contract guards, `law_check`, or `evolve_approve`.
- **Track K — Effect System, Algebraic Handlers & Perceus Reuse (`06b_phase3.src`, `effects_ok.src`, `perceus_ok.src`):**
  - Effect rows (`/ {pure, io, fs, net, alloc, async, fail, panic, rand, time}` + user effects), `pub fn` effect enforcement (`[E0200]`), and `@capability` module checking.
  - Algebraic `effect Name { fn op(...) -> R }` and `with handler Name { ... } in <body>` tail-resumptive lowering.
  - Perceus in-place constructor reuse (`__perceus_reuse_1` / `__perceus_reuse_2`) mutating `own`-matched cells in place with zero heap allocation.
- **Track S — Structured Concurrency, Channels & Supervised Actors (`concurrency.src`, `actor.src`, `concurrency_ok.src`):**
  - Lexical `scope` / `spawn` and static `Send`/`Sync` checking (`[S0001]`).
  - Typed channels (`chan[T]`), deterministic seeded `select`, and data-parallel combinators (`par_for_sum_range`, `par_map_scale`, `par_sum`).
  - `std.actor` mailbox state machines, Erlang/OTP-style `supervisor` (`one_for_one`, `one_for_all`), and `std.time.logical` virtual clock.
- **Track V — Contract Verification, `lume prove` & `LAWS` (`06b_phase3.src`, `lcaas.src`, `contracts_ok.src`):**
  - First-class `requires`, `ensures`, `invariant`, `old(...)`, and `law` declarations (`P34`), static refutation with concrete counterexamples (`[V0001]`), and `lume prove` / `lume agent prove`.
- **Stage 3 Capstone (`examples/apps/job_server/`):** Multi-module concurrent job processing server exercising Tracks O, A, K, S, and V with zero `unsafe`.

## [0.2.0] - 2026-10-26 — Stage 2: Comptime, Hygienic Macros, Data/Query, One-Tool CLI, Self-Evolution & HM Types

### Added
- **Track C — Comptime (`03_comptime.src`):** Compile-time expression folding (`C1`), pure recursive user functions (`C2`), generics via `comptime T: type` (`C3`), `comptime assert` (`C4a`), and precomputed lookup tables (`C4b`).
- **Track M — Macros & Metaprogramming (`ast_meta.src`, `macro_hygiene.src`):** First-class comptime AST (`quote`, `match` over AST, `splice` — `M1`) and hygienic quasiquote (`unquote` with automatic `_hyg_` lexical alpha-renaming — `M2`).
- **Track D — Data & Queries (`decimal.src`, `table.src`, `query.src`):** Exact `decimal(p, s)` arithmetic (`D1`), typed `table[T]` & CSV ingestion (`D2`), and compile-time checked relational queries (`query_where`, `query_order`, `query_join`, `query_group` — `D3`).
- **Track T — One Tool (`./lume`, `lfmt.src`, `ldoc.src`, `ltest.src`, `lmod.src`):** Unified `./lume` CLI (`build`, `run`, `fmt`, `test`, `doc`, `check`, `pkg`, `describe`), canonical AST formatter, and SHA-256 lockfile + `P26` capability auditing.
- **Track E — Self-Evolution (`lcaas.src`, `levolve.src`):** Triple self-build (`stage2 == stage3`) + Zero-C gate (`E2`), `lume compile --json` (`E1a`), in-process compiler library API `use lcaas` + `lume agent` (`E1b`), and 6-gate governed `lume evolve` loop (`E3`).
- **Track F — Hindley–Milner Inference & Front-End Unification (`06_typecheck.src`, `f4_*.src`):** Gradual typing, exhaustiveness checking, full Hindley–Milner constraint unification (`F3c`), and unified grammar across layout, explicit-brace, and Lume-Core (`F4`).
- **Stage 2 Capstone (`examples/apps/inventory/`):** Multi-module inventory, pricing, query, and reporting application (25 `lume test` assertions).

## [0.1.0] - 2026-10-25 — Stage 1: Toolchain-Free Native Self-Hosting (`lumec` + `lasm`)

### Added
- Self-hosted compiler (`compiler/stage1/lume/01_lexer.src`–`07_driver.src`) and native x86-64 assembler + ELF64 writer (`compiler/stage1/lasm.src`) producing static Linux x86-64 binaries with zero C compiler, assembler, linker, or libc dependency.
- Disposable C11 bootstrap seed (`bootstrap/lume0`) with lexer, parser, interpreter, LBE binary AST, semantic checker (`resolve.c`), and seed x86-64/ELF64 backend.
