// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023 - 2024
 *
 * Project  : Memory Tagged SEC-V
 * Author   : Till Mahlburg
 * Purpose  : Tests of the SEC-V memory tagging function unit.
 */

`include "svut_h.sv"
`include "../mtag.sv"
`include "../mtag_mem.sv"

module mtag_testbench();
    `SVUT_SETUP

    parameter int TLEN          = 16;
    parameter int GRANULARITY   = 2;

    parameter int MADR_WIDTH    = 8;        // Memory address width (address portion of a pointer)
    parameter int TADR_WIDTH    = MADR_WIDTH - GRANULARITY;

    logic   clk;
    logic   rst;

    // Tag memory
    logic                       tmem_re;
    logic [TADR_WIDTH-1 : 0]    tmem_radr;
    logic [TLEN-1 : 0]          tmem_rdat;
    logic                       tmem_rack;

    logic                       tmem_we;
    logic [TADR_WIDTH-1 : 0]    tmem_wadr;
    logic [TLEN-1 : 0]          tmem_wdat;
    logic                       tmem_wack;

    funit_in_t  fu_i;
    funit_out_t fu_o;

    logic [31:0] rnd;

    mtag #(
        .HARTS(4),
        .TLEN(TLEN),
        .GRANULARITY(GRANULARITY),
        .ADR_WIDTH(MADR_WIDTH),
        .TADR_WIDTH(TADR_WIDTH)
    ) dut (
        .fu_i       (fu_i),
        .fu_o       (fu_o),

        .rnd_i      (rnd),

        .tmem_we_o  (tmem_we),
        .tmem_adr_o (tmem_wadr),
        .tmem_dat_o (tmem_wdat),
        .tmem_ack_i (tmem_wack)
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
    always #1 clk = ~clk;

    // To dump data for visualization:
    initial begin
        $dumpfile("mtag_testbench.vcd");
        $dumpvars(0, mtag_testbench);
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

    `TEST_SUITE("MTAG")

    /*** MISC ***/
    `UNIT_TEST("Disabled unit should not be ready")
        fu_i.ena = 1'b0;
        #1 `FAIL_IF_NOT_EQUAL(fu_o.rdy, 0);
    `UNIT_TEST_END

    `UNIT_TEST("Enabled, but error and not writing to tag memory if MTAG_OP_NONE")
        fu_i.ena = 1'b1;
        fu_i.op = MTAG_OP_NONE;
        fu_i.src1 = 1;
        fu_i.src2 = 2;
        #1
        `FAIL_IF_NOT_EQUAL(fu_o.rdy, 1);
        `FAIL_IF_NOT_EQUAL(fu_o.err, 1);
        `FAIL_IF_NOT_EQUAL(tmem_we, 0);
    `UNIT_TEST_END

    /** TADRE **/
    `UNIT_TEST("Expose correct tag and tag memory address on MTAG_OP_TADRE")
        fu_i.ena = 1'b1;
        fu_i.op = MTAG_OP_TADRE;
        fu_i.src1 = 'h2140__0000_0000_0032; // Tag: 0x214 = 532 | Address: 0x32 = 50
        fu_i.src2 = 'b1010; // Hart Access: 0b1010 = 0xA
        // Complete tag: 0x214A = 8522
        #1
        `FAIL_IF_NOT_EQUAL(fu_o.rdy, 1);
        `FAIL_IF_NOT_EQUAL(fu_o.err, 0);
        `FAIL_IF_NOT_EQUAL(tmem_we, 1);
        `FAIL_IF_NOT_EQUAL(tmem_wdat, 8522);
        // Tag address = address >> GRANULARITY | 50 >> 2 = 12
        `FAIL_IF_NOT_EQUAL(tmem_wadr, 12);
    `UNIT_TEST_END

    `UNIT_TEST("Write successfully to tag memory on MTAG_OP_TADRE")
        tmem_re = 1'b1;
        tmem_radr = 12;
        #2
        fu_i.ena = 1'b0;
        #2
        `FAIL_IF_NOT_EQUAL(tmem_rdat, 8522);
        tmem_re = 1'b0;
    `UNIT_TEST_END

    /** TADR **/
    `UNIT_TEST("Expose correct tag and tag memory address on MTAG_OP_TADR")
        fu_i.ena = 1'b1;
        fu_i.op = MTAG_OP_TADR;
        fu_i.src1 = 'hE5; // Address: 0xE5 = 229
        fu_i.src2 = 'hA4B1; // Tag: 0xA4B1 = 42161
        #1
        `FAIL_IF_NOT_EQUAL(fu_o.rdy, 1);
        `FAIL_IF_NOT_EQUAL(fu_o.err, 0);
        `FAIL_IF_NOT_EQUAL(tmem_we, 1);
        `FAIL_IF_NOT_EQUAL(tmem_wdat, 42161);
        // Tag address = address >> GRANULARITY | 229 >> 2 = 57
        `FAIL_IF_NOT_EQUAL(tmem_wadr, 57);
    `UNIT_TEST_END

    `UNIT_TEST("Write successfully to tag memory on MTAG_OP_TADR")
        tmem_re = 1'b1;
        tmem_radr = 57;
        #2
        fu_i.ena = 1'b0;
        #2
        `FAIL_IF_NOT_EQUAL(tmem_rdat, 42161);
        tmem_re = 1'b0;
    `UNIT_TEST_END

    /** TADRR **/
    `UNIT_TEST("Expose correct tag and tag memory address on MTAG_OP_TADRR")
        rnd = 'h1ABF; // Tag: 0xABF = 2751
        #1
        fu_i.ena = 1'b1;
        fu_i.op = MTAG_OP_TADRR;
        fu_i.src1 = 'hE7; // Address: 0xE7 = 231
        fu_i.src2 = 'b0001; // Allowed harts (none, except 0)
        // Full tag: 0xABF1 = 44017
        #1
        `FAIL_IF_NOT_EQUAL(fu_o.rdy, 1);
        `FAIL_IF_NOT_EQUAL(fu_o.err, 0);
        `FAIL_IF_NOT_EQUAL(fu_o.res, 'hABF);
        `FAIL_IF_NOT_EQUAL(tmem_we, 1);
        `FAIL_IF_NOT_EQUAL(tmem_wdat, 44017);
        // Tag address = address >> GRANULARITY | 231 >> = 57
        `FAIL_IF_NOT_EQUAL(tmem_wadr, 57);
    `UNIT_TEST_END

    `UNIT_TEST("Write successfully to tag memory on MTAG_OP_TADRR")
        tmem_re = 1'b1;
        tmem_radr = 57;
        #2
        fu_i.ena = 1'b0;
        #2
        `FAIL_IF_NOT_EQUAL(tmem_rdat, 44017);
        tmem_re = 1'b0;
    `UNIT_TEST_END
    `TEST_SUITE_END
endmodule
