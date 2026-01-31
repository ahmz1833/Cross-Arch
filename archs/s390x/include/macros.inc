/*
 * macros.inc - s390x Helper Macros
 */

.include "constants.inc"

/* -----------------------------------------------------------------------------
 * Stack Helpers
 * ----------------------------------------------------------------------------- */
.macro push reg
    aghi    %r15, -8
    stg     \reg, 0(%r15)
.endm

.macro pop reg
    lg      \reg, 0(%r15)
    aghi    %r15, 8
.endm

# -----------------------------------------------------------------------------
# Argument Loading Helper
# -----------------------------------------------------------------------------

# Helper macro to load arguments (Register/Immediate/Label)
.macro _load_arg reg, val
    .set _type, 0
    .irpc char, \val
        .ifc \char, %
            .set _type, 2
            .exitm
        .endif
        .irp digit, 0,1,2,3,4,5,6,7,8,9,-
            .ifc \char, \digit
                .set _type, 1
            .endif
        .endr
        .ifc \char, I
            .set _type, 1
            .exitm
        .endif
        .exitm
    .endr

    .if _type == 2
        lgr \reg, \val
    .elseif _type == 1
        lgfi \reg, \val
    .else
        larl \reg, \val
    .endif
.endm

/* -----------------------------------------------------------------------------
 * Function Prologue/Epilogue
 * ----------------------------------------------------------------------------- */

/* enter: Sets up stack frame */
/* - Saves Rx-R15 */
/* - Use R11 as Frame Pointer */
/* - Allocates 'size'*8 bytes for locals */
.macro enter size=0 first=6
    stmg %r\first, %r15, \first*8(%r15)     /* Save Rx-R15 in caller's save area */
    lgr      %r11, %r15                     /* Save SP in FP */
    .if \size > 0
        lay  %r15, -\size*8(%r15)           /* Allocate local variables in stack */
    .endif
.endm

/* leave: Tears down stack frame */
/* - Restore SP from FP */
/* - Restores Rx-R15 */
/* - Returns */
.macro leave first=6
    lgr     %r15, %r11                      /* Restore SP from FP */
    lmg %r\first, %r15, \first*8(%r15)      /* Restore Rx-R15 */
    br      %r14                            /* Return */
.endm

/* ret: Simple return (for leaf functions without stack frame) */
.macro ret
    br      %r14
.endm

/* -----------------------------------------------------------------------------
 * Function Call Wrapper
 * ----------------------------------------------------------------------------- */

/* call: Calls a function with stack spill area allocation */
/* - Allocates 160 bytes (standard save area) */
/* - Calls target */
/* - Deallocates 160 bytes */
/* - Optional: Loads arguments into R2-R6 if provided and extra on stack */
.macro call target, a0, a1, a2, a3, a4, a5, a6, a7
    /* 1. Calculate Stack Alignment */
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
    
    /* 2. Push Stack Arguments */
    _stack_bytes = 0
    .ifnb \a7
        _load_arg %r2, \a7
        stg  %r2,  0(%r15)
        aghi %r15, -8
        _stack_bytes = _stack_bytes + 8
    .endif
    .ifnb \a6
        _load_arg %r2, \a6
        stg  %r2,  0(%r15)
        aghi %r15, -8
        _stack_bytes = _stack_bytes + 8
    .endif
    .ifnb \a5
        _load_arg %r2, \a6
        stg  %r2,  0(%r15)
        aghi %r15, -8
        _stack_bytes = _stack_bytes + 8
    .endif

    /* 3. Load Register Arguments */
    .ifnb \a0
        _load_arg %r2, \a0
    .endif
    .ifnb \a1
        _load_arg %r3, \a1
    .endif
    .ifnb \a2
        _load_arg %r4, \a2
    .endif
    .ifnb \a3
        _load_arg %r5, \a3
    .endif
    .ifnb \a4
        _load_arg %r6, \a4
    .endif

    /* 4. Allocate Register Spill Area (160 bytes) */
    aghi    %r15, -160

    /* 5. Call */
    brasl   %r14, \target

    /* 6. Cleanup */
    _total_cleanup = 160 + _stack_bytes
    aghi    %r15, _total_cleanup
.endm

/* -----------------------------------------------------------------------------
 * I/O Macros
 * ----------------------------------------------------------------------------- */

/* read_char(reg) - Reads a char into register */
.macro read_char reg
    call    fn_read_char
    lgr     \reg, %r2
.endm

/* read_int(reg) - Reads an integer into register */
.macro read_int reg
    call    fn_read_int
    lgr     \reg, %r2
.endm

/* read_int(buffer, size) - Reads a line */
.macro read_line buffer, size
    call    fn_read_line, \buffer, \size
.endm

/* print_str(label) */
.macro print_str label
    call    fn_print_str, \label
.endm

.macro print_int reg, base=10, width=0
    call    fn_print_int, \reg, \base, \width
.endm

.macro print_hex reg, width=0
    print_int \reg, 16, \width
.endm

.macro print_bin reg, width=0
    print_int \reg, 2, \width
.endm

.macro print_newline
    call     fn_print_char, 10
.endm

.include "syscalls.inc"
.include "functions.inc"
