# execve on Windows passes the program's envp (os_setenv included) to CreateProcessW as a UTF-16 block,
# as Linux execve passes envp; the block is freed once the child exists.
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in; my $n = 0;
sub rep { my ($o, $nw) = @_; my $i = index($t, $o); die "nf:\n$o" if $i < 0; die "amb:\n$o" if index($t, $o, $i + 1) >= 0; substr($t, $i, length($o)) = $nw; $n++ }
rep("    jl .Lws_ex_std\n    leaq .Lws_wbuf(%rip), %rcx\n    leaq .Lws_cwbuf(%rip), %rdx\n    xorq %r8, %r8\n    xorq %r9, %r9\n    movq \$1, 32(%rsp)\n    movq \$0, 40(%rsp)\n    movq \$0, 48(%rsp)\n",
"    jl .Lws_ex_std\n    call .Lws_envblock\n    movq %rax, .Lws_envblk(%rip)\n    leaq .Lws_wbuf(%rip), %rcx\n    leaq .Lws_cwbuf(%rip), %rdx\n    xorq %r8, %r8\n    xorq %r9, %r9\n    movq \$1, 32(%rsp)\n    movq \$0, 40(%rsp)\n    movq %rax, 48(%rsp)\n    testq %rax, %rax\n    jz .Lws_ex_noenv\n    movq \$1024, 40(%rsp)\n.Lws_ex_noenv:\n");
rep("    call CreateProcessW\n    shlq \$32, %rax\n    shrq \$32, %rax\n    testq %rax, %rax\n    jz .Lws_fail\n    movq 232(%rsp), %rcx\n",
"    call CreateProcessW\n    shlq \$32, %rax\n    shrq \$32, %rax\n    movq %rax, .Lws_cpres(%rip)\n    testq %rax, %rax\n    jnz .Lws_ex_free\n    call GetLastError\n    movq %rax, .Lws_cperr(%rip)\n.Lws_ex_free:\n    movq .Lws_envblk(%rip), %rcx\n    testq %rcx, %rcx\n    jz .Lws_ex_freed\n    xorq %rdx, %rdx\n    movq \$32768, %r8\n    call VirtualFree\n.Lws_ex_freed:\n    cmpq \$0, .Lws_cpres(%rip)\n    jne .Lws_ex_made\n    movq .Lws_cperr(%rip), %rax\n    shlq \$32, %rax\n    shrq \$32, %rax\n    jmp .Lws_errmap\n.Lws_ex_made:\n    movq 232(%rsp), %rcx\n");
rep(".Lws_execve:\n",
"# envp r14 (NULL-terminated UTF-8 strings) -> rax = UTF-16 environment block (VirtualAlloc, zeroed, so the\n" .
"# block ends in two NULs), 0 when there is no envp. Entered by call; keeps rbx, rsi, rdi, r12, r13.\n" .
".Lws_envblock:\n    pushq %rbx\n    pushq %rsi\n    pushq %rdi\n    pushq %r12\n    pushq %r13\n    subq \$64, %rsp\n    xorq %rax, %rax\n    testq %r14, %r14\n    jz .Lws_eb_out\n" .
"    xorq %rcx, %rcx\n    movq \$4194304, %rdx\n    movq \$12288, %r8\n    movq \$4, %r9\n    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lws_eb_out\n    movq %rax, %r12\n    movq %rax, %r13\n    xorq %rbx, %rbx\n" .
".Lws_eb_l:\n    movq (%r14,%rbx,8), %rsi\n    testq %rsi, %rsi\n    jz .Lws_eb_end\n    incq %rbx\n    leaq 4194296(%r12), %rax\n    subq %r13, %rax\n    shrq \$1, %rax\n    cmpq \$2, %rax\n    jl .Lws_eb_end\n" .
"    movq %r13, 32(%rsp)\n    movq %rax, 40(%rsp)\n    movq \$65001, %rcx\n    xorq %rdx, %rdx\n    movq %rsi, %r8\n    movq \$-1, %r9\n    call MultiByteToWideChar\n    shlq \$32, %rax\n    shrq \$32, %rax\n    testq %rax, %rax\n    jz .Lws_eb_l\n    shlq \$1, %rax\n    addq %rax, %r13\n    jmp .Lws_eb_l\n" .
".Lws_eb_end:\n    movq %r12, %rax\n.Lws_eb_out:\n    addq \$64, %rsp\n    popq %r13\n    popq %r12\n    popq %rdi\n    popq %rsi\n    popq %rbx\n    ret\n.Lws_execve:\n");
rep("    .lcomm .Lws_nrt, 1024\n", "    .lcomm .Lws_nrt, 1024\n    .lcomm .Lws_envblk, 8\n    .lcomm .Lws_cpres, 8\n    .lcomm .Lws_cperr, 8\n");
open my $o, '>:raw', $f or die; print $o $t; close $o; print "envblock patch: $n\n";
