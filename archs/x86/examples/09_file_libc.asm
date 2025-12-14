; -----------------------------------------------------------------------------
; Example 09: File I/O with Libc
; 
; Demonstrates:
; 1. Opening a file using fopen.
; 2. Writing to a file using fprintf.
; 3. Reading from a file using fscanf.
; 4. Closing a file using fclose.
; -----------------------------------------------------------------------------

extern fopen
extern fprintf
extern fscanf
extern fclose
extern printf
extern exit

section .data
    filename    db  "test_file.txt", 0
    mode_write  db  "w", 0
    mode_read   db  "r", 0
    
    fmt_write   db  "This is line %d", 10, 0
    fmt_read    db  "Read from file: %s %s %s %d", 10, 0
    fmt_scan    db  "%s %s %s %d", 0    ; Matches "This is line %d"
    
    msg_error   db  "Error opening file!", 10, 0
    msg_done    db  "File I/O complete.", 10, 0

section .bss
    file_handle resq 1
    buffer1     resb 32
    buffer2     resb 32
    buffer3     resb 32
    num_val     resd 1

section .text
    global main

main:
    push    rbp
    mov     rbp, rsp

    ; -------------------------------------------------------------------------
    ; 1. Open File for Writing
    ; FILE *fopen(const char *filename, const char *mode);
    ; -------------------------------------------------------------------------
    mov     rdi, filename
    mov     rsi, mode_write
    call    fopen
    
    test    rax, rax
    jz      .error
    mov     [file_handle], rax

    ; -------------------------------------------------------------------------
    ; 2. Write to File
    ; int fprintf(FILE *stream, const char *format, ...);
    ; -------------------------------------------------------------------------
    mov     rdi, [file_handle]
    mov     rsi, fmt_write
    mov     rdx, 1              ; Line number 1
    xor     rax, rax
    call    fprintf

    ; -------------------------------------------------------------------------
    ; 3. Close File
    ; int fclose(FILE *stream);
    ; -------------------------------------------------------------------------
    mov     rdi, [file_handle]
    call    fclose

    ; -------------------------------------------------------------------------
    ; 4. Open File for Reading
    ; -------------------------------------------------------------------------
    mov     rdi, filename
    mov     rsi, mode_read
    call    fopen
    
    test    rax, rax
    jz      .error
    mov     [file_handle], rax

    ; -------------------------------------------------------------------------
    ; 5. Read from File
    ; int fscanf(FILE *stream, const char *format, ...);
    ; -------------------------------------------------------------------------
    mov     rdi, [file_handle]
    mov     rsi, fmt_scan
    mov     rdx, buffer1        ; "This"
    mov     rcx, buffer2        ; "is"
    mov     r8,  buffer3        ; "line"
    mov     r9,  num_val        ; 1
    xor     rax, rax
    call    fscanf

    ; -------------------------------------------------------------------------
    ; 6. Print what we read
    ; -------------------------------------------------------------------------
    mov     rdi, fmt_read
    mov     rsi, buffer1
    mov     rdx, buffer2
    mov     rcx, buffer3
    mov     r8,  [num_val]      ; Value of number
    xor     rax, rax
    call    printf

    ; -------------------------------------------------------------------------
    ; 7. Close File
    ; -------------------------------------------------------------------------
    mov     rdi, [file_handle]
    call    fclose

    mov     rdi, msg_done
    xor     rax, rax
    call    printf

    xor     rax, rax
    leave
    ret

.error:
    mov     rdi, msg_error
    xor     rax, rax
    call    printf
    
    mov     rax, 1
    leave
    ret
