use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $old = 'let bin_p = if fs_path_exists(hio_lume_home() + "/build/bin/lume_driver") == 1 then hio_lume_home() + "/build/bin/lume_driver" else if fs_path_exists("build/bin/lume_driver") == 1 then "build/bin/lume_driver" else "/bin/sh" in';
my $new = 'let bin_p = os_arg_at(0) in';
my $i = index($t, $old); die "a" if $i < 0; substr($t, $i, length($old)) = $new;
my $o2 = 'sn_contains(rj, "\"machine_arch_code\":62") == 1 and sn_contains(rj, "\"p33_anti_rea_protection\":")';
my $n2 = '(sn_contains(rj, "\"machine_arch_code\":62") == 1 or sn_contains(rj, "\"machine_arch_code\":34404") == 1) and sn_contains(rj, "\"p33_anti_rea_protection\":")';
$i = index($t, $o2); die "b" if $i < 0; substr($t, $i, length($o2)) = $n2;
open my $o, '>:raw', $f or die; print $o $t; close $o; print "ok\n";
