# ============================================================================
# LUME PROGRAMMING LANGUAGE — BUILT-IN HUMAN & AI MANUAL (v1.1.0 / Wave 10)
# Edition 2026 | Zero-C Self-Hosted Steady State | "Lume gera Lume"
# ============================================================================

Lume is an AI-First AND Human-Friendly systems, verification, data, and neural
programming language. Every program can be formally proven, compiled to 27
hardware/OS targets without a C toolchain, and inspected interactively.

## QUICK USAGE
  lume manual                    Show this manual index (English)
  lume manual --pt               Mostrar o manual em Portugues (pt-BR)
  lume manual <chapter>          Read a specific chapter (e.g., lume manual syntax)
  lume manual --pt <capitulo>    Ler um capitulo em Portugues (ex: lume manual --pt sintaxe)
  lume manual all                Read the entire 10-chapter manual
  lume manual --json [chapter]   Emit structured JSON manual for AI/IDE tools
  lume manual --export <file.md> Generate full Markdown manual file on disk
  lume help <chapter>            Alias for lume manual <chapter>

## MANUAL CHAPTERS (10 CHAPTERS)
  1. overview   (visao-geral)  Architecture (.lume vs .src), Quickstart & Workflow
  2. syntax     (sintaxe)      Complete Grammar, fn/type/match/let & Compiler Rules
  3. types      (tipos)        Primitives, Records, ADTs, Ownership, Decimal, Money, Tensor
  4. contracts  (contratos)    Formal Verification (requires, ensures, law, QF_LIA, WCET)
  5. effects    (efeitos)      Algebraic Effects (/ pure), Scoped Arenas & E-Capsules
  6. stdlib     (biblioteca)   Standard Library & Sovereign Modules (`lume manual chameleon`)
  7. targets    (alvos)        27 Universal Targets, MIR SSA, APK/IPA/ISO/UEFI & Silicon RTL
  8. commands   (comandos)     Full CLI Reference across Phases 1-5 & Waves 1-10 (`lume chameleon`)
  9. examples   (exemplos)     6 Copy-Paste Working Programs + Example 7 (`chameleon_demo.src`)
 10. errors     (erros)        Diagnostic Error Codes ([P0002]..[W0002]) & How to Fix Them

# CHAPTER 1: OVERVIEW & QUICKSTART (ARCHITECTURE & WORKFLOW)

## 1.1 Why Lume Exists
Lume was designed from first principles so that both AI agents and human engineers
can write high-assurance software with zero external C/Python scaffolding:
- Self-Hosted Fixpoint: `lumec` (compiler), `lasm` (assembler/linker), and `lcli`
  compile themselves to bit-identical native binaries (`stage2 == stage3`).
- Built-in Formal Solver: Every `requires`/`ensures` contract and `law` is checked
  at compile time by Lume's internal `QF_LIA` / `QF_ALIA` / Separation Logic prover.
- Two Syntactic Tiers:
  1. `.src` (Lume-Core): Canonical expression-oriented syntax compiled directly by
     the self-hosted native compiler `lumec` and `lume_driver`.
  2. `.lume` (Surface Lume): Indentation/block surface syntax lowered to Lume-Core.

## 1.2 30-Second Human Quickstart
1. Create `hello.src` (always use pure LF `\n` line endings):
   ```lume
   fn square(x: int) -> int
     requires x >= 0
     ensures result >= 0
   = x * x

   fn test_square() = square(9) == 81

   print str(square(12))
   ```
2. Run directly:
   `lume run hello.src`           -> prints `144`
3. Run unit tests (`fn test_*()`):
   `lume test hello.src`          -> runs all `test_*` functions
4. Formally prove contracts:
   `lume prove hello.src`         -> emits `QF_LIA` mathematical proof JSON
5. Compile standalone native executable:
   `lume build hello.src -o hello`

# CHAPTER 2: SYNTAX, GRAMMAR & COMPILER INVARIANTS

## 2.1 Top-Level Declarations in `.src` (Lume-Core)
In `.src` files compiled by `lumec`, every top-level item must be one of:
- `use <module>`               Import a module from `compiler/stage1/<module>.src` or local dir.
- `type Name = ...`            Algebraic Data Type (ADT) or record type definition.
- `fn name(a, b) = expr`       Function definition (optional type annotations & contracts).
- `pub fn name(a, b) = expr`   Public exported function.
- `const NAME: T = expr`       Module-level constant (inlined into functions & contracts).
- `law name(a: int) = expr`    Universal mathematical law proven across all inputs.
- `print <expr>`               Top-level program entrypoint expression.

## 2.2 Expressions, Destructuring & Ergonomic Operators (10/10 DX)
- Local binding:      `let x = 10 in let y = 20 in x + y`
- Tuple destructure:  `let (a, b) = (10, 20) in a + b`
- Record destructure: `let {x, y} = point in x + y`
- Pipe operator:      `x |> step1(5) |> step2`
- Record update:      `{ state with count: state.count + 1 }`
- Conditional:        `if a > b then a else b` or braced `if a > b { a } else { b }`
- Logical (short-circuit): `a == 1 and b == 2`, `x < 0 or x > 10`, `not (a == b)` (`not` binds looser than `==`/`<`)
- Arithmetic:         `+`, `-`, `*`, `/`, `%`
- Comparison:         `==`, `!=` (constant-stack `O(1)` worklist structural equality on deep lists/ADTs/records), `<`, `<=`, `>`, `>=`
- String concat/interp: `f"val={x}"`, `"val=${x}"`, or `"val={x}"`
                        (raw JSON `"{\"a\":{\"b\":1}}"` is preserved; escape literal braces with `"\{x}"`,
                        `"{{x}}"`, or `"cost: \${x}"`; escapes `\n`, `\r`, `\t`, `\b`, `\f`, `\0`, `\'`, `\"`, `\\`)
- Record literal:     `{id: 1, name: "alice"}` (field access: `r.id`, `r.name`)
- List literals & ADTs: `[]` (`Nil`), `[1, 2, 3]` (`Cons(1, Cons(2, Cons(3, Nil)))`), `count([1, 2, 3]) == 3`
- Comments:           `## Double hash starts a comment line`

## 2.3 Pattern Matching (`match` — 10/10 DX)
Lume supports `match` everywhere (top-level bodies, `let ... in`, `if`, call arguments, record fields, and `match` arms):
1. Top-level function body `match`:
   ```lume
   fn sum_list(xs) = match xs
       Nil        => 0
       Cons(h, t) => h + sum_list(t)
   ```
2. Nested indentation-sensitive `match` inside `let ... in`, `if`, call arguments, or `match` arms:
   ```lume
   fn head_or_zero(xs) =
       let y = match xs
           Nil        => 0
           Cons(h, _) => h
       in y + 1
   ```
3. Inline braced `match expr { Pat => body, ... }`:
   ```lume
   fn is_empty(xs) = let res = match xs { Nil => 1, Cons(_, _) => 0 } in res
   ```

## 2.4 Essential Technical Rules for Humans & AI
1. Pure LF (`\n`) Line Endings: Always save `.src` and `.lume` files with Unix LF (`\n`),
   never Windows CRLF (`\r\n`).
2. Arbitrary Function Arity & TCO: Native SysV AMD64 codegen (`05_codegen.src`) passes
   the first 6 parameters in `%rdi, %rsi, %rdx, %rcx, %r8, %r9` and parameters 7+ on the
   stack with full swap-safe self-tail-call optimization (`jmp`).
3. Fail-Closed Patterns & Bindings: Duplicate parameter/pattern/destructuring names,
   float patterns (`1.5 =>`), and unbraced same-line nested `match` fail closed with `[P0002]`.
4. Never edit `compiler/stage1/lumec.src` directly: edit `compiler/stage1/lume/NN_*.src`
   and run `build/bin/lume_make amalgamate`.

# CHAPTER 3: TYPE SYSTEM, OWNERSHIP & DATA TYPES

## 3.1 Core Primitive & Composite Types
- `int`               64-bit signed integer (`-9223372036854775808` .. `9223372036854775807`)
- `bool`              Boolean (`true` / `false`, or `1` / `0` in untyped Lume-Core)
- `str`               Immutable UTF-8 byte-length-cached string (`O(1)` `count(s)`)
- `bytes`             Safe bounds-checked byte buffer (`std.bytes`)
- `List[T]`           Linked list (`Nil` | `Cons(h, t)`)
- `Option[T]`         `None` | `Some(v)`
- `Result[T, E]`      `Ok(v)` | `Err(e)`
- Record `{f: T}`     Structural or nominal record (`{x: 10, y: 20}`)

## 3.2 Algebraic Data Types (ADTs)
```lume
type Shape =
    Circle(int)
  | Rect(int, int)

fn area(s) = match s
    Circle(r)  => 3 * r * r
    Rect(w, h) => w * h
```

## 3.3 Financial & Tabular Types (`decimal`, `money`, `table`, `query`)
- `decimal(p, s)`     Exact fixed-point decimal with precision `p` and scale `s`.
- `money[CCY]`        Currency-parameterized monetary type (`money[BRL]`, `money[USD]`);
                      mixing currencies (`money[BRL] + money[USD]`) is a compile-time error!
- `table[Row]`        In-memory or WAL-persisted (`persist table`) relational table.
- `comptime table_schema(Row)` Inspects record schema at compile time (`[D0273]`).

## 3.4 Shape-Checked Tensors & Autodiff (`tensor[DType, D1, D2, ...]`)
- Shape mismatches are caught at compile time with diagnostic `[T0300]`.
- Supports forward/reverse automatic differentiation (`grad`, `value_and_grad`, `jvp`, `vjp`).

## 3.5 Ownership, Borrowing & Hardware Capabilities
- Linear ownership (`own T`), shared borrows (`ref T`), exclusive borrows (`mut T`)
  verified by the borrow checker (`[O0001]`..`[O0030]`) + Perceus reuse (`__perceus_reuse_1`).
- Freestanding hardware capabilities: `cap[Page]`, `cap[Port]`, `cap[Irq]`.

# CHAPTER 4: CONTRACTS, LAWS & FORMAL VERIFICATION

## 4.1 Function Preconditions & Postconditions (`requires` / `ensures`)
Every Lume function can declare machine-checked contracts:
```lume
fn clamp_deposit(bal: int, delta: int) -> int
  requires bal >= 0 and delta > 0
  ensures result > bal and result >= 0
= bal + delta
```
- If a contract can be violated, compilation fails with `[V0001]` and prints a concrete
  counterexample assignment!

## 4.2 Algebraic Laws (`law`) & Logical Implication Idiom
```lume
law add_commutative(a: int, b: int) = (a + b) == (b + a)
law clamp_implication(x: int, lo: int, hi: int) =
  if lo <= hi then clamp(x, lo, hi) >= lo else 1 == 1
```
- Implication Idiom (`if P then Q else 1 == 1`): Express logical implication $P \implies Q$
  inside `law` declarations using `if P then Q else 1 == 1`, which reduces directly to
  decidable `QF_LIA` branches in both `lcaas.src` and the standalone proof kernel `lcert.src`.
- Compound Termination & Proof Kernel (`lcert.src`): Verifies compound `terminates`
  obligations (`lk_prove_term_cond` across `and`/`or` guards) and runs a built-in
  NIST FIPS 180-4 SHA-256 Known-Answer Test (`sha256("abc")`).

## 4.3 Worst-Case Execution Time Bounds (`@bound(cycles: N)`)
For real-time kernels and interrupt handlers (`@interrupt`), annotate cycle budgets:
`@bound(cycles: 256) fn irq_timer() = ...` (violations emit `[V0002]`).

## 4.4 Autonomous Verification & Self-Healing Commands
- `lume prove <file.src>`              Prove all contracts and laws (`QF_LIA` / `QF_ALIA`).
- `lume certify <file.src> --json`     Emit standalone cryptographic proof certificate.
- `lume verify-cert <file.src>`        Replay proof certificate in standalone `lcert` kernel.
- `lume heal <file.src>`               Auto-repair refuted `ensures` contracts from counterexamples.
- `lume equiv <spec.src> <fast.src>`   Formally prove two implementations equivalent + superoptimize.
- `lume agent cegis <file.src>`        Synthesize missing `??` hole expressions via CEGIS.

# CHAPTER 5: ALGEBRAIC EFFECTS, DETERMINISTIC MEMORY, ARENAS & CAPSULES

## 5.1 Row-Polymorphic Algebraic Effects (`/ pure`, `/ {io, fs, net}`)
- Functions marked `/ pure` cannot perform I/O, network, process execution, or raw
  global arena mutation; violations fail closed with `[E0200]`.
- Custom effects are declared with `effect Name { fn op(...) -> T }` and handled via
  `handle expr with { ... }`.

## 5.2 Automatic Memory, Zero-Heap SRA & Scoped Arenas (`std.arena`)
- Lume collects garbage (a mark-sweep pause proportional to the live heap) and avoids heap work
  where it can prove it safe: Perceus reuse for provably unique values,
  Escape Analysis & Scalar Replacement of Aggregates (`lsra_expr`: non-escaping
  `let r = {k1: v1, ...} in body` records are lowered directly into `%rbp` stack
  slots `_sra_<r>_<k>` with 0 heap allocations), self-tail-call `jmp`, and O(1) arenas.
- Value words: an integer of 63 bits and a string of at most 7 bytes live in one machine word and
  never reach the heap; `int` still holds the full 64-bit range. A constructor costs 8 bytes plus its
  fields, a record 8 bytes plus its values, and a constructor without fields is one static cell.
- Builtins & `use arena`:
  - `let a = arena_new(65536)`   Create a scoped region arena
  - `mem_pack(s)` / `mem_unpack(b)`   Compress cold data (LZ4 block format, corrupt input stops)
  - `arena_freeze(a)` / `arena_thaw(a)`   Compress an arena; a frozen page returns on first touch
  - `arena_mark_secret(a)`, `@secret fn`   Secrets never reach the compactor ([C0009])
  - `arena_reset(a)` / `arena_destroy(a)`
  - `heap_stats()`               Query live heap allocations and bytes
  - `lume run --memory <file.src>` Measure peak RSS memory in KB

## 5.3 Tamper-Evident E-Capsules (`std.capsule` & `lume capsule`)
- Seal execution traces, inputs, outputs, and SHA-256 digests into reproducible capsules:
  - `lume capsule seal <source.src> -o <out.lcaps>`
  - `lume capsule replay <out.lcaps>`

# CHAPTER 6: BUILTINS, STANDARD LIBRARY & SOVEREIGN MODULES

## 6.1 Core Builtin Functions (Always Available in `.src`)
- Strings:  `count(s)`, `at(s, i)`, `slice(s, start, end)`, `slicen(s, n, start, end)`,
            `ord(ch)`, `chr(code)`, `str(n)`, `toint(s)`
- I/O & FS: `readall()`, `fs_read_file(path)`, `fs_write_sync(path, data)`,
            `fs_path_exists(path)`, `fs_read_byte(path, offset)`
- Process:  `os_arg_count()`, `os_arg_at(i)`,
            `os_getpid()`, `os_exit(code)`, `os_run(cmd, args)`, `os_run_capture_timeout(cmd, args, out, err, ms)`
- Hardware & Bare-Metal Kernel Primitives (Always Available in `@freestanding` / `.kernel`):
  - Port I/O (8/16/32-bit): `port_out8(p, v)`, `port_in8(p)`, `port_out16(p, v)`, `port_in16(p)`,
                            `port_out32(p, v)`, `port_in32(p)`
  - Volatile MMIO (8/16/32/64-bit): `mmio_volatile_write8(a, v)`, `mmio_volatile_read8(a)`,
                                    `mmio_volatile_write16(a, v)`, `mmio_volatile_read16(a)`,
                                    `mmio_volatile_write32(a, v)`, `mmio_volatile_read32(a)`,
                                    `mmio_volatile_write64(a, v)`, `mmio_volatile_read64(a)`
  - Native VGA Console (`0xB8000` + CRT `0x3D4`/`0x3D5`): `vga_puts(row, col, attr, text)`,
    `vga_fill_row(row, attr, ch_ascii)`, `vga_scroll_up(top_row, bot_row, attr)`,
    `vga_set_cursor(row, col)`
  - CPU, MSR & SMP: `cpu_cli()`, `cpu_sti()`, `cpu_hlt()`, `cpu_pause()`, `cpu_mfence()`,
                    `cpu_rdtsc()`, `cpu_rdmsr(msr)`, `cpu_wrmsr(msr, val)`, `cpu_read_cr3()`,
                    `cpu_write_cr3(v)`, `cpu_invlpg(va)`, `cpu_idt_init()`, `cpu_smp_boot_ap(v)`
  - 64-Bit Hardware Bitwise: `bit_and(a, b)`, `bit_or(a, b)`, `bit_xor(a, b)`, `bit_not(a)`,
                             `bit_shl(a, n)`, `bit_shr(a, n)`
  - Constant-Time Intrinsics: `ct_select(mask, a, b)` (bit by bit: `a` where the mask bit is set, else `b`),
                              `ct_eq(a, b)` (1 when equal, else 0); both are branch-free in a constant-time kernel
  - Block Memory, Integrity & O(1) Kernel State: `mem_copy(dst, src, len)`, `mem_set(dst, b, len)`,
    `mem_crc64(addr, len)` (64-bit FNV-1a anti-rootkit page integrity), `krn_slot_write(idx, val)`,
    `krn_slot_read(idx)` (zero-allocation 1024-slot kernel state table)
- Failure:  `ctfail(msg)` (prints message to stderr and exits with non-zero code)

## 6.2 Standard Library Modules (`use <module>`)
- `use fs`             Safe file handles (`sfile_with` close-on-all-paths, `[O0001]` safety)
- `use bytes`          Bounds-checked byte buffers (`bnew`, `bpush`, `bget`, `bslice`, `bto_str`)
- `use vec`            Formally verified generic collection & numeric invariants (`vec.src`, `decimal.src`,
                       `stdlib/std.lume`: `vec_clamp_index`, `vec_checked_slice_len`, `map_checked_slot`,
                       `decimal_clamp`)
- `use map`            256-way hash-bucketed dictionary (`map_new`, `map_put`, `map_get`, `map_get_or`,
                       `map_checked_slot`)
- `use arena`          Scoped O(1) memory arenas (`arena_new`, `arena_alloc`, `arena_reset`, `heap_stats`)
- `use capsule`        Tamper-evident execution capsules (`capsule_seal`, `capsule_verify`)
- `use fs_sha256_file` FIPS 180-4 SHA-256 digest (`lc_sha256(str)`, `fs_sha256_file(path)`, `fs_file_size(path, i)`)
- `use db`             Multi-way B+Tree + ACID WAL crash-recovery engine & SQL query executor
                       (`+/- 10^12` 64-bit scan bounds, nested `db_begin_tx` guard, and `BMInner`
                       separator subtree pruning, `6/6` `QF_LIA` proofs)
- `use net`            Full TCP/IP, Wireshark Multi-Layer Dissector (`wireshark_dissect_frame`,
                       `wireshark_filter_match`, `.pcap` reader/writer), L2/L3/P4 Switch Firmware
                       Engine (IEEE 802.1Q VLAN admission fix, 802.1w RSTP, CAM/MAC learning, MPLS,
                       FIB LPM, BGP-4, P4 pipeline), Industrial/Substation Telemetry Protocols from
                       scratch: Modbus RTU/TCP (`CRC-16 0xA001`), DNP3 IEEE 1815 (`0x0564` +
                       `CRC-16/DNP` + SBO + SAv5), IEC 60870-5-104 (`TCP/2404` I/S/U-Format),
                       IEC 61850 (`MMS ISO 9506`, `GOOSE 0x88B8`, `Sampled Values 0x88BA` with exact
                       frame-length guards), and Digital Substation Protection Relays
                       (`sv_dft_4sample_phasor` 60 Hz DFT, `net_isqrt` up to `10^16`, direct
                       `ansi50`/`ansi27_59` contracts, `ANSI 51`, `ANSI 87`, `ANSI 21`, `ANSI 81`,
                       `ANSI 79`, `23/23` `QF_LIA` proofs)
- `use gfx`            2D/3D Graphics, Fixed-Point Math (`fx_sqrt`, `fx_sin_deg`, `fx_cos_deg`),
                       Porter-Duff RGBA Alpha Blending, Bresenham/Circle/Bezier 2D Rasterizer,
                       3D Pinhole Perspective Projection, Binary 54-Byte BMP, PPM & SCADA HMI SVG
- `use gui`            X11 wire-protocol client (`0x42` MSB handshake, `CreateWindow`), Web DOM,
                       Declarative 4-Pane UI Layout (`lume ui-layout` / `@ui-layout`) for Win64 PE32+
                       & Web/WASM lowering with simultaneous `WS_THICKFRAME` border resizing and
                       `LBS_NOTIFY | LBS_HASSTRINGS` mouse selection (`1412694337` / `0x54340141` and
                       `1412698308` / `0x543410C4`) + `QF_LIA` split-pane geometry conservation
                       (`ui_split_conservation_law`), and System76 COSMIC 1.11 Wayland `xdg-dialog-v1`
                       modal dialog z-index stacking & background click blocking
                       (`ui_modal_blocks_parent`, `ui_modal_z_index`, `QF_LIA` proven)
- `use los`            Track O General-Purpose OS layer + System76 COSMIC 1.11 deterministic
                       hybrid GPU (`iGPU` vs `dGPU`) PCI selection policy (`os_select_hybrid_gpu`,
                       `11/11` `QF_LIA` proofs)
- `use nn`             Neural layers, binary `.safetensors` & Protobuf `.onnx` model I/O with
                       64-bit two's complement negative weights (`nn_le64_hex`), full-CSV
                       `model_content_hash`, and `tensor.src` `KIf` PTX/SPIR-V division-by-zero
                       clamping (`16/16` `QF_LIA` proofs)
- `use async_rt`       Work-stealing OS multi-process worker pool (`async_run_workers_os`)
- `use media`          2D raster canvas, font glyph renderer, and binary image codecs
- `use interop`        Fail-closed C ABI layout & header adapter (`[I0003]`)
- `use protect`        P33 control-flow flattening, string encryption, multi-step algebraic MBA
                       prologue (`addq`/`xorq`/`subq` in `lprotect.src`), & `[W0002]` secret scanner
- `use lgenesis`       Full-stack application & 8-target autonomous synthesizer
- `use lsentience`     Wave 9-10 Quantum, DNA, HDC, DEQ, LLM-Forge, Triad & Multimodal engine
- `use lume_llm_core`  Sovereign 1-Bit/Ternary LLM Core & 3-Tier Hybrid Router (`21/21` `QF_LIA` proofs):
                       PrismML `Bonsai` 1-bit (`{-1, +1}`) & `BitNet b1.58` ternary (`{-1, 0, +1}`)
                       zero-float integer MAC + 5-trit byte packing (`3^5 = 243 <= 255`), Liquid AI
                       `LFM3` $O(1)$ state-space recurrence + `LiquidCodec` 24 kHz audio frame math
                       (`12` tokens / `80 ms`), `DSpark` speculative decoding verifier, `Colibri` MoE
                       SSD admission guard (`llm_moe_admission_guard`), and 3-Tier Hybrid Router
                       (`Tier 0` Pure Lume Core -> `Tier 1` Local `Gemma4-E2B`/`Ministral-3B-Q4`/`Bonsai-1bit`
                       -> `Tier 2` Cloud API Key) with `QF_LIA` price/contract anti-hallucination oracle
- `use lume_crypto_blockchain_engine` SHA-256 PoW, Ed25519/Secp256k1, UTXO, AMM & Kelly Criterion
- `use lume_reversa_engine` Reversa-Lume SDD Engine v1.0: 7-phase hybrid binary (`ELF64`, `PE64`,
                       `UEFI`, `Mach-O`, `WASM`) + NSIS/7z installer payload unpacker + multi-language
                       reverse engineering, SHA-256 immutability guard, epistemic `CONFIRMED`/`INFERRED`/`GAP`
                       confidence score, `reversa_soul.md`, Mermaid `stateDiagram-v2` & C4 `flowchart TD`,
                       3D `reversa_code_city_3d.svg` via `std.gfx`, and modular `.src` Lume-Core reconstruction
- `use lume_pingora_proxy_engine` Pingora-Lume Edge Proxy Engine v1.0: `TinyUFO` S3-FIFO + 4-hash
                       Count-Min Sketch cache, `Ketama` 64-bit consistent hash ring + `P2C` load
                       balancer, dual-window sliding rate limiter (`429`), cache stampede lock,
                       keepalive connection pool + RFC 8446 TLS 1.3 session reuse, 3-state circuit
                       breaker + zero-downtime graceful hot-upgrade, and 7-phase `ProxyHttp` pipeline
- `use lume_egm_engine` EGM-Lume Elephant-Goldfish Model Engine v1.0: 8-pillar DARPA Heilmeier
                       Catechism validator + 6-lens Brainstorm shootdown, epistemic context isolation
                       (`Elephant` deep memory vs `Goldfish` zero-context `hist == 0, bias == 0`),
                       Stage 6 blind paraphrase comprehension test, Anti-Glazing lexical scanner,
                       5-stage antagonistic Goldfish review (Stages 5..9), contradiction auditor,
                       and bidirectional Spec <-> Code drift report integrated with `lume_reversa_engine`
- `use lume_ncm_engine` NCM-Lume Next-Concept Modeling Engine v1.0 (Stanford Hazy Research arXiv:2610.14162):
                       Multiscale Residual Vector Quantizer (`MS-RVQ` scales `[4, 8, 16, 32, 64]`,
                       area downsampling, linear upsampling, commitment loss, EMA centroids, dead-code
                       restart), Tied Codebook Euclidean Distance Logit Head (`2*<z,E_i> - ||E_i||^2`),
                       Block-Diagonal Scale-Causal Attention Mask + Per-Level Reset RoPE (`wle`),
                       Parallel Coarse-to-Fine K-Scale Decoder + Classifier-Free Guidance (`CFG`),
                       Global Constraint Satisfaction Sudoku 4x4 Solver, and Symbiotic Bridge with
                       `LLM-Forge`, `lume_egm_engine`, and `lume_reversa_engine`
- `use lume_opentpu_engine` OpenTPU-Lume Systolic AI Accelerator & ISA Engine v1.0 (`OmegaSoftDLL/openTPU`):
                       `openTPU ISA v1` assembler/disassembler, linear scalar register lifetimes (`R0..R15`),
                       Systolic Matrix Unit (`MXU`) stationary-row replay (`ceil(M / MCOLS)`), two-level
                       block-scaled quantizer (`QACT` `Sa * 2^-da` int8 + `FP4` 4.25 bits/weight), formal
                       K-Smoothing outlier migration (`<Q*2^s, K*2^-s> == <Q,K>`), programmable 5-stage
                       fused Stream Engine (`SE`, opcode `0x13` `STREAM` for Gated DeltaNet), card-side
                       MoE LRU slot cache + `WAITW` compute/PCIe-DMA overlap scheduler, analytic hardware
                       Scoreboard & Byte-Roofline verifier (`YPCB`, `BCU1525`, `AWS F2`, `ASIC`), and
                       0-ULP Golden/ISA-Sim/RTL equivalence bridge with `lume_ncm_engine`
- `use lume_continuum_nexus_engine` Lume Continuum Nexus Engine v1.0 (7 Reference Architectures):
                       `ECC AgentShield` red-team/blue-team security scanner & Bayesian instinct evolution
                       (`0.30..0.99`), `Bend` tree superposition (`bend/fold`) & state conservation laws,
                       `Billion-Context` Active Context Pruning (`ACP`) reversible hierarchical compression
                       (`96%` prefix-cache hit, lossless restore), `AI-Memory` access-weighted retention
                       curve + `claim-once` handoff + Dreaming Wiki (`ai_memory_wiki.md`), Sovereign
                       Quota-Aware Multi-Provider LLM Router, `Open-Notebook` grounded citation spans &
                       3-speaker binary RIFF/WAVE PCM podcast (`open_notebook_podcast.wav`), and `Doory`
                       conflict-free `LWW-Element-Set` CRDT scene-graph & vector slide (`doory_continuum_slide.svg`)
- `use lume_quantum_nexus_engine` Lume Sovereign Quantum Nexus Engine v1.0 (5 Quantum Innovations):
                       `Silq` Linear Qubit Type Checker (`No-Cloning`/`No-Measure-Reuse`), non-unitary `Meas`
                       dagger guard (`q_is_reversible_unitary`) & Automatic $U^\dagger$ Ancilla Uncomputation
                       (`qfree_safe == 1`), `QuiZX/PyZX` Graphical ZX-Calculus Spider Fusion & $T$-Count
                       Optimizer (`7x` $T$-gate reduction + pre/post-ZX statevector equivalence `q_sv2_equiv_tol`),
                       `Google Stim` Gottesman-Knill $O(n^2)$ Stabilizer Tableau Simulator (`GHZ_8`), Rotated
                       Surface Code `[[9, 1, 3]]` Topological QEC (`27/27` Pauli errors corrected), and
                       `PennyLane/Catalyst` Exact Parameter-Shift VQE
- `use lchameleon`     Universal Chameleon Polyglot Interop Engine v1.0 (`28/28` `QF_LIA` proofs,
                       `8/8` unit tests): Fail-closed `[I0003]` (`unverified[T] -> verified[T]`
                       under `/ {ffi}`) across all 9 ecosystems: `c_abi` (C/C++ `.h`/`.dll`/`.so`
                       Win64/SysV shadow-space & alignment), `rust_cdylib` (Cargo `extern "C"`
                       Perceus borrow exclusivity & unwind guard), `python_capi` (`PyObject*`
                       refcount conservation & zero-copy DLPack tensors), `node_napi_wasm`
                       (Node-API & WASM 64 KiB page bounds), `go_cshared` (`cgo` pointer-pinning
                       & stack-split guard), `java_jni` (`JNIEnv*` local frame & Panama FFM),
                       `dotnet_pinvoke` (`P/Invoke` & NativeAOT blittable layout), `sql_relational`
                       (`DDL`/`DML` -> `table[T]` row invariants), and `openapi_rpc` (HTTP/1.1,
                       TLS 1.3 & gRPC bounded payloads)

## 6.2.1 Universal Chameleon Polyglot Interop Engine (`use lchameleon` — 9 Ecosystems)
- **9 Verified Foreign Ecosystems:** `c_abi` (C/C++ `.h`/`.dll`/`.so` Win64 32-byte shadow space & SysV ABI),
  `rust_cdylib` (Rust `cdylib` Perceus ownership transfer & unwind guard), `python_capi` (CPython
  `PyObject*` refcount conservation & zero-copy DLPack tensors), `node_napi_wasm` (Node-API & WASM
  64 KiB linear memory bounds), `go_cshared` (Go `-buildmode=c-shared` pointer-pinning guard),
  `java_jni` (Java JNI local frame capacity & Project Panama `MemorySegment`), `dotnet_pinvoke`
  (C#/.NET P/Invoke & NativeAOT blittable layout), `sql_relational` (PostgreSQL/SQLite/DuckDB
  `DDL`/`DML` -> `table[T]` row invariants), and `openapi_rpc` (OpenAPI 3.1 / JSON Schema / gRPC).
- **Fail-Closed `[I0003]` Boundary Contracts:** Foreign inputs enter as `unverified[T]` under the
  `/ {ffi}` capability and are promoted to `verified[T]` only after `chameleon_verify_boundary`
  proves non-null pointers, alignment, and `QF_LIA` range bounds (`28/28` proven obligations).
- **CLI, REPL & LSP Integration:** Run `lume chameleon [eco]`, `lume camaleao [eco]`, `lume polyglot`,
  `lume ffi-bridge`, `lume adapt <c|rust|python|js|go|java|dotnet|sql|openapi> [file]`, or
  `lume morph <legacy_file>`; inside `lume repl`, use `:chameleon [eco]` or `:camaleao [eco]`.
- **Official Mascot (Lumi — The Bioluminescent Crystal Chameleon):** Embedded natively as `16x16` 32-bit
  BGRA `RT_ICON` (`Type=3, ID=1`) + `RT_GROUP_ICON` (`Type=14, ID=1`) in `--target x86_64-windows-gui`.

## 6.2.2 Declarative UI Layout (`@ui-layout`) & Verified Collection Invariants (`vec.src`, `decimal.src`, `stdlib/std.lume`)
- **Declarative UI Layout (`lume ui-layout` / `@ui-layout`):** Lowers declarative 4-pane workspace layouts
  to native Win64 PE32+ (`--target x86_64-windows-gui`) and Web/WASM DOM trees with simultaneous
  `WS_THICKFRAME` live border resizing and `LBS_NOTIFY | LBS_HASSTRINGS` mouse selection (`1412694337` /
  `0x54340141` for Listbox panes and `1412698308` / `0x543410C4` for multiline Edit panes), guarded by
  `QF_LIA` split-pane geometry conservation (`ui_split_conservation_law`).
- **Formally Verified Generic Collection Invariants (`vec.src`, `decimal.src`, `stdlib/std.lume`):**
  Machine-checked `QF_LIA` bounds and clamping helpers: `vec_clamp_index`, `vec_checked_slice_len`,
  `map_checked_slot`, and `decimal_clamp`.

## 6.2.3 Unified Field & Subsea Engine (`lume unified-field` / `lume ufe` / `lume subsea`), Singularity Transition & Bayes-SPC Engine (`lume singularity` / `lume ote`) & NetSentinel IEC 62443 / Conduite HA / Sovereign Mesh (`lume net-sentinel` / `lume iec62443` / `lume conduite` / `lume omega-mesh`)
- **Unified Field & Subsea/Offshore Engine (`lume unified-field` / `lume ufe` / `lume subsea` in `std.gfx`, `77/77` `QF_LIA` & WCET obligations, `9/9` tests):**
  - **7-DOF Singularity-Free Damped Least-Squares (DLS):** `ufe_dls_lambda_sq_milli` and
    `ufe_dls_safe_denom_milli` guarantee strictly positive inverse-kinematics denominators
    (`sigma_sq + lambda_sq >= 1`) near kinematic singularities.
  - **3D Harmonic Laplace Red-Black SOR Solver & Maximum Principle:** `ufe_laplace_sor_step_milli`
    and `ufe_harmonic_maximum_principle_law` solve $\nabla^2 \phi = 0$ on 3D voxel grids with
    provably zero local minima outside the target sink.
  - **GNRON Swirl Attenuation, Capsule Self-Collision & IEEE-754 Finite Register Guard:**
    `ufe_gnron_swirl_scale_milli` attenuates non-conservative rotational swirl,
    `ufe_self_collision_capsule_ok` enforces 7-DOF link-pair capsule clearance, and
    `ufe_ieee754_f32_finite_guard` rejects `NaN`/`Inf` exponent `255` before hardware actuator
    registers are written.
  - **Dual-State Actuator EKF ($5\sigma$ Mahalanobis + Joseph Covariance), Stiction & RUL:**
    `ufe_ekf_mahalanobis_5sigma_ok` enforces `innov_sq <= 25 * S` (`5-sigma` gate),
    `ufe_ekf_joseph_cov_pos_milli` guarantees positive-definite covariance updates,
    `ufe_actuator_stiction_detect` isolates control valve stiction/deadband, and
    `ufe_actuator_rul_hours` estimates Remaining Useful Life (`RUL`).
  - **Multi-Robot Swarm Separation, IAPWS-IF97 Steam Regions, Wet-Steam & Carnot Bound:**
    `ufe_swarm_separation_ok` proves inter-agent collision clearance, `ufe_if97_region_select`
    classifies thermodynamic steam regions (`1..4`), `ufe_turbine_wet_steam_guard` prevents blade
    erosion, and `ufe_carnot_efficiency_bound_ok` enforces 2nd-law Carnot efficiency bounds.
  - **Deterministic 1 kHz `LatencyMonitor` with 100-Cycle Hysteresis:** `ufe_latency_shedder_step`
    sheds non-critical load immediately on budget overrun and requires 100 consecutive clean
    1 kHz cycles before restoring full load.
  - **Subsea Catenary, VIV, Heavy-Lift DAF, Hyperbaric ZH-L16C, Well Control & ASME B31G (Wave 3):**
    `subsea_catenary_top_tension_n`, `subsea_catenary_tdp_bend_ok`,
    `subsea_combined_longitudinal_stress_ok` (`DNV-OS-F101`), `subsea_viv_screening_ok` (`DNV-RP-F105`),
    `subsea_miner_fatigue_safe_ok` (`DNV-RP-C203`), `marine_dnv_daf_floor_milli` &
    `marine_heavy_lift_feasible_ok` (`DNV-ST-N001`), `subsea_hyperbaric_decompression_safe_ok`
    (`Buhlmann ZH-L16C` $p_O2 \in [16, 160]$ cbar), `subsea_well_kill_icp_kpa` &
    `subsea_well_kill_mud_sg_milli` (*Wait & Weight* kill sheet), and `subsea_b31g_corroded_pipe_safe_ok`.
- **2nd-Order Dynamical Transition Engine, Singularity Boundary $\Omega$, Empirical-Bayes SPC & Zero-Limitation Tensor/Quire/Assimilator (`lume singularity` / `lume ote` / `lume transition-engine` in `lchameleon.src`, `200/200` `QF_LIA` & WCET obligations, `19/19` tests):
  - **Dual-Regime Step Identification & Quantitative $\zeta$ Estimator:** `ote_select_damping_regime`
    and `ote_estimate_zeta_milli` dispatch underdamped ($0 < \zeta < 1$ via overshoot $M_p$ and
    peak period $T_d$) vs. critically/overdamped ($1 \le \zeta \le 100$ via dimensionless rise-time
    ratio `t_80 / t_20`).
  - **Operational Power Triangle (`S, P, Q, cosPhi`) & Phase Coherence:** `ote_power_factor_milli`,
    `ote_reactive_waste_ratio_milli`, and `ote_phase_coherence_ok` quantify useful power vs.
    reactive rework and verify energetic vs. delay phase coherence (`|Phi - Phi_tau| <= 10 deg`).
  - **Singularity Boundary $\Omega$ (`tau_max = T_m / 4`), Margin Zones & Nyquist Guard:**
    `ote_singularity_tau_max_ms`, `ote_omega_boundary_crossed`, and `ote_singularity_margin_zone`
    detect counter-phase delivery across $\Omega$ (`omega_env * tau > pi / 2`), while
    `ote_nyquist_status_code` enforces $N_y = T_m / (2 T_s)$ (`NYQ-ALIAS` $< 1.0$, `NYQ-LIMIT` $< 2.0$).
  - **Cascade Bandwidth Decoupling, Gain Retuning & 9 Normative Prescriptions:**
    `ote_cascade_bandwidth_decoupled_ok` enforces $3\times$ inner/outer loop timescale separation,
    `ote_retune_kp_scale_milli` computes safe proportional gain scaling, and
    `ote_diagnose_primary_code` evaluates in immutable physical leverage order
    (Sampling $\to$ Delay/Boundary $\to$ Gain $\to$ Inertia):
    `NYQ-ALIAS` $\to$ `NYQ-LIMIT` $\to$ `OMEGA-CROSS` $\to$ `PF-LOW` $\to$ `MF-LOW` $\to$
    `CASCADE-DEEP` $\to$ `ZETA-LOW` $\to$ `ZETA-HIGH` $\to$ `QAMP-HIGH` / `TUNED`.
  - **Empirical-Bayes Beta-Binomial SPC, Bilateral CUSUM, CPM Float & $k$-Anonymous PAVA (Wave 3):**
    `spc_beta_binomial_posterior_num`, `spc_cusum_upper_step_milli`, `ops_cpm_total_float_hours`,
    `analytics_k_anonymity_release_ok` ($k \ge 5$ privacy gate), and `analytics_pava_monotonic_pair_hi`.
  - **Verified Floating-Point / Posit-Quire Tensor Engine, `QF_FP_Interval` & Autonomous Ecosystem Assimilator (Wave 4):**
    `fp_bf16_is_finite_ok`, `fp_fp16_is_finite_ok`, `fp_quire_exact_dot_accum` (`Posit-Quire` associativity law),
    `fp_interval_add_lo` & `fp_interval_add_hi` (`QF_FP_Interval` enclosure law),
    `fp_tensor_core_mma_m16n8k16_waves` & `fp_flash_attention_o1_sram_tiles` (PTX/SPIR-V GPU Tensor Cores),
    `pkg_assimilate_purity_gate_ok` (supply-chain backdoor rejection law), and
    `pkg_omni_stdlib_btree_split_mid` & `pkg_omni_stdlib_mvcc_visibility_ok` (`Omni-Stdlib` ACID B+Tree/MVCC).
  - **LumePuter & LumePU Weight-Compiled `RV32IM_Zba` + Bignum + Vector/Matrix NPU (`VDOT`/`SMAQA`/`VX VMAT`) & Zero-Drift Gated-DeltaNet RAM Engine (Wave 5, `lume lumeputer` / `lume lumepu` / `lume qwenputer`, Integrated Across All 17 Core Modules & 104 Autonomous Domains):**
    `lumeputer_swiglu_exact_relu_unit` (`SiLU(k * b) -> ReLU` for $k \ge 18$),
    `lumeputer_ballast_rmsnorm_guard_ok` (`B = 10000` norm-absorption immunity),
    `lumeputer_deltanet_ram_step_exact` (exact `beta = 1` overwrite & `beta = 0` zero-BF16-drift retention),
    `lumeputer_rv32im_pc_step` (4-byte aligned `PC = anchor + commits` & branch/JALR targets),
    `lumeputer_bmac_digit_file_step` (`BMAC` 128-digit bignum register file MAC),
    `lumepu_vdot_int8_int4_mac` & `lumepu_vx_vmat_row_mac_exact` (64-lane `VX VMAT` systolic NPU inside FFN weights),
    `lumeputer_compile_rv32_vx_to_weights_layers` (`11` layers for `RV32IM_Zba`, `13` layers with `VX` NPU `stories260K` in-weights),
    and full 17-module cross-compiler integration (`stdlib/std.lume`, `lstd.src`, `tensor.src`, `nn.src`,
    `ai_runtime.src`, `ltarget.src` `--target lumeputer-rv32im-weights`, `lchameleon.src`, `lsentience.src`,
    `lume_driver.src`, `lcli.src`, `linteractive.src`, `lmanual.src`, `lume_llm_core.src`,
    `lume_opentpu_engine.src`, `lume_ncm_engine.src`, `lume_continuum_nexus_engine.src`, `claude_audit_gate.src`)
    plus the 104-Domain 24/7 Autonomous Sanctuary Evolver (`#0..#103`, coprime step `43 mod 104`).
  - **Wave 6 `LumePuter` Recursive Stack `.lweights` Compiler, Relational Octagon/Interval Loop Prover & Universal Interface-Signature Incremental Cache v2:**
    `lumeputer_stack_push_frame_sp` & `lumeputer_compile_src_bundle_lweights` (recursive call stack frame push/pop and multi-function `.lweights` layer bundling),
    `prover_octagon_transitive_upper` & `prover_loop_ranking_steps_remaining` (Relational Octagon/Interval abstract interpretation and loop termination ranking),
    and `incremental_module_iface_digest` & `incremental_can_reuse_downstream_mod` (Universal Interface-Signature Incremental Cache v2 avoiding downstream rebuilds on body-only edits).
  - **Wave 7 `LumePuter` Trap/CSR (`ecall`/`mret`) & In-Weights `lcert` Verifier, Farkas Dual + Bit-Shift Prover & Fail-Closed FFI Callback Arena Epoch + Fuzzy Repair:**
    `lumeputer_ecall_save_mepc`, `lumeputer_mret_restore_pc` & `lumeputer_inweights_lcert_check` (`ecall`/`mret` CSR trap roundtrip and in-weights proof certificate verification),
    `prover_farkas_dual_rhs_sum`, `prover_farkas_unsat_witness_ok` & `prover_bitshift_shl_exact_bound` (Farkas Lemma linear dual contradiction witness and exact bit-shift bounds),
    and `ffi_callback_arena_epoch_safe`, `diag_fuzzy_repair_distance_score` & `diag_fuzzy_repair_suggest_ok` (`#334` FFI callback arena epoch guard and `#407` AI-first fuzzy symbol/arity repair).
  - **Wave 8 Industrial SSA/Chaitin Register Allocator/AVX-512 Auto-Vectorizer, Automated `io_uring` Zero-Copy FFI Bridge, Non-Linear Horner/Inductive Graph Prover & Structural Compiler Pass Evolver:**
    `ssa_chaitin_register_spill_cost`, `ssa_interprocedural_inline_gain` & `avx512_autovec_loop_speedup_lanes` (Chaitin-Briggs $K$-colorable zero-spill register allocation, interprocedural inlining and 8-lane AVX-512 loop auto-vectorization),
    `ffi_auto_header_abi_layout_ok` & `io_uring_zero_copy_ring_submit` (automated C/OS/CUDA ABI layout verification and Linux `io_uring` / Windows IOCP zero-copy DMA submission ring backpressure),
    `prover_nonlinear_horner_lower_bound` & `prover_inductive_graph_dag_rank_ok` (non-linear polynomial Horner/Bernstein bounding and inductive DAG topological rank acyclicity proofs),
    and `compiler_pass_evolve_verified_promote` (autonomous structural compiler pass self-evolution gated by `QF_LIA` equivalence and strict WCET reduction).
  - **Wave 9 Real x86-64 VEX/EVEX SIMD (`AVX2`/`AVX-512`) Machine-Code Encoding, Real Linux Kernel `io_uring` Syscalls (`425`/`426`/`427`), Native AST `x * x` Quadratic Square-Completion Prover & Industrial C Header Preprocessor (`--preprocess`):**
    `simd_add4_i64`, `simd_sub4_i64`, `simd_xor4_i64` & `vex_simd_hardware_add4_sum` (real VEX `%ymm0..%ymm15` and EVEX `%zmm0..%zmm15` encoding in `lasm.src` + hardware 256-bit `vpaddq`/`vpsubq`/`vpxor` in `05_codegen.src`),
    `os_io_uring_setup`, `os_io_uring_enter`, `os_io_uring_register` & `io_uring_kernel_syscall_sqe_batch_safe` (real Linux kernel `io_uring` syscalls `425`/`426`/`427` in `05_codegen.src`),
    `ast_native_horner_quadratic_eval` & `ast_native_quadratic_square_completion_law` (native AST `x * x + 2 * x + 1 >= 0` and `x * x + x >= 0` square-completion inside `06b_phase3.src` and `lcaas.src`),
    and `c_header_preprocessor_macro_strip_ok` (`lume adapt c --preprocess <header.h>` / `lume adapt c-raw <header.h>` stripping `#ifdef`/`#define`/`typedef`/`struct`/`__attribute__`/`WINAPI` from raw system `.h` headers).
  - **Wave 10 Critical Production-Assurance & Independent Verification Suite (Domains `#108..#111`, 112 Sovereign Domains Total `#0..#111`):**
    `lasm_vs_gnu_as_differential_byte_eq` & `lasm_differential_Mismatch_rejected_law` (Domain `#108` `LASM_Differential_Assembler_Oracle`: byte-for-byte differential verification of Lume's native `lasm` assembler scalar x86-64, AVX2 VEX `0xC5`/`0xC4`, and AVX-512 EVEX `0x62` compressed `disp8*N` & `disp32` against GNU `/usr/bin/as` + `objcopy -O binary`),
    `prover_adversarial_false_theorem_rejected` & `prover_unsound_acceptance_rejected_law` (Domain `#109` `Adversarial_Prover_False_Theorem_Fuzzer`: deterministic PRNG & 25+ adversarial false-theorem families across `QF_LIA`, negative modulo, bit-shifts, wrapping `+%`/`-%`/`*%`, non-linear `x*x`, and shadowed quantifiers under `let`, proving 0 false positives accepted across `lumec` and `lcaas`),
    `mutation_testing_kill_ratio_verified` & `mutation_surviving_mutant_rejected_law` (Domain `#110` `Gate_Mutation_Testing_Kill_Verifier`: active semantic mutation-kill harness injecting contract, ownership, `@secret`, `/ pure`, SIMD register, C header `void*`, and ISO boot-sector mutants and verifying a 100% mutation kill ratio),
    and `ddc_diverse_double_compilation_bit_identical` & `ddc_bootstrap_divergence_rejected_law` (Domain `#111` `Wheeler_Diverse_Double_Compilation_DDC`: David A. Wheeler's Diverse Double-Compilation verifying that `GCC -> lume0 -> stage1 -> stage2` produces a bit-for-bit identical compiler binary to the self-hosted `lumec -> stage3` chain).
- **NetSentinel IEC 62443, Conduite HA & Sovereign Mesh/Raft/DHT/TOFU (`lume net-sentinel` / `lume iec62443` / `lume conduite` / `lume omega-mesh` in `std.net`, `68/68` `QF_LIA` & WCET obligations, `15/15` tests):**
  - **Purdue Model (`L0..L4`) & DMZ (`L3.5`) Conduit Guard:** `iec62443_purdue_conduit_ok`
    enforces strict zone-conduit traversal and forbids direct enterprise-to-control bridging.
  - **OT Firewall Policy Audit & Structural Read-Only DCS Guard:** `netsentinel_fw_policy_audit_ok`
    verifies default-drop rules, and `ot_readonly_dcs_guard` structurally rejects any write
    mask (`CurrentWrite` / `HistoryWrite`) or Purdue level `< 3`.
  - **Tri-State Telemetry Quality & Finite `1e12` Sentinel:** `ot_tristate_quality_code`
    classifies `Good`/`Uncertain`/`Bad` samples without synthetic interpolation, and
    `ot_finite_sentinel_clamp` clamps out-of-range telemetry to `+/- 10^12`.
  - **Conduite HA ACL Parity, GOOSE Anti-Replay & Posture-Traffic Correlator (Wave 3):**
    `conduit_admin_timeout_ok` (rejects infinite `<= 0` and `> 15` min), `conduit_ha_failover_parity_ok`
    (order-sensitive ACL digest + `hold >= 3 * hello`), `conduit_severity_escalate_rank`,
    `ot_goose_state_transition_code`, `netsentinel_posture_traffic_confirmed`, and
    `netsentinel_broadcast_storm_code`.
  - **Sovereign Mesh Framing, Atomic NAT Dual TokenBucket, Kademlia Tiered DHT, Raft & TOFU (Wave 3):**
    `mesh_frame_bounds_ok`, `mesh_atomic_dual_rate_deduct` (zero token leak under shared NAT),
    `mesh_dht_healing_rank` (`Hub < Relay < Agent`), `mesh_raft_quorum_ok` & `mesh_raft_backtrack_index`,
    `mesh_tofu_verify_code`, and `mesh_channel_mux_quota_ok`.

## 6.3 All 8 Sovereign & Brazilian Verified Capstones (`examples/apps/`)
- `pix_fraud_trace` (`9/9` `QF_LIA` proofs): Real-time Pix graph taint & fraud trace engine.
- `sentry_uav_guard` (`9/9` `QF_LIA` proofs): Autonomous UAV geofence, battery & attitude safety guard.
- `verified_accounting` (`7/7` `QF_LIA` proofs): Double-entry ledger conservation & audit trail.
- `dfe_pix_bacen` (`11/11` `QF_LIA` proofs): SEFAZ NF-e/NFC-e Modulo-11 DV, ICMS/DIFAL & BACEN Pix EMV CRC-16.
- `omniroute_guard` (`8/8` `QF_LIA` proofs): Quota-aware multi-provider LLM & payment failover router.
- `brasil_public_id` (`9/9` `QF_LIA` proofs): CPF, PIS/PASEP, Titulo Eleitoral & RFB/SERPRO July 2026 Alphanumeric CNPJ (`ord(ch) - 48`).
- `zero_breach_forensics` (`8/8` `QF_LIA` proofs): Pegasus/Predator/Candiru forensic scanner & STIX 2.1 IOC verifier.
- `sovereign_llm_router` (`20/20` `QF_LIA` proofs): 1-Bit/Ternary MAC, `LFM3` LiquidCodec 24 kHz audio, `Colibri` MoE SSD guard & 3-tier hybrid router.

## 6.4 IDE Integrations (`editors/`)
- `editors/vscode-lume/`: VS Code extension (`extension.js` + `lsp_bridge.src` with `7/7` `QF_LIA` proofs)
  providing real-time diagnostics, `QF_LIA` proof code lenses, and hover obligations.
- `editors/openidea-lume/plugin.toml`: OpenIDEA / JetBrains sovereign Lume language plugin manifest.

# CHAPTER 7: 27 UNIVERSAL TARGETS, LUMEMIR SSA & STORE PACKAGERS

## 7.1 Native OS, Windows GUI, Mobile, Web, Bare-Metal & Exotic Targets (`lume build --target <t>`)
- Desktop/Server: `x86_64-linux-elf`, `aarch64-linux-elf`, `riscv64-linux-elf`,
                  `x86_64-windows-pe` (native `kernel32.dll` IAT), `aarch64-macos-macho`
- Windows Native GUI: `x86_64-windows-gui` and `x86_64-windows-gui-protected` (`PE32+` Win32 GUI
                  with `KERNEL32.dll`, `USER32.dll`, `GDI32.dll`, `COMDLG32.dll`, `SHELL32.dll` IAT,
                  declarative `@ui-layout` 4-pane lowering with `WS_THICKFRAME` + `LBS_NOTIFY | LBS_HASSTRINGS`
                  styles `1412694337` / `0x54340141` & `1412698308` / `0x543410C4`, `ui_split_conservation_law`,
                  `--protect max` P33 Anti-REA `XOR 0xB2 = 178`, `PYXH` MBA prologue, and `.lsym` vault)
- Mobile/Store:   `aarch64-android-elf`, `aarch64-ios-macho`
- Bare-Metal/OS:  `x86_64-uefi-pe`, `x86_64-none-raw`, `x86_64-none-mbr`, `x86_64-none-ihex`
- Web/Bytecode:   `wasm32-wasi` (with `@wasm-sandbox` `[I0275]`), `lumb`
- GPU/Accelerators: `nvptx64-nvidia-cuda` (PTX 8.0), `spirv64-vulkan-compute` (SPIR-V 1.6)
- Silicon/Hardware: `verilog-rtl` (IEEE 1364), `vhdl-rtl` (IEEE 1076)
- Quantum & Bio:  `qasm3-quantum` (OpenQASM 3.0), `dna-quaternary` (`A,C,G,T` codec)
- In-Weights Neural VM & NPU: `lumeputer-rv32im-weights` (aliases `lumeputer`, `lumepu`, `qwenputer`,
                  `rv32im-weights` — compiles `.src` directly into a 13-layer `RV32IM_Zba + BMAC + VX VMAT`
                  weight-compiled neural processor manifest with Ballast `B = 10000` and Gated-DeltaNet RAM)

## 7.2 Store/Boot Packagers, LumeMIR, Target Subset Classification & Tail-Recursive Codegen
- `lasm.src` & `ltarget.src` use 100% tail-recursive accumulators (`rev_append` / `lt_lines_acc`)
  for unbounded multi-megabyte sources without stack overflow, and `lume targets --json`
  reports explicit `subset` classifications (`"full-core"`, `"pe64-gui-template"`,
  `"verified-core-subset"`).
- `lume mir <target> <source.src>`                  Inspect target-independent SSA `LumeMIR`.
- `lume package apk|ipa|iso|uefi <src> -o <out>`    Build store/bootable images in one command.
- `lume neural-kernel [--json] <source.src>`        Synthesize PTX + SPIR-V + Verilog + VHDL
                                                    with 3-way hardware equivalence proof.

# CHAPTER 8: COMPLETE CLI COMMAND REFERENCE (PHASES 1-5 & WAVES 1-10)

## 8.1 Core Toolchain & Developer Commands
  lume build [--incremental] [--memory] [--protect [hardened|max]] [--target <t>] <src> [-o <out>]
  lume run [--memory] <src> [args...]    Compile and run source immediately
  lume test <src.src>...                 Run all `fn test_*()` unit tests
  lume check <src.src> [--json]          Typecheck, borrow-check, and effect-check
  lume fmt <src.src> [--check|--stdout]  Canonical code formatter
  lume doc <src.src> [--json]            Generate module documentation & run doctests
  lume repl [--kernel|--json]            Interactive Read-Eval-Prove-Print Loop (`--kernel`: Jupyter kernel protocol)
  lume lsp / lume dap                    Language Server & Debug Adapter Protocol
  lume pkg init|check|lock|verify|tree   Content-addressed package manager
  lume registry publish|resolve|discover Verified component registry

## 8.2 Formal Verification, AI Agent & Evolution Commands (Waves 1-8)
  lume prove [--diff|--share] <src.src>  Run `QF_LIA` / Separation Logic theorem prover
  lume certify <src.src>                 Emit a standalone proof certificate (JSON on stdout)
  lume verify-cert <certificate.json>    Verify a certificate with the minimal proof kernel
  lume agent <skeleton|cegis|prove> <f>  Compiler-as-Oracle AI synthesis
  lume patch-fn <src> <fn_name> <patch>  AST surgical single-function hot-patcher
  lume trace <src.src>                   Structured JSON execution trace
  lume diff-semver <old.src> <new.src>   Mathematical SemVer bump analyzer
  lume symbolize <file.lsym> <query>     P33 obfuscated symbol/address resolver
  lume capsule seal|replay <file>        Tamper-evident execution capsule V2
  lume pack / lume unpack <in> -o <out>  LZ1 atomic cold-arena & capsule block compressor
  lume genesis <app_name> [domain]       Full-stack + 8-target autonomous app synthesizer
  lume heal <src.src>                    Counterexample-driven contract self-healer
  lume equiv <spec.src> <fast.src>       Formal algorithmic equivalence prover
  lume adapt <c|rust|python|js|go|java|dotnet|sql|openapi> [file] Generate `[I0003]` fail-closed polyglot FFI adapters
  lume morph <file>                      Transmute legacy SQL/Python/C/OpenAPI to proven Lume (`lume morph <legacy_file>`)
  lume neural-kernel <src.src>           GPU/NPU/FPGA RTL differentiable synthesizer
  lume evolve list|goals|budgets|propose|verify|apply|grow|approve [id|dir|bundle] Cryptographically governed self-evolution

## 8.3 Wave 9 & Wave 10 Sovereign Commands
  lume morph-ast <src>     AST E-Graph equality saturation
  lume awaken <src>        Metacognitive active-inference self-model (Phi & Free Energy)
  lume quantum <src>       OpenQASM 3.0 + Bell entanglement & Grover statevector oracle
  lume bio-dna <src>       Quaternary DNA (A,C,G,T) storage encoder/decoder
  lume cosmic-tmr <src>    3-lane Triple-Modular Redundancy cosmic-ray SEU voter
  lume hologram <src>      128-bit Hyperdimensional Computing associative memory
  lume chronos <src>       Omniscient reverse-time causal debugger
  lume omega-net <src>     Infinite-depth DEQ + Liquid Neural ODE + 64-expert MoE
  lume llm-forge <src>     Sovereign LLM builder (BPE, RoPE, GQA, SwiGLU, AdamW, DPO)
  lume consult [src]       Living self-consultation & evolutionary agenda
  lume laws / memory       8 Constitutional Laws + 4-vault indestructible episodic memory
  lume replicate / hive / daemon-triad / hot-evolve / live-cockpit Triad swarm self-replication & zero-downtime hot-swap
    - `lume daemon-triad [src]`: Always-on P2P sub-100ms swarm gossip sentinel across Primary PC + Dell G3 + Acer
    - `lume hot-evolve [src]`:   Zero-downtime autonomous E-Graph self-recompilation & atomic binary hot-swap
    - `lume live-cockpit [src]`: Real-time continuous 22050 Hz voice + DEQ vision + network/Ring-0 telemetry loop
  lume ui-layout [src]     Declarative `@ui-layout` 4-pane Win64 PE32+ (`1412694337` / `1412698308`) & Web/WASM lowering (`ui_split_conservation_law`)
  lume reversa / reverse-engineer / reveng / decompile <target> Unified binary & 7-phase SDD reverse engineering
  lume pingora / proxy / cdn / load-balancer [target] Pingora-Lume Edge Proxy (TinyUFO, Ketama+P2C, TLS 1.3, 7-phase ProxyHttp)
  lume egm / elephant-goldfish / goldfish-review / drift-report / heilmeier [target] EGM-Lume Spec-Driven Development & Drift Engine
  lume ncm / next-concept / ncm-quantize / ncm-generate / ncm-solve [target] NCM-Lume Next-Concept Modeling Coarse-to-Fine Parallel Engine
  lume opentpu / tpu / otpu-asm / k-smooth / stream-se / tpu-scoreboard [target] OpenTPU-Lume Systolic AI Accelerator & ISA Engine
  lume continuum / nexus / billion-context / acp / ecc-shield / bend-laws / ai-memory / notebook / doory [target] Lume Continuum Nexus v1.0 (7 Reference Engines)
  lume quantum-nexus / quantum-zx / quantum-stabilizer / quantum-qec / quantum-vqe / quantum-uncompute / silq / quizx / stim [target] Lume Quantum Nexus v1.0 (Silq qfree, QuiZX, Stim, Surface Code QEC, Catalyst VQE)
  lume chameleon|camaleao|polyglot|ffi-bridge [target_or_file] (or `lume chameleon`) Universal Chameleon Polyglot Interop Engine across 9 ecosystems (`c_abi`, `rust_cdylib`, `python_capi`, `node_napi_wasm`, `go_cshared`, `java_jni`, `dotnet_pinvoke`, `sql_relational`, `openapi_rpc`)
  lume unified-field|ufe|subsea [target]             Unified Field & Subsea/Offshore Engine in `std.gfx` (`ufe_dls_lambda_sq_milli`..`ufe_latency_shedder_step`, `subsea_catenary_top_tension_n`, `subsea_viv_screening_ok`, `subsea_miner_fatigue_safe_ok`, `marine_dnv_daf_floor_milli`, `marine_heavy_lift_feasible_ok`, `subsea_hyperbaric_decompression_safe_ok`, `subsea_well_kill_icp_kpa`, `subsea_b31g_corroded_pipe_safe_ok`)
  lume singularity|ote|transition-engine [target]    2nd-Order Dynamical Transition Engine, Singularity Boundary Omega & Bayes-SPC/CPM/k-Anonymity in `lchameleon.src` (`ote_select_damping_regime`..`ote_diagnose_primary_code`, `spc_beta_binomial_posterior_num`, `spc_cusum_upper_step_milli`, `ops_cpm_total_float_hours`, `analytics_k_anonymity_release_ok`, `analytics_pava_monotonic_pair_hi`)
  lume net-sentinel|iec62443|conduite|omega-mesh [t] NetSentinel IEC 62443, Conduite HA & Sovereign Mesh/Raft/DHT/TOFU in `std.net` (`iec62443_purdue_conduit_ok`..`ot_finite_sentinel_clamp`, `conduit_admin_timeout_ok`, `conduit_ha_failover_parity_ok`, `ot_goose_state_transition_code`, `netsentinel_posture_traffic_confirmed`, `mesh_atomic_dual_rate_deduct`, `mesh_dht_healing_rank`, `mesh_raft_quorum_ok`, `mesh_tofu_verify_code`, `mesh_channel_mux_quota_ok`)
  lume lumeputer|lumepu|qwenputer [target]           LumePuter & LumePU Weight-Compiled `RV32IM_Zba` + Bignum + Vector/Matrix NPU (`VDOT`/`SMAQA`/`VX VMAT`) & Zero-Drift Gated-DeltaNet RAM Engine in `lchameleon.src` (`lumeputer_swiglu_exact_relu_unit`..`lumeputer_compile_rv32_vx_to_weights_layers`)
  lume run compiler/stage1/lume_llm_core.src         Sovereign 1-Bit/Ternary LLM Core, Liquid LFM3 Audio, Colibri MoE Guard & 3-Tier Router (`21/21` proofs)
  lume run examples/apps/sovereign_llm_router/main.src Sovereign Edge/Local/Cloud LLM Router & Anti-Hallucination Price Oracle (`20/20` proofs)
  lume os-control / bios-core / web-research / crypto-engine
  lume sensory-cortex / multimodal / file-indexer / interface / self-build
  lume wireshark / switch-fabric / scada-ics / modbus / dnp3 / iec104 / iec61850
  lume gfx / render-3d / scada-hmi / ied-protection / recall / synapse / orchestrate

### Wave 11 Certification Commands (Domains `#112..#115`)
  lume tv <src.src> [--fn <f>] [--exec]      Translation validation (`ltv`): per function, the lowered AST against the x86-64 text `lumec` emitted
  lume mcdc <src.src> [--fn <f>] [--exec]    Decision + masking MC/DC obligations (`lmcdc`); every witness is run on the real binary
  lume safety-envelope <kernel.src> --fn <f> --args <a,b,..> [--args ..] [--budget n] [--reset]
                                             2oo2 lockstep: native x86-64 (channel A) against the LumePuter RV32IM monitor (channel B)
  lume safety-envelope --gate                Fault-injection gate of the envelope (bit flips, RAM/register/ROM upsets, WCET, certificate)
  lume lumeputer exec <kernel.src> --fn <f> --args <a,b,..>   Run a kernel on the LumePuter RV32IM monitor alone (no vote, no commit)
  lume tv-gate [--stride n]                  Codegen mutation gate: `ltv` must reject every behaviour-changing assembly mutant
  lume soak [--rounds n] [--procs n]         Soak battle: collector stress, OS fault injection, concurrent determinism, hash-chained ledger
  lume prover-fuzz [--n k] [--seed s]        False-theorem fuzzer against `lumec`, `lcaas` and the `lcert` kernel
  lume qualify [--quick]                     Tool qualification battery; writes TOR, TQP, RTM, evidence and dossier to `build/certification/`

- **`ltv` (Domain `#112`)** symbolically executes the AST and the emitted assembly of each integer function and
  accepts only when, for every valuation of the branch atoms, both reach `ctfail` in the same cases with the same
  message, otherwise return the same value in `%rax`, perform the same divisions / modulos / calls, and keep the
  frame discipline (`%rsp`/`%rbp` restored, no write outside the frame). The machine model is the real one: tagged
  63-bit integers, fast paths guarded by `jo`/`jno`, runtime helpers as stated axioms. Anything it cannot derive is
  a rejection. Limits: integer fragment only (others are `unsupported`, never `validated`); the theorem is over the
  integers (executions without an i64 overflow trap); the SMT-LIB2 and Lean 4 certificates in
  `build/certification/proofs/` are checked only when `z3`/`cvc5`/`lean` are installed (`external_solver`,
  `lean_checked` in the report say which).
- **`lmcdc` (Domain `#114`)** lists the decisions of the lowered AST (`requires`, runtime-checked `ensures`, `if`
  conditions, Boolean values), searches witness vectors and runs each on the real binary. An obligation without a
  witness is reported as `theorem_false` (false outcome of a proven law or checked ensures), `infeasible` (proved
  contradictory by the `lcert` kernel: a redundant clause or dead branch, listed for review) or `uncovered`.
- **`lsafety_envelope` (Domain `#115`)** releases `VerifiedActuatorCommit(value)` only when channel A finished inside
  its watchdog, channel B halted inside the cycle budget (`@bound(cycles: N)` x 16, or `--budget`) without a trap,
  `ltv` validated the kernel, and the two words are equal. Every other case latches `SAFE_STATE_TRIP` in the
  hash-chained log `build/certification/safety_envelope_events.jsonl` until `--reset`. Real level: channel B is a
  software RV32IM interpreter on the same host (design diversity, not physical independence); the front end is
  common to both channels; the monitor domain is i32 (a kernel that leaves it trips).
- **`lume qualify` (Domain `#114`)** runs 70 probes, the module batteries (ltv, lmcdc, proof status) and 16 gates,
  checks the bidirectional traceability matrix (every requirement needs a parent, an existing source file, a passing
  positive test, a passing negative test and a passing mutation gate or proof) and writes the dossier. It is the
  developer's evidence package for DO-330 TQL-1 / DO-178C DAL A / IEC 61508 T3 / IEC 62304 class C work, **not a
  qualification**: that is granted per project by the authority or assessor and needs independent verification.
- **Soak ledger (Domain `#113`)**: `build/certification/battle_telemetry_ledger.json` accumulates the campaigns of
  `lume soak`; each entry carries the hash of the previous one and the gate re-verifies the chain before appending.

### Wave 12 Industrial Commands (Domains `#116..#121`) and the Wave 13 Closure
  lume build --dwarf|-g <src.src> [-o <out>]             DWARF v4 line table and symbols (`.debug_line`, `.debug_info`, `.debug_abbrev`, `.symtab`, `.strtab`)
  lume build --keep-proven-checks|--critical <src.src>   Keep the run-time check of every proven `ensures` (defence in depth)
  lume build --target aarch64-linux-gnu|aarch64-elf|riscv64-linux-gnu|riscv64-none-elf|riscv64-none-bin|riscv32-none-elf|riscv32-none-bin <kernel.src> -o <out>
                                                         Certified integer-kernel back ends (`larm64`, `lriscv`), `lumec` front end first
  lume build --target safetensors [--entry <fn>] <src.src> -o <out.safetensors>   Neural cartridge of a `/ pure` integer function
  lume proof-cache <check|store> <src.src> [<cache_dir>] [--require-all-hits]      Incremental per-function proof cache (`lproof_cache`)
  lume verify-cert --check-source <src.src> <cert.json>  Certificate kernel with the source-to-obligation binding check
  lume qualify --verify                                  Re-check the hash chain and the Ed25519 signature of `build/certification/`
  lume realtime-gate | concurrency-gate | crypto-gate | multi-arch-gate | safetensors-gate | dwarf-cache-gate | cert-source-gate
                                                         The acceptance gates of the features below

- **`@no_alloc` (Domain `#116`, `[E0210]`)**: the function and every function it calls (the check is transitive)
  must be unable to reach a heap allocation: `int`/`bool` parameters with proven bounds, `+ - *` proven inside the
  63-bit immediate range, no record, constructor with fields, string or allocating builtin, recursion in tail
  position only. `realtime_gate` measures the result with `heap_stats()`: zero allocations over the accepted
  kernels. Limits: no worst-case stack depth in bytes is computed and nothing is timed; `@bound` is the cycle budget.
- **Constant-time kernels (`@secret` + `@no_alloc`, `[C0011]`)**: a function that carries both attributes is lowered
  to straight-line code on immediate integers: no tag test, no overflow test, no runtime call, no jump. `[C0011]`
  rejects everything else: parameters and result are `int`; no `requires` (mask with `bit_and`; the kernel is total
  over immediates); an `ensures` only when it is proven (it is never checked at run time, also under
  `--keep-proven-checks`); the body uses `+ - * +% -% *%`, `bit_and` / `bit_or` / `bit_xor` / `bit_not`, `bit_shl` /
  `bit_shr` by an integer literal, `ct_select`, `ct_eq` and calls of other kernels; no `if`, `match`, comparison,
  `and` / `or`, `/`, `%`, recursion. Every arithmetic result must be proven inside the 63-bit immediate range for
  all immediate arguments (`[E0210]`). An entry guard faults when an argument is not an immediate. `ltv` re-derives
  the ranges itself and validates the machine code; `tv_gate` mutates it. Limits: "constant time" is the absence of
  secret-dependent branches, divisions and memory accesses in the instruction sequence; no timing is measured.
- **Multi-ISA kernel back ends (Domain `#117`)**: `larm64.src` and `lriscv.src` compile the integer kernel fragment
  (`int` functions, `+ - * / %`, comparisons, `and`/`or`, `if`, `let`, calls, `print`) to AArch64, RV64 and RV32
  images; `ltv_multiarch.src` validates every function image against the source. No image is released before the
  `lumec` front end accepted the same source (`[T0902]` with its diagnostic, `[T0903]` when `lumec` is missing); a
  source outside the fragment is `[T0901]`. Real level: executed on `qemu-aarch64`, `qemu-riscv64` and the LumePuter
  interpreter, not on silicon.
- **Linear concurrency (Domain `#118`)**: a value sent with `chan_send_linear` cannot be used again (`[E0305]`);
  `lock_acquire` out of rank order, an unreleased lock or a cycle of `actor_link` edges is rejected (`[E0306]`).
- **Cryptography and TLS 1.3 (Domain `#119`, `use lcrypto_tls`)**: SHA-256/512, HMAC, HKDF, ChaCha20-Poly1305,
  Ed25519, X25519, the TLS 1.3 key schedule, record layer and handshake state machine, all in Lume and checked
  against the official vectors by `crypto_tls_gate`. `ltv` adds `[C0010]`: the emitted code of a `@secret` function
  may hold no conditional branch, division or memory access outside its frame, and neither may any routine it
  reaches by `call` (the scan is transitive and names the call chain). Limits: tested, not formally
  verified; a plain `@secret` function that uses `+` or a bit operation is rejected by `[C0010]` (its helpers
  branch): write it as a constant-time kernel; no X.509 path validation.
- **Incremental proof cache (Domain `#120`)**: one sealed record per function, keyed by the SHA-256 of its body,
  contracts, callee interfaces and prover version. A tampered record is refused (`[PC0002]`), a module the prover
  refutes is never stored (`[PC0003]`), `--require-all-hits` turns a miss into an error (`[PC0005]`).
- **Neural cartridges (Domain `#121`)**: a `/ pure` integer function compiled to RV32IM words inside a
  `.safetensors` file with the integer weights of one SwiGLU block; the forward pass over the weights of the file
  must equal the native program and the LumePuter run. It is integer matrix arithmetic evaluated by this tool
  chain, not a claim about a floating-point inference engine.
- **Certificate binding (`lcert --check-source`)**: besides re-deriving every proof term, the kernel reads the
  contracts of the source itself and refuses a certificate whose obligations are not the obligations of that file.
- **Signed evidence**: `lume qualify` chains the sections of `QUALIFICATION_EVIDENCE.json` with SHA-256 and writes a
  detached Ed25519 signature (`QUALIFICATION_EVIDENCE.sig.json`). The key is a developer key kept in a file on the
  host (`/root/.lume/keys/qualification_ed25519.seed` or `--sign-key`): it shows who produced the file, it is not an
  independent attestation.

## 8.4 Universal Module Orchestrator (`LumeSynapse`) & Proactive Memory
- `lume synapse <file.src>` (or `lume orchestrate <file.src>`): Coordinates all Lume
  organs (`lmod`, `lumec`, `lasm`, `lcaas`, `lcert`, `ltest`, `lprotect`, `lsentience`)
  via the real-time shared blackboard (`synapse_bus.json`), performing Cross-Organ
  Omni-Warming (`prove -> check`, `certify -> prove + check`) and Compiler <-> Auto-Heal
  Synaptic Reflex (`synapse_last_diagnostic.json`).
- `lume recall <file.src>`: Queries the O(1) content-addressed proactive memory cache
  protected by `.sha256` cryptographic anti-tamper seals (up to 91x faster proofs and
  20x faster builds).
- `lume self-prove` (or `lume prove-all` / `lume verify-all` / `lume self prove`): Runs
  the proof batteries (`LumeCompiler-Embedded-OmniProof-v4`; every count in the JSON is measured by the run) inside
  the compiled Lume driver with zero external scripts (`std.net`, `std.gfx`,
  `lume_crypto_blockchain_engine`, `lume_reversa_engine`, `lume_pingora_proxy_engine`,
  `lume_egm_engine`, `lume_ncm_engine`, `lume_opentpu_engine`, `lume_continuum_nexus_engine`,
  `lume_quantum_nexus_engine`, `lchameleon`, `lsentience`, `lmanual`, `KerneLume` Bare-Metal OS,
  `[K0005]`/`[K0006]`/`[C0009]`/SRA guards, and `MANIFEST.sha256`: 700 formal obligations +
  162 unit tests + 99 verified toolchain artifacts + 112 autonomous domains + 17 LumePuter modules).

# CHAPTER 9: 6 COPY-PASTE WORKING EXAMPLES FOR HUMANS & AI

## Example 1: Recursion, ADTs & Pattern Matching (`list_demo.src`)
```lume
fn map_double(xs) = match xs
    Nil        => Nil
    Cons(h, t) => Cons(h * 2, map_double(t))

fn sum_all(xs) = match xs
    Nil        => 0
    Cons(h, t) => h + sum_all(t)

fn test_double_sum() = sum_all(map_double(Cons(3, Cons(7, Nil)))) == 20
print str(sum_all(map_double(Cons(10, Cons(20, Nil)))))
```

## Example 2: Formal Verification with `requires`, `ensures` & `law` (`bank_proof.src`)
```lume
fn safe_transfer(sender: int, receiver: int, amount: int) -> int
  requires sender >= amount and amount >= 0 and receiver >= 0
  ensures result == sender + receiver
= (sender - amount) + (receiver + amount)

law transfer_conserves_total(s: int, r: int, a: int) = ((s - a) + (r + a)) == (s + r)
print str(safe_transfer(500, 200, 150))
```

## Example 3: File I/O, SHA-256 & Dictionary Map (`hash_kv.src`)
```lume
use fs_sha256_file
use map

fn run_demo() =
    let m0 = map_new() in
    let m1 = map_put(m0, "creator", lc_sha256("Ricardo Bueno")) in
    map_get_or(m1, "creator", "missing")

print run_demo()
```

## Example 4: B+Tree ACID Database & SQL Query (`db_demo.src`)
```lume
use db

fn run_db() =
    let d0 = db_open(2) in
    let tx = db_put(db_begin_tx(d0), 1, 100, 1) in
    let d1 = db_commit_tx(tx) in
    db_read(d1, 1, 0)

print str(run_db())
```

## Example 5: Cryptographic Custody, PoW Mining & DeFi AMM (`crypto_demo.src`)
```lume
use lume_crypto_blockchain_engine

fn crypto_sha256_rounds(msg: str) = crypto_hmac_sha256("lume-key", msg)
print crypto_sha256_rounds("block-0")
```

## Example 6: Freestanding Hardware / Kernel Entry (`kernel_demo.src`)
```lume
@bound(cycles: 128)
fn rtc_bcd_to_bin(bcd: int) -> int
  requires bcd >= 0 and bcd <= 153
  ensures result >= 0
= ((bcd / 16) * 10) + (bcd % 16)

print str(rtc_bcd_to_bin(35))
```

## Example 7: Universal Chameleon Polyglot Interop (`chameleon_demo.src`)
```lume
use lchameleon

fn run_chameleon_demo() =
    let ok = chameleon_verify_boundary(1, 1, 1, 64, 4096) in
    let r = chameleon_adapt_ecosystem("rust") in
    str(ok) + ":" + r.id

print run_chameleon_demo()
```

## Example 8: LumePuter & LumePU In-Weights Neural VM & NPU (`lumeputer_demo.src`)
```lume
use lchameleon

fn run_lumeputer_demo() =
    let relu_val = lumeputer_swiglu_exact_relu_unit(42, 1, 20) in
    let ram_cell = lumeputer_deltanet_ram_step_exact(99, 777, 1) in
    let vx_mac = lumepu_vx_vmat_row_mac_exact(10, 4, 8, 64) in
    let layers = lumeputer_compile_rv32_vx_to_weights_layers(64, 1, 1) in
    str(relu_val) + ":" + str(ram_cell) + ":" + str(vx_mac) + ":" + str(layers)

print run_lumeputer_demo()
```

# CHAPTER 10: COMPILER DIAGNOSTIC CODES & HOW TO FIX THEM

| Code      | Category             | Meaning & How to Fix |
|-----------|----------------------|----------------------|
| `[P0002]` | Parser / Syntax      | Unexpected token or nested unbraced `match`. Move `match` to top-level helper `fn f(x) = match x ...` or wrap in braces `match x { ... }`, and verify pure LF (`\n`) line endings. |
| `[R0200]` | Name Resolution      | Call to undefined function or variable. Check spelling or add `use <module>` at top of file. |
| `[R0201]` | Name Resolution      | A function reuses the name of a runtime routine (`count`, `at`, ...) or a prefix reserved for it (`__rt_`, `__gc_`, `__lume_`, `__c_`, `__k_`, `__r_`, `__isr_`, `__cpu_`, `__krn_`, `__net_`). Rename it. |
| `[T0300]` | Tensor Shape         | Tensor shape mismatch: an argument dimension differs from the parameter's, or the branches of an `if` disagree. Reshape the tensor. |
| `[T2001]` | Type Check           | An operator applied to incompatible types (`int + str`, `money[BRL] + money[USD]`). Convert both operands to the same type. |
| `[T2002]` | Type Check           | A function returns a type other than the one it declares. Fix the body or the declared return type. |
| `[E0200]` | Algebraic Effects    | Impure operation (`io`, `fs`, `net`, `arena_new`, `embed`) called inside a `/ pure` function. Remove `/ pure` or add the required effect to the function signature. |
| `[O0001]` | Ownership / Borrow   | Use-after-move, double-close of file handle, or conflicting mutable borrow (`mut`). Clone or restructure ownership scope. |
| `[V0001]` | Contract / Law Proof | `requires`/`ensures` contract or `law` refuted by `QF_LIA` solver. Inspect the printed counterexample or run `lume heal <file.src>`. |
| `[V0002]` | WCET Cycle Bound     | Function exceeds `@bound(cycles: N)` budget or uses unbounded recursion in `@interrupt`. |
| `[I0003]` | Polyglot / C Interop | Unsafe or unsupported foreign declaration in `lume adapt c` or `lchameleon` (`unverified[T] -> verified[T]`). Add explicit `QF_LIA` bounds or `@repr(c)`. |
| `[I0275]` | WASM Sandbox         | A WebAssembly module handed to the capability sandbox imports an ungranted host capability (`path_open`, `sock_*`), declares memory outside `1..16` pages, or is malformed. |
| `[C0271]` | Comptime Embed       | `comptime embed("...")`: the path is not a string, is empty, contains `..`, or names a missing file. |
| `[D0273]` | Table Schema         | `comptime table_schema(T)`: `T` is not a nominal record type, or a column has an unsupported type or an invalid money currency. |
| `[K0005]` | Bare-Metal W^X / DMA | `mmio_volatile_write*`, `mem_copy`, or `mem_set` targets `.text`/`.rodata` (`[0x8000..0x3FFFF]`), including symbolic/affine `base + off`. Use a safe DMA RAM buffer (`>= 0x40000`). |
| `[K0006]` | Kernel Stack Safety  | Unbounded mutual recursion cycle (`f -> g -> f`) in `@freestanding` / `kernel_boot_entry` module. Use tail-loop state or bounded iteration. |
| `[C0009]` | Constant-Time Crypto | Secret-dependent `if`/`match` branch, variable-latency `/` or `%`, short-circuit `and`/`or`, or secret-indexed memory lookup on `secret_*` or inside `ct_*`. Use bitwise XOR/OR mask accumulation. |
| `[C0010]` | Machine Constant-Time | `lume tv`: the emitted code of a `@secret fn`, or of a routine it reaches by `call`, holds a conditional branch, a division or a memory access outside frame and stack. Write the function as a constant-time kernel (`@secret` + `@no_alloc`). |
| `[C0011]` | Constant-Time Kernel | A `@secret` + `@no_alloc` function has a `requires`, an unproven `ensures`, a conditional, comparison, `/` or `%`, a shift by a non-literal, recursion, a non-`int` type or a call of a function that is not a kernel. Use masks, `ct_select(mask, a, b)` and `ct_eq(a, b)`. |
| `[L0001]` | Lexer / Assembler    | Unterminated string literal in a source file (close it with a double quote); `lasm` uses the same code for an instruction or directive it does not know. |
| `[L0010]` | Link                 | A symbol is defined twice in one image, which would otherwise send calls to the wrong routine. |
| `[L0002]` | String Escape        | Unknown escape sequence in string literal (valid escapes: `\n`, `\r`, `\t`, `\b`, `\f`, `\0`, `\'`, `\"`, `\\`, `\{`, `\}`, `\$`). |
| `[W0002]` | P33 Secret Scanner   | Hardcoded private key/token detected before binary emission; move secrets out of source. |

# APPENDIX A: SYNOPSIS OF EVERY COMMAND

Generated by the native driver from the table it dispatches on: a command, subcommand or option that is not
listed here is refused (`unknown native driver command`, `unknown subcommand`, `unknown option`).
`[--x <value>]` takes a value (`--x v` or `--x=v`). `lume <command> --help` prints the line of one command and
`lume help --json` prints the whole table as JSON.

  lume --version|version
  lume --help|-h|help [--json] [--pt] [--pt-br] [--pt-BR] [--pt_br] [--pt_BR] [--en] [--en-us] [--en-US] [--export <value>] [chapter] (values: pt|pt-BR|pt-br|pt_BR|pt_br|en|en-US|en-us)
  lume manual|man|guide|manual-pt|man-pt|guia [--json] [--pt] [--pt-br] [--pt-BR] [--pt_br] [--pt_BR] [--en] [--en-us] [--en-US] [--export <value>] [chapter] (values: pt|pt-BR|pt-br|pt_BR|pt_br|en|en-US|en-us)
  lume describe|--describe [--json]
  lume targets|--targets [--json]
  lume build [-o <value>] [--target <value>] [--incremental] [--memory] [--protect] [--profile <value>] [--lsym <value>] [--link <value>] [-l <value>] [-l<value>] [--emit-c-header <value>] [--build-timeout-ms <value>] [--dwarf] [-g] [--keep-proven-checks] [--critical] [--entry <value>] <source.src> (values: none|standard|hardened|max|debug|release|ship)
  lume run [--memory] <source.src> [program-arguments]
  lume test <source.src>...
  lume check [--json] <source.src>
  lume compile [--json] [--run] <source.src>
  lume fmt [--check] [--stdout] <source.src>...
  lume doc [--json] <source.src>
  lume prove [--json] [--diff] [--share] [--compositional] <source.src> [new.src]
  lume certify [--json] <source.src>
  lume verify-cert [--json] [--check-source] [source.src] <certificate.json>
  lume proof-cache <self-test|check|store> [--require-all-hits] [source.src] [cache-dir]
  lume pkg <init|check|manifest|lock|verify|tree|check-rot> [dir]
  lume pkg <publish|audit> (served by the POSIX shim, scripts/lume_legacy.sh)
  lume registry <publish|resolve|discover> [--json] [--store <value>] [--target <value>] [--adapter <value>] [--source <value>] [--proof <value>] [--tests <value>] [--cid <value>] [--capability <value>] [--contract-signature <value>]
  lume agent <check|compile|fill|prove|ast|expand|symbols|eval|witness|repair|impact|hashes|grammar|project|bind|skeleton|cegis|synthesize|trace|heal|morph|kernel|c-export|replay|lineage|patch|patch-fn|diff-semver|equiv|check-rot> [--json] <source.src> [arguments] (the name of any `sentience` command is accepted in place of the subcommand)
  lume adapt <c|c-raw|rust|python|js|ts|node|go|java|csharp|dotnet|sql|openapi|polyglot|all> [--json] [--preprocess] [-o <value>] [--output <value>] [file]
  lume lsp [--stdio] [--json] [source.src]
  lume dap [--stdio] [--json] [source.src]
  lume repl [--json] [--kernel] [source.src]
  lume mcp [--json] <source.src>
  lume intent <build|run|verify|status|clean> [--json] [--cache <value>] [-o <value>] [--output <value>] <file.intent>
  lume mesh [--json] <request.mesh>
  lume economy [--output <value>] [--artifacts <value>] [--self-test]
  lume evolve <list|goals|budgets|propose|apply|grow|verify|status|check|approve> [--json] [--domain <value>] [--by <value>] [--sig <value>] [--target <value>] [--root <value>] [goal-or-proposal]
  lume self <status|verify|update|prove|prove-all> [--json] [--prefix <value>] [--from <value>]
  lume self-prove|prove-all|verify-all [--json]
  lume capsule <seal|verify|replay|open> [-o <value>] <file> [arguments]
  lume pack|unpack [-o <value>] <in>
  lume package <apk|ipa|iso|uefi> [-o <value>] <source.src>
  lume mir <target> <source.src>
  lume genesis <app-name> [domain]
  lume neural-kernel [--json] <source.src>
  lume symbolize <file.lsym> <query>
  lume patch-fn <source.src> <fn-name> <patch.src>
  lume trace <source.src>
  lume diff-semver <old.src> <new.src>
  lume heal <source.src>
  lume equiv <spec.src> <fast.src>
  lume morph <legacy-file>
  lume tv|translation-validate [--fn <value>] [--exec] [--json] <source.src>
  lume mcdc [--fn <value>] [--budget <value>] [--exec] [--json] <source.src>
  lume bundle <source.src>
  lume safety-envelope|lockstep [--fn <value>] [--args <value>] [--budget <value>] [--timeout-ms <value>] [--reset] [--gate] [kernel.src]
  lume tv-gate [--stride <value>]
  lume soak|soak-battle|battle [--rounds <value>] [--procs <value>] [--seed <value>]
  lume prover-fuzz [--n <value>] [--seed <value>]
  lume qualify|qualification [--quick] [--sign-key <value>] [--verify]
  lume realtime-gate
  lume concurrency-gate
  lume crypto-gate
  lume multi-arch-gate
  lume safetensors-gate
  lume dwarf-cache-gate
  lume cert-source-gate
  lume bootstrap|zero-c|amalgamate|seed|clean
  lume qwenputer|lumeputer|lumepu|weight-vm|in-weights-npu [exec|run] [--json] [--fn <value>] [--args <value>] [--budget <value>] [kernel.src] (values: sync|status)
  lume ui-layout|@ui-layout [--json] [file] (values: sync|status)
  lume unified-field|ufe|singularity|ote|transition-engine|net-sentinel|iec62443|conduite|omega-mesh|subsea [--json] [target] (values: sync|status)
  lume consult [--json] [file] (values: sync|status)
  lume laws|constitution|sanctuary [--json] [file] (values: sync|status)
  lume replicate|swarm-evolve [--json] [file] (values: sync|status)
  lume bios-core|firmware|kernel-core [--json] [file] (values: sync|status)
  lume daemon-triad [--json] [file] (values: sync|status)
  lume hot-evolve [--json] [file] (values: sync|status)
  lume live-cockpit [--json] [file] (values: sync|status)
  lume self-build [--json] [file] (values: sync|status)
  lume reverse-engineer|reveng|decompile|reversa [--json] [target] (values: sync|status)
  lume pingora|proxy|cdn|load-balancer [--json] [target] (values: sync|status)
  lume egm|elephant-goldfish|goldfish-review|drift-report|heilmeier [--json] [target] (values: sync|status)
  lume ncm|next-concept|ncm-quantize|ncm-generate|ncm-solve [--json] [target] (values: sync|status)
  lume opentpu|tpu|otpu-asm|k-smooth|stream-se|tpu-scoreboard [--json] [target] (values: sync|status)
  lume continuum|nexus|billion-context|acp|ecc-shield|agentshield|bend-laws|ai-memory|notebook|podcast|doory|canvas-crdt [--json] [target] (values: sync|status)
  lume quantum-nexus|quantum-zx|quantum-stabilizer|quantum-qec|quantum-vqe|quantum-uncompute|silq|quizx|stim [--json] [target] (values: sync|status)
  lume chameleon|camaleao|polyglot|ffi-bridge [--json] [target] (values: sync|status)
  lume interface|portal|chat [--json] [text] (values: sync|status)
  lume crypto-engine|cripto|blockchain [--json] [file] (values: sync|status)
  lume sensory-cortex|peripherals [--json] [file] (values: sync|status)
  lume file-indexer|pc-master|omni-reader [--json] [path] (values: sync|status)
  lume wireshark|packet-dissect|switch-fabric|scada-ics|modbus|dnp3|iec104|iec61850 [--json] [file] (values: sync|status)
  lume gfx|render-3d|scada-hmi|ied-protection [--json] [file] (values: sync|status)
  lume memory [--json] [file] (values: sync|status)
  lume recall [--json] [file-or-query] (values: sync|status)
  lume synapse|orchestrate [--json] [source.src] (values: sync|status)
  lume os-control|optimize|doctor|net-omni|network [--json] [file] (values: sync|status)
  lume web-research|internet|search [--json] [query-or-url] (values: sync|status)
  lume hive|central-core|ventral-core [--json] [file] (values: sync|status)
  lume saturate-contracts [--json] [file] (values: sync|status)
  lume fuse-mir-neural [--json] [file] (values: sync|status)
  lume triad-orchestrate [--json] [file] (values: sync|status)
  lume evolve-all [--json] [file] (values: sync|status)
  lume multimodal|talk|voice|listen|vision [--json] [file] (values: sync|status)
  lume awaken [--json] <source.src>
  lume morph-ast [--json] <source.src>
  lume quantum [--json] <source.src>
  lume bio-dna [--json] <source.src>
  lume cosmic-tmr [--json] <source.src>
  lume hologram [--json] <source.src>
  lume chronos [--json] <source.src>
  lume omega-net [--json] <source.src>
  lume llm-forge [--json] <source.src>
