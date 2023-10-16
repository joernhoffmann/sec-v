// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023
 *
 * Project  : Memory Tagged SEC-V
 * Author   : Till Mahlburg
 * Purpose  : Tests of the SEC-V memory tagging function unit.
 */

`include "svut_h.sv"
`include "../mtag.sv"
`include "../ram_wb.sv"

module mtag_testbench();
    `SVUT_SETUP

    parameter int TLEN          = 16;
    parameter int GRANULARITY   = 8;

    parameter int MADR_WIDTH    = 8; // memory address width (address portion of a pointer)
    parameter int TADR_WIDTH    = TLEN; // address width within the tag memory

    logic   clk_i;
    logic   rst_i;

    // tag memory
    logic                       tmem_cyc_o;
    logic                       tmem_stb_o;
    logic                       tmem_sel_o;
    logic [TADR_WIDTH-1 : 0]    tmem_adr_o;
    logic                       tmem_we_o;
    logic [TLEN-1 : 0]          tmem_dat_o;
    logic [TLEN-1 : 0]          tmem_dat_i;
    logic                       tmem_ack_i;

    funit_in_t  fu_i;
    funit_out_t fu_o;

    mtag #(
        .TLEN(TLEN),
        .GRANULARTIY(GRANULARITY),
        .ADR_WIDTH(MADR_WIDTH),
        .TADR_WIDTH(TADR_WIDTH)
    ) dut (
        .fu_i      (fu_i),
        .fu_o      (fu_o),

        // Wishbone tag memory interface
        .tmem_cyc_o (tmem_cyc_o),
        .tmem_stb_o (tmem_stb_o),
        .tmem_sel_o (tmem_sel_o),
        .tmem_adr_o (tmem_adr_o),
        .tmem_we_o  (tmem_we_o),
        .tmem_dat_o (tmem_dat_o),
        .tmem_dat_i (tmem_dat_i),
        .tmem_ack_i (tmem_ack_i)
    );

    ram_wb #(
        .RESET_MEM(1),
        .ADR_WIDTH(MADR_WIDTH),
        .DAT_WIDTH(TLEN)
    ) tmem (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .cyc_i  (tmem_cyc_o),
        .stb_i  (tmem_stb_o),
        .sel_i  (tmem_sel_o),
        .adr_i  (tmem_adr_o),
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
    //     $dumpfile("mtag_testbench.vcd");
    //     $dumpvars(0, mtag_testbench);
    // end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        //
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUIE("MTAG")

    `TEST_SUITE_END
endmodule
