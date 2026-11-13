# Second driver patch: on Windows the driver builds Windows programs (lumec --win64, lasm --pe).
use strict; use warnings;
local $/;
my $f = shift;
open my $in, '<:raw', $f or die "$f: $!";
my $t = <$in>;
close $in;
my $total = 0;
sub rep {
  my ($old, $new, $min) = @_;
  my $n = 0; my $pos = 0;
  while ((my $i = index($t, $old, $pos)) >= 0) { substr($t, $i, length($old)) = $new; $pos = $i + length($new); $n++; }
  die "pattern applied $n times (expected >= $min): $old\n" if $n < $min;
  $total += $n;
}
rep('os_run_input_capture_timeout(ld_tool(root, "lumec"), Nil, bundled, ',
    'os_run_input_capture_timeout(ld_tool(root, "lumec"), ld_host_cflags(), bundled, ', 2);
rep('os_run_capture_timeout(ld_tool(root, "lasm"), Cons("--strict", Cons(assembly, Nil)), ',
    'os_run_capture_timeout(ld_tool(root, "lasm"), ld_host_aflags(assembly), ', 2);
rep('fs_path_exists(ld_tool(root, "lumec")) == 1 and fs_path_exists(ld_tool(root, "lasm")) == 1',
    'ld_exists_bin(ld_tool(root, "lumec")) == 1 and ld_exists_bin(ld_tool(root, "lasm")) == 1', 1);
rep('fn ld_exists_bin(p) =',
    "## the host's native program format: Windows programs on Windows (lumec --win64 + lasm --pe), ELF elsewhere\nfn ld_host_cflags() = if os_platform() == \"windows\" then Cons(\"--win64\", Nil) else Nil\nfn ld_host_aflags(assembly) = if os_platform() == \"windows\" then Cons(\"--strict\", Cons(\"--pe\", Cons(assembly, Nil))) else Cons(\"--strict\", Cons(assembly, Nil))\nfn ld_exists_bin(p) =", 1);
open my $o, '>:raw', $f or die;
print $o $t;
close $o;
print "driver patched: $total substitutions\n";
