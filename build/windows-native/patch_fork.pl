# Win64 layer: a real fork for os_fork (the program goes on in two processes at once), as Linux fork does.
# os_run* keep the vfork emulation (fork + execve is exact and cheap there); os_fork passes rdi = 'FORK'.
#   parent: CreateProcessW(this .exe, same command line, LUME_FORK=1 in the environment, std handles inherited);
#           waits until the child flags .Lws_fk_ready in its own .bss (read with ReadProcessMemory);
#           suspends it; copies this image's .bss, every region the layer allocated (registry .Lws_regs: the
#           collector heap, arenas, buffers, argv), and the used stack; duplicates every file / pipe / socket
#           handle of the fd table into it; points its thread at .Lws_fork_resume with this handler frame's
#           rsp/rbp; resumes it; records it as a child (waitpid); returns its pid.
#   child:  __win_start sees LUME_FORK, removes it (grandchildren start normally), sets up the exception handler
#           and the console, flags ready and loops until the parent takes over.
#   child, resumed: clears what belongs to the parent only (its children, timer, DLL entry points), restarts
#           Winsock when it holds sockets, puts a guard page under its stack, and returns 0 from fork.
# The image has a fixed base (no ASLR), so every address the copy carries is valid in the child.
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in; my $n = 0;
sub rep { my ($o, $nw) = @_; my $i = index($t, $o); die "nf:\n$o" if $i < 0; die "amb:\n$o" if index($t, $o, $i + 1) >= 0; substr($t, $i, length($o)) = $nw; $n++ }

# --- region registry: mmap (both paths), munmap, argv block ---
rep("    movq 80(%rsp), %rcx\n    movq %rax, (%rcx)\n    movq %rax, %rdx\n    addq %r13, %rdx\n    movq %rdx, 8(%rcx)\n    jmp .Lws_ret\n",
    "    movq 80(%rsp), %rcx\n    movq %rax, (%rcx)\n    movq %rax, %rdx\n    addq %r13, %rdx\n    movq %rdx, 8(%rcx)\n    movq %rax, %rcx\n    movq %r13, %rdx\n    call .Lws_reg_add\n    jmp .Lws_ret\n");
rep(".Lws_mmap_go:\n    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lws_enomem\n    jmp .Lws_ret\n",
    ".Lws_mmap_go:\n    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lws_enomem\n    movq %rax, %rcx\n    movq %r13, %rdx\n    call .Lws_reg_add\n    jmp .Lws_ret\n");
rep(".Lws_munmap:\n", ".Lws_munmap:\n    movq %r12, %rcx\n    call .Lws_reg_del\n");
rep("    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lwst_oom\n    movq %rax, %rbx\n",
    "    call VirtualAlloc\n    testq %rax, %rax\n    jz .Lwst_oom\n    movq %rax, %rbx\n    movq %rax, %rcx\n    movq \$4194304, %rdx\n    call .Lws_reg_add\n");

# --- child start: fork mode ---
rep("    movq \$1, %rcx\n    leaq __win_veh(%rip), %rdx\n    call AddVectoredExceptionHandler\n",
    "    movq \$1, %rcx\n    leaq __win_veh(%rip), %rdx\n    call AddVectoredExceptionHandler\n" .
    "# a fork child: drop LUME_FORK, flag ready, wait for the parent to replace this thread's state\n" .
    "    leaq .Lws_fk_var(%rip), %rcx\n    leaq 64(%rsp), %rdx\n    movq \$16, %r8\n    call GetEnvironmentVariableA\n    testq %rax, %rax\n    jz .Lwst_normal\n" .
    "    leaq .Lws_fk_var(%rip), %rcx\n    xorq %rdx, %rdx\n    call SetEnvironmentVariableA\n    movq \$1, .Lws_fk_ready(%rip)\n.Lwst_fk_wait:\n    cmpq \$0, .Lws_fk_ready(%rip)\n    jne .Lwst_fk_wait\n    jmp .Lwst_fk_wait\n.Lwst_normal:\n");

# --- fork entry: real fork for os_fork ---
rep(".Lws_fork:\n    cmpq \$0, .Lws_fk_mode(%rip)\n", ".Lws_fork:\n    movq \$1263685446, %rax\n    cmpq %rax, %r12\n    je .Lws_fork_real\n    cmpq \$0, .Lws_fk_mode(%rip)\n");

my $L = <<'ASM';
# ---- region registry (base, size) of every block the layer maps: what a real fork copies --------------------
# (keeps rax: mmap returns it)
.Lws_reg_add:
    leaq .Lws_regs(%rip), %r10
    movq $1024, %r8
.Lws_rga_l:
    cmpq $0, (%r10)
    je .Lws_rga_put
    addq $16, %r10
    decq %r8
    jnz .Lws_rga_l
    ret
.Lws_rga_put:
    movq %rcx, (%r10)
    movq %rdx, 8(%r10)
    ret
.Lws_reg_del:
    leaq .Lws_regs(%rip), %r10
    movq $1024, %r8
.Lws_rgd_l:
    cmpq %rcx, (%r10)
    jne .Lws_rgd_n
    movq $0, (%r10)
    movq $0, 8(%r10)
.Lws_rgd_n:
    addq $16, %r10
    decq %r8
    jnz .Lws_rgd_l
    ret
# copy [rcx, rcx + rdx) of this process into the child (.Lws_fk_proc): reserve it there at the same address
# (r8 = 1) or not (r8 = 0), then commit and write every committed run; rax = 0 on success. Entered by call;
# keeps rbx, rsi, rdi, r12-r15 (uses its own frame).
.Lws_fk_copy:
    pushq %rbx
    pushq %rsi
    pushq %rdi
    pushq %r12
    pushq %r13
    subq $112, %rsp
    movq %rcx, %rsi
    movq %rcx, %rdi
    addq %rdx, %rdi
    testq %r8, %r8
    jz .Lws_fkc_walk
    movq .Lws_fk_proc(%rip), %rcx
    movq %rsi, %rdx
    movq %rdi, %r8
    subq %rsi, %r8
    movq $8192, %r9
    movq $1, 32(%rsp)
    call VirtualAllocEx
    cmpq %rsi, %rax
    jne .Lws_fkc_fail
.Lws_fkc_walk:
    cmpq %rdi, %rsi
    jge .Lws_fkc_ok
    movq %rsi, %rcx
    leaq 48(%rsp), %rdx
    movq $48, %r8
    call VirtualQuery
    testq %rax, %rax
    jz .Lws_fkc_fail
    movq 72(%rsp), %rbx
    movq 48(%rsp), %rax
    addq %rax, %rbx
    cmpq %rdi, %rbx
    jle .Lws_fkc_end
    movq %rdi, %rbx
.Lws_fkc_end:
    movq 80(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    cmpq $4096, %rax
    jne .Lws_fkc_next
    movq 84(%rsp), %r12
    shlq $32, %r12
    shrq $32, %r12
    andq $-257, %r12
    movq .Lws_fk_proc(%rip), %rcx
    movq %rsi, %rdx
    movq %rbx, %r8
    subq %rsi, %r8
    movq $4096, %r9
    movq %r12, 32(%rsp)
    call VirtualAllocEx
    testq %rax, %rax
    jz .Lws_fkc_fail
    cmpq $1, %r12
    je .Lws_fkc_next
    movq .Lws_fk_proc(%rip), %rcx
    movq %rsi, %rdx
    movq %rsi, %r8
    movq %rbx, %r9
    subq %rsi, %r9
    movq $0, 32(%rsp)
    call WriteProcessMemory
    testq %rax, %rax
    jz .Lws_fkc_fail
.Lws_fkc_next:
    movq %rbx, %rsi
    jmp .Lws_fkc_walk
.Lws_fkc_ok:
    xorq %rax, %rax
    jmp .Lws_fkc_out
.Lws_fkc_fail:
    movq $1, %rax
.Lws_fkc_out:
    addq $112, %rsp
    popq %r13
    popq %r12
    popq %rdi
    popq %rsi
    popq %rbx
    ret
# ---- fork for os_fork ---------------------------------------------------------------------------------------
.Lws_fork_real:
    cmpq $0, .Lws_fk_mode(%rip)
    jne .Lws_eagain
    leaq .Lws_fk_var(%rip), %rcx
    leaq .Lws_fk_one(%rip), %rdx
    call SetEnvironmentVariableA
    xorq %rcx, %rcx
    leaq .Lws_pbuf(%rip), %rdx
    movq $32768, %r8
    call GetModuleFileNameW
    leaq 112(%rsp), %rdi
    movq $13, %rcx
.Lws_fr_zsi:
    movq $0, (%rdi)
    addq $8, %rdi
    decq %rcx
    jnz .Lws_fr_zsi
    movq $104, 112(%rsp)
    movq $256, 172(%rsp)
    xorq %r14, %r14
.Lws_fr_std:
    movq $-10, %rcx
    subq %r14, %rcx
    call GetStdHandle
    movq %rax, 192(%rsp,%r14,8)
    movq %rax, %rcx
    movq $1, %rdx
    movq $1, %r8
    call SetHandleInformation
    incq %r14
    cmpq $3, %r14
    jl .Lws_fr_std
    call GetCommandLineW
    movq %rax, %rsi
    leaq .Lws_cwbuf(%rip), %rdi
    movq $32766, %rcx
.Lws_fr_cl:
    movzbq (%rsi), %rax
    movzbq 1(%rsi), %rdx
    movb %al, (%rdi)
    movb %dl, 1(%rdi)
    addq $2, %rsi
    addq $2, %rdi
    addq %rdx, %rax
    testq %rax, %rax
    jz .Lws_fr_cl_done
    decq %rcx
    jnz .Lws_fr_cl
    movb $0, (%rdi)
    movb $0, 1(%rdi)
.Lws_fr_cl_done:
    leaq .Lws_cwbuf(%rip), %rdx
    leaq .Lws_pbuf(%rip), %rcx
    xorq %r8, %r8
    xorq %r9, %r9
    movq $1, 32(%rsp)
    movq $0, 40(%rsp)
    movq $0, 48(%rsp)
    movq $0, 56(%rsp)
    leaq 112(%rsp), %rax
    movq %rax, 64(%rsp)
    leaq 224(%rsp), %rax
    movq %rax, 72(%rsp)
    call CreateProcessW
    movq %rax, %rbx
    leaq .Lws_fk_var(%rip), %rcx
    xorq %rdx, %rdx
    call SetEnvironmentVariableA
    shlq $32, %rbx
    shrq $32, %rbx
    testq %rbx, %rbx
    jz .Lws_fail
    movq 224(%rsp), %rax
    movq %rax, .Lws_fk_proc(%rip)
    movq 232(%rsp), %rax
    movq %rax, .Lws_fk_thread(%rip)
# wait until the child flags ready (or dies)
.Lws_fr_wait:
    movq $0, 88(%rsp)
    movq .Lws_fk_proc(%rip), %rcx
    leaq .Lws_fk_ready(%rip), %rdx
    leaq 88(%rsp), %r8
    movq $8, %r9
    movq $0, 32(%rsp)
    call ReadProcessMemory
    cmpq $1, 88(%rsp)
    je .Lws_fr_ready
    movq .Lws_fk_proc(%rip), %rcx
    movq $1, %rdx
    call WaitForSingleObject
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fr_dead
    jmp .Lws_fr_wait
.Lws_fr_ready:
    movq .Lws_fk_thread(%rip), %rcx
    call SuspendThread
# every writable region of this image (.bss: the runtime's and the layer's data)
    movq $4194304, %rsi
.Lws_fr_img:
    movq %rsi, %rcx
    leaq 48(%rsp), %rdx
    movq $48, %r8
    call VirtualQuery
    testq %rax, %rax
    jz .Lws_fr_img_done
    cmpq $4194304, 56(%rsp)
    jne .Lws_fr_img_done
    movq 84(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    cmpq $4, %rax
    jne .Lws_fr_img_next
    movq .Lws_fk_proc(%rip), %rcx
    movq 48(%rsp), %rdx
    movq 48(%rsp), %r8
    movq 72(%rsp), %r9
    movq $0, 32(%rsp)
    call WriteProcessMemory
    testq %rax, %rax
    jz .Lws_fr_abort
.Lws_fr_img_next:
    movq 48(%rsp), %rsi
    addq 72(%rsp), %rsi
    jmp .Lws_fr_img
.Lws_fr_img_done:
# every registered region
    leaq .Lws_regs(%rip), %r15
    movq $1024, %r13
.Lws_fr_regs:
    movq (%r15), %rcx
    testq %rcx, %rcx
    jz .Lws_fr_rnext
    movq 8(%r15), %rdx
    movq $1, %r8
    call .Lws_fk_copy
    testq %rax, %rax
    jnz .Lws_fr_abort
.Lws_fr_rnext:
    addq $16, %r15
    decq %r13
    jnz .Lws_fr_regs
# the stack: from the page holding rsp to the top of the committed stack
    movq %rsp, %rcx
    leaq 48(%rsp), %rdx
    movq $48, %r8
    call VirtualQuery
    movq 48(%rsp), %rax
    addq 72(%rsp), %rax
    movq %rax, 256(%rsp)
    movq 56(%rsp), %rax
    movq %rax, 264(%rsp)
    movq %rsp, %r12
    andq $-4096, %r12
    movq .Lws_fk_proc(%rip), %rcx
    movq %r12, %rdx
    leaq 48(%rsp), %r8
    movq $48, %r9
    call VirtualQueryEx
    movq 80(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    cmpq $65536, %rax
    jne .Lws_fr_stk
    movq .Lws_fk_proc(%rip), %rcx
    movq 264(%rsp), %rdx
    movq 256(%rsp), %r8
    subq %rdx, %r8
    movq $8192, %r9
    movq $1, 32(%rsp)
    call VirtualAllocEx
    testq %rax, %rax
    jz .Lws_fr_abort
.Lws_fr_stk:
    movq %r12, %rcx
    movq 256(%rsp), %rdx
    subq %r12, %rdx
    xorq %r8, %r8
    call .Lws_fk_copy
    testq %rax, %rax
    jnz .Lws_fr_abort
# file, pipe and socket handles into the child; directory streams are closed there
    leaq .Lws_fdt+48(%rip), %r15
    movq $3, %r13
.Lws_fr_fds:
    movq (%r15), %rax
    cmpq $1, %rax
    je .Lws_fr_dup
    cmpq $5, %rax
    je .Lws_fr_dup
    cmpq $2, %rax
    jne .Lws_fr_fnext
    movq $0, 88(%rsp)
    movq .Lws_fk_proc(%rip), %rcx
    movq %r15, %rdx
    leaq 88(%rsp), %r8
    movq $8, %r9
    movq $0, 32(%rsp)
    call WriteProcessMemory
    jmp .Lws_fr_fnext
.Lws_fr_dup:
    call GetCurrentProcess
    movq %rax, %rcx
    movq 8(%r15), %rdx
    movq .Lws_fk_proc(%rip), %r8
    leaq 88(%rsp), %r9
    movq $0, 88(%rsp)
    movq $0, 32(%rsp)
    movq $0, 40(%rsp)
    movq $2, 48(%rsp)
    call DuplicateHandle
    movq .Lws_fk_proc(%rip), %rcx
    leaq 8(%r15), %rdx
    leaq 88(%rsp), %r8
    movq $8, %r9
    movq $0, 32(%rsp)
    call WriteProcessMemory
.Lws_fr_fnext:
    addq $16, %r15
    incq %r13
    cmpq $1024, %r13
    jl .Lws_fr_fds
# the child thread continues at .Lws_fork_resume on this very handler frame
    leaq .Lws_ctx(%rip), %rbx
    addq $15, %rbx
    andq $-16, %rbx
    movq $1048587, 48(%rbx)
    movq .Lws_fk_thread(%rip), %rcx
    movq %rbx, %rdx
    call GetThreadContext
    testq %rax, %rax
    jz .Lws_fr_abort
    movq %rsp, 152(%rbx)
    movq %rbp, 160(%rbx)
    leaq .Lws_fork_resume(%rip), %rax
    movq %rax, 248(%rbx)
    movq .Lws_fk_thread(%rip), %rcx
    movq %rbx, %rdx
    call SetThreadContext
    testq %rax, %rax
    jz .Lws_fr_abort
    movq .Lws_fk_thread(%rip), %rcx
    call ResumeThread
    movq .Lws_fk_thread(%rip), %rcx
    call CloseHandle
    movq 240(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    movq %rax, 80(%rsp)
    call .Lws_kid_slot
    testq %rax, %rax
    jz .Lws_fr_done
    movq 80(%rsp), %rcx
    movq %rcx, (%rax)
    movq .Lws_fk_proc(%rip), %rcx
    movq %rcx, 8(%rax)
    movq $0, 16(%rax)
    movq $0, 24(%rax)
    movq $0, 32(%rax)
.Lws_fr_done:
    movq 80(%rsp), %rax
    jmp .Lws_ret
.Lws_fr_abort:
    movq .Lws_fk_proc(%rip), %rcx
    movq $1, %rdx
    call TerminateProcess
.Lws_fr_dead:
    movq .Lws_fk_thread(%rip), %rcx
    call CloseHandle
    movq .Lws_fk_proc(%rip), %rcx
    call CloseHandle
.Lws_eagain:
    movq $-11, %rax
    jmp .Lws_ret
# the child, on a copy of the parent's handler frame
.Lws_fork_resume:
    leaq .Lws_kids(%rip), %rdi
    movq $320, %rcx
.Lws_frs_z:
    movq $0, (%rdi)
    addq $8, %rdi
    decq %rcx
    jnz .Lws_frs_z
    movq $0, .Lws_timer(%rip)
    movq $0, .Lws_bcrypt_fn(%rip)
    movq $0, .Lws_ws_ok(%rip)
    movq $0, .Lws_fk_mode(%rip)
    movq $0, .Lws_fk_ready(%rip)
    leaq .Lws_fdt+48(%rip), %rdi
    movq $1021, %rcx
.Lws_frs_sk:
    cmpq $5, (%rdi)
    je .Lws_frs_ws
    addq $16, %rdi
    decq %rcx
    jnz .Lws_frs_sk
    jmp .Lws_frs_guard
.Lws_frs_ws:
    call .Lws_ws_init
.Lws_frs_guard:
    movq %rsp, %rcx
    leaq 64(%rsp), %rdx
    movq $48, %r8
    call VirtualQuery
    movq 64(%rsp), %rbx
    subq $4096, %rbx
    movq %rbx, %rcx
    leaq 64(%rsp), %rdx
    movq $48, %r8
    call VirtualQuery
    movq 96(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    cmpq $8192, %rax
    jne .Lws_frs_out
    movq %rbx, %rcx
    movq $4096, %rdx
    movq $4096, %r8
    movq $260, %r9
    call VirtualAlloc
.Lws_frs_out:
    xorq %rax, %rax
    jmp .Lws_ret
ASM
rep(".Lws_getdents:\n", $L . ".Lws_getdents:\n");
rep("    .section .rodata\n.Lws_ws_dll:\n", "    .section .rodata\n.Lws_fk_var:\n    .asciz \"LUME_FORK\"\n.Lws_fk_one:\n    .asciz \"1\"\n.Lws_ws_dll:\n");
rep("    .lcomm .Lws_ws_ok, 8\n", "    .lcomm .Lws_ws_ok, 8\n    .lcomm .Lws_regs, 16384\n    .lcomm .Lws_fk_ready, 8\n    .lcomm .Lws_fk_proc, 8\n    .lcomm .Lws_fk_thread, 8\n    .lcomm .Lws_ctx, 1264\n");
rep("    .extern KERNEL32.dll!GetComputerNameA\n", "    .extern KERNEL32.dll!GetComputerNameA\n" . join('', map { "    .extern KERNEL32.dll!$_\n" } qw(GetEnvironmentVariableA SetEnvironmentVariableA GetModuleFileNameW ReadProcessMemory WriteProcessMemory VirtualAllocEx VirtualQuery VirtualQueryEx SuspendThread ResumeThread GetThreadContext SetThreadContext DuplicateHandle)));
open my $o, '>:raw', $f or die; print $o $t; close $o; print "fork patch: $n\n";
