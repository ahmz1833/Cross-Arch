; -----------------------------------------------------------------------------
; File: constants.inc
; Description: System constants for x86_64 (Linux)
; -----------------------------------------------------------------------------

; --- Syscall Numbers (x86_64) ---
%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN    2
%define SYS_CLOSE   3
%define SYS_STAT    4
%define SYS_FSTAT   5
%define SYS_LSEEK   8
%define SYS_MMAP    9
%define SYS_MPROTECT 10
%define SYS_MUNMAP  11
%define SYS_BRK     12
%define SYS_EXIT    60

; --- File Descriptors ---
%define STDIN       0
%define STDOUT      1
%define STDERR      2

; --- Open Flags ---
%define O_RDONLY    0
%define O_WRONLY    1
%define O_RDWR      2
%define O_CREAT     64
%define O_EXCL      128
%define O_NOCTTY    256
%define O_TRUNC     512
%define O_APPEND    1024

; --- Boolean ---
%define TRUE        1
%define FALSE       0
