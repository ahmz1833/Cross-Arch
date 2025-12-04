# Printing Numbers in MIPS

.data
    msg1: .asciiz "Printing a number: "
    msg2: .asciiz "\nPrinting another number: "
    newline: .asciiz "\n"
    number1: .word 42
    number2: .word 100

.text
.globl main

main:
    # Print first message
    li $v0, 4
    la $a0, msg1
    syscall
    
    # Print first number (loaded from memory)
    li $v0, 1           # syscall code 1 = print integer
    lw $a0, number1     # load word from memory
    syscall
    
    # Print second message
    li $v0, 4
    la $a0, msg2
    syscall
    
    # Print second number (immediate value)
    li $v0, 1
    li $a0, 255         # load immediate value
    syscall
    
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    
    # Exit
    li $v0, 10
    syscall
