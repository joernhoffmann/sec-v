.section .text
.global main

main:
    # address
    addi    x1, x0, 0xbe    # x1 = 0xbe
    # build tag
    lui     x2, 0xff010     # x2 = 0xffff ffff ff01 0000
    slli    x2, x2, 32      # x2 = 0xff01 0000 0000 0000
    # encode tag in address
    or      x1, x1, x2      # x1 = 0xff01 0000 0000 00be

    # custom instruction: tadre
    # .insn: https://sourceware.org/binutils/docs/as/RISC_002dV_002dDirectives.html
    # instruction formats: https://sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html
    # tadre x0, x1, x0
    #           opcode6     func3   func7   rd  rs1 rs2
    .insn   r   CUSTOM_0,   1,      0,      x0, x1, x0
    # T[23] = 0xff01

    # successful memory store operation with tag
    sd      x2, 0(x1)       # M[0xbe] = 0xff01 0000 0000 0000


    # address
    addi    x5, x0, 0xfc    # x5 = 0xfc
    # tag
    addi	x6, x0, 0x4bc	# x6 = 0x4bc
    # custom instruction: tadr
    # tadr x0, x5, x6
    #           opcode6     func3   func7   rd  rs1 rs2
    .insn   r   CUSTOM_0,   0,      0,      x0, x5, x6
    # T[31] = 0x4bc

	# encode tag in address
	slli	x6, x6, 48		# x6 = 0x04bc 0000 0000 0000
	or 		x5, x5, x6		# x5 = 0x04bc 0000 0000 00fc
    # successful memory store operation with tag
    sd      x2, 0(x5)       # M[0xfc] = 0xff01 0000 0000 0000


    # address
    addi    x3, x0, 0xaa    # x3 = 0xaa
    # build tag
    lui     x4, 0xac0b0     # x4 = 0xffff ffff ac0b 0000
    slli    x4, x4, 32      # x4 = 0xac0b 0000 0000 0000
    # encode tag in address
    or      x3, x3, x4      # x1 = 0xac0b 0000 0000 00aa
    # unseccessful memory load operation with tag
    ld      x2, 0(x3)       # tag mismatch on address 0xaa (x3)
