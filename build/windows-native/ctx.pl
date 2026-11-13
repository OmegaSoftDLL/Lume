# Print the text around a literal pattern of a file, with Lume asm-string joins shown as new lines.
local $/; my ($f, $pat, $before, $after) = @ARGV; open my $i, '<:raw', $f or die; my $t = <$i>;
my $k = index($t, $pat); die "not found\n" if $k < 0;
my $s = substr($t, $k - $before < 0 ? 0 : $k - $before, $before + $after);
$s =~ s/\\n" \+ "/\n/g; print $s, "\n";
