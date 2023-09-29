.section .text
.global main

main:
    addi    x1, x0, 0xca        # x1 = 0xcafe
    slli    x1, x1, 8
    addi    x1, x1, 0xfe
    addi    x2, x0, 0xff        # x2 = 0xff

loop:
    sd      x1, 0(x2)           # M[0xff] = 0xcafe ++
    addi    x1, x1, 0x1         # x1++
    j       loop

