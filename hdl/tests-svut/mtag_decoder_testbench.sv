
// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023 - 2024
 *
 * Project  : Memory Tagged SEC-V
 * Author   : Till Mahlburg
 * Purpose  : Tests of the SEC-V memory tagging decoder.
 */

`include "svut_h.sv"
`include "../mtag_decoder.sv"

module mtag_decoder_testbench();
    `SVUT_SETUP

    inst_t      inst_i;
    inst_r_t    r_inst;

    mtag_op_t    op_o;
    logic       err_o;

    mtag_decoder
    dut (
        .inst_i (inst_i),
        .op_o   (op_o),
        .err_o  (err_o)
    );

    // To create a clock:
    // initial aclk = 0;
    // always #2 aclk = ~aclk;

    // To dump data for visualization:
    initial begin
        $dumpfile("mtag_decoder_testbench.vcd");
        $dumpvars(0, mtag_decoder_testbench);
    end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        inst_i = 'b0;
        r_inst = 'b0;
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("MTAG_DECODER")
    // -------------------------------------------------------------------------------------------------------------- //
    // --- Misc ---
    // -------------------------------------------------------------------------------------------------------------- //
    `UNIT_TEST("Do not decode other ops")
            r_inst.opcode = OPCODE_LUI;
            r_inst.funct3 = FUNCT3_MTAG_TADR;
            inst_i = r_inst;
            #1
            `FAIL_IF_NOT_EQUAL(op_o, MTAG_OP_NONE);
            `FAIL_IF_NOT(err_o);
        `UNIT_TEST_END

    // -------------------------------------------------------------------------------------------------------------- //
    // --- OPs ---
    // -------------------------------------------------------------------------------------------------------------- //
    `UNIT_TEST("decode CUSTOM_0 TADR")
        r_inst.opcode = OPCODE_CUSTOM_0;
        r_inst.funct3 = FUNCT3_MTAG_TADR;
        inst_i = r_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MTAG_OP_TADR);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode CUSTOM_0 TADRE")
        r_inst.opcode = OPCODE_CUSTOM_0;
        r_inst.funct3 = FUNCT3_MTAG_TADRE;
        inst_i = r_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MTAG_OP_TADRE);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("decode CUSTOM_0 TADRR")
        r_inst.opcode = OPCODE_CUSTOM_0;
        r_inst.funct3 = FUNCT3_MTAG_TADRR;
        inst_i = r_inst;
        #1
        `FAIL_IF_NOT_EQUAL(op_o, MTAG_OP_TADRR);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `TEST_SUITE_END
endmodule
