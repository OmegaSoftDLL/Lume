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
    .extern KERNEL32.dll!SetEndOfFile
    .extern KERNEL32.dll!CreateThread
    .extern KERNEL32.dll!CreateEventW
    .extern KERNEL32.dll!WriteFile
    .extern KERNEL32.dll!CreateJobObjectW
    .extern KERNEL32.dll!AssignProcessToJobObject
    .extern KERNEL32.dll!TerminateJobObject
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
    .extern KERNEL32.dll!LoadLibraryExW
    .extern KERNEL32.dll!GetModuleFileNameA
    .extern KERNEL32.dll!PeekNamedPipe
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
    cmpq $291, %rax
    je .Lws_epcreate
    cmpq $213, %rax
    je .Lws_epcreate
    cmpq $233, %rax
    je .Lws_epctl
    cmpq $232, %rax
    je .Lws_epwait
    cmpq $281, %rax
    je .Lws_epwait
    cmpq $16, %rax
    je .Lws_ioctl
    cmpq $1000, %rax
    je .Lws_dnssrv
    cmpq $1008, %rax
    je .Lws_ipv4if
    cmpq $1010, %rax
    je .Lws_dlsym
    cmpq $1011, %rax
    je .Lws_wcall
    cmpq $1012, %rax
    je .Lws_h2fd
    cmpq $1013, %rax
    je .Lws_fd2h
    cmpq $1014, %rax
    je .Lws_svc_start
    cmpq $1015, %rax
    je .Lws_svc_get
    cmpq $51, %rax
    je .Lws_getsockname
    cmpq $1001, %rax
    je .Lws_kc_put
    cmpq $1002, %rax
    je .Lws_kc_get
    cmpq $1003, %rax
    je .Lws_kc_del
    cmpq $1004, %rax
    je .Lws_kc_avail
    cmpq $1005, %rax
    je .Lws_fip
    cmpq $1006, %rax
    je .Lws_fmode
    cmpq $425, %rax
    je .Lws_ur_setup
    cmpq $426, %rax
    je .Lws_ur_enter
    cmpq $427, %rax
    je .Lws_ur_reg
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
    cmpq $316, %rax
    je .Lws_renameat2
    cmpq $109, %rax
    je .Lws_setpgid
    cmpq $77, %rax
    je .Lws_ftruncate
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
    cmpq $7, %rax
    je .Lws_poll
    cmpq $55, %rax
    je .Lws_getsockopt
    cmpq $72, %rax
    je .Lws_fcntl
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
    je .Lws_path3
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
    xorq %r9, %r9
# O_CREAT with no group or other bits in the mode (0600, 0400, 0700): the new file gets the owner-only DACL
    movq %r13, %rcx
    andq $64, %rcx
    testq %rcx, %rcx
    jz .Lws_open_cf
    movq %r14, %rcx
    andq $63, %rcx
    testq %rcx, %rcx
    jnz .Lws_open_cf
    movq %rdx, 80(%rsp)
    call .Lws_pv_sa_get
    movq 80(%rsp), %rdx
    testq %rax, %rax
    jz .Lws_eacces
    movq %rax, %r9
.Lws_open_cf:
    leaq .Lws_wbuf(%rip), %rcx
    movq $7, %r8
    call CreateFileW
    cmpq $-1, %rax
    je .Lws_open_cffail
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
# ERROR_PATH_NOT_FOUND (see .Lws_path3): Linux says ENOTDIR when the nearest existing component of the path is a file, ENOENT when it
# is a directory; walk .Lws_wbuf back one separator at a time and ask GetFileAttributesW
.Lws_open_cffail:
    call GetLastError
    shlq $32, %rax
    shrq $32, %rax
    jmp .Lws_errmap
# every ERROR_PATH_NOT_FOUND (open, unlink, stat, mkdir...) comes here with the path in .Lws_wbuf
.Lws_path3:
    leaq .Lws_wbuf(%rip), %rdi
.Lws_ocf_end:
    movzbq (%rdi), %rax
    movzbq 1(%rdi), %rdx
    orq %rdx, %rax
    testq %rax, %rax
    jz .Lws_ocf_back
    addq $2, %rdi
    jmp .Lws_ocf_end
.Lws_ocf_back:
    subq $2, %rdi
    leaq .Lws_wbuf(%rip), %rsi
    cmpq %rsi, %rdi
    jle .Lws_ocf_enoent
    movzbq 1(%rdi), %rdx
    testq %rdx, %rdx
    jnz .Lws_ocf_back
    movzbq (%rdi), %rax
    cmpq $92, %rax
    je .Lws_ocf_try
    cmpq $47, %rax
    jne .Lws_ocf_back
.Lws_ocf_try:
    movb $0, (%rdi)
    movq %rdi, 72(%rsp)
    leaq .Lws_wbuf(%rip), %rcx
    call GetFileAttributesW
    shlq $32, %rax
    shrq $32, %rax
    movq 72(%rsp), %rdi
    movq $4294967295, %rcx
    cmpq %rcx, %rax
    je .Lws_ocf_back
    andq $16, %rax
    testq %rax, %rax
    jz .Lws_enotdir
.Lws_ocf_enoent:
    movq $-2, %rax
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
# a closed fd leaves every epoll interest list; a closed epoll fd drops its whole list
    leaq .Lws_ept(%rip), %rax
    movq $256, %rcx
    leaq 1(%r12), %rdx
.Lws_close_ep:
    cmpq %r12, 8(%rax)
    jne .Lws_close_ep_own
    cmpq $0, (%rax)
    jne .Lws_close_ep_drop
.Lws_close_ep_own:
    cmpq %rdx, (%rax)
    jne .Lws_close_ep_n
.Lws_close_ep_drop:
    movq $0, (%rax)
    movq $0, 8(%rax)
    movq $0, 16(%rax)
    movq $0, 24(%rax)
.Lws_close_ep_n:
    addq $32, %rax
    decq %rcx
    jnz .Lws_close_ep
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
# ftruncate(fd, length): SetFilePointerEx to length, SetEndOfFile, then the old position back (Linux leaves it alone)
.Lws_ftruncate:
    call .Lws_fdh
    testq %rcx, %rcx
    jz .Lws_ebadf
    cmpq $3, %rcx
    je .Lws_einval
    cmpq $2, %rcx
    je .Lws_einval
    testq %r13, %r13
    js .Lws_einval
    movq %rax, 72(%rsp)
    movq %rax, %rcx
    xorq %rdx, %rdx
    leaq 64(%rsp), %r8
    movq $1, %r9
    call SetFilePointerEx
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    movq 72(%rsp), %rcx
    movq %r13, %rdx
    xorq %r8, %r8
    xorq %r9, %r9
    call SetFilePointerEx
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    movq 72(%rsp), %rcx
    call SetEndOfFile
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    movq 72(%rsp), %rcx
    movq 64(%rsp), %rdx
    xorq %r8, %r8
    xorq %r9, %r9
    call SetFilePointerEx
    jmp .Lws_zero
# renameat2(AT_FDCWD, old, AT_FDCWD, new, RENAME_NOREPLACE): MoveFileExW with WRITE_THROUGH only, so an existing
# target fails (ERROR_ALREADY_EXISTS -> EEXIST), as renameat2 with RENAME_NOREPLACE does on Linux
.Lws_renameat2:
    movq %r13, %r12
    movq %r15, %r13
    call .Lws_wpath
    testq %rax, %rax
    jz .Lws_fail
    movq %rax, %rcx
    addq %rax, %rcx
    leaq .Lws_wbuf(%rip), %rsi
    leaq .Lws_cwbuf(%rip), %rdi
.Lws_rnx_cp:
    movzbq (%rsi), %rax
    movb %al, (%rdi)
    incq %rsi
    incq %rdi
    decq %rcx
    jnz .Lws_rnx_cp
    movq %r12, 64(%rsp)
    movq %r13, %r12
    call .Lws_wpath
    movq 64(%rsp), %r12
    testq %rax, %rax
    jz .Lws_fail
    leaq .Lws_cwbuf(%rip), %rcx
    leaq .Lws_wbuf(%rip), %rdx
    movq $8, %r8
    call MoveFileExW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
# setpgid(0, 0) between a fork and its execve asks for a new process group: execve then creates the program suspended,
# puts it in a new Job Object and only then resumes it, so nothing it starts escapes; kill(-pid) terminates the job.
# Any other setpgid is accepted and does nothing (a Windows process is never moved between jobs here).
.Lws_setpgid:
    cmpq $0, .Lws_fk_mode(%rip)
    je .Lws_zero
    testq %r12, %r12
    jnz .Lws_zero
    movq $1, .Lws_fk_newgrp(%rip)
    jmp .Lws_zero
# the suspended process of execve (224(%rsp) process, 232 thread, 240 pid in the caller's frame): a new job, the process
# in it, the thread resumed; (pid, job) kept in a 64-entry ring (the job handle it replaces is closed)
.Lws_job_attach:
    subq $56, %rsp
    xorq %rcx, %rcx
    xorq %rdx, %rdx
    call CreateJobObjectW
    movq %rax, 32(%rsp)
    testq %rax, %rax
    jz .Lws_ja_resume
    movq %rax, %rcx
    movq 288(%rsp), %rdx
    call AssignProcessToJobObject
    movq .Lws_jobs_next(%rip), %rax
    andq $63, %rax
    shlq $4, %rax
    leaq .Lws_jobs(%rip), %rcx
    addq %rax, %rcx
    movq %rcx, 40(%rsp)
    movq 8(%rcx), %rcx
    testq %rcx, %rcx
    jz .Lws_ja_store
    call CloseHandle
.Lws_ja_store:
    movq 40(%rsp), %rcx
    movq 304(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    movq %rax, (%rcx)
    movq 32(%rsp), %rax
    movq %rax, 8(%rcx)
    incq .Lws_jobs_next(%rip)
.Lws_ja_resume:
    movq 296(%rsp), %rcx
    call ResumeThread
    movq $0, .Lws_fk_newgrp(%rip)
    addq $56, %rsp
    ret
# kill(-pid, sig): TerminateJobObject on the job of pid (exit code 128 + sig), when there is one; r12 = pid, r13 = sig
.Lws_job_kill:
    subq $40, %rsp
    leaq .Lws_jobs(%rip), %rax
    movq $64, %rcx
.Lws_jk_find:
    cmpq %r12, (%rax)
    je .Lws_jk_have
    addq $16, %rax
    decq %rcx
    jnz .Lws_jk_find
    addq $40, %rsp
    ret
.Lws_jk_have:
    movq 8(%rax), %rcx
    testq %rcx, %rcx
    jz .Lws_jk_out
    testq %r13, %r13
    jz .Lws_jk_out
    movq %r13, %rdx
    addq $128, %rdx
    call TerminateJobObject
.Lws_jk_out:
    addq $40, %rsp
    ret
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
# ---- epoll: an epoll fd (kind 6) and its interest list in .Lws_ept (32-byte entries: epfd + 1 (0 = free), fd,
# events, data). epoll_wait is level-triggered, as the Linux default: a pipe is readable when PeekNamedPipe reports
# bytes or a closed writer (EPOLLIN | EPOLLHUP), a socket by WSAPoll, a file or console is always ready; every
# kind but a socket is always writable. Until something is ready it waits 0.2 ms at a time on the high-resolution
# timer, up to the timeout (ms; -1 = no limit). struct epoll_event is packed: u32 events, u64 data.
.Lws_epcreate:
    movq $6, %r8
    xorq %r9, %r9
    call .Lws_fd_new
    jmp .Lws_ret
.Lws_epctl:
    call .Lws_fdh
    cmpq $6, %rcx
    jne .Lws_einval
    movq %r12, 64(%rsp)
    movq %r14, %r12
    call .Lws_fdh
    movq 64(%rsp), %r12
    testq %rcx, %rcx
    jz .Lws_ebadf
    leaq 1(%r12), %rdx
# find (epfd, fd)
    leaq .Lws_ept(%rip), %rax
    movq $256, %rcx
.Lws_epc_f:
    cmpq %rdx, (%rax)
    jne .Lws_epc_fn
    cmpq %r14, 8(%rax)
    je .Lws_epc_hit
.Lws_epc_fn:
    addq $32, %rax
    decq %rcx
    jnz .Lws_epc_f
# not in the list: ADD takes a free entry, DEL / MOD fail with ENOENT
    cmpq $1, %r13
    jne .Lws_epc_noent
    leaq .Lws_ept(%rip), %rax
    movq $256, %rcx
.Lws_epc_free:
    cmpq $0, (%rax)
    je .Lws_epc_put
    addq $32, %rax
    decq %rcx
    jnz .Lws_epc_free
    movq $-28, %rax
    jmp .Lws_ret
.Lws_epc_put:
    movq %rdx, (%rax)
    movq %r14, 8(%rax)
.Lws_epc_set:
    movq (%r15), %rcx
    shlq $32, %rcx
    shrq $32, %rcx
    movq %rcx, 16(%rax)
    movq 4(%r15), %rcx
    movq %rcx, 24(%rax)
    jmp .Lws_zero
.Lws_epc_hit:
    cmpq $1, %r13
    je .Lws_epc_exist
    cmpq $3, %r13
    je .Lws_epc_set
    cmpq $2, %r13
    jne .Lws_einval
    movq $0, (%rax)
    movq $0, 8(%rax)
    movq $0, 16(%rax)
    movq $0, 24(%rax)
    jmp .Lws_zero
.Lws_epc_exist:
    movq $-17, %rax
    jmp .Lws_ret
.Lws_epc_noent:
    movq $-2, %rax
    jmp .Lws_ret
.Lws_epwait:
    call .Lws_fdh
    cmpq $6, %rcx
    jne .Lws_einval
    testq %r14, %r14
    jle .Lws_einval
    leaq 96(%rsp), %rcx
    call QueryPerformanceFrequency
    leaq 104(%rsp), %rcx
    call QueryPerformanceCounter
.Lws_epw_loop:
# scan: rsi = entry, rdi = events written
    leaq .Lws_ept(%rip), %rsi
    xorq %rdi, %rdi
    movq $256, %rbx
.Lws_epw_scan:
    leaq 1(%r12), %rax
    cmpq %rax, (%rsi)
    jne .Lws_epw_next
    movq %r12, 112(%rsp)
    movq 8(%rsi), %r12
    call .Lws_fdh
    movq 112(%rsp), %r12
    movq $0, 120(%rsp)
    cmpq $5, %rcx
    je .Lws_epw_sock
    testq %rcx, %rcx
    jz .Lws_epw_hup
    cmpq $1, %rcx
    je .Lws_epw_pipe
    cmpq $4, %rcx
    je .Lws_epw_pipe
# any other kind (directory stream, /dev/urandom, an epoll fd): readable and writable
    movq $5, 120(%rsp)
    jmp .Lws_epw_mask
.Lws_epw_pipe:
    movq $4, 120(%rsp)
    movq %rax, %rcx
    xorq %rdx, %rdx
    xorq %r8, %r8
    xorq %r9, %r9
    movq $0, 128(%rsp)
    leaq 128(%rsp), %rax
    movq %rax, 32(%rsp)
    movq $0, 40(%rsp)
    call PeekNamedPipe
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_epw_pipe_err
    cmpq $0, 128(%rsp)
    je .Lws_epw_mask
    movq 120(%rsp), %rdx
    orq $1, %rdx
    movq %rdx, 120(%rsp)
    jmp .Lws_epw_mask
.Lws_epw_pipe_err:
    call GetLastError
    shlq $32, %rax
    shrq $32, %rax
    cmpq $109, %rax
    jne .Lws_epw_file
    movq 120(%rsp), %rdx
    orq $17, %rdx
    movq %rdx, 120(%rsp)
    jmp .Lws_epw_mask
.Lws_epw_file:
    movq 120(%rsp), %rdx
    orq $1, %rdx
    movq %rdx, 120(%rsp)
    jmp .Lws_epw_mask
.Lws_epw_hup:
    movq $16, 120(%rsp)
    jmp .Lws_epw_mask
.Lws_epw_sock:
# WSAPOLLFD { SOCKET, short events = POLLRDNORM | POLLWRNORM, short revents }
    movq %rax, 128(%rsp)
    movq $272, 136(%rsp)
    leaq 128(%rsp), %rcx
    movq $1, %rdx
    xorq %r8, %r8
    movq .Lws_ws_fn+112(%rip), %rax
    call *%rax
    movq 136(%rsp), %rax
    shrq $16, %rax
    andq $65535, %rax
    testq $256, %rax
    jz .Lws_epw_s1
    movq 120(%rsp), %rdx
    orq $1, %rdx
    movq %rdx, 120(%rsp)
.Lws_epw_s1:
    testq $16, %rax
    jz .Lws_epw_s2
    movq 120(%rsp), %rdx
    orq $4, %rdx
    movq %rdx, 120(%rsp)
.Lws_epw_s2:
    testq $2, %rax
    jz .Lws_epw_s3
    movq 120(%rsp), %rdx
    orq $17, %rdx
    movq %rdx, 120(%rsp)
.Lws_epw_s3:
    testq $1, %rax
    jz .Lws_epw_mask
    movq 120(%rsp), %rdx
    orq $9, %rdx
    movq %rdx, 120(%rsp)
.Lws_epw_mask:
# requested events, plus EPOLLERR and EPOLLHUP, which are always reported
    movq 16(%rsi), %rax
    orq $24, %rax
    andq 120(%rsp), %rax
    testq %rax, %rax
    jz .Lws_epw_next
    movq %rdi, %rcx
    imulq $12, %rcx
    addq %r13, %rcx
    movq %rax, (%rcx)
    movq 24(%rsi), %rax
    movq %rax, 4(%rcx)
    incq %rdi
    cmpq %r14, %rdi
    jge .Lws_epw_done
.Lws_epw_next:
    addq $32, %rsi
    decq %rbx
    jnz .Lws_epw_scan
    testq %rdi, %rdi
    jnz .Lws_epw_done
    testq %r15, %r15
    jz .Lws_epw_done
    js .Lws_epw_sleep
    leaq 112(%rsp), %rcx
    call QueryPerformanceCounter
    movq 112(%rsp), %rax
    subq 104(%rsp), %rax
    imulq $1000, %rax
    cqto
    idivq 96(%rsp)
    cmpq %r15, %rax
    jge .Lws_epw_done
.Lws_epw_sleep:
    movq $-2000, 80(%rsp)
    movq .Lws_timer(%rip), %rax
    testq %rax, %rax
    jnz .Lws_epw_tset
    xorq %rcx, %rcx
    xorq %rdx, %rdx
    movq $2, %r8
    movq $2031619, %r9
    call CreateWaitableTimerExW
    movq %rax, .Lws_timer(%rip)
    testq %rax, %rax
    jnz .Lws_epw_tset
    movq $1, %rcx
    call Sleep
    jmp .Lws_epw_loop
.Lws_epw_tset:
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
    jmp .Lws_epw_loop
.Lws_epw_done:
    movq %rdi, %rax
    jmp .Lws_ret
# ---- IP helper (iphlpapi.dll, System32, loaded on first use): GetAdaptersAddresses, if_nametoindex,
# ConvertInterfaceAliasToLuid, ConvertInterfaceLuidToIndex in .Lws_iph_fn; rax = 1 when loaded. Keeps rsi, rdi, rbx.
.Lws_iph_load:
    cmpq $0, .Lws_iph_fn+24(%rip)
    jne .Lws_iph_yes
    pushq %rsi
    pushq %rdi
    pushq %rbx
    subq $32, %rsp
    leaq .Lws_iph_dll(%rip), %rcx
    xorq %rdx, %rdx
    movq $2048, %r8
    call LoadLibraryExA
    testq %rax, %rax
    jz .Lws_iph_no
    movq %rax, %rbx
    leaq .Lws_iph_names(%rip), %rsi
    leaq .Lws_iph_fn(%rip), %rdi
.Lws_iph_l:
    movzbq (%rsi), %rax
    testq %rax, %rax
    jz .Lws_iph_done
    movq %rbx, %rcx
    movq %rsi, %rdx
    call GetProcAddress
    testq %rax, %rax
    jz .Lws_iph_no
    movq %rax, (%rdi)
    addq $8, %rdi
.Lws_iph_skip:
    incq %rsi
    movzbq -1(%rsi), %rax
    testq %rax, %rax
    jnz .Lws_iph_skip
    jmp .Lws_iph_l
.Lws_iph_done:
    addq $32, %rsp
    popq %rbx
    popq %rdi
    popq %rsi
.Lws_iph_yes:
    movq $1, %rax
    ret
.Lws_iph_no:
    movq $0, .Lws_iph_fn+24(%rip)
    addq $32, %rsp
    popq %rbx
    popq %rdi
    popq %rsi
    xorq %rax, %rax
    ret
# ioctl(fd, SIOCGIFINDEX, struct ifreq *): the index of the interface named in ifr_name (16 bytes) into ifr_ifindex
# (offset 16): the interface name (if_nametoindex), else the friendly name ("Ethernet", "Wi-Fi"); ENODEV when none.
# Any other request: ENOTTY.
.Lws_ioctl:
    cmpq $35123, %r13
    jne .Lws_enotty
    call .Lws_iph_load
    testq %rax, %rax
    jz .Lws_enosys
    movq %r14, %rcx
    movq .Lws_iph_fn+8(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_ioc_put
    movq $65001, %rcx
    xorq %rdx, %rdx
    movq %r14, %r8
    movq $-1, %r9
    leaq .Lws_wbuf(%rip), %rax
    movq %rax, 32(%rsp)
    movq $64, 40(%rsp)
    call MultiByteToWideChar
    testq %rax, %rax
    jz .Lws_enodev
    leaq .Lws_wbuf(%rip), %rcx
    leaq 80(%rsp), %rdx
    movq .Lws_iph_fn+16(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_enodev
    movq $0, 88(%rsp)
    leaq 80(%rsp), %rcx
    leaq 88(%rsp), %rdx
    movq .Lws_iph_fn+24(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_enodev
    movq 88(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_enodev
.Lws_ioc_put:
    movq %rax, 16(%r14)
    jmp .Lws_zero
.Lws_enotty:
    movq $-25, %rax
    jmp .Lws_ret
# pseudo system call 1000 (no Linux system call has this number: there it is ENOSYS): the DNS servers of the
# adapters that are up, as "nameserver <address>\n" lines (resolv.conf form) into buf r12 of r13 bytes; rax = the
# length. The addresses come from GetAdaptersAddresses, written by WSAAddressToStringA (IPv6 with %zone).
.Lws_dnssrv:
    call .Lws_iph_load
    testq %rax, %rax
    jz .Lws_enosys
    call .Lws_ws_init
    testq %rax, %rax
    jz .Lws_enosys
    movq $65536, 80(%rsp)
    xorq %rcx, %rcx
    movq $7, %rdx
    xorq %r8, %r8
    leaq .Lws_gaa(%rip), %r9
    leaq 80(%rsp), %rax
    movq %rax, 32(%rsp)
    movq .Lws_iph_fn(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_zero
    leaq .Lws_gaa(%rip), %rsi
    xorq %rdi, %rdi
.Lws_dns_ad:
    testq %rsi, %rsi
    jz .Lws_dns_done
    movq 104(%rsi), %rax
    shlq $32, %rax
    shrq $32, %rax
    cmpq $1, %rax
    jne .Lws_dns_adn
    movq 48(%rsi), %rbx
.Lws_dns_srv:
    testq %rbx, %rbx
    jz .Lws_dns_adn
    movq 16(%rbx), %rcx
    movq 24(%rbx), %rdx
    shlq $32, %rdx
    shrq $32, %rdx
    xorq %r8, %r8
    leaq .Lws_nbuf(%rip), %r9
    movq $256, 88(%rsp)
    leaq 88(%rsp), %rax
    movq %rax, 32(%rsp)
    movq .Lws_ws_fn+120(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_dns_srvn
    movq 88(%rsp), %r10
    shlq $32, %r10
    shrq $32, %r10
    decq %r10
    jle .Lws_dns_srvn
    movq %rdi, %rax
    addq %r10, %rax
    addq $12, %rax
    cmpq %r13, %rax
    jg .Lws_dns_done
    leaq .Lws_ns_pfx(%rip), %rax
.Lws_dns_p:
    movzbq (%rax), %rcx
    testq %rcx, %rcx
    jz .Lws_dns_pd
    movb %cl, (%r12,%rdi)
    incq %rdi
    incq %rax
    jmp .Lws_dns_p
.Lws_dns_pd:
    leaq .Lws_nbuf(%rip), %rax
    xorq %r11, %r11
.Lws_dns_a:
    cmpq %r10, %r11
    jge .Lws_dns_ad2
    movzbq (%rax,%r11), %rcx
    movb %cl, (%r12,%rdi)
    incq %rdi
    incq %r11
    jmp .Lws_dns_a
.Lws_dns_ad2:
    movb $10, (%r12,%rdi)
    incq %rdi
.Lws_dns_srvn:
    movq 8(%rbx), %rbx
    jmp .Lws_dns_srv
.Lws_dns_adn:
    movq 8(%rsi), %rsi
    jmp .Lws_dns_ad
.Lws_dns_done:
    movq %rdi, %rax
    jmp .Lws_ret
# ---- io_uring through its three system calls. Lume programs do not map the rings (no builtin maps an fd), so the
# queues are always empty: setup validates and returns an io_uring fd (kind 7) with sq_entries / cq_entries filled,
# enter submits nothing (0) and waits for ever when asked for completions, register answers as Linux 6.18 does for
# the NULL argument the builtin passes (.Lws_ur_tab: errno for nr_args 0 and >= 1; 255 = a new personality id).
.Lws_ur_setup:
    testq %r12, %r12
    jz .Lws_einval
    cmpq $32768, %r12
    jg .Lws_einval
    movq 8(%r13), %rax
    shlq $32, %rax
    shrq $49, %rax
    testq %rax, %rax
    jnz .Lws_einval
    movq $1, %rcx
.Lws_urs_p2:
    cmpq %r12, %rcx
    jge .Lws_urs_fill
    shlq $1, %rcx
    jmp .Lws_urs_p2
.Lws_urs_fill:
    movq %rcx, %rax
    shlq $33, %rax
    orq %rcx, %rax
    movq %rax, (%r13)
    movq $7, %r8
    xorq %r9, %r9
    call .Lws_fd_new
    jmp .Lws_ret
.Lws_ur_enter:
    call .Lws_fdh
    testq %rcx, %rcx
    jz .Lws_ebadf
    cmpq $7, %rcx
    jne .Lws_ur_notsup
    movq %r15, %rax
    andq $1, %rax
    jz .Lws_zero
    testq %r14, %r14
    jle .Lws_zero
    movq $4294967295, %rcx
    call Sleep
    jmp .Lws_zero
.Lws_ur_reg:
    call .Lws_fdh
    testq %rcx, %rcx
    jz .Lws_ebadf
    cmpq $7, %rcx
    jne .Lws_ur_notsup
    testq %r13, %r13
    js .Lws_einval
    cmpq $40, %r13
    jg .Lws_einval
    movq %r13, %rcx
    shlq $1, %rcx
    testq %r15, %r15
    jz .Lws_urr_c0
    incq %rcx
.Lws_urr_c0:
    leaq .Lws_ur_tab(%rip), %rax
    addq %rcx, %rax
    movzbq (%rax), %rax
    cmpq $255, %rax
    je .Lws_urr_pers
    negq %rax
    jmp .Lws_ret
.Lws_urr_pers:
    incq .Lws_ur_pers(%rip)
    movq .Lws_ur_pers(%rip), %rax
    jmp .Lws_ret
.Lws_ur_notsup:
    movq $-95, %rax
    jmp .Lws_ret
# ---- extern "c" functions: bound on first call, like the lazy binding of the Linux loader -------------------------
# __win_ffi_resolve: rdi = symbol name (NUL-terminated). Looks the symbol up in each library of __lume_ffi_libs
# (paths separated by ';', written there by `lume build --link`; "@..." = no library) and returns its address in
# rax. A symbol no library exports ends the process as ld.so does: "<exe>: symbol lookup error: <exe>: undefined
# symbol: <name>" on stderr, exit status 127. Keeps rbx, rsi, rdi, rbp, r12-r15.
__win_ffi_resolve:
    pushq %rbx
    pushq %rsi
    pushq %rdi
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %rbp
    movq %rsp, %rbp
    andq $-16, %rsp
    subq $64, %rsp
    movq %rdi, %r13
    leaq __lume_ffi_libs(%rip), %r14
    movzbq (%r14), %rax
    cmpq $64, %rax
    je .Lffr_none
.Lffr_next:
    movzbq (%r14), %rax
    testq %rax, %rax
    jz .Lffr_none
    leaq .Lws_cbuf(%rip), %rdi
.Lffr_cp:
    movzbq (%r14), %rax
    testq %rax, %rax
    jz .Lffr_cp_end
    incq %r14
    cmpq $59, %rax
    je .Lffr_cp_end
    movb %al, (%rdi)
    incq %rdi
    jmp .Lffr_cp
.Lffr_cp_end:
    movb $0, (%rdi)
    leaq .Lws_cbuf(%rip), %r12
    call .Lws_wpath
    testq %rax, %rax
    jz .Lffr_next
# LoadLibraryExW wants '\' separators
    leaq .Lws_wbuf(%rip), %rax
.Lffr_sl:
    movzbq (%rax), %rcx
    movzbq 1(%rax), %rdx
    movq %rcx, %r8
    orq %rdx, %r8
    jz .Lffr_load
    cmpq $47, %rcx
    jne .Lffr_sl_n
    testq %rdx, %rdx
    jnz .Lffr_sl_n
    movb $92, (%rax)
.Lffr_sl_n:
    addq $2, %rax
    jmp .Lffr_sl
.Lffr_load:
    leaq .Lws_wbuf(%rip), %rcx
    xorq %rdx, %rdx
    xorq %r8, %r8
    call LoadLibraryExW
    testq %rax, %rax
    jz .Lffr_next
    movq %rax, %rcx
    movq %r13, %rdx
    call GetProcAddress
    testq %rax, %rax
    jz .Lffr_next
    movq %rbp, %rsp
    popq %rbp
    popq %r14
    popq %r13
    popq %r12
    popq %rdi
    popq %rsi
    popq %rbx
    ret
.Lffr_none:
    xorq %rcx, %rcx
    leaq .Lws_cbuf(%rip), %rdx
    movq $32768, %r8
    call GetModuleFileNameA
    leaq .Lws_pbuf(%rip), %rdi
    leaq .Lws_cbuf(%rip), %rsi
    call .Lffr_cat
    leaq .Lffr_m1(%rip), %rsi
    call .Lffr_cat
    leaq .Lws_cbuf(%rip), %rsi
    call .Lffr_cat
    leaq .Lffr_m2(%rip), %rsi
    call .Lffr_cat
    movq %r13, %rsi
    call .Lffr_cat
    movb $10, (%rdi)
    incq %rdi
    leaq .Lws_pbuf(%rip), %rax
    subq %rax, %rdi
    movq %rdi, %rbx
    movq $-12, %rcx
    call GetStdHandle
    movq %rax, %rcx
    leaq .Lws_pbuf(%rip), %rdx
    movq %rbx, %r8
    leaq 48(%rsp), %r9
    movq $0, 32(%rsp)
    call WriteFile
    movq $127, %rcx
    call ExitProcess
# copy the NUL-terminated string at rsi to rdi (without its NUL); rdi ends past the copy
.Lffr_cat:
    movzbq (%rsi), %rax
    testq %rax, %rax
    jz .Lffr_cat_out
    movb %al, (%rdi)
    incq %rsi
    incq %rdi
    jmp .Lffr_cat
.Lffr_cat_out:
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
    xorq %rdx, %rdx
    movq %r13, %rcx
    andq $63, %rcx
    testq %rcx, %rcx
    jnz .Lws_mkdir_go
    call .Lws_pv_sa_get
    testq %rax, %rax
    jz .Lws_eacces
    movq %rax, %rdx
.Lws_mkdir_go:
    leaq .Lws_wbuf(%rip), %rcx
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
    je .Lws_chmod_acl
    leaq .Lws_wbuf(%rip), %rcx
    call SetFileAttributesW
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
.Lws_chmod_acl:
    movq %r13, %rcx
    andq $63, %rcx
    testq %rcx, %rcx
    jnz .Lws_chmod_open
    call .Lws_pv_sa_get
    testq %rax, %rax
    jz .Lws_eacces
    leaq .Lws_wbuf(%rip), %rcx
# DACL | PROTECTED_DACL security information: no inherited entry stays (the owner always may set the DACL; changing
# the owner needs WRITE_OWNER, which a user's own file in a shared tree does not grant)
    movq $2147483652, %rdx
    leaq .Lws_pv_sd(%rip), %r8
    movq .Lws_av_fn+64(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    jmp .Lws_zero
# group or other bits asked: the object stops being private. SetNamedSecurityInfoW(path, SE_FILE_OBJECT,
# DACL | UNPROTECTED_DACL, 0, 0, empty ACL, 0) drops the explicit entries and the protection, and Windows applies the
# entries inherited from the parent folder again (SetFileSecurityW would leave an empty DACL: no access at all).
# advapi32!SetNamedSecurityInfoW is resolved on first use.
.Lws_chmod_open:
    cmpq $0, .Lws_sns_fn(%rip)
    jne .Lws_cho_have
    leaq .Lws_adv_dll(%rip), %rcx
    xorq %rdx, %rdx
    movq $2048, %r8
    call LoadLibraryExA
    testq %rax, %rax
    jz .Lws_eacces
    movq %rax, %rcx
    leaq .Lws_adv_snsi(%rip), %rdx
    call GetProcAddress
    movq %rax, .Lws_sns_fn(%rip)
    testq %rax, %rax
    jz .Lws_eacces
.Lws_cho_have:
    leaq .Lws_empty_acl(%rip), %rax
    movq $524290, (%rax)
    leaq .Lws_wbuf(%rip), %rcx
    movq $1, %rdx
    movq $536870916, %r8
    xorq %r9, %r9
    movq $0, 32(%rsp)
    leaq .Lws_empty_acl(%rip), %rax
    movq %rax, 40(%rsp)
    movq $0, 48(%rsp)
    movq .Lws_sns_fn(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_zero
    jmp .Lws_errmap
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
# socket(family, type, proto): AF_INET (2) as it is, AF_INET6 (10 on Linux) is Winsock's 23. An IPv6 socket accepts
# IPv4-mapped peers (IPV6_V6ONLY off, the Linux default); a datagram socket ignores ICMP port-unreachable on recv
# (SIO_UDP_CONNRESET off: Linux does not fail the next recvfrom because of it)
.Lws_socket:
    call .Lws_ws_init
    testq %rax, %rax
    jz .Lws_enosys
    movq $2, %rcx
    cmpq $2, %r12
    je .Lws_sock_fam
    movq $23, %rcx
    cmpq $10, %r12
    jne .Lws_eafnosupport
.Lws_sock_fam:
    movq %r13, %rdx
    andq $15, %rdx
    movq %r14, %r8
    movq .Lws_ws_fn+8(%rip), %rax
    call *%rax
    cmpq $-1, %rax
    je .Lws_ws_fail
    movq %rax, 64(%rsp)
    cmpq $10, %r12
    jne .Lws_sock_v6done
    movq $0, 80(%rsp)
    movq %rax, %rcx
    movq $41, %rdx
    movq $27, %r8
    leaq 80(%rsp), %r9
    movq $4, 32(%rsp)
    movq .Lws_ws_fn+48(%rip), %rax
    call *%rax
.Lws_sock_v6done:
    movq %r13, %rax
    andq $15, %rax
    cmpq $2, %rax
    jne .Lws_sock_udpdone
    movq $0, 80(%rsp)
    movq 64(%rsp), %rcx
    movq %rcx, 104(%rsp)
    movq $2550136844, %rdx
    leaq 80(%rsp), %r8
    movq $4, %r9
    movq $0, 32(%rsp)
    movq $0, 40(%rsp)
    leaq 96(%rsp), %rax
    movq %rax, 48(%rsp)
    movq $0, 56(%rsp)
    movq $0, 64(%rsp)
    movq .Lws_ws_fn+128(%rip), %rax
    call *%rax
    movq 104(%rsp), %rax
    movq %rax, 64(%rsp)
.Lws_sock_udpdone:
    movq 64(%rsp), %rax
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
.Lws_eacces:
    movq $-13, %rax
    jmp .Lws_ret
# load advapi32.dll and its functions once: rax = 1, or 0 when it is not available. Entered by call; keeps rbx, rsi, rdi.
.Lws_av_init:
    cmpq $0, .Lws_av_ok(%rip)
    jne .Lws_avi_yes
    pushq %rbx
    pushq %rsi
    pushq %rdi
    subq $32, %rsp
    leaq .Lws_av_dll(%rip), %rcx
    xorq %rdx, %rdx
    movq $2048, %r8
    call LoadLibraryExA
    testq %rax, %rax
    jz .Lws_avi_no
    movq %rax, %rbx
    leaq .Lws_av_names(%rip), %rsi
    leaq .Lws_av_fn(%rip), %rdi
.Lws_avi_l:
    cmpb $0, (%rsi)
    je .Lws_avi_done
    movq %rbx, %rcx
    movq %rsi, %rdx
    call GetProcAddress
    testq %rax, %rax
    jz .Lws_avi_no
    movq %rax, (%rdi)
    addq $8, %rdi
.Lws_avi_skip:
    incq %rsi
    cmpb $0, -1(%rsi)
    jne .Lws_avi_skip
    jmp .Lws_avi_l
.Lws_avi_done:
    movq $1, .Lws_av_ok(%rip)
    addq $32, %rsp
    popq %rdi
    popq %rsi
    popq %rbx
.Lws_avi_yes:
    movq $1, %rax
    ret
.Lws_avi_no:
    addq $32, %rsp
    popq %rdi
    popq %rsi
    popq %rbx
    xorq %rax, %rax
    ret
# the owner-only SECURITY_ATTRIBUTES, built once: owner = the token's user, a protected DACL with one entry that grants
# that user FILE_ALL_ACCESS (inherited by files and directories made inside). rax = its address, or 0.
# Entered by call; keeps rbx, rsi, rdi.
.Lws_pv_sa_get:
    cmpq $0, .Lws_pv_ok(%rip)
    jne .Lws_pvs_yes
    pushq %rbx
    pushq %rsi
    pushq %rdi
    subq $64, %rsp
    call .Lws_av_init
    testq %rax, %rax
    jz .Lws_pvs_no
    call GetCurrentProcess
    movq %rax, %rcx
    movq $8, %rdx
    leaq 48(%rsp), %r8
    movq .Lws_av_fn(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_pvs_no
    movq 48(%rsp), %rcx
    movq $1, %rdx
    leaq .Lws_pv_tok(%rip), %r8
    movq $256, %r9
    leaq 56(%rsp), %rax
    movq %rax, 32(%rsp)
    movq .Lws_av_fn+8(%rip), %rax
    call *%rax
    movq %rax, %rbx
    movq 48(%rsp), %rcx
    call CloseHandle
    shlq $32, %rbx
    shrq $32, %rbx
    testq %rbx, %rbx
    jz .Lws_pvs_no
    leaq .Lws_pv_acl(%rip), %rcx
    movq $256, %rdx
    movq $2, %r8
    movq .Lws_av_fn+16(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_pvs_no
    leaq .Lws_pv_acl(%rip), %rcx
    movq $2, %rdx
    movq $3, %r8
    movq $2032127, %r9
    movq .Lws_pv_tok(%rip), %rax
    movq %rax, 32(%rsp)
    movq .Lws_av_fn+24(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_pvs_no
    leaq .Lws_pv_sd(%rip), %rcx
    movq $1, %rdx
    movq .Lws_av_fn+32(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_pvs_no
    leaq .Lws_pv_sd(%rip), %rcx
    movq $1, %rdx
    leaq .Lws_pv_acl(%rip), %r8
    xorq %r9, %r9
    movq .Lws_av_fn+40(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_pvs_no
    leaq .Lws_pv_sd(%rip), %rcx
    movq .Lws_pv_tok(%rip), %rdx
    xorq %r8, %r8
    movq .Lws_av_fn+48(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_pvs_no
    leaq .Lws_pv_sd(%rip), %rcx
    movq $4096, %rdx
    movq $4096, %r8
    movq .Lws_av_fn+56(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_pvs_no
    leaq .Lws_pv_sa(%rip), %rax
    movq $24, %rcx
    movq %rcx, (%rax)
    leaq .Lws_pv_sd(%rip), %rcx
    movq %rcx, 8(%rax)
    xorq %rcx, %rcx
    movq %rcx, 16(%rax)
    movq $1, .Lws_pv_ok(%rip)
    addq $64, %rsp
    popq %rdi
    popq %rsi
    popq %rbx
.Lws_pvs_yes:
    leaq .Lws_pv_sa(%rip), %rax
    ret
.Lws_pvs_no:
    addq $64, %rsp
    popq %rdi
    popq %rsi
    popq %rbx
    xorq %rax, %rax
    ret
# r12 (UTF-8 target name) -> .Lws_cwbuf (UTF-16): rax = characters written, 0 on failure. Entered by call.
.Lws_kc_wide:
    pushq %rbx
    pushq %rsi
    pushq %rdi
    subq $64, %rsp
    movq $65001, %rcx
    xorq %rdx, %rdx
    movq %r12, %r8
    movq $-1, %r9
    leaq .Lws_cwbuf(%rip), %rax
    movq %rax, 32(%rsp)
    movq $32767, %rax
    movq %rax, 40(%rsp)
    call MultiByteToWideChar
    shlq $32, %rax
    shrq $32, %rax
    addq $64, %rsp
    popq %rdi
    popq %rsi
    popq %rbx
    ret
# a failed Cred* call: ERROR_NOT_FOUND (1168) -> -ENOENT, anything else -> -EIO
# a Credential Manager failure: ERROR_NOT_FOUND (1168) is -2 (ENOENT); any other error code e is -(100000 + e), so the
# Lume side (keychain.src) can tell "absent" from "denied", "no session", "bad data" and never reports one as another
.Lws_kc_err:
    call GetLastError
    shlq $32, %rax
    shrq $32, %rax
    cmpq $1168, %rax
    jne .Lws_kc_err2
    movq $-2, %rax
    jmp .Lws_ret
.Lws_kc_err2:
    addq $100000, %rax
    negq %rax
    jmp .Lws_ret
# 1004: 0 when the Credential Manager can be used
.Lws_kc_avail:
    call .Lws_av_init
    testq %rax, %rax
    jz .Lws_enosys
    jmp .Lws_zero
# 1001 (target, blob, len): CredWriteW of a generic credential that persists on this machine for this user
.Lws_kc_put:
    call .Lws_av_init
    testq %rax, %rax
    jz .Lws_enosys
    cmpq $2560, %r14
    jg .Lws_einval
    cmpq $0, %r14
    jl .Lws_einval
    call .Lws_kc_wide
    testq %rax, %rax
    jz .Lws_einval
    movq $4294967296, %rax
    movq %rax, 96(%rsp)
    leaq .Lws_cwbuf(%rip), %rax
    movq %rax, 104(%rsp)
    xorq %rax, %rax
    movq %rax, 112(%rsp)
    movq %rax, 120(%rsp)
    movq %r14, 128(%rsp)
    movq %r13, 136(%rsp)
    movq $2, %rax
    movq %rax, 144(%rsp)
    xorq %rax, %rax
    movq %rax, 152(%rsp)
    movq %rax, 160(%rsp)
    movq %rax, 168(%rsp)
    leaq 96(%rsp), %rcx
    xorq %rdx, %rdx
    movq .Lws_av_fn+72(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_kc_err
    jmp .Lws_zero
# 1002 (target, out, cap): CredReadW, the blob copied to out: rax = its length, -ENOENT, -ERANGE
.Lws_kc_get:
    call .Lws_av_init
    testq %rax, %rax
    jz .Lws_enosys
    call .Lws_kc_wide
    testq %rax, %rax
    jz .Lws_einval
    leaq .Lws_cwbuf(%rip), %rcx
    movq $1, %rdx
    xorq %r8, %r8
    leaq 64(%rsp), %r9
    movq .Lws_av_fn+80(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_kc_err
    movq 64(%rsp), %rbx
    movq 32(%rbx), %rcx
    shlq $32, %rcx
    shrq $32, %rcx
    movq $-34, %rax
    cmpq %r14, %rcx
    jg .Lws_kcg_free
    movq %rcx, %rax
    movq 40(%rbx), %rsi
    movq %r13, %rdi
.Lws_kcg_cp:
    testq %rcx, %rcx
    jz .Lws_kcg_free
    movb (%rsi), %dl
    movb %dl, (%rdi)
    incq %rsi
    incq %rdi
    decq %rcx
    jmp .Lws_kcg_cp
.Lws_kcg_free:
    movq %rax, 72(%rsp)
    movq %rbx, %rcx
    movq .Lws_av_fn+96(%rip), %rax
    call *%rax
    movq 72(%rsp), %rax
    jmp .Lws_ret
# 1005 (path): 1 when the owner is the running user and every allowing entry of a present, non-null DACL names that
# user alone (deny entries only narrow); 0 otherwise; -errno when the path cannot be read
.Lws_fip:
    xorq %rax, %rax
    movq %rax, 128(%rsp)
    jmp .Lws_fip_go
# 1006 (path): the mode a POSIX reader expects: 0755 for a directory, 0644 for a file; 0700 / 0600 when only the owner
# can reach it (the 1005 walk); the read-only attribute takes the write bits away
.Lws_fmode:
    movq $1, %rax
    movq %rax, 128(%rsp)
.Lws_fip_go:
    call .Lws_pv_sa_get
    testq %rax, %rax
    jz .Lws_eacces
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
    movq %rax, 120(%rsp)
    leaq .Lws_wbuf(%rip), %rcx
    movq $5, %rdx
    leaq .Lws_pbuf(%rip), %r8
    movq $65536, %r9
    leaq 64(%rsp), %rax
    movq %rax, 32(%rsp)
    movq .Lws_av_fn+104(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    leaq .Lws_pbuf(%rip), %rcx
    leaq 72(%rsp), %rdx
    leaq 80(%rsp), %r8
    movq .Lws_av_fn+120(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_eio
    movq 72(%rsp), %rcx
    testq %rcx, %rcx
    jz .Lws_fip_no
    movq .Lws_pv_tok(%rip), %rdx
    movq .Lws_av_fn+128(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fip_no
    xorq %rax, %rax
    movq %rax, 88(%rsp)
    movq %rax, 96(%rsp)
    leaq .Lws_pbuf(%rip), %rcx
    leaq 88(%rsp), %rdx
    leaq 96(%rsp), %r8
    leaq 104(%rsp), %r9
    movq .Lws_av_fn+112(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_eio
    movq 88(%rsp), %rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fip_no
    movq 96(%rsp), %rbx
    testq %rbx, %rbx
    jz .Lws_fip_no
    movq 4(%rbx), %rsi
    andq $65535, %rsi
    xorq %rdi, %rdi
.Lws_fip_l:
    cmpq %rsi, %rdi
    jge .Lws_fip_yes
    movq %rbx, %rcx
    movq %rdi, %rdx
    leaq 112(%rsp), %r8
    movq .Lws_av_fn+136(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fip_no
    movq 112(%rsp), %rax
    movzbq (%rax), %rcx
    cmpq $1, %rcx
    je .Lws_fip_next
    testq %rcx, %rcx
    jnz .Lws_fip_no
    leaq 8(%rax), %rcx
    movq .Lws_pv_tok(%rip), %rdx
    movq .Lws_av_fn+128(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fip_no
.Lws_fip_next:
    incq %rdi
    jmp .Lws_fip_l
.Lws_fip_yes:
    movq $1, %rax
    jmp .Lws_fip_out
.Lws_fip_no:
    xorq %rax, %rax
.Lws_fip_out:
    cmpq $0, 128(%rsp)
    je .Lws_ret
    movq 120(%rsp), %rcx
    andq $16, %rcx
    testq %rcx, %rcx
    jz .Lws_fmode_file
    movq $493, %rcx
    testq %rax, %rax
    jz .Lws_fmode_ro
    movq $448, %rcx
    jmp .Lws_fmode_ro
.Lws_fmode_file:
    movq $420, %rcx
    testq %rax, %rax
    jz .Lws_fmode_ro
    movq $384, %rcx
.Lws_fmode_ro:
    movq 120(%rsp), %rax
    andq $1, %rax
    testq %rax, %rax
    jz .Lws_fmode_out
    andq $-147, %rcx
.Lws_fmode_out:
    movq %rcx, %rax
    jmp .Lws_ret
# 1003 (target): CredDeleteW
.Lws_kc_del:
    call .Lws_av_init
    testq %rax, %rax
    jz .Lws_enosys
    call .Lws_kc_wide
    testq %rax, %rax
    jz .Lws_einval
    leaq .Lws_cwbuf(%rip), %rcx
    movq $1, %rdx
    xorq %r8, %r8
    movq .Lws_av_fn+88(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_kc_err
    jmp .Lws_zero
# an outgoing sockaddr (rdi, or 0): an AF_INET6 one (family 10) is copied to .Lws_sa with Winsock's family 23;
# rdi = the address to pass. Uses rax, rcx.
.Lws_sa_fix:
    testq %rdi, %rdi
    jz .Lws_saf_out
    movzbq (%rdi), %rax
    cmpq $10, %rax
    jne .Lws_saf_out
    leaq .Lws_sa(%rip), %rax
    movq (%rdi), %rcx
    movq %rcx, (%rax)
    movq 8(%rdi), %rcx
    movq %rcx, 8(%rax)
    movq 16(%rdi), %rcx
    movq %rcx, 16(%rax)
    movq 24(%rdi), %rcx
    movq %rcx, 24(%rax)
    movb $23, (%rax)
    movq %rax, %rdi
.Lws_saf_out:
    ret
# a sockaddr Winsock filled (rdi, or 0): family 23 becomes Linux's 10. Uses rax.
.Lws_sa_back:
    testq %rdi, %rdi
    jz .Lws_sab_out
    movzbq (%rdi), %rax
    cmpq $23, %rax
    jne .Lws_sab_out
    movb $10, (%rdi)
.Lws_sab_out:
    ret
# connect(fd, addr, len) / bind(fd, addr, len): the same three arguments
.Lws_connect:
    movq $16, %rbx
    jmp .Lws_sock3
.Lws_bind:
    movq $32, %rbx
.Lws_sock3:
    movq %r13, %rdi
    call .Lws_sa_fix
    movq %rdi, %r13
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
    movq %r13, %rdi
    call .Lws_sa_back
    movq 64(%rsp), %rax
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
# poll(fds, nfds, ms) over sockets: the Linux pollfd array (fd, events, revents: 8 bytes each) becomes WSAPOLLFD
# entries (SOCKET, events, revents: 16 bytes) in .Lws_pbuf for WSAPoll, and the answers come back as Linux bits
# (POLLIN 1, POLLOUT 4, POLLERR 8, POLLHUP 16, POLLNVAL 32). A descriptor that is not a socket: -EINVAL.
.Lws_poll:
    call .Lws_ws_init
    testq %rax, %rax
    jz .Lws_enosys
    cmpq $0, %r13
    jl .Lws_einval
    cmpq $64, %r13
    jg .Lws_einval
    movq %r12, %rsi
    leaq .Lws_pbuf(%rip), %rdi
    xorq %rbx, %rbx
.Lws_poll_in:
    cmpq %r13, %rbx
    jge .Lws_poll_call
    movq (%rsi,%rbx,8), %rax
    movq %rax, 88(%rsp)
    movq %rax, %r12
    shlq $32, %r12
    shrq $32, %r12
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_einval
    movq %rbx, %rcx
    shlq $4, %rcx
    movq %rax, (%rdi,%rcx)
    movq 88(%rsp), %rax
    shrq $32, %rax
    xorq %rdx, %rdx
    movq %rax, %r8
    andq $1, %r8
    testq %r8, %r8
    jz .Lws_poll_in_w
    orq $768, %rdx
.Lws_poll_in_w:
    movq %rax, %r8
    andq $4, %r8
    testq %r8, %r8
    jz .Lws_poll_in_s
    orq $16, %rdx
.Lws_poll_in_s:
    movq %rdx, 8(%rdi,%rcx)
    incq %rbx
    jmp .Lws_poll_in
.Lws_poll_call:
    leaq .Lws_pbuf(%rip), %rcx
    movq %r13, %rdx
    movq %r14, %r8
    movq .Lws_ws_fn+112(%rip), %rax
    call *%rax
    shlq $32, %rax
    sarq $32, %rax
    cmpq $-1, %rax
    je .Lws_ws_fail
    movq %rax, 72(%rsp)
    xorq %rbx, %rbx
.Lws_poll_out:
    cmpq %r13, %rbx
    jge .Lws_poll_done
    movq %rbx, %rcx
    shlq $4, %rcx
    movq 8(%rdi,%rcx), %rax
    shrq $16, %rax
    andq $65535, %rax
    xorq %rdx, %rdx
    movq %rax, %r8
    andq $768, %r8
    testq %r8, %r8
    jz .Lws_poll_o1
    orq $1, %rdx
.Lws_poll_o1:
    movq %rax, %r8
    andq $16, %r8
    testq %r8, %r8
    jz .Lws_poll_o2
    orq $4, %rdx
.Lws_poll_o2:
    movq %rax, %r8
    andq $1, %r8
    testq %r8, %r8
    jz .Lws_poll_o3
    orq $8, %rdx
.Lws_poll_o3:
    movq %rax, %r8
    andq $2, %r8
    testq %r8, %r8
    jz .Lws_poll_o4
    orq $16, %rdx
.Lws_poll_o4:
    movq %rax, %r8
    andq $4, %r8
    testq %r8, %r8
    jz .Lws_poll_o5
    orq $32, %rdx
.Lws_poll_o5:
    movq (%rsi,%rbx,8), %rax
    shlq $16, %rax
    shrq $16, %rax
    shlq $48, %rdx
    orq %rdx, %rax
    movq %rax, (%rsi,%rbx,8)
    incq %rbx
    jmp .Lws_poll_out
.Lws_poll_done:
    movq 72(%rsp), %rax
    jmp .Lws_ret
# getsockopt(fd, SOL_SOCKET, SO_ERROR, val, lenp): Winsock's getsockopt(0xFFFF, 0x1007); 0 in val is no error
.Lws_getsockopt:
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_enotsock
    cmpq $1, %r13
    jne .Lws_gso_bad
    cmpq $4, %r14
    jne .Lws_gso_bad
    movq %rax, %rcx
    movq $65535, %rdx
    movq $4103, %r8
    movq %r15, %r9
    movq %rbx, 32(%rsp)
    movq .Lws_ws_fn+144(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_ws_fail
    jmp .Lws_zero
.Lws_gso_bad:
    movq $-92, %rax
    jmp .Lws_ret
# fcntl(fd, cmd, arg): F_GETFL is O_RDWR; F_SETFL on a socket sets or clears non-blocking mode (ioctlsocket FIONBIO);
# F_GETFD / F_SETFD and F_SETFL on other descriptors succeed without effect
.Lws_fcntl:
    cmpq $1, %r13
    je .Lws_zero
    cmpq $2, %r13
    je .Lws_zero
    cmpq $3, %r13
    je .Lws_fcntl_get
    cmpq $4, %r13
    jne .Lws_einval
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_zero
    movq %rax, %rcx
    movq %r14, %rax
    andq $2048, %rax
    shrq $11, %rax
    movq %rax, 80(%rsp)
    movq $2147772030, %rdx
    leaq 80(%rsp), %r8
    movq .Lws_ws_fn+136(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_ws_fail
    jmp .Lws_zero
.Lws_fcntl_get:
    movq $2, %rax
    jmp .Lws_ret

# getsockname(fd, addr, lenp): Winsock getsockname; an IPv6 address (family 23) is given back with Linux's family 10
.Lws_getsockname:
    call .Lws_fdh
    cmpq $5, %rcx
    jne .Lws_enotsock
    movq %rax, %rcx
    movq %r13, %rdx
    movq %r14, %r8
    movq .Lws_ws_fn+152(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_ws_fail
    movzbq (%r13), %rax
    cmpq $23, %rax
    jne .Lws_zero
    movb $10, (%r13)
    jmp .Lws_zero
# pseudo system call 1010 (ENOSYS on Linux): the address of the function named by the C string r13 in the system DLL
# named by the C string r12 (LoadLibraryExA with LOAD_LIBRARY_SEARCH_SYSTEM32, then GetProcAddress), or 0. With 1011 it
# lets runtime code written in Lume call any Win32 function: the Windows-specific logic stays Lume, not assembly.
.Lws_dlsym:
    movq %r12, %rcx
    xorq %rdx, %rdx
    movq $2048, %r8
    call LoadLibraryExA
    testq %rax, %rax
    jz .Lws_zero
    movq %rax, %rcx
    movq %r13, %rdx
    call GetProcAddress
    jmp .Lws_ret

# pseudo system call 1011 (ENOSYS on Linux): call the Win64 function at r12 with the r14 integer arguments (0 .. 14) in
# the block of 64-bit words at r13 (at least 4 words long); rax = its result. Arguments 5 and up go above the 32-byte
# shadow space, the first four in rcx, rdx, r8, r9; the stack is 16-byte aligned by __win_syscall.
.Lws_wcall:
    cmpq $14, %r14
    jg .Lws_enosys
    movq $4, %rcx
.Lws_wc_lp:
    cmpq %r14, %rcx
    jge .Lws_wc_regs
    movq (%r13,%rcx,8), %rax
    movq %rax, (%rsp,%rcx,8)
    incq %rcx
    jmp .Lws_wc_lp
.Lws_wc_regs:
    movq (%r13), %rcx
    movq 8(%r13), %rdx
    movq 16(%r13), %r8
    movq 24(%r13), %r9
    movq %r12, %rax
    call *%rax
    jmp .Lws_ret

# pseudo system call 1012: a Win32 HANDLE r12 becomes a descriptor of kind r13 (1 = pipe / file: read, write, epoll
# and close work on it); rax = the descriptor. 1013: the HANDLE behind descriptor r12 (0 when there is none).
.Lws_h2fd:
    movq %r13, %r8
    movq %r12, %r9
    call .Lws_fd_new
    jmp .Lws_ret
.Lws_fd2h:
    call .Lws_fdh
    testq %rcx, %rcx
    jz .Lws_zero
    jmp .Lws_ret

# pseudo system call 1014: run the service control dispatcher for the service named by the UTF-16 string r12 on a new
# thread; rax = a descriptor that delivers one 16-byte record per event: {DWORD code, DWORD event type, DWORD session,
# DWORD 0}. code 256: ServiceMain started (report SERVICE_RUNNING now); 257: the dispatcher failed, event type = the
# Win32 error (1063: the program was not started by the service control manager); otherwise the control code
# (1 STOP, 5 SHUTDOWN, 14 SESSIONCHANGE with the WTS reason and the session id, 15 PRESHUTDOWN, 4 INTERROGATE).
# 1015: r12 = 0 the service status handle (for SetServiceStatus), 1 the event that lets ServiceMain return.
.Lws_svc_start:
    leaq .Lws_svc_name(%rip), %rdi
    movq %r12, %rsi
    movq $255, %rcx
.Lws_svs_cp:
    movzbq (%rsi), %rax
    movzbq 1(%rsi), %rdx
    movb %al, (%rdi)
    movb %dl, 1(%rdi)
    orq %rdx, %rax
    testq %rax, %rax
    jz .Lws_svs_named
    addq $2, %rsi
    addq $2, %rdi
    decq %rcx
    jnz .Lws_svs_cp
    movb $0, (%rdi)
    movb $0, 1(%rdi)
.Lws_svs_named:
    leaq .Lws_adv_dll(%rip), %rcx
    xorq %rdx, %rdx
    movq $2048, %r8
    call LoadLibraryExA
    testq %rax, %rax
    jz .Lws_enosys
    movq %rax, 96(%rsp)
    movq %rax, %rcx
    leaq .Lws_adv_sscd(%rip), %rdx
    call GetProcAddress
    movq %rax, .Lws_svc_fdisp(%rip)
    movq 96(%rsp), %rcx
    leaq .Lws_adv_rsch(%rip), %rdx
    call GetProcAddress
    movq %rax, .Lws_svc_freg(%rip)
    cmpq $0, .Lws_svc_fdisp(%rip)
    je .Lws_enosys
    cmpq $0, .Lws_svc_freg(%rip)
    je .Lws_enosys
    leaq 80(%rsp), %rcx
    leaq 88(%rsp), %rdx
    xorq %r8, %r8
    movq $65536, %r9
    call CreatePipe
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jz .Lws_fail
    movq 88(%rsp), %rax
    movq %rax, .Lws_svc_wr(%rip)
    xorq %rcx, %rcx
    movq $1, %rdx
    xorq %r8, %r8
    xorq %r9, %r9
    call CreateEventW
    movq %rax, .Lws_svc_done(%rip)
    xorq %rcx, %rcx
    xorq %rdx, %rdx
    leaq .Lws_svc_thread(%rip), %r8
    xorq %r9, %r9
    movq $0, 32(%rsp)
    movq $0, 40(%rsp)
    call CreateThread
    testq %rax, %rax
    jz .Lws_fail
    movq %rax, %rcx
    call CloseHandle
    movq $1, %r8
    movq 80(%rsp), %r9
    call .Lws_fd_new
    jmp .Lws_ret
.Lws_svc_get:
    movq .Lws_svc_status(%rip), %rax
    testq %r12, %r12
    jz .Lws_ret
    movq .Lws_svc_done(%rip), %rax
    jmp .Lws_ret
# write the record {ecx code, edx event type, r8d session, 0} to the event pipe (any thread; volatile registers only)
.Lws_svc_post:
    subq $72, %rsp
    shlq $32, %rcx
    shrq $32, %rcx
    shlq $32, %rdx
    orq %rdx, %rcx
    movq %rcx, 48(%rsp)
    shlq $32, %r8
    shrq $32, %r8
    movq %r8, 56(%rsp)
    movq .Lws_svc_wr(%rip), %rcx
    leaq 48(%rsp), %rdx
    movq $16, %r8
    leaq 64(%rsp), %r9
    movq $0, 32(%rsp)
    call WriteFile
    addq $72, %rsp
    ret
# the dispatcher thread: SERVICE_TABLE_ENTRYW {name, ServiceMain}, {0, 0}; when the dispatcher returns at once it failed
.Lws_svc_thread:
    subq $56, %rsp
    leaq .Lws_svc_table(%rip), %rcx
    leaq .Lws_svc_name(%rip), %rax
    movq %rax, (%rcx)
    leaq .Lws_svc_main(%rip), %rax
    movq %rax, 8(%rcx)
    movq $0, 16(%rcx)
    movq $0, 24(%rcx)
    movq .Lws_svc_fdisp(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_svt_out
    call GetLastError
    movq $257, %rcx
    movq %rax, %rdx
    xorq %r8, %r8
    call .Lws_svc_post
.Lws_svt_out:
    xorq %rax, %rax
    addq $56, %rsp
    ret
# ServiceMain(argc, argv): the control handler registered, "started" posted, then it waits for the done event
.Lws_svc_main:
    subq $56, %rsp
    leaq .Lws_svc_name(%rip), %rcx
    leaq .Lws_svc_handler(%rip), %rdx
    xorq %r8, %r8
    movq .Lws_svc_freg(%rip), %rax
    call *%rax
    movq %rax, .Lws_svc_status(%rip)
    movq $256, %rcx
    xorq %rdx, %rdx
    xorq %r8, %r8
    call .Lws_svc_post
    movq .Lws_svc_done(%rip), %rcx
    movq $4294967295, %rdx
    call WaitForSingleObject
    addq $56, %rsp
    ret
# HandlerEx(control, event type, event data, context): every control posted; SESSIONCHANGE carries the session id of
# its WTSSESSION_NOTIFICATION {cbSize, dwSessionId}; the answer is NO_ERROR
.Lws_svc_handler:
    subq $56, %rsp
    xorq %rax, %rax
    movq %rcx, %r10
    shlq $32, %r10
    shrq $32, %r10
    cmpq $14, %r10
    jne .Lws_svh_post
    testq %r8, %r8
    jz .Lws_svh_post
    movq (%r8), %rax
    shrq $32, %rax
.Lws_svh_post:
    movq %rax, %r8
    call .Lws_svc_post
    xorq %rax, %rax
    addq $56, %rsp
    ret

# pseudo system call 1008 (ENOSYS on Linux): the IPv4 unicast addresses of the adapters that are up, 4 bytes each
# (network order) into buf r12 of r13 bytes; rax = the number of bytes written
.Lws_ipv4if:
    call .Lws_iph_load
    testq %rax, %rax
    jz .Lws_enosys
    movq $65536, 80(%rsp)
    movq $2, %rcx
    movq $14, %rdx
    xorq %r8, %r8
    leaq .Lws_gaa(%rip), %r9
    leaq 80(%rsp), %rax
    movq %rax, 32(%rsp)
    movq .Lws_iph_fn(%rip), %rax
    call *%rax
    shlq $32, %rax
    shrq $32, %rax
    testq %rax, %rax
    jnz .Lws_zero
    leaq .Lws_gaa(%rip), %rsi
    xorq %rdi, %rdi
.Lws_v4_ad:
    testq %rsi, %rsi
    jz .Lws_v4_done
    movq 104(%rsi), %rax
    shlq $32, %rax
    shrq $32, %rax
    cmpq $1, %rax
    jne .Lws_v4_adn
    movq 24(%rsi), %rbx
.Lws_v4_u:
    testq %rbx, %rbx
    jz .Lws_v4_adn
    movq 16(%rbx), %rcx
    testq %rcx, %rcx
    jz .Lws_v4_un
    movzbq (%rcx), %rax
    cmpq $2, %rax
    jne .Lws_v4_un
    movq %rdi, %rax
    addq $4, %rax
    cmpq %r13, %rax
    jg .Lws_v4_done
    movzbq 4(%rcx), %rax
    movb %al, (%r12,%rdi)
    incq %rdi
    movzbq 5(%rcx), %rax
    movb %al, (%r12,%rdi)
    incq %rdi
    movzbq 6(%rcx), %rax
    movb %al, (%r12,%rdi)
    incq %rdi
    movzbq 7(%rcx), %rax
    movb %al, (%r12,%rdi)
    incq %rdi
.Lws_v4_un:
    movq 8(%rbx), %rbx
    jmp .Lws_v4_u
.Lws_v4_adn:
    movq 8(%rsi), %rsi
    jmp .Lws_v4_ad
.Lws_v4_done:
    movq %rdi, %rax
    jmp .Lws_ret

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
    movq %rbx, %rdi
    call .Lws_sa_fix
    movq %rdi, %rbx
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
    movq %rax, 64(%rsp)
    movq %rbx, %rdi
    call .Lws_sa_back
    movq 64(%rsp), %rax
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
    movq $0, .Lws_fk_newgrp(%rip)
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
    cmpq $0, .Lws_fk_newgrp(%rip)
    je .Lws_ex_nosusp
    orq $4, 40(%rsp)
.Lws_ex_nosusp:
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
    cmpq $0, .Lws_fk_newgrp(%rip)
    je .Lws_ex_nojob
    call .Lws_job_attach
.Lws_ex_nojob:
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
    testq %r12, %r12
    jns .Lws_kill_pos
    negq %r12
    call .Lws_job_kill
.Lws_kill_pos:
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
# both ends inheritable (HANDLE_FLAG_INHERIT), as a POSIX pipe is across fork: a forked child that dup2s an end onto
# 0 / 1 / 2 and execs hands it to the new process (the child closes the ends it does not use before exec)
    movq 80(%rsp), %rcx
    movq $1, %rdx
    movq $1, %r8
    call SetHandleInformation
    movq 88(%rsp), %rcx
    movq $1, %rdx
    movq $1, %r8
    call SetHandleInformation
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
.Lws_adv_dll:
    .asciz "advapi32.dll"
.Lws_adv_snsi:
    .asciz "SetNamedSecurityInfoW"
.Lws_adv_sscd:
    .asciz "StartServiceCtrlDispatcherW"
.Lws_adv_rsch:
    .asciz "RegisterServiceCtrlHandlerExW"
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
    .asciz "WSAPoll"
    .asciz "WSAAddressToStringA"
    .asciz "WSAIoctl"
    .asciz "ioctlsocket"
    .asciz "getsockopt"
    .asciz "getsockname"
    .byte 0
.Lws_av_dll:
    .asciz "advapi32.dll"
.Lws_av_names:
    .asciz "OpenProcessToken"
    .asciz "GetTokenInformation"
    .asciz "InitializeAcl"
    .asciz "AddAccessAllowedAceEx"
    .asciz "InitializeSecurityDescriptor"
    .asciz "SetSecurityDescriptorDacl"
    .asciz "SetSecurityDescriptorOwner"
    .asciz "SetSecurityDescriptorControl"
    .asciz "SetFileSecurityW"
    .asciz "CredWriteW"
    .asciz "CredReadW"
    .asciz "CredDeleteW"
    .asciz "CredFree"
    .asciz "GetFileSecurityW"
    .asciz "GetSecurityDescriptorDacl"
    .asciz "GetSecurityDescriptorOwner"
    .asciz "EqualSid"
    .asciz "GetAce"
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
.Lws_iph_dll:
    .asciz "iphlpapi.dll"
.Lws_iph_names:
    .asciz "GetAdaptersAddresses"
    .asciz "if_nametoindex"
    .asciz "ConvertInterfaceAliasToLuid"
    .asciz "ConvertInterfaceLuidToIndex"
    .byte 0
.Lws_ns_pfx:
    .asciz "nameserver "
.Lws_bcrypt_dll:
    .asciz "bcrypt.dll"
.Lws_bcrypt_proc:
    .asciz "BCryptGenRandom"
.Lws_kbase_dll:
    .asciz "kernelbase.dll"
.Lws_mvn2_proc:
    .asciz "MapViewOfFileNuma2"
.Lffr_m1:
    .asciz ": symbol lookup error: "
.Lffr_m2:
    .asciz ": undefined symbol: "
# io_uring_register(fd, op, NULL, nr) for op 0..40: errno with nr_args 0, then with nr_args >= 1 (Linux 6.18)
.Lws_ur_tab:
    .byte 14, 14, 6, 22, 14, 14, 6, 22, 22, 14, 6, 22, 22, 14, 22, 14, 22, 22, 255, 22, 22, 0, 77, 77, 77, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 0, 22, 22, 22, 22, 14, 22, 14, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 0, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 0, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22
# the libraries of `lume build --link` (the driver replaces this line); "@..." = none
__lume_ffi_libs:
    .asciz "@lume-ffi-libs@"
.Lws_devstdin:
    .asciz "/dev/stdin"
    .section .bss
    .lcomm .Lws_wbuf, 65536
    .lcomm .Lws_jobs, 1024
    .lcomm .Lws_svc_name, 512
    .lcomm .Lws_svc_table, 32
    .lcomm .Lws_svc_wr, 8
    .lcomm .Lws_svc_done, 8
    .lcomm .Lws_svc_status, 8
    .lcomm .Lws_svc_fdisp, 8
    .lcomm .Lws_sns_fn, 8
    .lcomm .Lws_empty_acl, 16
    .lcomm .Lws_svc_freg, 8
    .lcomm .Lws_jobs_next, 8
    .lcomm .Lws_fk_newgrp, 8
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
    .lcomm .Lws_ws_fn, 256
    .lcomm .Lws_sa, 32
    .lcomm .Lws_gaa, 65536
    .lcomm .Lws_iph_fn, 32
    .lcomm .Lws_wsadata, 512
    .lcomm .Lws_envblk, 8
    .lcomm .Lws_envp_arg, 8
    .lcomm .Lws_cpres, 8
    .lcomm .Lws_cperr, 8
    .lcomm .Lws_shm, 1536
    .lcomm .Lws_ept, 8192
    .lcomm .Lws_ur_pers, 8
    .lcomm .Lws_mvn2_fn, 8
    .lcomm .Lws_av_ok, 8
    .lcomm .Lws_av_fn, 256
    .lcomm .Lws_pv_ok, 8
    .lcomm .Lws_pv_sa, 24
    .lcomm .Lws_pv_pad, 8
    .lcomm .Lws_pv_sd, 64
    .lcomm .Lws_pv_tok, 256
    .lcomm .Lws_pv_acl, 256
