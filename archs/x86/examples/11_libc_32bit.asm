; -----------------------------------------------------------------------------
; Example 11: Libc in 32-bit Mode
; Demonstrates calling C functions (printf, scanf) using the cdecl convention.
; 
; Build: lab-build -m nasm-gcc -t i386 examples/11_libc_32bit.asm -o 11.elf
; -----------------------------------------------------------------------------

extern printf
extern scanf
extern exit

section .data
    msg_prompt  db  "Enter a number: ", 0
    fmt_in      db  "%d", 0
    msg_out     db  "You entered: %d", 10, 0
    msg_debug   db  "Debug: Stack is aligned.", 10, 0

section .bss
    num         resd 1

section .text
    global main

main:
    ; -------------------------------------------------------------------------
    ; Function Prologue
    ; -------------------------------------------------------------------------
    push    ebp
    mov     ebp, esp
    
    ; Stack Alignment Note:
    ; GCC's main entry point usually aligns ESP to 16 bytes.
    ; Pushing EBP (4 bytes) makes it misaligned by 4.
    ; However, for simple 32-bit calls, 4-byte alignment is often sufficient 
    ; unless SSE instructions are used by libc.
    ; To be safe and strictly compliant with modern GCC, we can align ESP.
    and     esp, -16        ; Align ESP to 16-byte boundary

    ; -------------------------------------------------------------------------
    ; Print Prompt
    ; printf("Enter a number: ");
    ; -------------------------------------------------------------------------
    push    msg_prompt      ; Push address of string
    call    printf
    add     esp, 4          ; Clean up stack (1 arg * 4 bytes)

    ; -------------------------------------------------------------------------
    ; Read Input
    ; scanf("%d", &num);
    ; -------------------------------------------------------------------------
    lea     eax, [num]      ; Load address of num
    push    eax             ; Push &num
    push    fmt_in          ; Push format string
    call    scanf
    add     esp, 8          ; Clean up stack (2 args * 4 bytes)

    ; -------------------------------------------------------------------------
    ; Print Result
    ; printf("You entered: %d\n", num);
    ; -------------------------------------------------------------------------
    mov     eax, [num]      ; Load value of num
    push    eax             ; Push value
    push    msg_out         ; Push format string
    call    printf
    add     esp, 8          ; Clean up stack

    ; -------------------------------------------------------------------------
    ; Exit
    ; -------------------------------------------------------------------------
    xor     eax, eax        ; Return 0
    mov     esp, ebp        ; Restore stack pointer (undo alignment)
    pop     ebp             ; Restore base pointer
    ret
