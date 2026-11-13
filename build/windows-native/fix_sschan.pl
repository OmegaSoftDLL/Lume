local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i;
my $old = 'os_run_input_capture_timeout("/bin/sh", Cons("-c", Cons(cmd, Nil)), reqpath, outpath, outpath + ".err", timeout_ms)';
my $k = index($t, $old); die "nf" if $k < 0; substr($t, $k, length($old)) = 'hio_cmdline_ict(cmd, reqpath, outpath, outpath + ".err", timeout_ms)';
open my $o, '>:raw', $f; print $o $t; close $o; print "ok\n";
