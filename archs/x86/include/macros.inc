; -----------------------------------------------------------------------------
; File: macros.inc
; Description: Useful Macros for x86_64 assembly (NASM)
; -----------------------------------------------------------------------------

%include "constants.inc"
%include "syscalls.inc"

; -----------------------------------------------------------------------------
; Helper Macros
; -----------------------------------------------------------------------------

%macro print_str 1
    lea     rdi, [%1]       ; Load Effective Address (handles labels)
    call    fn_print_string
%endmacro

%macro print_int 1
    mov     rdi, %1
    call    fn_print_int
%endmacro

%macro print_newline 0
    call    fn_print_newline
%endmacro

%macro exit 0
    sys_exit 0
%endmacro

%macro print_hex 1
    mov     rdi, %1
    mov     rsi, 16
    xor     rdx, rdx        ; Default width 0
    call    fn_print_uint_base
%endmacro

%macro print_hex 2
    mov     rdi, %1
    mov     rsi, 16
    mov     rdx, %2         ; Width
    call    fn_print_uint_base
%endmacro

%macro print_bin 1
    mov     rdi, %1
    mov     rsi, 2
    xor     rdx, rdx        ; Default width 0
    call    fn_print_uint_base
%endmacro

%macro print_bin 2
    mov     rdi, %1
    mov     rsi, 2
    mov     rdx, %2         ; Width
    call    fn_print_uint_base
%endmacro

%macro read_line 2
    lea     rdi, [%1]
    mov     rsi, %2
    call    fn_read_line
%endmacro

%macro read_char 1
    call    fn_read_char
    mov     %1, al
%endmacro

; -----------------------------------------------------------------------------
; Include Helper Functions
; -----------------------------------------------------------------------------
; We include functions here so they are available. 
; Since they are in 'section .text', they will be placed in the text segment.
; Ensure your program defines '_start' or 'main' as the entry point.
%include "functions.inc"
