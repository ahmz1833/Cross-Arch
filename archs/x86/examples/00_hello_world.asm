; -----------------------------------------------------------------------------
; Example 00: Hello World
; Mode: Nolibc (NASM)
; Demonstrates:
; - Basic structure of a NASM program
; - Using macros for printing
; -----------------------------------------------------------------------------

%include "macros.inc"

section .data
    msg db "Hello, x86_64 World!", 0

section .text
default rel
global _start

_start:
    ; Print Hello World
    print_str msg
    
    ; Print Newline
    print_newline

    ;amd64(X86-64) ASSEMBLY INSTRUCTION REFERENCE
    ;https://www.felixcloutier.com/x86/
    mov rax, 20
    mov rbx, 30
    add rax, rbx ; RAX = RAX + RBX = 50
    
    ; mov rax, 3
    ; mov rbx, 7
    mul rbx; RDX:RAX = RAX*SOURC(RBX)
    ;; 21

    print_int rax

    ; Exit
    exit
