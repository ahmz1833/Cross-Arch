# -----------------------------------------------------------------------------
# Example 06: Min/Max Finder (Dynamic Memory)
# Linking Type: Libc
# Demonstrates:
# - Dynamic memory allocation using standard library (malloc/free)
# - Reading integers into a dynamically allocated array
# - Processing array to find Minimum and Maximum values
# -----------------------------------------------------------------------------

.include "macros.inc"

.data
    msg_count:  .asciiz "Enter number of elements: "
    msg_enter:  .asciiz "Enter element %d: "
    msg_min:    .asciiz "Minimum: %d\n"
    msg_max:    .asciiz "Maximum: %d\n"
    fmt_int:    .asciiz "%d"
    
    # Error messages
    msg_err_mem: .asciiz "Memory allocation failed!\n"

.text
.globl main

main:
    # Allocate stack for local vars:
    # - 0($sp): N (count)
    # - 4($sp): Array Pointer
    # - 8($sp): Loop Counter / Temp
    enter 2    # 2 * 8 = 16 bytes

    # 1. Get Count (N)
    call    printf, msg_count
    
    # scanf("%d", &N) -> &N is at 0($sp)
    addiu   $a1, $sp, 0
    call    scanf, fmt_int, $a1
    
    # Load N
    lw      $s0, 0($sp)     # $s0 = N
    
    # Check if N <= 0
    blez    $s0, exit_main
    nop

    # 2. Allocate Memory
    # Size = N * 4
    sll     $a0, $s0, 2     # $a0 = N * 4
    call    malloc, $a0
    
    # Check if NULL
    beqz    $v0, mem_error
    nop
    
    move    $s1, $v0        # $s1 = Array Pointer
    sw      $s1, 4($sp)     # Save pointer

    # 3. Read Elements
    li      $s2, 0          # i = 0

read_loop:
    beq     $s2, $s0, process_start
    nop

    # printf("Enter element %d: ", i)
    call    printf, msg_enter, $s2

    # scanf("%d", &array[i])
    # Address = Base + (i * 4)
    sll     $t0, $s2, 2     # Offset
    addu    $a1, $s1, $t0   # Address
    call    scanf, fmt_int, $a1

    addiu   $s2, $s2, 1
    b       read_loop
    nop

process_start:
    # 4. Find Min/Max
    # Initialize min/max with first element
    lw      $t0, 0($s1)     # Load array[0]
    move    $s3, $t0        # $s3 = Min
    move    $s4, $t0        # $s4 = Max
    
    li      $s2, 1          # i = 1

scan_loop:
    beq     $s2, $s0, print_results
    nop

    # Load array[i]
    sll     $t0, $s2, 2
    addu    $t1, $s1, $t0
    lw      $t2, 0($t1)     # $t2 = current value

    # Update Min
    blt     $t2, $s3, update_min
    nop
    b       check_max
    nop

update_min:
    move    $s3, $t2

check_max:
    # Update Max
    bgt     $t2, $s4, update_max
    nop
    b       next_iter
    nop

update_max:
    move    $s4, $t2

next_iter:
    addiu   $s2, $s2, 1
    b       scan_loop
    nop

print_results:
    # 5. Print Min/Max
    call    printf, msg_min, $s3
    call    printf, msg_max, $s4

    # 6. Free Memory
    lw      $a0, 4($sp)
    call    free, $a0

    b       exit_main
    nop

mem_error:
    call    printf, msg_err_mem
    li      $v0, 1
    b       main_ret
    nop

exit_main:
    li      $v0, 0

main_ret:
    leave
    ret
