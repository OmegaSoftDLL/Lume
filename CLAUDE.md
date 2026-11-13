# CLAUDE.md — Lume

Read **`AGENTS.md`** first (rules of the repository), then this file (where the current work stands).
Converse with the owner in Portuguese (pt-BR); write code, docs, comments and commits in English.

## Current work: native Windows toolchain

Goal set by the owner: Lume on Windows identical to Linux or better — every function, module and domain, same
outputs, performance never below Linux — and only then start the LumeDesk project (`C:\Users\Ricardo.Bueno\LUMEDESK`).

- Branch: `windows-native-toolchain`, local commits only. **Never push or publish without the owner's explicit
  order.** Commit locally at the end of each closed step.
- This checkout (`L:\lume`, a Dev Drive) is the working copy since 2026-11-13. `C:\Users\Ricardo.Bueno\lume` is the
  older copy (remote `copia-c`); `origin` is GitHub.
- Design, status and the remaining work: `docs/42-windows-native-toolchain.md` (§6 parity table, §6.1 memory,
  §7 design, **§9 the 12 remaining items, smallest first**).
- Step-by-step tracker and the audit reports (Portuguese): `build/windows-native/audit/PLANO_DE_CORRECOES.md`.

## Rules the owner added (also in AGENTS.md)

- Lume generates Lume, 100 % Lume, for everything and every system. Whatever Windows lacks is written in Lume.
- Never leave a bug, a correction or an improvement behind before moving to the next step.
- A measured Windows/Linux gap (time or memory) is a defect to fix, not a difference to document.
- "Tested" means the full universe, not a sample: 111 files with `fn test_` (`mem/tests_all.txt`), 205 programs
  (`mem/progs_all.txt`), the memory battery, then the gates and the 114 CLI commands — on both systems, compared.

## How to build and test

Everything lives in `build/windows-native/` (git-ignored; the sources there were added with `git add -f`).

- Layer source: `win64_layer.s`. `sync_win64_layer.src` turns it into `rt_win64_imports` / `rt_win64_layer` inside
  `compiler/stage1/runtime_core.lume`. Edit the `.s` (by hand or with a small perl script), never the generated text.
- `rebuild_all.sh` (run inside WSL): rebuilds `lumec` / `lasm`, the Windows test programs (`t/*.src` -> `t/*.exe`)
  and both tool trees: `inst/bin` (Windows `.exe`) and `instl/bin` (Linux). Then run `link_trees_linux.sh` and create
  the Windows junctions (`inst\compiler\stage1`, `inst\stdlib`) so `use` finds the modules, as an install does.
- Linux side: `mem/full_linux.sh` (tests + programs), `mem/mem_all_linux.sh` (memory battery).
- Windows side (PowerShell): `mem/run_windows.ps1` (memory battery), `mem/tests_windows.ps1 -List tests_all.txt -Out ta_w`,
  `mem/progs_windows.ps1`, `mem/osrun_windows.ps1`. Compare the result directories byte by byte.
- Never run the Linux and the Windows test runs at the same time on this checkout: tests use fixed-name probe files.

## Traps already paid for

- Call WSL from Git Bash as `MSYS_NO_PATHCONV=1 wsl -d Ubuntu -u root -- bash /mnt/l/lume/...script.sh`; an inline
  command with `$` is mangled. In WSL the drive needs `montar-l` (or `mount -t drvfs L: /mnt/l -o metadata`).
- After a reboot the Dev Drive is mounted by the scheduled task "Lume - montar Dev Drive"
  (`C:\DevDrive\montar_lume.ps1`); by hand: `Mount-DiskImage C:\DevDrive\lume.vhdx`.
- Text with backslashes: write it with a perl script and `chr(92)`, or with the editor tool; shell heredocs and perl
  `\h`, `\b` have corrupted sources here.
- `while read` loops that start a program reading stdin need `< /dev/null`.
- PowerShell variables are case-insensitive (`$P` and `$p` are one variable); `"$p.s"` is a property access.
- Defender on this machine holds every newly built `.exe` about 10 s per launch until its cloud lookup for that file
  succeeds (per file). It is not a Lume defect, exclusions cannot be set locally, and the Dev Drive does not change it.
  Do not rebuild probe executables needlessly, and take timings on cleared files or with `os_monotonic_ns`.
- `lume` on this machine from PowerShell is the released toolchain inside WSL, not the port; the port is
  `build\windows-native\inst\bin\lume.exe`.

## Progress 2026-11-13 evening (newest first)

- Both trees rebuilt complete after the low-memory stop (mem/inst_part.sh, batches; drop the WSL page cache between
  batches when memory is short: `echo 3 > /proc/sys/vm/drop_caches`). Run long batteries in the 6 parts
  (tests_part_0x, progs_part_0x) so each fits a 10-minute foreground call, then merge into ta_* / pr_*.
- Tests, full universe, new trees: Windows = Linux test by test (1773 passed, 15 failed on both; the 15 are the four
  precondition files, which pass 3/7/13/13 on both with precond_*.{sh,ps1}; sidecar 127 on both). Linux programs
  re-run (pr_l): 87 exit 0, 117 exit 3, 1 timeout (ledger_server). Windows programs re-run in progress (pr_w_0x).
- `lume run` on an @freestanding kernel: same message and exit 3 on both (commit 350b68c).
- The owner uses the native Windows toolchain installed in C:\Lume (native installer). After every tested step
  rebuilt into inst/bin run `mem/update_install.ps1` and tell him. Never touch C:\Users\Ricardo.Bueno\LUMEDESK or
  install over ~/.lume. The user PATH still resolves `lume` to the WSL release: change it only on his order.
- Told the owner: macOS targets are only the verified-core subset (write/exit syscalls); a LumeDesk for macOS needs a
  Darwin runtime layer like the Win64 one. He has not decided yet whether to add it to §9.
- Next: compare pr_w with pr_l, then the 30 gates (mem/gates_*.{sh,ps1}; six still call /bin/sh), then the 114 CLI
  commands, then §9 items 10 (Win32 GUI) and 11 (TLS over sockets) - the two the LumeDesk needs most.

## Progress 2026-11-13 afternoon (newest first; details in the commit messages and doc 42 §9)

- Done and committed: §9 items 2 (os_shm_map), 3 (native installer), 5 (epoll), 6 (io_uring), 7 (C FFI, Win64 ABI,
  --link, ld.so-style binding), self-kill of item 1; test runs isolated from the real home (HOME / USERPROFILE /
  LUME_WIN_HOME / LUME_SYSTEM_VAULT sandbox in every runner) after a test overwrote ~/.lume sanctuary files (restored
  from gen_4081); tests/registry/gate.src expectation fixed; precond runners (precond_*.{sh,ps1}).
- Coverage with the 11:31 trees: 111 test files identical on both systems (sidecar now 127 on both with the new
  driver); 205 programs identical except the two @freestanding kernels.
- Not committed yet: lume_driver.src `ld_is_freestanding` (lume run refuses a bare-metal kernel with a message on
  both systems) - needs the rebuild, then both batteries again.
- The rebuild of 12:13 was stopped by low memory: build/windows-native/lumec and lasm are new, inst/bin is a MIX of
  new and old tools, instl/bin is from 11:31. Run mem/rebuild_isolated.sh to completion before any battery.
- Next: rebuild, Linux then Windows batteries (tests, precond, programs), then gates (mem/gates_*.{sh,ps1};
  six gates still call /bin/sh), then the 114 CLI commands.

## State when this file was written (2026-11-13 ~10:00)

Done and tested on both systems: `lumec --win64`, `lasm --pe`, the Win64 layer (fd table, lazy memory, VEH, real
fork, Winsock, envp for children, uname, clocks), the new builtins, `hostio.src`, the 13 defects of the audits, the
memory battery (62/62 identical), a 24-file test sample and `net.src`.

Open in the current step, in order:

1. Full coverage. Linux is done on this checkout (`mem/ta_l`, `mem/pr_l`, 2026-11-13 ~10:20): 1769 passed, 16
   failed, 6 files not zero — `fs_path_exists_ok` and `fs_read_byte_ok` (paths relative to `bootstrap/lume0/tests`:
   run them from there, as `run.sh` does), `os_run_ok` and `process_ok` (need the probes built first; `os_run_ok` is
   13/13 on Linux with them), `examples/interop/sidecar/host.lume` (needs the example's C library built), and
   `tests/registry/gate.src` (`test_replace_once_does_not_duplicate_text` fails with the released toolchain too: an
   old defect, to fix). Programs: 88 exit 0, 114 exit 3 (mostly negative cases), 2 exit 127 and 1 timeout to look at.
   Next: the same on Windows (`tests_windows.ps1 -List tests_all.txt -Out ta_w`, `progs_windows.ps1`), compare with
   the Linux directories file by file, fix every difference, then set up the preconditions and run those files too.
2. `os_run_ok` on Windows: 11/13; the two failures give a probe 1 s and Defender holds it longer — reconfirm.
3. `lasm_gate` with the new `indirect` family (`call *%reg`, `jmp *%reg`), and the self-`kill` signal test.
4. Gates (~35) and the 114 CLI commands on Windows.
5. Then §9 of doc 42. For LumeDesk the items that matter most are epoll, real TLS over sockets and the Win32 GUI.
