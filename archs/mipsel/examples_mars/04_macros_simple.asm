# Simple Macros for MIPS
# Macros make code more readable and reusable

.data
    newline: .asciiz "\n"
    prompt: .asciiz "Enter a number: "
    result_msg: .asciiz "You entered: "

# Macro to print an integer
.macro print_int(%reg)
    li $v0, 1
    move $a0, %reg
    syscall
.end_macro

# Macro to print a string
.macro print_str(%str)
    li $v0, 4
    la $a0, %str
    syscall
.end_macro

# Macro to print newline
.macro print_newline
    li $v0, 4
    la $a0, newline
    syscall
.end_macro

# Macro to read an integer
.macro read_int(%reg)
    li $v0, 5           # syscall code 5 = read integer
    syscall
    move %reg, $v0      # store result in specified register
.end_macro

.text
.globl main

main:
    # Prompt user for input
    print_str(prompt)
    
    # Read integer from user
    read_int($t0)
    
    
    # Print result message
    print_str(result_msg)
    
    
    # Print the number
    print_int($t0)
    
    # Print newline
    print_newline
    
    # Exit
    li $v0, 10
    syscall
