.section .text
.global main

## HART MISMATCH
main:
    # address
    addi    x5, x0, 0xcc  # x5 = 0xcc
    # access forbidden for hart 0
    addi	x6, x0, 0b0   # x6 = 0b0
    # color is going to be randomly generated

    # custom instruction: tadrr
    # tadrr x7, x5, x6
    #           opcode6     func3   func7   rd   rs1  rs2
    .insn   r   CUSTOM_0,   2,      0,      x7,  x5,  x6
    # T[816] = randomly generated color with extra bit (from x29) for hart access at the end
    # x7 = address with randomly generated color encoded

    # unsuccessful memory store operation because hart 0 isn't allowed access
    sd      x5, 0(x7)		# hart mismatch on address 0xcc

    ## retagging the memory address to allow hart 0
    # access allowed for hart 0
    addi	x6, x0, 0b1   # x6 = 0b1
    # custom instruction: tadre
    # tadre x0, x1, x0
    #           opcode6     func3   func7   rd  rs1 rs2
    .insn   r   CUSTOM_0,   1,      0,      x0, x7, x6
    # T[816] = formely generated color, with hart 0 now allowed

    # formerly unsuccessful memory store operation, now successful
    sd      x5, 0(x7)		# store 0xcc in x5

    # successful memory load operation
    ld      x1, 0(x7)		# load 0xcc in x1
