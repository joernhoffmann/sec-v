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


    initial begin
        $dumpfile("alu_testbench.vcd");
        $dumpvars(1, alu_testbench);
    end


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

    task tst;
        input alu_op_t op;
        input logic [XLEN-1 : 0] a;
        input logic [XLEN-1 : 0] b;
        input logic [XLEN-1 : 0] res;

        op_i = op;
        a_i = a;
        b_i = b;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, res);
        `FAIL_IF(err_o);
    endtask

    task tst_fail;
        input alu_op_t op;
        input logic [XLEN-1 : 0] a;
        input logic [XLEN-1 : 0] b;
        input logic [XLEN-1 : 0] res;

        op_i = op;
        a_i = a;
        b_i = b;
        #1
        `FAIL_IF_NOT_EQUAL(res_o, res);
        `FAIL_IF_NOT(err_o);
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
        tst_fail(ALU_OP_NONE, 1, 2, 0);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // ADD - Addition
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("ADD zero")
        tst(ALU_OP_ADD, 0, 0, 0);
        $display("out %x", res_o);
        $display("err %x", err_o);

    `UNIT_TEST_END

    `UNIT_TEST("ADD positive integers")
        tst(ALU_OP_ADD, 1, 2, 3);
    `UNIT_TEST_END

    `UNIT_TEST("ADD positive and negative integer")
        tst(ALU_OP_ADD, 1, -3, -2);
    `UNIT_TEST_END

    `UNIT_TEST("ADD with overflow")
        tst(ALU_OP_ADD, ~0, 1, 0);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // ADDW - Addition of 32-bit words
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("ADDW zero")
        tst(ALU_OP_ADDW, 0, 0, 0);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW positive integers")
        tst(ALU_OP_ADDW, 1, 2, 3);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW positive and negative integer")
        tst(ALU_OP_ADDW, 1, -3, -2);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW with overflow")
        tst(ALU_OP_ADDW, ~0, 1, 0);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW generates sign extend")
        tst(ALU_OP_ADDW, -2, 1, ~0);
    `UNIT_TEST_END

    `UNIT_TEST("ADDW overflows and stays in range")
        tst(ALU_OP_ADDW, 64'hffff_ffff, 128, 128-1);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SUB - Substract
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SUB with zero")
        tst(ALU_OP_SUB, 0, 0, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SUB with positive integers")
        tst(ALU_OP_SUB, 1, 2, -1);
    `UNIT_TEST_END

    `UNIT_TEST("SUB with positive and negative number")
        tst(ALU_OP_SUB, 1, -3, 4);
    `UNIT_TEST_END

    `UNIT_TEST("SUB with overflow")
        tst(ALU_OP_SUB, ~0, -1, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SUB of maximum negative values")
        tst(ALU_OP_SUB, ~0, ~0, 0);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SLL - Shift Left Logic
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SLL shift-in no bits")
        tst(ALU_OP_SLL, ~0, 0, ~0);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-in 1-bit zero")
        tst(ALU_OP_SLL, 64'hffffffff_ffffffff, 1, 64'hffffffff_fffffffe);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-in 63-bit zeros")
        tst(ALU_OP_SLL, 64'hffffffff_ffffffff, 63, 64'h80000000_00000000);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-left 65 is like shift-left 1 (shamt limited to [5:0])")
        tst(ALU_OP_SLL, 64'hffffffff_ffffffff, 65, 64'hffffffff_fffffffe);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-left 16 some pattern")
        tst(ALU_OP_SLL, 64'hcafe, 16, 64'hcafe0000);
    `UNIT_TEST_END

    `UNIT_TEST("SLL shift-left pattern 32 digits")
        tst(ALU_OP_SLL, 64'hcafebabe, 32, 64'hcafebabe_00000000);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SRL - Shift Right Logic
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SRL shift-out no bit")
        tst(ALU_OP_SRL, ~0, 0, ~0);
    `UNIT_TEST_END

    `UNIT_TEST("SRL shift-out one bit")
        tst(ALU_OP_SRL, ~0, 1, ~0 >> 1);
    `UNIT_TEST_END

    `UNIT_TEST("SRL shift-out 63-bits")
        tst(ALU_OP_SRL, ~0, 63, 1);
    `UNIT_TEST_END

    `UNIT_TEST("SRL shift-right 65-bits is like shift-right 1-bit (shamt limited to [5:0])")
        tst(ALU_OP_SRL, ~0, 65, ~0 >> 1);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SRA - Shift Right Arithmetic
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SRA shift-in no bit")
        tst(ALU_OP_SRA, 64'h80000000_00000000, 0, 64'h80000000_00000000);
    `UNIT_TEST_END

    `UNIT_TEST("SRA shift-in additional bit")
        tst(ALU_OP_SRA, 64'h80000000_00000000, 1, 64'hc0000000_00000000);
    `UNIT_TEST_END

    `UNIT_TEST("SRA shift-in 63-Bit so that all bits set")
        tst(ALU_OP_SRA, 64'h80000000_00000000, 63, 64'hffffffff_ffffffff);
    `UNIT_TEST_END

    `UNIT_TEST("SRA shift-in 65 bits is like shift in one bit (shamt limited)")
        tst(ALU_OP_SRA, 64'h80000000_00000000, 65, 64'hc0000000_00000000);
    `UNIT_TEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SLLW - Shift Left Logic Word
    // ----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SLLW shift-in no bit")
        tst(ALU_OP_SLLW, 1, 0, 1);
    `UNIT_TEST_END

    `UNIT_TEST("SLLW shift-in no bit and correctly sign extend")
        tst(ALU_OP_SLLW, 64'h0000_0000_8000_0000, 0, 64'hffff_ffff_8000_0000);
    `UNIT_TEST_END

    `UNIT_TEST("SLLW shift-in 31-bit zeros")
        tst(ALU_OP_SLLW, 64'hffff_ffff_ffff_ffff, 31, 64'hffff_ffff_8000_0000);
    `UNIT_TEST_END

    `UNIT_TEST("SLLW shift-in 33-bit zeros is like 1-bit (shamt limited)")
        tst(ALU_OP_SLLW, 64'hffff_ffff_ffff_ffff, 32, 64'hffff_ffff_ffff_ffff);
    `UNIT_TEST_END

    // -----------------------------------------------------------------------------------------------------------------
    // SLT - Set Less Than
    // -----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SLT check same results to 0")
        tst(ALU_OP_SLT, 0, 0, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SLT check less than results to 1")
        tst(ALU_OP_SLT, -1, 0, 1);
    `UNIT_TEST_END

    `UNIT_TEST("SLT check larger results to 0")
        tst(ALU_OP_SLT, 2, 1, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SLT check less than and both negative results to 1")
        tst(ALU_OP_SLT, 1 << XLEN-1, 1 << XLEN-1 | 1 << XLEN-2, 1);
    `UNIT_TEST_END

    // -----------------------------------------------------------------------------------------------------------------
    // SLTU - Set Less Than Unsigned
    // -----------------------------------------------------------------------------------------------------------------
    `UNIT_TEST("SLTU check same results to 0")
        tst(ALU_OP_SLTU, 0, 0, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SLTU check less than results to 1")
        tst(ALU_OP_SLTU, 0, 2, 1);
    `UNIT_TEST_END

    `UNIT_TEST("SLTU check larger results to 0")
        tst(ALU_OP_SLTU, 128, 0, 0);
    `UNIT_TEST_END

    `UNIT_TEST("SLTU check not using signed negative")
        tst(ALU_OP_SLTU, ~0, 0, 0);
    `UNIT_TEST_END
    `TEST_SUITE_END
endmodule
