; -----------------------------------------------------------------------------
; Example 03: Data Types and Sections
; Mode: Nolibc (NASM)
; Demonstrates how to define different data types and use sections in NASM.
; -----------------------------------------------------------------------------

%include "macros.inc"

; -----------------------------------------------------------------------------
; Section .data
; Used for initialized data. These variables exist in the binary and are loaded
; into memory when the program starts.
; -----------------------------------------------------------------------------
section .data
    ; Constants (Assembler constants, not stored in memory)
    MY_CONST    equ 123

    ; Strings (Array of bytes)
    ; 10 is newline (\n), 0 is null terminator
    title_msg   db  "--- NASM Data Types & Sections ---", 10, 0
    
    lbl_byte    db  "Byte (db, 8-bit): ", 0
    lbl_word    db  "Word (dw, 16-bit): ", 0
    lbl_dword   db  "DWord (dd, 32-bit): ", 0
    lbl_qword   db  "QWord (dq, 64-bit): ", 0
    lbl_array   db  "Array element [2]: ", 0

    ; Scalar Variables
    ; db = Define Byte (8 bits)
    var_byte    db  42
    
    ; dw = Define Word (16 bits)
    var_word    dw  1337
    
    ; dd = Define Double Word (32 bits)
    var_dword   dd  123456789
    
    ; dq = Define Quad Word (64 bits)
    var_qword   dq  987654321098765432

    ; Arrays
    ; Just a sequence of values. The label points to the first one.
    my_array    db  10, 4 dup(20), 30, 40
	; This creates an array: [10, 20, 20, 20, 20, 30, 40]

; -----------------------------------------------------------------------------
; Section .bss
; Used for uninitialized data. This section doesn't take up space in the binary
; on disk, but the OS reserves memory for it at runtime.
; -----------------------------------------------------------------------------
section .bss
    ; resb = Reserve Byte
    ; resw = Reserve Word
    ; resd = Reserve Double Word
    ; resq = Reserve Quad Word
    
    buffer      resb 64     ; Reserve 64 bytes
    count       resd 1      ; Reserve 1 dword (4 bytes)

; -----------------------------------------------------------------------------
; Section .text
; Contains the actual code (instructions).
; -----------------------------------------------------------------------------
section .text
default rel
global _start

_start:
    ; Print title
    print_str title_msg

    ; --- 8-bit Byte ---
    print_str lbl_byte
    
    ; To print a byte, we load it into a register.
    ; Since registers are 64-bit (rax), we should clear it first or use movzx.
    xor     rax, rax        ; Clear rax
    mov     al, [var_byte]  ; Load 8 bits into al (lower part of rax)
    print_int rax
    print_newline

    ; --- 16-bit Word ---
    print_str lbl_word
    
    xor     rax, rax
    mov     ax, [var_word]  ; Load 16 bits into ax
    print_int rax
    print_newline

    ; --- 32-bit DWord ---
    print_str lbl_dword
    
    xor     rax, rax
    mov     eax, [var_dword] ; Load 32 bits into eax
    print_int rax
    print_newline

    ; --- 64-bit QWord ---
    print_str lbl_qword
    
    mov     rax, [var_qword] ; Load 64 bits into rax
    print_int rax
    print_newline

    ; --- Array Access ---
    print_str lbl_array
    
    ; Accessing array element at index 2 (0-based)
    ; Address = my_array + 2
    xor     rax, rax
    mov     al, [my_array + 2]
    print_int rax
    print_newline

    exit
