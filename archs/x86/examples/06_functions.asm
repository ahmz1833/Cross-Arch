; -----------------------------------------------------------------------------
; Example 06: Functions, Stack Frames, and Command Line Arguments
; Mode: Nasm-GCC (Links with libc)
; This example demonstrates:
; 1. Interfacing with C Standard Library (libc) functions (printf).
; 2. Accessing Command Line Arguments (argc, argv) passed to 'main'.
; 3. Defining and calling functions using the System V AMD64 ABI.
; 4. Managing Stack Frames using 'enter' and 'leave' instructions.
; -----------------------------------------------------------------------------

; Declare external symbols from libc
extern printf

section .data
    ; Format strings for printf
    ; %d = signed decimal (32-bit)
    ; %s = string
    ; %ld = signed long decimal (64-bit)
    ; 10 = newline (\n), 0 = null terminator
    
    fmt_title   db  "--- Functions & Args Demo (Libc) ---", 10, 0
    fmt_argc    db  "Argument Count (argc): %d", 10, 0
    fmt_argv    db  "Argument %d: %s", 10, 0
    fmt_sum     db  "Sum of %ld + %ld = %ld", 10, 0

section .text
default rel
global main     ; Entry point for GCC

; -----------------------------------------------------------------------------
; Function: main
; Arguments (passed by OS/Runtime):
;   rdi = argc (Argument Count)
;   rsi = argv (Argument Vector - pointer to array of strings)
; -----------------------------------------------------------------------------
main:
    ; -------------------------------------------------------------------------
    ; Function Prologue
    ; -------------------------------------------------------------------------
    ; We use 'push rbp' and 'mov rbp, rsp' to set up a stack frame.
    ; This is standard for debugging and stack unwinding.
    push    rbp
    mov     rbp, rsp

    ; -------------------------------------------------------------------------
    ; Saving Callee-Saved Registers
    ; -------------------------------------------------------------------------
    ; The ABI says rbx, rbp, r12, r13, r14, r15 must be preserved by the callee.
    ; Since we want to use registers that survive function calls (like printf),
    ; we will use r12, r13, r14 and save them first.
    push    r12
    push    r13
    push    r14

    ; Move arguments to safe registers
    mov     r12, rdi        ; r12 = argc
    mov     r13, rsi        ; r13 = argv

    ; Print Title
    mov     rdi, fmt_title
    xor     rax, rax        ; rax = 0 (no vector registers used)
    call    printf

    ; -------------------------------------------------------------------------
    ; Part 1: Print Argument Count (argc)
    ; -------------------------------------------------------------------------
    mov     rdi, fmt_argc   ; Arg 1: Format string
    mov     rsi, r12        ; Arg 2: argc value
    xor     rax, rax        ; No floating point args
    call    printf

    ; -------------------------------------------------------------------------
    ; Part 2: Loop through Arguments (argv)
    ; -------------------------------------------------------------------------
    xor     r14, r14        ; r14 = loop counter (i = 0)

.loop_args:
    cmp     r14, r12        ; Compare i with argc
    jge     .loop_end       ; If i >= argc, exit loop

    ; Prepare arguments for printf("Argument %d: %s", i, argv[i])
    
    ; Arg 1: Format string
    mov     rdi, fmt_argv
    
    ; Arg 2: Index (i)
    mov     rsi, r14
    
    ; Arg 3: String pointer (argv[i])
    ; argv is a pointer to an array of pointers (char**)
    ; Address of argv[i] is: base (r13) + index (r14) * size (8 bytes)
    mov     rdx, [r13 + r14*8]
    
    xor     rax, rax
    call    printf

    inc     r14             ; i++
    jmp     .loop_args

.loop_end:

    ; -------------------------------------------------------------------------
    ; Part 3: Call a Custom Function
    ; -------------------------------------------------------------------------
    ; We will call 'my_sum(100, 200)'
    
    mov     rdi, 100        ; Arg 1
    mov     rsi, 200        ; Arg 2
    call    my_sum
    
    ; Result is in rax. Let's print it.
    ; printf("Sum of %ld + %ld = %ld", 100, 200, result)
    
    mov     rcx, rax        ; Arg 4: Result (move first to avoid overwriting)
    mov     rdx, 200        ; Arg 3: 200
    mov     rsi, 100        ; Arg 2: 100
    mov     rdi, fmt_sum    ; Arg 1: Format
    xor     rax, rax
    call    printf

    ; -------------------------------------------------------------------------
    ; Function Epilogue & Exit
    ; -------------------------------------------------------------------------
    ; Restore saved registers in reverse order
    pop     r14
    pop     r13
    pop     r12

    ; Restore stack frame
    leave       ; Equivalent to 'mov rsp, rbp' then 'pop rbp'
    
    xor     rax, rax        ; Return 0 from main
    ret

; -----------------------------------------------------------------------------
; Function: my_sum
; Purpose:  Adds two integers.
; Inputs:   rdi = a, rsi = b
; Returns:  rax = a + b
; -----------------------------------------------------------------------------
my_sum:
    ; 'enter' instruction creates a stack frame.
    ; Operand 1: Bytes to allocate for local variables (0 here).
    ; Operand 2: Nesting level (0 for standard functions).
    ; It performs: push rbp; mov rbp, rsp; sub rsp, alloc_size
    enter   0, 0

    mov     rax, rdi        ; Move first arg to result register
    add     rax, rsi        ; Add second arg

    ; 'leave' destroys the stack frame.
    ; It performs: mov rsp, rbp; pop rbp
    leave
    ret
