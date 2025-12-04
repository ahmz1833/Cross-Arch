# -----------------------------------------------------------------------------
# Example 08: Floating Point Operations
# Linking Type: Libc
# Demonstrates:
# - Using Coprocessor 1 (FPU) for floating point arithmetic
# - Loading single precision floats (.float)
# - Converting float to double (required for printf)
# - Passing double to variadic function (printf) observing O32 alignment
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
    val1:       .float 12.5
    val2:       .float 2.25
    msg_op:     .asciiz "Calculating: 12.5 + 2.25\n"
    fmt_res:    .asciiz "Result: %f\n"

.text
.globl main

main:
    enter

    # 1. Print Operation
    call    printf, msg_op

    # 2. Load Floats
    # lwc1: Load Word to Coprocessor 1
    lwc1    $f0, val1
    lwc1    $f2, val2

    # 3. Perform Addition (Single Precision)
    add.s   $f4, $f0, $f2       # $f4 = 12.5 + 2.25 = 14.75

    # 4. Prepare for printf
    # printf expects 'double' for %f.
    # We must convert single ($f4) to double ($f4, $f5 pair).
    cvt.d.s $f4, $f4            # Result is now in $f4 (low) and $f5 (high)

    # 5. Move to Integer Registers
    # Workaround for assembler error "float register should be even" on mfc1 $f5
    # We store the double to stack and load it back to integer registers.
    
    # Store double ($f4, $f5) to stack (needs 8 bytes)
    addiu   $sp, $sp, -8
    sdc1    $f4, 0($sp)     # Store Double Coprocessor 1
    
    # Load into integer registers
    lw      $t0, 0($sp)     # Low
    lw      $t1, 4($sp)     # High
    addiu   $sp, $sp, 8     # Restore stack

    # 6. Call printf
    # We pass '0' as the second argument to ensure $t0/$t1 land in $a2/$a3
    call    printf, fmt_res, 0, $t0, $t1

    leave
    li      $v0, 0
    ret
