use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in; my $n = 0;
sub rep { my ($o, $nw) = @_; my $i = index($t, $o); die "nf:\n$o" if $i < 0; die "amb" if index($t, $o, $i + 1) >= 0; substr($t, $i, length($o)) = $nw; $n++ }
rep(".Lws_kill:\n    call .Lws_kid_find\n",
".Lws_kill:\n# kill(own pid, sig): the process ends with 0xE0000000 | sig, which wait4 reports as that signal (sig 0: alive)\n" .
"    call GetCurrentProcessId\n    shlq \$32, %rax\n    shrq \$32, %rax\n    cmpq %rax, %r12\n    jne .Lws_kill_kid\n    testq %r13, %r13\n    jz .Lws_zero\n" .
"    movq %r13, %rdx\n    andq \$127, %rdx\n    movq \$3758096384, %rax\n    orq %rax, %rdx\n    movq \$-1, %rcx\n    call TerminateProcess\n    jmp .Lws_zero\n.Lws_kill_kid:\n    call .Lws_kid_find\n");
rep(".Lws_w_code:\n    movq \$3221225472, %rcx\n",
".Lws_w_code:\n    movq %rax, %rcx\n    andq \$-256, %rcx\n    movq \$3758096384, %rdx\n    cmpq %rdx, %rcx\n    jne .Lws_w_nt\n    movq %rax, %rcx\n    andq \$127, %rcx\n    jmp .Lws_w_sig\n.Lws_w_nt:\n    movq \$3221225472, %rcx\n");
open my $o, '>:raw', $f or die; print $o $t; close $o; print "kill-self patch: $n\n";
