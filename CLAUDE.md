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
- Golden rule (2026-11-16): the runtime itself must be 100 % Lume source too. Today runtime_core.lume holds x86
  assembly text and the Windows layer is win64_layer.s; both are to be migrated to Lume (freestanding subset +
  minimal compiler intrinsics). Never add new runtime code as hand-written asm when it can be Lume.
- Never leave a bug, a correction or an improvement behind before moving to the next step.
- A measured Windows/Linux gap (time or memory) is a defect to fix, not a difference to document.
- "Tested" means the full universe, not a sample: 111 files with `fn test_` (`mem/tests_all.txt`), 205 programs
  (`mem/progs_all.txt`), the memory battery, then the gates and the 114 CLI commands — on both systems, compared.

## State on 2026-11-18 (newest first)

- RULE (owner, inviolable): the repository is 100 % Lume. 192 non-Lume helper files under build/windows-native
  (Perl, shell, PowerShell, Python) had been force-added and showed GitHub's language bar as "Perl 99%"; removed in
  cf37ed6 (kept on disk). Never `git add -f` under build/; check `git diff --cached --name-only` before each commit.
- CI repair round (main was a0c16d7, 7 of 17 jobs red): seed `.byte 0` -> `.asciz ""` (os_getenv of an unset
  variable), runtime split rt_lume_core / rt_lume_os (kernels get no fs code; rt_int moved to rt_text), the three
  gates get LUME_BIN_DIR=build/bin, runtime-refusal tests through `dyn(x: any)`, `any` accepted both ways
  (06_typecheck tcompat), lasm --shared section headers, hostio `env -C` and PATH lookup of bare names, fs_copy keeps
  the source mode, lcaas without `{r with}` (the Stage-0 checker on macOS has none), driver never fails silently.
- Performance for LumeDesk (repro38 follow-up): GC keeps freed chunks mapped and zeroed up to the collection limit
  (alloc 20 -> 8 ns, sys time 0.16 -> 0.02 s); field reads through an inline per-field cache (__ic_NAME, slow path
  __rt_recget_ic in rt_text.src). The 64 MiB minimum collection limit is still above the agent's 15 MB target.
  Next: SIMD (lasm packed encodings + --raw vector intrinsics), unboxed loops, --raw leaf mode with cold calls (2b).

- v1.2.0 published (release, main = branch 75e880f). The tag's workflows failed before publishing (assets intact):
  the seed could not parse a parameter named `as` (renamed in 05_codegen / lcrypto_tls; fresh-clone seed bootstrap
  verified in WSL) and release.yml checked "lume 1.1.0" (now the tag's version). Not pushed yet.
- LumeDesk repro37 (stages 9-10): winsys gained displays (Per-Monitor-V2), DXGI Desktop Duplication in Lume over COM
  vtables + GDI fallback, cursor shape, SendInput, key state, SendSAS, a viewer window without callbacks, and the
  WH_KEYBOARD_LL hook (the only asm: layer pseudo call 1016, a 64-event ring). 32 tests, Linux and Windows.
- LumeDesk repro38 (loop speed): buf_get/buf_set inline fast path and literal div/mod in 05_codegen (5x); colour
  conversion builtins buf_bgra_to_i420 / buf_i420_to_bgra in rt/rt_video.src (~10-15 ms per 1080p frame). NEXT for
  the 16 ms budget: SIMD (lasm packed-integer encodings + --raw vector intrinsics) and type-directed unboxed loops.
  Register locals for ordinary code were tried and reverted: see memory runtime-asm-clobbers-callee-saved.
- lume run / lume test scratch binaries are `.exe` on Windows (D3D kills extensionless images at exit).

## Runtime in Lume: state on 2026-11-16

- Lume sources of the runtime: `compiler/stage1/rt/*.src`, compiled by `lumec --raw` (freestanding words; intrinsics
  load8/32/64, store8/32/64, bit_*, sys_call, sym_addr("label"); any number of parameters/arguments (the 7th on go on
  the stack, never in leaf mode); operands are computed left to right as in ordinary Lume (since 2026-11-21); functions
  may span lines (`lume fmt` lays them out one `let` per line); gen_runtime refuses a name the runtime does not define). `gen_runtime.src` writes
  `runtime_lume.lume`: `rt_lume()` (rt_text, rt_fs: in every program) and `rt_lume_crypto()` (rt_x25519, rt_ed25519:
  only when a program names a crypto_ builtin, through rt_crypto/has_crypto).
- Migrated so far (asm removed from runtime_core): strlen, streq, __rt_nofield_text and 28 fs_*/os_*/io_* builtins;
  batch 5 (fs_*_private, os_keychain_*) is written in rt_fs.src, not yet cut from runtime_core. Left: about 385
  global labels (74 public builtins). Hot ones (buf_*, ord_at, slice, count, chr, addv...) wait for two --raw
  improvements: save only the registers a function uses, and inline mkint / __rt_uint.
- Cutting asm: NEVER by hand or by "next label" regexes (that once crossed fn boundaries and dropped three fn
  headers). Run `python build/windows-native/mem/rebuild_core.py build/windows-native/mem/rc_head.lume
  compiler/stage1/runtime_core.lume`: it rebuilds from the commit's file and cuts, inside each fn line, every routine
  rt/*.src defines (refresh rc_head.lume from `git show HEAD:...` after each commit).
- A routine whose Lume needs a primitive the installed lumec lacks: two bootstraps (strip it from rt/*.src, rebuild_core,
  gen_runtime, bootstrap; restore, rebuild_core, gen_runtime, bootstrap). A new builtin: add its row to
  compiler/stage1/builtins_table.src, run tests/harness/builtins_gate.src with `@mode gen` (rewrites the name_flow,
  06b_phase3 and lcaas lists), define, document and call it in builtins_regress_ok; rebuild lcaas and lcert too.
- RUNTIME QUEUE, executed in this order without skipping (owner: "nada fica pra depois"; tick each when committed):
  1. [x] rt_io.src (read, readall) cut from runtime_core (commit fc5b13d; Linux battery clean).
  2. [x] (fc5b13d + next commit) first five values in rbx/r12-r15; immediates/registers as direct operands; if on
     a comparison jumps straight to else; bit ops with immediates (ord_at draft 163 -> 108 instructions). Was:
     --raw register allocation: keep lets/params in registers (callee-saved r12-r15/rbx saved once), not
     rbp slots, so hot builtins are not slower than the asm (measure X25519 and a buf_set loop before/after).
  2b.[x] (2026-11-20: up to 3 calls in a leaf, tail calls as jumps, cold `__rt_*` branches laid out last, code
     aligned to 32 bytes) leaf mode done (no frame, params in their registers; X25519 800 -> 550 us). Left in 2b: a call on a
     cold path (mkint's boxed case, __rt_not_str) must not disqualify a leaf: spill around it. Was: --raw leaf routines: a function whose common path makes no call keeps its parameters in the incoming
     registers (rdi, rsi, rdx, r8, r9; the 4th moves off rcx) and needs no frame; calls only on cold paths
     (__rt_not_str, mkint's boxed case) spill around themselves. Target: ord_at/buf_get within 1.5x of the asm.
  3. [~] (done 2026-11-20: buf_*, ord, ord_at, at, chr, count, slice, slicen, toint, str, strni, utf8_chr, wch,
     wint, print_int, emit, flush, __rt_write_fd1; left: printval/showval and the rest of the list) hot builtins
     to Lume after (2) and (2b): buf_new/len/get/set/copy/slice/from_str/to_str, ord, ord_at, chr, count,
     at, slice, slicen, str, strni, toint, utf8_chr, emit/flush/wch/wstr/wint/print_int, printval/showval.
  4. [ ] --raw stack intrinsics (read/set %rsp/%rbp, jump) -> ctfail, __lume_try_begin/end/msg, __rt_die*.
  5. [ ] --raw f64 intrinsics (SSE2 movq/addsd/mulsd/divsd/sqrtsd/cvt...) -> f64_* builtins and rt_f64.
  6. [ ] value-model builtins (addv, cmpv*, eqv*, mkint/mkstr/mklist/mkarray, lidx/lset/recget, alloc) and the GC
     (__gc_*), then crypto_sha256_blocks/chacha20_xor/poly1305 (with (2) they can match the asm).
  7. [ ] Windows layer win64_layer.s to Lume over the generic Win32 call (pseudo calls 1010 / 1011), routine by
     routine, keeping the syscall numbers.
  After each item: both batteries compared, commit, install /root/.lume, update C:\Lume.
- New crypto (lcrypto_tls): AES-128/256 + GCM, ECDSA P-256 (verify/sign RFC 6979), X25519 and Ed25519 point math in
  Lume runtime routines; tests crypto_{aes,p256,x25519,ed25519}_ok.src. Module fixes: lmod segment aliases, driver keeps
  the written name when a module gets a canonical name (tests/namespaces/same_seg_ok.src, rel/a/rel_ok.src).

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

## Progress 2026-11-13 late night (newest first)

- '+' never converts (T0604) in all code (tpl_* pass in 06_typecheck + runtime refusal in addv); closure dispatcher
  __closure_call_N gets no fixed type (seq_loop with str acc + any annotation); seq_loop_inv + lcaas loop proofs.
- lcert: range facts (bit_and with a constant mask, ct_eq), non-linear antecedents dropped, byte masks as low(a, m)
  variables: lcrypto_tls certifies 48/48. ltv_rt executes the f64/decimal hooks (.Lrt_anyf/.Lrt_anyd ...) it meets.
- codegen: bit_and/or/xor/shl/shr inline fast path for two small ints (3.5x); lcrypto_tls gained the string API
  lcs_* (SHA-256 12 MB/s, AEAD 13 MB/s, memory of the output only); crypto_str_ok.src.
- Memory is short on this machine: run builds and batteries in foreground batches (tb_*.lst, wb_*.lst, test parts),
  never one long background job while idle (the session reaper kills it).

## Progress 2026-11-13 night (newest first)

- LumeDesk developer's list, all on Linux (commit 39a9cbb + the f64 commit): seq.src (repetition without recursion),
  module namespaces (`use X as Y`, `X.NAME`, a name in two modules kept apart as NAME__module, ambiguity is an error
  with file:line:col), error locations everywhere (spans skip comments/strings now), fmt nested match, effect docs.
- f64: lasm encodes scalar SSE2 and x87 (lasm_gate family "float", 23 families byte-identical to GNU as); kind-17
  cells in runtime_core (rt_f64), hooks in addv/__rt_sub/__rt_mul/__rt_div/cmpv/eqv/str/showval. A program gets
  rt_f64 only when it calls an f64 builtin (has_f64), else rt_f64_stub: the seed `lume0 asm` (frozen C) assembles the
  stage-0 lcli and knows no xmm/x87. data_asmgen.lume (the seed's code generator) uses the stubs too.
- Decimals: print/str write 1.5, 0.10 (rt_dec, always, seed-safe); a decimal through a parameter/list/record goes to
  the sugar's __lume_dyn_* (decimal_add and friends) when the program has them (has_dec), else rt_dec_dyn_stub.
  `__lume_` names are runtime-reserved: compiler helpers must be listed in name_flow nf_comp_helper.
- Next: Linux battery (th_l_0x, ph_l_0x), then the Windows tree with all of it, Windows batteries, compare,
  update C:\Lume, commit; tell the owner the message for the LumeDesk developer.

## Progress 2026-11-13 evening (newest first)

- Both trees rebuilt complete after the low-memory stop (mem/inst_part.sh, batches; drop the WSL page cache between
  batches when memory is short: `echo 3 > /proc/sys/vm/drop_caches`). Run long batteries in the 6 parts
  (tests_part_0x, progs_part_0x) so each fits a 10-minute foreground call, then merge into ta_* / pr_*.
- Tests, full universe, new trees: Windows = Linux test by test (1773 passed, 15 failed on both; the 15 are the four
  precondition files, which pass 3/7/13/13 on both with precond_*.{sh,ps1}; sidecar 127 on both). Linux programs
  re-run (pr_l): 87 exit 0, 117 exit 3, 1 timeout (ledger_server). Windows programs re-run in progress (pr_w_0x).
- `lume run` on an @freestanding kernel: same message and exit 3 on both (commit 350b68c).
- The owner uses the native Windows toolchain installed in C:\Lume (native installer). After every tested step
  rebuilt into inst/bin run `mem/update_install.ps1` and tell him. Never touch C:\Users\Ricardo.Bueno\LUMEDESK. Owner
  authorization (2026-11-18): after a tested step, install with native_installer into /root/.lume (the LumeDesk
  developer's WSL toolchain) and C:\Users\Ricardo.Bueno\.lume; never write there by other means (tests run in a
  sandboxed home). The user PATH still resolves `lume` to the WSL release: change it only on his order.
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
