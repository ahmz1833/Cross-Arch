# -----------------------------------------------------------------------------
# Example 10: Basic File Operation (Syscalls)
# Linking Type: Nolibc (Static)
# Demonstrates:
# - Direct Linux Syscalls for File I/O (open, write, read, close)
# - Writing to a file ("write.txt")
# - Reading from a file ("read.txt")
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
    # Filenames
    file_write:     .asciiz "write.txt"
    file_read:      .asciiz "read.txt"

    # Content to write
    write_text:     .ascii "Hello from MIPS Syscalls!\n"
    write_len = . - write_text

    # Messages
    msg_done_write: .asciiz "Successfully wrote to 'write.txt'\n"
    msg_start_read: .asciiz "Reading content of 'read.txt':\n"
    msg_err_write:  .asciiz "Error: Could not open 'write.txt' for writing.\n"
    msg_err_read:   .asciiz "Error: Could not open 'read.txt' for reading.\n"
    
    # Buffer for reading
    buffer:         .space 256

.text
.globl __start

__start:
    # -------------------------------------------------------------------------
    # Part 1: Write to "write.txt"
    # -------------------------------------------------------------------------
    
    # Open file for writing (O_WRONLY | O_CREAT | O_TRUNC)
    # Mode: 0644 (rw-r--r--)
    sys_open    file_write, O_WRONLY|O_CREAT|O_TRUNC, 0644
    
    # Check for error (negative return value)
    bltz        $v0, error_write
    move        $s0, $v0        # Save FD to $s0

    # Write content
    # sys_write(fd, buffer, length)
    li          $t0, write_len
    sys_write   $s0, write_text, $t0

    # Close file
    sys_close   $s0

    # Print success message
    print_str   msg_done_write

    # -------------------------------------------------------------------------
    # Part 2: Read from "read.txt"
    # -------------------------------------------------------------------------

    # Open file for reading (O_RDONLY)
    sys_open    file_read, O_RDONLY, 0
    
    # Check for error
    bltz        $v0, error_read
    move        $s0, $v0        # Save FD to $s0

    # Print "Reading..." message
    print_str   msg_start_read

    # Read content
    # sys_read(fd, buffer, length)
    li          $t0, 256
    sys_read    $s0, buffer, $t0
    
    move        $s1, $v0        # Save bytes read

    # Write content to STDOUT
    # sys_write(STDOUT, buffer, bytes_read)
    la $a0, buffer
    print_str   $a0

    # Close file
    sys_close   $s0
    
    b           exit

error_write:
    print_str   msg_err_write
    li          $a0, 1
    b           do_exit
    
error_read:
    print_str   msg_err_read
    li          $a0, 1
    b           do_exit

exit:
    li          $a0, 0
do_exit:
    sys_exit
