# fs_remove(path): unlink, and when that fails, rmdir (an empty directory is removed too, on every system)
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $old = 'fs_remove:\n" + "    call __rt_cstr\n" + "    movq %rax, %rdi\n" + "    movq $87, %rax\n" + "    syscall\n" + "    testq %rax, %rax\n" + "    js .Lrt_frm_error\n" + "    movq $1, %rdi\n"';
my $new = 'fs_remove:\n" + "    call __rt_cstr\n" + "    movq %rax, %rdi\n" + "    movq $87, %rax\n" + "    syscall\n" + "    testq %rax, %rax\n" + "    jns .Lrt_frm_ok\n" + "    movq $84, %rax\n" + "    syscall\n" + "    testq %rax, %rax\n" + "    js .Lrt_frm_error\n" + ".Lrt_frm_ok:\n" + "    movq $1, %rdi\n"';
my $i = index($t, $old); die "not found" if $i < 0; substr($t, $i, length($old)) = $new;
open my $o, '>:raw', $f or die; print $o $t; close $o; print "fs_remove patched\n";
