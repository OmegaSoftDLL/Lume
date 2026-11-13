local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i;
my $bs = chr(92);
my $nl = $bs . 'n';
$t =~ s/\Qmovl (%rax), %eax${nl}\E/movq (%rax), %rax${nl}    shlq ${bs}\$32, %rax${nl}    shrq ${bs}\$32, %rax${nl}/g;
$t =~ s/\Q.Lws_un_num:${nl}    movl %eax, %eax${nl}\E/.Lws_un_num:${nl}/;
$t =~ s/\Qxorq %rdx, %rdx${nl}    divq %rcx${nl}\E/cqto${nl}    idivq %rcx${nl}/;
$t =~ s/\Qxorq %rdx, %rdx${nl}    movq ${bs}\$10000000, %rcx${nl}    divq %rcx${nl}\E/cqto${nl}    movq ${bs}\$10000000, %rcx${nl}    idivq %rcx${nl}/;
open my $o, '>:raw', $f; print $o $t; close $o;
