; -----------------------------------------------------------------------------
; Example 01: Hello World (Libc)
; Mode: Nasm-GCC (Links with libc)
; Demonstrates:
; - Linking with C library
; - Calling printf
; - Stack alignment (System V AMD64 ABI)
; -----------------------------------------------------------------------------

%include "macros.inc"

extern printf

section .data
    msg db "Hello, Libc World!", 10, 0
    fmt db "Integer: %d, String: %s", 10, 0

section .text
default rel
global main

; SystemV AMD64 ABI 
; Integer Function arguments : RDI, RSI, RDX, RCX, R8, R9, (Extra on stack)
; Float/Double Function arguments : [XYZ]MM[0-7]
; Return value : RAX
; More Info : https://wiki.osdev.org/System_V_ABI#x86-64
main:
    ; we are working with c => rsp % 16 = 0 before any function call
    enter   0, 0            ; Setup stack frame (push rbp; mov rbp, rsp)

    ; 1. Simple printf
    ; printf(msg)
    lea     rdi, [msg]
    xor     rax, rax        ; Clear AL (0 vector registers used for varargs)
    call    printf

    ; 2. Formatted printf
    ; printf(fmt, 42, msg)
    lea     rdi, [fmt]      ; 1st arg: format string
    mov     rsi, 42         ; 2nd arg: integer
    lea     rdx, [msg]      ; 3rd arg: string
    xor     rax, rax        ; Clear AL
    call    printf

    ; Return 0
    xor     rax, rax

    ;amd64(X86-64) ASSEMBLY INSTRUCTION REFERENCE
    ;https://www.felixcloutier.com/x86/
    ; mov rax, 20
    ; mov rbx, 30
    ; add rax, rbx
    
    ; mov rax, 3
    ; mov rbx, 7
    mul rbx; RDX:RAX = RAX*SOURC(RBX)
    ;; 21
    
    ; Epilogue
    leave                   ; Restore RSP and RBP (mov rsp, rbp; pop rbp)
    ret
