# -----------------------------------------------------------------------------
# File: constants.inc
# Description: System constants for MIPS32 (Linux O32 ABI)
# -----------------------------------------------------------------------------

# --- Syscall Numbers ---
.eqv SYS_EXIT,  4001
.eqv SYS_READ,  4003
.eqv SYS_WRITE, 4004
.eqv SYS_OPEN,  4005
.eqv SYS_CLOSE, 4006
.eqv SYS_BRK,   4045    # Used for memory allocation (heap)

# --- File Descriptors ---
.eqv STDIN,     0
.eqv STDOUT,    1
.eqv STDERR,    2

# --- Open Flags (MIPS32 Linux) ---
.eqv O_RDONLY,  0x0000
.eqv O_WRONLY,  0x0001
.eqv O_RDWR,    0x0002
.eqv O_APPEND,  0x0008
.eqv O_CREAT,   0x0100  # Create file if it doesn't exist
.eqv O_TRUNC,   0x0200  # Truncate file

# --- Boolean ---
.eqv TRUE,      1
.eqv FALSE,     0
