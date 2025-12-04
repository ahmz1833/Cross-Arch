# -----------------------------------------------------------------------------
# File: macros.inc
# Description: Useful Macros for MIPS architecture assembly programming
# -----------------------------------------------------------------------------

.include "constants.inc"
.include "syscalls.inc"

# -----------------------------------------------------------------------------
# Stack Helpers
# -----------------------------------------------------------------------------
.macro push reg
    addiu   $sp, $sp, -8
    sw      \reg, 0($sp)
.endm

.macro pop reg
    lw      \reg, 0($sp)
    addiu   $sp, $sp, 8
.endm

# -----------------------------------------------------------------------------
# Argument Loading Helper
# -----------------------------------------------------------------------------

# Helper macro to load arguments (Register or Immediate/Label)
.macro _load_arg reg, val
    .ifc \val, ""
        .exitm
    .endif

    _is_reg = 0
    .irpc char, \val
        .ifc \char, $
            _is_reg = 1
        .endif
        .exitm
    .endr
    
    .if _is_reg
        move \reg, \val
    .else
        # For simplicity, we use 'la' which handles both labels and some immediates
        la \reg, \val
    .endif
.endm


# -----------------------------------------------------------------------------
# Control Flow & Stack Frame Macros
# -----------------------------------------------------------------------------

# call: Variadic function call
# Usage: call target, [a0, a1, a2, a3, stack_arg1, stack_arg2...]
# - Automatically reserves 16-byte shadow space (O32 ABI)
# - Loads first 4 args into $a0-$a3
# - Pushes remaining args to stack (right-to-left)
# - Cleans up stack after call
.macro call target, a0, a1, a2, a3, a4, a5, a6, a7
    # 1. Calculate Stack Alignment
    _stack_args_count = 0
    .ifnb \a7
        _stack_args_count = _stack_args_count + 1
    .endif
    .ifnb \a6
        _stack_args_count = _stack_args_count + 1
    .endif
    .ifnb \a5
        _stack_args_count = _stack_args_count + 1
    .endif
    .ifnb \a4
        _stack_args_count = _stack_args_count + 1
    .endif

    _padding = 0
    _is_odd = _stack_args_count % 2
    .if _is_odd
        _padding = 4
        addiu $sp, $sp, -4
    .endif

    # 2. Push Stack Arguments
    _stack_bytes = 0
    .ifnb \a7
        _load_arg $at, \a7
        addiu $sp, $sp, -4
        sw $at, 0($sp)
        _stack_bytes = _stack_bytes + 4
    .endif
    .ifnb \a6
        _load_arg $at, \a6
        addiu $sp, $sp, -4
        sw $at, 0($sp)
        _stack_bytes = _stack_bytes + 4
    .endif
    .ifnb \a5
        _load_arg $at, \a5
        addiu $sp, $sp, -4
        sw $at, 0($sp)
        _stack_bytes = _stack_bytes + 4
    .endif
    .ifnb \a4
        _load_arg $at, \a4
        addiu $sp, $sp, -4
        sw $at, 0($sp)
        _stack_bytes = _stack_bytes + 4
    .endif

    # 3. Load Register Arguments
    .ifnb \a0
        _load_arg $a0, \a0
    .endif
    .ifnb \a1
        _load_arg $a1, \a1
    .endif
    .ifnb \a2
        _load_arg $a2, \a2
    .endif
    .ifnb \a3
        _load_arg $a3, \a3
    .endif

    # 4. Reserve Shadow Space (16 bytes)
    addiu   $sp, $sp, -16

    # 5. Call
    jal     \target
    nop

    # 6. Cleanup
    _total_cleanup = 16 + _stack_bytes + _padding
    addiu   $sp, $sp, _total_cleanup
.endm

.macro ret
    jr      $ra
    nop
.endm

# enter: Sets up O32 stack frame
# - Saves $ra and $fp (8 bytes)
# - Sets new $fp
# - Allocates 'size' bytes for locals (user must ensure alignment/arg slots if needed)
.macro enter size=0
    addiu   $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $fp, 0($sp)
    move    $fp, $sp
    .if \size > 0
    addiu   $sp, $sp, -8*\size
    .endif
.endm

# leave: Tears down O32 stack frame
# - Restores $sp from $fp
# - Restores $fp and $ra
# - Pops stack
.macro leave
    move    $sp, $fp
    lw      $fp, 0($sp)
    lw      $ra, 4($sp)
    addiu   $sp, $sp, 8
.endm

# -----------------------------------------------------------------------------
# Input Macros
# -----------------------------------------------------------------------------

.macro read_char reg
    jal     fn_read_char
    nop
    move    \reg, $v0
.endm

.macro read_line buffer, size
    la      $a0, \buffer
    li      $a1, \size
    jal     fn_read_line
    nop
.endm

# -----------------------------------------------------------------------------
# Smart Printing Wrappers
# (Requires functions.inc to be included at end of file)
# -----------------------------------------------------------------------------

# print_str(label|reg) - Prints a null-terminated string to stdout.
.macro print_str addr
	_load_arg $a0, \addr
    jal     fn_print_str
    nop
.endm

# print_int(register, base=10, width=0)
.macro print_int reg, base=10, width=0
    move    $a0, \reg
    li      $a1, \base
    li      $a2, \width
    jal     fn_print_int
    nop
.endm

.macro print_hex reg, width=0
    print_int \reg, 16, \width
.endm

.macro print_bin reg, width=0
    print_int \reg, 2, \width
.endm

.macro print_newline
    jal     fn_print_newline
    nop
.endm

# -----------------------------------------------------------------------------
# Heap Allocation Helper
# -----------------------------------------------------------------------------

# allocate_heap(size_in_bytes)
# Result: $v0 contains the address of the allocated block
# Logic: 
#   1. Call brk(0) to get current break.
#   2. Save that address (it's our pointer).
#   3. Add size to it.
#   4. Call brk(new_address) to expand heap.
.macro allocate_heap size
    # 1. Get current break
    li      $v0, SYS_BRK
    li      $a0, 0
    syscall
    
    move    $t0, $v0        # $t0 = Start of new block
    
    # 2. Calculate new break
    addiu   $a0, $t0, \size
    
    # 3. Set new break
    li      $v0, SYS_BRK
    # $a0 is already set
    syscall
    
    # 4. Return the start of the block
    move    $v0, $t0
.endm

.include "functions.inc"
