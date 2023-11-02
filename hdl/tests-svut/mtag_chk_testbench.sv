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
`include "../ram_wb.sv"

module mtag_chk_testbench();
    `SVUT_SETUP

    /* size of tags in bit */
    parameter int TLEN = 16;
    /* size of granules in byte */
    parameter int GRANULARITY = 8;
    /* address size in bit */
    parameter int ADR_WIDTH = 16;
    /* tag memory address width in bit */
    parameter int TADR_WIDTH = 16;
    /* tag memory byte selection width */
    parameter int TSEL_WIDTH = TLEN / 8;

    logic clk, rst;

    logic ena;
    logic [XLEN-1 : 0] adr;
    logic err;

    logic                       tmem_cyc_o;
    logic                       tmem_cyc_i;
    logic                       tmem_stb_o;
    logic                       tmem_stb_i;
    logic [TSEL_WIDTH-1 : 0]    tmem_sel_o;
    logic [TSEL_WIDTH-1 : 0]    tmem_sel_i;
    logic [TADR_WIDTH-1 : 0]    tmem_adr_o;
    logic [TADR_WIDTH-1 : 0]    tmem_adr_i;
    logic                       tmem_we_o;
    logic [TLEN-1 : 0]          tmem_dat_o;
    logic [TLEN-1 : 0]          tmem_dat_i;
    logic                       tmem_ack_i;

    mtag_chk #(
        .TLEN(TLEN),
        .GRANULARITY(GRANULARITY),
        .ADR_WIDTH(ADR_WIDTH),
        .TADR_WIDTH(TADR_WIDTH),
        .TSEL_WIDTH(TSEL_WIDTH)
    ) dut (
        .ena_i      (ena),
        .adr_i      (adr),
        .err_o      (err),

        .tmem_cyc_o (tmem_cyc_o),
        .tmem_stb_o (tmem_stb_o),
        .tmem_sel_o (tmem_sel_o),
        .tmem_adr_o (tmem_adr_o),
        .tmem_dat_i (tmem_dat_i),
        .tmem_ack_i (tmem_ack_i)
    );

    ram_wb #(
        .ADR_WIDTH(TADR_WIDTH),
        .DAT_WIDTH(TLEN),
        .RESET_MEM(1)
    ) tmem (
        .clk_i  (clk),
        .rst_i  (rst),
        .cyc_i  (tmem_cyc_i),
        .stb_i  (tmem_stb_i),
        .sel_i  (tmem_sel_i),
        .adr_i  (tmem_adr_i),
        .we_i   (tmem_we_o),
        .dat_i  (tmem_dat_o),
        .dat_o  (tmem_dat_i),
        .ack_o  (tmem_ack_i)
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
        rst = 1;
        #2
        rst = 0;
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
         `FAIL_IF_NOT_EQUAL(err_adr, 0);
         `FAIL_IF_NOT_EQUAL(tmem_cyc_o, 0);
         `FAIL_IF_NOT_EQUAL(tmem_stb_o, 0);
         `FAIL_IF_NOT_EQUAL(tmem_sel_o, 0);
         `FAIL_IF_NOT_EQUAL(tmem_adr_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("No early error")
        ena = 1'b1;
        // Tag: 0x01AB = 427 | Address: 0x011F = 287
        adr = 'h01AB_0000_0000_011F;
        #1
        `FAIL_IF_NOT_EQUAL(err, 0);
    `UNIT_TEST_END

    `UNIT_TEST("Error on tag mismatch")
        ena = 1'b1;
        // Tag: 0x01AB = 427 | Address: 0x011F = 287
        adr = 'h01AB_0000_0000_011F;
        #1
        tmem_cyc_i = tmem_cyc_o;
        tmem_stb_i = tmem_stb_o;
        tmem_sel_i = tmem_sel_o;
        tmem_adr_i = tmem_adr_o;
        #4
        `FAIL_IF_NOT_EQUAL(err, 1);
        `FAIL_IF_NOT_EQUAL(tmem_cyc_o, '1);
        `FAIL_IF_NOT_EQUAL(tmem_stb_o, '1);
        `FAIL_IF_NOT_EQUAL(tmem_sel_o, '1);
        // Tag address = address / GRANULARITY | 287 / 8 = 35
        `FAIL_IF_NOT_EQUAL(tmem_adr_o, 35);
        // Tag in memory should be zero, because of memory reset
        `FAIL_IF_NOT_EQUAL(tmem_dat_i, 0);
    `UNIT_TEST_END

    `UNIT_TEST("No error if tags match")
        // Write tag in tag memory
        tmem_cyc_i = 1'b1;
        tmem_stb_i = 1'b1;
        tmem_sel_i = '1;
        // Tag memory address
        tmem_adr_i = 35;
        // Tag value
        tmem_dat_o = 'h01AB; // = 427
        tmem_we_o = 1'b1;

        ena = 1'b0;
        #4
        tmem_we_o = 1'b0;
        tmem_dat_o = '0;
        ena = 1'b1;
        // Tag: 0x01AB = 427 | Address: 0x011F = 287
        adr = 'h01AB_0000_0000_011F;
        #1
        tmem_cyc_i = tmem_cyc_o;
        tmem_stb_i = tmem_stb_o;
        tmem_sel_i = tmem_sel_o;
        tmem_adr_i = tmem_adr_o;

        #4
        `FAIL_IF_NOT_EQUAL(err, 0);
        `FAIL_IF_NOT_EQUAL(tmem_cyc_o, '1);
        `FAIL_IF_NOT_EQUAL(tmem_stb_o, '1);
        `FAIL_IF_NOT_EQUAL(tmem_sel_o, '1);
        // Tag address = address / GRANULARITY | 287 / 8 = 35
        `FAIL_IF_NOT_EQUAL(tmem_adr_o, 35);
        `FAIL_IF_NOT_EQUAL(tmem_dat_i, 'h01AB);
    `UNIT_TEST_END

    `TEST_SUITE_END
endmodule
