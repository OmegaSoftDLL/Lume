    .need "KERNEL32.dll"
    .extern KERNEL32.dll!Sleep
    .extern KERNEL32.dll!ExitProcess
    .section .text
_start:
    subq $40, %rsp
    movq $4000, %rcx
    call Sleep
    xorq %rcx, %rcx
    call ExitProcess
