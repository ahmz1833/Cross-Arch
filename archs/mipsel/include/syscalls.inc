# -----------------------------------------------------------------------------
# File: syscalls.inc
# Description: Wrappers for raw Linux Kernel Syscalls
# Requires: constants.inc
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Process Control
# -----------------------------------------------------------------------------
.macro sys_exit
    li      $v0, SYS_EXIT
    syscall
.endm

# -----------------------------------------------------------------------------
# File I/O
# -----------------------------------------------------------------------------

# sys_write(fd, buffer, length)
.macro sys_write fd, buf, len
    move    $a0, \fd        # Use move in case reg is passed
    la      $a1, \buf       # Assume label/address
    move    $a2, \len       # Length
    li      $v0, SYS_WRITE
    syscall
.endm

# sys_read(fd, buffer, length)
# Returns: Number of bytes read in $v0
.macro sys_read fd, buf, len
    move    $a0, \fd
    la      $a1, \buf
    move    $a2, \len
    li      $v0, SYS_READ
    syscall
.endm

# sys_open(filename, flags, mode)
# Returns: File Descriptor in $v0 (negative if error)
# Mode is usually 0644 (rw-r--r--)
.macro sys_open filename, flags, mode
    la      $a0, \filename
    li      $a1, \flags
    li      $a2, \mode
    li      $v0, SYS_OPEN
    syscall
.endm

# sys_close(fd)
.macro sys_close fd
    move    $a0, \fd
    li      $v0, SYS_CLOSE
    syscall
.endm

# -----------------------------------------------------------------------------
# Memory Management (Heap)
# -----------------------------------------------------------------------------

# sys_brk(address)
# If address is 0, returns current break (end of heap).
# If address is > 0, sets new break to that address.
.macro sys_brk address
    move    $a0, \address
    li      $v0, SYS_BRK
    syscall
.endm
