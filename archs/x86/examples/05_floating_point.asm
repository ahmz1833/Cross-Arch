; -----------------------------------------------------------------------------
; Example 05: Floating Point Arithmetic (with libc)
; Mode: Nasm-GCC (Links with libc)
; Demonstrates SSE/AVX floating point instructions and registers (xmm).
; -----------------------------------------------------------------------------

; We are using libc functions, so we need to declare them as external.
extern printf
extern exit

section .data
    ; Format strings for printf
    fmt_float   db  "Float Value: %f", 10, 0
    fmt_double  db  "Double Value: %lf", 10, 0
    fmt_calc    db  "Calculation: %f + %f = %f", 10, 0
    
    ; Single Precision (32-bit) - 'dd'
    val_f1      dd  3.14159
    val_f2      dd  2.5
    
    ; Double Precision (64-bit) - 'dq'
    val_d1      dq  123.456
    val_d2      dq  10.0

section .text
default rel
global main     ; GCC expects 'main' as entry point, not '_start'

main:
    push    rbp             ; Align stack (System V ABI requires 16-byte alignment)
    mov     rbp, rsp

    ; -------------------------------------------------------------------------
    ; 1. Printing a Double (64-bit)
    ; -------------------------------------------------------------------------
    ; Arguments for printf:
    ; rdi = format string
    ; xmm0 = first floating point argument
    ; rax = number of vector registers used (for varargs)
    
    mov     rdi, fmt_double
    movsd   xmm0, [val_d1]  ; Load scalar double
    mov     rax, 1          ; 1 vector register used
    call    printf

    ; -------------------------------------------------------------------------
    ; 2. Single Precision Arithmetic
    ; -------------------------------------------------------------------------
    ; Note: printf expects doubles for %f. We must convert float to double.
    ; cvtss2sd: Convert Scalar Single to Scalar Double
    
    movss   xmm0, [val_f1]  ; Load float (32-bit) into xmm0
    cvtss2sd xmm0, xmm0     ; Convert to double for printing
    
    mov     rdi, fmt_float
    mov     rax, 1
    call    printf

    ; -------------------------------------------------------------------------
    ; 3. Basic Calculation (Addition)
    ; -------------------------------------------------------------------------
    ; Let's do: val_f1 + val_f2
    
    movss   xmm0, [val_f1]  ; Load 3.14159
    movss   xmm1, [val_f2]  ; Load 2.5
    
    ; Save original values for printing later (need to convert to double)
    cvtss2sd xmm2, xmm0     ; xmm2 = val_f1 (double)
    cvtss2sd xmm3, xmm1     ; xmm3 = val_f2 (double)
    
    addss   xmm0, xmm1      ; xmm0 = xmm0 + xmm1
    
    cvtss2sd xmm0, xmm0     ; Convert result to double
    
    ; Print: "Calculation: %f + %f = %f"
    ; rdi = fmt
    ; xmm0 = result
    ; xmm1 = val_f1 (arg 2) -> wait, order matters in printf call?
    ; printf(fmt, arg1, arg2, arg3)
    ; xmm0 = arg1, xmm1 = arg2, xmm2 = arg3
    
    ; We need to rearrange registers for the call
    ; Wanted: printf(fmt, val_f1, val_f2, result)
    
    movapd  xmm4, xmm0      ; Save result temporarily
    
    movapd  xmm0, xmm2      ; Arg1: val_f1
    movapd  xmm1, xmm3      ; Arg2: val_f2
    movapd  xmm2, xmm4      ; Arg3: result
    
    mov     rdi, fmt_calc
    mov     rax, 3          ; 3 vector registers used
    call    printf

    ; -------------------------------------------------------------------------
    ; 4. Integer to Float Conversion
    ; -------------------------------------------------------------------------
    mov     rax, 42
    cvtsi2sd xmm0, rax      ; Convert Scalar Integer (rax) to Scalar Double (xmm0)
    
    mov     rdi, fmt_double
    mov     rax, 1
    call    printf

    ; Exit
    xor     rax, rax        ; Return 0
    pop     rbp
    ret
