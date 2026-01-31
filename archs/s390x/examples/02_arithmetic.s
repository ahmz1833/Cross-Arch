/*********************************************************************
* Example 02: Arithmetic
* Linking Type: NoLibc
* Demonstrates:
* - Add, Mult, Divide, etc
*********************************************************************/

.include "macros.inc"

.macro print_ux reg
    srlg    %r0, \reg, 32
    print_hex %r0, 8
    llgfr   %r0, \reg
    print_hex %r0, 8
.endm

.data
.align 8
prompt1:   .asciz " Please enter first number: "
.align 8
prompt2:   .asciz "Please enter second number: "
.align 8
add_label: .asciz "      Addition: "
.align 8
x6_label:  .asciz "            6x: "
.align 8
div_label: .asciz "Division (Q:R): "
.align 8
mul_label: .asciz "      Multiply: "

.text
.global _start

_start:
    print_str prompt1
    read_int  %r12
    print_str prompt2
    read_int  %r13
    print_ux  %r12
    call      fn_print_char, ' '
    print_ux  %r13
    print_newline
    print_newline

    print_str add_label
    lgr       %r2, %r12
    agr       %r2, %r13
    print_int %r2
    print_newline

    print_str x6_label
    lgr       %r2, %r12
    mghi      %r2, 6
    print_int %r2
    print_newline   

    print_str div_label
    lgr       %r3, %r12
    lgr       %r4, %r13
    dsgr      %r2, %r4       # R3 / R4 , Quotient in R3, Remainder in R2
    lgr       %r8, %r2
    lgr       %r9, %r3
    print_ux  %r9
    call      fn_print_char, ':'
    print_ux  %r8
    call      fn_print_char, ' '
    print_int %r9
    call      fn_print_char, ':'
    print_int %r8
    print_newline
    
    print_str mul_label
    lgr       %r3, %r12
    lgr       %r4, %r13
    mgrk      %r2, %r3, %r4   # R2:R3 = R3 * R4 
    lgr       %r8, %r2
    lgr       %r9, %r3
    print_ux  %r8
    call      fn_print_char, ':'
    print_ux  %r9
    call      fn_print_char, ' '
    print_int %r9
    print_newline

    sys_exit
