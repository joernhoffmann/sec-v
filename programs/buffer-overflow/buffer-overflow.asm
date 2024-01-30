.section .text
.global main

# simulate buffer overflow
main:
	# tag four consecutive granules

	# counter
	addi	x1, x0, 3 		# x1 = 3
	# start address
	addi	x2, x0, 0x00	# x2 = 0x00
	# color: 0x2aa
	# hart access: 0b1
	# full tag: 0xf55
    addi	x3, x0, 0x555	# x3 = 0x555

	# tag current granule and get start address with encoded
	# color in x4
	#
    # custom instruction: tadr
    # tadr x4, x2, x3
    #           opcode6     func3   func7   rd  rs1 rs2
    .insn   r   CUSTOM_0,   0,      0,      x4, x2, x3

tagloop:
    # counter - 1
	addi	x1, x1, -1 		# x1 -= 1

	# calculate next granule address, which is eight addresses further
	addi	x2, x2, 8 		# x2 += 8

	# tag granule
    # custom instruction: tadr
    # tadr x0, x2, x3
    #           opcode6     func3   func7   rd  rs1 rs2
    .insn   r   CUSTOM_0,   0,      0,      x0, x2, x3

	# loop if counter (x1) != 0
	bnez 	x1, tagloop

	## read from tagged granules + 1 (8 byte in each of the four granules)
	# counter
	addi	x1, x0, 33 		# x1 = 33

readloop:
    # successful memory load operation, unless counter (x1) is < 1
    lb      x5, 0(x4)		# will fail if there is a hart (or color) mismatch

    # counter - 1
	addi	x1, x1, -1 		# x1 -= 1
	# next address
	addi	x4, x4, 1 		# address = address + 1

	# loop if counter (x1) != 0
	bnez	x1, readloop
