; -----------------------------------------------------------------------------
; File: functions.inc
; Description: Helper functions for x86_64 assembly
; -----------------------------------------------------------------------------

section .text

; -----------------------------------------------------------------------------
; fn_string_length
; Input: rdi = pointer to string
; Output: rax = length
; -----------------------------------------------------------------------------
fn_string_length:
    xor     rax, rax
.loop:
    cmp     byte [rdi + rax], 0
    je      .done
    inc     rax
    jmp     .loop
.done:
    ret

; -----------------------------------------------------------------------------
; fn_print_string
; Input: rdi = pointer to null-terminated string
; -----------------------------------------------------------------------------
fn_print_string:
    push    rdi
    push    rsi
    push    rdx
    push    rax
    push    rcx
    push    r11

    ; Calculate length
    call    fn_string_length
    mov     rdx, rax        ; Length
    
    mov     rsi, rdi        ; Buffer
    mov     rdi, STDOUT     ; FD
    mov     rax, SYS_WRITE  ; Syscall
    syscall

    pop     r11
    pop     rcx
    pop     rax
    pop     rdx
    pop     rsi
    pop     rdi
    ret

; -----------------------------------------------------------------------------
; fn_print_newline
; -----------------------------------------------------------------------------
fn_print_newline:
    push    rdi
    push    rsi
    push    rdx
    push    rax
    push    rcx
    push    r11
    
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    push    10              ; Push newline char to stack
    mov     rsi, rsp        ; Address of char on stack
    mov     rdx, 1          ; Length
    syscall
    pop     rax             ; Restore stack (remove char)

    pop     r11
    pop     rcx
    pop     rax
    pop     rdx
    pop     rsi
    pop     rdi
    ret

; -----------------------------------------------------------------------------
; fn_print_int
; Input: rdi = integer to print (signed)
; -----------------------------------------------------------------------------
fn_print_int:
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rdi
    push    rsi
    push    r8 
    push    r9
    push    r10

    mov     rax, rdi
    
    ; Handle negative
    test    rax, rax
    jns     .positive
    
    ; Print '-'
    push    rax
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    push    '-'
    mov     rsi, rsp
    mov     rdx, 1
    syscall
    pop     rax         ; remove char
    pop     rax         ; restore number
    neg     rax

.positive:
    mov     rbx, 10     ; Base
    xor     rcx, rcx    ; Digit count

.divide_loop:
    xor     rdx, rdx
    div     rbx         ; rax = rax / 10, rdx = rax % 10
    add     rdx, '0'    ; Convert to ASCII
    push    rdx         ; Push digit
    inc     rcx
    test    rax, rax
    jnz     .divide_loop

.print_loop:
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    mov     rsi, rsp    ; Point to digit on stack
    mov     rdx, 1
    push    rcx         ; Save counter
    syscall
    pop     rcx         ; Restore counter
    pop     rax         ; Remove digit from stack
    dec     rcx
    jnz     .print_loop

    pop     r10
    pop     r9
    pop     r8
    pop     rsi
    pop     rdi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret

; -----------------------------------------------------------------------------
; fn_print_uint_base
; Input: rdi = unsigned integer
;        rsi = base (e.g., 16, 2, 10)
;        rdx = min width (pad with '0')
; -----------------------------------------------------------------------------
fn_print_uint_base:
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rdi
    push    rsi
    push    r8 
    push    r9
    push    r10

    mov     rax, rdi
    mov     rbx, rsi    ; Base
    mov     r8,  rdx    ; Width
    xor     rcx, rcx    ; Digit count

    ; Handle 0 explicitly
    test    rax, rax
    jnz     .divide_loop
    push    '0'
    inc     rcx
    jmp     .check_padding

.divide_loop:
    xor     rdx, rdx
    div     rbx         ; rax = rax / base, rdx = rax % base
    
    ; Convert to ASCII (handle hex > 9)
    cmp     rdx, 9
    jg      .hex_char
    add     rdx, '0'
    jmp     .push_digit
.hex_char:
    add     rdx, 'A' - 10

.push_digit:
    push    rdx         ; Push digit
    inc     rcx
    test    rax, rax
    jnz     .divide_loop

.check_padding:
    ; Check if we need padding
    cmp     rcx, r8
    jge     .print_loop
    
    ; Calculate padding needed
    mov     r9, r8
    sub     r9, rcx     ; r9 = width - digits
    
    push    rcx         ; Save digit count

.padding_loop:
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    push    '0'         ; Push '0' to print (using stack for address)
    mov     rsi, rsp
    mov     rdx, 1
    syscall
    pop     rax         ; Cleanup stack
    dec     r9
    jnz     .padding_loop

    pop     rcx         ; Restore digit count

.print_loop:
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    mov     rsi, rsp    ; Point to digit on stack
    mov     rdx, 1
    push    rcx         ; Save counter
    syscall
    pop     rcx         ; Restore counter
    pop     rax         ; Remove digit from stack
    dec     rcx
    jnz     .print_loop

    pop     r10
    pop     r9
    pop     r8
    pop     rsi
    pop     rdi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret

; -----------------------------------------------------------------------------
; fn_read_line
; Input: rdi = buffer
;        rsi = max size
; Output: rax = bytes read
; -----------------------------------------------------------------------------
fn_read_line:
    push    rdi
    push    rsi
    push    rdx
    push    rcx
    push    rbx
    
    mov     rbx, rdi        ; Buffer pointer
    mov     rcx, rsi        ; Max size
    xor     r8, r8          ; Bytes read count

.read_loop:
    cmp     rcx, 1          ; Leave space for null terminator
    jle     .done_loop

    ; Read 1 byte
    mov     rax, SYS_READ
    mov     rdi, STDIN
    mov     rsi, rbx        ; Current buffer position
    mov     rdx, 1
    push    rcx             ; Save max size counter
    syscall
    pop     rcx             ; Restore max size counter

    cmp     rax, 0          ; Check EOF or error
    jle     .done_loop

    mov     al, [rbx]
    cmp     al, 10          ; Check newline
    je      .newline_found
    
    inc     rbx
    inc     r8
    dec     rcx
    jmp     .read_loop

.newline_found:
    ; We don't increment r8 for newline if we want to exclude it
    ; But usually we consume it.
    ; Let's just stop here.
    jmp     .done_loop

.done_loop:
    mov     byte [rbx], 0   ; Null terminate
    mov     rax, r8         ; Return length (excluding newline)

    pop     rbx
    pop     rcx
    pop     rdx
    pop     rsi
    pop     rdi
    ret

; -----------------------------------------------------------------------------
; fn_read_char
; Output: rax = char (byte)
; -----------------------------------------------------------------------------
fn_read_char:
    push    rdi
    push    rsi
    push    rdx
    
    sub     rsp, 1          ; Reserve 1 byte on stack
    
    mov     rax, SYS_READ
    mov     rdi, STDIN
    mov     rsi, rsp        ; Read into stack
    mov     rdx, 1
    syscall

    xor     rax, rax
    mov     al, [rsp]       ; Load char
    add     rsp, 1          ; Restore stack

    pop     rdx
    pop     rsi
    pop     rdi
    ret
