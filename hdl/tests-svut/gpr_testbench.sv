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

    regadr_t address;
    logic [XLEN-1: 0] rd_dat, rs1_dat, rs2_dat;

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

    // Clock
    parameter int PERIOD = 2;
    initial clk_i = 0;
    always #PERIOD clk_i = ~clk_i;

    // To dump data for visualization:
    initial begin
        $dumpfile("gpr_testbench.vcd");
        $dumpvars(0, gpr_testbench);
    end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        reset();
    end
    endtask

    task teardown(msg="");
    begin
        ;
    end
    endtask

    // -------------------------------------------------------------------------------------------------------------- //
    // Helper tasks
    // -------------------------------------------------------------------------------------------------------------- //
    task reset();
    begin
        @(posedge clk_i)
        rst_i = 1'b1;
        #PERIOD;
        rst_i = 1'b0;
    end
    endtask

    // Write destination register
    task write_rd;
        input  regadr_t            adr;
        input  logic    [XLEN-1:0] dat;
    begin
        @(posedge clk_i);
        rd_adr_i = adr;
        rd_dat_i = dat;
        rd_wb_i  = 1'b1;
        #1
        rd_wb_i  = 1'b0;
    end
    endtask

    // Read source register 1
    task read_rs1;
        input  regadr_t         adr;
        output logic [XLEN-1:0] dat;
    begin
        @(posedge clk_i);
        rs1_adr_i = adr;
        #1
        dat = rs1_dat_o;
    end
    endtask

    // Read source register 2
    task read_rs2;
        input  regadr_t         adr;
        output logic [XLEN-1:0] dat;
    begin
        @(posedge clk_i);
        rs2_adr_i = adr;
        #1
        dat = rs2_dat_o;
    end
    endtask

    // -------------------------------------------------------------------------------------------------------------- //
    // Tests
    // -------------------------------------------------------------------------------------------------------------- //
    `TEST_SUITE("GPR")
    `UNIT_TEST("Check random value written to r0..r32 return 0 if read after reset")
        for (int i = 0; i < REG_COUNT; i++) begin
            address = i;
            rd_dat = i*2;
            write_rd(.adr(address), .dat(rd_dat));
        end

        reset();

        for (int i = 0; i < REG_COUNT; i++) begin
            read_rs1(.adr(address), .dat(rs1_dat));
            read_rs2(.adr(address), .dat(rs2_dat));
            `FAIL_IF_NOT_EQUAL(rs1_dat, 'b0);
            `FAIL_IF_NOT_EQUAL(rs2_dat, 'b0);
        end
    `UNIT_TEST_END

    // Register [0]
    `UNIT_TEST("Check random value written to r0 returns 0 if read")
        address = 0;
        rd_dat = 'h42;
        write_rd(.adr(address), .dat(rd_dat));

        read_rs1(.adr(address), .dat(rs1_dat));
        read_rs2(.adr(address), .dat(rs2_dat));
        `FAIL_IF_NOT_EQUAL(rs1_dat, 'b0);
        `FAIL_IF_NOT_EQUAL(rs2_dat, 'b0);
    `UNIT_TEST_END

    // Register [1..32]
    `UNIT_TEST("Check random value written to r1..r32 could be read")
        for (int i = 1; i < REG_COUNT; i++) begin
            address = i;
            rd_dat = i*2;
            write_rd(.adr(address), .dat(rd_dat));
        end

        for (int i = 1; i < REG_COUNT; i++) begin
            address = i;
            rd_dat = i*2;
            read_rs1(.adr(address), .dat(rs1_dat));
            read_rs2(.adr(address), .dat(rs2_dat));
            `FAIL_IF_NOT_EQUAL(rs1_dat, rd_dat);
            `FAIL_IF_NOT_EQUAL(rs2_dat, rd_dat);
        end
    `UNIT_TEST_END
    `TEST_SUITE_END
endmodule
