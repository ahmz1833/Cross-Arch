# MIPS Sections Explained
# .data section: for declaring variables and constants
# .text section: for program instructions
# .globl: makes a label visible to other files (like main)

.data
    # Different data types in .data section
    byte_var: .byte 65          # Single byte (character 'A')
    half_var: .half 1000        # Half word (2 bytes)
    word_var: .word 50000       # Word (4 bytes)
    float_var: .float 3.14      # Floating point number
    double_var: .double 2.71828 # Double precision float
    
    string_var: .asciiz "This is a string\n"  # Null-terminated string
    string_var2: .ascii "This is a string without null terminator"  # Non-null-terminated string
    array: .word 1, 2, 3, 4, 5  # Array of 5 words
    
    # Reserve space without initialization
    buffer: .space 100          # Reserve 100 bytes

.text
.globl main

main:
    # Print string
    li $v0, 4
    la $a0, string_var
    syscall
    
    # Load and print byte
    li $v0, 11          # print character
    lb $a0, byte_var    # load byte
    syscall
    
    li $v0, 4
    li $a0, '\n'
    syscall
    
    # Load and print word
    li $v0, 1
    lw $a0, word_var    # load word
    syscall
    
    # Exit
    li $v0, 10
    syscall
