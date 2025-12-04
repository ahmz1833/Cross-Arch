# Basic MIPS Program - Hello World

.data
    message: .asciiz "Hello, MIPS World!\n"

.text
.globl main

main:
    # Print the message
    la $a0, message     # load address of message into $a0
    jal printf         # call printf function
    
    # Exit program
    li $v0, 10          # syscall code 10 = exit
    syscall
