# -----------------------------------------------------------------------------
# Example 05: Array Summation
# Linking Type: Nolibc
# Demonstrates:
# - Defining arrays in the data segment
# - Accessing memory using load/store instructions
# - Iterating through an array with a loop
# - Accumulating a result (sum)
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
    # Define an array of 32-bit integers (words)
    my_array:   .word 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
    
    # Calculate array size (number of elements)
    # (Current Address - Start Address) / 4
    array_end:
    array_len:  .word (array_end - my_array) / 4

    msg_start:  .asciiz "Summing array elements...\n"
    msg_elem:   .asciiz "Element: "
    msg_sum:    .asciiz "Total Sum: "

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

    print_str msg_start

    # Initialize registers
    la      $t0, my_array       # $t0 = Address of current element
    lw      $t1, array_len      # $t1 = Number of elements (Loop counter)
    li      $s0, 0              # $s0 = Sum accumulator

loop_start:
    beqz    $t1, loop_end       # If counter == 0, exit loop
    nop

    # Load current element
    lw      $t2, 0($t0)         # $t2 = *t0

    # Print current element (Optional, for visualization)
    # print_str msg_elem
    # print_int $t2
    # print_newline

    # Add to sum
    addu    $s0, $s0, $t2

    # Advance pointer and decrement counter
    addiu   $t0, $t0, 4         # Move to next word (4 bytes)
    addiu   $t1, $t1, -1        # Decrement counter
    
    b       loop_start
    nop

loop_end:
    # Print result
    print_str msg_sum
    print_int $s0
    print_newline

    leave
    li      $v0, 0
    ret
