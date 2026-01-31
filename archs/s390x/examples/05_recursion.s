/*********************************************************************
* Example 05: Recursion (Factorial)
* Linking Type: NoLibc
* Demonstrates:
* - Recursive function implementation
* - Stack frame for non-leaf functions
* - Saving/restoring callee-saved registers
* - Base case and recursive case handling
*********************************************************************/

.include "macros.inc"

.data
.align 8
msg_prompt:     .asciz "Enter a number (0-20): "
.align 8
msg_factorial:  .asciz "Factorial of "
.align 8
msg_is:         .asciz " is: "
.align 8
msg_fib_title:  .asciz "\n--- Fibonacci Sequence ---\n"
.align 8
msg_fib:        .asciz "Fibonacci("
.align 8
msg_paren:      .asciz ") = "

.text
.global _start

_start:
    /*=================================================================
     * Factorial
     *=================================================================*/
    print_str msg_prompt
    read_int  %r12               /* R12 = n */

    /* Call factorial(n) */
    call factorial, %r12
    lgr       %r13, %r2          /* R13 = result */

    /* Print result */
    print_str msg_factorial
    print_int %r12
    print_str msg_is
    print_int %r13
    print_newline

    /*=================================================================
     * Fibonacci (first 10 numbers)
     *=================================================================*/
    print_str msg_fib_title
    
    lgfi      %r12, 0            /* Counter */

fib_loop:
    cgfi      %r12, 10           /* Print fib(0) to fib(9) */
    jhe       done

    /* Call fibonacci(i) */
    call fibonacci, %r12
    lgr       %r13, %r2          /* Result */

    /* Print: "Fibonacci(i) = result" */
    print_str msg_fib
    print_int %r12
    print_str msg_paren
    print_int %r13
    print_newline

    agfi      %r12, 1
    j         fib_loop

done:
    sys_exit 0

/*********************************************************************
 * Function: factorial
 * Arguments: R2 = n
 * Returns: R2 = n!
 * 
 * Algorithm:
 *   if n <= 1: return 1
 *   else: return n * factorial(n-1)
 *********************************************************************/
factorial:
    /* Setup stack frame, save R6-R15 */
    enter 0, 6

    /* Base case: if n <= 1, return 1 */
    cgfi      %r2, 1
    jle       fact_base

    /* Save n in callee-saved register */
    lgr       %r6, %r2           /* R6 = n */

    /* Recursive call: factorial(n-1) */
    aghi      %r2, -1            /* R2 = n - 1 */
    call factorial, %r2          /* Result in R2 */

    /* Multiply: result = n * factorial(n-1) */
    msgr      %r2, %r6           /* R2 = R6 * R2 */

    j         fact_done

fact_base:
    lgfi      %r2, 1

fact_done:
    leave 6
    ret

/*********************************************************************
 * Function: fibonacci
 * Arguments: R2 = n
 * Returns: R2 = fib(n)
 * 
 * Algorithm:
 *   if n <= 1: return n
 *   else: return fib(n-1) + fib(n-2)
 *********************************************************************/
fibonacci:
    /* Setup stack frame */
    enter 0, 6

    /* Base case: if n <= 1, return n */
    cgfi      %r2, 1
    jle       fib_base

    /* Save n in callee-saved register */
    lgr       %r6, %r2           /* R6 = n */

    /* Calculate fib(n-1) */
    aghi      %r2, -1            /* R2 = n - 1 */
    call fibonacci, %r2
    lgr       %r7, %r2           /* R7 = fib(n-1) */

    /* Calculate fib(n-2) */
    lgr       %r2, %r6
    aghi      %r2, -2            /* R2 = n - 2 */
    call fibonacci, %r2

    /* Result = fib(n-1) + fib(n-2) */
    agr       %r2, %r7           /* R2 = R2 + R7 */

    j         fib_done

fib_base:
    /* Return n (already in R2) */

fib_done:
    leave 6
    ret
