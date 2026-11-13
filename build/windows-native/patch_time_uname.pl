# Runtime: os_unix_time() (seconds since 1970-01-01 UTC, CLOCK_REALTIME) and os_uname_field(i) (uname(2) field i:
# 0 sysname, 1 nodename, 2 release, 3 version, 4 machine; "" when i is out of range or the call fails).
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
die "already" if index($t, 'os_unix_time:') >= 0;
my $anchor = '"os_unsetenv:\n"';
my $i = index($t, $anchor); die "anchor" if $i < 0;
my @a = (
 'os_unix_time:', '    subq $24, %rsp', '    xorq %rdi, %rdi', '    movq %rsp, %rsi', '    movq $228, %rax', '    syscall',
 '    movq (%rsp), %rdi', '    addq $24, %rsp', '    testq %rax, %rax', '    jns mkint', '    xorq %rdi, %rdi', '    jmp mkint',
 'os_uname_field:', '    pushq %rbx', '    movq %rdi, %rax', '    call __rt_uint', '    movq %rax, %rbx', '    subq $400, %rsp',
 '    testq %rbx, %rbx', '    js .Lrt_oun_none', '    cmpq $4, %rbx', '    jg .Lrt_oun_none',
 '    movq %rsp, %rdi', '    movq $63, %rax', '    syscall', '    testq %rax, %rax', '    js .Lrt_oun_none',
 '    imulq $65, %rbx', '    leaq (%rsp,%rbx,1), %rdi', '    movb $0, 64(%rdi)', '    call mkstr', '    addq $400, %rsp', '    popq %rbx', '    ret',
 '.Lrt_oun_none:', '    leaq .Lrt_oge_empty(%rip), %rdi', '    call mkstr', '    addq $400, %rsp', '    popq %rbx', '    ret');
substr($t, $i, 0) = join('', map { '"' . $_ . '\n" + ' } @a);
open my $o, '>:raw', $f or die; print $o $t; close $o; print "os_unix_time + os_uname_field added\n";
