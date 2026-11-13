local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i;
my $bs = chr(92);
my $old = ' z' . $bs . ' w") in count(w) == 5';
my $new = ' z' . $bs . $bs . ' w") in count(w) == 5';
my $k = index($t, $old); die "nf" if $k < 0; substr($t, $k, length($old)) = $new;
open my $o, '>:raw', $f; print $o $t; close $o; print "ok\n";
