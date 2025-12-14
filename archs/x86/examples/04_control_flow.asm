; -----------------------------------------------------------------------------
; Example 04: Control Flow
; Mode: Nolibc (NASM)
; Demonstrates comparisons, conditional jumps (if/else), and loops.
; -----------------------------------------------------------------------------

%include "macros.inc"

section .data
    msg_start   db  "--- Control Flow Demo ---", 10, 0
    
    ; If/Else Data
    num_a       dq  50
    num_b       dq  20
    msg_greater db  "A is greater than B", 10, 0
    msg_less    db  "A is less than or equal to B", 10, 0
    
    ; Loop Data
    msg_loop    db  "Counting down from 5:", 10, 0
    msg_done    db  "Loop finished!", 10, 0

section .text
default rel
global _start

_start:
    print_str msg_start

    ; -------------------------------------------------------------------------
    ; Part 1: If / Else
    ; if (rax > rbx) { print greater } else { print less }
    ; -------------------------------------------------------------------------
    
    mov     rax, [num_a]
    mov     rbx, [num_b]
    
    ; Compare rax and rbx
    ; cmp performs (rax - rbx) and sets flags (ZF, SF, OF, CF, etc.)
    cmp     rax, rbx
    
    ; Jump if Greater (signed comparison)
    jg      .is_greater
    
    ; Else block (Less or Equal)
    print_str msg_less
    jmp     .after_check    ; Skip the "then" block

.is_greater:
    ; Then block
    print_str msg_greater

.after_check:
    print_newline

    ; -------------------------------------------------------------------------
    ; Part 2: Loop (While / For)
    ; int i = 5; while (i > 0) { print i; i--; }
    ; -------------------------------------------------------------------------
    
    print_str msg_loop
    
    mov     rcx, 5          ; Initialize counter

.my_loop:
    ; Body of the loop
    print_int rcx
    print_newline
    
    ; Decrement counter
    dec     rcx ; No need to cmp all the time, some instructions set flags automatically
    
    ; Check condition
    ; dec sets Zero Flag if result is 0
    ; jnz = Jump if Not Zero
    jnz     .my_loop
    
    print_str msg_done

    exit
