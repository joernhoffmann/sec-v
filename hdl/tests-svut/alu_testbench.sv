// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Tests of the SEC-V ALU.
 */

`include "svut_h.sv"
`include "../secv_pkg.svh"
`include "../alu.sv"
`include "../alu_core.sv"
`include "../alu_decoder.sv"

module alu_testbench();
    `SVUT_SETUP

    parameter XLEN = 64;
    alu_op_t	op_i;
    funit_in_t  fu_i;
    funit_out_t fu_o;

    /* verilator lint_off UNOPTFLAT */
    logic [XLEN-1:0] 	res_o;

    alu #(
        .XLEN   (XLEN)
    ) dut (
        .fu_i 	 (fu_i),
        .fu_o 	 (fu_o)
    );

/*
    initial begin
        $dumpfile("alu_testbench.vcd");
        $dumpvars(1, alu_testbench);
    end
*/

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        // setup() runs when a test begins
            //fu_i = funit_in_default();
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("ALU_WRAPPER")

    // -------------------------------------------------------------------------------------------------------------- //
    // General operation
    // -------------------------------------------------------------------------------------------------------------- //
    `UNIT_TEST("Disabled ALU should not be ready")
        fu_i.ena    = 1'b0;
        #1 `FAIL_IF_NOT_EQUAL(fu_o.rdy, 0);
    `UNIT_TEST_END

    `UNIT_TEST("Enabled ALU with ALU_OP_NONE should write-back zero")
        fu_i.ena    = 1'b1;
        fu_i.op     = ALU_OP_NONE;
        fu_i.src1   = 1;
        fu_i.src2   = 2;
        #1
        `FAIL_IF_NOT_EQUAL(fu_o.rdy, 1);
        `FAIL_IF_NOT_EQUAL(fu_o.err, 0);
        `FAIL_IF_NOT_EQUAL(fu_o.res, 0);
        `FAIL_IF_NOT_EQUAL(fu_o.res_wb, 1);
    `UNIT_TEST_END

    `UNIT_TEST("Enabled ALU with ALU_OP_ADD should write-back")
        fu_i.ena    = 1'b1;
        fu_i.op     = ALU_OP_ADD;
        fu_i.src1   = 1;
        fu_i.src2   = 2;
        #1
        `FAIL_IF_NOT_EQUAL(fu_o.rdy,    1);
        `FAIL_IF_NOT_EQUAL(fu_o.err,    0);
        `FAIL_IF_NOT_EQUAL(fu_o.res,    3);
        `FAIL_IF_NOT_EQUAL(fu_o.res_wb, 1);
    `UNIT_TEST_END
    `TEST_SUITE_END

endmodule
