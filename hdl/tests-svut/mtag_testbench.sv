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

    parameter int TSEL_WIDTH    = TLEN / 8; // tag memory byte selection width

    logic   clk;
    logic   rst;

    // tag memory
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

    funit_in_t  fu_i;
    funit_out_t fu_o;

    mtag #(
        .TLEN(TLEN),
        .GRANULARITY(GRANULARITY),
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
    always #1 clk = ~clk;

    // To dump data for visualization:
    //initial begin
    //    $dumpfile("mtag_testbench.vcd");
    //    $dumpvars(0, mtag_testbench);
    //end

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

    `TEST_SUITE("MTAG")

    /*** MISC ***/
    `UNIT_TEST("Disabled unit should not be ready")
        fu_i.ena = 1'b0;
        #1 `FAIL_IF_NOT_EQUAL(fu_o.rdy, 0);
    `UNIT_TEST_END

    `UNIT_TEST("Enabled, but error and not writing to memory if MTAG_OP_NONE")
        fu_i.ena = 1'b1;
        fu_i.op = MTAG_OP_NONE;
        fu_i.src1 = 1;
        fu_i.src2 = 2;
        #1
        `FAIL_IF_NOT_EQUAL(fu_o.rdy, 1);
        `FAIL_IF_NOT_EQUAL(fu_o.err, 1);
        `FAIL_IF_NOT_EQUAL(tmem_we_o, 0);
    `UNIT_TEST_END

    /*** MEMORY ***/
    `UNIT_TEST("Expose correct tag and tag memory address on MTAG_OP_TADR")
        fu_i.ena = 1'b1;
        fu_i.op = MTAG_OP_TADR;
        fu_i.src1 = 'h214A__0000_0000_0032; // Tag: 0x214A_0032 = 8522 | Address: 0x32 = 50
        fu_i.src2 = 0; // ignored
        #1
        `FAIL_IF_NOT_EQUAL(fu_o.rdy, 1);
        `FAIL_IF_NOT_EQUAL(fu_o.err, 0);
        `FAIL_IF_NOT_EQUAL(tmem_we_o, 1);
        `FAIL_IF_NOT_EQUAL(tmem_cyc_o, 1);
        `FAIL_IF_NOT_EQUAL(tmem_stb_o, 1);
        `FAIL_IF_NOT_EQUAL(tmem_sel_o, '1);
        `FAIL_IF_NOT_EQUAL(tmem_dat_o, 8522);
        // Tag address = address / GRANULARITY | 50 / 8 = 6
        `FAIL_IF_NOT_EQUAL(tmem_adr_o, 6);
    `UNIT_TEST_END

    `UNIT_TEST("Write successfully to memory on MTAG_OP_TADR")
        tmem_adr_i = tmem_adr_o;
        tmem_cyc_i = tmem_cyc_o;
        tmem_stb_i = tmem_stb_o;
        tmem_sel_i = tmem_sel_o;
        #2
        fu_i.ena = 1'b0;
        #2
        `FAIL_IF_NOT_EQUAL(tmem_dat_i, 8522);
    `UNIT_TEST_END

    `TEST_SUITE_END
endmodule
