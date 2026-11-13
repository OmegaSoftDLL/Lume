# Introduce a Linux-like file descriptor table in the Win64 layer (exact substitutions on win64_layer.s).
# fd 0..2 = standard handles (kind 4), lowest free fd >= 3 is allocated (as on Linux);
# kind 1 = HANDLE, 2 = directory stream record, 3 = /dev/urandom.
use strict; use warnings;
local $/;
my $f = shift;
open my $in, '<:raw', $f or die "$f: $!";
my $t = <$in>;
close $in;
my $n = 0;
sub rep {
  my ($old, $new) = @_;
  my $i = index($t, $old);
  die "not found:\n$old\n" if $i < 0;
  die "ambiguous:\n$old\n" if index($t, $old, $i + 1) >= 0;
  substr($t, $i, length($old)) = $new;
  $n++;
}

# helpers, before the first handler
rep(".Lws_eio:\n    movq \$-5, %rax\n    jmp .Lws_ret\n",
".Lws_eio:\n    movq \$-5, %rax\n    jmp .Lws_ret\n.Lws_eisdir:\n    movq \$-21, %rax\n    jmp .Lws_ret\n" .
"# fd r12 -> rax = HANDLE / record, rcx = kind (0 = not open). Subroutine, entered by call (rsp = 8 mod 16).\n" .
".Lws_fdh:\n    subq \$40, %rsp\n    xorq %rcx, %rcx\n    xorq %rax, %rax\n    testq %r12, %r12\n    js .Lws_fdh_out\n    cmpq \$1024, %r12\n    jge .Lws_fdh_out\n" .
"    leaq .Lws_fdt(%rip), %rax\n    movq %r12, %rcx\n    shlq \$4, %rcx\n    addq %rcx, %rax\n    movq (%rax), %rcx\n    movq 8(%rax), %rax\n    cmpq \$4, %rcx\n    jne .Lws_fdh_out\n" .
"    movq \$-10, %rcx\n    subq %r12, %rcx\n    call GetStdHandle\n    movq \$4, %rcx\n.Lws_fdh_out:\n    addq \$40, %rsp\n    ret\n" .
"# lowest free fd >= 3 for (kind r8, value r9): rax = fd, or -EMFILE. No API call.\n" .
".Lws_fd_new:\n    leaq .Lws_fdt+48(%rip), %rax\n    movq \$3, %rcx\n.Lws_fdn_l:\n    cmpq \$1024, %rcx\n    jge .Lws_fdn_full\n    cmpq \$0, (%rax)\n    je .Lws_fdn_put\n    addq \$16, %rax\n    incq %rcx\n    jmp .Lws_fdn_l\n" .
".Lws_fdn_put:\n    movq %r8, (%rax)\n    movq %r9, 8(%rax)\n    movq %rcx, %rax\n    ret\n.Lws_fdn_full:\n    movq \$-24, %rax\n    ret\n" .
"# free fd r12. No API call.\n.Lws_fd_free:\n    leaq .Lws_fdt(%rip), %rax\n    movq %r12, %rcx\n    shlq \$4, %rcx\n    movq \$0, (%rax,%rcx,1)\n    movq \$0, 8(%rax,%rcx,1)\n    ret\n");

# read
rep(".Lws_read:\n    testq %r12, %r12\n    js .Lws_ebadf\n    movq \$2147483632, %rax\n    cmpq %rax, %r12\n    je .Lws_read_random\n    movq %r12, %rax\n    cmpq \$2, %r12\n    jg .Lws_read_h\n    movq \$-10, %rcx\n    subq %r12, %rcx\n    call GetStdHandle\n.Lws_read_h:\n",
".Lws_read:\n    call .Lws_fdh\n    testq %rcx, %rcx\n    jz .Lws_ebadf\n    cmpq \$3, %rcx\n    je .Lws_read_random\n    cmpq \$2, %rcx\n    je .Lws_eisdir\n    movq %rax, 72(%rsp)\n.Lws_read_h:\n");
rep("    call ReadFile\n    shlq \$32, %rax\n    shrq \$32, %rax\n    testq %rax, %rax\n    jz .Lws_read_err\n    movq 64(%rsp), %rax\n    jmp .Lws_ret\n.Lws_read_err:\n",
"    call ReadFile\n    shlq \$32, %rax\n    shrq \$32, %rax\n    testq %rax, %rax\n    jz .Lws_read_err\n    movq 64(%rsp), %rax\n    testq %r12, %r12\n    jnz .Lws_ret\n    testq %rax, %rax\n    jz .Lws_ret\n" .
"    movq 72(%rsp), %rcx\n    call GetFileType\n    shlq \$32, %rax\n    shrq \$32, %rax\n    cmpq \$2, %rax\n    movq 64(%rsp), %rax\n    jne .Lws_ret\n" .
"# console input in cooked mode ends lines with \"\\r\\n\": drop the '\\r' (a Linux terminal delivers \"\\n\")\n" .
"    movq %r13, %rsi\n    movq %r13, %rdi\n    movq %rax, %rcx\n.Lws_read_cr:\n    movzbq (%rsi), %rax\n    incq %rsi\n    cmpq \$13, %rax\n    je .Lws_read_cr_skip\n    movb %al, (%rdi)\n    incq %rdi\n.Lws_read_cr_skip:\n    decq %rcx\n    jnz .Lws_read_cr\n    movq %rdi, %rax\n    subq %r13, %rax\n    jmp .Lws_ret\n.Lws_read_err:\n");

# write
rep(".Lws_write:\n    testq %r12, %r12\n    js .Lws_ebadf\n    movq %r12, %rax\n    cmpq \$2, %r12\n    jg .Lws_write_h\n    movq \$-10, %rcx\n    subq %r12, %rcx\n    call GetStdHandle\n.Lws_write_h:\n",
".Lws_write:\n    call .Lws_fdh\n    cmpq \$1, %rcx\n    je .Lws_write_h\n    cmpq \$4, %rcx\n    jne .Lws_ebadf\n.Lws_write_h:\n");

# open: /dev/urandom, files, directories
rep(".Lws_open_random:\n    movq \$2147483632, %rax\n    jmp .Lws_ret\n",
".Lws_open_random:\n    movq \$3, %r8\n    xorq %r9, %r9\n    call .Lws_fd_new\n    jmp .Lws_ret\n");
rep("    cmpq \$-1, %rax\n    je .Lws_fail\n    cmpq \$0, .Lws_fk_mode(%rip)\n    je .Lws_ret\n# vfork child: the handle is inheritable and is closed in the parent once the child process exists\n    movq %rax, 64(%rsp)\n    movq %rax, %rcx\n    movq \$1, %rdx\n    movq \$1, %r8\n    call SetHandleInformation\n    movq .Lws_fk_nopen(%rip), %rcx\n    cmpq \$8, %rcx\n    jge .Lws_open_rec\n    leaq .Lws_fk_open(%rip), %rdx\n    movq 64(%rsp), %rax\n    movq %rax, (%rdx,%rcx,8)\n    incq %rcx\n    movq %rcx, .Lws_fk_nopen(%rip)\n.Lws_open_rec:\n    movq 64(%rsp), %rax\n    jmp .Lws_ret\n",
"    cmpq \$-1, %rax\n    je .Lws_fail\n    movq %rax, 64(%rsp)\n    movq \$1, %r8\n    movq %rax, %r9\n    call .Lws_fd_new\n    testq %rax, %rax\n    jns .Lws_open_fd\n    movq %rax, 72(%rsp)\n    movq 64(%rsp), %rcx\n    call CloseHandle\n    movq 72(%rsp), %rax\n    jmp .Lws_ret\n" .
".Lws_open_fd:\n    movq %rax, 72(%rsp)\n    cmpq \$0, .Lws_fk_mode(%rip)\n    je .Lws_ret\n# vfork child: the handle is inheritable; its fd is closed in the parent once the child process exists\n" .
"    movq 64(%rsp), %rcx\n    movq \$1, %rdx\n    movq \$1, %r8\n    call SetHandleInformation\n    movq .Lws_fk_nopen(%rip), %rcx\n    cmpq \$8, %rcx\n    jge .Lws_open_rec\n    leaq .Lws_fk_open(%rip), %rdx\n    movq 72(%rsp), %rax\n    movq %rax, (%rdx,%rcx,8)\n    incq %rcx\n    movq %rcx, .Lws_fk_nopen(%rip)\n.Lws_open_rec:\n    movq 72(%rsp), %rax\n    jmp .Lws_ret\n");
rep("    movq 64(%rsp), %rcx\n    movq %rax, 8(%rcx)\n    movq \$0, 16(%rcx)\n    leaq 1(%rcx), %rax\n    jmp .Lws_ret\n",
"    movq 64(%rsp), %rcx\n    movq %rax, 8(%rcx)\n    movq \$0, 16(%rcx)\n    movq \$2, %r8\n    movq %rcx, %r9\n    call .Lws_fd_new\n    testq %rax, %rax\n    jns .Lws_ret\n    movq %rax, 72(%rsp)\n    movq 64(%rsp), %rcx\n    movq 8(%rcx), %rcx\n    call FindClose\n    movq 64(%rsp), %rcx\n    xorq %rdx, %rdx\n    movq \$32768, %r8\n    call VirtualFree\n    movq 72(%rsp), %rax\n    jmp .Lws_ret\n");

# close
rep(".Lws_close:\n    cmpq \$0, .Lws_fk_mode(%rip)\n    jne .Lws_zero\n    cmpq \$2, %r12\n    jle .Lws_zero\n    movq \$2147483632, %rax\n    cmpq %rax, %r12\n    je .Lws_zero\n    movq %r12, %rax\n    andq \$1, %rax\n    testq %rax, %rax\n    jz .Lws_close_h\n    movq %r12, %rax\n    subq \$1, %rax\n    movq %rax, 64(%rsp)\n    movq 8(%rax), %rcx\n    call FindClose\n    movq 64(%rsp), %rcx\n    xorq %rdx, %rdx\n    movq \$32768, %r8\n    call VirtualFree\n    jmp .Lws_zero\n.Lws_close_h:\n    cmpq \$2, %r12\n    jle .Lws_zero\n    movq %r12, %rcx\n    call CloseHandle\n",
".Lws_close:\n    cmpq \$0, .Lws_fk_mode(%rip)\n    jne .Lws_zero\n    cmpq \$2, %r12\n    jle .Lws_zero\n    call .Lws_fdh\n    testq %rcx, %rcx\n    jz .Lws_ebadf\n    movq %rax, 64(%rsp)\n    movq %rcx, 72(%rsp)\n    call .Lws_fd_free\n    movq 72(%rsp), %rcx\n    cmpq \$2, %rcx\n    je .Lws_close_dir\n    cmpq \$1, %rcx\n    jne .Lws_zero\n    movq 64(%rsp), %rcx\n    call CloseHandle\n");
rep("    jz .Lws_fail\n    jmp .Lws_zero\n.Lws_lseek:\n",
"    jz .Lws_fail\n    jmp .Lws_zero\n.Lws_close_dir:\n    movq 64(%rsp), %rax\n    movq 8(%rax), %rcx\n    call FindClose\n    movq 64(%rsp), %rcx\n    xorq %rdx, %rdx\n    movq \$32768, %r8\n    call VirtualFree\n    jmp .Lws_zero\n.Lws_lseek:\n");

# lseek
rep(".Lws_lseek:\n# /dev/urandom has no position: lseek succeeds at 0, as on Linux\n    movq \$2147483632, %rax\n    cmpq %rax, %r12\n    je .Lws_zero\n    movq %r12, %rax\n    cmpq \$2, %r12\n    jg .Lws_lseek_h\n    movq \$-10, %rcx\n    subq %r12, %rcx\n    call GetStdHandle\n.Lws_lseek_h:\n",
".Lws_lseek:\n    call .Lws_fdh\n    testq %rcx, %rcx\n    jz .Lws_ebadf\n# /dev/urandom has no position: lseek succeeds at 0, as on Linux\n    cmpq \$3, %rcx\n    je .Lws_zero\n    cmpq \$2, %rcx\n    je .Lws_einval\n.Lws_lseek_h:\n");

# fsync
rep(".Lws_fsync:\n    cmpq \$2, %r12\n    jle .Lws_zero\n    movq %r12, %rcx\n    call FlushFileBuffers\n",
".Lws_fsync:\n    cmpq \$2, %r12\n    jle .Lws_zero\n    call .Lws_fdh\n    cmpq \$1, %rcx\n    jne .Lws_einval\n    movq %rax, %rcx\n    call FlushFileBuffers\n");

# flock
rep(".Lws_flock:\n    cmpq \$2, %r12\n    jle .Lws_zero\n    movq \$0, 96(%rsp)\n",
".Lws_flock:\n    cmpq \$2, %r12\n    jle .Lws_zero\n    call .Lws_fdh\n    cmpq \$1, %rcx\n    jne .Lws_zero\n    movq %rax, 88(%rsp)\n    movq \$0, 96(%rsp)\n");
rep("    jz .Lws_flock_lock\n    movq %r12, %rcx\n    xorq %rdx, %rdx\n", "    jz .Lws_flock_lock\n    movq 88(%rsp), %rcx\n    xorq %rdx, %rdx\n");
rep(".Lws_flock_go:\n    movq %r12, %rcx\n", ".Lws_flock_go:\n    movq 88(%rsp), %rcx\n");

# getdents
rep(".Lws_getdents:\n    cmpq \$2, %r12\n    jle .Lws_enotdir\n    movq %r12, %rax\n    andq \$1, %rax\n    testq %rax, %rax\n    jz .Lws_enotdir\n    movq %r12, %rbx\n    subq \$1, %rbx\n",
".Lws_getdents:\n    call .Lws_fdh\n    cmpq \$2, %rcx\n    jne .Lws_enotdir\n    movq %rax, %rbx\n");

# pipe: two small fds, written as two 32-bit ints
rep("    jz .Lws_fail\n    movq 88(%rsp), %rax\n    shlq \$32, %rax\n    movq 80(%rsp), %rcx\n    shlq \$32, %rcx\n    shrq \$32, %rcx\n    addq %rcx, %rax\n    movq %rax, (%r12)\n    jmp .Lws_zero\n",
"    jz .Lws_fail\n    movq \$1, %r8\n    movq 80(%rsp), %r9\n    call .Lws_fd_new\n    movq %rax, 96(%rsp)\n    movq \$1, %r8\n    movq 88(%rsp), %r9\n    call .Lws_fd_new\n    movq %rax, 104(%rsp)\n" .
"    movq 96(%rsp), %rcx\n    testq %rcx, %rcx\n    js .Lws_pipe_full\n    testq %rax, %rax\n    js .Lws_pipe_full\n    shlq \$32, %rax\n    addq %rcx, %rax\n    movq %rax, (%r12)\n    jmp .Lws_zero\n" .
".Lws_pipe_full:\n    movq 80(%rsp), %rcx\n    call CloseHandle\n    movq 88(%rsp), %rcx\n    call CloseHandle\n    movq \$-24, %rax\n    jmp .Lws_ret\n");

# dup2
rep(".Lws_dup2_h:\n    movq %rax, 80(%rsp)\n", ".Lws_dup2_h:\n    movq %rax, 80(%rsp)\n");
rep("    js .Lws_ebadf\n    movq %r12, %rax\n    cmpq \$2, %r12\n    jg .Lws_dup2_h\n    movq \$-10, %rcx\n    subq %r12, %rcx\n    call GetStdHandle\n.Lws_dup2_h:\n",
"    js .Lws_ebadf\n    call .Lws_fdh\n    cmpq \$1, %rcx\n    je .Lws_dup2_h\n    cmpq \$4, %rcx\n    jne .Lws_ebadf\n.Lws_dup2_h:\n");

# vfork child fds: close the handle and free the fd
rep("    leaq .Lws_fk_open(%rip), %rdx\n    movq (%rdx,%rcx,8), %rcx\n    call CloseHandle\n    jmp .Lws_fco_loop\n",
"    leaq .Lws_fk_open(%rip), %rdx\n    movq (%rdx,%rcx,8), %rcx\n    leaq .Lws_fdt(%rip), %rax\n    shlq \$4, %rcx\n    addq %rcx, %rax\n    movq 8(%rax), %rcx\n    movq \$0, (%rax)\n    movq \$0, 8(%rax)\n    call CloseHandle\n    jmp .Lws_fco_loop\n");

# start-up: fds 0..2 are the standard handles
rep("    movq \$32771, %rcx\n    call SetErrorMode\n",
"    movq \$4, .Lws_fdt(%rip)\n    movq \$4, .Lws_fdt+16(%rip)\n    movq \$4, .Lws_fdt+32(%rip)\n    movq \$32771, %rcx\n    call SetErrorMode\n");

# table storage and GetFileType import
rep("    .lcomm .Lws_bcrypt_fn, 8\n", "    .lcomm .Lws_bcrypt_fn, 8\n    .lcomm .Lws_fdt, 16384\n");
rep("    .extern KERNEL32.dll!MoveFileExW\n", "    .extern KERNEL32.dll!MoveFileExW\n    .extern KERNEL32.dll!GetFileType\n");

open my $o, '>:raw', $f or die;
print $o $t;
close $o;
print "fd table patch: $n substitutions\n";
