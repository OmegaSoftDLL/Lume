use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
$t =~ s/hio_osrun\("\/usr\/bin\/flock", Cons\(ld_test_lock\(\), Cons\(binary, Nil\)\)\)/ld_osrun_locked(binary)/ or die "a";
$t =~ s/(fn ld_run_in_dir\(root, binary, out, err\) = )/fn ld_osrun_locked(binary) = let l = ld_lock_take(36000) in let st = hio_osrun(binary, Nil) in let g = fs_remove(ld_lock_dir()) in st\n$1/ or die "b";
$t =~ s/## \/tmp\/lume-sentience-memory\.lock \(the kernel drops the lock when the process ends, so there is no stale lock\), and\n/## \/tmp\/lume-sentience-memory.lock.d (a lock directory: mkdir is atomic on Linux and Windows; a lock older than the\n## 30-minute test timeout is taken over), and\n/ or die "c";
$t =~ s/## several modules keep fixed-name probe files\)\. Without \/usr\/bin\/flock the tests run unserialised, as before\.\n/## several modules keep fixed-name probe files).\n/ or die "d";
open my $o, '>:raw', $f or die; print $o $t; close $o; print "ok\n";
