# Census of Linux syscall sites in the hosted runtime and codegen OS builtins.
# For each `    syscall\n` in the asm strings: nearest preceding `$N, %rax|%eax` and nearest preceding label.
local $/; my (%n, %where);
for my $f (@ARGV) {
  open my $h, '<', $f or die; my $t = <$h>; close $h;
  while ($t =~ /    syscall\x5cn/g) {
    my $pos = pos($t); my $back = substr($t, 0, $pos);
    my ($nr) = $back =~ /.*\$(\d+), %(?:rax|eax)/s; $nr //= '?';
    my ($lbl) = $back =~ /.*"([A-Za-z_.][\w.]*):\x5cn/s; $lbl //= '?';
    $n{$nr}++; $where{$nr}{$lbl}++;
  }
}
for my $k (sort { ($a =~ /^\d+$/ ? $a : 1e9) <=> ($b =~ /^\d+$/ ? $b : 1e9) } keys %n) { printf "%4s x%-3d %s\n", $k, $n{$k}, join(",", sort keys %{$where{$k}}) }
