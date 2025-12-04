# Linear Search Algorithm
# Searches for a value in an array

.data
    array: .word 10, 23, 45, 12, 67, 34, 89, 15
    size: .word 8
    search_val: .word 200
    found_msg: .asciiz "Value found at index: "
    not_found_msg: .asciiz "Value not found in array\n"
    newline: .asciiz "\n"

.text
.globl main

main:
    # Call linear search
    la $a0, array
    lw $a1, size
    lw $a2, search_val
    jal linear_search
    
    move $t0, $v0       # save result
    
    # Check if found
    li $t1, -1
    beq $t0, $t1, not_found
    
    # Found - print message and index
    li $v0, 4
    la $a0, found_msg
    syscall
    
    li $v0, 1
    move $a0, $t0
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    j exit_program
    
not_found:
    li $v0, 4
    la $a0, not_found_msg
    syscall
    
exit_program:
    # Exit
    li $v0, 10
    syscall

# Function: linear_search(array, size, target)
# Arguments: $a0 = array, $a1 = size, $a2 = target
# Returns: $v0 = index if found, -1 if not found
linear_search:
    li $t0, 0           # i = 0
    move $t1, $a0       # array pointer
    
search_loop:
    beq $t0, $a1, search_not_found  # if i == size
    
    lw $t2, 0($t1)      # load array[i]
    beq $t2, $a2, search_found      # if array[i] == target
    
    addi $t1, $t1, 4    # next element
    addi $t0, $t0, 1    # i++
    j search_loop
    
search_found:
    move $v0, $t0       # return index
    jr $ra
    
search_not_found:
    li $v0, -1          # return -1
    jr $ra
