/*********************************************************************
* Example 01: Hello World (Libc)
* Linking Type: Libc
* Demonstrates:
* - Standard C-style main function
* - Calling standard library functions (printf)
* - Stack frame management with enter/leave
*********************************************************************/

.include "macros.inc"

.data
msg: .asciz "Hello, s390x Libc World!\n"

.text
.global main

main:
    enter
    call printf msg
    xgr %r2, %r2
    leave
    ret
