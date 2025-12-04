# -----------------------------------------------------------------------------
# Example 02: Input and Output
# Linking Type: Nolibc
# Demonstrates:
# - Reading strings with read_line
# - Reading characters with read_char
# - Printing integers (ASCII values)
# - Using the variadic call macro
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
    prompt_name: .asciiz "Enter your name: "
    greeting:    .asciiz "Hello, "
    prompt_char: .asciiz "Enter a character to see its ASCII code: "
    msg_ascii_dec:   .asciiz "The ASCII code is: "
    msg_ascii_hex:   .asciiz "The ASCII code in hex is: 0x"
    msg_ascii_bin:   .asciiz "The ASCII code in binary is: 0b"
    buffer:      .space 64

.text
.globl main
.globl __start

__start:
    call main
    move $a0, $v0
    sys_exit

main:
    enter

    # 1. Read Name
    print_str prompt_name
    read_line buffer, 64

    # 2. Print Greeting
    print_str greeting
    print_str buffer
    print_newline

    # 3. Read Character
    print_str prompt_char
    read_char $s0

    # 4. Print ASCII Code
    print_newline
    print_str msg_ascii_dec
    print_int $s0
    print_newline

    # 5. Print Hex and Binary representation
    print_str msg_ascii_hex
    print_hex $s0, 2
    print_newline
    print_str msg_ascii_bin
    print_bin $s0, 8
    print_newline

    leave
    li      $v0, 0
    ret
