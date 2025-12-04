# -----------------------------------------------------------------------------
# Example 04: Functions and Recursion
# Linking Type: Libc
# Demonstrates:
# - Defining and calling functions
# - Printing and Scanning using libc functions (printf, scanf)
# - Handling command-line arguments (argc, argv)
# - Recursive function (factorial)
# - Stack frame management with enter/leave
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
msg_prompt: .asciiz "Calculating Factorial...\n"
msg_input:  .asciiz "Enter a number: "
fmt_result: .asciiz "Factorial of %d is: %d\n"
fmt_int:    .asciiz "%d"

.text
.globl main
main:
    # Allocate one place (8-byte aligned) for local int variable (for scanf)
    enter 1

    # Check argc ($a0)
    li      $t0, 1
    bgt     $a0, $t0, use_arg
    nop

    # Case: No arguments. Prompt and Scanf.
    call printf, msg_input
    
    # Calculate address of local variable (it's at $sp)
    # scanf("%d", &local_var)
    move    $a1, $sp 
    call scanf, fmt_int, $a1
    
    # Load the value
    lw      $s0, 0($sp)
    b       calculate
    nop

use_arg:
    # Case: Argument provided. argv[1] is at 4($a1)
    # atoi(argv[1])
    lw      $a0, 4($a1)
    call atoi, $a0
    move    $s0, $v0

calculate:
    # $s0 holds the number n
    call printf, msg_prompt

    # Call factorial(n)
    call factorial, $s0
    
    # Result is in $v0
    move    $s1, $v0

    # printf("Factorial of %d is: %d\n", n, result)
    call printf, fmt_result, $s0, $s1

    leave
    li      $v0, 0
    ret

# -----------------------------------------------------------------------------
# Function: factorial
# Arguments:
#   $a0 - n
# Returns:
#   $v0 - n!
# -----------------------------------------------------------------------------
factorial:
    # 1. Setup Stack Frame
    enter
    
    # 2. Save Callee-Saved Registers
    # We use $s0 to store 'n' across the recursive call
    push    $s0

    # 3. Base Case: if n <= 1 return 1
    li      $t0, 1
    ble     $a0, $t0, fact_base
    nop

    # 4. Recursive Step
    move    $s0, $a0        # Save n in $s0
    
    addiu   $a0, $s0, -1    # Calculate n - 1
    jal     factorial       # Recursive call: factorial(n-1)
    nop
    
    # Result is in $v0
    mul     $v0, $s0, $v0   # v0 = n * factorial(n-1)
    
    b       fact_end
    nop

fact_base:
    li      $v0, 1

fact_end:
    # 5. Restore Callee-Saved Registers
    pop     $s0

    # 6. Teardown Stack Frame and Return
    leave
    ret
