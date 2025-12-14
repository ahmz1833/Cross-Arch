; -----------------------------------------------------------------------------
; Example 02: Input and Output
; Mode: Nolibc (NASM)
; Demonstrates:
; - Reading strings with read_line
; - Reading characters with read_char
; - Printing integers (ASCII values) in Dec, Hex, Bin
; -----------------------------------------------------------------------------

%include "macros.inc"

section .data
    prompt_name     db "Enter your name: ", 0
    greeting        db "Hello, ", 0
    prompt_char     db "Enter a character to see its ASCII code: ", 0
    msg_ascii_dec   db "The ASCII code is: ", 0
    msg_ascii_hex   db "The ASCII code in hex is: 0x", 0
    msg_ascii_bin   db "The ASCII code in binary is: 0b", 0

section .bss
    buffer          resb 64

section .text
default rel
global _start

_start:
    ; 1. Read Name
    print_str   prompt_name
    read_line   buffer, 64

    ; 2. Print Greeting
    print_str   greeting
    print_str   buffer
    print_newline

    ; 3. Read Character
    print_str   prompt_char
    read_char   bl          ; Read into BL register

    ; Consume the newline left in buffer if any (optional but good practice)
    ; For simplicity, we assume user types char + enter. 
    ; read_char reads 1 byte. The newline is still in stdin buffer.
    ; We might want to flush it or just ignore it.
    
    ; 4. Print ASCII Code
    print_newline
    
    ; Decimal
    print_str   msg_ascii_dec
    movzx       rdi, bl     ; Zero-extend char to 64-bit
    print_int   rdi
    print_newline

    ; Hex
    print_str   msg_ascii_hex
    movzx       rdi, bl
    print_hex   rdi, 2      ; Print with width 2 (e.g. 0A)
    print_newline

    ; Binary
    print_str   msg_ascii_bin
    movzx       rdi, bl
    print_bin   rdi, 8      ; Print with width 8 (e.g. 01000001)
    print_newline

    exit
