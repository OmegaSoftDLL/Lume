# Memory fidelity fixes in the Win64 layer (exact substitutions on win64_layer.s):
# - MAP_NORESERVE (0x4000) with RW protection reserves only; pages are committed on first touch by the VEH
#   (64 KiB at a time) or before a read/write hands the buffer to the kernel, as Linux commits on demand;
# - PROT_READ / PROT_READ|PROT_EXEC map to PAGE_READONLY / PAGE_EXECUTE_READ (no silent upgrade to writable);
# - madvise(MADV_DONTNEED) that cannot recommit (commit limit reached) ends with the runtime's out-of-memory
#   diagnostic and status 12 instead of a later access violation;
# - the VEH maps STATUS_ILLEGAL_INSTRUCTION to SIGILL (status 132, as Linux) and leaves access violations outside
#   this image's code to the next handler (a DLL's own __try), as Linux never sees those.
use strict; use warnings;
local $/;
my $f = shift;
open my $in, '<:raw', $f or die "$f: $!";
my $t = <$in>;
close $in;
my $n = 0;
sub rep {
  my ($old, $new) = @_;
  my $i = index($t, $old);
  die "not found:\n$old\n" if $i < 0;
  die "ambiguous:\n$old\n" if index($t, $old, $i + 1) >= 0;
  substr($t, $i, length($old)) = $new;
  $n++;
}

# protection value for prot r14 into r9: PROT_WRITE -> RW / RWX, else READONLY / EXECUTE_READ
rep(".Lws_mmap:\n    movq %r15, %rax\n    andq \$32, %rax\n    testq %rax, %rax\n    jz .Lws_enodev\n    xorq %rcx, %rcx\n    movq %r13, %rdx\n    movq \$8192, %r8\n    movq \$1, %r9\n    testq %r14, %r14\n    jz .Lws_mmap_go\n    movq \$12288, %r8\n    movq \$4, %r9\n    movq %r14, %rax\n    andq \$4, %rax\n    testq %rax, %rax\n    jz .Lws_mmap_go\n    movq \$64, %r9\n.Lws_mmap_go:\n",
".Lws_mmap:\n    movq %r15, %rax\n    andq \$32, %rax\n    testq %rax, %rax\n    jz .Lws_enodev\n" .
"# MAP_NORESERVE + read/write (not exec): reserve now, commit on first touch\n" .
"    movq %r15, %rax\n    andq \$16384, %rax\n    testq %rax, %rax\n    jz .Lws_mmap_std\n    cmpq \$3, %r14\n    jne .Lws_mmap_std\n    call .Lws_nr_slot\n    testq %rax, %rax\n    jz .Lws_mmap_std\n    movq %rax, 80(%rsp)\n" .
"    xorq %rcx, %rcx\n    movq %r13, %rdx\n    movq \$8192, %r8\n    movq \$1, %r9\n    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lws_enomem\n    movq 80(%rsp), %rcx\n    movq %rax, (%rcx)\n    movq %rax, %rdx\n    addq %r13, %rdx\n    movq %rdx, 8(%rcx)\n    jmp .Lws_ret\n" .
".Lws_mmap_std:\n    xorq %rcx, %rcx\n    movq %r13, %rdx\n    movq \$8192, %r8\n    movq \$1, %r9\n    testq %r14, %r14\n    jz .Lws_mmap_go\n    movq \$12288, %r8\n    call .Lws_prot\n    movq %rax, %r9\n    xorq %rcx, %rcx\n    movq %r13, %rdx\n.Lws_mmap_go:\n");

rep(".Lws_mprotect:\n    testq %r14, %r14\n    jz .Lws_mprotect_none\n    movq \$4, %rax\n    movq %r14, %rcx\n    andq \$4, %rcx\n    testq %rcx, %rcx\n    jz .Lws_mprotect_p\n    movq \$64, %rax\n.Lws_mprotect_p:\n",
".Lws_mprotect:\n    testq %r14, %r14\n    jz .Lws_mprotect_none\n    call .Lws_prot\n");

# munmap forgets a lazily committed reservation
rep(".Lws_munmap:\n    movq %r12, %rcx\n    xorq %rdx, %rdx\n    movq \$32768, %r8\n",
".Lws_munmap:\n    leaq .Lws_nrt(%rip), %rax\n    movq \$64, %rcx\n.Lws_mu_nr:\n    cmpq %r12, (%rax)\n    jne .Lws_mu_nx\n    movq \$0, (%rax)\n    movq \$0, 8(%rax)\n.Lws_mu_nx:\n    addq \$16, %rax\n    decq %rcx\n    jnz .Lws_mu_nr\n    movq %r12, %rcx\n    xorq %rdx, %rdx\n    movq \$32768, %r8\n");

# madvise: a failed recommit is out of memory, reported like the runtime's own allocator
rep("    movq \$4096, %r8\n    movq \$4, %r9\n    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lws_enomem\n    jmp .Lws_zero\n.Lws_exit:\n",
"    movq \$4096, %r8\n    movq \$4, %r9\n    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lrt_alloc_oom\n    jmp .Lws_zero\n" .
"# r14 = PROT_* (non-zero) -> rax = PAGE_* ; no API call\n" .
".Lws_prot:\n    movq %r14, %rax\n    andq \$2, %rax\n    testq %rax, %rax\n    jz .Lws_prot_ro\n    movq %r14, %rax\n    andq \$4, %rax\n    testq %rax, %rax\n    movq \$4, %rax\n    jz .Lws_prot_out\n    movq \$64, %rax\n    ret\n" .
".Lws_prot_ro:\n    movq %r14, %rax\n    andq \$4, %rax\n    testq %rax, %rax\n    movq \$2, %rax\n    jz .Lws_prot_out\n    movq \$32, %rax\n.Lws_prot_out:\n    ret\n" .
"# free slot of the lazy-commit table -> rax (0 when full); no API call\n" .
".Lws_nr_slot:\n    leaq .Lws_nrt(%rip), %rax\n    movq \$64, %rcx\n.Lws_nrs_l:\n    cmpq \$0, (%rax)\n    je .Lws_nrs_out\n    addq \$16, %rax\n    decq %rcx\n    jnz .Lws_nrs_l\n    xorq %rax, %rax\n.Lws_nrs_out:\n    ret\n" .
"# commit the part of [rcx, rcx + rdx) that lies in lazily committed reservations (before the kernel reads or\n" .
"# writes a user buffer: it reports ERROR_NOACCESS instead of faulting). Entered by call; keeps r12-r15.\n" .
".Lws_nr_commit:\n    pushq %rbx\n    pushq %rsi\n    pushq %rdi\n    subq \$48, %rsp\n    movq %rcx, %rsi\n    movq %rcx, %rdi\n    addq %rdx, %rdi\n    leaq .Lws_nrt(%rip), %rbx\n    movq \$64, 40(%rsp)\n" .
".Lws_nrc_l:\n    movq (%rbx), %rcx\n    testq %rcx, %rcx\n    jz .Lws_nrc_n\n    cmpq %rsi, %rcx\n    jge .Lws_nrc_lo\n    movq %rsi, %rcx\n.Lws_nrc_lo:\n    movq 8(%rbx), %rdx\n    cmpq %rdi, %rdx\n    jle .Lws_nrc_hi\n    movq %rdi, %rdx\n.Lws_nrc_hi:\n    andq \$-4096, %rcx\n    cmpq %rdx, %rcx\n    jge .Lws_nrc_n\n    subq %rcx, %rdx\n    movq \$4096, %r8\n    movq \$4, %r9\n    call VirtualAlloc\n" .
".Lws_nrc_n:\n    addq \$16, %rbx\n    movq 40(%rsp), %rax\n    decq %rax\n    movq %rax, 40(%rsp)\n    jnz .Lws_nrc_l\n    addq \$48, %rsp\n    popq %rdi\n    popq %rsi\n    popq %rbx\n    ret\n" .
".Lws_exit:\n");

# read / write: commit a lazily reserved user buffer first
rep("    movq %rax, 72(%rsp)\n.Lws_read_h:\n    movq %rax, %rcx\n",
"    movq %rax, 72(%rsp)\n    movq %r13, %rcx\n    movq %r14, %rdx\n    call .Lws_nr_commit\n    movq 72(%rsp), %rax\n.Lws_read_h:\n    movq %rax, %rcx\n");
rep(".Lws_write:\n    call .Lws_fdh\n    cmpq \$1, %rcx\n    je .Lws_write_h\n    cmpq \$4, %rcx\n    jne .Lws_ebadf\n.Lws_write_h:\n",
".Lws_write:\n    call .Lws_fdh\n    cmpq \$1, %rcx\n    je .Lws_write_c\n    cmpq \$4, %rcx\n    jne .Lws_ebadf\n.Lws_write_c:\n    movq %rax, 72(%rsp)\n    movq %r13, %rcx\n    movq %r14, %rdx\n    call .Lws_nr_commit\n    movq 72(%rsp), %rax\n.Lws_write_h:\n");

# VEH: illegal instruction -> SIGILL; lazy commit; foreign access violations go on to the next handler
rep("    movq \$3221225622, %rdx\n    cmpq %rdx, %rax\n    jne .Lwv_pass\n    xorq %r11, %r11\n    jmp .Lwv_segv\n.Lwv_av:\n    movq 40(%r8), %r11\n    jmp .Lwv_segv\n",
"    movq \$3221225622, %rdx\n    cmpq %rdx, %rax\n    jne .Lwv_pass\n    xorq %r11, %r11\n    jmp .Lwv_segv\n" .
".Lwv_av:\n    movq 40(%r8), %r11\n" .
"# a first touch of a lazily committed reservation: commit its 64 KiB block and retry the instruction\n" .
"    leaq .Lws_nrt(%rip), %rax\n    movq \$64, %rcx\n.Lwv_nr_l:\n    movq (%rax), %rdx\n    testq %rdx, %rdx\n    jz .Lwv_nr_n\n    cmpq %rdx, %r11\n    jl .Lwv_nr_n\n    cmpq 8(%rax), %r11\n    jl .Lwv_nr_hit\n.Lwv_nr_n:\n    addq \$16, %rax\n    decq %rcx\n    jnz .Lwv_nr_l\n    jmp .Lwv_own\n" .
".Lwv_nr_hit:\n    movq %r11, 200(%rsp)\n    movq %r10, 208(%rsp)\n    movq %r11, %rcx\n    andq \$-65536, %rcx\n    cmpq %rdx, %rcx\n    jge .Lwv_nr_lo\n    movq %rdx, %rcx\n.Lwv_nr_lo:\n    movq %rcx, %rdx\n    addq \$65536, %rdx\n    cmpq 8(%rax), %rdx\n    jle .Lwv_nr_hi\n    movq 8(%rax), %rdx\n.Lwv_nr_hi:\n    subq %rcx, %rdx\n    movq \$4096, %r8\n    movq \$4, %r9\n    call VirtualAlloc\n    movq 200(%rsp), %r11\n    movq 208(%rsp), %r10\n    testq %rax, %rax\n    jz .Lwv_segv\n    movq \$-1, %rax\n    jmp .Lwv_out\n" .
"# an access violation raised outside this image's code (inside a DLL that may handle it) is not ours\n" .
".Lwv_own:\n    movq 248(%r9), %rax\n    movq \$4194304, %rdx\n    cmpq %rdx, %rax\n    jl .Lwv_pass\n    leaq __win_image_hi(%rip), %rdx\n    cmpq %rdx, %rax\n    jge .Lwv_pass\n    jmp .Lwv_segv\n");
# end of this image's code: the layer's text is the last text of the program (.text is the first PE section)
rep("    ret\n    .section .rodata\n.Lws_urandom:\n", "    ret\n__win_image_hi:\n    .section .rodata\n.Lws_urandom:\n");

rep("    .lcomm .Lws_fdt, 16384\n", "    .lcomm .Lws_fdt, 16384\n    .lcomm .Lws_nrt, 1024\n");

open my $o, '>:raw', $f or die;
print $o $t;
close $o;
print "memory patch: $n substitutions\n";
