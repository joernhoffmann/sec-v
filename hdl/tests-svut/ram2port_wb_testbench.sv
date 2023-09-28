// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : 2-port RAM testbench
 *
 * History
 *  v1.0    - Initial version
 */

`include "svut_h.sv"
`include "ram2port_wb.sv"
`timescale 1 ns / 100 ps

module ram2port_wb_testbench();

    `SVUT_SETUP

    parameter int ADDR_WIDTH    = 8;
    parameter int INST_WIDTH    = 32;
    parameter int DATA_WIDTH    = 64;
    parameter logic RESET_MEM   = 0;
    parameter ISEL_WIDTH        = INST_WIDTH / 8;
    parameter DSEL_WIDTH        = DATA_WIDTH / 8;

    logic                    clk_i;
    logic                    rst_i;
    logic                    cyc1_i;
    logic                    stb1_i;
    logic [ISEL_WIDTH-1 : 0] sel1_i;
    logic [ADDR_WIDTH-1 : 0] adr1_i;
    logic [INST_WIDTH-1 : 0] dat1_o;
    logic                    ack1_o;
    logic                    cyc2_i;
    logic                    stb2_i;
    logic [DSEL_WIDTH-1 : 0] sel2_i;
    logic [ADDR_WIDTH-1 : 0] adr2_i;
    logic                     we2_i;
    logic [DATA_WIDTH-1 : 0] dat2_i;
    logic [DATA_WIDTH-1 : 0] dat2_o;
    logic                    ack2_o;

    ram2port_wb
    #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .INST_WIDTH (INST_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .RESET_MEM (RESET_MEM)
    )
    dut
    (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .cyc1_i (cyc1_i),
        .stb1_i (stb1_i),
        .sel1_i (sel1_i),
        .adr1_i (adr1_i),
        .dat1_o (dat1_o),
        .ack1_o (ack1_o),
        .cyc2_i (cyc2_i),
        .stb2_i (stb2_i),
        .sel2_i (sel2_i),
        .adr2_i (adr2_i),
        .we2_i  (we2_i),
        .dat2_i (dat2_i),
        .dat2_o (dat2_o),
        .ack2_o (ack2_o)
    );


    // To create a clock:
    // initial aclk = 0;
    // always #2 aclk = ~aclk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("ram_2port_wb_testbench.vcd");
    //     $dumpvars(0, ram_2port_wb_testbench);
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

    `TEST_SUITE("RAM_2PORT_WB")

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
