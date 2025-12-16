; -----------------------------------------------------------------------------
; Example 07: Recursion & Input
; Mode: Nasm-GCC (Links with libc)
; Demonstrates:
; 1. Using scanf to get user input.
; 2. Recursive factorial function.
; 3. Using enter/leave for stack frames.
; -----------------------------------------------------------------------------

extern printf
extern scanf
extern exit

section .data
    prompt_msg  db  "Enter a number to calculate factorial: ", 0
    scan_fmt    db  "%ld", 0
    result_msg  db  "Factorial of %ld is %ld", 10, 0

section .bss
    input_num   resq 1

section .text
default rel
global main

main:
    enter   0, 0 ; Set up stack frame

    ; Print prompt
    ; printf("Enter a number...")
    mov     rdi, prompt_msg
    xor     rax, rax        ; 0 vector registers
    call    printf

    ; Read input
    ; scanf("%ld", &input_num)
    mov     rdi, scan_fmt
    mov     rsi, input_num
    xor     rax, rax
    call    scanf

    ; Calculate factorial
    mov     rdi, [input_num]
    call    factorial

    ; Print result
    ; printf("Factorial of %ld is %ld\n", input_num, result)
    mov     rdi, result_msg
    mov     rsi, [input_num]
    mov     rdx, rax        ; Result from factorial
    xor     rax, rax
    call    printf

    xor     rax, rax        ; Return 0
    leave
    ret

; -----------------------------------------------------------------------------
; Function: factorial
; Arguments: rdi = n
; Returns: rax = n!
; -----------------------------------------------------------------------------
factorial:
    ; Allocate 16 bytes for local variables + alignment
    enter   16, 0

    ; Save n (rdi) to local stack [rbp-8]
    mov     [rbp-8], rdi
    
    ; Base case: if n <= 1, return 1
    cmp     rdi, 1
    jle     .base_case
    
    ; Recursive step: factorial(n-1)
    dec     rdi
    call    factorial
    
    ; Restore n
    mov     rdi, [rbp-8]
    
    ; Result = n * factorial(n-1)
    mul     rdi         ; rdx:rax = rax * rdi
    jmp     .done

.base_case:
    mov     rax, 1

.done:
    leave
    ret
