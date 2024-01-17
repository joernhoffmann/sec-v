// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2024
 *
 * Project  : Memory Tagged SEC-V
 * Author   : Till Mahlburg
 * Purpose  : Tests of the SEC-V tag memory.
 */

`include "svut_h.sv"
`include "../mtag_mem.sv"

module mtag_mem_testbench();
    `SVUT_SETUP

    // Tag memory data width
    parameter int TDAT_WIDTH = 16;
    // Tag memory adress width
    parameter int TADR_WIDTH = 8;

    logic clk;
    logic rst;

    logic [TADR_WIDTH-1:0]  radr;
    logic [TDAT_WIDTH-1:0]  rdat;
    logic                   re;
    logic                   rack;

    logic [TADR_WIDTH-1:0]  wadr;
    logic [TDAT_WIDTH-1:0]  wdat;
    logic                   we;
    logic                   wack;

    mtag_mem #(
        .ADR_WIDTH(TADR_WIDTH),
        .DAT_WIDTH(TDAT_WIDTH),
        .RESET_MEM(0)
    ) dut (
        .clk_i  (clk),
        .rst_i  (rst),

        .radr_i (radr),
        .dat_o  (rdat),
        .re_i   (re),
        .rack_o (rack),

        .wadr_i (wadr),
        .dat_i  (wdat),
        .we_i   (we),
        .wack_o (wack)
    );

    // Clock
    initial clk = 0;
    always #2 clk = ~clk;

    // To dump data for visualization:
    initial begin
        $dumpfile("mtag_mem_testbench.vcd");
        $dumpvars(0, mtag_mem_testbench);
    end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        // runs when a test begins
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("MTAG_MEM")

    `UNIT_TEST("Do nothing, if not enabled")
        // initial setup
        rst = 1'b1;
        #4
        rst = 1'b0;

        re      = 1'b0;
        we      = 1'b0;
        radr    = 'hAA;
        wadr    = 'hBB;
        wdat    = 'hABCD;
        #4
        `FAIL_IF_NOT_EQUAL(rdat, 0)
        `FAIL_IF_NOT_EQUAL(rack, 0)
        `FAIL_IF_NOT_EQUAL(wack, 0)
    `UNIT_TEST_END

    `UNIT_TEST("Write")
        we      = 1'b1;
        wadr    = 'hAA;
        wdat    = 'hABCD;
        #4
        `FAIL_IF_NOT_EQUAL(rdat, 0)
        `FAIL_IF_NOT_EQUAL(rack, 0)
        `FAIL_IF_NOT_EQUAL(wack, 1'b1)
    `UNIT_TEST_END

    `UNIT_TEST("Read")
        we      = 1'b0;
        re      = 1'b1;
        radr    = 'hAA;
        #4
        `FAIL_IF_NOT_EQUAL(rdat, 'hABCD)
        `FAIL_IF_NOT_EQUAL(rack, 1'b1)
        `FAIL_IF_NOT_EQUAL(wack, 0)
    `UNIT_TEST_END

    `UNIT_TEST("Read and write")
        we = 1'b0;
        re = 1'b0;
        #4
        `FAIL_IF_NOT_EQUAL(rdat, 0)
        `FAIL_IF_NOT_EQUAL(rack, 0)
        `FAIL_IF_NOT_EQUAL(wack, 0)

        we      = 1'b1;
        re      = 1'b1;
        radr    = 'hAA;
        wadr    = 'hBB;
        wdat    = 'h1234;
        #4
        `FAIL_IF_NOT_EQUAL(rdat, 'hABCD)
        `FAIL_IF_NOT_EQUAL(rack, 1'b1)
        `FAIL_IF_NOT_EQUAL(wack, 1'b1)
    `UNIT_TEST_END

    `UNIT_TEST("Last write correct?")
        we      = 1'b0;
        re      = 1'b1;
        radr    = 'hBB;
        #4
        `FAIL_IF_NOT_EQUAL(rdat, 'h1234)
        `FAIL_IF_NOT_EQUAL(rack, 1'b1)
        `FAIL_IF_NOT_EQUAL(wack, 0)
    `UNIT_TEST_END
    `TEST_SUITE_END

endmodule
