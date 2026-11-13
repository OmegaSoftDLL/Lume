use strict; use warnings; local $/;
for my $f (@ARGV) { open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
  my $n = ($t =~ s/\bfs_path_exists\(("\/(?:usr\/(?:local\/)?)?bin\/[A-Za-z0-9_.+-]+")\)/hio_tool_exists($1)/g) || 0;
  next unless $n;
  if ($t !~ /^use hostio$/m) { my @l = split /\n/, $t, -1; my $last = -1; for my $k (0 .. $#l) { $last = $k if $l[$k] =~ /^use / } if ($last < 0) { $last = 0; $last++ while $last < @l && $l[$last] =~ /^#/; $last-- } splice @l, $last + 1, 0, 'use hostio'; $t = join "\n", @l }
  open my $o, '>:raw', $f or die; print $o $t; close $o; print "$f: $n\n"; }
