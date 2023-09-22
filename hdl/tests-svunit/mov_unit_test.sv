`include "/home/reckert/lib/svunit/svunit_base/svunit_defines.svh"
`include "svunit_defines.svh"
`include "secv_pkg.svh"
`include "mov.sv"

module mov_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "mov_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  funit_in_t fu_i;
  funit_out_t fu_o;

  mov #(
    .XLEN(XLEN)
  ) dut (
    // Funit interface
    .fu_i (fu_i),
    .fu_o (fu_o)
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
    fu_i = funit_in_default();

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

    // --- General behaviour ---------------------------------------------------------------------------------------- //
    `SVTEST(MOV_not_ready_if_not_enabled)
        fu_i.ena = 0;

        #1 `FAIL_UNLESS(!fu_o.rdy);
    `SVTEST_END

    `SVTEST(MOV_signals_error_if_enabled_with_invalid_opcode)
        fu_i.ena = 1;

        #1 `FAIL_UNLESS(fu_o.err);
    `SVTEST_END

    `SVTEST(MOV_not_enabled_and_with_valid_opcode)
      fu_i.ena = 0;
      fu_i.inst.i_type.opcode = OPCODE_LUI;

      #1 `FAIL_UNLESS(!fu_o.rdy);
    `SVTEST_END

    `SVTEST(MOV_enabled_with_valid_opcode_OPCODE_LUI)
      fu_i.ena = 1;
      fu_i.inst.i_type.opcode = OPCODE_LUI;
      fu_i.imm = 42;

      #1 `FAIL_UNLESS(fu_o.rd_dat == 42);
    `SVTEST_END

    `SVTEST(MOV_enabled_with_valid_opcode_OPCODE_AUIPC)
      fu_i.ena = 1;
      fu_i.inst.i_type.opcode = OPCODE_AUIPC;
      fu_i.imm = 42;
      fu_i.pc = 21;

      #1 `FAIL_UNLESS(fu_o.rd_dat == 63);
    `SVTEST_END    

  `SVUNIT_TESTS_END
endmodule
