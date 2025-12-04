# -----------------------------------------------------------------------------
# Example 07: Variadic Function Call (Many Arguments)
# Linking Type: Libc
# Demonstrates:
# - Calling a function with more than 4 arguments
# - Stack argument passing (O32 ABI)
# - Reading 6 numbers and printing them using a custom function
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
    msg_prompt: .asciiz "Enter 6 numbers (space separated): "
    fmt_scan:   .asciiz "%d %d %d %d %d %d"
    fmt_print:  .asciiz "You entered: %d, %d, %d, %d, %d, %d\n"

.text
.globl main

main:
    # Allocate stack for 6 integers (6 * 4 = 24 bytes)
    enter 24

    # 1. Prompt User
    call    printf, msg_prompt

    # 2. Read 6 numbers
    # scanf("%d %d %d %d %d %d", &v1, &v2, &v3, &v4, &v5, &v6)
    # Arguments:
    # $a0: format string
    # $a1: &v1 (0($sp))
    # $a2: &v2 (4($sp))
    # $a3: &v3 (8($sp))
    # Stack: &v4 (12($sp)), &v5 (16($sp)), &v6 (20($sp))
    
    # Prepare addresses
    addiu   $t0, $sp, 0     # &v1
    addiu   $t1, $sp, 4     # &v2
    addiu   $t2, $sp, 8     # &v3
    addiu   $t3, $sp, 12    # &v4
    addiu   $t4, $sp, 16    # &v5
    addiu   $t5, $sp, 20    # &v6

    # Call scanf using our macro (handles stack args automatically)
    call    scanf, fmt_scan, $t0, $t1, $t2, $t3, $t4, $t5

    # 3. Load values to print
    lw      $s0, 0($sp)     # v1
    lw      $s1, 4($sp)     # v2
    lw      $s2, 8($sp)     # v3
    lw      $s3, 12($sp)    # v4
    lw      $s4, 16($sp)    # v5
    lw      $s5, 20($sp)    # v6

    # 4. Print values
    # printf(fmt, v1, v2, v3, v4, v5, v6)
    call    printf, fmt_print, $s0, $s1, $s2, $s3, $s4, $s5

    leave
    li      $v0, 0
    ret
