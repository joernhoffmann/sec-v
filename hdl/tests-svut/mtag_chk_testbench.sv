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
    parameter int ADR_WIDTH = 8;
    /* tag memory address width in bit */
    parameter int TADR_WIDTH = 16;
    /* tag memory byte selection width */
    parameter int TSEL_WIDTH = TLEN / 8;

    logic clk, rst;

    logic ena;
    logic [XLEN-1 : 0] adr;
    logic err;
    logic [XLEN-1 : 0] err_adr;

    logic                       tmem_cyc_o;
    logic                       tmem_stb_o;
    logic [TSEL_WIDTH-1 : 0]    tmem_sel_o;
    logic [TADR_WIDTH-1 : 0]    tmem_adr_o;
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
        .err_adr_o  (err_adr),

        .tmem_cyc_o (tmem_cyc_o),
        .tmem_stb_o (tmem_stb_o),
        .tmem_sel_o (tmem_sel_o),
        .tmem_adr_o (tmem_adr_o),
        .tmem_dat_i (tmem_dat_i),
        .tmem_ack_i (tmem_ack_i)
    );

    ram_wb #(
        .ADR_WIDTH(TADR_WIDTH),
        .DAT_WIDTH(TLEN)
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
    // initial begin
    //     $dumpfile("mtag_chk_testbench.vcd");
    //     $dumpvars(0, mtag_chk_testbench);
    // end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        rst = 0;
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("MTAG_CHK")


    `TEST_SUITE_END
endmodule
