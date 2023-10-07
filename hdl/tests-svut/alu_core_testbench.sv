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
    parameter WLEN = XLEN/2;

    alu_op_t	     op_i;
    logic [XLEN-1:0] a_i;
    logic [XLEN-1:0] b_i;

    /* verilator lint_off UNOPTFLAT */
    logic [XLEN-1:0] 	res_o;
    logic err_o;

    alu_core #(
        .XLEN   (XLEN)
    ) dut (
        .op_i 	 (op_i),
        .a_i     (a_i),
        .b_i     (b_i),
        .res_o   (res_o),
        .err_o   (err_o)
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

    `TEST_SUITE("ALU_CORE")
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
    // Misc
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("NONE returns 0 and error")
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_NONE;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF_NOT(err_o);
    `UNIT_TEST_END

/*  Currently all opcodes defined
    `UNIT_TEST("Invalid opcode returns 0 and error")
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= alu_op_t'('b1);
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(!err_o);
    `UNIT_TEST_END
*/

    // ----------------------------------------------------------------------------------------------------------------
    // ADD - Addition
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("ADD zero")
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_ADD;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("ADD positive integers")
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_ADD;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 3);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("ADD positive and negative integer")
        a_i 	= 1;
        b_i 	= -3;
        op_i 	= ALU_OP_ADD;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, -2);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("ADD with overflow")
        a_i 	= ~0;
        b_i 	= 1;
        op_i 	= ALU_OP_ADD;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // ADDW - Addition of 32-bit words
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("ADDW zero")
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_ADDW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW positive integers")
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_ADDW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 3);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW positive and negative integer")
        a_i 	= 1;
        b_i 	= -3;
        op_i 	= ALU_OP_ADDW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, -2);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW with overflow")
        a_i 	= ~0;
        b_i 	= 1;
        op_i 	= ALU_OP_ADDW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW generates sign extend")
        a_i 	= {32'b0, -32'd2};
        b_i 	=  1;
        op_i 	= ALU_OP_ADDW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, {XLEN{1'b1}});
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW overflows and stays in range")
        a_i 	= {32'b0, {32{1'b1}}};
        b_i 	=  128;
        op_i 	= ALU_OP_ADDW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 128-1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SUB - Substract
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SUB with zero")
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_SUB;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SUB with positive integers")
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_SUB;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, -1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SUB with positive and negative number")
        a_i 	= 1;
        b_i 	= -3;
        op_i 	= ALU_OP_SUB;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 4);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SUB with overflow")
        a_i 	= ~0;
        b_i 	= -1;
        op_i 	= ALU_OP_SUB;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SUB of maximum negative values")
        a_i 	= ~0;
        b_i 	= ~0;
        op_i 	= ALU_OP_SUB;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SLL - Shift Left Logic
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SLL shift-in no bits")
        a_i 	= ~0;
        b_i 	= 0;
        op_i 	= ALU_OP_SLL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, ~0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-in 1-bit zero")
        a_i 	= ~0;
        b_i 	= 1;
        op_i 	= ALU_OP_SLL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, ~0 << 1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-in 63-bit zeros")
        a_i 	= ~0;
        b_i 	= XLEN-1;
        op_i 	= ALU_OP_SLL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, {1'b1, {XLEN-1{1'b0}}});
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-in 64-bits zeros is pot possible (shamt [5:0])")
        a_i 	= ~0;
        b_i 	= XLEN;
        op_i 	= ALU_OP_SLL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, ~0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-left pattern 16")
        a_i 	= 'hcafe;
        b_i 	= 16;
        op_i 	= ALU_OP_SLL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 'hcafe0000);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-left pattern 32 digits")
        a_i 	= 'hcafebabe;
        b_i 	= 32;
        op_i 	= ALU_OP_SLL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 64'hcafebabe_00000000);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SRL - Shift Right Logic
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SRL shift-out no bit")
        a_i 	= ~0;
        b_i 	= 0;
        op_i 	= ALU_OP_SRL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, ~0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SRL shift-out one bit")
        a_i 	= ~0;
        b_i 	= 1;
        op_i 	= ALU_OP_SRL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, ~0 >> 1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SRL shift-out 63-bits")
        a_i 	= ~0;
        b_i 	= XLEN-1;
        op_i 	= ALU_OP_SRL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SRL shift-out 64-bits is pot possible (shamt [5:0])")
        a_i 	= ~0;
        b_i 	= XLEN;
        op_i 	= ALU_OP_SRL;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, ~0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SRA - Shift Right Arithmetic
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SRA shift-in no bit")
        a_i 	= 1 << XLEN-1;
        b_i 	= 0;
        op_i 	= ALU_OP_SRA;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, { 1'b1, {XLEN-1{1'b0}}});
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SRA shift-in single bit")
        a_i 	= 1 << XLEN-1;	    // Set MSB to 1
        b_i 	= 1;
        op_i 	= ALU_OP_SRA;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, { 2'b11, {XLEN-2{1'b0}}});
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SRA shift-in 63-Bit so that all bits set")
        a_i 	= 1 << XLEN-1;	    // Set MSB to 1
        b_i 	= XLEN-1;
        op_i 	= ALU_OP_SRA;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, ~0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SRA shift-in 64 bits not possible")
        a_i 	= 1 << XLEN-1;
        b_i 	= XLEN;
        op_i 	= ALU_OP_SRA;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 1 << XLEN-1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SLLW - Shift Left Logic Word
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SLLW shift-in no bit")
        a_i 	= 1;
        b_i 	= 0;
        op_i 	= ALU_OP_SLLW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLLW shift-in no bit and correctly sign extend")
        a_i 	= 1 << WLEN-1;
        b_i 	= 0;
        op_i 	= ALU_OP_SLLW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 64'hffff_ffff_8000_0000);
        `FAIL_IF(err_o);
        $display("res_o : %x", res_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLLW shift-in 31-bit zeros")
        a_i 	= ~0;
        b_i 	= WLEN-1;
        op_i 	= ALU_OP_SLLW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 64'hffff_ffff_8000_0000);
        `FAIL_IF(err_o);
        $display("res_o : %x", res_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLLW shift-in 32-bit zeros not possible")
        a_i 	= ~0;
        b_i 	= WLEN;
        op_i 	= ALU_OP_SLLW;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, ~0);
        `FAIL_IF(err_o);
        $display("res_o : %x", res_o);
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
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLT check larger")
        a_i 	= 2;
        b_i 	= 0;
        op_i 	= ALU_OP_SLT;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLT check less than both neg")
        a_i 	= 1 << XLEN-1;
        b_i 	= 1 << XLEN-1 | 1 << XLEN-2;
        op_i 	= ALU_OP_SLT;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    // -----------------------------------------------------------------------------------------------------------------
    // SLTU - Set Less Than Unsigned
    // -----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SLTU check same")
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_SLTU;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLTU check less than")
        a_i 	= 0;
        b_i 	= 2;
        op_i 	= ALU_OP_SLTU;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 1);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLTU check larger")
        a_i 	= 128;
        b_i 	= 0;
        op_i 	= ALU_OP_SLTU;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `UNIT_TEST("SLTU check not using signed negative")
        a_i 	= -1;
        b_i 	= 0;
        op_i 	= ALU_OP_SLTU;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, 0);
        `FAIL_IF(err_o);
    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
