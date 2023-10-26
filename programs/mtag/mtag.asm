.section .text
.global main

main:
    addi	x1,	x0, 0xbe 	# x1 = 0xbe
    lui		x2, 0xff010    	# x2 = 0xffffffffff010000
    slli 	x2, x2, 32     	# x2 = 0xff01000000000000
    or 		x1, x1, x2      # x1 = 0xff010000000000be

    # custom instruction: tadr
    # .insn: https://sourceware.org/binutils/docs/as/RISC_002dV_002dDirectives.html
    # instruction formats: https://sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html
    # tadr x0, x1, x0
    #       	opcode6     func3   func7   rd  rs1 rs2
    .insn 	r 	CUSTOM_0,   0,      1,      x0, x1, x0
    # T[23] = 0xff01

    # successful memory store operation with tag
    sd 		x2, 0(x1)       # M[0xbe] = 0xff01000000000000

    addi 	x3, x0, 0xaa	# x3 = 0xaa
    lui		x4, 0xac0b0    	# x4 = 0xffffffffac0b0000
    slli 	x4, x4, 32     	# x4 = 0xac0b000000000000
    or 		x3, x3, x4      # x1 = 0xac0b0000000000aa
    # unseccessful memory load operation with tag
    ld 		x2, 0(x3)       # tag mismatch on address 0xaa (x3)
