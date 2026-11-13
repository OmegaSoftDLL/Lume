local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i;
my $bs = chr(92);
my $old = 'hio_osrun_ct("/bin/sh", Cons("-c", Cons("ulimit -s 8192; exec ' . $bs . '"$0' . $bs . '" ' . $bs . '"$1' . $bs . '"", Cons(solver, Cons(file, Nil)))), work + ".solver.out", work + ".solver.err", 60000)';
my $k = index($t, $old); die "nf" if $k < 0;
substr($t, $k, length($old)) = 'hio_osrun_ct(solver, Cons(file, Nil), work + ".solver.out", work + ".solver.err", 60000)';
open my $o, '>:raw', $f; print $o $t; close $o; print "ok\n";
