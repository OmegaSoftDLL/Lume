# Win64 layer: uname(2) and the CPU-time clocks.
# - uname(buf): sysname "Windows_NT", nodename (GetComputerNameA), release "major.minor.build" read from
#   KUSER_SHARED_DATA (0x7FFE0000: NtBuildNumber +0x260, NtMajorVersion +0x26C, NtMinorVersion +0x270, the
#   page every process maps read-only), version "", machine "x86_64"; 65-byte fields as in Linux struct utsname.
# - clock_gettime(CLOCK_PROCESS_CPUTIME_ID=2 / CLOCK_THREAD_CPUTIME_ID=3): user + kernel time of the process /
#   thread (GetProcessTimes / GetThreadTimes, 100 ns units), as Linux reports CPU time for those ids.
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in; my $n = 0;
sub rep { my ($o, $nw) = @_; my $i = index($t, $o); die "nf:\n$o" if $i < 0; die "amb:\n$o" if index($t, $o, $i + 1) >= 0; substr($t, $i, length($o)) = $nw; $n++ }
rep("    cmpq \$228, %rax\n    je .Lws_clock\n", "    cmpq \$228, %rax\n    je .Lws_clock\n    cmpq \$63, %rax\n    je .Lws_uname\n");
rep(".Lws_clock:\n    testq %r12, %r12\n    jz .Lws_clock_real\n",
".Lws_clock:\n    testq %r12, %r12\n    jz .Lws_clock_real\n    cmpq \$2, %r12\n    je .Lws_clock_cpu\n    cmpq \$3, %r12\n    je .Lws_clock_cpu\n");
rep(".Lws_clock_real:\n",
"# CPU time: FILETIME creation, exit, kernel, user at 64/72/80/88(%rsp)\n" .
".Lws_clock_cpu:\n    cmpq \$3, %r12\n    je .Lws_clock_thr\n    movq \$-1, %rcx\n    leaq 64(%rsp), %rdx\n    leaq 72(%rsp), %r8\n    leaq 80(%rsp), %r9\n    leaq 88(%rsp), %rax\n    movq %rax, 32(%rsp)\n    call GetProcessTimes\n    jmp .Lws_clock_cpu2\n" .
".Lws_clock_thr:\n    movq \$-2, %rcx\n    leaq 64(%rsp), %rdx\n    leaq 72(%rsp), %r8\n    leaq 80(%rsp), %r9\n    leaq 88(%rsp), %rax\n    movq %rax, 32(%rsp)\n    call GetThreadTimes\n" .
".Lws_clock_cpu2:\n    shlq \$32, %rax\n    shrq \$32, %rax\n    testq %rax, %rax\n    jz .Lws_fail\n    movq 80(%rsp), %rax\n    addq 88(%rsp), %rax\n    xorq %rdx, %rdx\n    movq \$10000000, %rcx\n    divq %rcx\n    movq %rax, (%r13)\n    imulq \$100, %rdx\n    movq %rdx, 8(%r13)\n    jmp .Lws_zero\n" .
".Lws_clock_real:\n");
rep(".Lws_getdents:\n",
"# uname(r12 = struct utsname, 6 x 65 bytes)\n" .
".Lws_uname:\n    movq %r12, %rdi\n    movq \$390, %rcx\n.Lws_un_z:\n    movb \$0, (%rdi)\n    incq %rdi\n    decq %rcx\n    jnz .Lws_un_z\n" .
"    leaq .Lws_un_sys(%rip), %rsi\n    movq %r12, %rdi\n    call .Lws_un_cpy\n    leaq .Lws_un_mach(%rip), %rsi\n    leaq 260(%r12), %rdi\n    call .Lws_un_cpy\n" .
"    movq \$64, 64(%rsp)\n    leaq 65(%r12), %rcx\n    leaq 64(%rsp), %rdx\n    call GetComputerNameA\n" .
"    leaq 130(%r12), %rdi\n    movq \$2147353196, %rax\n    movq (%rax), %rax\n    shlq \$32, %rax\n    shrq \$32, %rax\n    call .Lws_un_num\n    movb \$46, (%rdi)\n    incq %rdi\n    movq \$2147353200, %rax\n    movq (%rax), %rax\n    shlq \$32, %rax\n    shrq \$32, %rax\n    call .Lws_un_num\n" .
"    movb \$46, (%rdi)\n    incq %rdi\n    movq \$2147353184, %rax\n    movq (%rax), %rax\n    shlq \$32, %rax\n    shrq \$32, %rax\n    call .Lws_un_num\n    jmp .Lws_zero\n" .
"# copy the C string rsi to rdi (no API call)\n.Lws_un_cpy:\n    movzbq (%rsi), %rax\n    movb %al, (%rdi)\n    testq %rax, %rax\n    jz .Lws_un_cpy_out\n    incq %rsi\n    incq %rdi\n    jmp .Lws_un_cpy\n.Lws_un_cpy_out:\n    ret\n" .
"# write eax (zero-extended) in decimal at rdi, rdi advanced (no API call)\n.Lws_un_num:\n    movq \$10, %rcx\n    xorq %r8, %r8\n.Lws_un_n1:\n    cqto\n    idivq %rcx\n    addq \$48, %rdx\n    pushq %rdx\n    incq %r8\n    testq %rax, %rax\n    jnz .Lws_un_n1\n.Lws_un_n2:\n    popq %rax\n    movb %al, (%rdi)\n    incq %rdi\n    decq %r8\n    jnz .Lws_un_n2\n    ret\n" .
".Lws_getdents:\n");
rep("    .section .rodata\n.Lws_urandom:\n", "    .section .rodata\n.Lws_un_sys:\n    .asciz \"Windows_NT\"\n.Lws_un_mach:\n    .asciz \"x86_64\"\n.Lws_urandom:\n");
rep("    .extern KERNEL32.dll!SetFileAttributesW\n", "    .extern KERNEL32.dll!SetFileAttributesW\n    .extern KERNEL32.dll!GetProcessTimes\n    .extern KERNEL32.dll!GetThreadTimes\n    .extern KERNEL32.dll!GetComputerNameA\n");
open my $o, '>:raw', $f or die; print $o $t; close $o; print "uname/clock patch: $n\n";
