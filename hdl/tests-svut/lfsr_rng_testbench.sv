// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2024
 *
 * Project  : Memory Tagged SEC-V
 * Author   : Till Mahlburg
 * Purpose  : Tests of the SEC-V random number generator.
 */

`include "svut_h.sv"
`include "../lfsr_rng.sv"

module lfsr_rng_testbench();
    `SVUT_SETUP

    localparam WIDTH = 32;

    logic clk;
    logic rst;

    logic [WIDTH-1:0] poly;
    logic [WIDTH-1:0] lfsr;
    logic [WIDTH-1:0] last_lfsr;

    lfsr_rng #(
        .WIDTH(WIDTH)
    ) dut (
        .clk_i(clk),
        .rst_i(rst),

        .poly_i(poly),
        .lfsr_i(lfsr),
        .lfsr_o(lfsr)
    );

    initial clk = 0;
    always #2 clk = ~clk;

    // To dump data for visualization:
    initial begin
        $dumpfile("lfsr_rng_testbench.vcd");
        $dumpvars(0, lfsr_rng_testbench);
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

    `TEST_SUITE("LFSR_RNG")

    `UNIT_TEST("Generate a number in one clock cycle")
        poly = 'h911111FB;
        last_lfsr = lfsr;
        #2
        `FAIL_IF_EQUAL(last_lfsr, lfsr);
    `UNIT_TEST_END

    `UNIT_TEST("Generate a different number the next clock cycle")
        last_lfsr = lfsr;
        #2
        `FAIL_IF_EQUAL(last_lfsr, lfsr);
    `UNIT_TEST_END

    `TEST_SUITE_END
endmodule
