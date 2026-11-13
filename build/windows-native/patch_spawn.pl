use strict; use warnings; local $/;
my ($cg, $rt) = @ARGV;
open my $in, '<:raw', $cg or die; my $t = <$in>; close $in;
sub rep { my ($o, $n) = @_; my $i = index($t, $o); die "nf: $o" if $i < 0; die "amb: $o" if index($t, $o, $i + 1) >= 0; substr($t, $i, length($o)) = $n }
rep('    jz .Lrt_os_run_capture_child\n    movq $0, .Lrt_pbuf(%rip)\n',
    '    jz .Lrt_os_run_capture_child\n    cmpq $0, .Lrt_spawn_nowait(%rip)\n    jne .Lrt_os_run_capture_spawned\n    movq $0, .Lrt_pbuf(%rip)\n');
rep('.Lrt_os_run_capture_child:\n',
    '.Lrt_os_run_capture_spawned:\n    movq %r15, %rdi\n    call mkint\n    addq $360, %rsp\n    popq %r15\n    popq %r14\n    popq %r13\n    popq %r12\n    popq %rbx\n    popq %rbp\n    ret\n' .
    'os_spawn_capture:\n    subq $8, %rsp\n    movq $1, .Lrt_spawn_nowait(%rip)\n    call os_run_capture\n    movq $0, .Lrt_spawn_nowait(%rip)\n    addq $8, %rsp\n    ret\n' .
    '.Lrt_os_run_capture_child:\n');
open my $o, '>:raw', $cg or die; print $o $t; close $o;
open $in, '<:raw', $rt or die; my $r = <$in>; close $in;
my $b = '.lcomm .Lrt_pbuf, 32\n';
my $i = index($r, $b); die "pbuf" if $i < 0;
substr($r, $i + length($b), 0) = '" + "    .lcomm .Lrt_spawn_nowait, 8\n';
open $o, '>:raw', $rt or die; print $o $r; close $o; print "os_spawn_capture added\n";
