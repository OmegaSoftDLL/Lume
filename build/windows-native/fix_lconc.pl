use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
# 1. shell script builders -> process spawn + wait
my $s = index($t, 'fn lconc_sh_quote(s) = '); die "s" if $s < 0;
my $e = index($t, 'fn lconc_collect_outputs(', $s); die "e" if $e < 0;
my $spawn = <<'LUME';
## every partition as its own OS process, all started before any is awaited (os_spawn_capture returns the pid at
## once; on Windows the child is a real process too), output of worker i in w<i>.out / w<i>.err
fn lconc_spawn_all(work_dir, worker_bin, parts, idx) = match parts
    Nil        => Nil
    Cons(p, r) =>
        let pid = os_spawn_capture(worker_bin, Cons(str(p.lo), Cons(str(p.hi), Nil)), work_dir + "/w" + str(idx) + ".out", work_dir + "/w" + str(idx) + ".err") in
        Cons(pid, lconc_spawn_all(work_dir, worker_bin, r, idx + 1))

## the barrier: wait for every worker; 1 when any of them failed or could not start
fn lconc_wait_all(pids) = match pids
    Nil        => 0
    Cons(p, r) =>
        let st = if p <= 0 then 256 else os_waitpid_status(p) in
        let rest = lconc_wait_all(r) in
        if lconc_wait_exit(st) != 0 or rest != 0 then 1 else 0

## the reference worker as a Lume program: prints sum_{i = lo}^{hi - 1} (i * i + 3 * i + 7) for argv lo hi
fn lconc_worker_src() =
    "fn w_parse_neg(s, i, n, acc) = if i >= n then acc else w_parse_neg(s, i + 1, n, acc * 10 - (ord(at(s, i)) - 48))\n" +
    "fn w_parse(s) = 0 - w_parse_neg(s, 0, count(s), 0)\n" +
    "fn w_kernel(lo: int, hi: int, acc: int) -> int = if lo >= hi then acc else w_kernel(lo + 1, hi, acc + (lo * lo + 3 * lo + 7))\n" +
    "let lo = if os_arg_count() >= 2 then w_parse(os_arg_at(1)) else 0\n" +
    "let hi = if os_arg_count() >= 3 then w_parse(os_arg_at(2)) else 0\n" +
    "print w_kernel(lo, hi, 0)\n"

## the tool directory (the driver exports LUME_BIN_DIR to test binaries; build/bin otherwise)
fn lconc_bin_dir() = let d = os_getenv("LUME_BIN_DIR") in if d != "" then hio_posix(d) else "build/bin"

## compile the worker for this host with bindir's lumec + lasm (a PE image on Windows): its path, or "" on failure
fn lconc_build_worker(bindir, dir) =
    let win = os_platform() == "windows" in
    let src = dir + "/conc_worker.src" in
    let asm = dir + "/conc_worker.s" in
    let bin = dir + (if win then "/conc_worker.exe" else "/conc_worker.elf") in
    let w = fs_write_sync(src, lconc_worker_src()) in
    let c = hio_osrun_ict(bindir + "/lumec", if win then Cons("--win64", Nil) else Nil, src, asm, dir + "/conc_worker.cerr", 120000) in
    let a = if lconc_wait_exit(c) != 0 then 256 else hio_osrun_ct(bindir + "/lasm", if win then Cons("--strict", Cons("--pe", Cons(asm, Nil))) else Cons("--strict", Cons(asm, Nil)), bin, dir + "/conc_worker.aerr", 120000) in
    let x = fs_make_executable(bin) in
    if lconc_wait_exit(c) == 0 and lconc_wait_exit(a) == 0 then bin else ""

LUME
substr($t, $s, $e - $s) = $spawn;
# 2. the dispatch body
my $old_d = '        let script = "#!/bin/sh\nRC=0\n" + lconc_build_spawn_lines(work_dir, worker_bin, parts, 0) + lconc_build_wait_lines(parts, 0) + "exit $RC\n" in
        let sp = work_dir + "/dispatch.sh" in
        let w = fs_write_sync(sp, script) in
        let st = hio_osrun_ct("/bin/sh", Cons(sp, Nil), work_dir + "/dispatch.out", work_dir + "/dispatch.err", 60000) in
        if lconc_wait_exit(st) != 0 then {ok: 0, workers: n, sum: 0, transcript: "worker_failed:" + fs_read_file(work_dir + "/dispatch.err")}';
my $new_d = '        let pids = lconc_spawn_all(work_dir, worker_bin, parts, 0) in
        if lconc_wait_all(pids) != 0 then {ok: 0, workers: n, sum: 0, transcript: "worker_failed:" + fs_read_file(work_dir + "/w0.err")}';
my $i = index($t, $old_d); die "d" if $i < 0; substr($t, $i, length($old_d)) = $new_d;
# 3. the unit test builds the Lume worker instead of a shell script
my $old_t = '    let wbin = wdir + "/worker.sh" in
    let wsrc = "#!/bin/sh\nLO=$1\nHI=$2\nACC=0\nI=$LO\nwhile [ \"$I\" -lt \"$HI\" ]; do\n  ACC=$((ACC + I * I + 3 * I + 7))\n  I=$((I + 1))\ndone\necho \"$ACC\"\n" in
    let wf = fs_write_sync(wbin, wsrc) in
    let ch = hio_run("chmod", Cons("+x", Cons(wbin, Nil))) in';
my $new_t = '    let wbin = lconc_build_worker(lconc_bin_dir(), wdir) in';
$i = index($t, $old_t); die "t" if $i < 0; substr($t, $i, length($old_t)) = $new_t;
$t =~ s/    res\.ok == 1 and res\.workers == 4 and res\.sum == seq_ref/    wbin != "" and res.ok == 1 and res.workers == 4 and res.sum == seq_ref/ or die "r";
open my $o, '>:raw', $f or die; print $o $t; close $o; print "lconcurrency fixed\n";
