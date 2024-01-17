// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023
 *
 * Project  : Memory Tagged SEC-V
 * Author   : Till Mahlburg
 * Purpose  : Tests of the SEC-V memory tagging checker.
 */

`include "svut_h.sv"
`include "../mtag_chk.sv"
`include "../mtag_mem.sv"

module mtag_chk_testbench();
    `SVUT_SETUP

    parameter int HARTS = 4;        // Amount of harts
    parameter int TLEN = 16;        // Size of tags in bit
    parameter int GRANULARITY = 8;  // Size of granules in byte
    parameter int ADR_WIDTH = 16;   // Address size in bit
    parameter int TADR_WIDTH = 16;   // Tag memory address width in bit

    logic clk, rst;

    logic ena;
    logic [XLEN-1 : 0] adr;
    logic err;

    logic                       tmem_re;
    logic [TADR_WIDTH-1 : 0]    tmem_radr;
    logic [TLEN-1 : 0]          tmem_rdat;
    logic                       tmem_rack;

    logic                       tmem_we;
    logic [TADR_WIDTH-1 : 0]    tmem_wadr;
    logic [TLEN-1 : 0]          tmem_wdat;
    logic                       tmem_wack;

    mtag_chk #(
        .HARTS(HARTS),
        .TLEN(TLEN),
        .GRANULARITY(GRANULARITY),
        .ADR_WIDTH(ADR_WIDTH),
        .TADR_WIDTH(TADR_WIDTH)
    ) dut (
        .ena_i      (ena),
        .adr_i      (adr),
        .err_o      (err),

        .hart_id    (0),

        .tmem_re_o  (tmem_re),
        .tmem_adr_o (tmem_radr),
        .tmem_dat_i (tmem_rdat),
        .tmem_ack_i (tmem_rack)
    );

    mtag_mem #(
        .ADR_WIDTH(TADR_WIDTH),
        .DAT_WIDTH(TLEN),
        .RESET_MEM(1)
    ) tmem (
        .clk_i  (clk),
        .rst_i  (rst),

        .re_i   (tmem_re),
        .radr_i (tmem_radr),
        .dat_o  (tmem_rdat),
        .rack_o (tmem_rack),

        .we_i   (tmem_we),
        .wadr_i (tmem_wadr),
        .dat_i  (tmem_wdat),
        .wack_o (tmem_wack)
    );

    // To create a clock:
    initial clk = 0;
    always #2 clk = ~clk;

    // To dump data for visualization:
    initial begin
        $dumpfile("mtag_chk_testbench.vcd");
        $dumpvars(0, mtag_chk_testbench);
    end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        rst = 1'b1;
        #2
        rst = 1'b0;
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("MTAG_CHK")

    `UNIT_TEST("Do nothing, if not enabled")
         ena = 1'b0;
         #1
         `FAIL_IF_NOT_EQUAL(err, 0);
         `FAIL_IF_NOT_EQUAL(tmem_re, 0);
         `FAIL_IF_NOT_EQUAL(tmem_radr, 0);
    `UNIT_TEST_END

    `UNIT_TEST("No early error")
        ena = 1'b1;
        // Tag: 0x01A = 26
        // Harts: 0xF = 0b1111 (any hart allowed)
        // Address: 0x011F = 287
        adr = 'h01AF_0000_0000_011F;
        #1
        `FAIL_IF_NOT_EQUAL(err, 0);
    `UNIT_TEST_END

    `UNIT_TEST("Error on tag mismatch")
        ena = 1'b1;
        // Tag: 0x01A = 26
        // Harts: 0xF = 0b1111 (any hart allowed)
        // Address: 0x011F = 287
        adr = 'h01AF_0000_0000_011F;
        #4
        `FAIL_IF_NOT_EQUAL(err, 1);
        `FAIL_IF_NOT_EQUAL(tmem_re, '1);
        // Tag address = address / GRANULARITY | 287 / 8 = 35
        `FAIL_IF_NOT_EQUAL(tmem_radr, 35);
        // Tag in memory should be zero, because of memory reset
        `FAIL_IF_NOT_EQUAL(tmem_rdat, 0);
    `UNIT_TEST_END

    `UNIT_TEST("No error if tags and harts match")
        // Write tag in tag memory
        tmem_we = 1'b1;
        // Tag memory address
        tmem_wadr = 35;
        // Tag value
        tmem_wdat = 'h01AF; // 0x01A = 26 | harts: 0xF = 0b1111 (any hart is allowed)

        ena = 1'b0;
        #4
        tmem_we = 1'b0;

        ena = 1'b1;
        // Tag: 0x01A = 26 | Address: 0x011F = 287
        adr = 'h01A0_0000_0000_011F;

        #4
        `FAIL_IF_NOT_EQUAL(err, 0);
        `FAIL_IF_NOT_EQUAL(tmem_re, '1);
        // Tag address = address / GRANULARITY | 287 / 8 = 35
        `FAIL_IF_NOT_EQUAL(tmem_radr, 35);
        `FAIL_IF_NOT_EQUAL(tmem_rdat, 'h01AF);
    `UNIT_TEST_END

    `UNIT_TEST("Error on hart mismatch")
        // Write tag in tag memory
        tmem_we = 1'b1;
        // Tag memory address
        tmem_wadr = 483;
        // Tag value
        tmem_wdat = 'hAF1E; // 0xAF1 = 2801 | harts: 0xF = 0b1110 (hart 0 is forbidden)

        ena = 1'b0;
        #4
        tmem_we = 1'b0;

        ena = 1'b1;
        // Tag: 0xAF1 = 2801 | Address: 0x0F1B = 3867
        adr = 'hAF10_0000_0000_0F1B;

        #4
        `FAIL_IF_NOT_EQUAL(err, 1);
        `FAIL_IF_NOT_EQUAL(tmem_re, '1);
        // Tag address = address / GRANULARITY | 3867 / 8 = 483
        `FAIL_IF_NOT_EQUAL(tmem_radr, 483);
        `FAIL_IF_NOT_EQUAL(tmem_rdat, 'hAF1E);
    `UNIT_TEST_END

    `TEST_SUITE_END
endmodule
