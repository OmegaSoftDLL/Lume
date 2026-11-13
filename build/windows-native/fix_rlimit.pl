use strict; use warnings; local $/;
my $cg = shift; open my $in, '<:raw', $cg or die; my $c = <$in>; close $in;
my $removed = ($c =~ s/    cmpq \$0, \.Lrt_stk_orig\+8\(%rip\)\n    je \.Lrt_rl_skip_\d+\n    movq \$160, %rax\n    movq \$3, %rdi\n    leaq \.Lrt_stk_orig\(%rip\), %rsi\n    syscall\n\.Lrt_rl_skip_\d+:\n//g);
my $pat = '    movq %r12, %rdi\n    movq %rsp, %rsi\n    call __lume_get_envp\n';
my @parts = split /\Q$pat\E/, $c, -1;
my $out = shift @parts; my $n = 0;
for my $p (@parts) { $n++; $out .= '    cmpq $0, .Lrt_stk_orig+8(%rip)\n    je .Lrt_rl_skip_' . $n . '\n    movq $160, %rax\n    movq $3, %rdi\n    leaq .Lrt_stk_orig(%rip), %rsi\n    syscall\n.Lrt_rl_skip_' . $n . ':\n' . $pat . $p }
open my $o, '>:raw', $cg or die; print $o $out; close $o; print "removed $removed, applied at $n sites\n";
