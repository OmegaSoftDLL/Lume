use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
sub rep { my ($o, $n) = @_; my $i = index($t, $o); die "nf: $o" if $i < 0; substr($t, $i, length($o)) = $n }
rep('"os_setenv:\n" + "    pushq %rbx\n"', '"os_unsetenv:\n" + "    movq $1, .Lrt_ose_unset(%rip)\n" + "    movq %rdi, %rsi\n" + "    jmp .Lrt_ose_body\n" + "os_setenv:\n" + "    movq $0, .Lrt_ose_unset(%rip)\n" + ".Lrt_ose_body:\n" + "    pushq %rbx\n"');
rep('".Lrt_ose_cpe:\n" + "    movq %r9, (%r15,%rdx,8)\n" + "    incq %rdx\n"', '".Lrt_ose_cpe:\n" + "    cmpq $0, .Lrt_ose_unset(%rip)\n" + "    jne .Lrt_ose_noadd\n" + "    movq %r9, (%r15,%rdx,8)\n" + "    incq %rdx\n" + ".Lrt_ose_noadd:\n"');
rep('"    .lcomm .Lrt_envp_ovr, 8\n"', '"    .lcomm .Lrt_envp_ovr, 8\n" + "    .lcomm .Lrt_ose_unset, 8\n"');
open my $o, '>:raw', $f or die; print $o $t; close $o; print "os_unsetenv added\n";
