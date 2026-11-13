# Win64 layer: BSD sockets on Winsock (ws2_32.dll from System32, loaded on first use, like bcrypt.dll).
# Syscalls socket(41) connect(42) accept(43) sendto(44) recvfrom(45) shutdown(48) bind(49) listen(50)
# setsockopt(54). A socket is fd kind 5 in the fd table: read/write/close on it are recv/send/closesocket.
# sockaddr_in and AF_INET / SOCK_STREAM / SOCK_DGRAM / SHUT_* have the same values and layout on both systems.
# Winsock errors map to Linux errno. Function pointers are called with `call *%rax`.
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in; my $n = 0;
sub rep { my ($o, $nw) = @_; my $i = index($t, $o); die "nf:\n$o" if $i < 0; die "amb:\n$o" if index($t, $o, $i + 1) >= 0; substr($t, $i, length($o)) = $nw; $n++ }

# dispatch
rep("    cmpq \$63, %rax\n    je .Lws_uname\n",
    "    cmpq \$63, %rax\n    je .Lws_uname\n" . join('', map { "    cmpq \$$_->[0], %rax\n    je $_->[1]\n" }
      ([41, '.Lws_socket'], [42, '.Lws_connect'], [43, '.Lws_accept'], [44, '.Lws_sendto'], [45, '.Lws_recvfrom'],
       [48, '.Lws_shutdown'], [49, '.Lws_bind'], [50, '.Lws_listen'], [54, '.Lws_setsockopt'])));

# read / write / close on a socket
rep("    cmpq \$2, %rcx\n    je .Lws_eisdir\n    movq %rax, 72(%rsp)\n",
    "    cmpq \$2, %rcx\n    je .Lws_eisdir\n    cmpq \$5, %rcx\n    je .Lws_read_sock\n    movq %rax, 72(%rsp)\n");
rep(".Lws_write:\n    call .Lws_fdh\n    cmpq \$1, %rcx\n    je .Lws_write_c\n",
    ".Lws_write:\n    call .Lws_fdh\n    cmpq \$5, %rcx\n    je .Lws_write_sock\n    cmpq \$1, %rcx\n    je .Lws_write_c\n");
rep("    movq 72(%rsp), %rcx\n    cmpq \$2, %rcx\n    je .Lws_close_dir\n",
    "    movq 72(%rsp), %rcx\n    cmpq \$2, %rcx\n    je .Lws_close_dir\n    cmpq \$5, %rcx\n    je .Lws_close_sock\n");

my $L = <<'ASM';
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
ASM
rep(".Lws_getdents:\n", $L . ".Lws_getdents:\n");

my $RO = <<'RO';
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
RO
rep("    .section .rodata\n.Lws_un_sys:\n", "    .section .rodata\n" . $RO . ".Lws_un_sys:\n");
rep("    .lcomm .Lws_nrt, 1024\n", "    .lcomm .Lws_nrt, 1024\n    .lcomm .Lws_ws_ok, 8\n    .lcomm .Lws_ws_fn, 128\n    .lcomm .Lws_wsadata, 512\n");
open my $o, '>:raw', $f or die; print $o $t; close $o; print "sockets patch: $n\n";
