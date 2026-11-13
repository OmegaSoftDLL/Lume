local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i; my $n = 0;
sub ins { my ($anchor, $step) = @_; my $k = index($t, $anchor); die "nf: $anchor" if $k < 0; substr($t, $k, 0) = "    movq \$$step, .Lws_fk_step(%rip)\n"; $n++ }
ins("    movq 224(%rsp), %rax\n    movq %rax, .Lws_fk_proc(%rip)\n", 1);
ins(".Lws_fr_ready:\n", 2); 
ins("# every writable region of this image", 3);
ins("# every registered region\n", 4);
ins("# the stack: from the page holding rsp", 5);
ins("# file, pipe and socket handles into the child", 6);
ins("# the child thread continues at .Lws_fork_resume", 7);
$t =~ s/\.Lws_fr_dead:\n    movq \.Lws_fk_thread\(%rip\), %rcx\n    call CloseHandle\n    movq \.Lws_fk_proc\(%rip\), %rcx\n    call CloseHandle\n\.Lws_eagain:\n    movq \$-11, %rax\n    jmp \.Lws_ret\n/.Lws_fr_dead:\n    movq .Lws_fk_thread(%rip), %rcx\n    call CloseHandle\n    movq .Lws_fk_proc(%rip), %rcx\n    call CloseHandle\n    movq \$-1000, %rax\n    subq .Lws_fk_step(%rip), %rax\n    jmp .Lws_ret\n.Lws_eagain:\n    movq \$-11, %rax\n    jmp .Lws_ret\n/ or die "dead";
$t =~ s/(    \.lcomm \.Lws_fk_ready, 8\n)/$1    .lcomm .Lws_fk_step, 8\n/ or die "bss";
open my $o, '>:raw', $f; print $o $t; close $o; print "instrumented $n\n";
