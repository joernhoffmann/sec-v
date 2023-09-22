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

  const logic[XLEN-1:0] imm = 42;
  const logic[XLEN-1:0] pc = 21;

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

    // --- Opcode tests --------------------------------------------------------------------------------------------- //
    `SVTEST(MOV_performs_LUI)
      fu_i.ena = 1;
      fu_i.inst.i_type.opcode = OPCODE_LUI;
      fu_i.imm = imm;

      #1
      `FAIL_UNLESS(fu_o.rdy);
      `FAIL_UNLESS(fu_o.rd_dat == imm);
      `FAIL_UNLESS(fu_o.rd_wb  == 1'b1);
      `FAIL_IF(fu_o.pc_wb);
    `SVTEST_END

    `SVTEST(MOV_performs_AUIPC)
      fu_i.ena = 1;
      fu_i.inst.i_type.opcode = OPCODE_AUIPC;
      fu_i.pc = pc;
      fu_i.imm = imm;

      #1
      `FAIL_UNLESS(fu_o.rd_dat == pc + imm);
      `FAIL_UNLESS(fu_o.rd_wb  == 1'b1);
      `FAIL_IF(fu_o.pc_wb);
    `SVTEST_END
  `SVUNIT_TESTS_END
endmodule
