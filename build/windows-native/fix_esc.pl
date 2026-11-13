use strict; use warnings; local $/;
for my $f (@ARGV) { open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
  my $bs = chr(92); my $q = chr(34);
  my $n = ($t =~ s/\Q${bs}hio_\E/${bs}${q}${q} + hio_/g) || 0;
  open my $o, '>:raw', $f or die; print $o $t; close $o; print "$f: $n\n"; }
