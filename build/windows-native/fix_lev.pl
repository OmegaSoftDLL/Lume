local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i;
my $bs = chr(92);
my $old = 'ev_unsafe_path("a' . $bs . 'b.src")'; my $new = 'ev_unsafe_path("a' . $bs . $bs . 'b.src")';
my $k = index($t, $old); die "nf" if $k < 0; substr($t, $k, length($old)) = $new;
open my $o, '>:raw', $f; print $o $t; close $o; print "ok\n";
