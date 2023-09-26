// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Tests of the SEC-V ALU decoder.
 */

`include "svut_h.sv"
`include "../alu_decoder.sv"

module alu_decoder_testbench();
    `SVUT_SETUP

    inst_t      inst_i;
    inst_i_t    i_inst;
    inst_r_t    r_inst;

    alu_op_t    op_o;
    logic       err_o;

    alu_decoder
    dut (
        .inst_i (inst_i),
        .op_o   (op_o),
        .err_o  (err_o)
    );

    // To create a clock:
    // initial aclk = 0;
    // always #2 aclk = ~aclk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("alu_decoder_testbench.vcd");
    //     $dumpvars(0, alu_decoder_testbench);
    // end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        inst_i = 'b0;
        r_inst = 'b0;
        i_inst = 'b0;
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("TESTSUITE_NAME")

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

    // --- Misc ---
    `UNIT_TEST("Do not decode other ops")
            r_inst.opcode = OPCODE_LUI;
            r_inst.funct3 = FUNCT3_ALU_AND;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_NONE);
            `FAIL_IF_NOT(err_o);
        `UNIT_TEST_END

    // --- AND ---
        `UNIT_TEST("64 reg: decode AND")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_AND;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_AND);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode AND")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_AND;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_AND);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode AND")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_AND;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_AND);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode AND")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_AND;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_AND);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // --- OR ---
        `UNIT_TEST("64 reg: decode OR")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_OR;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_OR);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode OR")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_OR;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_OR);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode OR")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_OR;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_OR);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode OR")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_OR;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_OR);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // --- XOR ---
        `UNIT_TEST("64 reg: decode XOR")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_XOR;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_XOR);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode XOR")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_XOR;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_XOR);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode XOR")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_XOR;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_XOR);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode XOR")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_XOR;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_XOR);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // ADD ? SUB
        `UNIT_TEST("64 reg: decode ADD")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h0;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_ADD);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 reg: decode SUB")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h20;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SUB);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 reg: decode ADD/SUB with invalid funct7 should fail")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h1;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_NONE);
            `FAIL_IF_NOT(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode ADD")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h0;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_ADD);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode SUB should fail")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h20;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_NONE);
            `FAIL_IF_NOT(err_o);
        `UNIT_TEST_END

    // ADDW ? SUBW (32-bit)
        `UNIT_TEST("32 reg: decode ADDW")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h0;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_ADDW);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode SUBW")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h20;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SUBW);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode ADDW/SUBW with invalid funct7 should fail")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h1;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_NONE);
            `FAIL_IF_NOT(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode ADDW")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h0;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_ADDW);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode SUBW should fail")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_ADD;
            r_inst.funct7 = 7'h20;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_NONE);
            `FAIL_IF_NOT(err_o);
        `UNIT_TEST_END

    // SLL - shift left logic
        `UNIT_TEST("64 reg: decode SLL")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_SLL;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLL);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode SLL")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_SLL;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLL);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode SLL")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_SLL;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLLW);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode SLL")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_SLL;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLLW);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // SRL ? SRA - shift right logic ? arithmetic
        `UNIT_TEST("64 reg: decode SRL")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h0;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SRL);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 reg: decode SRA")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h20;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SRA);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 reg: decode SRL/SRA with invalid funct7 should fail")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h1;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_NONE);
            `FAIL_IF_NOT(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode SRL")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h0;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SRL);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode SRA")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h20;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SRA);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // SRLW ? SRAW (32-bit) - shift right logic ? arithmetic
        `UNIT_TEST("32 reg: decode SRLW")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h0;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SRLW);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode SRAW")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h20;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SRAW);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode SRLW/SRAW with invalid funct7 should fail")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h1;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_NONE);
            `FAIL_IF_NOT(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode SRLW")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h0;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SRLW);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode SRAW should fail")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_SRL;
            r_inst.funct7 = 7'h20;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SRAW);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // SLT - set less then
        `UNIT_TEST("64 reg: decode SLT")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_SLT;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLT);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode SLT")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_SLT;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLT);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode SLT")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_SLT;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLT);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode SLT")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_SLT;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLT);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // SLTU - Set less than unsigned
        `UNIT_TEST("64 reg: decode SLTU")
            r_inst.opcode = OPCODE_OP;
            r_inst.funct3 = FUNCT3_ALU_SLTU;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLTU);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("64 imm: decode SLTU")
            r_inst.opcode = OPCODE_OP_IMM;
            r_inst.funct3 = FUNCT3_ALU_SLTU;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLTU);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 reg: decode SLTU")
            r_inst.opcode = OPCODE_OP_32;
            r_inst.funct3 = FUNCT3_ALU_SLTU;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLTU);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("32 imm: decode SLTU")
            r_inst.opcode = OPCODE_OP_IMM_32;
            r_inst.funct3 = FUNCT3_ALU_SLTU;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, ALU_OP_SLTU);
            `FAIL_IF(err_o);
        `UNIT_TEST_END



    `TEST_SUITE_END

endmodule
