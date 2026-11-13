    .need "KERNEL32.dll"
    .extern KERNEL32.dll!GetStdHandle
    .extern KERNEL32.dll!ReadFile
    .extern KERNEL32.dll!WriteFile
    .extern KERNEL32.dll!CreateFileW
    .extern KERNEL32.dll!CloseHandle
    .extern KERNEL32.dll!SetFilePointerEx
    .extern KERNEL32.dll!VirtualAlloc
    .extern KERNEL32.dll!VirtualFree
    .extern KERNEL32.dll!VirtualProtect
    .extern KERNEL32.dll!ExitProcess
    .extern KERNEL32.dll!GetLastError
    .extern KERNEL32.dll!MultiByteToWideChar
    .extern KERNEL32.dll!WideCharToMultiByte
    .extern KERNEL32.dll!FindFirstFileW
    .extern KERNEL32.dll!FindNextFileW
    .extern KERNEL32.dll!FindClose
    .extern KERNEL32.dll!LockFileEx
    .extern KERNEL32.dll!UnlockFileEx
    .extern KERNEL32.dll!FlushFileBuffers
    .extern KERNEL32.dll!GetCurrentDirectoryW
    .extern KERNEL32.dll!GetTempPathW
    .extern KERNEL32.dll!CreateDirectoryW
    .extern KERNEL32.dll!DeleteFileW
    .extern KERNEL32.dll!GetCurrentProcessId
    .extern KERNEL32.dll!GetCurrentProcess
    .extern KERNEL32.dll!GetProcessTimes
    .extern KERNEL32.dll!K32GetProcessMemoryInfo
    .extern KERNEL32.dll!QueryPerformanceCounter
    .extern KERNEL32.dll!QueryPerformanceFrequency
    .extern KERNEL32.dll!GetSystemTimePreciseAsFileTime
    .extern KERNEL32.dll!Sleep
    .extern KERNEL32.dll!GetCommandLineW
    .extern KERNEL32.dll!GetEnvironmentStringsW
    .extern KERNEL32.dll!SetConsoleOutputCP
    .extern KERNEL32.dll!SetConsoleCP
    .extern KERNEL32.dll!SetErrorMode
    .extern KERNEL32.dll!SetProcessInformation
    .extern KERNEL32.dll!SetHandleInformation
    .extern KERNEL32.dll!GetFileAttributesW
    .extern KERNEL32.dll!CreateProcessW
    .extern KERNEL32.dll!WaitForSingleObject
    .extern KERNEL32.dll!GetExitCodeProcess
    .extern KERNEL32.dll!TerminateProcess
    .extern KERNEL32.dll!CreatePipe
    .extern KERNEL32.dll!SetStdHandle
    .extern KERNEL32.dll!SetCurrentDirectoryW
    .extern KERNEL32.dll!MoveFileExW
    .extern KERNEL32.dll!GetFileType
    .extern KERNEL32.dll!RemoveDirectoryW
    .extern KERNEL32.dll!SetFileAttributesW
    .extern KERNEL32.dll!GetProcessTimes
    .extern KERNEL32.dll!GetThreadTimes
    .extern KERNEL32.dll!GetComputerNameA
    .extern KERNEL32.dll!GetEnvironmentVariableA
    .extern KERNEL32.dll!SetEnvironmentVariableA
    .extern KERNEL32.dll!GetModuleFileNameW
    .extern KERNEL32.dll!ReadProcessMemory
    .extern KERNEL32.dll!WriteProcessMemory
    .extern KERNEL32.dll!VirtualAllocEx
    .extern KERNEL32.dll!VirtualQuery
    .extern KERNEL32.dll!VirtualQueryEx
    .extern KERNEL32.dll!SuspendThread
    .extern KERNEL32.dll!ResumeThread
    .extern KERNEL32.dll!GetThreadContext
    .extern KERNEL32.dll!SetThreadContext
    .extern KERNEL32.dll!DuplicateHandle
    .extern KERNEL32.dll!CreateWaitableTimerExW
    .extern KERNEL32.dll!SetWaitableTimer
    .extern KERNEL32.dll!SetThreadStackGuarantee
    .extern KERNEL32.dll!AddVectoredExceptionHandler
    .extern KERNEL32.dll!LoadLibraryExA
    .extern KERNEL32.dll!GetProcAddress
    .extern KERNEL32.dll!CreateFileMappingW
    .extern KERNEL32.dll!MapViewOfFileEx
    .extern KERNEL32.dll!UnmapViewOfFile
    .section .text
# __win_syscall: the Linux x86-64 syscall ABI on top of Win64.
# In: rax = Linux syscall number, rdi rsi rdx r10 r8 r9 = arguments. Out: rax (>= 0, or -errno).
# Preserves every register except rax, rcx, r11, like the syscall instruction.
__win_syscall:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %r8
    pushq %r9
    pushq %r10
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    movq %rdi, %r12
    movq %rsi, %r13
    movq %rdx, %r14
    movq %r10, %r15
    movq %r8, %rbx
    andq $-16, %rsp
    subq $320, %rsp
    cmpq $0, %rax
    je .Lws_read
    cmpq $57, %rax
    je .Lws_fork
    cmpq $58, %rax
    je .Lws_fork
    cmpq $59, %rax
    je .Lws_execve
    cmpq $61, %rax
    je .Lws_wait4
    cmpq $62, %rax
    je .Lws_kill
    cmpq $22, %rax
    je .Lws_pipe
    cmpq $33, %rax
    je .Lws_dup2
    cmpq $1, %rax
    je .Lws_write
    cmpq $2, %rax
    je .Lws_open
    cmpq $3, %rax
    je .Lws_close
    cmpq $8, %rax
    je .Lws_lseek
    cmpq $9, %rax
    je .Lws_mmap
    cmpq $10, %rax
    je .Lws_mprotect
    cmpq $11, %rax
    je .Lws_munmap
    cmpq $13, %rax
    je .Lws_zero
    cmpq $131, %rax
    je .Lws_zero
    cmpq $160, %rax
    je .Lws_zero
    cmpq $28, %rax
    je .Lws_madvise
    cmpq $35, %rax
    je .Lws_nanosleep
    cmpq $39, %rax
    je .Lws_getpid
    cmpq $60, %rax
    je .Lws_exit
    cmpq $231, %rax
    je .Lws_exit
    cmpq $73, %rax
    je .Lws_flock
    cmpq $74, %rax
    je .Lws_fsync
    cmpq $79, %rax
    je .Lws_getcwd
    cmpq $83, %rax
    je .Lws_mkdir
    cmpq $80, %rax
    je .Lws_chdir
    cmpq $82, %rax
    je .Lws_rename
    cmpq $90, %rax
    je .Lws_chmod
    cmpq $87, %rax
    je .Lws_unlink
    cmpq $84, %rax
    je .Lws_rmdir
    cmpq $97, %rax
    je .Lws_getrlimit
    cmpq $98, %rax
    je .Lws_getrusage
    cmpq $217, %rax
    je .Lws_getdents
    cmpq $228, %rax
    je .Lws_clock
    cmpq $63, %rax
    je .Lws_uname
    cmpq $41, %rax
    je .Lws_socket
    cmpq $42, %rax
    je .Lws_connect
    cmpq $43, %rax
    je .Lws_accept
    cmpq $44, %rax
    je .Lws_sendto
    cmpq $45, %rax
    je .Lws_recvfrom
    cmpq $48, %rax
    je .Lws_shutdown
    cmpq $49, %rax
    je .Lws_bind
    cmpq $50, %rax
    je .Lws_listen
    cmpq $54, %rax
    je .Lws_setsockopt
    movq $-38, %rax
.Lws_ret:
    leaq -88(%rbp), %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %r10
    popq %r9
    popq %r8
    popq %rdx
    popq %rsi
    popq %rdi
    popq %rbx
    popq %rbp
    ret
.Lws_zero:
    xorq %rax, %rax
    jmp .Lws_ret
.Lws_ebadf:
    movq $-9, %rax
    jmp .Lws_ret
.Lws_enomem:
    movq $-12, %rax
    jmp .Lws_ret
.Lws_einval:
    movq $-22, %rax
    jmp .Lws_ret
.Lws_enotdir:
    movq $-20, %rax
    jmp .Lws_ret
.Lws_enodev:
    movq $-19, %rax
    jmp .Lws_ret
.Lws_erange:
    movq $-34, %rax
    jmp .Lws_ret
.Lws_fail:
    call GetLastError
    shlq $32, %rax
    shrq $32, %rax
.Lws_errmap:
    movq $-2, %rcx
    cmpq $2, %rax
    je .Lws_errset
    cmpq $3, %rax
    je .Lws_errset
    movq $-13, %rcx
    cmpq $5, %rax
    je .Lws_errset
    movq $-17, %rcx
    cmpq $80, %rax
    je .Lws_errset
    cmpq $183, %rax
    je .Lws_errset
    movq $-9, %rcx
    cmpq $6, %rax
    je .Lws_errset
    movq $-12, %rcx
    cmpq $8, %rax
    je .Lws_errset
    cmpq $14, %rax
    je .Lws_errset
    movq $-16, %rcx
    cmpq $32, %rax
    je .Lws_errset
    cmpq $33, %rax
    je .Lws_errset
    movq $-32, %rcx
    cmpq $109, %rax
    je .Lws_errset
    cmpq $232, %rax
    je .Lws_errset
    movq $-39, %rcx
    cmpq $145, %rax
    je .Lws_errset
    movq $-20, %rcx
    cmpq $267, %rax
    je .Lws_errset
    movq $-22, %rcx
    cmpq $87, %rax
    je .Lws_errset
    cmpq $123, %rax
    je .Lws_errset
    movq $-28, %rcx
    cmpq $112, %rax
    je .Lws_errset
    movq $-84, %rcx
    cmpq $1113, %rax
    je .Lws_errset
    movq $-18, %rcx
    cmpq $17, %rax
    je .Lws_errset
    movq $-24, %rcx
    cmpq $4, %rax
    je .Lws_errset
    movq $-36, %rcx
    cmpq $206, %rax
    je .Lws_errset
    movq $-5, %rcx
.Lws_errset:
    movq %rcx, %rax
    jmp .Lws_ret
# fds: a Linux-like table (.Lws_fdt, 16 bytes per fd: kind, value); 0/1/2 are the standard handles, new fds take the lowest free slot >= 3
.Lws_read:
    call .Lws_fdh
    testq %rcx, %rcx
    jz .Lws_ebadf
    cmpq $3, %rcx
    je .Lws_read_random
    cmpq $2, %rcx
    je .Lws_eisdir
    cmpq $5, %rcx
    je .Lws_read_sock
    movq %rax, 72(%rsp)
    movq %r13, %rcx
    movq %r14, %rdx
    call .Lws_nr_commit
    movq 72(%rsp), %rax
.Lws_read_h:
    movq %rax, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    movq $2147483647, %rax
    cmpq %rax, %r8
    jle .Lws_read_n
    movq %rax, %r8
.Lws_read_n:
    movq $0, 64(%rsp)
    leaq 64(%rsp), %r9
    movq $0, 32(%rsp)
    call ReadFile
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_read_err
    movq 64(%rsp), %rax
    testq %r12, %r12
    jnz .Lws_ret
    testq %rax, %rax
    jz .Lws_ret
    movq 72(%rsp), %rcx
    call GetFileType
    shlq $32, %rax
    shrq $32, %rax
    cmpq $2, %rax
    movq 64(%rsp), %rax
    jne .Lws_ret
# console input in cooked mode ends lines with "\r\n": drop the '\r' (a Linux terminal delivers "\n")
    movq %r13, %rsi
    movq %r13, %rdi
    movq %rax, %rcx
.Lws_read_cr:
    movzbq (%rsi), %rax
    incq %rsi
    cmpq $13, %rax
    je .Lws_read_cr_skip
    movb %al, (%rdi)
    incq %rdi
.Lws_read_cr_skip:
    decq %rcx
    jnz .Lws_read_cr
    movq %rdi, %rax
    subq %r13, %rax
    jmp .Lws_ret
.Lws_read_err:
    call GetLastError
    shlq $32, %rax
    shrq $32, %rax
    cmpq $109, %rax
    je .Lws_zero
    cmpq $38, %rax
    je .Lws_zero
    jmp .Lws_errmap
# /dev/urandom: BCryptGenRandom(NULL, buf, n, BCRYPT_USE_SYSTEM_PREFERRED_RNG), bcrypt.dll loaded from System32 on
# first use (no start-up cost for programs that never read entropy); called through push/ret (no indirect call)
.Lws_read_random:
    movq .Lws_bcrypt_fn(%rip), %rax
    testq %rax, %rax
    jnz .Lws_rr_have
    leaq .Lws_bcrypt_dll(%rip), %rcx
    xorq %rdx, %rdx
    movq $2048, %r8
    call LoadLibraryExA
    testq %rax, %rax
    jz .Lws_eio
    movq %rax, %rcx
    leaq .Lws_bcrypt_proc(%rip), %rdx
    call GetProcAddress
    testq %rax, %rax
    jz .Lws_eio
    movq %rax, .Lws_bcrypt_fn(%rip)
.Lws_rr_have:
    movq %rax, %r10
    xorq %rcx, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    movq $2, %r9
    leaq .Lws_rr_back(%rip), %r11
    pushq %r11
    pushq %r10
    ret
.Lws_rr_back:
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_eio
    movq %r14, %rax
    jmp .Lws_ret
.Lws_eio:
    movq $-5, %rax
    jmp .Lws_ret
.Lws_eisdir:
    movq $-21, %rax
    jmp .Lws_ret
# fd r12 -> rax = HANDLE / record, rcx = kind (0 = not open). Subroutine, entered by call (rsp = 8 mod 16).
.Lws_fdh:
    subq $40, %rsp
    xorq %rcx, %rcx
    xorq %rax, %rax
    testq %r12, %r12
    js .Lws_fdh_out
    cmpq $1024, %r12
    jge .Lws_fdh_out
    leaq .Lws_fdt(%rip), %rax
    movq %r12, %rcx
    shlq $4, %rcx
    addq %rcx, %rax
    movq (%rax), %rcx
    movq 8(%rax), %rax
    cmpq $4, %rcx
    jne .Lws_fdh_out
    movq $-10, %rcx
    subq %r12, %rcx
    call GetStdHandle
    movq $4, %rcx
.Lws_fdh_out:
    addq $40, %rsp
    ret
# lowest free fd >= 3 for (kind r8, value r9): rax = fd, or -EMFILE. No API call.
.Lws_fd_new:
    leaq .Lws_fdt+48(%rip), %rax
    movq $3, %rcx
.Lws_fdn_l:
    cmpq $1024, %rcx
    jge .Lws_fdn_full
    cmpq $0, (%rax)
    je .Lws_fdn_put
    addq $16, %rax
    incq %rcx
    jmp .Lws_fdn_l
.Lws_fdn_put:
    movq %r8, (%rax)
    movq %r9, 8(%rax)
    movq %rcx, %rax
    ret
.Lws_fdn_full:
    movq $-24, %rax
    ret
# free fd r12. No API call.
.Lws_fd_free:
    leaq .Lws_fdt(%rip), %rax
    movq %r12, %rcx
    shlq $4, %rcx
    movq $0, (%rax,%rcx,1)
    movq $0, 8(%rax,%rcx,1)
    ret
.Lws_write:
    call .Lws_fdh
    cmpq $5, %rcx
    je .Lws_write_sock
    cmpq $1, %rcx
    je .Lws_write_c
    cmpq $4, %rcx
    jne .Lws_ebadf
.Lws_write_c:
    movq %rax, 72(%rsp)
    movq %r13, %rcx
    movq %r14, %rdx
    call .Lws_nr_commit
    movq 72(%rsp), %rax
.Lws_write_h:
    movq %rax, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    movq $2147483647, %rax
    cmpq %rax, %r8
    jle .Lws_write_n
    movq %rax, %r8
.Lws_write_n:
    movq $0, 64(%rsp)
    leaq 64(%rsp), %r9
    movq $0, 32(%rsp)
    call WriteFile
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    movq 64(%rsp), %rax
    jmp .Lws_ret
# path in r12 (UTF-8, NUL-terminated) -> .Lws_wbuf (UTF-16), with the POSIX view of Windows paths:
# "/dev/null" -> "NUL", "/x" and "/x/..." (one drive letter) -> "X:/...", "/tmp" and "/tmp/..." -> the Windows
# temporary directory; any other path is passed as it is (Windows accepts '/' as a separator).
# Subroutine (entered by call, rsp = 8 mod 16); returns the UTF-16 length with its NUL, or 0 on failure.
.Lws_wpath:
    subq $72, %rsp
    leaq .Lws_devnull(%rip), %rsi
    movq %r12, %rdi
.Lws_wpath_cmp:
    movzbq (%rsi), %rax
    movzbq (%rdi), %rcx
    cmpq %rax, %rcx
    jne .Lws_wpath_conv
    testq %rax, %rax
    jz .Lws_wpath_nul
    incq %rsi
    incq %rdi
    jmp .Lws_wpath_cmp
.Lws_wpath_nul:
    leaq .Lws_wbuf(%rip), %rax
    movb $78, (%rax)
    movb $0, 1(%rax)
    movb $85, 2(%rax)
    movb $0, 3(%rax)
    movb $76, 4(%rax)
    movb $0, 5(%rax)
    movb $0, 6(%rax)
    movb $0, 7(%rax)
    movq $4, %rax
    addq $72, %rsp
    ret
.Lws_wpath_conv:
    movq %r12, %r8
    movzbq (%r12), %rax
    cmpq $47, %rax
    jne .Lws_wpath_go
    leaq .Lws_tmpdir(%rip), %rsi
    movq %r12, %rdi
.Lws_wpath_tcmp:
    movzbq (%rsi), %rax
    testq %rax, %rax
    jz .Lws_wpath_tend
    movzbq (%rdi), %rcx
    cmpq %rax, %rcx
    jne .Lws_wpath_drive
    incq %rsi
    incq %rdi
    jmp .Lws_wpath_tcmp
.Lws_wpath_tend:
    movzbq (%rdi), %rax
    testq %rax, %rax
    jz .Lws_wpath_tmp
    cmpq $47, %rax
    jne .Lws_wpath_drive
    incq %rdi
.Lws_wpath_tmp:
    movq %rdi, 64(%rsp)
    movq $32768, %rcx
    leaq .Lws_wbuf(%rip), %rdx
    call GetTempPathW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_wpath_out
    movq $65001, %rcx
    xorq %rdx, %rdx
    leaq .Lws_wbuf(%rip), %r8
    movq $-1, %r9
    leaq .Lws_pbuf(%rip), %rax
    movq %rax, 32(%rsp)
    movq $98304, 40(%rsp)
    movq $0, 48(%rsp)
    movq $0, 56(%rsp)
    call WideCharToMultiByte
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_wpath_out
    leaq .Lws_pbuf(%rip), %rdi
    leaq -1(%rdi,%rax,1), %rdi
    movq 64(%rsp), %rsi
    jmp .Lws_wpath_copy
.Lws_wpath_drive:
    movzbq 1(%r12), %rax
    movq %rax, %rcx
    subq $97, %rcx
    js .Lws_wpath_up
    cmpq $26, %rcx
    jl .Lws_wpath_dl
    jmp .Lws_wpath_go
.Lws_wpath_up:
    movq %rax, %rcx
    subq $65, %rcx
    js .Lws_wpath_go
    cmpq $26, %rcx
    jge .Lws_wpath_go
.Lws_wpath_dl:
    movzbq 2(%r12), %rcx
    testq %rcx, %rcx
    jz .Lws_wpath_d2
    cmpq $47, %rcx
    jne .Lws_wpath_go
.Lws_wpath_d2:
    leaq .Lws_pbuf(%rip), %rdi
    movb %al, (%rdi)
    movb $58, 1(%rdi)
    movb $47, 2(%rdi)
    movb $0, 3(%rdi)
    addq $2, %rdi
    leaq 2(%r12), %rsi
    testq %rcx, %rcx
    jz .Lws_wpath_pb
.Lws_wpath_copy:
    movzbq (%rsi), %rax
    movb %al, (%rdi)
    incq %rsi
    incq %rdi
    testq %rax, %rax
    jnz .Lws_wpath_copy
.Lws_wpath_pb:
    leaq .Lws_pbuf(%rip), %r8
.Lws_wpath_go:
    movq $65001, %rcx
    movq $8, %rdx
    movq $-1, %r9
    leaq .Lws_wbuf(%rip), %rax
    movq %rax, 32(%rsp)
    movq $32768, 40(%rsp)
    call MultiByteToWideChar
    shlq $32, %rax
    shrq $32, %rax
.Lws_wpath_out:
    addq $72, %rsp
    ret
# rdi = C string: rax = 1 when it ends in "/" or "/." (no API call; clobbers rax, rcx, rdi)
.Lws_trail_dir:
    movq %rdi, %rcx
.Lws_td_end:
    cmpb $0, (%rcx)
    je .Lws_td_at
    incq %rcx
    jmp .Lws_td_end
.Lws_td_at:
    xorq %rax, %rax
    cmpq %rdi, %rcx
    je .Lws_td_out
    cmpb $47, -1(%rcx)
    je .Lws_td_yes
    cmpb $46, -1(%rcx)
    jne .Lws_td_out
    leaq 1(%rdi), %rdi
    cmpq %rdi, %rcx
    jle .Lws_td_out
    cmpb $47, -2(%rcx)
    jne .Lws_td_out
.Lws_td_yes:
    movq $1, %rax
.Lws_td_out:
    ret
.Lws_open:
    leaq .Lws_devstdout(%rip), %rsi
    movq %r12, %rdi
    call .Lws_streq
    testq %rax, %rax
    jz .Lws_open_s2
    movq $1, %rax
    jmp .Lws_ret
.Lws_open_s2:
    leaq .Lws_devstderr(%rip), %rsi
    movq %r12, %rdi
    call .Lws_streq
    testq %rax, %rax
    jz .Lws_open_s0
    movq $2, %rax
    jmp .Lws_ret
.Lws_open_s0:
    leaq .Lws_devstdin(%rip), %rsi
    movq %r12, %rdi
    call .Lws_streq
    testq %rax, %rax
    jz .Lws_open_ur
    xorq %rax, %rax
    jmp .Lws_ret
.Lws_open_ur:
    leaq .Lws_urandom(%rip), %rsi
    movq %r12, %rdi
.Lws_open_cmp:
    movzbq (%rsi), %rax
    movzbq (%rdi), %rcx
    cmpq %rax, %rcx
    jne .Lws_open_file
    testq %rax, %rax
    jz .Lws_open_random
    incq %rsi
    incq %rdi
    jmp .Lws_open_cmp
.Lws_open_random:
    movq $3, %r8
    xorq %r9, %r9
    call .Lws_fd_new
    jmp .Lws_ret
.Lws_open_file:
    movq %r13, %rax
    andq $65536, %rax
    testq %rax, %rax
    jnz .Lws_opendir
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
# a path ending in "/" or "/." names a directory (Win32 drops the trailing "." and "/"; Linux says ENOTDIR)
    movq %r12, %rdi
    call .Lws_trail_dir
    testq %rax, %rax
    jz .Lws_open_go
    leaq .Lws_wbuf(%rip), %rcx
    call GetFileAttributesW
    shlq $32, %rax
    shrq $32, %rax
    movq $4294967295, %rcx
    cmpq %rcx, %rax
    je .Lws_fail
    andq $16, %rax
    testq %rax, %rax
    jz .Lws_enotdir
.Lws_open_go:
    movq %r13, %rax
    andq $3, %rax
    movq $2147483648, %rdx
    cmpq $1, %rax
    jne .Lws_open_a1
    movq $1073741824, %rdx
.Lws_open_a1:
    cmpq $2, %rax
    jne .Lws_open_a2
    movq $3221225472, %rdx
.Lws_open_a2:
    movq %r13, %rcx
    andq $1024, %rcx
    testq %rcx, %rcx
    jz .Lws_open_a3
    movq $1048580, %rdx
    cmpq $2, %rax
    jne .Lws_open_a3
    movq $2148532228, %rdx
.Lws_open_a3:
    movq $3, %r8
    movq %r13, %rcx
    andq $512, %rcx
    testq %rcx, %rcx
    jz .Lws_open_d1
    movq $5, %r8
.Lws_open_d1:
    movq %r13, %rcx
    andq $64, %rcx
    testq %rcx, %rcx
    jz .Lws_open_d4
    movq $4, %r8
    movq %r13, %rcx
    andq $512, %rcx
    testq %rcx, %rcx
    jz .Lws_open_d2
    movq $2, %r8
.Lws_open_d2:
    movq %r13, %rcx
    andq $128, %rcx
    testq %rcx, %rcx
    jz .Lws_open_d4
    movq $1, %r8
.Lws_open_d4:
    movq %r8, 32(%rsp)
    movq $33554560, 40(%rsp)
    movq $0, 48(%rsp)
    leaq .Lws_wbuf(%rip), %rcx
    movq $7, %r8
    xorq %r9, %r9
    call CreateFileW
    cmpq $-1, %rax
    je .Lws_fail
    movq %rax, 64(%rsp)
    movq $1, %r8
    movq %rax, %r9
    call .Lws_fd_new
    testq %rax, %rax
    jns .Lws_open_fd
    movq %rax, 72(%rsp)
    movq 64(%rsp), %rcx
    call CloseHandle
    movq 72(%rsp), %rax
    jmp .Lws_ret
.Lws_open_fd:
    movq %rax, 72(%rsp)
    cmpq $0, .Lws_fk_mode(%rip)
    je .Lws_ret
# vfork child: the handle is inheritable; its fd is closed in the parent once the child process exists
    movq 64(%rsp), %rcx
    movq $1, %rdx
    movq $1, %r8
    call SetHandleInformation
    movq .Lws_fk_nopen(%rip), %rcx
    cmpq $8, %rcx
    jge .Lws_open_rec
    leaq .Lws_fk_open(%rip), %rdx
    movq 72(%rsp), %rax
    movq %rax, (%rdx,%rcx,8)
    incq %rcx
    movq %rcx, .Lws_fk_nopen(%rip)
.Lws_open_rec:
    movq 72(%rsp), %rax
    jmp .Lws_ret
.Lws_opendir:
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
    leaq .Lws_wbuf(%rip), %rcx
    leaq -2(%rcx,%rax,2), %rdx
    movb $92, (%rdx)
    movb $0, 1(%rdx)
    movb $42, 2(%rdx)
    movb $0, 3(%rdx)
    movb $0, 4(%rdx)
    movb $0, 5(%rdx)
    xorq %rcx, %rcx
    movq $4096, %rdx
    movq $12288, %r8
    movq $4, %r9
    call VirtualAlloc
    testq %rax, %rax
    jz .Lws_enomem
    movq %rax, 64(%rsp)
    leaq .Lws_wbuf(%rip), %rcx
    leaq 32(%rax), %rdx
    call FindFirstFileW
    cmpq $-1, %rax
    je .Lws_opendir_fail
    movq 64(%rsp), %rcx
    movq %rax, 8(%rcx)
    movq $0, 16(%rcx)
    movq $2, %r8
    movq %rcx, %r9
    call .Lws_fd_new
    testq %rax, %rax
    jns .Lws_ret
    movq %rax, 72(%rsp)
    movq 64(%rsp), %rcx
    movq 8(%rcx), %rcx
    call FindClose
    movq 64(%rsp), %rcx
    xorq %rdx, %rdx
    movq $32768, %r8
    call VirtualFree
    movq 72(%rsp), %rax
    jmp .Lws_ret
.Lws_opendir_fail:
    call GetLastError
    shlq $32, %rax
    shrq $32, %rax
    movq %rax, 72(%rsp)
    movq 64(%rsp), %rcx
    xorq %rdx, %rdx
    movq $32768, %r8
    call VirtualFree
    movq 72(%rsp), %rax
    jmp .Lws_errmap
.Lws_close:
    cmpq $0, .Lws_fk_mode(%rip)
    jne .Lws_zero
    cmpq $2, %r12
    jle .Lws_zero
    call .Lws_fdh
    testq %rcx, %rcx
    jz .Lws_ebadf
    movq %rax, 64(%rsp)
    movq %rcx, 72(%rsp)
    call .Lws_fd_free
    movq 72(%rsp), %rcx
    cmpq $2, %rcx
    je .Lws_close_dir
    cmpq $5, %rcx
    je .Lws_close_sock
    cmpq $1, %rcx
    jne .Lws_zero
    movq 64(%rsp), %rcx
    call CloseHandle
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
.Lws_close_dir:
    movq 64(%rsp), %rax
    movq 8(%rax), %rcx
    call FindClose
    movq 64(%rsp), %rcx
    xorq %rdx, %rdx
    movq $32768, %r8
    call VirtualFree
    jmp .Lws_zero
.Lws_lseek:
    call .Lws_fdh
    testq %rcx, %rcx
    jz .Lws_ebadf
# /dev/urandom has no position: lseek succeeds at 0, as on Linux
    cmpq $3, %rcx
    je .Lws_zero
    cmpq $2, %rcx
    je .Lws_einval
.Lws_lseek_h:
    movq %rax, %rcx
    movq %r13, %rdx
    leaq 64(%rsp), %r8
    movq %r14, %r9
    call SetFilePointerEx
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    movq 64(%rsp), %rax
    jmp .Lws_ret
.Lws_mmap:
    movq %r15, %rax
    andq $32, %rax
    testq %rax, %rax
    jz .Lws_enodev
# MAP_SHARED | MAP_ANONYMOUS (os_shm_map): a section, still shared with a fork child
    movq %r15, %rax
    andq $1, %rax
    testq %rax, %rax
    jnz .Lws_mmap_shm
# MAP_NORESERVE + read/write (not exec): reserve now, commit on first touch
    movq %r15, %rax
    andq $16384, %rax
    testq %rax, %rax
    jz .Lws_mmap_std
    cmpq $3, %r14
    jne .Lws_mmap_std
    call .Lws_nr_slot
    testq %rax, %rax
    jz .Lws_mmap_std
    movq %rax, 80(%rsp)
    xorq %rcx, %rcx
    movq %r13, %rdx
    movq $1056768, %r8
    movq $1, %r9
    call VirtualAlloc
    testq %rax, %rax
    jz .Lws_enomem
    movq 80(%rsp), %rcx
    movq %rax, (%rcx)
    movq %rax, %rdx
    addq %r13, %rdx
    movq %rdx, 8(%rcx)
    movq %rax, %rcx
    movq %r13, %rdx
    call .Lws_reg_add
    jmp .Lws_ret
# the layer maps top-down (MEM_TOP_DOWN): far from where any process puts its early heaps and stacks, so a fork
# child can take every region at the same address
.Lws_mmap_std:
    xorq %rcx, %rcx
    movq %r13, %rdx
    movq $1056768, %r8
    movq $1, %r9
    testq %r14, %r14
    jz .Lws_mmap_go
    movq $1060864, %r8
    call .Lws_prot
    movq %rax, %r9
    xorq %rcx, %rcx
    movq %r13, %rdx
.Lws_mmap_go:
    call VirtualAlloc
    testq %rax, %rax
    jz .Lws_enomem
    movq %rax, %rcx
    movq %r13, %rdx
    call .Lws_reg_add
    jmp .Lws_ret
# shared anonymous mapping: a pagefile-backed section mapped at an address taken top-down (free in a fork child too,
# like every region of the layer), recorded in .Lws_shm (base, size, section) and not in the private registry: a
# fork maps the same section into the child instead of copying it
.Lws_mmap_shm:
    testq %r13, %r13
    jz .Lws_einval
    leaq .Lws_shm(%rip), %rax
    movq $64, %rcx
.Lws_ms_slot:
    cmpq $0, (%rax)
    je .Lws_ms_have
    addq $24, %rax
    decq %rcx
    jnz .Lws_ms_slot
    jmp .Lws_enomem
.Lws_ms_have:
    movq %rax, 80(%rsp)
    xorq %rcx, %rcx
    movq %r13, %rdx
    movq $1056768, %r8
    movq $1, %r9
    call VirtualAlloc
    testq %rax, %rax
    jz .Lws_enomem
    movq %rax, 96(%rsp)
    movq %rax, %rcx
    xorq %rdx, %rdx
    movq $32768, %r8
    call VirtualFree
    movq $-1, %rcx
    xorq %rdx, %rdx
    movq $4, %r8
    movq %r13, %r9
    shrq $32, %r9
    movq %r13, %rax
    shlq $32, %rax
    shrq $32, %rax
    movq %rax, 32(%rsp)
    movq $0, 40(%rsp)
    call CreateFileMappingW
    testq %rax, %rax
    jz .Lws_enomem
    movq %rax, 88(%rsp)
    movq %rax, %rcx
    movq $6, %rdx
    xorq %r8, %r8
    xorq %r9, %r9
    movq %r13, 32(%rsp)
    movq 96(%rsp), %rax
    movq %rax, 40(%rsp)
    call MapViewOfFileEx
    testq %rax, %rax
    jz .Lws_ms_fail
    movq 80(%rsp), %rcx
    movq %rax, (%rcx)
    movq %r13, 8(%rcx)
    movq 88(%rsp), %rdx
    movq %rdx, 16(%rcx)
    jmp .Lws_ret
.Lws_ms_fail:
    movq 88(%rsp), %rcx
    call CloseHandle
    jmp .Lws_enomem
# rax = MapViewOfFileNuma2 (kernelbase.dll, loaded on first use), or 0. Keeps rbx, rsi, rdi, r12-r15.
.Lws_mvn2:
    movq .Lws_mvn2_fn(%rip), %rax
    testq %rax, %rax
    jnz .Lws_mvn2_out
    subq $40, %rsp
    leaq .Lws_kbase_dll(%rip), %rcx
    xorq %rdx, %rdx
    movq $2048, %r8
    call LoadLibraryExA
    testq %rax, %rax
    jz .Lws_mvn2_none
    movq %rax, %rcx
    leaq .Lws_mvn2_proc(%rip), %rdx
    call GetProcAddress
    movq %rax, .Lws_mvn2_fn(%rip)
.Lws_mvn2_none:
    addq $40, %rsp
.Lws_mvn2_out:
    ret
.Lws_mprotect:
    testq %r14, %r14
    jz .Lws_mprotect_none
    call .Lws_prot
    movq %rax, 80(%rsp)
    movq %r12, %rcx
    movq %r13, %rdx
    movq $4096, %r8
    movq %rax, %r9
    call VirtualAlloc
    testq %rax, %rax
    jz .Lws_enomem
    movq %r12, %rcx
    movq %r13, %rdx
    movq 80(%rsp), %r8
    leaq 64(%rsp), %r9
    call VirtualProtect
    jmp .Lws_zero
.Lws_mprotect_none:
    movq %r12, %rcx
    movq %r13, %rdx
    movq $16384, %r8
    call VirtualFree
    jmp .Lws_zero
.Lws_munmap:
    testq %r12, %r12
    jz .Lws_mu_priv
    leaq .Lws_shm(%rip), %rax
    movq $64, %rcx
.Lws_mu_shm:
    cmpq %r12, (%rax)
    je .Lws_mu_shm_hit
    addq $24, %rax
    decq %rcx
    jnz .Lws_mu_shm
    jmp .Lws_mu_priv
.Lws_mu_shm_hit:
    movq %rax, 80(%rsp)
    movq %r12, %rcx
    call UnmapViewOfFile
    movq 80(%rsp), %rax
    movq 16(%rax), %rcx
    movq $0, (%rax)
    movq $0, 8(%rax)
    movq $0, 16(%rax)
    call CloseHandle
    jmp .Lws_zero
.Lws_mu_priv:
    movq %r12, %rcx
    call .Lws_reg_del
    leaq .Lws_nrt(%rip), %rax
    movq $64, %rcx
.Lws_mu_nr:
    cmpq %r12, (%rax)
    jne .Lws_mu_nx
    movq $0, (%rax)
    movq $0, 8(%rax)
.Lws_mu_nx:
    addq $16, %rax
    decq %rcx
    jnz .Lws_mu_nr
    movq %r12, %rcx
    xorq %rdx, %rdx
    movq $32768, %r8
    call VirtualFree
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_zero
    movq %r12, %rcx
    movq %r13, %rdx
    movq $16384, %r8
    call VirtualFree
    jmp .Lws_zero
.Lws_madvise:
    cmpq $4, %r14
    jne .Lws_zero
    movq %r12, %rcx
    movq %r13, %rdx
    movq $16384, %r8
    call VirtualFree
    movq %r12, %rcx
    movq %r13, %rdx
    movq $4096, %r8
    movq $4, %r9
    call VirtualAlloc
    testq %rax, %rax
    jz .Lrt_alloc_oom
    jmp .Lws_zero
# r14 = PROT_* (non-zero) -> rax = PAGE_* ; no API call
.Lws_prot:
    movq %r14, %rax
    andq $2, %rax
    testq %rax, %rax
    jz .Lws_prot_ro
    movq %r14, %rax
    andq $4, %rax
    testq %rax, %rax
    movq $4, %rax
    jz .Lws_prot_out
    movq $64, %rax
    ret
.Lws_prot_ro:
    movq %r14, %rax
    andq $4, %rax
    testq %rax, %rax
    movq $2, %rax
    jz .Lws_prot_out
    movq $32, %rax
.Lws_prot_out:
    ret
# free slot of the lazy-commit table -> rax (0 when full); no API call
.Lws_nr_slot:
    leaq .Lws_nrt(%rip), %rax
    movq $64, %rcx
.Lws_nrs_l:
    cmpq $0, (%rax)
    je .Lws_nrs_out
    addq $16, %rax
    decq %rcx
    jnz .Lws_nrs_l
    xorq %rax, %rax
.Lws_nrs_out:
    ret
# commit the part of [rcx, rcx + rdx) that lies in lazily committed reservations (before the kernel reads or
# writes a user buffer: it reports ERROR_NOACCESS instead of faulting). Entered by call; keeps r12-r15.
.Lws_nr_commit:
    pushq %rbx
    pushq %rsi
    pushq %rdi
    subq $48, %rsp
    movq %rcx, %rsi
    movq %rcx, %rdi
    addq %rdx, %rdi
    leaq .Lws_nrt(%rip), %rbx
    movq $64, 40(%rsp)
.Lws_nrc_l:
    movq (%rbx), %rcx
    testq %rcx, %rcx
    jz .Lws_nrc_n
    cmpq %rsi, %rcx
    jge .Lws_nrc_lo
    movq %rsi, %rcx
.Lws_nrc_lo:
    movq 8(%rbx), %rdx
    cmpq %rdi, %rdx
    jle .Lws_nrc_hi
    movq %rdi, %rdx
.Lws_nrc_hi:
    andq $-4096, %rcx
    cmpq %rdx, %rcx
    jge .Lws_nrc_n
    subq %rcx, %rdx
    movq $4096, %r8
    movq $4, %r9
    call VirtualAlloc
.Lws_nrc_n:
    addq $16, %rbx
    movq 40(%rsp), %rax
    decq %rax
    movq %rax, 40(%rsp)
    jnz .Lws_nrc_l
    addq $48, %rsp
    popq %rdi
    popq %rsi
    popq %rbx
    ret
.Lws_exit:
    cmpq $0, .Lws_fk_mode(%rip)
    jne .Lws_exit_child
# the exit status is 8 bits, as on Linux (exit(256) is 0)
    movq %r12, %rcx
    andq $255, %rcx
    call ExitProcess
# a vfork child that exits without execve: a finished child with a synthetic pid and status (code & 255) << 8
.Lws_exit_child:
    movq .Lws_kid_fake(%rip), %rax
    testq %rax, %rax
    jnz .Lws_exit_child_id
    movq $1073741824, %rax
.Lws_exit_child_id:
    incq %rax
    movq %rax, .Lws_kid_fake(%rip)
    movq %rax, 80(%rsp)
    movq %r12, %rcx
    andq $255, %rcx
    imulq $256, %rcx
    movq %rcx, 88(%rsp)
    call .Lws_kid_slot
    testq %rax, %rax
    jz .Lws_exit_child_full
    movq 80(%rsp), %rcx
    movq %rcx, (%rax)
    movq $0, 8(%rax)
    movq $1, 16(%rax)
    movq 88(%rsp), %rcx
    movq %rcx, 24(%rax)
    movq $0, 32(%rax)
.Lws_exit_child_full:
    call .Lws_fk_close_opened
    movq 80(%rsp), %rax
    jmp .Lws_fk_resume
.Lws_getpid:
    call GetCurrentProcessId
    shlq $32, %rax
    shrq $32, %rax
    jmp .Lws_ret
# nanosleep on a high-resolution waitable timer (Sleep would round up to the 15.6 ms scheduler tick)
.Lws_nanosleep:
    movq 8(%r12), %rax
    cqto
    movq $100, %rcx
    idivq %rcx
    movq %rax, 64(%rsp)
    movq (%r12), %rax
    imulq $10000000, %rax
    movq 64(%rsp), %rdx
    addq %rdx, %rax
    testq %rax, %rax
    jle .Lws_zero
    negq %rax
    movq %rax, 80(%rsp)
    movq .Lws_timer(%rip), %rax
    testq %rax, %rax
    jnz .Lws_nanosleep_set
    xorq %rcx, %rcx
    xorq %rdx, %rdx
    movq $2, %r8
    movq $2031619, %r9
    call CreateWaitableTimerExW
    movq %rax, .Lws_timer(%rip)
    testq %rax, %rax
    jz .Lws_nanosleep_coarse
.Lws_nanosleep_set:
    movq %rax, %rcx
    leaq 80(%rsp), %rdx
    xorq %r8, %r8
    xorq %r9, %r9
    movq $0, 32(%rsp)
    movq $0, 40(%rsp)
    call SetWaitableTimer
    movq .Lws_timer(%rip), %rcx
    movq $4294967295, %rdx
    call WaitForSingleObject
    jmp .Lws_zero
.Lws_nanosleep_coarse:
    movq 80(%rsp), %rax
    negq %rax
    cqto
    movq $10000, %rcx
    idivq %rcx
    movq %rax, %rcx
    call Sleep
    jmp .Lws_zero
.Lws_fsync:
    cmpq $2, %r12
    jle .Lws_zero
    call .Lws_fdh
    cmpq $1, %rcx
    jne .Lws_einval
    movq %rax, %rcx
    call FlushFileBuffers
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
.Lws_flock:
    cmpq $2, %r12
    jle .Lws_zero
    call .Lws_fdh
    cmpq $1, %rcx
    jne .Lws_zero
    movq %rax, 88(%rsp)
    movq $0, 96(%rsp)
    movq $0, 104(%rsp)
    movq $0, 112(%rsp)
    movq $0, 120(%rsp)
    movq %r13, %rax
    andq $8, %rax
    testq %rax, %rax
    jz .Lws_flock_lock
    movq 88(%rsp), %rcx
    xorq %rdx, %rdx
    movq $4294967295, %r8
    movq $4294967295, %r9
    leaq 96(%rsp), %rax
    movq %rax, 32(%rsp)
    call UnlockFileEx
    jmp .Lws_zero
.Lws_flock_lock:
    xorq %rdx, %rdx
    movq %r13, %rax
    andq $2, %rax
    testq %rax, %rax
    jz .Lws_flock_nb
    movq $2, %rdx
.Lws_flock_nb:
    movq %r13, %rax
    andq $4, %rax
    testq %rax, %rax
    jz .Lws_flock_go
    addq $1, %rdx
.Lws_flock_go:
    movq 88(%rsp), %rcx
    xorq %r8, %r8
    movq $4294967295, %r9
    movq $4294967295, %rax
    movq %rax, 32(%rsp)
    leaq 96(%rsp), %rax
    movq %rax, 40(%rsp)
    call LockFileEx
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_zero
    call GetLastError
    shlq $32, %rax
    shrq $32, %rax
    cmpq $33, %rax
    jne .Lws_errmap
    movq $-11, %rax
    jmp .Lws_ret
.Lws_getcwd:
    movq $32768, %rcx
    leaq .Lws_wbuf(%rip), %rdx
    call GetCurrentDirectoryW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    movq $65001, %rcx
    xorq %rdx, %rdx
    leaq .Lws_wbuf(%rip), %r8
    movq $-1, %r9
    movq %r12, 32(%rsp)
    movq %r13, 40(%rsp)
    movq $0, 48(%rsp)
    movq $0, 56(%rsp)
    call WideCharToMultiByte
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_erange
    movq %rax, 64(%rsp)
    movq %r12, %rcx
.Lws_getcwd_sl:
    movzbq (%rcx), %rdx
    testq %rdx, %rdx
    jz .Lws_getcwd_done
    cmpq $92, %rdx
    jne .Lws_getcwd_nx
    movb $47, (%rcx)
.Lws_getcwd_nx:
    incq %rcx
    jmp .Lws_getcwd_sl
.Lws_getcwd_done:
    movzbq 1(%r12), %rax
    cmpq $58, %rax
    jne .Lws_getcwd_ret
    movzbq (%r12), %rax
    movq %rax, %rcx
    subq $65, %rcx
    js .Lws_getcwd_low
    cmpq $26, %rcx
    jge .Lws_getcwd_low
    addq $32, %rax
.Lws_getcwd_low:
    movb %al, 1(%r12)
    movb $47, (%r12)
.Lws_getcwd_ret:
    movq 64(%rsp), %rax
    jmp .Lws_ret
.Lws_mkdir:
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
    leaq .Lws_wbuf(%rip), %rcx
    xorq %rdx, %rdx
    call CreateDirectoryW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
# rename(old, new): MoveFileExW with REPLACE_EXISTING | COPY_ALLOWED | WRITE_THROUGH (replaces like POSIX rename)
.Lws_rename:
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
    movq %rax, %rcx
    addq %rax, %rcx
    leaq .Lws_wbuf(%rip), %rsi
    leaq .Lws_cwbuf(%rip), %rdi
.Lws_rename_cp:
    movzbq (%rsi), %rax
    movb %al, (%rdi)
    incq %rsi
    incq %rdi
    decq %rcx
    jnz .Lws_rename_cp
    movq %r12, 64(%rsp)
    movq %r13, %r12
    call .Lws_wpath
    movq 64(%rsp), %r12
    testq %rax, %rax
    jz .Lws_fail
    leaq .Lws_cwbuf(%rip), %rcx
    leaq .Lws_wbuf(%rip), %rdx
# REPLACE_EXISTING | WRITE_THROUGH, no COPY_ALLOWED: across volumes it fails (EXDEV) as on Linux
    movq $9, %r8
    call MoveFileExW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
# chmod: Windows has no execute bit (the extension decides); succeed when the file exists
.Lws_chmod:
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
    leaq .Lws_wbuf(%rip), %rcx
    call GetFileAttributesW
    shlq $32, %rax
    shrq $32, %rax
    movq $4294967295, %rcx
    cmpq %rcx, %rax
    je .Lws_fail
# the owner write bit (0200) is the read-only attribute, as the C runtime's _chmod does; group and other bits
# have no meaning here (a profile directory is already owner-only by its ACL)
    movq %rax, %rdx
    andq $-2, %rdx
    movq %r13, %rcx
    andq $128, %rcx
    testq %rcx, %rcx
    jnz .Lws_chmod_set
    orq $1, %rdx
.Lws_chmod_set:
    cmpq %rax, %rdx
    je .Lws_zero
    leaq .Lws_wbuf(%rip), %rcx
    call SetFileAttributesW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
# rsi = literal, rdi = string: rax = 1 when equal (clobbers rcx, rsi, rdi; no API call)
.Lws_streq:
    movzbq (%rsi), %rax
    movzbq (%rdi), %rcx
    cmpq %rax, %rcx
    jne .Lws_streq_no
    testq %rax, %rax
    jz .Lws_streq_yes
    incq %rsi
    incq %rdi
    jmp .Lws_streq
.Lws_streq_yes:
    movq $1, %rax
    ret
.Lws_streq_no:
    xorq %rax, %rax
    ret
.Lws_chdir:
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
    leaq .Lws_wbuf(%rip), %rcx
    call SetCurrentDirectoryW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
.Lws_unlink:
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
    leaq .Lws_wbuf(%rip), %rcx
    call DeleteFileW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_zero
# a read-only file (chmod without the owner write bit) is removable on Linux: drop the attribute and retry
    call GetLastError
    shlq $32, %rax
    shrq $32, %rax
    cmpq $5, %rax
    jne .Lws_errmap
    leaq .Lws_wbuf(%rip), %rcx
    call GetFileAttributesW
    shlq $32, %rax
    shrq $32, %rax
    movq %rax, %rdx
    andq $17, %rax
    cmpq $1, %rax
    movq $5, %rax
    jne .Lws_errmap
    andq $-2, %rdx
    leaq .Lws_wbuf(%rip), %rcx
    call SetFileAttributesW
    leaq .Lws_wbuf(%rip), %rcx
    call DeleteFileW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
# rmdir(path): RemoveDirectoryW (empty directories only, as on Linux)
.Lws_rmdir:
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
    leaq .Lws_wbuf(%rip), %rcx
    call RemoveDirectoryW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
.Lws_getrlimit:
    movq $-1, %rax
    cmpq $3, %r12
    jne .Lws_getrlimit_w
    movq $4294967296, %rax
.Lws_getrlimit_w:
    movq %rax, (%r13)
    movq %rax, 8(%r13)
    jmp .Lws_zero
.Lws_getrusage:
    xorq %rcx, %rcx
.Lws_getrusage_z:
    movq $0, (%r13,%rcx,8)
    incq %rcx
    cmpq $18, %rcx
    jl .Lws_getrusage_z
    call GetCurrentProcess
    movq %rax, 64(%rsp)
    movq %rax, %rcx
    leaq 128(%rsp), %rdx
    leaq 136(%rsp), %r8
    leaq 144(%rsp), %r9
    leaq 152(%rsp), %rax
    movq %rax, 32(%rsp)
    call GetProcessTimes
    movq 152(%rsp), %rax
    cqto
    movq $10000000, %rcx
    idivq %rcx
    movq %rax, (%r13)
    movq %rdx, %rax
    cqto
    movq $10, %rcx
    idivq %rcx
    movq %rax, 8(%r13)
    movq 144(%rsp), %rax
    cqto
    movq $10000000, %rcx
    idivq %rcx
    movq %rax, 16(%r13)
    movq %rdx, %rax
    cqto
    movq $10, %rcx
    idivq %rcx
    movq %rax, 24(%r13)
    movq $72, 96(%rsp)
    movq 64(%rsp), %rcx
    leaq 96(%rsp), %rdx
    movq $72, %r8
    call K32GetProcessMemoryInfo
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_zero
    movq 104(%rsp), %rax
    cqto
    movq $1024, %rcx
    idivq %rcx
    movq %rax, 32(%r13)
    jmp .Lws_zero
.Lws_clock:
    testq %r12, %r12
    jz .Lws_clock_real
    cmpq $2, %r12
    je .Lws_clock_cpu
    cmpq $3, %r12
    je .Lws_clock_cpu
    leaq 64(%rsp), %rcx
    call QueryPerformanceCounter
    leaq 72(%rsp), %rcx
    call QueryPerformanceFrequency
    movq 72(%rsp), %rcx
    movq 64(%rsp), %rax
    cqto
    idivq %rcx
    movq %rax, (%r13)
    movq %rdx, %rax
    imulq $1000000000, %rax
    cqto
    idivq %rcx
    movq %rax, 8(%r13)
    jmp .Lws_zero
# CPU time: FILETIME creation, exit, kernel, user at 64/72/80/88(%rsp)
.Lws_clock_cpu:
    cmpq $3, %r12
    je .Lws_clock_thr
    movq $-1, %rcx
    leaq 64(%rsp), %rdx
    leaq 72(%rsp), %r8
    leaq 80(%rsp), %r9
    leaq 88(%rsp), %rax
    movq %rax, 32(%rsp)
    call GetProcessTimes
    jmp .Lws_clock_cpu2
.Lws_clock_thr:
    movq $-2, %rcx
    leaq 64(%rsp), %rdx
    leaq 72(%rsp), %r8
    leaq 80(%rsp), %r9
    leaq 88(%rsp), %rax
    movq %rax, 32(%rsp)
    call GetThreadTimes
.Lws_clock_cpu2:
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    movq 80(%rsp), %rax
    addq 88(%rsp), %rax
    cqto
    movq $10000000, %rcx
    idivq %rcx
    movq %rax, (%r13)
    imulq $100, %rdx
    movq %rdx, 8(%r13)
    jmp .Lws_zero
.Lws_clock_real:
    leaq 64(%rsp), %rcx
    call GetSystemTimePreciseAsFileTime
    movq 64(%rsp), %rax
    movq $116444736000000000, %rcx
    subq %rcx, %rax
    cqto
    movq $10000000, %rcx
    idivq %rcx
    movq %rax, (%r13)
    imulq $100, %rdx
    movq %rdx, 8(%r13)
    jmp .Lws_zero
# uname(r12 = struct utsname, 6 x 65 bytes)
.Lws_uname:
    movq %r12, %rdi
    movq $390, %rcx
.Lws_un_z:
    movb $0, (%rdi)
    incq %rdi
    decq %rcx
    jnz .Lws_un_z
    leaq .Lws_un_sys(%rip), %rsi
    movq %r12, %rdi
    call .Lws_un_cpy
    leaq .Lws_un_mach(%rip), %rsi
    leaq 260(%r12), %rdi
    call .Lws_un_cpy
    movq $64, 64(%rsp)
    leaq 65(%r12), %rcx
    leaq 64(%rsp), %rdx
    call GetComputerNameA
    leaq 130(%r12), %rdi
    movq $2147353196, %rax
    movq (%rax), %rax
    shlq $32, %rax
    shrq $32, %rax
    call .Lws_un_num
    movb $46, (%rdi)
    incq %rdi
    movq $2147353200, %rax
    movq (%rax), %rax
    shlq $32, %rax
    shrq $32, %rax
    call .Lws_un_num
    movb $46, (%rdi)
    incq %rdi
    movq $2147353184, %rax
    movq (%rax), %rax
    shlq $32, %rax
    shrq $32, %rax
    call .Lws_un_num
    jmp .Lws_zero
# copy the C string rsi to rdi (no API call)
.Lws_un_cpy:
    movzbq (%rsi), %rax
    movb %al, (%rdi)
    testq %rax, %rax
    jz .Lws_un_cpy_out
    incq %rsi
    incq %rdi
    jmp .Lws_un_cpy
.Lws_un_cpy_out:
    ret
# write eax (zero-extended) in decimal at rdi, rdi advanced (no API call)
.Lws_un_num:
    movq $10, %rcx
    xorq %r8, %r8
.Lws_un_n1:
    cqto
    idivq %rcx
    addq $48, %rdx
    pushq %rdx
    incq %r8
    testq %rax, %rax
    jnz .Lws_un_n1
.Lws_un_n2:
    popq %rax
    movb %al, (%rdi)
    incq %rdi
    decq %r8
    jnz .Lws_un_n2
    ret
# ---- sockets ------------------------------------------------------------------------------------------------
# load ws2_32.dll and its functions once, then WSAStartup(2.2): rax = 1, or 0 when Winsock is not available.
# Entered by call; keeps rbx, rsi, rdi.
.Lws_ws_init:
    cmpq $0, .Lws_ws_ok(%rip)
    jne .Lws_wsi_yes
    pushq %rbx
    pushq %rsi
    pushq %rdi
    subq $32, %rsp
    leaq .Lws_ws_dll(%rip), %rcx
    xorq %rdx, %rdx
    movq $2048, %r8
    call LoadLibraryExA
    testq %rax, %rax
    jz .Lws_wsi_no
    movq %rax, %rbx
    leaq .Lws_ws_names(%rip), %rsi
    leaq .Lws_ws_fn(%rip), %rdi
.Lws_wsi_l:
    cmpb $0, (%rsi)
    je .Lws_wsi_start
    movq %rbx, %rcx
    movq %rsi, %rdx
    call GetProcAddress
    testq %rax, %rax
    jz .Lws_wsi_no
    movq %rax, (%rdi)
    addq $8, %rdi
.Lws_wsi_skip:
    incq %rsi
    cmpb $0, -1(%rsi)
    jne .Lws_wsi_skip
    jmp .Lws_wsi_l
.Lws_wsi_start:
    movq $514, %rcx
    leaq .Lws_wsadata(%rip), %rdx
    movq .Lws_ws_fn(%rip), %rax
    call *%rax
    testq %rax, %rax
    jnz .Lws_wsi_no
    movq $1, .Lws_ws_ok(%rip)
    addq $32, %rsp
    popq %rdi
    popq %rsi
    popq %rbx
.Lws_wsi_yes:
    movq $1, %rax
    ret
.Lws_wsi_no:
    addq $32, %rsp
    popq %rdi
    popq %rsi
    popq %rbx
    xorq %rax, %rax
    ret
# a failed Winsock call: WSAGetLastError -> -errno
.Lws_ws_fail:
    movq .Lws_ws_fn+104(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    leaq .Lws_ws_err(%rip), %rcx
.Lws_wsf_l:
    movq (%rcx), %rdx
    testq %rdx, %rdx
    jz .Lws_wsf_other
    cmpq %rdx, %rax
    je .Lws_wsf_hit
    addq $16, %rcx
    jmp .Lws_wsf_l
.Lws_wsf_hit:
    movq 8(%rcx), %rax
    jmp .Lws_ret
.Lws_wsf_other:
    movq $-5, %rax
    jmp .Lws_ret
.Lws_socket:
    call .Lws_ws_init
    testq %rax, %rax
    jz .Lws_enosys
    movq $2, %rcx
    cmpq $2, %r12
    jne .Lws_eafnosupport
    movq %r13, %rdx
    andq $15, %rdx
    movq %r14, %r8
    movq .Lws_ws_fn+8(%rip), %rax
    call *%rax
    cmpq $-1, %rax
    je .Lws_ws_fail
    movq %rax, 64(%rsp)
    movq $5, %r8
    movq %rax, %r9
    call .Lws_fd_new
    testq %rax, %rax
    jns .Lws_ret
    movq %rax, 72(%rsp)
    movq 64(%rsp), %rcx
    movq .Lws_ws_fn+96(%rip), %rax
    call *%rax
    movq 72(%rsp), %rax
    jmp .Lws_ret
.Lws_eafnosupport:
    movq $-97, %rax
    jmp .Lws_ret
.Lws_enotsock:
    movq $-88, %rax
    jmp .Lws_ret
.Lws_enosys:
    movq $-38, %rax
    jmp .Lws_ret
# connect(fd, addr, len) / bind(fd, addr, len): the same three arguments
.Lws_connect:
    movq $16, %rbx
    jmp .Lws_sock3
.Lws_bind:
    movq $32, %rbx
.Lws_sock3:
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_enotsock
    movq %rax, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    leaq .Lws_ws_fn(%rip), %rax
    movq (%rax,%rbx,1), %rax
    call *%rax
    testq %rax, %rax
    jnz .Lws_ws_fail
    jmp .Lws_zero
.Lws_listen:
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_enotsock
    movq %rax, %rcx
    movq %r13, %rdx
    movq .Lws_ws_fn+40(%rip), %rax
    call *%rax
    testq %rax, %rax
    jnz .Lws_ws_fail
    jmp .Lws_zero
.Lws_shutdown:
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_enotsock
    movq %rax, %rcx
    movq %r13, %rdx
    movq .Lws_ws_fn+88(%rip), %rax
    call *%rax
    testq %rax, %rax
    jnz .Lws_ws_fail
    jmp .Lws_zero
# accept(fd, addr, lenp): socklen_t is a 32-bit int on both systems
.Lws_accept:
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_enotsock
    movq %rax, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    movq .Lws_ws_fn+24(%rip), %rax
    call *%rax
    cmpq $-1, %rax
    je .Lws_ws_fail
    movq %rax, 64(%rsp)
    movq $5, %r8
    movq %rax, %r9
    call .Lws_fd_new
    testq %rax, %rax
    jns .Lws_ret
    movq %rax, 72(%rsp)
    movq 64(%rsp), %rcx
    movq .Lws_ws_fn+96(%rip), %rax
    call *%rax
    movq 72(%rsp), %rax
    jmp .Lws_ret
# setsockopt(fd, level, name, val, len): SO_REUSEADDR is Linux's default rebinding rule on Windows (and Winsock's
# SO_REUSEADDR would let another socket steal the port), so it succeeds without a change; TCP options pass through
.Lws_setsockopt:
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_enotsock
    cmpq $1, %r13
    jne .Lws_sso_tcp
    cmpq $2, %r14
    je .Lws_zero
    movq $-92, %rax
    jmp .Lws_ret
.Lws_sso_tcp:
    cmpq $6, %r13
    jne .Lws_sso_bad
    movq %rax, %rcx
    movq $6, %rdx
    movq %r14, %r8
    movq %r15, %r9
    movq %rbx, 32(%rsp)
    movq .Lws_ws_fn+48(%rip), %rax
    call *%rax
    testq %rax, %rax
    jnz .Lws_ws_fail
    jmp .Lws_zero
.Lws_sso_bad:
    movq $-92, %rax
    jmp .Lws_ret
# sendto(fd, buf, len, flags, addr, alen) / recvfrom(fd, buf, len, flags, addr, alenp); the 6th argument is the
# saved r9 of the caller (-48(%rbp))
.Lws_sendto:
    movq $72, %rax
    jmp .Lws_sock6
.Lws_recvfrom:
    movq $80, %rax
.Lws_sock6:
    movq %rax, 88(%rsp)
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_enotsock
    movq %rax, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    movq $2147483647, %rax
    cmpq %rax, %r8
    jle .Lws_s6_n
    movq %rax, %r8
.Lws_s6_n:
    movq %r15, %r9
    movq %rbx, 32(%rsp)
    movq -48(%rbp), %rax
    movq %rax, 40(%rsp)
    leaq .Lws_ws_fn(%rip), %rax
    addq 88(%rsp), %rax
    movq (%rax), %rax
    call *%rax
    shlq $32, %rax
    sarq $32, %rax
    cmpq $-1, %rax
    je .Lws_ws_fail
    jmp .Lws_ret
# read / write on a socket: recv / send with flags 0 (rax = SOCKET)
.Lws_read_sock:
    movq %rax, 72(%rsp)
    movq %r13, %rcx
    movq %r14, %rdx
    call .Lws_nr_commit
    movq 72(%rsp), %rcx
    movq %r13, %rdx
    movq %r14, %r8
    movq $2147483647, %rax
    cmpq %rax, %r8
    jle .Lws_rs_n
    movq %rax, %r8
.Lws_rs_n:
    xorq %r9, %r9
    movq .Lws_ws_fn+64(%rip), %rax
    call *%rax
    shlq $32, %rax
    sarq $32, %rax
    cmpq $-1, %rax
    je .Lws_ws_fail
    jmp .Lws_ret
.Lws_write_sock:
    movq %rax, 72(%rsp)
    movq %r13, %rcx
    movq %r14, %rdx
    call .Lws_nr_commit
    movq 72(%rsp), %rcx
    movq %r13, %rdx
    movq %r14, %r8
    movq $2147483647, %rax
    cmpq %rax, %r8
    jle .Lws_ws_n
    movq %rax, %r8
.Lws_ws_n:
    xorq %r9, %r9
    movq .Lws_ws_fn+56(%rip), %rax
    call *%rax
    shlq $32, %rax
    sarq $32, %rax
    cmpq $-1, %rax
    je .Lws_ws_fail
    jmp .Lws_ret
.Lws_close_sock:
    movq 64(%rsp), %rcx
    movq .Lws_ws_fn+96(%rip), %rax
    call *%rax
    jmp .Lws_zero
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
# every shared mapping (os_shm_map): the same section mapped into the child at the same address, and its handle
# duplicated into the child so its own munmap works
    leaq .Lws_shm(%rip), %r15
    movq $64, %r13
.Lws_fr_shm:
    cmpq $0, (%r15)
    je .Lws_fr_snext
    call .Lws_mvn2
    testq %rax, %rax
    jz .Lws_fr_abort
    movq 16(%r15), %rcx
    movq .Lws_fk_proc(%rip), %rdx
    xorq %r8, %r8
    movq (%r15), %r9
    movq 8(%r15), %r10
    movq %r10, 32(%rsp)
    movq $0, 40(%rsp)
    movq $4, 48(%rsp)
    movq $-1, 56(%rsp)
    call *%rax
    cmpq (%r15), %rax
    jne .Lws_fr_abort
    call GetCurrentProcess
    movq %rax, %rcx
    movq 16(%r15), %rdx
    movq .Lws_fk_proc(%rip), %r8
    leaq 88(%rsp), %r9
    movq $0, 88(%rsp)
    movq $0, 32(%rsp)
    movq $0, 40(%rsp)
    movq $2, 48(%rsp)
    call DuplicateHandle
    movq .Lws_fk_proc(%rip), %rcx
    leaq 16(%r15), %rdx
    leaq 88(%rsp), %r8
    movq $8, %r9
    movq $0, 32(%rsp)
    call WriteProcessMemory
.Lws_fr_snext:
    addq $24, %r15
    decq %r13
    jnz .Lws_fr_shm
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
.Lws_getdents:
    call .Lws_fdh
    cmpq $2, %rcx
    jne .Lws_enotdir
    movq %rax, %rbx
    movq $0, 64(%rsp)
.Lws_gd_loop:
    cmpq $2, 16(%rbx)
    je .Lws_gd_done
    movq $65001, %rcx
    xorq %rdx, %rdx
    leaq 76(%rbx), %r8
    movq $-1, %r9
    leaq .Lws_nbuf(%rip), %rax
    movq %rax, 32(%rsp)
    movq $1024, 40(%rsp)
    movq $0, 48(%rsp)
    movq $0, 56(%rsp)
    call WideCharToMultiByte
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_gd_next
    movq %rax, 80(%rsp)
    leaq 26(%rax), %rcx
    andq $-8, %rcx
    movq %rcx, 72(%rsp)
    movq 64(%rsp), %rdx
    addq %rcx, %rdx
    cmpq %r14, %rdx
    jg .Lws_gd_full
    movq 64(%rsp), %rdi
    addq %r13, %rdi
    movq $1, (%rdi)
    movq $0, 8(%rdi)
    movq 72(%rsp), %rax
    movb %al, 16(%rdi)
    shrq $8, %rax
    movb %al, 17(%rdi)
    movb $8, 18(%rdi)
    movq 32(%rbx), %rax
    andq $16, %rax
    testq %rax, %rax
    jz .Lws_gd_type
    movb $4, 18(%rdi)
.Lws_gd_type:
    leaq .Lws_nbuf(%rip), %rsi
    leaq 19(%rdi), %rdx
    movq 80(%rsp), %rcx
.Lws_gd_copy:
    movzbq (%rsi), %rax
    movb %al, (%rdx)
    incq %rsi
    incq %rdx
    decq %rcx
    jnz .Lws_gd_copy
    movq 72(%rsp), %rax
    addq %rax, 64(%rsp)
.Lws_gd_next:
    movq 8(%rbx), %rcx
    leaq 32(%rbx), %rdx
    call FindNextFileW
    shlq $32, %rax
    shrq $32, %rax
    movq $0, 16(%rbx)
    testq %rax, %rax
    jnz .Lws_gd_loop
    movq $2, 16(%rbx)
    jmp .Lws_gd_loop
.Lws_gd_full:
    cmpq $0, 64(%rsp)
    je .Lws_einval
.Lws_gd_done:
    movq 64(%rsp), %rax
    jmp .Lws_ret
# --- processes: vfork semantics on CreateProcessW ---
# fork/vfork returns 0 and the caller continues as the "child" inside this process (vfork rules: the child borrows the
# parent's memory). In that mode open() makes inheritable handles (closed in the parent afterwards), dup2(fd, 0..2) sets
# the child's standard handles, close() is deferred. execve() then starts the program with CreateProcessW and resumes the
# parent right after its fork call with the child's pid; exit() resumes it with a synthetic pid of a finished child.
# wait4() returns the Linux status word ((exit code & 255) << 8, or the signal number), WNOHANG polls, rusage carries
# user / system time and the peak working set; kill() is TerminateProcess; pipe() is CreatePipe.
# Kid record (40 bytes): pid, process handle, done, status, signal sent by kill.
.Lws_fork:
    movq $1263685446, %rax
    cmpq %rax, %r12
    je .Lws_fork_real
    cmpq $0, .Lws_fk_mode(%rip)
    je .Lws_fork_ok
    movq $-11, %rax
    jmp .Lws_ret
.Lws_fork_ok:
    leaq .Lws_fk_ctx(%rip), %rcx
    movq -8(%rbp), %rax
    movq %rax, (%rcx)
    movq -16(%rbp), %rax
    movq %rax, 8(%rcx)
    movq -24(%rbp), %rax
    movq %rax, 16(%rcx)
    movq -32(%rbp), %rax
    movq %rax, 24(%rcx)
    movq -40(%rbp), %rax
    movq %rax, 32(%rcx)
    movq -48(%rbp), %rax
    movq %rax, 40(%rcx)
    movq -56(%rbp), %rax
    movq %rax, 48(%rcx)
    movq -64(%rbp), %rax
    movq %rax, 56(%rcx)
    movq -72(%rbp), %rax
    movq %rax, 64(%rcx)
    movq -80(%rbp), %rax
    movq %rax, 72(%rcx)
    movq -88(%rbp), %rax
    movq %rax, 80(%rcx)
    movq (%rbp), %rax
    movq %rax, 88(%rcx)
    movq 8(%rbp), %rax
    movq %rax, 96(%rcx)
    leaq 16(%rbp), %rax
    movq %rax, 104(%rcx)
    movq $1, .Lws_fk_mode(%rip)
    movq $0, .Lws_fk_std(%rip)
    movq $0, .Lws_fk_std+8(%rip)
    movq $0, .Lws_fk_std+16(%rip)
    movq $0, .Lws_fk_nopen(%rip)
    jmp .Lws_zero
# resume the parent after its fork call, rax = the child's pid
.Lws_fk_resume:
    movq $0, .Lws_fk_mode(%rip)
    leaq .Lws_fk_ctx(%rip), %rcx
    movq 104(%rcx), %rsp
    movq (%rcx), %rbx
    movq 8(%rcx), %rdi
    movq 16(%rcx), %rsi
    movq 24(%rcx), %rdx
    movq 32(%rcx), %r8
    movq 40(%rcx), %r9
    movq 48(%rcx), %r10
    movq 56(%rcx), %r12
    movq 64(%rcx), %r13
    movq 72(%rcx), %r14
    movq 80(%rcx), %r15
    movq 88(%rcx), %rbp
    movq 96(%rcx), %r11
    pushq %r11
    ret
# free kid record in rax, or 0 (no API call: may be called with rsp = 8 mod 16)
.Lws_kid_slot:
    leaq .Lws_kids(%rip), %rax
    movq $64, %rcx
.Lws_ks_loop:
    cmpq $0, (%rax)
    je .Lws_ks_ret
    addq $40, %rax
    decq %rcx
    jnz .Lws_ks_loop
    xorq %rax, %rax
.Lws_ks_ret:
    ret
# kid record of pid r12 (-1: any) in rax, or 0
.Lws_kid_find:
    leaq .Lws_kids(%rip), %rax
    movq $64, %rcx
.Lws_kf_loop:
    movq (%rax), %rdx
    testq %rdx, %rdx
    jz .Lws_kf_next
    cmpq $-1, %r12
    je .Lws_kf_ret
    cmpq %rdx, %r12
    je .Lws_kf_ret
.Lws_kf_next:
    addq $40, %rax
    decq %rcx
    jnz .Lws_kf_loop
    xorq %rax, %rax
.Lws_kf_ret:
    ret
# close the handles a vfork child opened (they now belong to the child process)
.Lws_fk_close_opened:
    subq $40, %rsp
.Lws_fco_loop:
    movq .Lws_fk_nopen(%rip), %rcx
    testq %rcx, %rcx
    jz .Lws_fco_done
    decq %rcx
    movq %rcx, .Lws_fk_nopen(%rip)
    leaq .Lws_fk_open(%rip), %rdx
    movq (%rdx,%rcx,8), %rcx
    leaq .Lws_fdt(%rip), %rax
    shlq $4, %rcx
    addq %rcx, %rax
    movq 8(%rax), %rcx
    movq $0, (%rax)
    movq $0, 8(%rax)
    call CloseHandle
    jmp .Lws_fco_loop
.Lws_fco_done:
    addq $40, %rsp
    ret
.Lws_e2big:
    movq $-7, %rax
    jmp .Lws_ret
# envp .Lws_envp_arg (NULL-terminated UTF-8 strings) -> rax = UTF-16 environment block (VirtualAlloc, zeroed, so the
# block ends in two NULs), 0 when there is no envp. Entered by call; keeps rbx, rsi, rdi, r12, r13.
.Lws_envblock:
    pushq %rbx
    pushq %rsi
    pushq %rdi
    pushq %r12
    pushq %r13
    subq $64, %rsp
    xorq %rax, %rax
    movq .Lws_envp_arg(%rip), %rdi
    testq %rdi, %rdi
    jz .Lws_eb_out
    xorq %rcx, %rcx
    movq $4194304, %rdx
    movq $12288, %r8
    movq $4, %r9
    call VirtualAlloc
    testq %rax, %rax
    jz .Lws_eb_out
    movq %rax, %r12
    movq %rax, %r13
    xorq %rbx, %rbx
.Lws_eb_l:
    movq (%rdi,%rbx,8), %rsi
    testq %rsi, %rsi
    jz .Lws_eb_end
    incq %rbx
    leaq 4194296(%r12), %rax
    subq %r13, %rax
    shrq $1, %rax
    cmpq $2, %rax
    jl .Lws_eb_end
    movq %r13, 32(%rsp)
    movq %rax, 40(%rsp)
    movq $65001, %rcx
    xorq %rdx, %rdx
    movq %rsi, %r8
    movq $-1, %r9
    call MultiByteToWideChar
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_eb_l
    shlq $1, %rax
    addq %rax, %r13
    jmp .Lws_eb_l
.Lws_eb_end:
    movq %r12, %rax
.Lws_eb_out:
    addq $64, %rsp
    popq %r13
    popq %r12
    popq %rdi
    popq %rsi
    popq %rbx
    ret
.Lws_execve:
    movq %r14, .Lws_envp_arg(%rip)
    leaq .Lws_cbuf(%rip), %rdi
    movq %r13, %rbx
    xorq %r15, %r15
.Lws_ex_arg:
    movq (%rbx), %rsi
    testq %rsi, %rsi
    jz .Lws_ex_cmd_done
    testq %r15, %r15
    jz .Lws_ex_first
    movb $32, (%rdi)
    incq %rdi
.Lws_ex_first:
    incq %r15
    leaq .Lws_cbuf(%rip), %rax
    movq %rdi, %rcx
    subq %rax, %rcx
    cmpq $65536, %rcx
    jg .Lws_e2big
    movq %rsi, %rcx
    movzbq (%rcx), %rax
    testq %rax, %rax
    jz .Lws_ex_quote
.Lws_ex_scan:
    movzbq (%rcx), %rax
    testq %rax, %rax
    jz .Lws_ex_plain
    cmpq $32, %rax
    je .Lws_ex_quote
    cmpq $9, %rax
    je .Lws_ex_quote
    cmpq $34, %rax
    je .Lws_ex_quote
    incq %rcx
    jmp .Lws_ex_scan
.Lws_ex_plain:
    movzbq (%rsi), %rax
    testq %rax, %rax
    jz .Lws_ex_next
    movb %al, (%rdi)
    incq %rsi
    incq %rdi
    jmp .Lws_ex_plain
.Lws_ex_quote:
    movb $34, (%rdi)
    incq %rdi
    xorq %rdx, %rdx
.Lws_ex_q:
    movzbq (%rsi), %rax
    testq %rax, %rax
    jz .Lws_ex_qend
    incq %rsi
    cmpq $92, %rax
    jne .Lws_ex_qnb
    incq %rdx
    jmp .Lws_ex_q
.Lws_ex_qnb:
    cmpq $34, %rax
    jne .Lws_ex_qch
    movq %rdx, %rcx
    addq %rdx, %rcx
    incq %rcx
.Lws_ex_bs1:
    testq %rcx, %rcx
    jz .Lws_ex_bs1d
    movb $92, (%rdi)
    incq %rdi
    decq %rcx
    jmp .Lws_ex_bs1
.Lws_ex_bs1d:
    movb $34, (%rdi)
    incq %rdi
    xorq %rdx, %rdx
    jmp .Lws_ex_q
.Lws_ex_qch:
    movq %rdx, %rcx
.Lws_ex_bs2:
    testq %rcx, %rcx
    jz .Lws_ex_bs2d
    movb $92, (%rdi)
    incq %rdi
    decq %rcx
    jmp .Lws_ex_bs2
.Lws_ex_bs2d:
    movb %al, (%rdi)
    incq %rdi
    xorq %rdx, %rdx
    jmp .Lws_ex_q
.Lws_ex_qend:
    movq %rdx, %rcx
    addq %rdx, %rcx
.Lws_ex_bs3:
    testq %rcx, %rcx
    jz .Lws_ex_bs3d
    movb $92, (%rdi)
    incq %rdi
    decq %rcx
    jmp .Lws_ex_bs3
.Lws_ex_bs3d:
    movb $34, (%rdi)
    incq %rdi
.Lws_ex_next:
    addq $8, %rbx
    jmp .Lws_ex_arg
.Lws_ex_cmd_done:
    movb $0, (%rdi)
    movq $65001, %rcx
    xorq %rdx, %rdx
    leaq .Lws_cbuf(%rip), %r8
    movq $-1, %r9
    leaq .Lws_cwbuf(%rip), %rax
    movq %rax, 32(%rsp)
    movq $32768, 40(%rsp)
    call MultiByteToWideChar
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_e2big
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
    movq %rax, 96(%rsp)
# "<path>.exe" first (the Windows convention, and a build tree can hold a Linux binary of the same name), then <path>
    leaq .Lws_wbuf(%rip), %rcx
    movq 96(%rsp), %rax
    leaq -2(%rcx,%rax,2), %rdx
    movb $46, (%rdx)
    movb $0, 1(%rdx)
    movb $101, 2(%rdx)
    movb $0, 3(%rdx)
    movb $120, 4(%rdx)
    movb $0, 5(%rdx)
    movb $101, 6(%rdx)
    movb $0, 7(%rdx)
    movb $0, 8(%rdx)
    movb $0, 9(%rdx)
    leaq .Lws_wbuf(%rip), %rcx
    call GetFileAttributesW
    shlq $32, %rax
    shrq $32, %rax
    movq $4294967295, %rcx
    cmpq %rcx, %rax
    jne .Lws_ex_app
    leaq .Lws_wbuf(%rip), %rcx
    movq 96(%rsp), %rax
    leaq -2(%rcx,%rax,2), %rdx
    movb $0, (%rdx)
    movb $0, 1(%rdx)
.Lws_ex_app:
    xorq %rcx, %rcx
.Lws_ex_zero:
    movq $0, 112(%rsp,%rcx,8)
    incq %rcx
    cmpq $17, %rcx
    jl .Lws_ex_zero
    movq $104, 112(%rsp)
    movq $1099511627776, %rax
    movq %rax, 168(%rsp)
    xorq %r14, %r14
.Lws_ex_std:
    leaq .Lws_fk_std(%rip), %rax
    movq (%rax,%r14,8), %rax
    cmpq $0, .Lws_fk_mode(%rip)
    je .Lws_ex_std_def
    testq %rax, %rax
    jnz .Lws_ex_std_have
.Lws_ex_std_def:
    movq $-10, %rcx
    subq %r14, %rcx
    call GetStdHandle
.Lws_ex_std_have:
    movq %rax, 192(%rsp,%r14,8)
    movq %rax, %rcx
    movq $1, %rdx
    movq $1, %r8
    call SetHandleInformation
    incq %r14
    cmpq $3, %r14
    jl .Lws_ex_std
    call .Lws_envblock
    movq %rax, .Lws_envblk(%rip)
    leaq .Lws_wbuf(%rip), %rcx
    leaq .Lws_cwbuf(%rip), %rdx
    xorq %r8, %r8
    xorq %r9, %r9
    movq $1, 32(%rsp)
    movq $0, 40(%rsp)
    movq %rax, 48(%rsp)
    testq %rax, %rax
    jz .Lws_ex_noenv
    movq $1024, 40(%rsp)
.Lws_ex_noenv:
    movq $0, 56(%rsp)
    leaq 112(%rsp), %rax
    movq %rax, 64(%rsp)
    leaq 224(%rsp), %rax
    movq %rax, 72(%rsp)
    call CreateProcessW
    shlq $32, %rax
    shrq $32, %rax
    movq %rax, .Lws_cpres(%rip)
    testq %rax, %rax
    jnz .Lws_ex_free
    call GetLastError
    movq %rax, .Lws_cperr(%rip)
.Lws_ex_free:
    movq .Lws_envblk(%rip), %rcx
    testq %rcx, %rcx
    jz .Lws_ex_freed
    xorq %rdx, %rdx
    movq $32768, %r8
    call VirtualFree
.Lws_ex_freed:
    cmpq $0, .Lws_cpres(%rip)
    jne .Lws_ex_made
    movq .Lws_cperr(%rip), %rax
    shlq $32, %rax
    shrq $32, %rax
    jmp .Lws_errmap
.Lws_ex_made:
    movq 232(%rsp), %rcx
    call CloseHandle
    movq 240(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    movq %rax, 80(%rsp)
    cmpq $0, .Lws_fk_mode(%rip)
    je .Lws_ex_replace
    call .Lws_kid_slot
    testq %rax, %rax
    jz .Lws_ex_nokid
    movq 80(%rsp), %rcx
    movq %rcx, (%rax)
    movq 224(%rsp), %rcx
    movq %rcx, 8(%rax)
    movq $0, 16(%rax)
    movq $0, 24(%rax)
    movq $0, 32(%rax)
.Lws_ex_nokid:
    call .Lws_fk_close_opened
    movq 80(%rsp), %rax
    jmp .Lws_fk_resume
# execve without a fork: run the program, then exit with its exit code (the process image cannot be replaced)
.Lws_ex_replace:
    movq 224(%rsp), %rcx
    movq $4294967295, %rdx
    call WaitForSingleObject
    movq $0, 88(%rsp)
    movq 224(%rsp), %rcx
    leaq 88(%rsp), %rdx
    call GetExitCodeProcess
    movq 88(%rsp), %rcx
    call ExitProcess
.Lws_wait4:
    cmpq $0, %r12
    jg .Lws_w_find
    movq $-1, %r12
.Lws_w_find:
    call .Lws_kid_find
    testq %rax, %rax
    jnz .Lws_w_have
    movq $-10, %rax
    jmp .Lws_ret
.Lws_w_have:
    movq %rax, %rbx
    cmpq $0, 16(%rbx)
    jne .Lws_w_done
    movq 8(%rbx), %rcx
    movq $4294967295, %rdx
    movq %r14, %rax
    andq $1, %rax
    testq %rax, %rax
    jz .Lws_w_wait
    xorq %rdx, %rdx
.Lws_w_wait:
    call WaitForSingleObject
    shlq $32, %rax
    shrq $32, %rax
    cmpq $258, %rax
    je .Lws_zero
    movq $0, 88(%rsp)
    movq 8(%rbx), %rcx
    leaq 88(%rsp), %rdx
    call GetExitCodeProcess
    movq 88(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    movq 32(%rbx), %rcx
    testq %rcx, %rcx
    jz .Lws_w_code
    movq %rcx, %rax
    jmp .Lws_w_set
.Lws_w_code:
    movq %rax, %rcx
    andq $-256, %rcx
    movq $3758096384, %rdx
    cmpq %rdx, %rcx
    jne .Lws_w_nt
    movq %rax, %rcx
    andq $127, %rcx
    jmp .Lws_w_sig
.Lws_w_nt:
    movq $3221225472, %rcx
    cmpq %rcx, %rax
    jl .Lws_w_exit
    movq $11, %rcx
    movq $3221225477, %rdx
    cmpq %rdx, %rax
    je .Lws_w_sig
    movq $3221225725, %rdx
    cmpq %rdx, %rax
    je .Lws_w_sig
    movq $8, %rcx
    movq $3221225620, %rdx
    cmpq %rdx, %rax
    je .Lws_w_sig
    movq $3221225621, %rdx
    cmpq %rdx, %rax
    je .Lws_w_sig
    movq $4, %rcx
    movq $3221225501, %rdx
    cmpq %rdx, %rax
    je .Lws_w_sig
    movq $2, %rcx
    movq $3221225786, %rdx
    cmpq %rdx, %rax
    je .Lws_w_sig
    movq $6, %rcx
.Lws_w_sig:
    movq %rcx, %rax
    jmp .Lws_w_set
.Lws_w_exit:
    andq $255, %rax
    imulq $256, %rax
.Lws_w_set:
    movq %rax, 24(%rbx)
    movq $1, 16(%rbx)
    testq %r15, %r15
    jz .Lws_w_close
    xorq %rcx, %rcx
.Lws_w_rz:
    movq $0, (%r15,%rcx,8)
    incq %rcx
    cmpq $18, %rcx
    jl .Lws_w_rz
    movq 8(%rbx), %rcx
    leaq 128(%rsp), %rdx
    leaq 136(%rsp), %r8
    leaq 144(%rsp), %r9
    leaq 152(%rsp), %rax
    movq %rax, 32(%rsp)
    call GetProcessTimes
    movq 152(%rsp), %rax
    cqto
    movq $10000000, %rcx
    idivq %rcx
    movq %rax, (%r15)
    movq %rdx, %rax
    cqto
    movq $10, %rcx
    idivq %rcx
    movq %rax, 8(%r15)
    movq 144(%rsp), %rax
    cqto
    movq $10000000, %rcx
    idivq %rcx
    movq %rax, 16(%r15)
    movq %rdx, %rax
    cqto
    movq $10, %rcx
    idivq %rcx
    movq %rax, 24(%r15)
    movq $72, 160(%rsp)
    movq 8(%rbx), %rcx
    leaq 160(%rsp), %rdx
    movq $72, %r8
    call K32GetProcessMemoryInfo
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_w_close
    movq 168(%rsp), %rax
    cqto
    movq $1024, %rcx
    idivq %rcx
    movq %rax, 32(%r15)
.Lws_w_close:
    movq 8(%rbx), %rcx
    call CloseHandle
    movq $0, 8(%rbx)
.Lws_w_done:
    testq %r13, %r13
    jz .Lws_w_nost
    movq 24(%rbx), %rax
    movq %rax, (%r13)
.Lws_w_nost:
    movq (%rbx), %rax
    movq $0, (%rbx)
    movq $0, 16(%rbx)
    jmp .Lws_ret
.Lws_kill:
# kill(own pid, sig): the process ends with 0xE0000000 | sig, which wait4 reports as that signal (sig 0: alive)
    call GetCurrentProcessId
    shlq $32, %rax
    shrq $32, %rax
    cmpq %rax, %r12
    jne .Lws_kill_kid
    testq %r13, %r13
    jz .Lws_zero
    movq %r13, %rdx
    andq $127, %rdx
    movq $3758096384, %rax
    orq %rax, %rdx
    movq $-1, %rcx
    call TerminateProcess
    jmp .Lws_zero
.Lws_kill_kid:
    call .Lws_kid_find
    testq %rax, %rax
    jnz .Lws_kill_have
    movq $-3, %rax
    jmp .Lws_ret
.Lws_kill_have:
    movq %rax, %rbx
    testq %r13, %r13
    jz .Lws_zero
    cmpq $0, 16(%rbx)
    jne .Lws_zero
    movq %r13, 32(%rbx)
    movq 8(%rbx), %rcx
    movq %r13, %rdx
    addq $128, %rdx
    call TerminateProcess
    jmp .Lws_zero
.Lws_pipe:
    leaq 80(%rsp), %rcx
    leaq 88(%rsp), %rdx
    xorq %r8, %r8
    movq $65536, %r9
    call CreatePipe
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    movq $1, %r8
    movq 80(%rsp), %r9
    call .Lws_fd_new
    movq %rax, 96(%rsp)
    movq $1, %r8
    movq 88(%rsp), %r9
    call .Lws_fd_new
    movq %rax, 104(%rsp)
    movq 96(%rsp), %rcx
    testq %rcx, %rcx
    js .Lws_pipe_full
    testq %rax, %rax
    js .Lws_pipe_full
    shlq $32, %rax
    addq %rcx, %rax
    movq %rax, (%r12)
    jmp .Lws_zero
.Lws_pipe_full:
    movq 80(%rsp), %rcx
    call CloseHandle
    movq 88(%rsp), %rcx
    call CloseHandle
    movq $-24, %rax
    jmp .Lws_ret
.Lws_dup2:
    cmpq $2, %r13
    jg .Lws_ebadf
    testq %r13, %r13
    js .Lws_ebadf
    call .Lws_fdh
    cmpq $1, %rcx
    je .Lws_dup2_h
    cmpq $4, %rcx
    jne .Lws_ebadf
.Lws_dup2_h:
    movq %rax, 80(%rsp)
    cmpq $0, .Lws_fk_mode(%rip)
    je .Lws_dup2_parent
    leaq .Lws_fk_std(%rip), %rcx
    movq %rax, (%rcx,%r13,8)
    movq %rax, %rcx
    movq $1, %rdx
    movq $1, %r8
    call SetHandleInformation
    movq %r13, %rax
    jmp .Lws_ret
.Lws_dup2_parent:
    movq $-10, %rcx
    subq %r13, %rcx
    movq 80(%rsp), %rdx
    call SetStdHandle
    movq %r13, %rax
    jmp .Lws_ret
# __win_start: the process start-up that Linux gets from the kernel: argc, argv and envp as UTF-8 C strings
# (argv[argc] = 0, then envp, then 0, as on the Linux initial stack), UTF-8 console, no error boxes,
# a stack guarantee for the exception handler, and the vectored exception handler.
__win_start:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %rdi
    pushq %rsi
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    andq $-16, %rsp
    subq $96, %rsp
    movq $4, .Lws_fdt(%rip)
    movq $4, .Lws_fdt+16(%rip)
    movq $4, .Lws_fdt+32(%rip)
    movq $32771, %rcx
    call SetErrorMode
# opt out of power throttling (EcoQoS): PROCESS_POWER_THROTTLING_STATE {Version 1, ControlMask EXECUTION_SPEED, StateMask 0}
    call GetCurrentProcess
    movq %rax, %rcx
    movq $4, %rdx
    movq $4294967297, %rax
    movq %rax, 64(%rsp)
    movq $0, 72(%rsp)
    leaq 64(%rsp), %r8
    movq $12, %r9
    call SetProcessInformation
    movq $65001, %rcx
    call SetConsoleOutputCP
    movq $65001, %rcx
    call SetConsoleCP
    movq $65536, 64(%rsp)
    leaq 64(%rsp), %rcx
    call SetThreadStackGuarantee
    movq $1, %rcx
    leaq __win_veh(%rip), %rdx
    call AddVectoredExceptionHandler
# a fork child: drop LUME_FORK, flag ready, wait for the parent to replace this thread's state
    leaq .Lws_fk_var(%rip), %rcx
    leaq 64(%rsp), %rdx
    movq $16, %r8
    call GetEnvironmentVariableA
    testq %rax, %rax
    jz .Lwst_normal
    leaq .Lws_fk_var(%rip), %rcx
    xorq %rdx, %rdx
    call SetEnvironmentVariableA
    movq $1, .Lws_fk_ready(%rip)
.Lwst_fk_wait:
    cmpq $0, .Lws_fk_ready(%rip)
    jne .Lwst_fk_wait
    jmp .Lwst_fk_wait
.Lwst_normal:
# argv: the command line is split here by the rules CommandLineToArgvW applies (no SHELL32 at start-up):
# blanks separate arguments outside quotes; 2n backslashes + '"' -> n backslashes and the quote toggles quoting;
# 2n+1 backslashes + '"' -> n backslashes and a literal '"'; other backslashes are literal; '""' inside quotes is
# a literal '"'. UTF-8 bytes of non-ASCII characters never equal these ASCII bytes, so splitting UTF-8 is exact.
# Block of 4 MiB: pointer array from the start (argv..., 0, envp..., 0), strings from +1 MiB, raw command line at +3 MiB.
    xorq %rcx, %rcx
    movq $4194304, %rdx
    movq $1056768, %r8
    movq $1, %r9
    call VirtualAlloc
    testq %rax, %rax
    jz .Lwst_oom
    movq %rax, %rbx
# reserved only: pages are committed on first touch through the lazy table (the handler is already installed)
    call .Lws_nr_slot
    testq %rax, %rax
    jz .Lwst_argv_commit
    movq %rbx, (%rax)
    leaq 4194304(%rbx), %rcx
    movq %rcx, 8(%rax)
# the three parts every start touches (pointers, strings, raw command line): committed now, 64 KiB each, so an
# ordinary start takes no fault; anything larger commits on first touch
    movq %rbx, %rcx
    movq $65536, %rdx
    movq $4096, %r8
    movq $4, %r9
    call VirtualAlloc
    leaq 1048576(%rbx), %rcx
    movq $65536, %rdx
    movq $4096, %r8
    movq $4, %r9
    call VirtualAlloc
    leaq 3145728(%rbx), %rcx
    movq $65536, %rdx
    movq $4096, %r8
    movq $4, %r9
    call VirtualAlloc
    jmp .Lwst_argv_ready
.Lwst_argv_commit:
    movq %rbx, %rcx
    movq $4194304, %rdx
    movq $4096, %r8
    movq $4, %r9
    call VirtualAlloc
.Lwst_argv_ready:
    movq %rbx, %rax
    movq %rax, %rcx
    movq $4194304, %rdx
    call .Lws_reg_add
    call GetCommandLineW
    movq $65001, %rcx
    xorq %rdx, %rdx
    movq %rax, %r8
    movq $-1, %r9
    leaq 3145728(%rbx), %rax
    movq %rax, 32(%rsp)
    movq $1048576, 40(%rsp)
    movq $0, 48(%rsp)
    movq $0, 56(%rsp)
    call WideCharToMultiByte
    leaq 3145728(%rbx), %rsi
    leaq 1048576(%rbx), %rdi
    movq %rbx, %r14
    xorq %r13, %r13
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lwa_skipws
    movb $0, (%rsi)
.Lwa_skipws:
    movzbq (%rsi), %rax
    testq %rax, %rax
    jz .Lwa_done
    cmpq $32, %rax
    je .Lwa_ws
    cmpq $9, %rax
    jne .Lwa_start
.Lwa_ws:
    incq %rsi
    jmp .Lwa_skipws
.Lwa_start:
    movq %rdi, (%r14)
    addq $8, %r14
    incq %r13
    xorq %r15, %r15
.Lwa_char:
    movzbq (%rsi), %rax
    testq %rax, %rax
    jz .Lwa_endarg
    cmpq $92, %rax
    je .Lwa_bs
    cmpq $34, %rax
    je .Lwa_q
    testq %r15, %r15
    jnz .Lwa_lit
    cmpq $32, %rax
    je .Lwa_endarg
    cmpq $9, %rax
    je .Lwa_endarg
.Lwa_lit:
    movb %al, (%rdi)
    incq %rdi
    incq %rsi
    jmp .Lwa_char
.Lwa_q:
    testq %r15, %r15
    jz .Lwa_qopen
    movzbq 1(%rsi), %rax
    cmpq $34, %rax
    jne .Lwa_qclose
    movb $34, (%rdi)
    incq %rdi
    addq $2, %rsi
    jmp .Lwa_char
.Lwa_qclose:
    xorq %r15, %r15
    incq %rsi
    jmp .Lwa_char
.Lwa_qopen:
    movq $1, %r15
    incq %rsi
    jmp .Lwa_char
.Lwa_bs:
    xorq %rcx, %rcx
.Lwa_bscount:
    movzbq (%rsi,%rcx,1), %rax
    cmpq $92, %rax
    jne .Lwa_bsend
    incq %rcx
    jmp .Lwa_bscount
.Lwa_bsend:
    cmpq $34, %rax
    jne .Lwa_bslit
    addq %rcx, %rsi
    movq %rcx, %r8
    shrq $1, %r8
.Lwa_bshalf:
    testq %r8, %r8
    jz .Lwa_bshalf_done
    movb $92, (%rdi)
    incq %rdi
    decq %r8
    jmp .Lwa_bshalf
.Lwa_bshalf_done:
    andq $1, %rcx
    testq %rcx, %rcx
    jz .Lwa_char
    movb $34, (%rdi)
    incq %rdi
    incq %rsi
    jmp .Lwa_char
.Lwa_bslit:
    addq %rcx, %rsi
.Lwa_bsall:
    testq %rcx, %rcx
    jz .Lwa_char
    movb $92, (%rdi)
    incq %rdi
    decq %rcx
    jmp .Lwa_bsall
.Lwa_endarg:
    movb $0, (%rdi)
    incq %rdi
    movzbq (%rsi), %rax
    testq %rax, %rax
    jz .Lwa_done
    jmp .Lwa_skipws
.Lwa_done:
    movq $0, (%r14)
    addq $8, %r14
# envp: every UTF-16 string of the environment block, as UTF-8, after argv's terminator
    call GetEnvironmentStringsW
    movq %rax, %r12
    testq %r12, %r12
    jz .Lwst_env_done
.Lwst_env_next:
    movzbq (%r12), %rax
    movzbq 1(%r12), %rcx
    addq %rcx, %rax
    testq %rax, %rax
    jz .Lwst_env_done
    movq $65001, %rcx
    xorq %rdx, %rdx
    movq %r12, %r8
    movq $-1, %r9
    movq %rdi, 32(%rsp)
    leaq 3145728(%rbx), %rax
    subq %rdi, %rax
    movq %rax, 40(%rsp)
    movq $0, 48(%rsp)
    movq $0, 56(%rsp)
    call WideCharToMultiByte
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lwst_env_skip
    movq %rdi, (%r14)
    addq $8, %r14
    addq %rax, %rdi
.Lwst_env_skip:
    movzbq (%r12), %rax
    movzbq 1(%r12), %rcx
    addq $2, %r12
    addq %rcx, %rax
    testq %rax, %rax
    jnz .Lwst_env_skip
    jmp .Lwst_env_next
.Lwst_env_done:
    movq $0, (%r14)
# argv[0] in the POSIX view used everywhere else: '\' -> '/', "X:" -> "/x"
    testq %r13, %r13
    jz .Lwst_a0_done
    movq (%rbx), %rcx
.Lwst_a0_sl:
    movzbq (%rcx), %rdx
    testq %rdx, %rdx
    jz .Lwst_a0_drv
    cmpq $92, %rdx
    jne .Lwst_a0_nx
    movb $47, (%rcx)
.Lwst_a0_nx:
    incq %rcx
    jmp .Lwst_a0_sl
.Lwst_a0_drv:
    movq (%rbx), %rcx
    movzbq 1(%rcx), %rax
    cmpq $58, %rax
    jne .Lwst_a0_done
    movzbq (%rcx), %rax
    movq %rax, %rdx
    subq $65, %rdx
    js .Lwst_a0_low
    cmpq $26, %rdx
    jge .Lwst_a0_low
    addq $32, %rax
.Lwst_a0_low:
    movb %al, 1(%rcx)
    movb $47, (%rcx)
.Lwst_a0_done:
    movq %r13, .Lrt_os_argc(%rip)
    movq %rbx, .Lrt_os_argv(%rip)
    leaq -56(%rbp), %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rsi
    popq %rdi
    popq %rbx
    popq %rbp
    ret
.Lwst_oom:
    movq $12, %rcx
    call ExitProcess
# __win_veh: vectored exception handler (Win64 ABI, rcx = EXCEPTION_POINTERS*). Faults go to the same handlers
# the Linux runtime installs: an access violation or a stack overflow to __rt_on_segv with a siginfo whose
# si_addr is the faulting address and a ucontext whose saved rsp is the faulting rsp (so frozen-arena pages are
# paged in and execution resumes, and a stack overflow is the same diagnosed stop); an integer division fault to
# __rt_on_fpe. Anything else is passed on.
__win_veh:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %rdi
    pushq %rsi
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    andq $-16, %rsp
    subq $256, %rsp
    movq (%rcx), %r8
    movq 8(%rcx), %r9
    movq (%r8), %rax
    shlq $32, %rax
    shrq $32, %rax
    movq $3221225620, %rdx
    cmpq %rdx, %rax
    je .Lwv_fpe
    movq $3221225621, %rdx
    cmpq %rdx, %rax
    je .Lwv_fpe
    movq 152(%r9), %r10
    movq $3221225725, %rdx
    cmpq %rdx, %rax
    je .Lwv_stack
    movq $3221225477, %rdx
    cmpq %rdx, %rax
    je .Lwv_av
    movq $3221225622, %rdx
    cmpq %rdx, %rax
    jne .Lwv_pass
    xorq %r11, %r11
    jmp .Lwv_segv
.Lwv_av:
    movq 40(%r8), %r11
# a first touch of a lazily committed reservation: commit its 64 KiB block and retry the instruction
    leaq .Lws_nrt(%rip), %rax
    movq $64, %rcx
.Lwv_nr_l:
    movq (%rax), %rdx
    testq %rdx, %rdx
    jz .Lwv_nr_n
    cmpq %rdx, %r11
    jl .Lwv_nr_n
    cmpq 8(%rax), %r11
    jl .Lwv_nr_hit
.Lwv_nr_n:
    addq $16, %rax
    decq %rcx
    jnz .Lwv_nr_l
    jmp .Lwv_own
.Lwv_nr_hit:
    movq %r11, 200(%rsp)
    movq %r10, 208(%rsp)
    movq %r11, %rcx
    andq $-65536, %rcx
    cmpq %rdx, %rcx
    jge .Lwv_nr_lo
    movq %rdx, %rcx
.Lwv_nr_lo:
    movq %rcx, %rdx
    addq $65536, %rdx
    cmpq 8(%rax), %rdx
    jle .Lwv_nr_hi
    movq 8(%rax), %rdx
.Lwv_nr_hi:
    subq %rcx, %rdx
    movq $4096, %r8
    movq $4, %r9
    call VirtualAlloc
    movq 200(%rsp), %r11
    movq 208(%rsp), %r10
    testq %rax, %rax
    jz .Lwv_segv
    movq $-1, %rax
    jmp .Lwv_out
# an access violation raised outside this image's code (inside a DLL that may handle it) is not ours
.Lwv_own:
    movq 248(%r9), %rax
    movq $4194304, %rdx
    cmpq %rdx, %rax
    jl .Lwv_pass
    leaq __win_image_hi(%rip), %rdx
    cmpq %rdx, %rax
    jge .Lwv_pass
    jmp .Lwv_segv
.Lwv_stack:
    movq %r10, %r11
.Lwv_segv:
    movq %r11, 16(%rsp)
    movq %r10, 192(%rsp)
    movq $11, %rdi
    movq %rsp, %rsi
    leaq 32(%rsp), %rdx
    call __rt_on_segv
    movq $-1, %rax
    jmp .Lwv_out
.Lwv_fpe:
    call __rt_on_fpe
.Lwv_pass:
    xorq %rax, %rax
.Lwv_out:
    leaq -56(%rbp), %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rsi
    popq %rdi
    popq %rbx
    popq %rbp
    ret
__win_image_hi:
    .section .rodata
.Lws_fk_var:
    .asciz "LUME_FORK"
.Lws_fk_one:
    .asciz "1"
.Lws_ws_dll:
    .asciz "ws2_32.dll"
.Lws_ws_names:
    .asciz "WSAStartup"
    .asciz "socket"
    .asciz "connect"
    .asciz "accept"
    .asciz "bind"
    .asciz "listen"
    .asciz "setsockopt"
    .asciz "send"
    .asciz "recv"
    .asciz "sendto"
    .asciz "recvfrom"
    .asciz "shutdown"
    .asciz "closesocket"
    .asciz "WSAGetLastError"
    .byte 0
# Winsock error -> -errno (EWOULDBLOCK, EINTR, EBADF, EACCES, EFAULT, EINVAL, EMFILE, ENOTSOCK, EMSGSIZE,
# EAFNOSUPPORT, EADDRINUSE, EADDRNOTAVAIL, ENETUNREACH, ECONNABORTED, ECONNRESET, ENOTCONN, ETIMEDOUT,
# ECONNREFUSED, EHOSTUNREACH, EISCONN, EALREADY, EINPROGRESS)
.Lws_ws_err:
    .quad 10035
    .quad -11
    .quad 10004
    .quad -4
    .quad 10009
    .quad -9
    .quad 10013
    .quad -13
    .quad 10014
    .quad -14
    .quad 10022
    .quad -22
    .quad 10024
    .quad -24
    .quad 10038
    .quad -88
    .quad 10040
    .quad -90
    .quad 10047
    .quad -97
    .quad 10048
    .quad -98
    .quad 10049
    .quad -99
    .quad 10051
    .quad -101
    .quad 10053
    .quad -103
    .quad 10054
    .quad -104
    .quad 10057
    .quad -107
    .quad 10060
    .quad -110
    .quad 10061
    .quad -111
    .quad 10065
    .quad -113
    .quad 10056
    .quad -106
    .quad 10037
    .quad -114
    .quad 10036
    .quad -115
    .quad 0
    .quad 0
.Lws_un_sys:
    .asciz "Windows_NT"
.Lws_un_mach:
    .asciz "x86_64"
.Lws_urandom:
    .asciz "/dev/urandom"
.Lws_devnull:
    .asciz "/dev/null"
.Lws_tmpdir:
    .asciz "/tmp"
.Lws_devstdout:
    .asciz "/dev/stdout"
.Lws_devstderr:
    .asciz "/dev/stderr"
.Lws_bcrypt_dll:
    .asciz "bcrypt.dll"
.Lws_bcrypt_proc:
    .asciz "BCryptGenRandom"
.Lws_kbase_dll:
    .asciz "kernelbase.dll"
.Lws_mvn2_proc:
    .asciz "MapViewOfFileNuma2"
.Lws_devstdin:
    .asciz "/dev/stdin"
    .section .bss
    .lcomm .Lws_wbuf, 65536
    .lcomm .Lws_nbuf, 1024
    .lcomm .Lws_pbuf, 98304
    .lcomm .Lws_cbuf, 98304
    .lcomm .Lws_cwbuf, 65536
    .lcomm .Lws_fk_mode, 8
    .lcomm .Lws_fk_ctx, 112
    .lcomm .Lws_fk_std, 24
    .lcomm .Lws_fk_open, 64
    .lcomm .Lws_fk_nopen, 8
    .lcomm .Lws_kids, 2560
    .lcomm .Lws_kid_fake, 8
    .lcomm .Lws_timer, 8
    .lcomm .Lws_bcrypt_fn, 8
    .lcomm .Lws_fdt, 16384
    .lcomm .Lws_nrt, 1024
    .lcomm .Lws_ws_ok, 8
    .lcomm .Lws_regs, 16384
    .lcomm .Lws_fk_ready, 8
    .lcomm .Lws_fk_proc, 8
    .lcomm .Lws_fk_thread, 8
    .lcomm .Lws_ctx, 1264
    .lcomm .Lws_ws_fn, 128
    .lcomm .Lws_wsadata, 512
    .lcomm .Lws_envblk, 8
    .lcomm .Lws_envp_arg, 8
    .lcomm .Lws_cpres, 8
    .lcomm .Lws_cperr, 8
    .lcomm .Lws_shm, 1536
    .lcomm .Lws_mvn2_fn, 8
