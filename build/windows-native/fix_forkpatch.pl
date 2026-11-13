local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i; my $n = 0;
sub rep { my ($o, $nw) = @_; my $k = index($t, $o); die "nf: $o" if $k < 0; substr($t, $k, length($o)) = $nw; $n++ }
rep(".Lws_reg_add:\n    leaq .Lws_regs(%rip), %rax\n    movq \$1024, %r8\n.Lws_rga_l:\n    cmpq \$0, (%rax)\n    je .Lws_rga_put\n    addq \$16, %rax\n    decq %r8\n    jnz .Lws_rga_l\n    ret\n.Lws_rga_put:\n    movq %rcx, (%rax)\n    movq %rdx, 8(%rax)\n    ret\n",
    "# (keeps rax: mmap returns it)\n.Lws_reg_add:\n    leaq .Lws_regs(%rip), %r10\n    movq \$1024, %r8\n.Lws_rga_l:\n    cmpq \$0, (%r10)\n    je .Lws_rga_put\n    addq \$16, %r10\n    decq %r8\n    jnz .Lws_rga_l\n    ret\n.Lws_rga_put:\n    movq %rcx, (%r10)\n    movq %rdx, 8(%r10)\n    ret\n");
rep(".Lws_reg_del:\n    leaq .Lws_regs(%rip), %rax\n    movq \$1024, %r8\n.Lws_rgd_l:\n    cmpq %rcx, (%rax)\n    jne .Lws_rgd_n\n    movq \$0, (%rax)\n    movq \$0, 8(%rax)\n.Lws_rgd_n:\n    addq \$16, %rax\n",
    ".Lws_reg_del:\n    leaq .Lws_regs(%rip), %r10\n    movq \$1024, %r8\n.Lws_rgd_l:\n    cmpq %rcx, (%r10)\n    jne .Lws_rgd_n\n    movq \$0, (%r10)\n    movq \$0, 8(%r10)\n.Lws_rgd_n:\n    addq \$16, %r10\n");
# stack temporaries out of the MEMORY_BASIC_INFORMATION buffer (48..95)
rep("    movq 48(%rsp), %rax\n    addq 72(%rsp), %rax\n    movq %rax, 88(%rsp)\n    movq 56(%rsp), %rax\n    movq %rax, 96(%rsp)\n",
    "    movq 48(%rsp), %rax\n    addq 72(%rsp), %rax\n    movq %rax, 256(%rsp)\n    movq 56(%rsp), %rax\n    movq %rax, 264(%rsp)\n");
rep("    movq .Lws_fk_proc(%rip), %rcx\n    movq 96(%rsp), %rdx\n    movq 88(%rsp), %r8\n    subq %rdx, %r8\n",
    "    movq .Lws_fk_proc(%rip), %rcx\n    movq 264(%rsp), %rdx\n    movq 256(%rsp), %r8\n    subq %rdx, %r8\n");
rep(".Lws_fr_stk:\n    movq %r12, %rcx\n    movq 88(%rsp), %rdx\n", ".Lws_fr_stk:\n    movq %r12, %rcx\n    movq 256(%rsp), %rdx\n");
# a writable copy of the command line for CreateProcessW
rep("    call GetCommandLineW\n    movq %rax, %rdx\n    leaq .Lws_pbuf(%rip), %rcx\n    xorq %r8, %r8\n",
    "    call GetCommandLineW\n    movq %rax, %rsi\n    leaq .Lws_cwbuf(%rip), %rdi\n    movq \$32766, %rcx\n.Lws_fr_cl:\n    movzbq (%rsi), %rax\n    movzbq 1(%rsi), %rdx\n    movb %al, (%rdi)\n    movb %dl, 1(%rdi)\n    addq \$2, %rsi\n    addq \$2, %rdi\n    addq %rdx, %rax\n    testq %rax, %rax\n    jz .Lws_fr_cl_done\n    decq %rcx\n    jnz .Lws_fr_cl\n    movb \$0, (%rdi)\n    movb \$0, 1(%rdi)\n.Lws_fr_cl_done:\n    leaq .Lws_cwbuf(%rip), %rdx\n    leaq .Lws_pbuf(%rip), %rcx\n    xorq %r8, %r8\n");
open my $o, '>:raw', $f; print $o $t; close $o; print "fixed $n\n";
