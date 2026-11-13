# Route os_run / os_run_capture / os_run_capture_timeout through hostio's dispatchers (hio_osrun*), which do
# the known coreutils programs in Lume and start every other program exactly as before. Adds `use hostio`.
use strict; use warnings;
for my $f (@ARGV) {
  open my $in, '<:raw', $f or die; local $/; my $t = <$in>; close $in;
  my $n = 0;
  $n += ($t =~ s/\bos_run_capture_timeout\(/hio_osrun_ct(/g);
  $n += ($t =~ s/\bos_run_capture\(/hio_osrun_c(/g);
  $n += ($t =~ s/\bos_run\(/hio_osrun(/g);
  next unless $n;
  if ($t !~ /^use hostio$/m) {
    my @l = split /\n/, $t, -1; my $last = -1;
    for my $k (0 .. $#l) { $last = $k if $l[$k] =~ /^use / }
    if ($last < 0) { $last = 0; $last++ while $last < @l && $l[$last] =~ /^#/; $last-- }
    splice @l, $last + 1, 0, 'use hostio';
    $t = join "\n", @l;
  }
  open my $o, '>:raw', $f or die; print $o $t; close $o;
  print "$f: $n\n";
}
