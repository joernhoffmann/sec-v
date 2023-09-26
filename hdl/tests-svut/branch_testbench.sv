// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Tests SEC-V decoder
 */

`include "svut_h.sv"
`include "../branch.sv"
`timescale 1 ns / 100 ps

module branch_testbench();
    `SVUT_SETUP

    parameter int XLEN = secv_pkg::XLEN;

    funct3_t            funct3_i;
    logic [XLEN-1 : 0]  rs1_i;
    logic [XLEN-1 : 0]  rs2_i;
    logic               take_o;
    logic               err_o;

    branch #(
        .XLEN (XLEN)
    ) dut (
        .funct3_i (funct3_i),
        .rs1_i    (rs1_i),
        .rs2_i    (rs2_i),
        .take_o   (take_o),
        .err_o    (err_o)
    );

    // To create a clock:
    // initial aclk = 0;
    // always #2 aclk = ~aclk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("branch_testbench.vcd");
    //     $dumpvars(0, branch_testbench);
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

    `TEST_SUITE("TESTSUITE_NAME")

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
    // MISC
        `UNIT_TEST("Test branch indicate error for invalid funct3")
            funct3_i = 3'b010;
            #1`FAIL_IF(!err_o);

            funct3_i = 3'b011;
            #1`FAIL_IF(!err_o);
        `UNIT_TEST_END

    // BEQ - branch equal
        `UNIT_TEST("Test BEQ a == b jumps")
            funct3_i = FUNCT3_BRANCH_BEQ;
            rs1_i    = 1;
            rs2_i    = 1;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 1);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BEQ a != b not jumps")
            funct3_i = FUNCT3_BRANCH_BEQ;
            rs1_i    = 1;
            rs2_i    = 2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 0);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // BNE - branch not equal
        `UNIT_TEST("Test BNE a != b jumps")
            funct3_i = FUNCT3_BRANCH_BNE;
            rs1_i    = 1;
            rs2_i    = 2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 1);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BEQ a == b not jumps")
            funct3_i = FUNCT3_BRANCH_BNE;
            rs1_i    = 1;
            rs2_i    = 1;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 0);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // BLT - branch less than
        `UNIT_TEST("Test BLT -a == -b not jumps")
            funct3_i = FUNCT3_BRANCH_BLT;
            rs1_i    = -1;
            rs2_i    = -1;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 0);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BLT -a < b jumps")
            funct3_i = FUNCT3_BRANCH_BLT;
            rs1_i    = -1;
            rs2_i    =  2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 1);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BLT -a < -b jumps")
            funct3_i = FUNCT3_BRANCH_BLT;
            rs1_i    = -2;
            rs2_i    = -1;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 1);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BLT -a > -b not jumps")
            funct3_i = FUNCT3_BRANCH_BLT;
            rs1_i    = -1;
            rs2_i    = -2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 0);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // BGE - branch greater equal
        `UNIT_TEST("Test BGE -a < b not jumps")
            funct3_i = FUNCT3_BRANCH_BGE;
            rs1_i    = -1;
            rs2_i    =  2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 0);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BGE -a > -b jumps")
            funct3_i = FUNCT3_BRANCH_BGE;
            rs1_i    = -1;
            rs2_i    = -2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 1);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BGE -a => -b jumps")
            funct3_i = FUNCT3_BRANCH_BGE;
            rs1_i    = -2;
            rs2_i    = -2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 1);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // BLTU - branch less than (unsigned)
        `UNIT_TEST("Test BLTU -a < b not jumps")
            funct3_i = FUNCT3_BRANCH_BLTU;
            rs1_i    = -1;
            rs2_i    =  2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 0);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BLTU -a < -b jumps")
            funct3_i = FUNCT3_BRANCH_BLTU;
            rs1_i    = -2;
            rs2_i    = -1;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 1);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BLTU a = b not jumps")
            funct3_i = FUNCT3_BRANCH_BLTU;
            rs1_i    =  2;
            rs2_i    =  2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 0);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

        `UNIT_TEST("Test BLTU a > b not jumps")
            funct3_i = FUNCT3_BRANCH_BLTU;
            rs1_i    =  3;
            rs2_i    =  2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 0);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    // BGEU - branch greater equal (unsigned)
        `UNIT_TEST("Test BGEU a < b not jumps")
            funct3_i = FUNCT3_BRANCH_BGEU;
            rs1_i    = 1;
            rs2_i    = 2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 0);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    `UNIT_TEST("Test BGEU a > b jumps")
            funct3_i = FUNCT3_BRANCH_BGEU;
            rs1_i    = 2;
            rs2_i    = 1;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 1);
            `FAIL_IF(err_o);
        `UNIT_TEST_END

    `UNIT_TEST("Test BGEU a >= b jumps")
            funct3_i = FUNCT3_BRANCH_BGEU;
            rs1_i    = 2;
            rs2_i    = 2;
            #1
            `FAIL_IF_NOT_EQUAL(take_o, 1);
            `FAIL_IF(err_o);
        `UNIT_TEST_END
    `TEST_SUITE_END

endmodule
