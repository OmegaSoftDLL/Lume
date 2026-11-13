local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i;
my $old = 'os_fork:\n    movq $57, %rax\n    syscall\n';
my $new = 'os_fork:\n    movq $1263685446, %rdi\n    movq $57, %rax\n    syscall\n';
my $k = index($t, $old); die "nf" if $k < 0; substr($t, $k, length($old)) = $new;
open my $o, '>:raw', $f; print $o $t; close $o; print "os_fork marks a real fork (rdi = FORK; Linux ignores it)\n";
