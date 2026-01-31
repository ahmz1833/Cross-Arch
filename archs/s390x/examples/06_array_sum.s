/*********************************************************************
* Example 06: Array Operations
* Linking Type: NoLibc
* Demonstrates:
* - Defining arrays in data segment
* - Array traversal using indexing
* - Computing sum, min, max of array elements
* - Pointer arithmetic
*********************************************************************/

.include "macros.inc"

.data
.align 8
/* Array of 64-bit integers */
my_array:
    .quad 42, 17, 89, 3, 56, 91, 28, 64, 12, 35
array_end:
.equ I_ARRAY_LEN, (array_end - my_array) / 8

.align 8
msg_title:    .asciz "--- Array Operations ---\n"
.align 8
msg_elements: .asciz "\nArray Elements:\n"
.align 8
msg_elem:     .asciz "  ["
.align 8
msg_bracket:  .asciz "] = "
.align 8
msg_sum:      .asciz "\nSum of all elements: "
.align 8
msg_min:      .asciz "Minimum value: "
.align 8
msg_max:      .asciz "Maximum value: "
.align 8
msg_avg:      .asciz "Average value: "

.bss
/* Use BSS for temporaries instead of stack */
.align 8
saved_sum:    .skip 8
saved_min:    .skip 8
saved_max:    .skip 8
saved_avg:    .skip 8
saved_idx:    .skip 8
saved_val:    .skip 8

.text
.global _start

_start:
    call main
    sys_exit 0

/*********************************************************************
 * Main function - has proper stack frame
 *********************************************************************/
main:
    enter

    print_str msg_title

    /*=================================================================
     * Print all array elements
     *=================================================================*/
    print_str msg_elements

    /* Initialize index to 0 */
    larl      %r1, saved_idx
    lgfi      %r0, 0
    stg       %r0, 0(%r1)

print_loop:
    /* Load index */
    larl      %r1, saved_idx
    lg        %r6, 0(%r1)
    
    cgfi      %r6, I_ARRAY_LEN
    jhe       print_done

    /* Load array[i] and save to BSS */
    larl      %r1, my_array
    lgr       %r2, %r6
    sllg      %r2, %r2, 3        /* R2 = i * 8 */
    lg        %r7, 0(%r2, %r1)   /* R7 = array[i] */
    
    larl      %r1, saved_val
    stg       %r7, 0(%r1)

    /* Print "[i] = value" */
    print_str msg_elem
    
    larl      %r1, saved_idx
    lg        %r6, 0(%r1)
    print_int %r6
    
    print_str msg_bracket
    
    larl      %r1, saved_val
    lg        %r7, 0(%r1)
    print_int %r7
    print_newline

    /* Increment index and save */
    larl      %r1, saved_idx
    lg        %r6, 0(%r1)
    agfi      %r6, 1
    stg       %r6, 0(%r1)
    
    j         print_loop

print_done:

    /*=================================================================
     * Calculate Sum
     *=================================================================*/
    lgfi      %r6, 0             /* i = 0 */
    lgfi      %r7, 0             /* sum = 0 */

sum_loop:
    cgfi      %r6, I_ARRAY_LEN
    jhe       sum_done

    /* sum += array[i] */
    larl      %r1, my_array
    lgr       %r2, %r6
    sllg      %r2, %r2, 3
    lg        %r2, 0(%r2, %r1)
    agr       %r7, %r2

    agfi      %r6, 1
    j         sum_loop

sum_done:
    /* Save sum to BSS */
    larl      %r1, saved_sum
    stg       %r7, 0(%r1)
    
    print_str msg_sum
    larl      %r1, saved_sum
    lg        %r6, 0(%r1)
    print_int %r6
    print_newline

    /*=================================================================
     * Find Minimum and Maximum
     *=================================================================*/
    larl      %r1, my_array
    lg        %r6, 0(%r1)        /* R6 = min = array[0] */
    lgr       %r7, %r6           /* R7 = max = array[0] */
    lgfi      %r8, 1             /* R8 = index, start from 1 */

minmax_loop:
    cgfi      %r8, I_ARRAY_LEN
    jhe       minmax_done

    /* Load current element */
    larl      %r1, my_array
    lgr       %r2, %r8
    sllg      %r2, %r2, 3
    lg        %r2, 0(%r2, %r1)   /* R2 = array[i] */

    /* Check for new minimum */
    cgr       %r2, %r6
    jhe       check_max
    lgr       %r6, %r2           /* New min found */

check_max:
    /* Check for new maximum */
    cgr       %r2, %r7
    jle       next_iter
    lgr       %r7, %r2           /* New max found */

next_iter:
    agfi      %r8, 1
    j         minmax_loop

minmax_done:
    /* Save min/max to BSS before printing */
    larl      %r1, saved_min
    stg       %r6, 0(%r1)
    larl      %r1, saved_max
    stg       %r7, 0(%r1)
    
    print_str msg_min
    larl      %r1, saved_min
    lg        %r6, 0(%r1)
    print_int %r6
    print_newline

    print_str msg_max
    larl      %r1, saved_max
    lg        %r6, 0(%r1)
    print_int %r6
    print_newline

    /*=================================================================
     * Calculate Average (Sum / Length)
     *=================================================================*/
    larl      %r1, saved_sum
    lg        %r3, 0(%r1)        /* R3 = sum */
    lgfi      %r4, I_ARRAY_LEN   /* R4 = length (divisor) */
    
    /* Signed division: R2:R3 / R4 -> Quotient in R3, Remainder in R2 */
    lgfi      %r2, 0             /* Clear high part */
    dsgr      %r2, %r4           /* R3 = quotient, R2 = remainder */
    
    larl      %r1, saved_avg
    stg       %r3, 0(%r1)

    print_str msg_avg
    larl      %r1, saved_avg
    lg        %r6, 0(%r1)
    print_int %r6
    print_newline

    leave
    ret
