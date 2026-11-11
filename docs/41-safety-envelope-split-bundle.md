# 41 - Safety envelope: clean-room channel B and the dual-board split bundle

Status: shipped as described below; the "Real level" section says what was executed and what was not.
Source: `compiler/stage1/lsafety_envelope.src`. Gates: `tests/harness/safety_envelope_gate.src`,
`tests/harness/multi_arch_gate.src`.

## 1. Two channels with no shared front end

`lume safety-envelope` computes a critical kernel twice and commits the value only when both results are equal.

| | Channel A (command) | Channel B (monitor) |
|---|---|---|
| Input | the kernel file | the same kernel file, as raw text |
| Front end | `build/bin/lumec` (lexer, parser, checker, prover, lowering) | `cbl_*` / `cbp_*` / `cbt_*` inside the tool, written from `docs/03-specification.md` and `grammar/lume.ebnf` |
| Code generator | lumec x86-64 + `lasm` | `cbg_*`: AST to RV32IM directly |
| Execution | native process | RV32IM interpreter (the LumePuter), or the bare image on a board |
| Number domain | 64-bit integers | i32, every overflow traps |
| Contracts | run-time checks unless lumec proved them | always run-time checks |

The tool does not `use lumec`. The gate proves it on every run: it bundles the tool (`lume bundle`), extracts every
function the bundle defines, and requires that none of them is a function of `compiler/stage1/lumec.src`; the same
scan over the gate's own bundle (which does link the compiler for its reference evaluator) must find the compiler,
which is the negative control of the scan.

The fragment channel B accepts, and the places where it refuses instead of guessing (operator `not`, line breaks
before an operator, `#[` comments, loose integer literals, implicit int / bool conversions), are listed in the header
of `lsafety_envelope.src`. Of the attributes, `@bound` is read, `@no_alloc` and `@secret` (properties lumec checks on
the channel-A side that do not change a value) are passed over, and any other attribute is a refusal. Section 12 of
the gate holds one regression case per decision: 28 kernels whose values were derived by hand from the specification
(channel B, the gate's reference evaluator and the real lumec + lasm channel must all give them) and 41 texts that
channel B must refuse with a named reason.

## 2. The split bundle

```
printf '@root %s\n@src %s\n@fn %s\n@split %s\n' "$PWD" examples/safety_envelope/critical_kernels.src \
    actuator_rate_limit "$PWD/build/certification/envelope_split" | build/bin/lsafety_envelope
```

| File | What it is | Tool chain |
|---|---|---|
| `channel_a_x86_64.elf` | channel A, x86-64 Linux | lumec + lasm (the frame shell is Lume code appended to the kernel; kept as `channel_a_x86_64.src`) |
| `channel_a_aarch64.elf` | channel A, AArch64 Linux | lumec must accept the file, then `lkir.src` + `larm64.src` compile the kernel; the frame shell is A64 code |
| `channel_a_riscv64.elf` | a third program, RV64 Linux | the same through `lriscv.src` |
| `channel_b_riscv_bare.bin` | channel B, bare-metal RV32IM | the clean-room compiler; load address and entry `0x80000000` |
| `manifest.json` | kernel id, budget, addresses, size and SHA-256 of every artifact | |

The bare image contains: `jal start`; a machine-exception stub (`mtvec` points at it); the frame shell (polled 16550
UART at `0x10000000`, hex codec, CRC-32); five trap stubs; the kernel code. The kernel code is instrumented: every
basic block adds its length to `x27` and traps when the counter exceeds the limit in `x26`, and every function entry
traps when `sp` is below `x25`. Memory: buffer at `0x80020000`, stack top `0x80030000`, stack limit `0x8002C000`.
After the response frame the image writes `0x5555` to `0x100000` (the test finisher of the QEMU `virt` board) and
loops; a real board replaces that by its own halt or reset. One request is served per reset.

The AArch64 and RV64 programs are built only when the whole kernel file is inside the fragment of `lkir.src` (no
`bit_and` / `bit_or` / `bit_xor`, no `ctfail`, no `elif`); otherwise the manifest records the reason.

## 3. Frame protocol (version 1)

A word is 8 upper-case hex digits (a 32-bit value). A frame is its words followed by one line feed. The CRC is
CRC-32/ISO-HDLC (polynomial `0xEDB88320` reflected, initial value and final xor `0xFFFFFFFF`) over the ASCII characters
that precede the CRC word.

Request, 15 words, 121 bytes:

| Word | Field |
|---|---|
| 0 | magic `4C535251` ("LSRQ") |
| 1 | protocol version, `00000001` |
| 2 | sequence number |
| 3-4 | kernel id: the first 64 bits of `sha256(kernel file text + "\n" + function name)` |
| 5 | number of arguments (at most 8) |
| 6-13 | argument words (two's complement; unused ones are zero) |
| 14 | CRC |

Response, 20 words, 161 bytes:

| Word | Field |
|---|---|
| 0 | magic `4C535253` ("LSRS") |
| 1 | protocol version |
| 2 | sequence number of the request |
| 3-4 | kernel id of the program that answers |
| 5 | channel code: `A0000001` x86-64, `A0000002` AArch64, `A0000003` RV64, `B0000001` bare RV32IM |
| 6 | number of arguments as received |
| 7-14 | argument words as received |
| 15 | status: 0 result valid, 1 the kernel trapped, 2 the request was refused |
| 16 | cause (below) |
| 17 | result word |
| 18 | cycle count (channel B: kernel instructions executed; channel A: 0) |
| 19 | CRC |

Trap causes (status 1): 1 contract, 2 integer overflow, 3 division by zero, 4 cycle budget, 5 stack limit, 6 result
outside i32 (64-bit channels), 7 machine exception. Refusal causes (status 2): 1 magic, 2 version, 3 kernel id,
4 number of arguments, 5 CRC, 6 format, 8 a bool argument that is not 0 or 1.

The x86-64 program cannot catch its own trap: a kernel trap ends the process without a frame, which the voter treats
as a missing frame. The AArch64, RV64 and bare RV32IM programs send a trap frame.

## 4. The voter

```
printf '@root %s\n@mode split-run\n@manifest %s/manifest.json\n@seq 7\n@args 120,100,15\n@cmd_a %s\n@cmd_b %s\n' \
    "$PWD" "$D" "$D/channel_a_x86_64.elf" "lumeputer:$D/channel_b_riscv_bare.bin" | build/bin/lsafety_envelope
```

`@cmd_a` and `@cmd_b` are shell commands that stand for the two serial links: the request frame is their standard
input, the response frame their standard output, and each runs under `@frame_timeout_ms` (default 5000).
`lumeputer:<image>` runs the bare image on the in-tool interpreter. An optional `@cmd_c` adds a third frame of
channel-A class that must agree as well.

The voter commits only when, for both frames: the frame arrived in time, has 161 bytes and a correct CRC, carries the
magic, the version, the sequence number of this request, the kernel id of the manifest, a channel code of the right
class, the argument count and the argument words that were sent, status 0 and cause 0; channel B's cycle count is
within the manifest's limit; and the two result words are equal. Anything else is `SAFE_STATE_TRIP` with a reason
(`a_frame_timeout`, `b_frame_crc`, `a_frame_sequence`, `b_frame_kernel_id`, `b_trap_overflow`, `lockstep_mismatch`,
...). A trip is latched in the hash-chained event log until `@reset 1`. A replayed response carries an old sequence
number and trips as `*_frame_sequence`. The voter also refuses to reuse a sequence number: `@seq` must be larger than
every sequence number of a split-run event already in the event log, else the request is not sent and the run trips
with `sequence_not_fresh` (without that, the frames recorded for an earlier request with the same sequence number,
kernel and arguments would pass every check and hide a channel that has died since). This protection is as durable
as the event log: with a new or deleted log the numbering starts again.

`@mode split-verify` with `@manifest` re-hashes every artifact against the manifest.

## 5. Emulator command lines used by the gates

```
qemu-system-riscv32 -machine virt -bios none -display none -monitor none -serial stdio -kernel channel_b_riscv_bare.bin
qemu-aarch64 channel_a_aarch64.elf
qemu-riscv64 channel_a_riscv64.elf
```

Each is started as `/bin/sh -c 'ulimit -s 8192; exec timeout 15 <command>'` with the request frame on standard input.
`tests/harness/multi_arch_gate.src` fails (it does not skip) when one of the three emulators is missing.

## 6. What the gates check

`safety_envelope_gate` (no emulator needed): independence scan; conformance of the clean-room parser on
`critical_kernels.src`, `lchameleon.src` and `lstd.src`; a differential campaign of random kernels (channel A = real
lumec + lasm binaries, channel B = clean room) from a fixed seed and a `/dev/urandom` seed; the cross-detection matrix
(`a_src`, `b_src`, `b_cg` mutants); the split bundle with the x86-64 program and the bare image on the interpreter,
including every frame fault (bit flip, replay, wrong sequence, truncation, wrong kernel id, crossed channels, silent
channel, forged frames with a valid CRC, a sequence number used twice). Totals go to `build/certification/safety_envelope_gate_summary.json`.

`multi_arch_gate`: the same bundle on qemu-system-riscv32, qemu-aarch64 and qemu-riscv64; the response frame of the
bare image must be identical on QEMU and on the in-tool interpreter; contract and overflow traps; a request corrupted
or truncated on the way to the board; the image of another kernel; an illegal instruction in the image (QEMU vectors
to the machine-exception stub, which sends a trap frame); a silent channel.

## 7. Real level

- QEMU is an emulator, not silicon. Two processes on one host are not two boards. Standard input and output stand for
  the UART. No timing property of a real serial link (baud rate, framing errors, flow control) is exercised.
- What exists: a split that can be loaded on two boards as it is (apart from the board-specific halt and UART
  set-up), and a frame / voter protocol tested against the faults listed above.
- The voter and its event log are one process on one host: a single point that the split does not remove.
- The AArch64 and RV64 programs take the kernel through `lkir.src` (a small reader of the same syntax) after lumec
  accepted the file; they are not produced by lumec's code generator. A pairing of only those two would share that
  reader, so the voter always requires the clean-room channel B and treats the RV64 program as a third frame.
- The bare image was run on QEMU `virt` only. Its UART is used as the reset configuration leaves it (no divisor
  programming), and it serves one request per reset.
- The cycle counter of the bare image counts kernel instructions of the uninstrumented layout; it is not a
  wall-clock bound.
