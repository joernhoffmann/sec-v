`include "svunit_defines.svh"
`include "mem_wb.sv"

module mem_wb_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "mem_wb_ut";
  svunit_testcase svunit_ut;
  
  	logic clk, rst;
  
	wishbone_if wb(clk, rst);


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  mem_wb my_mem_wb( .wb(wb));


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



  `SVUNIT_TESTS_END

endmodule
