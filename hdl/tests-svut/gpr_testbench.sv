// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Tests general purpose register file
 */

`include "svut_h.sv"
`include "../gpr.sv"

module gpr_testbench();
    `SVUT_SETUP

    parameter int XLEN = secv_pkg::XLEN;

    logic clk_i;
    logic rst_i;
    regadr_t            rs1_adr_i;
    logic [XLEN-1:0]    rs1_dat_o;
    regadr_t            rs2_adr_i;
    logic [XLEN-1:0]    rs2_dat_o;
    regadr_t            rd_adr_i;
    logic [XLEN-1:0]    rd_dat_i;
    logic               rd_wb_i;

    gpr #(
    .XLEN (XLEN)
    ) dut (
        .clk_i     (clk_i),
        .rst_i     (rst_i),
        .rs1_adr_i (rs1_adr_i),
        .rs1_dat_o (rs1_dat_o),
        .rs2_adr_i (rs2_adr_i),
        .rs2_dat_o (rs2_dat_o),
        .rd_adr_i  (rd_adr_i),
        .rd_dat_i  (rd_dat_i),
        .rd_wb_i   (rd_wb_i)
    );


    // To create a clock:
    // initial aclk = 0;
    // always #2 aclk = ~aclk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("gpr_testbench.vcd");
    //     $dumpvars(0, gpr_testbench);
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

    `UNIT_TEST("TESTCASE_NAME")

        // Describe here the testcase scenario
        //
        // Because SVUT uses long nested macros, it's possible
        // some local variable declaration leads to compilation issue.
        // You should declare your variables after the IOs declaration to avoid that.

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
