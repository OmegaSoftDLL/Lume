# A child started by os_run*/os_exec gets the stack limit the program itself was started with, not the 4 GiB
# the runtime raises for Lume's own recursion (an external program such as a solver must not inherit it).
use strict; use warnings; local $/;
my ($rt, $cg) = @ARGV;
open my $in, '<:raw', $rt or die; my $t = <$in>; close $in;
my $o1 = 'fn runtime_hosted_init() = "    movq $97, %rax\n" + "    movq $3, %rdi\n" + "    leaq -16(%rsp), %rsi\n" + "    syscall\n"';
my $i = index($t, $o1); die "init" if $i < 0;
substr($t, $i, length($o1)) = $o1 . ' + "    movq -16(%rsp), %rax\n" + "    movq %rax, .Lrt_stk_orig(%rip)\n" + "    movq -8(%rsp), %rax\n" + "    movq %rax, .Lrt_stk_orig+8(%rip)\n"';
my $b = '"    .lcomm .Lrt_spawn_nowait, 8\n"';
$i = index($t, $b); die "bss" if $i < 0;
substr($t, $i + length($b), 0) = ' + "    .lcomm .Lrt_stk_orig, 16\n"';
open my $o, '>:raw', $rt or die; print $o $t; close $o;
open $in, '<:raw', $cg or die; my $c = <$in>; close $in;
my $pat = '    movq %r12, %rdi\n    movq %rsp, %rsi\n    call __lume_get_envp\n';
my $rep = '    cmpq $0, .Lrt_stk_orig+8(%rip)\n    je .Lrt_rl_skip_NN\n    movq $160, %rax\n    movq $3, %rdi\n    leaq .Lrt_stk_orig(%rip), %rsi\n    syscall\n.Lrt_rl_skip_NN:\n' . $pat;
my $n = 0;
while ((my $k = index($c, $pat)) >= 0) { $n++; my $r = $rep; $r =~ s/NN/$n/g; substr($c, $k, length($pat)) = "\x01$n\x01"; $c =~ s/\x01$n\x01/$r/; last if $n > 20 }
# the placeholder loop replaced in place; make sure the original pattern now appears only after the guard
open $o, '>:raw', $cg or die; print $o $c; close $o; print "rlimit restore at $n execve sites\n";
