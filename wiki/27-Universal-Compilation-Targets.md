<h1>
  <img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-mascot-badge.svg" alt="Lumi — Official Lume Chameleon Mascot" width="76" height="76" align="left" />
  27 Universal Compilation Targets, Neural Cartridges &amp; System Packagers
</h1>
<br clear="left"/>

Lume compiles verified `.src` programs directly across **27 target triples** (`ISA × Container × OS/ABI`), neural weight cartridges, and bootable/mobile system packages through `lumec`, `lasm`, `larm64`, `lriscv`, `lkir`, `ltarget`, and `lneural_cartridge` — with zero external C compilers or system linkers required at steady state.

> **Fail-Closed Target Invariant (`[V0001]` / `[T0902]`):** Every target backend runs `lumec`'s type, ownership, effect, `@no_alloc`, `@secret`, and `QF_LIA`/`QF_NIA` contract verifier **before** lowering. Any refuted contract aborts emission across all 27 targets (`verified in G-MARCH`).

---

## 1. Native Desktop, Server &amp; Bare-Metal CPU Targets (`lasm`, `larm64`, `lriscv`)

- **`lasm.src` Differential Assurance (`G-LASM`):** Byte-identical against GNU `as` across **`39,968` generated x86-64 instructions in `21` instruction families** (including `AVX2` VEX, `AVX-512` EVEX, and DWARF v4 `.debug_info`/`.debug_line`), rejecting `176/176` malformed assembly lines with `[L0001]`.
- **`larm64.src` &amp; `lriscv.src` Differential Assurance (`G-MARCH`):** **`73/73` AArch64** and **`55/55` RISC-V** official encoding vectors match `clang` word-for-word and execute identically across native `x86-64`, `qemu-aarch64`, `qemu-riscv64`, and bare-metal `LumePuter` (`ltv_multiarch` verified).

| Target Triple | Binary Container &amp; ABI | Key Capabilities |
| :--- | :--- | :--- |
| `x86_64-linux-elf` | ELF64 (`ET_EXEC`, SysV AMD64) | Direct Linux syscalls (`io_uring` `425..427`), DWARF v4 `-g`, `AVX2`/`AVX-512`, zero `libc` |
| `aarch64-linux-elf` | ELF64 (`EM_AARCH64`, AAPCS64) | Native 64-bit ARMv8-A Linux executable (`ltv_multiarch` validated) |
| `riscv64-linux-elf` | ELF64 (`EM_RISCV`, `RV64IM`) | Native 64-bit RISC-V Linux executable |
| `riscv32-none-elf` / `riscv64-none-elf` | Bare-metal ELF / flat ROM (`RV32IM` / `RV64IM`) | Clean-room `2oo2D` Channel B &amp; bare-metal deterministic monitor execution |
| `x86_64-windows-pe` | PE32+ Console (`Subsystem 3`) | Native Windows x64 `.exe` console binary (`KERNEL32.dll` import table) |
| `x86_64-windows-gui` | **PE32+ Native GUI (`Subsystem 2`)** | **`33,792`-byte** standalone Win64 GUI with embedded Lumi icon &amp; 4 scrollable/resizable panes |
| `x86_64-windows-gui-protected` | **PE32+ Protected Native GUI** | **`33,824`-byte** Win64 GUI with encrypted `.data`, MBA prologue &amp; `.lsym` symbol protection |
| `aarch64-macos-macho` | Mach-O 64 (`CPU_TYPE_ARM64`) | Native Apple Silicon (`M1`–`M4`) executable with `16 KiB` page alignment |
| `x86_64-macos-macho` | Mach-O 64 (`CPU_TYPE_X86_64`) | Native macOS Intel `LC_MAIN` executable |
| `x86_64-kernel` / `x86_64-uefi` | `@freestanding` Ring-0 `.kernel` &amp; PE32+ `BOOTX64.EFI` | Zero-GC MBR/Long-Mode &amp; UEFI boot binaries (`[K0005]` `W^X` DMA, `[K0006]` stack guard) |
| `thumbv7em-none-eabihf` / `avr-none` / `xtensa-esp32-elf` | ARM Cortex-M4/M7, AVR &amp; ESP32 firmware | Deterministic `@no_alloc` embedded microcontroller images &amp; Intel HEX |
| `aarch64-linux-android` / `aarch64-apple-ios` | Android ARM64 ELF &amp; iOS ARM64 Mach-O | Paired with one-command `lume package apk` and `lume package ipa` bundlers |

---

## 2. Clean Generic Win64 Native GUI (`--target x86_64-windows-gui`)

<img src="https://raw.githubusercontent.com/OmegaSoftDLL/lume/main/docs/assets/lume-icon.jpg" alt="Official Lumi 3D App &amp; Desktop GUI Icon (RT_ICON / RT_GROUP_ICON)" width="175" align="right" />

Compiling with `--target x86_64-windows-gui` emits a standalone **`33,792`-byte Windows 64-bit PE32+ GUI executable (`Subsystem 2`)** directly from Lume with zero C/C++/Rust/.NET toolchains:
- Embeds the official **Lumi 3D App Icon (`RT_ICON` + `RT_GROUP_ICON` + `LoadIconA(hInstance, 1)`)** inside the PE32+ `.rsrc` directory for the title bar, Alt+Tab switcher, and taskbar.
- Configures crisp **Segoe UI `-12`** typography and **4 independently resizable, horizontally &amp; vertically scrollable panes** (`WS_CLIPSIBLINGS | WS_THICKFRAME | WS_HSCROLL | WS_VSCROLL`), customizable via pure Lume hooks (`app_window_title`, `app_status_bar`, `app_editor_initial_buffer`, `app_secondary_buffer`, `app_tree_item_1`..`7`) and conservation-proven `@ui-layout` splits (`gui.src`).

```sh
lume build app.src --target x86_64-windows-gui -o Studio.exe
lume build app.src --target x86_64-windows-gui-protected -o StudioProtected.exe
```

<br clear="right"/>

---

## 3. Neural Cartridges, WebAssembly, GPU Compute, Silicon RTL &amp; Quantum Targets

| Domain | Target Triples &amp; Formats | Verification &amp; Execution Highlights |
| :--- | :--- | :--- |
| **Neural Weight VMs** | `safetensors`, `lumeputer-rv32im-weights`, `neural-kernel` | Compiles verified functions into `.safetensors` (`SwiGLU K=128` + `Gated-DeltaNet` + `RV32IM_Zba` ROM + embedded `lcert`, `63/63` bit-exact vectors in `G-SAFETENSORS`) |
| **Web &amp; Portable VM** | `wasm32-wasi`, `web-dom-wasm`, `lumb` | WebAssembly binary with `[I0275]` `64 KiB` linear-memory page bounds &amp; `[W0402]` capability import sandbox; `.lumb` verified bytecode |
| **GPU &amp; Systolic AI** | `nvptx64-nvidia-cuda`, `spirv64-vulkan-compute` | `@schedule(...)` `kernel fn` lowering to NVIDIA CUDA PTX 8.0 (`sm_80`/`sm_90`) and Vulkan SPIR-V 1.6 with built-in warp/word validators |
| **Synthesizable Silicon** | `verilog-rtl`, `vhdl-rtl` | IEEE 1364-2005 Verilog &amp; IEEE 1076-2008 VHDL deterministic FSM/pipeline emission with cycle-accurate RTL simulation |
| **Quantum &amp; Molecular** | `qasm3-quantum`, `qiskit`, `cirq`, `braket`, `qir`, `stim-clifford`, `dna-quaternary` | Linear `Qubit` no-cloning `[Q0001]`, automatic $U^\dagger$ uncomputation, ZX spider fusion, `[[9,1,3]]` surface-code QEC, and homopolymer-free quaternary DNA archives |

---

## 4. Target &amp; System Packager CLI Reference

```sh
lume targets                                                      # List all 27 supported target triples
lume build --target x86_64-linux-elf app.src -o app               # Native Linux x86-64 ELF64
lume build --target aarch64-linux-elf app.src -o app              # Native Linux ARM64 ELF64
lume build --target riscv64-linux-elf app.src -o app              # Native Linux RISC-V RV64IM ELF64
lume build --target riscv32-none-elf kernel.src -o kernel.rv32    # Bare-metal RISC-V RV32IM kernel
lume build --target x86_64-windows-pe app.src -o app.exe          # Native Windows x64 PE32+ console
lume build --target x86_64-windows-gui app.src -o gui.exe         # Clean Generic Win64 Native GUI
lume build --target aarch64-macos-macho app.src -o app            # Native Apple Silicon Mach-O 64
lume build --target wasm32-wasi app.src -o app.wasm               # Capability-sandboxed WebAssembly WASI
lume build --target safetensors --entry f k.src -o f.safetensors  # Verified .safetensors neural cartridge
lume build --target lumeputer-rv32im-weights --entry f k.src -o w # LumePuter RV32IM_Zba weight image
lume build --target nvptx64-nvidia-cuda k.src -o k.ptx            # NVIDIA CUDA PTX 8.0 compute kernel
lume build --target spirv64-vulkan-compute k.src -o k.spv         # Vulkan SPIR-V 1.6 compute shader
lume build --target verilog-rtl k.src -o k.v                      # Synthesizable IEEE 1364-2005 Verilog RTL
lume build --target vhdl-rtl k.src -o k.vhd                       # Synthesizable IEEE 1076-2008 VHDL RTL
lume build --target qasm3-quantum q.src -o q.qasm                 # OpenQASM 3.0 quantum circuit
lume build --target dna-quaternary d.src -o d.dna                 # Quaternary DNA storage archive
lume package apk app.src -o app.apk                               # Android APK package
lume package ipa app.src -o app.ipa                               # iOS IPA package
lume package iso kernel.src -o lume_os.iso                        # Bootable BIOS / El-Torito OS ISO
lume package uefi kernel.src -o BOOTX64.EFI                       # UEFI x86-64 PE32+ boot application
```
