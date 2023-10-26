.section .text
.global main

main:
	addi x1, x0, 0xbe 	# x1 = 0xbe
	lui x2, 0xff010 	# x2 = 0xff010000
	slli x2, x2, 32 	# x2 = 0xff0100000000
	or x1, x1, x2		# x1 = 0xff010000000000be

	# custom instruction: tadr
	# .insn: https://sourceware.org/binutils/docs/as/RISC_002dV_002dDirectives.html
	# instruction formats: https://sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html
	# tadr x0, x1, x0
	# 		opcode6 	func3 	func7 	rd 	rs1 rs2
	.insn r CUSTOM_0, 	0, 		0, 		x0,	x1,	x0

	sd x2, 0(x1)		# M[0xbe]
	ld x3, 0(x2)
