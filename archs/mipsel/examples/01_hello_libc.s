# -----------------------------------------------------------------------------
# Example 01: Hello World (Libc)
# Linking Type: Libc
# Demonstrates:
# - Standard C-style main function
# - Calling standard library functions (printf)
# - Stack frame management with enter/leave
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
    msg: .asciiz "Hello, Libc World!\n"

.text
.globl main

main:
    # 1. Setup Stack Frame (Required for main)
    enter

    # 2. Call printf
    # printf(msg)
    la      $a0, msg
    call    printf

    # 3. Return 0
    li      $v0, 0

    # 4. Teardown Stack Frame and Return
    leave
    ret
