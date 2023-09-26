// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Tests SEC-V decoder
 */

`include "svut_h.sv"
`include "../decoder.sv"

module decoder_testbench();
    `SVUT_SETUP

    inst_t              inst_i;

    // Operadns
    regadr_t    rs1_o;
    regadr_t    rs2_o;
    regadr_t    rd_o;
    imm_t       imm;

    // MUX
    funit_t     funit_o;
    src1_sel_t  src1_sel;
    src2_sel_t  src2_sel;
    imm_sel_t   imm_sel;
    rd_sel_t    rd_sel;
    pc_sel_t    pc_sel;

    // Error
    logic       err;

    // Ops
    alu_op_t    alu_op_o;


    decoder dut (
        .inst_i     (inst_i),

        // Opcode

        // Operands
        .rs1_adr_o  (rs1_o),
        .rs2_adr_o  (rs2_o),
        .rd_adr_o   (rd_o),

        // Muxer
        .funit_o    (funit_o),
        .src1_sel_o (src1_sel),
        .src2_sel_o (src2_sel),
        .imm_sel_o  (imm_sel),
        .rd_sel_o   (rd_sel),
        .pc_sel_o   (pc_sel),

        // Errors
        .err_o      (err)
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
    // Opcode decoding checks
    // -------------------------------------------------------------------------------------------------------------- //
    `UNIT_TEST("Check LUI")
        inst_i = {25'bx, OPCODE_LUI};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_NONE);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_0);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_0);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_U);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_IMM);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("AUIPC")
        inst_i = {25'bx, OPCODE_AUIPC};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_ALU);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_PC);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_IMM);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_U);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_FUNIT);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("JAL")
        inst_i = {25'bx, OPCODE_JAL};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_ALU);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_PC);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_IMM);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_J);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_FUNIT);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("JALR")
        inst_i = {25'bx, OPCODE_JALR};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_ALU);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_RS1);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_IMM);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_I);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_FUNIT);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("BRNANCH")
        inst_i = {25'bx, OPCODE_BRANCH};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_ALU);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_PC);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_IMM);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_B);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_NONE);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_BRANCH);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("LOAD")
        inst_i = {25'bx, OPCODE_LOAD};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_MEM);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_RS1);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_IMM);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_I);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_FUNIT);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("STORE")
        inst_i = {25'bx, OPCODE_STORE};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_MEM);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_RS1);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_IMM);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_S);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_FUNIT);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("ALU_OP")
        inst_i = {25'bx, OPCODE_OP};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_ALU);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_RS1);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_RS2);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_0);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_FUNIT);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("ALU_OP_32")
        inst_i = {25'bx, OPCODE_OP_32};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_ALU);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_RS1);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_RS2);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_0);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_FUNIT);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("ALU_OP_IMM")
        inst_i = {25'bx, OPCODE_OP_IMM};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_ALU);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_RS1);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_IMM);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_I);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_FUNIT);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

    `UNIT_TEST("ALU_OP_IMM_32")
        inst_i = {25'bx, OPCODE_OP_IMM_32};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o,  FUNIT_ALU);
        `FAIL_IF_NOT_EQUAL(src1_sel, SRC1_SEL_RS1);
        `FAIL_IF_NOT_EQUAL(src2_sel, SRC2_SEL_IMM);
        `FAIL_IF_NOT_EQUAL(imm_sel,  IMM_SEL_I);
        `FAIL_IF_NOT_EQUAL(rd_sel,   RD_SEL_FUNIT);
        `FAIL_IF_NOT_EQUAL(pc_sel,   PC_SEL_NXTPC);
        `FAIL_IF_NOT_EQUAL(err,      1'b0);
    `UNIT_TEST_END

   `UNIT_TEST("Check selection of FUNIT_NONE with wrong opcode")
        inst_i = {25'bx, 7'b00000_00};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);
        `FAIL_IF_NOT_EQUAL(err,      1'b1);

        inst_i = {25'bx, 7'b00000_01};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);
        `FAIL_IF_NOT_EQUAL(err,      1'b1);

        inst_i = {25'bx, 7'b00000_10};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);
        `FAIL_IF_NOT_EQUAL(err,      1'b1);

        inst_i = {25'bx, 7'b11100_11};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);
        `FAIL_IF_NOT_EQUAL(err,      1'b1);

        inst_i = {25'bx, 7'b11111_11};
        #1
        `FAIL_IF_NOT_EQUAL(funit_o, FUNIT_NONE);
        `FAIL_IF_NOT_EQUAL(err,      1'b1);
    `UNIT_TEST_END

    // -------------------------------------------------------------------------------------------------------------- //
    // ALU operation decoding
    // -------------------------------------------------------------------------------------------------------------- //
    `TEST_SUITE_END


endmodule
