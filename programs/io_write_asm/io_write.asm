.section .text
.global main

main:
    # Target address
    lui     a1, 0x8000          # a1 = 0x8000_0000  (IO_LED port)
    sll     a1, a1, 8

    addi    a2, x0, 0xff        # compare

reset:
    addi    a3, x0, 0xff        # counter

count_up:
    addi    a3, a3, 0x1
    beq     a3, a2, reset
    sd      a2, 0(a1)
    j count_up

