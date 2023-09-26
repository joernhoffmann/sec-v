// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Tests of the SEC-V ALU.
 */

`include "svut_h.sv"
`include "../alu_core.sv"

module alu_core_testbench();
    `SVUT_SETUP

    parameter XLEN = 64;
    alu_op_t	     op_i;
    logic [XLEN-1:0] a_i;
    logic [XLEN-1:0] b_i;

    /* verilator lint_off UNOPTFLAT */
    logic [XLEN-1:0] 	res_o;

    alu_core #(
        .XLEN   (XLEN)
    ) dut (
        .op_i 	 (op_i),
        .a_i     (a_i),
        .b_i     (b_i),
        .res_o   (res_o)
    );

/*
    initial begin
        $dumpfile("alu_testbench.vcd");
        $dumpvars(1, alu_testbench);
    end
*/

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

    `TEST_SUITE("ALU Tests (64-bit)")
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


    // ----------------------------------------------------------------------------------------------------------------
    // ADD - Addition
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("ADD zero")
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_ADD;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("ADD positive integers")
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_ADD;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 3);
    `UNIT_TEST_END

    `UNIT_TEST("ADD positive and negative integer")
        a_i 	= 1;
        b_i 	= -3;
        op_i 	= ALU_OP_ADD;
        #1 `FAIL_IF_NOT_EQUAL(res_o, -2);
    `UNIT_TEST_END

    `UNIT_TEST("ADD with overflow")
        a_i 	= ~0;
        b_i 	= 1;
        op_i 	= ALU_OP_ADD;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // ADDW - Addition of 32-bit words
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("ADDW zero")
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW positive integers")
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 3);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW positive and negative integer")
        a_i 	= 1;
        b_i 	= -3;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_IF_NOT_EQUAL(res_o, -2);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW with overflow")
        a_i 	= ~0;
        b_i 	= 1;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW generates sign extend")
        a_i 	= {32'b0, -32'd2};
        b_i 	=  1;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_IF_NOT_EQUAL(res_o, {XLEN{1'b1}});
    `UNIT_TEST_END

    `UNIT_TEST("ADDW overflows and stays in range")
        a_i 	= {32'b0, {32{1'b1}}};
        b_i 	=  128;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 128-1);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SUB - Substract
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SUB with zero")
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SUB with positive integers")
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_IF_NOT_EQUAL(res_o, -1);
    `UNIT_TEST_END

    `UNIT_TEST("SUB with positive and negative number")
        a_i 	= 1;
        b_i 	= -3;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 4);
    `UNIT_TEST_END

    `UNIT_TEST("SUB with overflow")
        a_i 	= ~0;
        b_i 	= -1;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SUB of maximum negative values")
        a_i 	= ~0;
        b_i 	= ~0;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SRL - Shift Right Logic
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SRL shift-out all bits but one")
        a_i 	= ~0;
        b_i 	= XLEN-1;
        op_i 	= ALU_OP_SRL;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 1);
    `UNIT_TEST_END

    `UNIT_TEST("SRL shift-out all bits")
        a_i 	= ~0;
        b_i 	= XLEN;
        op_i 	= ALU_OP_SRL;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SRL shift-out all bits with large shift amount")
        a_i 	= ~0;
        b_i 	= ~0-1;
        op_i 	= ALU_OP_SRL;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SRA - Shift Right Arithmetic
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SRA shift-in so that all bits set")
        a_i 	= 1 << XLEN-1;	    // Set MSB to 1
        b_i 	= XLEN-1;
        op_i 	= ALU_OP_SRA;
        #1 `FAIL_IF_NOT_EQUAL(res_o, ~0);
    `UNIT_TEST_END

    `UNIT_TEST("SRA shift-in single bit")
        a_i 	= 1 << XLEN-1;	    // Set MSB to 1
        b_i 	= 1;
        op_i 	= ALU_OP_SRA;
        #1 `FAIL_IF_NOT_EQUAL(res_o, { 2'b11, {XLEN-2{1'b0}}});
    `UNIT_TEST_END

    `UNIT_TEST("SRA shift-out all bits")
        a_i 	= 1 << XLEN-1;
        b_i 	= XLEN;
        op_i 	= ALU_OP_SRA;
        #1 `FAIL_IF_NOT_EQUAL(res_o, ~0);
    `UNIT_TEST_END

    `UNIT_TEST("SRA shift-out all bits with large shift amount")
        a_i 	= 1 << XLEN-1;
        b_i 	= ~0-1;
        op_i 	= ALU_OP_SRA;
        #1 `FAIL_IF_NOT_EQUAL(res_o, ~0);
    `UNIT_TEST_END

    // -----------------------------------------------------------------------------------------------------------------
    // SLT - Set Less Than
    // -----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SLT check same")
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_SLT;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SLT check less than")
        a_i 	= -1;
        b_i 	= 0;
        op_i 	= ALU_OP_SLT;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 1);
    `UNIT_TEST_END

    `UNIT_TEST("SLT check larger")
        a_i 	= 2;
        b_i 	= 0;
        op_i 	= ALU_OP_SLT;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SLT check less than both neg")
        a_i 	= 1 << XLEN-1;
        b_i 	= 1 << XLEN-1 | 1 << XLEN-2;
        op_i 	= ALU_OP_SLT;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 1);
    `UNIT_TEST_END

    // -----------------------------------------------------------------------------------------------------------------
    // SLTU - Set Less Than Unsigned
    // -----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SLTU check same")
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_SLTU;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SLTU check less than")
        a_i 	= 0;
        b_i 	= 2;
        op_i 	= ALU_OP_SLTU;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 1);
    `UNIT_TEST_END

    `UNIT_TEST("SLTU check larger")
        a_i 	= 128;
        b_i 	= 0;
        op_i 	= ALU_OP_SLTU;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SLTU check not using signed negative")
        a_i 	= -1;
        b_i 	= 0;
        op_i 	= ALU_OP_SLTU;
        #1 `FAIL_IF_NOT_EQUAL(res_o, 0);
    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
