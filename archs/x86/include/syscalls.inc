; -----------------------------------------------------------------------------
; File: syscalls.inc
; Description: Wrappers for Linux x86_64 Syscalls
; Requires: constants.inc
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Process Control
; -----------------------------------------------------------------------------

; sys_exit(status)
%macro sys_exit 1
    mov     rax, SYS_EXIT
    mov     rdi, %1
    syscall
%endmacro

; -----------------------------------------------------------------------------
; File I/O
; -----------------------------------------------------------------------------

; sys_write(fd, buffer, length)
%macro sys_write 3
    mov     rax, SYS_WRITE
    mov     rdi, %1
    mov     rsi, %2
    mov     rdx, %3
    syscall
%endmacro

; sys_read(fd, buffer, length)
%macro sys_read 3
    mov     rax, SYS_READ
    mov     rdi, %1
    mov     rsi, %2
    mov     rdx, %3
    syscall
%endmacro

; sys_open(filename, flags, mode)
%macro sys_open 3
    mov     rax, SYS_OPEN
    mov     rdi, %1
    mov     rsi, %2
    mov     rdx, %3
    syscall
%endmacro

; sys_close(fd)
%macro sys_close 1
    mov     rax, SYS_CLOSE
    mov     rdi, %1
    syscall
%endmacro
