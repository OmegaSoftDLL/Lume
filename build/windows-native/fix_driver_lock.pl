use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
sub rep { my ($o, $n) = @_; my $i = index($t, $o); die "nf: " . substr($o, 0, 80) if $i < 0; substr($t, $i, length($o)) = $n }
rep('fn ld_test_serial(btext, always) = if fs_path_exists("/usr/bin/flock") == 0 then 0 else if always == 1 then 1 else ',
    'fn ld_test_serial(btext, always) = if always == 1 then 1 else ');
rep('fn ld_run_in_dir(root, binary, out, err) = ',
    "## serialized test runs (they share the sentience memory files): a lock directory, since mkdir is atomic on every\n" .
    "## system; a lock older than the 30-minute test timeout is taken over\n" .
    'fn ld_lock_dir() = ld_test_lock() + ".d"' . "\n" .
    'fn ld_lock_take(n) = if fs_mkdir(ld_lock_dir()) == 1 then 1 else if n <= 0 then (let r = fs_remove(ld_lock_dir()) in fs_mkdir(ld_lock_dir())) else let s = os_sleep_ms(50) in ld_lock_take(n - 1)' . "\n" .
    'fn ld_run_serial(root, binary, out, err, serial) = if serial == 1 then (let l = ld_lock_take(36000) in let st = ld_run_in_dir(root, binary, out, err) in let g = fs_remove(ld_lock_dir()) in st) else ld_run_in_dir(root, binary, out, err)' . "\n" .
    'fn ld_run_in_dir(root, binary, out, err) = ');
my $re = qr/\(if os_platform\(\) == "windows" then ld_run_in_dir\(root, binary, stem \+ "\.out", stem \+ "\.err"\) else hio_osrun_ct\("\/bin\/sh", Cons\("-c", Cons\("cd \\"" \+ root \+ "\\" && " \+ \(if ld_test_serial\(g\.btext, 1\) == 1 then "\/usr\/bin\/flock " \+ ld_test_lock\(\) \+ " " else ""\) \+ "\\"" \+ binary \+ "\\"", Nil\)\), stem \+ "\.out", stem \+ "\.err", 1800000\)\)/;
$t =~ s/$re/ld_run_serial(root, binary, stem + ".out", stem + ".err", ld_test_serial(g.btext, 1))/ or die "run";
open my $o, '>:raw', $f or die; print $o $t; close $o; print "driver lock fixed\n";
