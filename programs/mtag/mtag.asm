.section .text
.global main

main:
    ## TADRE
    # address
    addi    x1, x0, 0xbe    # x1 = 0xbe
    # memory color (0x7f80)
    lui     x2, 0x7f800     # x2 = 0xffff ffff 7f80 0000
    slli    x2, x2, 32      # x2 = 0x7f80 0000 0000 0000
    # encode color in address
    or      x1, x1, x2      # x1 = 0x7f80 0000 0000 00be
    # and the hart access tag (0b1)
	addi	x3, x0, 0b1		# x3 = 0b1
    # resulting tag = 0xff01

    # custom instruction: tadre
    # .insn: https://sourceware.org/binutils/docs/as/RISC_002dV_002dDirectives.html
    # instruction formats: https://sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html
    # tadre x0, x1, x0
    #           opcode6     func3   func7   rd  rs1 rs2
    .insn   r   CUSTOM_0,   1,      0,      x0, x1, x3
    # T[23] = 0x7f81

    # successful memory store operation with tag
    sd      x2, 0(x1)       # M[0xbe] = 0x7f80 0000 0000 0000

    ## TADR
    # address
    addi    x5, x0, 0xfc    # x5 = 0xfc
    # tag
    # memory color = 0x25e
    # hart access = 0b1
    addi    x6, x0, 0x4bd   # x6 = 0x4bd
    # custom instruction: tadr
    # tadr x7, x5, x6
    #           opcode6     func3   func7   rd  rs1 rs2
    .insn   r   CUSTOM_0,   0,      0,      x7, x5, x6
    # T[31] = 0x4bd
    # x7 = address with encoded color

    # successful memory store operation with tag
    sd      x2, 0(x7)       # M[0xfc] = 0xff01 0000 0000 0000

	## TADRR
    # address
    addi    x28, x0, 0xab  # x28 = 0xab
    # hart access
    addi	x29, x0, 0b1   # x29 = 0b1
    # color is going to be randomly generated

    # custom instruction: tadrr
    # tadrr x30, x28, x29
    #           opcode6     func3   func7   rd   rs1  rs2
    .insn   r   CUSTOM_0,   2,      0,      x30, x28, x29
    # T[21] = randomly generated color with extra bit (from x29) for hart access at the end
    # x30 = address with randomly generated color encoded

    # successful memory store operation with tag
    sd      x2, 0(x30)      # M[0xfc] = 0xff01 0000 0000 0000

    ## COLOR MISMATCH
    # address
    addi    x3, x0, 0xaa    # x3 = 0xaa
    # build tag
    # memory color: 0x5605
    # hart acces: 0b1
    lui     x4, 0xac0b0     # x4 = 0xffff ffff ac0b 0000
    slli    x4, x4, 32      # x4 = 0xac0b 0000 0000 0000
    # encode color in address
    or      x3, x3, x4      # x1 = 0xac0b 0000 0000 00aa
    # unseccessful memory load operation with tag
    ld      x2, 0(x3)       # tag mismatch on address 0xaa (x3)

    ## HART MISMATCH
	## TADRR
    # address
    addi    x28, x0, 0xcc  # x28 = 0xcc
    # access forbidden for hart 0
    addi	x29, x0, 0b0   # x29 = 0b0
    # color is going to be randomly generated

    # custom instruction: tadrr
    # tadrr x30, x28, x29
    #           opcode6     func3   func7   rd   rs1  rs2
    .insn   r   CUSTOM_0,   2,      0,      x30, x28, x29
    # T[25] = randomly generated color with extra bit (from x29) for hart access at the end
    # x30 = address with randomly generated color encoded

    # unsuccessful memory store operation because hart 0 isn't allowed access
    sd      x2, 0(x30)		# hart mismatch on address 0xaa
