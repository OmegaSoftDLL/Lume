# fs_chmod(path, mode): chmod(2) with a numeric mode (e.g. 384 = 0600); 1 on success, 0 on failure or bad mode.
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
die "already" if index($t, 'fs_chmod:') >= 0;
my $old = '".Lrt_fmx_ret:\n" + "    jmp mkint\n"';
my $i = index($t, $old); die "not found" if $i < 0;
my @a = ('fs_chmod:', '    pushq %rsi', '    call __rt_cstr', '    popq %rdi', '    pushq %rax', '    movq %rdi, %rax',
 '    call __rt_uint', '    popq %rdi', '    testq %rax, %rax', '    js .Lrt_fchm_bad', '    cmpq $4095, %rax', '    jg .Lrt_fchm_bad',
 '    movq %rax, %rsi', '    movq $90, %rax', '    syscall', '    movq $1, %rdi', '    testq %rax, %rax', '    jns .Lrt_fchm_ret',
 '.Lrt_fchm_bad:', '    xorq %rdi, %rdi', '.Lrt_fchm_ret:', '    jmp mkint');
substr($t, $i, length($old)) = $old . join('', map { ' + "' . $_ . '\n"' } @a);
open my $o, '>:raw', $f or die; print $o $t; close $o; print "fs_chmod added\n";
