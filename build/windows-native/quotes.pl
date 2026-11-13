my ($f, $ln, $col) = @ARGV; open my $in, '<:raw', $f or die; my $l; while (<$in>) { if ($. == $ln) { $l = $_; last } }
my $in_s = 0; my $last = 0;
for (my $i = 0; $i < $col && $i < length $l; $i++) { my $c = substr($l, $i, 1);
  if ($in_s) { if ($c eq chr(92)) { $i++; next } if ($c eq '"') { $in_s = 0 } }
  else { if ($c eq '"') { $in_s = 1; $last = $i } } }
print "in_string=$in_s last_open=$last\n"; print substr($l, $last - 80, 200), "\n";
