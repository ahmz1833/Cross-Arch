/*********************************************************************
* Example 03: Control Flow
* Linking Type: NoLibc
* Demonstrates:
* - Conditional branching (if/else)
* - Comparison instructions
* - Loops (while, for-like)
* - Switch-case style branching
*********************************************************************/

.include "macros.inc"

.data
.align 8
msg_enter:      .asciz "Enter a number: "
.align 8
msg_positive:   .asciz "Number is POSITIVE\n"
.align 8
msg_negative:   .asciz "Number is NEGATIVE\n"
.align 8
msg_zero:       .asciz "Number is ZERO\n"
.align 8
msg_loop:       .asciz "\n--- Counting from 1 to 5 ---\n"
.align 8
msg_iter:       .asciz "Iteration: "
.align 8
msg_sum:        .asciz "\n--- Sum 1 to N ---\n"
.align 8
msg_sum_result: .asciz "Sum of 1 to "
.align 8
msg_is:         .asciz " is: "

.text
.global _start

_start:
    /*=================================================================
     * Part 1: If-Else (Checking if number is positive/negative/zero)
     *=================================================================*/
    print_str msg_enter
    read_int  %r12               /* Read number into R12 */

    /* Compare R12 with 0 */
    cgfi      %r12, 0
    je        is_zero            /* Jump if Equal (R12 == 0) */
    jl        is_negative        /* Jump if Less (R12 < 0) */
    /* Fall through: R12 > 0 */

is_positive:
    print_str msg_positive
    j         part2

is_negative:
    print_str msg_negative
    j         part2

is_zero:
    print_str msg_zero

part2:
    /*=================================================================
     * Part 2: For Loop (Count from 1 to 5)
     *=================================================================*/
    print_str msg_loop

    lgfi      %r10, 1            /* R10 = Counter (i = 1) */
    lgfi      %r11, 5            /* R11 = Limit */

for_loop:
    cgr       %r10, %r11         /* Compare counter with limit */
    jh        for_done           /* Jump if Higher (i > 5) */

    print_str msg_iter
    print_int %r10
    print_newline

    agfi      %r10, 1            /* i++ */
    j         for_loop

for_done:

part3:
    /*=================================================================
     * Part 3: While Loop (Sum 1 to N)
     * Uses previously read number (R12) as N
     *=================================================================*/
    print_str msg_sum

    /* Make N positive for summing */
    lgr       %r13, %r12         /* R13 = N */
    cgfi      %r13, 0
    jhe       skip_negate
    lghi      %r0, 0
    sgr       %r0, %r13          /* R0 = -R13 */
    lgr       %r13, %r0          /* R13 = |N| */
skip_negate:

    lgfi      %r10, 1            /* R10 = Counter (i = 1) */
    lgfi      %r11, 0            /* R11 = Sum accumulator */

while_loop:
    cgr       %r10, %r13         /* Compare i with N */
    jh        while_done         /* Exit if i > N */

    agr       %r11, %r10         /* Sum += i */
    agfi      %r10, 1            /* i++ */
    j         while_loop

while_done:
    /* Print result */
    print_str msg_sum_result
    print_int %r13
    print_str msg_is
    print_int %r11
    print_newline

    sys_exit 0
