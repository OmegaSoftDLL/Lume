local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i; my $n = 0;
sub rep { my ($o, $nw) = @_; my $k = index($t, $o); die "nf: $o" if $k < 0; substr($t, $k, length($o)) = $nw; $n++ }
rep('fn la_fam_count() = 21', 'fn la_fam_count() = 22');
rep('else if i == 19 then "evex256" else "evex_cube"', 'else if i == 19 then "evex256" else if i == 20 then "evex_cube" else "indirect"');
rep('else if i == 19 then la_f_evex256() else la_f_evex_cube()', 'else if i == 19 then la_f_evex256() else if i == 20 then la_f_evex_cube() else la_f_ind(0, "")');
rep('fn la_f_test() = ', "## register-indirect call and jmp (FF /2, FF /4) over all 16 registers\nfn la_f_ind(i, acc) = if i >= 16 then acc else la_f_ind(i + 1, acc + \"    call *\" + la_r64(i) + \"\n    jmp *\" + la_r64(i) + \"\n\")\nfn la_f_test() = ");
open my $o, '>:raw', $f; print $o $t; close $o; print "$f: $n\n";
