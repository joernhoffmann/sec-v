`include "svut_h.sv"
`include "rom_wb.sv"
`include "ram_wb.sv"
`include "alu_core.sv"
`include "alu_decoder.sv"
`include "alu.sv"
`include "branch.sv"
`include "decoder.sv"
`include "lfsr_rng.sv"
`include "mem.sv"
`include "mem_decoder.sv"
`include "mtag.sv"
`include "mtag_chk.sv"
`include "mtag_decoder.sv"
`include "mtag_mem.sv"
`include "secv.sv"
`include "gpr.sv"
`include "csr.sv"
`include "csr_regs.sv"

module secv_testbench();
    `SVUT_SETUP

    parameter int ILEN = secv_pkg::ILEN;
    parameter int XLEN = secv_pkg::XLEN;
    parameter int TLEN = 16;
    parameter int GRANULARTIY = 2;
    parameter int IADR_WIDTH = 10;          // 1K (Byte addressable)
    parameter int DADR_WIDTH = 10;          // 1k (Byte addressable)
    parameter int ISEL_WIDTH = ILEN/8;
    parameter int DSEL_WIDTH = XLEN/8;

    logic   clk_i;
    logic   rst_i;

    // Instruction memory
    logic                       imem_cyc_o;
    logic                       imem_stb_o;
    logic [ISEL_WIDTH-1 : 0]    imem_sel_o;
    logic [IADR_WIDTH-1 : 0]    imem_adr_o;
    logic [ILEN-1       : 0]    imem_dat_i;
    logic                       imem_ack_i;

    // Data memory
    logic                       dmem_cyc_o;
    logic                       dmem_stb_o;
    logic [DSEL_WIDTH-1 : 0]    dmem_sel_o;
    logic [DADR_WIDTH-1 : 0]    dmem_adr_o;
    logic                       dmem_we_o;
    logic [XLEN-1 : 0]          dmem_dat_o;
    logic [XLEN-1 : 0]          dmem_dat_i;
    logic                       dmem_ack_i;

    secv #(
        .IADR_WIDTH (IADR_WIDTH),
        .DADR_WIDTH (DADR_WIDTH),
        .ISEL_WIDTH (ISEL_WIDTH),
        .DSEL_WIDTH (DSEL_WIDTH)
    ) dut
    (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .imem_cyc_o (imem_cyc_o),
        .imem_stb_o (imem_stb_o),
        .imem_sel_o (imem_sel_o),
        .imem_adr_o (imem_adr_o),
        .imem_dat_i (imem_dat_i),
        .imem_ack_i (imem_ack_i),

        .dmem_cyc_o (dmem_cyc_o),
        .dmem_stb_o (dmem_stb_o),
        .dmem_sel_o (dmem_sel_o),
        .dmem_adr_o (dmem_adr_o),
        .dmem_we_o  (dmem_we_o),
        .dmem_dat_o (dmem_dat_o),
        .dmem_dat_i (dmem_dat_i),
        .dmem_ack_i (dmem_ack_i)
   );

    rom_wb #(
        .FILE   ("mtag.hex"),
        .ADR_WIDTH (10-2),              // 256 * 4 Byte = 1k
        .DAT_WIDTH (secv_pkg::ILEN)     // 4 Byte
    )  rom (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .cyc_i  (imem_cyc_o),
        .stb_i  (imem_stb_o),
        .sel_i  (imem_sel_o),
        .adr_i  (imem_adr_o[9:2]),
        .dat_o  (imem_dat_i),
        .ack_o  (imem_ack_i)
    );

    ram_wb # (
        .RESET_MEM  (1),
        .ADR_WIDTH  (10-3),             // 128 * 8 Byte = 1k
        .DAT_WIDTH  (secv_pkg::XLEN)    // 8 Byte
    ) ram (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .cyc_i  (dmem_cyc_o),
        .stb_i  (dmem_stb_o),
        .sel_i  (dmem_sel_o),
        .adr_i  (dmem_adr_o[9:3]),
        .we_i   (dmem_we_o),
        .dat_i  (dmem_dat_o),
        .dat_o  (dmem_dat_i),
        .ack_o  (dmem_ack_i)
    );

    // To create a clock:
    initial clk_i = 0;
    always #2 clk_i = ~clk_i;

    // To dump data for visualization:
    initial begin
         $dumpfile("secv_testbench.vcd");
         $dumpvars(0, secv_testbench);
    end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    // -------------------------------------------------------------------------------------------------------------- //
    // Helper
    // -------------------------------------------------------------------------------------------------------------- //

    task setup(msg="");
    begin
        reset();
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    task reset();
    begin
        @(posedge clk_i)
        rst_i = 1'b1;

        @(posedge clk_i)
        rst_i = 1'b0;
    end
    endtask

    `TEST_SUITE("SECV program execution")

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

    `UNIT_TEST("Test program execution")
        #10000;

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
