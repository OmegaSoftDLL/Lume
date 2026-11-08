<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Lume Mascot" width="76" height="76" align="left" />
  27 Universal Proof-Preserving Compilation Targets
</h1>
<br clear="left"/>

Lume's orthogonal target engine (`compiler/stage1/ltarget.src` + `lasm.src`) lowers verified Lume programs across **27 target triples** — from desktop and server machine code to **Clean Generic Win64 Native GUI executables**, GPUs, microcontrollers, FPGAs, mobile/web runtimes, and quantum QPU circuits.

> **Fail-Closed Target Invariant (`[V0001]`):** Every target compilation runs the `QF_LIA` theorem prover BEFORE emitting a single byte of machine code. If any `requires`/`ensures` contract is refuted, emission is aborted across all 27 targets.

---

## 1. Native Desktop, Server & Win64 GUI Targets

| Target Triple | Binary Format | Highlights |
| :--- | :--- | :--- |
| `x86_64-linux` | ELF64 (`ET_EXEC`) | Direct Linux syscall emission, zero `libc` / zero `ld` |
| `x86_64-windows` | PE32+ Console (`Subsystem 3`) | Standalone Windows x64 console binary (`KERNEL32.dll`) |
| `x86_64-windows-gui` | **PE32+ Native GUI (`Subsystem 2`)** | **`33,792`-byte** standalone Win64 Studio GUI with Lumi `RT_ICON`, Segoe UI `-12`, and 4 resizable/scrollable panes (`WS_CLIPSIBLINGS \| WS_THICKFRAME`) |
| `x86_64-windows-gui-protected` | **PE32+ P33 Protected GUI** | **`33,824`-byte** Win64 GUI with `.data` encrypted via `XOR k=178` + self-healing MBA prologue + `LUME_SEAL` |
| `x86_64-macos` | Mach-O 64 (`CPU_TYPE_X86_64`) | Direct macOS `LC_MAIN` + `LC_UNIXTHREAD` binary |
| `aarch64-linux` | ELF64 ARM64 (`EM_AARCH64`) | 64-bit ARMv8-A machine code with proof-elided guards |
| `aarch64-macos` | Mach-O 64 (`CPU_TYPE_ARM64`) | Native Apple Silicon (`M1`/`M2`/`M3`/`M4`) executable |
| `riscv64-linux` | ELF64 (`EM_RISCV` `RV64GC`) | Native 64-bit RISC-V Linux executable |

### Building a Standalone Windows 64-Bit Native GUI App (`x86_64-windows-gui`)

```bash
# Emit a standalone 33,792-byte Windows x64 GUI executable (.exe)
lume build app.lume --target x86_64-windows-gui -o MyStudio.exe

# Emit with P33 Anti-REA .data encryption (XOR k=178 + MBA prologue)
lume build app.lume --target x86_64-windows-gui-protected -o MyStudio_P33.exe
```

You can customize the native Win64 GUI window title, status bar, initial code editor buffer, executive report, and tree items simply by defining pure Lume functions (`app_window_title`, `app_status_bar`, `app_editor_initial_buffer`, `app_secondary_buffer`, `app_tree_item_1`..`7`).

---

## 2. WebAssembly, Bytecode, GPU & Accelerator Targets

| Target Triple | Format / ISA | Built-In Simulator / Verification |
| :--- | :--- | :--- |
| `wasm32` / `wasm32-wasi` | WebAssembly Binary (`\0asm\x01\0\0\0`) | Capability-sandboxed (`[W0402]` rejects unauthorized host imports) |
| `web-dom-wasm` | HTML5 + Canvas + WebAssembly Bundle | Single-file reactive browser bundle |
| `lumb` | Lume Verified Bytecode (`LUMB\x01`) | Executed by built-in stack VM with contract attestation |
| `nvptx64` | NVIDIA CUDA PTX 8.0 (`sm_80` / `sm_90`) | Built-in warp/thread PTX simulator (`@run-ptx`) |
| `spirv64` | Khronos Vulkan / OpenCL SPIR-V 1.6 | Built-in SPIR-V binary word validator & VM (`@run-spirv`) |
| `neural-kernel` | Differentiable AVX-512 / AMX / PTX Kernel | Synthesized via `lume neural-kernel <file>` |

---

## 3. Bare-Metal MCU, FPGA Silicon & Mobile Targets

| Target Triple | Architecture / Format | Highlights |
| :--- | :--- | :--- |
| `thumbv7em-none-eabihf` | ARM Cortex-M4/M7 Thumb-2 + Intel HEX | Cycle-accurate MCU trap simulator |
| `avr-none` | Microchip AVR (`ATmega328P`) + Intel HEX | 8-bit deterministic control firmware |
| `xtensa-esp32-elf` | Espressif ESP32 (`LX6`/`LX7`) | IoT bare-metal firmware |
| `verilog-rtl` | Synthesizable IEEE 1364-2005 Verilog | Cycle-accurate RTL simulator (`@run-hdl`) |
| `vhdl-rtl` | Synthesizable IEEE 1076-2008 VHDL | Deterministic FSM & pipeline synthesis |
| `aarch64-apple-ios` | iOS ARM64 Mach-O + `.ipa` Packager | `lume package ipa <file> -o app.ipa` |
| `aarch64-linux-android` | Android ARM64 ELF + `.apk` Packager | `lume package apk <file> -o app.apk` |
| `x86_64-uefi` / `iso` | UEFI PE32+ `BOOTX64.EFI` & Bootable ISO | `lume package uefi` / `lume package iso` |

---

## 4. Quantum QPU & Molecular Targets

Lume compiles quantum `qreg` / unitary gate programs (`H`, `X`, `Z`, `CNOT`, `RZ`) with compile-time **No-Cloning Theorem enforcement (`[Q0001]`)** across 6 quantum targets (`qasm3`, `qiskit`, `cirq`, `braket`, `qir`, `stim-clifford`) plus synthetic `dna` quaternary encoding (`A/C/G/T` with homopolymer & GC-balance verification).
