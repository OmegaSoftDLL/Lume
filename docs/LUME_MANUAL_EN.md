# ============================================================================
# LUME PROGRAMMING LANGUAGE — BUILT-IN HUMAN & AI MANUAL (v0.3.0-rc.3 / Wave 10)
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
  6. stdlib     (biblioteca)   Standard Library & Sovereign Modules (fs, db, net, gui, nn...)
  7. targets    (alvos)        27 Universal Targets, MIR SSA, APK/IPA/ISO/UEFI & Silicon RTL
  8. commands   (comandos)     Full CLI Reference across Phases 1-5 & Waves 1-10
  9. examples   (exemplos)     6 Copy-Paste Working Programs for Humans & AI
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
- Conditional:        `if a > b then a else b`
- Logical (short-circuit): `a == 1 and b == 2`, `x < 0 or x > 10`, `not flag`
- Arithmetic:         `+`, `-`, `*`, `/`, `%`
- Comparison:         `==`, `!=`, `<`, `<=`, `>`, `>=`
- String concat/interp: `f"val={x}"`, `"val=${x}"`, or `"hello " + str(42)`
                        (split `"{" + s + "}"` when building raw brace templates)
- Record literal:     `{id: 1, name: "alice"}` (field access: `r.id`, `r.name`)
- List constructors:  `Nil`, `Cons(head, tail)`
- Comments:           `## Double hash starts a comment line`

## 2.3 Pattern Matching (`match` — 10/10 DX)
Lume supports three `match` forms everywhere:
1. Top-level function body `match`:
   ```lume
   fn sum_list(xs) = match xs
       Nil        => 0
       Cons(h, t) => h + sum_list(t)
   ```
2. Nested indentation-sensitive `match` inside `let ... in` or `if ... then ... else`:
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
2. Function Arity: Register calling convention uses `%rdi, %rsi, %rdx, %rcx, %r8, %r9`
   for the first 6 parameters and automatically spills parameters 7+ onto the stack.
3. Never edit `compiler/stage1/lumec.src` directly: edit `compiler/stage1/lume/NN_*.src`
   and run `scripts/amalgamate.sh`.

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

## 4.2 Algebraic Laws (`law`)
```lume
law add_commutative(a: int, b: int) = (a + b) == (b + a)
```

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

## 5.2 Deterministic Memory, Zero-Heap SRA & Scoped Arenas (`std.arena`)
- No stop-the-world GC pauses! Lume combines Perceus compile-time reference reuse,
  Escape Analysis & Scalar Replacement of Aggregates (`lsra_expr`: non-escaping
  `let r = {k1: v1, ...} in body` records are lowered directly into `%rbp` stack
  slots `_sra_<r>_<k>` with 0 heap `mkrec`/`recget` allocations), small-integer
  caching (`[-1024..1024]`), self-tail-call `jmp`, and O(1) bump arenas.
- Builtins & `use arena`:
  - `let a = arena_new(65536)`   Create a scoped region arena
  - `arena_enter(a)` / `arena_leave(a)` / `arena_reset(a)` / `arena_destroy(a)`
  - `heap_stats()`               Query live heap allocations and bytes
  - `lume run --memory <file.src>` Measure peak RSS memory in KB

## 5.3 Tamper-Evident E-Capsules (`std.capsule` & `lume capsule`)
- Seal execution traces, inputs, outputs, and SHA-256 digests into reproducible capsules:
  - `lume capsule seal <source.src> -o <out.lcaps>`
  - `lume capsule replay <out.lcaps>`

# CHAPTER 6: BUILTINS, STANDARD LIBRARY & SOVEREIGN MODULES

## 6.1 Core Builtin Functions (Always Available in `.src`)
- Strings:  `count(s)`, `at(s, i)`, `slice(s, start, end)`, `slicen(s, start, len)`,
            `ord(ch)`, `chr(code)`, `str_from_byte(code)`, `str(n)`, `toint(s)`
- I/O & FS: `readall()`, `fs_read_file(path)`, `fs_write_sync(path, data)`,
            `fs_path_exists(path)`, `fs_read_byte(path, offset)`, `fs_file_size(path)`
- Process:  `os_arg_count()`, `os_arg_at(i)`, `os_getpid()`, `os_exit(code)`,
            `os_run(cmd, args)`, `os_run_capture_timeout(cmd, args, out, err, ms)`
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
  - Block Memory, Integrity & O(1) Kernel State: `mem_copy(dst, src, len)`, `mem_set(dst, b, len)`,
    `mem_crc64(addr, len)` (64-bit FNV-1a anti-rootkit page integrity), `krn_slot_write(idx, val)`,
    `krn_slot_read(idx)` (zero-allocation 1024-slot kernel state table)
- Failure:  `ctfail(msg)` (prints message to stderr and exits with non-zero code)

## 6.2 Standard Library Modules (`use <module>`)
- `use fs`             Safe file handles (`with_file` close-on-all-paths, `[O0001]` safety)
- `use bytes`          Bounds-checked byte buffers (`bytes_from_str`, `bytes_get`, `bytes_slice`)
- `use map`            256-way hash-bucketed dictionary (`map_empty`, `map_put`, `map_get`)
- `use arena`          Scoped O(1) memory arenas (`with_arena`, `arena_stats`)
- `use capsule`        Tamper-evident execution capsules (`capsule_seal`, `capsule_verify`)
- `use fs_sha256_file` FIPS 180-4 SHA-256 digest (`lc_sha256(str)`, `fs_sha256_file(path)`)
- `use db`             Multi-way B+Tree + ACID WAL crash-recovery engine & SQL query executor
- `use net`            Full TCP/IP, Wireshark Multi-Layer Dissector (`wireshark_dissect_frame`,
                       `wireshark_filter_match`, `.pcap` reader/writer), L2/L3/P4 Switch Firmware
                       Engine (IEEE 802.1Q VLAN, 802.1w RSTP, CAM/MAC learning, MPLS, FIB LPM,
                       BGP-4, P4 pipeline), Industrial/Substation Telemetry Protocols from
                       scratch: Modbus RTU/TCP (`CRC-16 0xA001`), DNP3 IEEE 1815 (`0x0564` +
                       `CRC-16/DNP` + SBO + SAv5), IEC 60870-5-104 (`TCP/2404` I/S/U-Format),
                       IEC 61850 (`MMS ISO 9506`, `GOOSE 0x88B8`, `Sampled Values 0x88BA`), and
                       Digital Substation Protection Relays (`sv_dft_4sample_phasor` 60 Hz DFT,
                       `ANSI 50`, `ANSI 51`, `ANSI 87`, `ANSI 21`, `ANSI 27/59`, `ANSI 81`, `ANSI 79`)
- `use gfx`            2D/3D Graphics, Fixed-Point Math (`fx_sqrt`, `fx_sin_deg`, `fx_cos_deg`),
                       Porter-Duff RGBA Alpha Blending, Bresenham/Circle/Bezier 2D Rasterizer,
                       3D Pinhole Perspective Projection, Binary 54-Byte BMP, PPM & SCADA HMI SVG
- `use gui`            X11 wire-protocol client (`0x42` MSB handshake, `CreateWindow`) & Web DOM
- `use nn`             Neural layers, binary `.safetensors` & Protobuf `.onnx` model I/O
- `use async_rt`       Work-stealing OS multi-process worker pool (`async_run_workers_os`)
- `use media`          2D raster canvas, font glyph renderer, and binary image codecs
- `use interop`        Fail-closed C ABI layout & header adapter (`[I0003]`)
- `use protect`        P33 control-flow flattening, string encryption & `[W0002]` secret scanner
- `use lgenesis`       Full-stack application & 8-target autonomous synthesizer
- `use lsentience`     Wave 9-10 Quantum, DNA, HDC, DEQ, LLM-Forge, Triad & Multimodal engine
- `use lume_crypto_blockchain_engine` SHA-256 PoW, Ed25519/Secp256k1, UTXO, AMM & Kelly Criterion
- `use lume_reversa_engine` Reversa-Lume SDD Engine v1.0: 7-phase hybrid binary (`ELF64`, `PE64`,
                       `UEFI`, `Mach-O`, `WASM`) + multi-language reverse engineering, SHA-256
                       immutability guard, epistemic `CONFIRMED`/`INFERRED`/`GAP` confidence score,
                       `reversa_soul.md`, Mermaid `stateDiagram-v2` & C4 `flowchart TD`, 3D
                       `reversa_code_city_3d.svg` via `std.gfx`, and Lume-Core decompilation
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
                       `Silq` Linear Qubit Type Checker (`No-Cloning`/`No-Measure-Reuse`) & Automatic $U^\dagger$
                       Ancilla Uncomputation (`qfree_safe == 1`), `QuiZX/PyZX` Graphical ZX-Calculus Spider Fusion
                       & $T$-Count Optimizer (`7x` $T$-gate reduction), `Google Stim` Gottesman-Knill $O(n^2)$
                       Stabilizer Tableau Simulator (`GHZ_8`), Rotated Surface Code `[[9, 1, 3]]` Topological QEC
                       (`27/27` Pauli errors corrected), and `PennyLane/Catalyst` Exact Parameter-Shift VQE

# CHAPTER 7: 27 UNIVERSAL TARGETS, LUMEMIR SSA & STORE PACKAGERS

## 7.1 Native OS, Mobile, Web, Bare-Metal & Exotic Targets (`lume build --target <t>`)
- Desktop/Server: `x86_64-linux-elf`, `aarch64-linux-elf`, `riscv64-linux-elf`,
                  `x86_64-windows-pe` (native `kernel32.dll` IAT), `aarch64-macos-macho`
- Mobile/Store:   `aarch64-android-apk`, `aarch64-ios-ipa`
- Bare-Metal/OS:  `x86_64-uefi-pe`, `x86_64-boot-iso`, `x86_64-baremetal-kernel`, `ihex`
- Web/Bytecode:   `wasm32-wasi` (with `@wasm-sandbox` `[I0275]`), `lumb`
- GPU/Accelerators: `nvptx64-nvidia-cuda` (PTX 8.0), `spirv64-vulkan-shader` (SPIR-V 1.6)
- Silicon/Hardware: `verilog-rtl-2005` (IEEE 1364), `vhdl-rtl-2008` (IEEE 1076)
- Quantum & Bio:  `qasm3-quantum` (OpenQASM 3.0), `dna-quaternary` (`A,C,G,T` codec)

## 7.2 Store/Boot Packagers, LumeMIR & Differentiable Silicon
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
  lume repl [--stdio|--kernel]           Interactive Read-Eval-Prove-Print Loop
  lume lsp / lume dap                    Language Server & Debug Adapter Protocol
  lume pkg init|check|lock|verify|tree   Content-addressed package manager
  lume registry publish|resolve|discover Verified component registry

## 8.2 Formal Verification, AI Agent & Evolution Commands (Waves 1-8)
  lume prove [--diff|--share] <src.src>  Run `QF_LIA` / Separation Logic theorem prover
  lume certify / verify-cert <src.src>   Emit & verify standalone proof certificates
  lume agent <skeleton|cegis|prove> <f>  Compiler-as-Oracle AI synthesis
  lume patch-fn <src> <fn_name> <patch>  AST surgical single-function hot-patcher
  lume trace <src.src>                   Structured JSON execution trace
  lume diff-semver <old.src> <new.src>   Mathematical SemVer bump analyzer
  lume symbolize <file.lsym> <query>     P33 obfuscated symbol/address resolver
  lume capsule seal|replay <file>        Tamper-evident execution capsule V2
  lume genesis <app_name> [domain]       Full-stack + 8-target autonomous app synthesizer
  lume heal <src.src>                    Counterexample-driven contract self-healer
  lume equiv <spec.src> <fast.src>       Formal algorithmic equivalence prover
  lume morph <legacy_file>               Transmute SQL/Python/C/OpenAPI to proven Lume
  lume neural-kernel <src.src>           GPU/NPU/FPGA RTL differentiable synthesizer
  lume evolve propose|apply|verify|...   Cryptographically governed self-evolution

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
  lume replicate / hive    Triad swarm self-replication & Byzantine Krum mesh sync
  lume reversa / reverse-engineer / reveng / decompile <target> Unified binary & 7-phase SDD reverse engineering
  lume pingora / proxy / cdn / load-balancer [target] Pingora-Lume Edge Proxy (TinyUFO, Ketama+P2C, TLS 1.3, 7-phase ProxyHttp)
  lume egm / elephant-goldfish / goldfish-review / drift-report / heilmeier [target] EGM-Lume Spec-Driven Development & Drift Engine
  lume ncm / next-concept / ncm-quantize / ncm-generate / ncm-solve [target] NCM-Lume Next-Concept Modeling Coarse-to-Fine Parallel Engine
  lume opentpu / tpu / otpu-asm / k-smooth / stream-se / tpu-scoreboard [target] OpenTPU-Lume Systolic AI Accelerator & ISA Engine
  lume continuum / nexus / billion-context / acp / ecc-shield / bend-laws / ai-memory / notebook / doory [target] Lume Continuum Nexus v1.0 (7 Reference Engines)
  lume quantum-nexus / qfree / zx-calculus / surface-code / vqe [target] Lume Quantum Nexus v1.0 (Silq qfree, QuiZX, Stim, Surface Code QEC, Catalyst VQE)
  lume os-control / bios-core / web-research / crypto-engine
  lume sensory-cortex / multimodal / file-indexer / interface / self-build
  lume wireshark / switch-fabric / scada-ics / modbus / dnp3 / iec104 / iec61850
  lume gfx / render-3d / scada-hmi / ied-protection / recall / synapse / orchestrate

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
  all 14 Sovereign Proof Batteries (`LumeCompiler-Embedded-OmniProof-v3`) directly inside
  the compiled Lume driver with zero external scripts (`std.net`, `std.gfx`,
  `lume_crypto_blockchain_engine`, `lume_reversa_engine`, `lume_pingora_proxy_engine`,
  `lume_egm_engine`, `lume_ncm_engine`, `lume_opentpu_engine`, `lume_continuum_nexus_engine`,
  `lume_quantum_nexus_engine`, `lsentience`, `lmanual`, `KerneLume` Bare-Metal OS,
  `[K0005]`/`[K0006]`/`[C0009]`/SRA guards, and `MANIFEST.sha256`: 396 formal obligations +
  134 unit tests + 98 verified toolchain artifacts).

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
    let m0 = map_empty() in
    let m1 = map_put(m0, "creator", lc_sha256("Ricardo Bueno")) in
    map_get(m1, "creator", "missing")

print run_demo()
```

## Example 4: B+Tree ACID Database & SQL Query (`db_demo.src`)
```lume
use db
print str(db_btree_self_test())
```

## Example 5: Cryptographic Custody, PoW Mining & DeFi AMM (`crypto_demo.src`)
```lume
use lume_crypto_blockchain_engine
print crypto_blockchain_full_report()
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

# CHAPTER 10: COMPILER DIAGNOSTIC CODES & HOW TO FIX THEM

| Code      | Category             | Meaning & How to Fix |
|-----------|----------------------|----------------------|
| `[P0002]` | Parser / Syntax      | Unexpected token or nested unbraced `match`. Move `match` to top-level helper `fn f(x) = match x ...` or wrap in braces `match x { ... }`, and verify pure LF (`\n`) line endings. |
| `[R0200]` | Name Resolution      | Call to undefined function or variable. Check spelling or add `use <module>` at top of file. |
| `[T0300]` | Type / Tensor Shape  | Type mismatch, currency mismatch (`money[BRL]` vs `money[USD]`), or tensor shape mismatch. |
| `[E0200]` | Algebraic Effects    | Impure operation (`io`, `fs`, `net`, `arena_new`, `embed`) called inside a `/ pure` function. Remove `/ pure` or add the required effect to the function signature. |
| `[O0001]` | Ownership / Borrow   | Use-after-move, double-close of file handle, or conflicting mutable borrow (`mut`). Clone or restructure ownership scope. |
| `[V0001]` | Contract / Law Proof | `requires`/`ensures` contract or `law` refuted by `QF_LIA` solver. Inspect the printed counterexample or run `lume heal <file.src>`. |
| `[V0002]` | WCET Cycle Bound     | Function exceeds `@bound(cycles: N)` budget or uses unbounded recursion in `@interrupt`. |
| `[I0003]` | C ABI Interop        | Unsafe or unsupported C declaration in `lume adapt c`. Add explicit bounds or `@repr(c)`. |
| `[I0275]` | WASM Sandbox         | Disallowed host import (`env.*`, `proc_exit`) in `@wasm-sandbox` module. |
| `[C0271]` | Comptime Embed       | `comptime embed("...")` path escapes project root (`..`) or file is missing. |
| `[D0273]` | Table Schema         | `comptime table_schema(T)` called on a non-record type. |
| `[K0005]` | Bare-Metal W^X / DMA | `mmio_volatile_write*`, `mem_copy`, or `mem_set` targets `.text`/`.rodata` (`[0x8000..0x3FFFF]`), including symbolic/affine `base + off`. Use a safe DMA RAM buffer (`>= 0x40000`). |
| `[K0006]` | Kernel Stack Safety  | Unbounded mutual recursion cycle (`f -> g -> f`) in `@freestanding` / `kernel_boot_entry` module. Use tail-loop state or bounded iteration. |
| `[C0009]` | Constant-Time Crypto | Secret-dependent `if`/`match` branch, variable-latency `/` or `%`, short-circuit `and`/`or`, or secret-indexed memory lookup on `secret_*` or inside `ct_*`. Use bitwise XOR/OR mask accumulation. |
| `[Q0001]` | Quantum Linearity    | Non-linear `Qubit` duplication (No-Cloning violation) or reuse of measured qubit. Ensure each `Qubit` wire is consumed linearly. |
| `[Q0002]` | Quantum Uncompute    | Uncomputed ancilla wire in `qfree` function (`anc_leaked > 0`). Apply adjoint $U^\dagger$ (`q_silq_qfree_verify`) before returning. |
| `[L0001]` | Lint / Style         | Unformatted source or lint warning; run `lume fmt <file.src>`. |
| `[W0002]` | P33 Secret Scanner   | Hardcoded private key/token detected before binary emission; move secrets out of source. |
