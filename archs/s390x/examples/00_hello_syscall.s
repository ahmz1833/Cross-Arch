/*********************************************************************
* Example 00: Hello World (Bare Metal / No Libc)
* Linking Type: Nolibc
* Demonstrates:
* - Basic program structure without C Runtime
* - Entry point _start
* - Using macros for printing
* - Program termination via syscall
*********************************************************************/

.include "macros.inc"

.data
msg: .asciz "Hello, s390x Syscall World!\n"
.equ I_msg_len, . - msg

.text
.global _start

_start:
    /* sys_write(STDOUT, msg, msg_len) */
    _load_arg %r2, 12
    
    sys_write I_STDOUT, msg, I_msg_len
    
    /* sys_exit(0) */
    sys_exit 0
