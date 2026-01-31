/*
 * constants.inc - s390x System Constants
 */

/* Syscall Numbers (Linux s390x) */
.equ I_SYS_EXIT,  1
.equ I_SYS_READ,  3
.equ I_SYS_WRITE, 4
.equ I_SYS_OPEN,  5
.equ I_SYS_CLOSE, 6

/* File Descriptors */
.equ I_STDIN,     0
.equ I_STDOUT,    1
.equ I_STDERR,    2

/* Boolean */
.equ I_TRUE,      1
.equ I_FALSE,     0
