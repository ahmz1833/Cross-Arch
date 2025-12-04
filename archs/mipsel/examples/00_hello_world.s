# -----------------------------------------------------------------------------
# Example 00: Hello World (Bare Metal / No Libc)
# Linking Type: Nolibc
# Demonstrates:
# - Basic program structure without C Runtime
# - Entry point __start
# - Using macros for printing
# - Program termination via syscall
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
    msg: .asciiz "Hello, Cross-Arch World!\n"

.text
.globl __start

__start:
    # No stack frame setup needed for __start as it is the entry point.
    
    # 1. Print String
    print_str msg

    # 2. Exit with status 0
	li $a0, 0
    sys_exit
