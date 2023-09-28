// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Tests of the SEC-V MEM decoder.
 */

`include "svut_h.sv"
`include "../mem_decoder.sv"

module mem_decoder_testbench();
    `SVUT_SETUP

    inst_t      inst_i;
    inst_i_t    i_inst;
    inst_s_t    s_inst;

    mem_op_t    op_o;
    logic       err_o;

    mem_decoder
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
    //     $dumpfile("mem_decoder_testbench.vcd");
    //     $dumpvars(0, mem_decoder_testbench);
    // end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        inst_i = 'b0;
        i_inst = 'b0;
        s_inst = 'b0;
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("MEM_DECODER")
    // -------------------------------------------------------------------------------------------------------------- //
    // --- Misc ---
    // -------------------------------------------------------------------------------------------------------------- //
    `UNIT_TEST("Do not decode other ops")
            i_inst.opcode = OPCODE_LUI;
            i_inst.funct3 = FUNCT3_STORE_SB;
            inst_i = i_inst;           
            #1
            `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_NONE);
            `FAIL_IF_NOT(err_o);
        `UNIT_TEST_END

    // -------------------------------------------------------------------------------------------------------------- //
    // --- LOAD ---
    // -------------------------------------------------------------------------------------------------------------- //
    `UNIT_TEST("decode LOAD_LB")
        i_inst.opcode = OPCODE_LOAD;
        i_inst.funct3 = FUNCT3_LOAD_LB;
        inst_i = i_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_LB);
        `FAIL_IF(err_o);
    `UNIT_TEST_END   

    `UNIT_TEST("decode LOAD_LH")
        i_inst.opcode = OPCODE_LOAD;
        i_inst.funct3 = FUNCT3_LOAD_LH;
        inst_i = i_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_LH);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode LOAD_LW")
        i_inst.opcode = OPCODE_LOAD;
        i_inst.funct3 = FUNCT3_LOAD_LW;
        inst_i = i_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_LW);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode LOAD_LD")
        i_inst.opcode = OPCODE_LOAD;
        i_inst.funct3 = FUNCT3_LOAD_LD;
        inst_i = i_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_LD);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode LOAD_LBU")
        i_inst.opcode = OPCODE_LOAD;
        i_inst.funct3 = FUNCT3_LOAD_LBU;
        inst_i = i_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_LBU);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode LOAD_LHU")
        i_inst.opcode = OPCODE_LOAD;
        i_inst.funct3 = FUNCT3_LOAD_LHU;
        inst_i = i_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_LHU);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode LOAD_LWU")
        i_inst.opcode = OPCODE_LOAD;
        i_inst.funct3 = FUNCT3_LOAD_LWU;
        inst_i = i_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_LWU);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    // -------------------------------------------------------------------------------------------------------------- //
    // --- STORE ---
    // -------------------------------------------------------------------------------------------------------------- //
    `UNIT_TEST("decode STORE_SB")
        s_inst.opcode = OPCODE_STORE;
        s_inst.funct3 = FUNCT3_STORE_SB;
        inst_i = s_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_SB);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode STORE_SH")
        s_inst.opcode = OPCODE_STORE;
        s_inst.funct3 = FUNCT3_STORE_SH;
        inst_i = s_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_SH);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode STORE_SW")
        s_inst.opcode = OPCODE_STORE;
        s_inst.funct3 = FUNCT3_STORE_SW;
        inst_i = s_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_SW);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode STORE_SD")
        s_inst.opcode = OPCODE_STORE;
        s_inst.funct3 = FUNCT3_STORE_SD;
        inst_i = s_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MEM_OP_SD);
        `FAIL_IF(err_o);
    `UNIT_TEST_END    

    `TEST_SUITE_END
endmodule
