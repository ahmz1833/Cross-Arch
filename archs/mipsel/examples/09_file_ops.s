# -----------------------------------------------------------------------------
# Example 09: Basic File Operation
# Linking Type: Libc
# Demonstrates:
# - Command line arguments (argc, argv)
# - File I/O using libc (fopen, fgets, fclose)
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
    msg_usage:  .asciiz "Usage: %s <filename>\n"
    msg_err:    .asciiz "Error: Could not open file '%s'\n"
    mode_r:     .asciiz "r"
    fmt_str:    .asciiz "%s"
    buffer:     .space 256

.text
.globl main

main:
    enter

    # Save Callee-Saved Registers ($s0-$s3)
    push    $s0
    push    $s1
    push    $s2
    push    $s3

    # Save argc ($a0) and argv ($a1)
    move    $s0, $a0    # argc
    move    $s1, $a1    # argv

    # 1. Check argc >= 2
    li      $t0, 2
    bge     $s0, $t0, open_file

    # Print Usage
    lw      $a1, 0($s1) # argv[0] (program name)
    la      $a0, msg_usage
    call    printf
    li      $v0, 1      # Return 1
    b       cleanup

open_file:
    # 2. Open File
    lw      $s2, 4($s1) # argv[1] (filename)
    
    # fopen(filename, "r")
    move    $a0, $s2
    la      $a1, mode_r
    call    fopen
    
    # Check for NULL
    beqz    $v0, file_error
    move    $s3, $v0    # Save file pointer to $s3

read_loop:
    # 3. Read Line
    # fgets(buffer, 256, fp)
    la      $a0, buffer
    li      $a1, 256
    move    $a2, $s3
    call    fgets
    
    # Check for NULL (EOF or error)
    beqz    $v0, close_file
    
    # 4. Print Line
    # printf("%s", buffer)
    la      $a0, fmt_str
    la      $a1, buffer
    call    printf
    
    b       read_loop

close_file:
    # 5. Close File
    move    $a0, $s3
    call    fclose
    li      $v0, 0
    b       cleanup

file_error:
    # Print Error
    move    $a1, $s2    # filename
    la      $a0, msg_err
    call    printf
    li      $v0, 1

cleanup:
    # Restore Callee-Saved Registers
    pop     $s3
    pop     $s2
    pop     $s1
    pop     $s0

    leave
    ret
