# -----------------------------------------------------------------------------
# Example 03: Control Flow
# Linking Type: Nolibc
# Demonstrates:
# - Looping from 0 to 9
# - Conditional branches to check even/odd
# - Printing results
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
msg_start:  .asciiz "Starting loop from 0 to 9:\n"
msg_even:   .asciiz " is Even\n"
msg_odd:    .asciiz " is Odd\n"
msg_done:   .asciiz "Done!\n"

.text
.globl main
.globl __start

__start:
	call main
	move $a0, $v0
	sys_exit

# -----------------------------------------------------------------------------
# Function: main
# -----------------------------------------------------------------------------
main:
	enter

    # Print start message
    print_str msg_start

    # Initialize counter $s0 = 0
    li      $s0, 0
    li      $s1, 10     # Limit

loop_start:
    beq     $s0, $s1, loop_end
    nop

    # Print current number
    print_int $s0

    # Check if even or odd
    andi    $t0, $s0, 1
    beqz    $t0, is_even
    nop

is_odd:
    print_str msg_odd
    b       loop_continue
    nop

is_even:
    print_str msg_even

loop_continue:
    addiu   $s0, $s0, 1
    b       loop_start
    nop

loop_end:
    print_str msg_done
    
	leave
    li      $v0, 0
	ret
