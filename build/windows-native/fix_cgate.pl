use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $s = index($t, 'fn cg_build_worker_elf(root, tmp) ='); die "s" if $s < 0;
my $e = index($t, 'fn cg_check_parallel_workers(', $s); die "e" if $e < 0;
substr($t, $s, $e - $s) = <<'LUME';
fn cg_build_worker_elf(root, tmp) =
    let bindir = if os_getenv("LUME_BIN_DIR") != "" then lconc_bin_dir() else root + "/build/bin" in
    let w = lconc_build_worker(bindir, tmp) in
    if w == "" then ctfail("concurrency gate failed: worker compile error: " + fs_read_file(tmp + "/conc_worker.cerr") + fs_read_file(tmp + "/conc_worker.aerr") + "\n")
    else w

LUME
$t =~ s/across 6 and 8 native Lume ELF64 worker processes/across 6 and 8 native Lume worker processes (ELF64 on Linux, PE32+ on Windows)/;
$t =~ s/across 6 and 8 parallel native Lume ELF64 OS worker processes;/across 6 and 8 parallel native Lume OS worker processes;/;
open my $o, '>:raw', $f or die; print $o $t; close $o; print "gate fixed\n";
