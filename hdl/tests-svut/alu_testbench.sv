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

    `TEST_SUITE("ALU Tests (64-bit)")
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

    // Enable
        `UNIT_TEST("enable off")
            fu_i.ena    = 1'b0;
            #1 `FAIL_IF_NOT_EQUAL(fu_o.rdy, 0);
        `UNIT_TEST_END

    // Operation
        // op 0 = NO_ALU operation - invalid op value not possible because the 4 bit op variable is used completely
        // Therefor no error bit can be set 
        `UNIT_TEST("enable on - invalid op")
            fu_i.ena    = 1'b1;
            fu_i.op     = 0;
            #1 `FAIL_IF_NOT_EQUAL(fu_o.rdy, 1);
            #1 `FAIL_IF_NOT_EQUAL(fu_o.err, 0);
            #1 `FAIL_IF_NOT_EQUAL(fu_o.res, 0);
            #1 `FAIL_IF_NOT_EQUAL(fu_o.res_wb, 1);
        `UNIT_TEST_END

        `UNIT_TEST("enable on - valid op ALU_ADD")
            fu_i.ena    = 1'b1;
            fu_i.op     = 4;
            fu_i.src1   = 1;
            fu_i.src2   = 1;
            #1 `FAIL_IF_NOT_EQUAL(fu_o.rdy, 1);
            #1 `FAIL_IF_NOT_EQUAL(fu_o.err, 0);
            #1 `FAIL_IF_NOT_EQUAL(fu_o.res, 2);
            #1 `FAIL_IF_NOT_EQUAL(fu_o.res_wb, 1);       
        `UNIT_TEST_END

        



    `TEST_SUITE_END

endmodule
