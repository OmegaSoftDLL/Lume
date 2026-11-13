# os_setenv(name, value): set NAME=VALUE in the environment the program reads (os_getenv) and passes to every
# child (execve's envp, through __lume_get_envp). A new envp array is built once per call (old entries except
# NAME=, then NAME=VALUE); 1 on success, 0 for an empty name, a name with '=', or no memory.
use strict; use warnings; local $/;
my ($rt, $cg) = @ARGV;
open my $in, '<:raw', $rt or die; my $t = <$in>; close $in;
die "already" if index($t, 'os_setenv:') >= 0;
# bss slot
my $b = '"    .lcomm .Lrt_os_argv, 8\n"';
my $i = index($t, $b); die "bss" if $i < 0;
substr($t, $i, length($b)) = $b . ' + "    .lcomm .Lrt_envp_ovr, 8\n"';
# os_getenv honours the override
my $g = '"    movq .Lrt_os_argv(%rip), %rcx\n" + "    testq %rcx, %rcx\n" + "    jz .Lrt_oge_none\n"';
$i = index($t, $g); die "getenv" if $i < 0;
substr($t, $i, length($g)) = '"    movq .Lrt_envp_ovr(%rip), %rcx\n" + "    testq %rcx, %rcx\n" + "    jnz .Lrt_oge_1\n" + ' . $g;
# os_setenv after os_getenv
my $anchor = '"    leaq .Lrt_oge_empty(%rip), %rdi\n" + "    jmp mkstr\n"';
$i = index($t, $anchor); die "anchor" if $i < 0;
my @a = (
 'os_setenv:', '    pushq %rbx', '    pushq %r12', '    pushq %r13', '    pushq %r14', '    pushq %r15', '    pushq %rsi',
 '    call __rt_cstr', '    movq %rax, %r12', '    popq %rdi', '    call __rt_cstr', '    movq %rax, %r13',
 '    cmpb $0, (%r12)', '    je .Lrt_ose_bad', '    movq %r12, %rax',
 '.Lrt_ose_chk:', '    movzbq (%rax), %rcx', '    testq %rcx, %rcx', '    jz .Lrt_ose_ok', '    cmpq $61, %rcx', '    je .Lrt_ose_bad', '    incq %rax', '    jmp .Lrt_ose_chk',
 '.Lrt_ose_ok:', '    movq .Lrt_envp_ovr(%rip), %r14', '    testq %r14, %r14', '    jnz .Lrt_ose_cnt0',
 '    movq .Lrt_os_argv(%rip), %r14', '    testq %r14, %r14', '    jz .Lrt_ose_cnt0',
 '    movq .Lrt_os_argc(%rip), %rax', '    addq $1, %rax', '    imulq $8, %rax', '    addq %rax, %r14',
 '.Lrt_ose_cnt0:', '    xorq %rbx, %rbx', '    testq %r14, %r14', '    jz .Lrt_ose_len',
 '.Lrt_ose_cnt:', '    cmpq $0, (%r14,%rbx,8)', '    je .Lrt_ose_len', '    incq %rbx', '    jmp .Lrt_ose_cnt',
 '.Lrt_ose_len:', '    movq %r12, %rax',
 '.Lrt_ose_l1:', '    cmpb $0, (%rax)', '    je .Lrt_ose_l1e', '    incq %rax', '    jmp .Lrt_ose_l1',
 '.Lrt_ose_l1e:', '    subq %r12, %rax', '    movq %rax, %r8', '    movq %r13, %rax',
 '.Lrt_ose_l2:', '    cmpb $0, (%rax)', '    je .Lrt_ose_l2e', '    incq %rax', '    jmp .Lrt_ose_l2',
 '.Lrt_ose_l2e:', '    subq %r13, %rax', '    addq %r8, %rax', '    addq $2, %rax',
 '    leaq 2(%rbx), %rsi', '    imulq $8, %rsi', '    addq %rax, %rsi',
 '    xorq %rdi, %rdi', '    movq $3, %rdx', '    movq $34, %r10', '    movq $-1, %r8', '    xorq %r9, %r9', '    movq $9, %rax', '    syscall',
 '    testq %rax, %rax', '    js .Lrt_ose_bad', '    movq %rax, %r15',
 '    leaq 2(%rbx), %rdi', '    imulq $8, %rdi', '    addq %r15, %rdi', '    movq %rdi, %r9', '    movq %r12, %rsi',
 '.Lrt_ose_c1:', '    movzbq (%rsi), %rax', '    testq %rax, %rax', '    jz .Lrt_ose_c1e', '    movb %al, (%rdi)', '    incq %rsi', '    incq %rdi', '    jmp .Lrt_ose_c1',
 '.Lrt_ose_c1e:', '    movb $61, (%rdi)', '    incq %rdi', '    movq %r13, %rsi',
 '.Lrt_ose_c2:', '    movzbq (%rsi), %rax', '    movb %al, (%rdi)', '    incq %rdi', '    incq %rsi', '    testq %rax, %rax', '    jnz .Lrt_ose_c2',
 '    xorq %rcx, %rcx', '    xorq %rdx, %rdx',
 '.Lrt_ose_cp:', '    cmpq %rbx, %rcx', '    jge .Lrt_ose_cpe', '    movq (%r14,%rcx,8), %r8', '    incq %rcx', '    movq %r8, %rsi', '    movq %r12, %rdi',
 '.Lrt_ose_m:', '    movzbq (%rdi), %rax', '    testq %rax, %rax', '    jz .Lrt_ose_mend', '    cmpb %al, (%rsi)', '    jne .Lrt_ose_keep', '    incq %rdi', '    incq %rsi', '    jmp .Lrt_ose_m',
 '.Lrt_ose_mend:', '    cmpb $61, (%rsi)', '    je .Lrt_ose_cp',
 '.Lrt_ose_keep:', '    movq %r8, (%r15,%rdx,8)', '    incq %rdx', '    jmp .Lrt_ose_cp',
 '.Lrt_ose_cpe:', '    movq %r9, (%r15,%rdx,8)', '    incq %rdx', '    movq $0, (%r15,%rdx,8)', '    movq %r15, .Lrt_envp_ovr(%rip)',
 '    movq $1, %rdi', '    jmp .Lrt_ose_ret',
 '.Lrt_ose_bad:', '    xorq %rdi, %rdi',
 '.Lrt_ose_ret:', '    popq %r15', '    popq %r14', '    popq %r13', '    popq %r12', '    popq %rbx', '    jmp mkint');
substr($t, $i, length($anchor)) = $anchor . join('', map { ' + "' . $_ . '\n"' } @a);
open my $o, '>:raw', $rt or die; print $o $t; close $o;
# __lume_get_envp (codegen) returns the override when one is set
open $in, '<:raw', $cg or die; my $c = <$in>; close $in;
my $old = '__lume_get_envp:\n    xorq %rdx, %rdx\n';
$i = index($c, $old); die "get_envp" if $i < 0;
substr($c, $i, length($old)) = '__lume_get_envp:\n    movq .Lrt_envp_ovr(%rip), %rdx\n    testq %rdx, %rdx\n    jnz .Lrt_lge_done\n    xorq %rdx, %rdx\n';
open $o, '>:raw', $cg or die; print $o $c; close $o;
print "os_setenv added\n";
