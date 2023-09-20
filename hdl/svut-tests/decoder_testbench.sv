// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Tests SEC-V decoder
 */

// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

// Specify the module to load or on files.f
`include "../decoder.sv"

module decoder_testbench();
    `SVUT_SETUP

    inst_t              inst_i;
    regadr_t            rs1_o;
    regadr_t            rs2_o;
    regadr_t            rd_o;
    funit_t             funit_o;
    alu_op_t            alu_op_o;
    imm_t               imm_o;
    imm_t               imm;

    decoder dut (
        .inst_i     (inst_i),
        .rs1_adr_o  (rs1_o),
        .rs2_adr_o  (rs2_o),
        .rd_adr_o   (rd_o),
        .imm_o      (imm_o),
        .funit_o    (funit_o)
    );

    // To create a clock:
    // initial aclk = 0;
    // always #2 aclk = ~aclk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("decode_testbench.vcd");
    //     $dumpvars(0, decode_testbench);
    // end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        // setup() runs when a test begins
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("Decoder function tests")
    //  Available macros:"
    //
    //    - `MSG("message"):       Print a raw white message
    //    - `INFO("message"):      Print a blue message with INFO: prefix
    //    - `SUCCESS("message"):   Print a green message if SUCCESS: prefix
    //    - `WARNING("message"):   Print an orange message with WARNING: prefix and increment warning counter
    //    - `CRITICAL("message"):  Print a purple message with CRITICAL: prefix and increment critical counter
    //    - `ERROR("message"):     Print a red message with ERROR: prefix and increment error counter
    //
    //    - `FAIL_IF(aSignal):                 Increment error counter if evaluaton is true
    //    - `FAIL_IF_NOT(aSignal):             Increment error coutner if evaluation is false
    //    - `FAIL_IF_EQUAL(aSignal, 23):       Increment error counter if evaluation is equal
    //    - `FAIL_IF_NOT_EQUAL(aSignal, 45):   Increment error counter if evaluation is not equal
    //    - `ASSERT(aSignal):                  Increment error counter if evaluation is not true
    //    - `ASSERT((aSignal == 0)):           Increment error counter if evaluation is not true
    //
    //  Available flag:
    //
    //    - `LAST_STATUS: tied to 1 is last macro did experience a failure, else tied to 0

    // -------------------------------------------------------------------------------------------------------------- //
    // Instruction type decoding
    // -------------------------------------------------------------------------------------------------------------- //
    `UNIT_TEST("Decode I-type immediate")
        inst_i = 64'bx111_1111_1100_zzzz_zzzz_zzzz_zzzz_zzzz;
        imm = decode_imm_i(inst_i);

        #1 `FAIL_IF_NOT_EQUAL(imm, 64'bxxxx_xxxx_xxxx_xxxx_xxxx_x111_1111_1100);
    `UNIT_TEST_END

    `UNIT_TEST("Decode S-type immediate")
        inst_i = 64'bx111_101z_zzzz_zzzz_zzzz_0110_1zzz_zzzz;
        imm = decode_imm_s(inst_i);

        #1 `FAIL_IF_NOT_EQUAL(imm, 64'bxxxx_xxxx_xxxx_xxxx_xxxx_x111_1010_1101);
    `UNIT_TEST_END

    `UNIT_TEST("Decode B-type immediate")
        inst_i = 64'bx111_0110_0000_0000_0000_0101_1zzz_zzzz;
        imm = decode_imm_b(inst_i);

        #1 `FAIL_IF_NOT_EQUAL(imm, 64'bxxx_xxxx_xxx_xxxx_xxxx_1111_0110_1010);
    `UNIT_TEST_END

    `UNIT_TEST("Decode U-type immediate")
        inst_i = 64'bx101_1110_0110_0011_1001_zzzz_zzzz_zzzz;
        imm = decode_imm_u(inst_i);

        #1 `FAIL_IF_NOT_EQUAL(imm, 64'bx101_1110_0110_0011_1001_0000_0000_0000);
    `UNIT_TEST_END

    `UNIT_TEST("Decode J-type immediate")
        inst_i = 64'bx_1111010010_0_00110101_zzzz_zzzz_zzzz;
        imm = decode_imm_j(inst_i);

        #1 `FAIL_IF_NOT_EQUAL(imm, 64'bxxxx_xxxx_xxxx_00110101_0_1111010010_0);
    `UNIT_TEST_END

    // -------------------------------------------------------------------------------------------------------------- //
    // Function unit selection
    // -------------------------------------------------------------------------------------------------------------- //
    `UNIT_TEST("Check selection of MOV unit")
        inst_i = {25'bx, OPCODE_LUI};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_MOV);

        inst_i = {25'bx, OPCODE_AUIPC};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_MOV);
    `UNIT_TEST_END

    `UNIT_TEST("Check selection of BRANCH unit")
        inst_i = {25'bx, OPCODE_BRANCH};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_BRANCH);

        inst_i = {25'bx, OPCODE_JAL};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_BRANCH);

        inst_i = {25'bx, OPCODE_JALR};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_BRANCH);
    `UNIT_TEST_END

    `UNIT_TEST("Check selection of MEM unit")
        inst_i = {25'bx, OPCODE_LOAD};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_MEM);

        inst_i = {25'bx, OPCODE_STORE};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_MEM);

        inst_i = {25'bx, OPCODE_MISC_MEM};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_MEM);
    `UNIT_TEST_END

    `UNIT_TEST("Check selection of ALU")
        inst_i = {25'bx, OPCODE_OP};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_ALU);

        inst_i = {25'bx, OPCODE_OP_32};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_ALU);

        inst_i = {25'bx, OPCODE_OP_IMM};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_ALU);

        inst_i = {25'bx, OPCODE_OP_IMM_32};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_ALU);
    `UNIT_TEST_END

   `UNIT_TEST("Check selection of no unit with wrong opcode")
        inst_i = {25'bx, 7'b00000_00};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);

        inst_i = {25'bx, 7'b00000_01};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);

        inst_i = {25'bx, 7'b00000_10};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);

        inst_i = {25'bx, 7'b11100_11};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);

        inst_i = {25'bx, 7'b11111_11};
        #1 `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);
    `UNIT_TEST_END

    // -------------------------------------------------------------------------------------------------------------- //
    // ALU operation decoding
    // -------------------------------------------------------------------------------------------------------------- //
    `TEST_SUITE_END


endmodule
