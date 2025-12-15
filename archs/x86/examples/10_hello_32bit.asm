; -----------------------------------------------------------------------------
; Example 10: Hello World (32-bit)
; Demonstrates legacy Linux syscalls using int 0x80.
; -----------------------------------------------------------------------------

section .data
    msg     db  "Hello from 32-bit Legacy Mode!", 10
    len     equ $ - msg

section .text
    global _start

_start:
    ; sys_write(fd=1, buf=msg, len=len)
    ; syscall number 4 is write in x86 (32-bit)
    mov     eax, 4
    mov     ebx, 1          ; fd = stdout
    mov     ecx, msg        ; buffer
    mov     edx, len        ; length
    int     0x80            ; Interrupt 0x80 invokes the kernel

    ; sys_exit(status=0)
    ; syscall number 1 is exit in x86 (32-bit)
    mov     eax, 1
    mov     ebx, 0          ; status
    int     0x80
