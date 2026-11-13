use strict; use warnings; local $/;
for my $f (@ARGV) { open my $i, '<:raw', $f or die; my $t = <$i>; close $i; my $n = 0;
  $n += ($t =~ s/\b(root|cfg\.root|g\.root|c\.root)( \+ "\/build\/bin\/)/hio_bin_dir($1) + "\//g);
  $n += ($t =~ s/fs_path_exists\((hio_bin_dir\([a-z.]+\) \+ "\/[a-z_0-9]+")\)/fs_path_exists(hio_exe_path($1))/g);
  next unless $n;
  if ($t !~ /^use hostio$/m) { my @l = split /\n/, $t, -1; my $last = -1; for my $k (0 .. $#l) { $last = $k if $l[$k] =~ /^use / } if ($last < 0) { $last = 0; $last++ while $last < @l && $l[$last] =~ /^#/; $last-- } splice @l, $last + 1, 0, 'use hostio'; $t = join "\n", @l }
  open my $o, '>:raw', $f; print $o $t; close $o; print "$f: $n\n"; }
