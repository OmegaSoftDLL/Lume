# fs_remove keeps its contract (a directory is rejected: test_remove_directory_rejected); removing an empty
# directory is its own builtin, fs_rmdir(path) -> 1 / 0.
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $cur = 'fs_remove:\n" + "    call __rt_cstr\n" + "    movq %rax, %rdi\n" + "    movq $87, %rax\n" + "    syscall\n" + "    testq %rax, %rax\n" + "    jns .Lrt_frm_ok\n" + "    movq $84, %rax\n" + "    syscall\n" + "    testq %rax, %rax\n" + "    js .Lrt_frm_error\n" + ".Lrt_frm_ok:\n" + "    movq $1, %rdi\n"';
my $orig = 'fs_remove:\n" + "    call __rt_cstr\n" + "    movq %rax, %rdi\n" + "    movq $87, %rax\n" + "    syscall\n" + "    testq %rax, %rax\n" + "    js .Lrt_frm_error\n" + "    movq $1, %rdi\n"';
my $rmdir = 'fs_rmdir:\n" + "    call __rt_cstr\n" + "    movq %rax, %rdi\n" + "    movq $84, %rax\n" + "    syscall\n" + "    movq $1, %rdi\n" + "    testq %rax, %rax\n" + "    jns .Lrt_frd_ret\n" + "    xorq %rdi, %rdi\n" + ".Lrt_frd_ret:\n" + "    jmp mkint\n" + "';
my $i = index($t, $cur); die "nf" if $i < 0;
substr($t, $i, length($cur)) = $rmdir . $orig;
open my $o, '>:raw', $f or die; print $o $t; close $o; print "fs_remove restored, fs_rmdir added\n";
