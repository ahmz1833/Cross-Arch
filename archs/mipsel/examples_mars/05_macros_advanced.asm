# Advanced Macros for MIPS
# More complex and useful macros

.data
    newline: .asciiz "\n"
    space: .asciiz " "

# Print integer macro
.macro print_int(%reg)
    li $v0, 1
    move $a0, %reg
    syscall
.end_macro

# Print string macro
.macro print_str(%str)
    li $v0, 4
    la $a0, %str
    syscall
.end_macro

# Read integer macro
.macro read_int(%reg)
    li $v0, 5
    syscall
    move %reg, $v0
.end_macro

# Print integer with newline
.macro print_int_ln(%reg)
    print_int(%reg)
    print_str(newline)
.end_macro

# Macro to swap two registers
.macro swap(%reg1, %reg2)
    move $t9, %reg1
    move %reg1, %reg2
    move %reg2, $t9
.end_macro

# Macro to find max of two numbers
.macro max(%result, %a, %b)
    bgt %a, %b, max_is_a
    move %result, %b
    j max_done
max_is_a:
    move %result, %a
max_done:
.end_macro

# Macro to print array elements
.macro print_array(%base, %size)
    li $t8, 0           # counter
print_loop:
    beq $t8, %size, print_end
    
    lw $t7, 0(%base)    # load array element
    print_int($t7)
    print_str(space)
    
    addi %base, %base, 4    # move to next element
    addi $t8, $t8, 1        # increment counter
    j print_loop
print_end:
    print_str(newline)
.end_macro

.text
.globl main

main:
    # Test swap macro
    li $t0, 10
    li $t1, 20
    
    print_str(newline)
    print_int($t0)
    print_str(space)
    print_int_ln($t1)
    
    swap($t0, $t1)
    
    print_int($t0)
    print_str(space)
    print_int_ln($t1)
    
    # Exit
    li $v0, 10
    syscall
