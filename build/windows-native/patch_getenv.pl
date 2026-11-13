# Add os_getenv(name) to runtime_core.lume: the value of NAME in the process environment, "" when absent.
# Same code on Linux and Windows (both start with envp after argv's terminator). Exact, case-sensitive match.
use strict; use warnings;
local $/;
my $f = shift;
open my $in, '<:raw', $f or die;
my $t = <$in>;
close $in;
my $old = 'os_platform:\n" + "    leaq .Lrt_platform(%rip), %rdi\n" + "    jmp mkstr\n"';
my $i = index($t, $old);
die "os_platform not found" if $i < 0;
die "already patched" if index($t, 'os_getenv:') >= 0;
my @asm = (
 'os_getenv:', '    call __rt_cstr', '    movq %rax, %rsi', '    cmpb $0, (%rsi)', '    je .Lrt_oge_none',
 '    movq .Lrt_os_argv(%rip), %rcx', '    testq %rcx, %rcx', '    jz .Lrt_oge_none',
 '    movq .Lrt_os_argc(%rip), %rax', '    addq $1, %rax', '    imulq $8, %rax', '    addq %rax, %rcx',
 '.Lrt_oge_1:', '    movq (%rcx), %rdx', '    testq %rdx, %rdx', '    jz .Lrt_oge_none', '    movq %rsi, %rdi',
 '.Lrt_oge_2:', '    movzbq (%rdi), %rax', '    testq %rax, %rax', '    jz .Lrt_oge_eq', '    cmpb %al, (%rdx)',
 '    jne .Lrt_oge_3', '    incq %rdi', '    incq %rdx', '    jmp .Lrt_oge_2',
 '.Lrt_oge_eq:', '    cmpb $61, (%rdx)', '    jne .Lrt_oge_3', '    leaq 1(%rdx), %rdi', '    jmp mkstr',
 '.Lrt_oge_3:', '    addq $8, %rcx', '    jmp .Lrt_oge_1',
 '.Lrt_oge_none:', '    leaq .Lrt_oge_empty(%rip), %rdi', '    jmp mkstr');
my $new = $old . join('', map { ' + "' . $_ . '\n"' } @asm);
substr($t, $i, length($old)) = $new;
my $ro = '.Lrt_platform:\n" + "    .asciz \"linux\"\n"';
my $j = index($t, $ro);
die "rodata platform not found" if $j < 0;
substr($t, $j, length($ro)) = $ro . ' + ".Lrt_oge_empty:\n" + "    .byte 0\n"';
open my $o, '>:raw', $f or die;
print $o $t;
close $o;
print "os_getenv added\n";
