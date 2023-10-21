`include "svunit_defines.svh"
`include "secv_pkg.svh"
`include "mem.sv"

module mem_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "mem_ut";
  svunit_testcase svunit_ut;

  parameter int ADR_WIDTH = 8;
  parameter int SEL_WIDTH = XLEN/8;

  parameter int TLEN = 16;
  parameter int TADR_WIDTH = 16;
  parameter int TSEL_WIDTH = TLEN/8;

  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  funit_in_t fu_i;
  funit_out_t fu_o;

  logic [ADR_WIDTH-1 : 0]  t_err_adr;

  logic                    dmem_cyc_o;
  logic                    dmem_stb_o;
  logic [SEL_WIDTH-1 : 0]  dmem_sel_o;
  logic [ADR_WIDTH-1 : 0]  dmem_adr_o;
  logic                    dmem_we_o;
  logic [XLEN-1      : 0]  dmem_dat_o;
  logic [XLEN-1      : 0]  dmem_dat_i;
  logic                    dmem_ack_i;

  logic                    tmem_cyc_o;
  logic                    tmem_stb_o;
  logic [TSEL_WIDTH-1 : 0] tmem_sel_o;
  logic [TADR_WIDTH-1 : 0] tmem_adr_o;
  logic [TLEN-1       : 0] tmem_dat_i;
  logic                    tmem_ack_i;

  mem #(
    .XLEN(XLEN),
    .ADR_WIDTH(ADR_WIDTH)
  ) dut (
    // Funit interface
    .fu_i (fu_i),
    .fu_o (fu_o),

    // Tagging error
    .t_err_adr_o (t_err_adr),

    // Wishbone interface for data memory
    .dmem_cyc_o (dmem_cyc_o),
    .dmem_stb_o (dmem_stb_o),
    .dmem_sel_o (dmem_sel_o),
    .dmem_adr_o (dmem_adr_o),
    .dmem_we_o  (dmem_we_o),
    .dmem_dat_o (dmem_dat_o),
    .dmem_dat_i (dmem_dat_i),
    .dmem_ack_i (dmem_ack_i),

    // Wishbone interface for tag memory
    .tmem_cyc_o (tmem_cyc_o),
    .tmem_stb_o (tmem_stb_o),
    .tmem_sel_o (tmem_sel_o),
    .tmem_adr_o (tmem_adr_o),
    .tmem_dat_i (tmem_dat_i),
    .tmem_ack_i (tmem_ack_i)
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
    `SVTEST(MEM_not_ready_if_not_enabled)
        fu_i.ena = 0;
        #1
        `FAIL_UNLESS(!fu_o.rdy);
    `SVTEST_END

    `SVTEST(MEM_ready_if_enabled_with_invalid_opcode)
        fu_i.ena = 1;
      	#1
        `FAIL_UNLESS(fu_o.rdy);
    `SVTEST_END

    `SVTEST(MEM_signals_error_if_enabled_with_invalid_opcode)
        fu_i.ena = 1;
        #1
        `FAIL_UNLESS(fu_o.err);
    `SVTEST_END

    `SVTEST(MEM_does_not_write_back_if_enabled_with_invalid_opcode)
        fu_i.ena = 1;
        #1
        `FAIL_UNLESS(!fu_o.res_wb);
    `SVTEST_END

    `SVTEST(MEM_not_ready_if_not_enabled_and_with_valid_opcode_and_dmem_ack)
      fu_i.ena = 0;
      fu_i.op = MEM_OP_LW;
      dmem_ack_i = 1'b1;
      #1
      `FAIL_UNLESS(!fu_o.rdy);
    `SVTEST_END

    `SVTEST(MEM_not_ready_if_enabled_with_valid_opcode_and_dmem_nack)
      fu_i.ena = 1;
	  fu_i.op = MEM_OP_LW;
      dmem_ack_i = 1'b0;
      #1
      `FAIL_UNLESS(!fu_o.rdy);
    `SVTEST_END

    `SVTEST(MEM_ready_if_enabled_with_valid_opcode_and_dmem_ack)
      fu_i.ena = 1;
  	  fu_i.op = MEM_OP_LW;
      dmem_ack_i = 1'b1;
      #1
      `FAIL_UNLESS(fu_o.rdy);
    `SVTEST_END

    // --- Load ----------------------------------------------------------------------------------------------------- //

    // --- Store ---------------------------------------------------------------------------------------------------- //

  `SVUNIT_TESTS_END
endmodule
