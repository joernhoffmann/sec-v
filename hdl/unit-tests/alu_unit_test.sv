`include "svunit_defines.svh"
`include "secv_pkg.svh"
`include "alu.sv"

module alu_unit_test;
  import svunit_pkg::svunit_testcase;
  import secv_pkg::*;


  string name = "alu_ut";
  svunit_testcase svunit_ut;

  parameter XLEN=64;
  logic [XLEN-1 : 0] a_i, b_i, res_o;
  alu_op_t op_i;

  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  alu #(
    .XLEN   (XLEN)
  ) my_alu (
    .a_i    (a_i),
    .b_i    (b_i),
    .res_o  (res_o),
    .op_i   (op_i)
  );


  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
  endfunction


  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    svunit_ut.setup();
    /* Place Setup Code Here */

  endtask


  //===================================
  // Here we deconstruct anything we
  // need after running the Unit Tests
  //===================================
  task teardown();
    svunit_ut.teardown();
    /* Place Teardown Code Here */

  endtask


  //===================================
  // All tests are defined between the
  // SVUNIT_TESTS_BEGIN/END macros
  //
  // Each individual test must be
  // defined between `SVTEST(_NAME_)
  // `SVTEST_END
  //
  // i.e.
  //   `SVTEST(mytest)
  //     <test code>
  //   `SVTEST_END
  //===================================
  `SVUNIT_TESTS_BEGIN

    // ----------------------------------------------------------------------------------------------------------------
    // ADD - Addition
    // ----------------------------------------------------------------------------------------------------------------
    `SVTEST(ADD_zero)
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_ADD;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(ADD_positive_integers)
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_ADD;
        #1 `FAIL_UNLESS_EQUAL(res_o, 3);
    `SVTEST_END

    `SVTEST(ADD_positive_and_negative_integer)
        a_i 	= 1;
        b_i 	= -3;
        op_i 	= ALU_OP_ADD;
        #1 `FAIL_UNLESS_EQUAL(res_o, -2);
    `SVTEST_END

    `SVTEST(ADD_with_overflow)
        a_i 	= ~0;
        b_i 	= 1;
        op_i 	= ALU_OP_ADD;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // ADDW - Addition of 32-bit words
    // ----------------------------------------------------------------------------------------------------------------
    `SVTEST(ADDW_zero)
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(ADDW_positive_integers)
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_UNLESS_EQUAL(res_o, 3);
    `SVTEST_END

    `SVTEST(ADDW_positive_and_negative_integer)
        a_i 	= 1;
        b_i 	= -3;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_UNLESS_EQUAL(res_o, -2);
    `SVTEST_END

    `SVTEST(ADDW_with_overflow)
        a_i 	= ~0;
        b_i 	= 1;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(ADDW_generates_sign_extend)
        a_i 	= {32'b0, -32'd2};
        b_i 	=  1;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_UNLESS_EQUAL(res_o, {XLEN{1'b1}});
    `SVTEST_END

    `SVTEST(ADDW_overflows_and_stays_in_range)
        a_i 	= {32'b0, {32{1'b1}}};
        b_i 	=  128;
        op_i 	= ALU_OP_ADDW;
        #1 `FAIL_UNLESS_EQUAL(res_o, 128-1);
    `SVTEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SUB - Substract
    // ----------------------------------------------------------------------------------------------------------------
    `SVTEST(SUB_with_zero)
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(SUB_with_positive_integers)
        a_i 	= 1;
        b_i 	= 2;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_UNLESS_EQUAL(res_o, -1);
    `SVTEST_END

    `SVTEST(SUB_with_positive_and_negative_number)
        a_i 	= 1;
        b_i 	= -3;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_UNLESS_EQUAL(res_o, 4);
    `SVTEST_END

    `SVTEST(SUB_with_overflow)
        a_i 	= ~0;
        b_i 	= -1;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(SUB_of_maximum_negative_values)
        a_i 	= ~0;
        b_i 	= ~0;
        op_i 	= ALU_OP_SUB;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SRL - Shift Right Logic
    // ----------------------------------------------------------------------------------------------------------------
    `SVTEST(SRL_shift_out_all_bits_but_one)
        a_i 	= ~0;
        b_i 	= XLEN-1;
        op_i 	= ALU_OP_SRL;
        #1 `FAIL_UNLESS_EQUAL(res_o, 1);
    `SVTEST_END

    `SVTEST(SRL_shift_out_all_bits)
        a_i 	= ~0;
        b_i 	= XLEN;
        op_i 	= ALU_OP_SRL;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(SRL_shift_out_all_bits_with_large_shift_amount)
        a_i 	= ~0;
        b_i 	= ~0-1;
        op_i 	= ALU_OP_SRL;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    // ----------------------------------------------------------------------------------------------------------------
    // SRA - Shift Right Arithmetic
    // ----------------------------------------------------------------------------------------------------------------
    `SVTEST(SRA_shift_in_so_that_all_bits_set)
        a_i 	= 1 << XLEN-1;	    // Set MSB to 1
        b_i 	= XLEN-1;
        op_i 	= ALU_OP_SRA;
        #1 `FAIL_UNLESS_EQUAL(res_o, ~0);
    `SVTEST_END

    `SVTEST(SRA_shift_in_single_bit)
        a_i 	= 1 << XLEN-1;	    // Set MSB to 1
        b_i 	= 1;
        op_i 	= ALU_OP_SRA;
        #1 `FAIL_UNLESS_EQUAL(res_o, { 2'b11, {XLEN-2{1'b0}}});
    `SVTEST_END

    `SVTEST(SRA_shift_out_all_bits)
        a_i 	= 1 << XLEN-1;
        b_i 	= XLEN;
        op_i 	= ALU_OP_SRA;
        #1 `FAIL_UNLESS_EQUAL(res_o, ~0);
    `SVTEST_END

    `SVTEST(SRA_shift_out_all_bits_with_large_shift_amount)
        a_i 	= 1 << XLEN-1;
        b_i 	= ~0-1;
        op_i 	= ALU_OP_SRA;
        #1
        `FAIL_UNLESS_EQUAL(res_o, ~0);
        // $display("sra %h", res_o);

    `SVTEST_END

    // -----------------------------------------------------------------------------------------------------------------
    // SLT - Set Less Than
    // -----------------------------------------------------------------------------------------------------------------
    `SVTEST(SLT_check_same)
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_SLT;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(SLT_check_less_than)
        a_i 	= -1;
        b_i 	= 0;
        op_i 	= ALU_OP_SLT;
        #1 `FAIL_UNLESS_EQUAL(res_o, 1);
    `SVTEST_END

    `SVTEST(SLT_check_larger)
        a_i 	= 2;
        b_i 	= 0;
        op_i 	= ALU_OP_SLT;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(SLT_check_less_than_both_neg)
        a_i 	= (1 << XLEN-1) ;
        b_i 	= (1 << XLEN-1) | (1 << XLEN-2);
        op_i 	= ALU_OP_SLT;
        #1 `FAIL_UNLESS_EQUAL(res_o, 1);
    `SVTEST_END

    // -----------------------------------------------------------------------------------------------------------------
    // SLTU - Set Less Than Unsigned
    // -----------------------------------------------------------------------------------------------------------------
    `SVTEST(SLTU_check_same)
        a_i 	= 0;
        b_i 	= 0;
        op_i 	= ALU_OP_SLTU;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(SLTU_check_less_than)
        a_i 	= 0;
        b_i 	= 2;
        op_i 	= ALU_OP_SLTU;
        #1 `FAIL_UNLESS_EQUAL(res_o, 1);
    `SVTEST_END

    `SVTEST(SLTU_check_larger)
        a_i 	= 128;
        b_i 	= 0;
        op_i 	= ALU_OP_SLTU;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

    `SVTEST(SLTU_check_not_using_signed_negative)
        a_i 	= -1;
        b_i 	= 0;
        op_i 	= ALU_OP_SLTU;
        #1 `FAIL_UNLESS_EQUAL(res_o, 0);
    `SVTEST_END

  `SVUNIT_TESTS_END


endmodule
