local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i; my $bs = chr(92);
my $s = index($t, 'fn la_f_ind(i, acc) = '); die "s" if $s < 0;
my $e = index($t, "\nfn la_f_test() = ", $s); die "e" if $e < 0;
substr($t, $s, $e - $s) = 'fn la_f_ind(i, acc) = if i >= 16 then acc else la_f_ind(i + 1, acc + "    call *" + la_r64(i) + "' . $bs . 'n    jmp *" + la_r64(i) + "' . $bs . 'n")';
open my $o, '>:raw', $f; print $o $t; close $o; print "ok\n";
