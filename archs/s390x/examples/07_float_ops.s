/*********************************************************************
* Example 07: Floating Point Operations
* Linking Type: Libc
* Demonstrates:
* - Floating point registers (F0-F15)
* - Loading and storing floats/doubles
* - Arithmetic: add, subtract, multiply, divide
* - Conversion between integer and float
* - Using printf for floating point output
*
* Note: s390x uses floating point registers F0-F15
* - Single precision: 32-bit
* - Double precision: 64-bit (commonly used)
*********************************************************************/

.include "macros.inc"

.data
.align 8
/* Double precision values (64-bit) */
val_d1:     .double 12.5
val_d2:     .double 3.25
pi:         .double 3.14159265358979

.align 8
/* Single precision values (32-bit) */
val_f1:     .float 2.5
val_f2:     .float 1.5

.align 8
/* Format strings for printf */
fmt_double: .asciz "Double value: %f\n"
fmt_calc:   .asciz "%s%.2f %c %.2f = %.2f\n"
fmt_conv:   .asciz "Integer %ld as double: %f\n"
fmt_area:   .asciz "Circle area (r=5): %f\n"

.align 8
msg_title:  .asciz "--- Floating Point Operations ---\n\n"
msg_add:    .asciz "Addition:       "
msg_sub:    .asciz "Subtraction:    "
msg_mul:    .asciz "Multiplication: "
msg_div:    .asciz "Division:       "

.text
.global main

main:
    enter

    /*=================================================================
     * Print title
     *=================================================================*/
    call printf, msg_title

    /*=================================================================
     * 1. Load and print a double
     *=================================================================*/
    larl      %r1, val_d1
    ld        %f0, 0(%r1)        /* Load double into F0 */
    
    /* printf("Double value: %f\n", val_d1) */
    /* On s390x, float args go in F0, F2, F4, F6 for first 4 */
    larl      %r2, fmt_double
    /* F0 already has the value */
    call printf, %r2

    /*=================================================================
     * 2. Addition: val_d1 + val_d2
     *=================================================================*/
    larl      %r1, val_d1
    ld        %f0, 0(%r1)        /* F0 = 12.5 */
    larl      %r1, val_d2
    ld        %f2, 0(%r1)        /* F2 = 3.25 */
    
    ldr       %f4, %f0           /* F4 = F0 (copy for printing) */
    ldr       %f6, %f2           /* F6 = F2 (copy for printing) */
    
    adbr      %f0, %f2           /* F0 = F0 + F2 = 15.75 */
    
    /* printf("%s%.2f %c %.2f = %.2f\n", msg, a, '+', b, result) */
    larl      %r2, fmt_calc
    larl      %r3, msg_add
    lgfi      %r4, '+'
    /* F4=a, F6=b, F0=result - need to reorganize */
    ldr       %f8, %f0           /* Save result */
    ldr       %f0, %f4           /* F0 = a */
    ldr       %f2, %f6           /* F2 = b */
    ldr       %f4, %f8           /* F4 = result */
    call printf, %r2, %r3, %r4

    /*=================================================================
     * 3. Subtraction: val_d1 - val_d2
     *=================================================================*/
    larl      %r1, val_d1
    ld        %f0, 0(%r1)
    larl      %r1, val_d2
    ld        %f2, 0(%r1)
    
    ldr       %f4, %f0
    ldr       %f6, %f2
    
    sdbr      %f0, %f2           /* F0 = F0 - F2 = 9.25 */
    
    ldr       %f8, %f0
    ldr       %f0, %f4
    ldr       %f2, %f6
    ldr       %f4, %f8
    larl      %r2, fmt_calc
    larl      %r3, msg_sub
    lgfi      %r4, '-'
    call printf, %r2, %r3, %r4

    /*=================================================================
     * 4. Multiplication: val_d1 * val_d2
     *=================================================================*/
    larl      %r1, val_d1
    ld        %f0, 0(%r1)
    larl      %r1, val_d2
    ld        %f2, 0(%r1)
    
    ldr       %f4, %f0
    ldr       %f6, %f2
    
    mdbr      %f0, %f2           /* F0 = F0 * F2 = 40.625 */
    
    ldr       %f8, %f0
    ldr       %f0, %f4
    ldr       %f2, %f6
    ldr       %f4, %f8
    larl      %r2, fmt_calc
    larl      %r3, msg_mul
    lgfi      %r4, '*'
    call printf, %r2, %r3, %r4

    /*=================================================================
     * 5. Division: val_d1 / val_d2
     *=================================================================*/
    larl      %r1, val_d1
    ld        %f0, 0(%r1)
    larl      %r1, val_d2
    ld        %f2, 0(%r1)
    
    ldr       %f4, %f0
    ldr       %f6, %f2
    
    ddbr      %f0, %f2           /* F0 = F0 / F2 ≈ 3.846 */
    
    ldr       %f8, %f0
    ldr       %f0, %f4
    ldr       %f2, %f6
    ldr       %f4, %f8
    larl      %r2, fmt_calc
    larl      %r3, msg_div
    lgfi      %r4, '/'
    call printf, %r2, %r3, %r4

    /*=================================================================
     * 6. Integer to Float conversion
     *=================================================================*/
    lgfi      %r3, 42
    cdgbr     %f0, %r3           /* Convert R3 to double in F0 */
    
    larl      %r2, fmt_conv
    call printf, %r2, %r3

    /*=================================================================
     * 7. Calculate circle area: pi * r^2 (r=5)
     *=================================================================*/
    larl      %r1, pi
    ld        %f0, 0(%r1)        /* F0 = pi */
    
    lgfi      %r3, 5
    cdgbr     %f2, %r3           /* F2 = 5.0 (radius) */
    
    mdbr      %f2, %f2           /* F2 = r^2 = 25.0 */
    mdbr      %f0, %f2           /* F0 = pi * r^2 */
    
    larl      %r2, fmt_area
    call printf, %r2

    xgr       %r2, %r2           /* Return 0 */
    leave
    ret
