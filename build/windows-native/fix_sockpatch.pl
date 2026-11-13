local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i;
# drop the unused helper
$t =~ s/# r12 = fd of a socket -> rax = SOCKET \(or to \.Lws_ebadf \/ ENOTSOCK\)\n\.Lws_sockh:\n    pushq %rbx\n    call \.Lws_fdh\n    popq %rbx\n    ret\n// or die "h";
# commit a lazily reserved buffer before recv / send
$t =~ s/\.Lws_read_sock:\n    movq %rax, %rcx\n/.Lws_read_sock:\n    movq %rax, 72(%rsp)\n    movq %r13, %rcx\n    movq %r14, %rdx\n    call .Lws_nr_commit\n    movq 72(%rsp), %rcx\n/ or die "r";
$t =~ s/\.Lws_write_sock:\n    movq %rax, %rcx\n/.Lws_write_sock:\n    movq %rax, 72(%rsp)\n    movq %r13, %rcx\n    movq %r14, %rdx\n    call .Lws_nr_commit\n    movq 72(%rsp), %rcx\n/ or die "w";
# one value per .quad line, no .balign
$t =~ s/    \.byte 0\n    \.balign 8\n/    .byte 0\n/ or die "b";
$t =~ s{^    \.quad (.*,.*)$}{join("\n", map { "    .quad $_" } split(/, /, $1))}gme;
open my $o, '>:raw', $f; print $o $t; close $o; print "ok\n";
