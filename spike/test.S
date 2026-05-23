.section .text
.globl _start
_start:
    addi x1, x0, 5       # x1 = 5
    addi x2, x0, 3       # x2 = 3
    add  x3, x1, x2      # x3 = 8
    sub  x4, x1, x2      # x4 = 2
    and  x5, x1, x2      # x5 = 1
    or   x6, x1, x2      # x6 = 7
    xor  x7, x1, x2      # x7 = 6
    addi x12, x0, 1
    addi x12, x12, 2
    addi x12, x12, 3
    addi x12, x12, 4     # x12 = 10
    # end
    unimp                 # trap to halt
