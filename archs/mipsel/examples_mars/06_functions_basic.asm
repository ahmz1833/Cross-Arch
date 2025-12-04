# Basic Functions in MIPS
# Demonstrates function calls and return values

.data
    msg1: .asciiz "Calling add function with 5 and 7\n"
    msg2: .asciiz "Result: "
    newline: .asciiz "\n"

.text
.globl main

main:
    # Print message
    li $v0, 4
    la $a0, msg1
    syscall
    
    # Call add function
    li $a0, 5           # first argument
    li $a1, 7           # second argument
    jal add_function    # jump and link (saves return address in $ra)
    
    # Result is in $v0
    move $t0, $v0
    
    # Print result message
    li $v0, 4
    la $a0, msg2
    syscall
    
    # Print result
    li $v0, 1
    move $a0, $t0
    syscall
    
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    
    # Exit
    li $v0, 10
    syscall

# Function: add_function
# Arguments: $a0 = first number, $a1 = second number
# Returns: $v0 = sum
add_function:
    add $v0, $a0, $a1   # add arguments and store in return register
    jr $ra              # return to caller
