; -----------------------------------------------------------------------------
; Example 08: Many Arguments with Scanf/Printf
; Demonstrates passing >6 arguments (System V ABI).
; -----------------------------------------------------------------------------

default rel

extern printf
extern scanf

extern puts

section .data
    align 16
    fmt_title   db  "--- Many Arguments Demo ---", 0
    align 16
    fmt_prompt  db  "Enter 8 integers: ", 0
    fmt_in      db  "%ld %ld %ld %ld %ld %ld %ld %ld", 0
    fmt_out     db  "You entered: %ld, %ld, %ld, %ld, %ld, %ld, %ld, %ld", 10, 0

section .bss
    nums        resq 8      ; Array of 8 quadwords

section .text
    global main

main:
    push    rbp
    mov     rbp, rsp

    ; Print Title
    lea     rdi, [fmt_title]
    call    puts
    
    ; Print Prompt
    lea     rdi, [fmt_prompt]
    xor     rax, rax
    call    printf

    ; -------------------------------------------------------------------------
    ; Scanf: scanf("%ld...", &nums[0], ..., &nums[7])
    ; -------------------------------------------------------------------------
    ; We have 9 arguments total (fmt + 8 pointers).
    ; 6 in registers, 3 on stack.
    ; Stack must be 16-byte aligned before 'call'.
    ; Pushing 3 args (24 bytes) misaligns it (if started aligned).
    ; So we subtract 8 bytes first.
    
    sub     rsp, 8              ; Align stack
    
    ; Push Args 9, 8, 7 (Reverse order)
    lea     rax, [nums + 56]    ; &nums[7]
    push    rax
    lea     rax, [nums + 48]    ; &nums[6]
    push    rax
    lea     rax, [nums + 40]    ; &nums[5]
    push    rax
    
    ; Args 1-6 in registers
    lea     r9,  [nums + 32]    ; &nums[4]
    lea     r8,  [nums + 24]    ; &nums[3]
    lea     rcx, [nums + 16]    ; &nums[2]
    lea     rdx, [nums + 8]     ; &nums[1]
    lea     rsi, [nums]         ; &nums[0]
    lea     rdi, [fmt_in]       ; Format
    
    xor     rax, rax
    call    scanf
    add     rsp, 32             ; Clean stack (3 args + 8 alignment)

    ; -------------------------------------------------------------------------
    ; Printf: printf("...", nums[0], ..., nums[7])
    ; -------------------------------------------------------------------------
    ; Same alignment logic: 3 args on stack.
    
    sub     rsp, 8              ; Align stack
    
    push    qword [nums + 56]   ; n7
    push    qword [nums + 48]   ; n6
    push    qword [nums + 40]   ; n5
    
    mov     r9,  [nums + 32]    ; n4
    mov     r8,  [nums + 24]    ; n3
    mov     rcx, [nums + 16]    ; n2
    mov     rdx, [nums + 8]     ; n1
    mov     rsi, [nums]         ; n0
    lea     rdi, [fmt_out]      ; Format
    
    xor     rax, rax
    call    printf
    add     rsp, 32             ; Clean stack
    
    xor     rax, rax
    leave
    ret
