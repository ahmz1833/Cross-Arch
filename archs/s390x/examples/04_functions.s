/*********************************************************************
* Example 04: Functions (Simple)
* Linking Type: NoLibc
* Demonstrates:
* - Defining and calling functions
* - Passing arguments (R2-R6 for first 5 args)
* - Return values (R2)
* - Stack frame management with enter/leave
* - Callee-saved registers (R6-R15)
*********************************************************************/

.include "macros.inc"

.data
.align 8
msg_add:        .asciz "--- Addition Function ---\n"
.align 8
msg_enter_a:    .asciz "Enter first number (a): "
.align 8
msg_enter_b:    .asciz "Enter second number (b): "
.align 8
msg_result:     .asciz "Result of add(a, b): "
.align 8
msg_max:        .asciz "\n--- Max Function ---\n"
.align 8
msg_max_result: .asciz "Max of a and b: "
.align 8
msg_square:     .asciz "\n--- Square Function ---\n"
.align 8
msg_sq_result:  .asciz "Square of a: "
.align 8
msg_abs:        .asciz "\n--- Absolute Value ---\n"
.align 8
msg_abs_result: .asciz "Absolute value of a: "

.text
.global _start

_start:
    /*=================================================================
     * Read two numbers
     *=================================================================*/
    print_str msg_enter_a
    read_int  %r12               /* R12 = a */
    
    print_str msg_enter_b
    read_int  %r13               /* R13 = b */

    /*=================================================================
     * Test add function
     *=================================================================*/
    print_str msg_add
    
    /* Call add(a, b) - Args in R2, R3, return in R2 */
    lgr       %r2, %r12
    lgr       %r3, %r13
    brasl     %r14, fn_add
    lgr       %r10, %r2            /* Save result in R10 */
    
    print_str msg_result
    print_int %r10
    print_newline

    /*=================================================================
     * Test max function
     *=================================================================*/
    print_str msg_max

    /* Call max(a, b) */
    lgr       %r2, %r12
    lgr       %r3, %r13
    brasl     %r14, fn_max
    lgr       %r10, %r2            /* Save result in R10 */

    print_str msg_max_result
    print_int %r10
    print_newline

    /*=================================================================
     * Test square function
     *=================================================================*/
    print_str msg_square

    /* Call square(a) */
    lgr       %r2, %r12
    brasl     %r14, fn_square
    lgr       %r10, %r2            /* Save result in R10 */

    print_str msg_sq_result
    print_int %r10
    print_newline

    /*=================================================================
     * Test absolute value function
     *=================================================================*/
    print_str msg_abs

    /* Call abs(a) */
    lgr       %r2, %r12
    brasl     %r14, fn_abs
    lgr       %r10, %r2            /* Save result in R10 */

    print_str msg_abs_result
    print_int %r10
    print_newline

    sys_exit 0

/*********************************************************************
 * Function: fn_add
 * Arguments: R2 = a, R3 = b
 * Returns: R2 = a + b
 * Leaf function (no stack frame needed)
 *********************************************************************/
fn_add:
    agr       %r2, %r3           /* R2 = R2 + R3 */
    ret

/*********************************************************************
 * Function: fn_max
 * Arguments: R2 = a, R3 = b
 * Returns: R2 = max(a, b)
 * Leaf function with conditional move
 *********************************************************************/
fn_max:
    cgr       %r2, %r3           /* Compare a with b */
    jhe       max_done           /* If a >= b, a is already max */
    lgr       %r2, %r3           /* Otherwise, result = b */
max_done:
    ret

/*********************************************************************
 * Function: fn_square
 * Arguments: R2 = n
 * Returns: R2 = n * n
 * Leaf function
 *********************************************************************/
fn_square:
    msgr      %r2, %r2           /* R2 = R2 * R2 (signed multiply) */
    ret

/*********************************************************************
 * Function: fn_abs
 * Arguments: R2 = n
 * Returns: R2 = |n|
 * Leaf function
 *********************************************************************/
fn_abs:
    cgfi      %r2, 0             /* Compare with 0 */
    jhe       abs_done           /* If n >= 0, return n */
    lghi      %r0, 0
    sgr       %r0, %r2           /* R0 = 0 - R2 */
    lgr       %r2, %r0           /* R2 = -n */
abs_done:
    ret
