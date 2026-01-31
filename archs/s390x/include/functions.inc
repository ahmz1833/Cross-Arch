/*
 * functions.inc - Helper functions (Syscall based)
 */

.text

/* -----------------------------------------------------------------------------
 * String Length
 * fn_strlen(str_addr) -> length in R2
 * ----------------------------------------------------------------------------- */
.global fn_strlen
fn_strlen:
    lgr     %r1, %r2        /* R1 = current pointer */
    lghi    %r2, 0          /* R2 = length */
strlen_loop:
    llc     %r0, 0(%r1)     /* Load byte */
    chi     %r0, 0          /* Check for null */
    je      strlen_done
    aghi    %r2, 1
    aghi    %r1, 1
    jg      strlen_loop
strlen_done:
    ret

/* -----------------------------------------------------------------------------
 * Print String
 * fn_print_str(char* str)
 * ----------------------------------------------------------------------------- */
.global fn_print_str
fn_print_str:
    enter 0, 11
    lgr         %r13, %r2           /* Save string address in R13 (saved by enter) */
    call        fn_strlen           /* Get length */
    lgr         %r4, %r2            /* Length in R4 */
    sys_write   I_STDOUT, %r13, %r4 /* Syscall Write */
    leave 11
    ret

/* -----------------------------------------------------------------------------
 * Print Char
 * fn_print_char(char c)
 * ----------------------------------------------------------------------------- */
.global fn_print_char
fn_print_char:
    enter 1, 11
    stc         %r2,  0(%r15)       /* Store char */
    sys_write   I_STDOUT, %r15, 1   /* Syscall Write */
    leave 11
    ret

/* -----------------------------------------------------------------------------
 * Print Integer
 * fn_print_int(long n, base, min_width)
 * %R2 -> The integer to print
 * %R3 -> The base (e.g., 10, 16, 2). If 0, defaults to 10.
 * %R4 -> Minimum width (pads with '0' if fewer digits). Default 0.
 * Return Value (in %R2): None
 * Notes:
 *  - Handles negative numbers only for base 10.
 *  - Supports bases up to 16 (prints A-F for 10-15).
 * ----------------------------------------------------------------------------- */
.global fn_print_int
fn_print_int:
    enter  4,   6
    lgr    %r5, %r4
    lgr    %r4, %r3
    lgr    %r3, %r2
    lay    %r2, 0(%r15)
    call   _ltoa
    print_str %r15
    leave 6
    ret

_ltoa:
    enter  0,    6
    lgfi   %r6,  0                           # Load the buffer address to %r6
    lgr    %r9,  %r3                         # Load the number to %r9
    lgfi   %r7,  0                           # Initialize the counter to 0
    cgijhe %r9,  0, 10f                      # Jump to 1 if the number is positive
    lgfi   %r8,  '-                          # Load the negative sign to %r8
    stc    %r8,  0(%r2)                      # Store the negative sign in the buffer
    agfi   %r6,  1                           # Move the buffer pointer to the next position
    lgfi   %r8, -1                           #|
    xgr    %r9,  %r8                         #| %r9 <- -%r9
    agfi   %r9,  1                           #|
10: dsgr   %r8,  %r4                         # %r9:%r8 (%r8 is reminder) <- %r9 / base
    push   %r8                               # Push the reminder to stack
    agfi   %r7,  1                           # %r7 <- %r7 + 1
    cgijne %r9,  0,   10b                    # If %r9 != 0, jump to 1
11: crjhe  %r7,  %r5, 12f                    # Compare the number of digits with the required digits
    lgfi   %r8,  0                           #|
    push   %r8                               #| Push '0' to stack
    agfi   %r7,  1                           # %r7 <- %r7 + 1
    j      11b                               # Loop
12: pop    %r8                               # Pop the digit from stack
    cgijle %r8,  9,   13f                    # Check if the digit is greater than 9
    agfi   %r8, -10 + 'A - '0                # Convert the reminder to ASCII (HEX)
13: agfi   %r8,  '0                          # Convert the reminder to ASCII
    stc    %r8,  0(%r6, %r2)                 # Store the digit in the buffer
    agfi   %r6,  1                           # Move the buffer pointer to the next position
    agfi   %r7, -1                           # %r7 <- %r7 - 1  
    cgijne %r7,  0, 12b                      # If %r7 != 0, jump to 2
    lgfi   %r8,  0                           # Load the null terminator to %r8
    stc    %r8,  0(%r6, %r2)                 # Store the null terminator in the buffer
    leave  6
    ret

/* -----------------------------------------------------------------------------
 * Read Char
 * fn_read_char() -> char in R2
 * ----------------------------------------------------------------------------- */
.global fn_read_char
fn_read_char:
    enter 1, 11
    sys_read I_STDIN, %r15, 1
    llc      %r2, 0(%r15)   /* Load char */
    leave 11
    ret

/* -----------------------------------------------------------------------------
 * Read Int
 * fn_read_int() -> long in R2
 * ----------------------------------------------------------------------------- */
.global fn_read_int
fn_read_int:
    enter 0, 6
    lghi    %r6, 0          /* Result */
    lghi    %r7, 0          /* Sign (0=pos, 1=neg) */

    read_char %r8

    chi     %r8, '-'
    jne     ri_digit
    lghi    %r7, 1          /* Negative */
    
    read_char %r8
    

ri_digit:
    /* Check if digit */
    chi     %r8, '0'
    jl      ri_done
    chi     %r8, '9'
    jh      ri_done

    /* Result = Result * 10 + (Char - '0') */
    mghi    %r6, 10
    aghi    %r8, -48
    agr     %r6, %r8

    read_char %r8
    jg      ri_digit

ri_done:
    /* Apply sign */
    chi     %r7, 1
    jne     ri_ret
    lghi    %r0, 0
    sgr     %r0, %r6
    lgr     %r6, %r0

ri_ret:
    lgr     %r2, %r6
    leave 6
    ret

/* -----------------------------------------------------------------------------
 * Read Line
 * fn_read_line(buffer, size) -> long:number-of-read-bytes in R2
 * ----------------------------------------------------------------------------- */
fn_read_line:
    enter 0, 6
    lgr     %r6, %r2    /* Buffer Pointer */
    lgr     %r7, %r3    /* Max Size */
    lgfi    %r8, 0      /* Count */

_rl_loop:
    /* Check if full (leave space for null terminator) */
    lay     %r0, 1(%r8)
    cgr     %r0, %r7
    je      _rl_done

    /* Read 1 char */
    lay      %r0, 0(%r8, %r6)  /* D(X,B) */
    sys_read I_STDIN, %r0, 1

    /* Check for error or EOF (return value <= 0) */
    cgfi    %r2, 0
    jle     _rl_done

    
    /* Check for newline */
    llc     %r0, 0(%r8, %r6)
    cgfi    %r0, 10
    je      _rl_done_nl

    agfi    %r8, 1
    j       _rl_loop
    
_rl_done_nl:
    agfi    %r8, 1
_rl_done:
    lgfi    %r0, 0
    stc     %r0, 0(%r8, %r6)
    lgr     %r2, %r8
    leave 6
    ret

