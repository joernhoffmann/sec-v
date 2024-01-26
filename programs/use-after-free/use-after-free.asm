.section .text
.global main

# simulate a use after free
main:
    # address
    addi    x5, x0, 0xcc  # x5 = 0xcc
    # hart access
    addi	x6, x0, 0b1   # x6 = 0b1
    # color is going to be randomly generated

    # custom instruction: tadrr
    # tadrr x7, x5, x6
    #           opcode6     func3   func7   rd   rs1  rs2
    .insn   r   CUSTOM_0,   2,      0,      x7,  x5,  x6
    # T[816] = randomly generated color with extra bit (from x6) for hart access at the end
    # x7 = address with randomly generated color encoded

    # successful memory store operation
    sd      x5, 0(x7)		# store 0xcc in M[0xcc]

    ## retagging the memory address to tag 0, simulating a free

    # custom instruction: tadr
    # tadr x0, x7, x0
    #           opcode6     func3   func7   rd  rs1 rs2
    .insn   r   CUSTOM_0,   0,      0,      x0, x7, x0
    # T[816] = 0

    # unsuccessful memory load operation
    ld      x1, 0(x7)		# try to load 0xcc in x1, will fail because of hart (and color) mismatch
