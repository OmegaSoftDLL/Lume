# 42 — Native Windows toolchain

Status of each part: **shipped** (runs and is tested in CI), **planned** (not built yet).

## 1. The problem

The Windows release archive (`lume-<tag>-windows-x86_64.tar.gz`) ships the seed (`lume0.exe`), the
`x86_64-windows-pe` target and two sample executables. It does not ship the native toolchain
(`lume_driver`, `lumec`, `lasm`, `lmod`): those are x86-64 Linux ELF binaries. On Windows the shim
therefore routes every command to `scripts/lume_legacy.sh` and the seed, which:

- rejects Lume-Core `.src` constructs it does not know (`law`, multi-line contracts) in `check` and `test`;
- used to run `lfmt` through the seed interpreter and overwrite the file with its output, even when that
  output had dropped contracts, `law` and `+%` (data loss).

The seed itself is correct: it compiles `lumec.src` on Windows with output byte-identical to Linux. What is
missing is a native toolchain that runs on Windows.

Why the native toolchain is Linux-only: the hosted runtime (`compiler/stage1/runtime_core.lume`) and the
OS builtins emitted by `compiler/stage1/lume/05_codegen.src` are x86-64 code that calls the Linux kernel
directly (about 100 `syscall` sites: `mmap`/`mprotect`/`madvise` for the collector, `read`/`write`/`open`,
`getdents`, clocks, `fork`/`execve`/`pipe`/`wait4` for `os_run*`, `io_uring`, shared memory), and `lasm`
only wrote ELF.

## 2. Plan

| Part | Deliverable | Status |
| --- | --- | --- |
| 1 | Fail closed on seed-only hosts: `lume fmt` refuses `.src` and leaves the file untouched; release gate C on Windows; release notes and README state what each archive contains | **shipped** |
| 2 | `lasm --pe`: Windows x64 PE32+ console executables with a real import table | **shipped** |
| 3 | Win64 hosted runtime: collector on `VirtualAlloc`/`VirtualFree`, files, directories, argv, environment and clocks on `KERNEL32` | **in the working tree, tested** |
| 4 | Processes: `os_run*` on `CreateProcessW`/`CreatePipe`/`WaitForSingleObject` (timeouts, captured output, exit status); the driver stops depending on `/bin/sh` | **in the working tree, tested** |
| 5 | `lume_driver`, `lumec`, `lasm`, `lmod` built as `.exe`; the full suite runs on Windows; the Windows archive ships them and its gate runs the same checks as Linux (`check`, `test` with `law`, `prove`, `fmt` preserving the file) | planned |

Until part 5 ships, the full toolchain on Windows means Linux x86_64, for example under WSL.

## 3. Part 1 — fail closed (shipped)

- `scripts/lume_legacy.sh` `cmd_fmt`: on a host where the native toolchain cannot run, `.src` files are
  refused with exit 1 and the message `formatting .src needs the native toolchain (x86_64 Linux); this host
  only has the seed — file left unchanged`, in all three modes (in place, `--check`, `--stdout`). `.lume`
  files keep the whitespace formatter.
- Regression test: `tests/harness/claude_audit_gate.src` `cag_check_seed_path` runs the legacy dispatcher
  with `LUME_FORCE_SEED=1` on a `.src` with a contract, a `law` and `+%`, and fails if `fmt` or
  `fmt --check` exits 0 or the file changes. The previous dispatcher exits 0 and rewrites the file to
  `fn wrap_add(a: int, b: int) -> int = requires` / `law`, so the test fails on it.
- `.github/workflows/release.yml` Windows gate C: the installed archive must refuse `fmt` (three modes) and
  `test` on that `.src`, and leave it byte-identical.

## 4. Part 2 — `lasm --pe` (shipped)

`lasm --pe file.s > file.exe` writes the same item stream as the ELF paths as a PE32+ console executable.

Layout:

- Image base `0x400000`, no base relocations (`IMAGE_FILE_RELOCS_STRIPPED | EXECUTABLE_IMAGE |
  LARGE_ADDRESS_AWARE`, no `DYNAMIC_BASE`), so the loader maps the image at its preferred base and every
  absolute address lasm computes (`.quad label`) stays valid.
- Headers in the first 512 bytes: DOS header (`e_lfanew = 64`), `PE\0\0`, COFF header (machine `0x8664`,
  one section), PE32+ optional header (subsystem 3 = console, `NX_COMPAT | TERMINAL_SERVER_AWARE`, stack
  reserve 1 GiB / commit 1 MiB for the recursive compiler front end, import and IAT data directories).
- One section `.lume` at RVA `0x1000`, file offset `0x200`, read/write/execute: code, one 6-byte
  `jmp *IAT(%rip)` thunk per import, rodata (16-aligned), import directory (8-aligned: IDT, ILT, IAT,
  hint/name table, DLL names). `.bss` is the zero-filled tail (`VirtualSize > SizeOfRawData`).
- Entry point `_start`, entered with the Win64 ABI (`rsp = 8 mod 16`, arguments in `rcx`, `rdx`, `r8`,
  `r9`, 32-byte shadow space).

Imports reuse the directives of the dynamic ELF output:

```
    .need "KERNEL32.dll"            # declare a DLL
    .extern ExitProcess             # from the only declared DLL
    .need "ntdll.dll"
    .extern ntdll.dll!RtlComputeCrc32   # explicit DLL, required once two or more DLLs are declared
    ...
    call ExitProcess                # reaches the thunk (ExitProcess@plt works too)
```

Diagnostics (all `[L0001]`, nothing written): a bare `.extern` with several `.need`s, a DLL that is not
`.need`ed, a malformed `DLL!Sym`, an unresolved call target, `.kernel` input, debug directives.

The ELF output is unchanged byte for byte (the PE code is a separate path selected by `--pe`).

Tests:

- `tests/harness/lasm_gate.src` `la_pe` (Linux, `native-assembly` job): assembles two probes, checks the
  PE32+ header bytes, checks the five negative cases, and copies the probes to `build/windows-pe-probes/`.
- `.github/workflows/ci.yml` `windows-pe` job: downloads the probes and runs them on Windows.
  `pe_hello.exe` must print `hello from lasm` and exit 3 (a zeroed `.bss` word + 3); `pe_multi.exe` imports
  from `KERNEL32.dll` and `ntdll.dll`, reads its message through a `.quad` absolute address, and must print
  `123456789ab` and exit 38 (low byte of `RtlComputeCrc32(0, "123456789") = 0xCBF43926`).

Limits of part 2: lasm writes the container; the code that runs inside must already follow the Win64 ABI.
`lumec` output still uses the Linux runtime, so a Lume program does not become a working `.exe` until
part 3.

## 5. What the v1.1.0 qualification package covers on Windows

Sources read in full: `docs/certification/TOR_TOOL_OPERATIONAL_REQUIREMENTS.md`,
`docs/certification/QUALIFICATION_DOSSIER.md`, `docs/certification/RTM_TRACEABILITY_MATRIX.md`,
`docs/RELATORIO_AUDITORIA_E_CERTIFICACAO_CLAUDE_PT_BR.md`, `docs/41-safety-envelope-split-bundle.md`.

**The package does not cover Windows, and says so.** TOR section 1 states `Host / target: x86-64 Linux (ELF64,
static)` and "every other target is outside this package"; TOR section 3 states the operational environment as
"Linux on x86-64"; the dossier was generated on `Linux 6.18.33.2-microsoft-standard-WSL2 x86_64`. Every PASS in the
package is a Linux x86-64 result. None of it is false; none of it is a Windows result.

Requirement by requirement, what carries over to a native Windows host once parts 3 to 5 ship, and what needs its
own work (checked against the code, not only the documents):

| Requirement / gate | Carries over to Windows? | Why |
| --- | --- | --- |
| HLR-01 front end (LLR-LEX/PAR/TYP), HLR-02 prover and certificates (LLR-CON/PRV/CRT/CAAS/PCH), HLR-03 isolation (LLR-PUR/SEC/FFI) | Yes, same verdicts | Pure Lume computation on the source text; no OS call decides a verdict. Must still be re-run on the Windows binaries. |
| LLR-LTV-01 / LLR-LTV-02 / LLR-SEC-02/03 (`ltv`, `ltv_rt`) | Partly | They validate the x86-64 code and the 18 integer runtime helpers, which are the same instructions on Windows. The Win64 OS layer (part 3) is new trusted code that no validator covers. |
| LLR-ASM-01 (`lasm` vs GNU `as`) | Encodings yes; PE container is new | Instruction encodings are shared. The PE32+ writer (`lasm --pe`) is covered by the `la_pe` checks and the Windows run, not by the GNU `as` differential. |
| LLR-RTE-01 overflow and division by zero | Yes | `__rt_idiv` / `__rt_imod` test the divisor and the `INT64_MIN / -1` case before `idivq`; overflow uses `jo`. No signal is involved. |
| HLR-05 resource exhaustion: stack overflow | **No (part 3)** | The diagnosed stop for stack overflow is the SIGSEGV handler on an alternate stack (`__rt_stack_guard`: `sigaltstack` + `rt_sigaction`). Windows needs a vectored exception handler for `EXCEPTION_STACK_OVERFLOW` / `EXCEPTION_ACCESS_VIOLATION`; until then a stack overflow is a Windows crash, not a diagnosed stop. |
| LLR-MEM-01 heap exhaustion | Yes after part 3 | `mmap` failure is already a diagnosed stop; the Win64 layer must return `-ENOMEM` when `VirtualAlloc` fails. |
| LLR-CRY-02 OS entropy | **No (part 3)** | Entropy is read from `/dev/urandom` (`lcrypto_tls.src`). Windows needs `ProcessPrng` / `BCryptGenRandom` behind the same health checks. |
| LLR-BOOT-01 (`G-BOOT`, DDC) | To be re-established | stage 2 == stage 3 must be shown for the Windows-built compiler; the DDC of `G-AUDIT` uses `cc`/`clang`. |
| `G-DWARF-CACHE` (LLR-DBG-01) | **No** | DWARF v4 in ELF, read back with `readelf` / `addr2line`. PE executables carry no DWARF here (Windows debuggers use CodeView/PDB). |
| `G-SOAK` | **No as written** | Fault injection uses `/proc/version`, read-only sysfs, uid 0 and 64 forked instances. Needs Windows equivalents. |
| `G-PFUZZ` | Yes after part 3 | Seeds from `/dev/urandom` go through the same entropy path. |
| `G-SMT`, `G-LASM`, `G-MARCH`, `G-ENV` | Linux-hosted tools | `z3` at `/usr/bin/z3`, GNU `as`, `qemu-aarch64` / `qemu-riscv64` / `qemu-system-riscv32`, and voter commands run as `/bin/sh -c 'ulimit -s 8192; exec timeout 15 ...'` (doc 41 section 5). |
| HLR-07 safety envelope (LLR-ENV-01/02/03) | Protocol yes, channel A no | The frame protocol of doc 41 (hex words, CRC-32, stdin/stdout) is OS-independent, but channel A is `channel_a_x86_64.elf` (Linux) and the voter launches channels through `/bin/sh`. |
| HLR-09 / HLR-10 synergy chain (`G-SYNERGY`, LLR-SYN-01) | **No (part 5)** | Stage S06 builds an ELF64 with DWARF, S09 runs the split bundle under QEMU, S10 needs OS entropy. The chain has to be re-run end to end on Windows. |
| Signing key custody | Host-specific | The key lives at `/root/.lume/keys/qualification_ed25519.seed`. |

Consequence: claiming the qualification evidence "100% for Windows" requires, after parts 3 to 5, running
`lume qualify` on a Windows host with Windows equivalents for the Linux-specific probes above (or listing each one
as excluded, by name, in the TOR), and generating a separate, signed Windows evidence package. Until then the
correct statement is the one the TOR already makes: qualified evidence exists for x86-64 Linux only.

## 6. Parity rule and checklist

Owner's rule (2026-11-12): the Windows package must match the Linux one exactly: no missing function, no missing
process, no different performance. Where Windows has no equivalent, one is built; nothing is moved out of scope.

| Area (Linux implementation) | Windows equivalent | Status |
| --- | --- | --- |
| Hosted runtime syscalls (files, dirs, memory, clocks, exit, argv/envp) | `__win_syscall` on KERNEL32 | shipped in the working tree (part 3) |
| Frozen-arena paging and stack-overflow stop (SIGSEGV + sigaltstack) | vectored exception handler -> `__rt_on_segv` | shipped and verified (§6.1): frozen pages come back on first touch, also under `LUME_ARENA_COLD` + `LUME_GC_STRESS`; stack overflow prints the same message, exit 12 |
| Division faults (SIGFPE backstop) | VEH -> `__rt_on_fpe` | shipped |
| OS entropy (`/dev/urandom`) | `BCryptGenRandom` behind the same fd | shipped |
| Power management | opt out of EcoQoS power throttling at start-up (console processes are otherwise clocked down) | shipped |
| Processes: `os_run*`, `os_spawn_capture`, pipes, `waitpid`, `kill`, timeouts | `CreateProcessW`, `CreatePipe`, `WaitForSingleObject`, `TerminateProcess` | shipped (fork + execve emulated exactly) |
| `os_fork` without `execve` (both processes go on) | a real fork: the same image started, its memory and handles copied, its thread resumed at the fork (§7) | shipped; 20/20 runs of a fork + socket exchange |
| Environment for children (`os_setenv`, `os_unsetenv`, `env NAME=VALUE prog`) | the envp passed to `CreateProcessW` as a UTF-16 block | shipped |
| `io_uring` | IoRing (Windows 11) / IOCP | to build |
| Sockets (`net.src`: TCP, UDP, shutdown) | Winsock (`ws2_32.dll` from System32, loaded on first use), sockets in the fd table | shipped |
| epoll | IOCP / `WSAPoll` | to build |
| X11 frames (GUI) | Win32 windowing | to build |
| DWARF v4 (`-g`) | CodeView / PDB | to build |
| Shared memory (`os_shm_map`) | `CreateFileMapping` / `MapViewOfFile` | to build |
| Multi-worker concurrency (`lconcurrency`, concurrency gate) | Lume worker compiled for the host, started with `os_spawn_capture` (no `sh`) | shipped |
| Safety envelope voter (channel commands, channel A) | command lines run without a shell (`hio_cmdline_ict`), channel A built for the host (PE on Windows) | shipped; pipelines in a channel command need an `sh` on the PATH; QEMU channels need QEMU |
| `/bin/mkdir`, `rm`, `cp`, `mv`, `chmod`, `ls`, `pwd`, `printenv`, `test`, `env`, `date`, `uname` started by tools and gates | `compiler/stage1/hostio.src`: the same work in Lume, no process | shipped |
| `lume qualify` on a Windows host, signed Windows evidence | same batteries on Windows | part 5 |
| Mach-O output in `lasm` (claimed in the v1.0 inventory, not present) | — | to build if kept as a claim |

Measured parity (same machine, Linux under WSL2, 2026-11-12, after the EcoQoS opt-out and the memory work of §6.1).
Times inside the process come from `os_monotonic_ns`; launch times come from the same Lume launcher
(`os_run_capture_timeout`) on both systems:

| Workload | Windows | Linux |
| --- | ---: | ---: |
| `fib(32)` inside the process | 14.6-14.8 ms | 16.8-20.1 ms |
| allocation loop inside the process (`bench_inproc`) | 27.2-27.5 ms | 37.1-37.7 ms |
| collector churn, 2 GiB of short-lived cells under a 64 MiB cap | 190-198 ms | 200-245 ms |
| the same with 400 000 live strings | 52-55 ms | 61-68 ms |
| `lumec` compiling `lumec.src` (`LUME_GC=on`) | 3.36 s | 3.98 s |
| the same with `LUME_GC_STRESS=100000` | 4.39 s | 4.82 s |
| launch + run of hello | 9-12 ms | 9-13 ms |
| launch + run of `atomic_compactor_ok` | 30-49 ms | 42-55 ms |

Output of `lumec.exe` is byte-identical to the Linux `lumec` on every input tried. The first launch of a freshly built,
unsigned `.exe` takes about one second more: Windows Defender inspects it before the process starts (later launches
do not pay it). On a machine where Defender's cloud lookup fails (measured on the development machine, 2026-11-13:
`LastMAPSFailureTime` moving every minute, events 2010 and 1122), every freshly built `.exe` is held 10 s per failed
lookup, at each launch, until one lookup for that exact file succeeds; from then on the same file starts in about
20 ms. It is per file, not per launcher and not per content: the same layer runs in 16-25 ms once cleared. A Dev
Drive does not change it; a folder exclusion or signed executables would. Take timings on files that are already
cleared, or inside the program with `os_monotonic_ns`.

### 6.1 Memory system verification (2026-11-12)

Every program of `tests/memory/` plus `arena_mem.src` and `compiler_perceus_ok.src` was compiled for both systems by
the same `lumec` (`--win64` + `lasm --pe` for Windows), run plain and in 15 environment cases (`LUME_GC_STRESS` 3/5/7,
`LUME_ARENA_COLD=1` alone and with `LUME_GC_STRESS=3`, `LUME_HEAP_CAP` 16m/32m/64m/bogus, `LUME_GC=off|bogus`), and
stdout, stderr and exit status were compared byte by byte (scripts in `build/windows-native/mem/`):

- 62 of 62 runs agree in exit status, stdout and stderr, except one number: the peak RSS that `arena_mem` prints
  (`vmhwm_kb`, 23 424 on Linux and 27 160 on Windows; both pass the 23 000 threshold). Measured cause (2026-11-13):
  - Windows charges every process about 3.1 MiB of resident memory for the system DLLs it maps (shared with all
    processes): a PE that only calls `Sleep` has 3 124 KiB resident, 244 KiB private. An idle Lume program has
    3 260 KiB resident, 300 KiB private: 136 KiB (56 KiB private) above that floor. On Linux the same program has
    52 KiB resident.
  - Growth with data is the same: 24 bytes per cons cell on both (2 496 KiB for 100 000 cells on Windows; Linux
    reports 1 496 KiB there because the kernel updates its RSS counter in batches, and 23 512 KiB for 1 000 000).
  - A defect found and fixed on the way: every Windows process committed 6 164 KiB at start (the 4 MiB argv block
    and 1 MiB of stack committed up front). The argv block is now reserved and committed on first touch (three
    64 KiB parts up front) and the image asks for 64 KiB of stack commit: 1 300 KiB.
- Every `.expected` file of `tests/memory/` matches the Windows output; every check of the memory section of
  `bootstrap/lume0/tests/run.sh` holds (heap cap exit 12 with the cap in the message, invalid environment exit 12,
  live-arena limit, arena budget, no-pin, directory race, stack overflow).
- The compactor (`atomic_compactor_ok`) holds at every level, and its output without the `_bytes` lines is the same
  plain, with `LUME_GC_STRESS=7`, with `LUME_ARENA_COLD=1`, and with both: level 3 freezes arena pages and brings them
  back through the vectored exception handler.
- `lume test` with the native `lume.exe` on `gc_ok.src` (11 tests), `arena_ok.src` (8) and `perceus_ok.src` gives the
  same bytes as on Linux.
- The collector gate (`tests/harness/gc_gate.src`): `lumec.exe` compiling `lumec.src` with `LUME_GC=on` and with
  `LUME_GC_STRESS=100000` writes the same 6 509 683-byte assembly as Linux in both modes
  (SHA-256 `97b4fc9c506d32591ba2f2f997e05f61205bcb806657a0e17ca859c67d67b2c1`).
- Compile-time memory diagnostics (`C0009` secret compression, `V0002` cycle budget) are identical for both targets.
  `freestanding_values_ok` is a `@freestanding` image: it has no hosted form on any system, and `--win64` says so.

Memory semantics of the Win64 layer, each one matching Linux:

- `mmap` with `MAP_NORESERVE` and read/write protection (the collector's mark stack, the compactor's page buffers)
  only reserves; the vectored exception handler commits 64 KiB on first touch, and `read`/`write` commit the part of
  a user buffer inside such a reservation before the kernel sees it (Windows reports `ERROR_NOACCESS` instead of
  faulting there). Without this every collection committed `nchunks * 32 KiB` at once.
- `PROT_READ` and `PROT_READ|PROT_EXEC` become `PAGE_READONLY` and `PAGE_EXECUTE_READ`; nothing is silently writable.
- `madvise(MADV_DONTNEED)` decommits and recommits, so a released chunk reads zero, as on Linux. If the recommit
  fails (commit limit), the process stops with the runtime's out-of-memory message and status 12, not with an access
  violation later.
- Stack: 4 GiB reserve, as the Linux `setrlimit` target. Windows grows the stack one guard page at a time, so
  `lumec --win64` turns every frame allocation of 4 KiB or more into page-by-page steps that touch each page (what
  `__chkstk` does); a 9.6 KiB frame recursing 300 deep gives the same result on both systems.
- The exception handler handles access violations only when they come from this image's code or touch a lazily
  committed reservation; one raised inside a system DLL goes on to that DLL's own handler. An illegal instruction is
  left to the system, so the process ends with `STATUS_ILLEGAL_INSTRUCTION`, which `wait4` reports as signal 4, as
  Linux reports `SIGILL`.
- File descriptors are small integers from a table, as on Linux: 0-2 are the standard handles and a new descriptor
  takes the lowest free number from 3 (`EMFILE` past 1024). Console input in cooked mode loses its `\r`, so a line
  read from a terminal ends in `\n` as on Linux.

A child of `os_fork` is a separate process with its own copy of the heap (§7), so its collector and the parent's
never share memory.

## 7. Parts 3 and 4 as built

`lumec --win64` keeps the Linux program and makes three textual changes (`lw_win64` in `lume/07_driver.src`):
`runtime_hosted_init` becomes `rt_win64_init`, every `syscall` becomes `call __win_syscall`, and the Win64 layer
(`rt_win64_imports` + `rt_win64_layer` in `runtime_core.lume`) is appended; `.Lrt_platform` becomes `"windows"`.
`lasm --pe` writes the result. The Linux runtime and code generator are reused unchanged.

Design decisions:

- **Linux syscall ABI on KERNEL32.** `__win_syscall` takes the Linux number and registers and returns the Linux
  result (`-errno` on error), clobbering only `rax`, `rcx`, `r11`. Implemented: read, write, open, close, lseek,
  mmap (anonymous), mprotect, munmap, madvise, exit, exit_group, flock, fsync, getcwd, chdir, mkdir, rmdir, unlink,
  rename, chmod, getdents64, getpid, uname, clock_gettime (real time, monotonic, process and thread CPU time),
  nanosleep (high-resolution waitable timer), getrusage, getrlimit, pipe, dup2, fork/vfork, execve, wait4, kill,
  socket, connect, accept, bind, listen, setsockopt, sendto, recvfrom, shutdown; rt_sigaction / sigaltstack /
  setrlimit are no-ops because faults arrive through the vectored exception handler. Any other number returns
  `-ENOSYS`.
- **POSIX view of paths.** `fs_current_dir()` and `argv[0]` are `/c/Users/...`; on open, `/x/...` is `X:/...`,
  `/tmp/...` is the Windows temporary directory, `/dev/null` is `NUL`, `/dev/stdin|stdout|stderr` are fds 0-2,
  `/dev/urandom` is `BCryptGenRandom`. Lume code written for Linux runs unchanged, including the repository test
  that requires `fs_current_dir()` to start with `/`.
- **Processes.** The `os_run*` builtins (fork + open/dup2 + execve) use vfork semantics: the "child" runs inside
  the process until `execve`, then `CreateProcessW` with the redirected handles and the envp, and the parent resumes
  after its `fork` with the real pid; this is exact and costs no copy. `os_fork` (rdi = 'FORK', which Linux ignores)
  is a real fork: the parent starts its own image with `LUME_FORK=1`; the child sets up its exception handler and
  waits in a loop; the parent suspends it, copies every writable region of the image (the runtime's and the layer's
  data), every region the layer mapped (a registry kept by mmap/munmap: the collector heap, arenas, buffers, argv) and
  the used stack, duplicates the file, pipe and socket handles of the fd table, and points the child's thread at
  `.Lws_fork_resume` on a copy of its own system-call frame; the child clears what belongs to the parent alone (its
  children, timer, DLL entry points), restarts Winsock when it holds sockets, puts a guard page under its stack and
  returns 0. The image has a fixed base and the layer maps top-down, so every address is free in the child. A child
  gets the stack limit the program started with, not the 4 GiB the runtime raises for itself. Program lookup tries
  `<path>.exe` first, then `<path>`.
- **Sockets.** Winsock from System32, loaded on first use (no import entry: the image imports only KERNEL32). A
  socket is a descriptor like any other: read, write and close are recv, send and closesocket. `SO_REUSEADDR` is
  Linux's default rebinding rule on Windows and succeeds without a change (Winsock's own `SO_REUSEADDR` would let
  another socket steal the port). Winsock errors become Linux errno values.
- **Faults.** `__win_veh` passes access violations, stack overflows and privileged-instruction faults to
  `__rt_on_segv` with a Linux-shaped siginfo/ucontext (frozen-arena paging resumes; stack overflow prints the same
  message and exits 12), and integer division faults to `__rt_on_fpe`.
- **Power throttling.** Windows 11 clocks down console processes without a visible window (EcoQoS). The start-up
  opts out (`SetProcessInformation(ProcessPowerThrottling)`); without it a compute-bound program ran 3-7 times slower.
- **W^X image.** `.text` read/execute, `.rdata` read only, `.bss` read/write.

New builtins, identical on both systems, so the driver's build path no longer starts `/bin/cp`, `/bin/mv`,
`/bin/rm` or `/bin/chmod`, and on Windows it changes directory with `fs_chdir` instead of `/bin/sh -c 'cd ...'`
(tools and gates do the remaining `/bin/*` work through `hostio.src`; external reference programs such as z3 or QEMU
are looked up on the PATH): `os_platform()` (`"linux"` / `"windows"`), `fs_chdir(path)`,
`fs_copy(src, dst)` (binary-safe, 64 KiB mapped buffer), `fs_rename(src, dst)` (replaces, like POSIX rename),
`fs_make_executable(path)` (mode 0755 on Linux; on Windows the extension decides, so it checks the file exists),
`fs_chmod(path, mode)` (on Windows the owner write bit is the read-only attribute, as the C runtime's `_chmod`),
`fs_rmdir(path)` (an empty directory; `fs_remove` still rejects a directory), `os_getenv(name)`, `os_setenv(name, value)` and `os_unsetenv(name)` (they hold
for every child started afterwards), `os_unix_time()`, `os_uname_field(i)` (`Windows_NT`, the version from the
shared user data page, `x86_64`), `os_spawn_capture(prog, args, out, err)` (start without waiting; `os_waitpid_status`
waits). `lasm` also encodes `call *%reg` and `jmp *%reg` (checked against GNU as in `lasm_gate`, family `indirect`).

Measured differences that remain, and why:

| Item | Linux | Windows | Reason |
| --- | --- | --- | --- |
| `os_last_child_maxrss_kb` of a short child | 0 | peak working set | the WSL2 kernel reports `ru_maxrss=0` for that child (seen with `strace`); Windows reports the real peak |
| `fs_write_sync("/dev/stdout", ...)` with stdout redirected to a file | truncates the file (`O_TRUNC` on the redirect target) | appends to the stream | `/dev/stdout` is fd 1 on Windows |
| `fork` cost | copy-on-write pages | the used memory is copied once | Windows has no copy-on-write fork for a program; `os_run*` (fork + exec) copies nothing |
| a channel command with shell syntax (pipe, redirection) | `/bin/sh` | the `sh` found on the PATH (Git for Windows ships one) | plain command lines run without any shell on both systems |

## 8. Parts 3–5 (original plan)

- **Runtime.** A second OS layer in `runtime_core.lume` for Win64: each Linux `syscall` site gets a
  `KERNEL32` equivalent called through the import thunks, with the Win64 calling convention and shadow
  space at each call. The heap reservation becomes `VirtualAlloc(MEM_RESERVE)` + `MEM_COMMIT` as it grows,
  and chunk release becomes `VirtualFree(MEM_DECOMMIT)`, which keeps the "a free chunk reads as zero"
  invariant. Both assemblers (`lasm` and `lume0 asm`) must accept every instruction (see `AGENTS.md`).
  Two items from section 5 belong here: a vectored exception handler that turns `EXCEPTION_STACK_OVERFLOW` /
  `EXCEPTION_ACCESS_VIOLATION` into the same diagnosed stop as the Linux SIGSEGV handler, and OS entropy from
  `ProcessPrng` / `BCryptGenRandom` behind the existing health checks.
- **Processes.** `os_run`, `os_run_capture`, `os_run_input*`, `os_run_timeout*` on `CreateProcessW` with
  redirected handles and `WaitForSingleObject` timeouts; `fork`-only builtins (`os_fork`, `os_pipe_*`,
  `io_uring`, `os_shm_map`) report a named diagnostic on Windows instead of a wrong result.
- **Toolchain build and release.** `lume build --target x86_64-windows-pe` on the full Lume-Core goes
  through `lumec` + Win64 runtime + `lasm --pe`; the Windows archive ships the native `.exe` tools, and
  release gate C is replaced by the same parity checks the Linux archive passes.

## 9. Remaining work to full parity (status 2026-11-13)

Owner's goal: Lume on Windows identical to Linux, every function, module and sovereign domain included. Sources of
this assessment: the audits in `build/windows-native/audit/` (122-domain map, processor and memory audit, the six
reports on the external dossier and catalogue, `PLANO_DE_CORRECOES.md`) and the test runs of §6.

**Identical today (about 80-85 % of the toolchain).** The whole compiler (check, test, prove, fmt, build, run; the
output of `lumec.exe` is byte-identical); the memory system (§6.1); files, directories, processes, a real fork,
environment for children, sockets, clocks; every pure-Lume module, which covers the 63 domains with no host
dependency and the 29 whose only dependency was a fixed host path (now `hostio.src` helpers). On the 25 core test
files (about 900 tests) the only Windows/Linux difference left was the fork + socket TLS loopback test of `net.src`,
which the real fork and Winsock now pass in isolation (20/20); the full re-run is pending.

**Remaining, smallest first:**

| # | Item | Size |
| --- | --- | --- |
| 1 | Stack limit for one child (`soak_battle_gate` uses `ulimit -s`); self `kill` with the exact signal (done, to test) | small |
| 2 | Shared memory: `os_shm_map` on `CreateFileMapping` / `MapViewOfFile` | small |
| 3 | Native `lume.exe` resolving `use` of a module outside the file's directory; `ld_root` pointing at the install tree on Windows | small |
| 4 | Finish the gates that build and run native programs: tv, tv_rt, soak, safety_envelope, crypto, cert_source, synergy, smt_cert, lcaas_scale (`/usr/bin/time`) | medium |
| 5 | epoll (`async_rt`, domain #71) on IOCP / `WSAPoll` | medium |
| 6 | io_uring (domain #105) on IoRing (Windows 11) | medium |
| 7 | C FFI with the Win64 ABI (interop, `--emit-c-header`, `--module` / `--link`) | medium |
| 8 | `scripts/lume_legacy.sh` routes (pkg `~publish` / `~audit`, `.lume` surfaces, the `.wasm` target, `fmt` outside `.src`, `self` with `LUME_HOME`): rewrite in Lume (POSIX sh today) | large |
| 9 | DWARF to CodeView / PDB (`-g`, `dwarf_cache_gate`, native witnesses of `lproof_cache`) | large |
| 10 | GUI: `gui.src` speaks the X11 protocol; Windows needs Win32 windowing | large |
| 11 | `curl`, `git`, `7z` replaced by Lume: an HTTP client over real TLS 1.3 (the Lume TLS is a sans-IO state machine today), `git ls-files` and zip are medium, 7z is large | large |
| 12 | `lume qualify` on a Windows host: the 21 gates, signed evidence, regenerated `MANIFEST.sha256` | medium, after 4 and 9 |

Items 1-7 close parity for everything that runs (runtime, tools, tests); items 8-12 are each the size of the real
fork or larger. Order of work: 1 to 12, unless the owner sets another priority.

**Decisions that are not about Windows:**

- The Stage-0 seed (C), DDC, `make test` / `asan` need a C compiler on every host; Windows has `lume0.exe`. The
  gates that compare against GCC, clang, GNU as, QEMU, z3 or python3 use them as external oracles on purpose; they
  are looked up on the PATH and run when installed.
- The 39 model-only domains (IAPWS-IF97, ASME B31G, Raft, the blockchain engine's "HMAC", and the others listed in
  `build/windows-native/audit/domains_122_map.md`) already behave the same on both systems; making them real
  computations improves Lume itself and is separate from Windows parity.
- The false claims found in the documentation and in the external catalogue (listed in
  `build/windows-native/audit/PLANO_DE_CORRECOES.md` §6) are to be corrected in the texts.
