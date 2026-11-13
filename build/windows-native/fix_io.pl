use strict; use warnings; local $/;
my $bs = chr(92); my $q = chr(34);
for my $f (@ARGV) { open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
  my $n = ($t =~ s/\Q${bs}${q}${q} + hio_\E(?!(?:lume_home|data_dir|system_vault|win_system32|win_home)\(\))/ io_/g) || 0;
  open my $o, '>:raw', $f or die; print $o $t; close $o; print "$f: $n reverted\n"; }
