# -----------------------------------------------------------------------------
# File: functions.inc
# Description: Common subroutines. Include this ONCE at the end of .text
# -----------------------------------------------------------------------------

    .text
    .align 2

# -----------------------------------------------------------------------------
# Function: fn_print_str
# Description: Prints a null-terminated string to stdout.
# Arguments:
#   $a0 - Address of the null-terminated string
# Returns:
#   None
# -----------------------------------------------------------------------------
fn_print_str:
    addiu   $sp, $sp, -12
    sw      $ra, 8($sp)
    sw      $s0, 4($sp)
    sw      $a0, 0($sp)

    move    $s0, $a0        # Cursor
_pstr_loop:
    lb      $t0, 0($s0)
    beqz    $t0, _pstr_end
    addiu   $s0, $s0, 1
    b       _pstr_loop
    nop
_pstr_end:
    lw      $a1, 0($sp)     # Start
    subu    $a2, $s0, $a1   # Length
    li      $v0, SYS_WRITE
    li      $a0, STDOUT
    syscall
    
    lw      $s0, 4($sp)
    lw      $ra, 8($sp)
    addiu   $sp, $sp, 12
    jr      $ra
    nop

# -----------------------------------------------------------------------------
# Function: fn_print_newline
# Description: Prints a newline character ('\n') to stdout.
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
fn_print_newline:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)
    .data
    _nl_c: .asciiz "\n"
    .text
    la      $a0, _nl_c
    jal     fn_print_str
    nop
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    jr      $ra
    nop

# -----------------------------------------------------------------------------
# Function: fn_read_line
# Description: Reads a line from stdin into a buffer.
#              Stops at newline or max size. Null-terminates the result.
# Arguments:
#   $a0 - Address of the buffer
#   $a1 - Max size of the buffer (including null terminator)
# Returns:
#   $v0 - Number of bytes read (excluding null terminator)
# -----------------------------------------------------------------------------
fn_read_line:
    addiu   $sp, $sp, -16
    sw      $ra, 12($sp)
    sw      $s0, 8($sp)   # Buffer ptr
    sw      $s1, 4($sp)   # Max size
    sw      $s2, 0($sp)   # Count

    move    $s0, $a0
    move    $s1, $a1
    li      $s2, 0

_rl_loop:
    # Check if full (leave space for null terminator)
    addiu   $t0, $s2, 1
    beq     $t0, $s1, _rl_done
    nop

    # Read 1 char
    li      $v0, SYS_READ
    li      $a0, STDIN
    move    $a1, $s0      # Read directly into buffer
    li      $a2, 1
    syscall

    # Check for error or EOF (v0 <= 0)
    blez    $v0, _rl_done
    nop

    lb      $t0, 0($s0)
    
    # Check for newline
    li      $t1, 10       # \n
    beq     $t0, $t1, _rl_done_newline
    nop

    addiu   $s0, $s0, 1
    addiu   $s2, $s2, 1
    b       _rl_loop
    nop

_rl_done_newline:
    # Store newline
    addiu   $s0, $s0, 1
    addiu   $s2, $s2, 1

_rl_done:
    # Null terminate
    sb      $zero, 0($s0)
    
    move    $v0, $s2      # Return count

    lw      $s2, 0($sp)
    lw      $s1, 4($sp)
    lw      $s0, 8($sp)
    lw      $ra, 12($sp)
    addiu   $sp, $sp, 16
    jr      $ra
    nop

# -----------------------------------------------------------------------------
# Function: fn_read_char
# Description: Reads a single character from stdin.
# Arguments:
#   None
# Returns:
#   $v0 - The character read
# -----------------------------------------------------------------------------
fn_read_char:
    addiu   $sp, $sp, -4
    li      $v0, SYS_READ
    li      $a0, STDIN
    move    $a1, $sp      # Buffer is stack top
    li      $a2, 1        # Length 1
    syscall
    lb      $v0, 0($sp)
    addiu   $sp, $sp, 4
    jr      $ra
    nop

# -----------------------------------------------------------------------------
# Function: fn_print_int
# Description: Prints an integer in a specified base.
# Arguments:
#   $a0 - The integer to print
#   $a1 - The base (e.g., 10, 16, 2). If 0, defaults to 10.
#   $a2 - Minimum width (pads with '0' if fewer digits). Default 0.
# Returns:
#   None
# Notes:
#   - Handles negative numbers only for base 10.
#   - Supports bases up to 16 (prints A-F for 10-15).
# -----------------------------------------------------------------------------
fn_print_int:
    addiu   $sp, $sp, -24
    sw      $ra, 20($sp)
    sw      $s0, 16($sp)
    sw      $s1, 12($sp)
    sw      $s2, 8($sp)
    sw      $s3, 4($sp)
    
    move    $s0, $a0        # Number
    move    $s1, $a1        # Base
    move    $s3, $a2        # Min Width

    # Default base 10 if $a1 is 0
    bnez    $s1, _pint_check_base
    nop
    li      $s1, 10

_pint_check_base:
    # Handle 0 explicitly
    bnez    $s0, _pint_sign
    nop
    
    # If 0, push '0' and jump to print
    li      $t0, '0'
    push    $t0
    li      $s2, 1          # 1 digit
    b       _pint_print_stack
    nop

_pint_sign:
    # Only handle negative for base 10
    li      $t0, 10
    bne     $s1, $t0, _pint_conv
    nop
    bgez    $s0, _pint_conv
    nop
    
    # Print minus sign
    li      $a0, '-'
    move    $s2, $s0        # Save s0
    jal     _fn_putc
    nop
    move    $s0, $s2
    neg     $s0, $s0

_pint_conv:
    li      $s2, 0          # Digit count

_pint_loop:
    beqz    $s0, _pint_print_stack
    nop
    
    divu    $s0, $s1        # Unsigned division for bases
    mflo    $s0             # Quotient
    mfhi    $t0             # Remainder

    # Convert to ASCII
    li      $t1, 10
    blt     $t0, $t1, _pint_digit
    nop
    addiu   $t0, $t0, 7     # 'A' - 10 - '0' = 7 offset for hex

_pint_digit:
    addiu   $t0, $t0, 48    # + '0'
    push    $t0
    addiu   $s2, $s2, 1
    b       _pint_loop
    nop

_pint_print_stack:
    # Padding logic
    # $s2 has digit count. $s3 has min width.
    
_pint_pad_loop:
    bge     $s2, $s3, _pint_pop_loop
    nop
    
    li      $a0, '0'
    jal     _fn_putc
    nop
    
    addiu   $s3, $s3, -1    # Decrease remaining width requirement
    b       _pint_pad_loop
    nop

_pint_pop_loop:
    beqz    $s2, _pint_end
    nop
    pop     $a0
    jal     _fn_putc
    nop
    addiu   $s2, $s2, -1
    b       _pint_pop_loop
    nop

_pint_end:
    lw      $s3, 4($sp)
    lw      $s2, 8($sp)
    lw      $s1, 12($sp)
    lw      $s0, 16($sp)
    lw      $ra, 20($sp)
    addiu   $sp, $sp, 24
    jr      $ra
    nop

# -----------------------------------------------------------------------------
# Helper: _fn_putc
# Description: Prints a single character to stdout.
# Arguments:
#   $a0 - The character to print
# Returns:
#   None
# -----------------------------------------------------------------------------
_fn_putc:
    addiu   $sp, $sp, -4
    sb      $a0, 0($sp)
    li      $v0, SYS_WRITE
    li      $a0, STDOUT
    move    $a1, $sp
    li      $a2, 1
    syscall
    addiu   $sp, $sp, 4
    jr      $ra
    nop
