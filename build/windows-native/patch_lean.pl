# Lean start-up: the 4 MiB argv/envp block is reserved and committed on first touch (lazy table), like Linux
# commits pages on demand, instead of 4 MiB of commit charge in every process.
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $old = "    xorq %rcx, %rcx\n    movq \$4194304, %rdx\n    movq \$1060864, %r8\n    movq \$4, %r9\n    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lwst_oom\n    movq %rax, %rbx\n";
my $new = "    xorq %rcx, %rcx\n    movq \$4194304, %rdx\n    movq \$1056768, %r8\n    movq \$1, %r9\n    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lwst_oom\n    movq %rax, %rbx\n" .
"# reserved only: pages are committed on first touch through the lazy table (the handler is already installed)\n" .
"    call .Lws_nr_slot\n    testq %rax, %rax\n    jz .Lwst_argv_commit\n    movq %rbx, (%rax)\n    leaq 4194304(%rbx), %rcx\n    movq %rcx, 8(%rax)\n    jmp .Lwst_argv_ready\n" .
".Lwst_argv_commit:\n    movq %rbx, %rcx\n    movq \$4194304, %rdx\n    movq \$4096, %r8\n    movq \$4, %r9\n    call VirtualAlloc\n.Lwst_argv_ready:\n    movq %rbx, %rax\n";
my $i = index($t, $old); die "nf" if $i < 0; die "amb" if index($t, $old, $i + 1) >= 0; substr($t, $i, length($old)) = $new;
open my $o, '>:raw', $f or die; print $o $t; close $o; print "argv block is lazy\n";
