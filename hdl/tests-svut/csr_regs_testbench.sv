`include "svut_h.sv"
`include "csr_regs.sv"
`include "csr_pkg.svh"

module csr_regs_testbench();

    `SVUT_SETUP

    parameter int HARTS = 1;

    logic                       clk_i;
    logic                       rst_i;

    logic [0 : 0]               hartid_i;
    priv_mode_t                 priv_i;
    priv_mode_t                 priv_prev_o;

    logic [11:0]                csr_adr_i;
    logic                       csr_we_i;
    logic [XLEN-1:0]            csr_dat_i;
    logic [XLEN-1:0]            csr_dat_o;

    logic [XLEN-1:0]            trap_pc_i;
    logic [XLEN-1:0]            trap_adr_i;
    logic [XLEN-1:0]            trap_vec_o;
    logic                       mret_i;

    logic                       ex_i;
    ex_cause_t                  ex_cause_i;

    logic                       irq_i;
    irq_cause_t                 irq_cause_i;
    ivec_t                      irq_pend_i;
    logic                       irq_ena_o;
    ivec_t                      irq_ena_vec_o;

    logic [XLEN-1:0]            dat;

    csr_regs
    #(
        .HARTS (HARTS)
    )
    dut (
        .clk_i         (clk_i),
        .rst_i         (rst_i),

        // General
        .hartid_i      (hartid_i),
        .priv_i        (priv_i),
        .priv_prev_o   (priv_prev_o),

        // CSR access
        .csr_adr_i     (csr_adr_i),
        .csr_we_i      (csr_we_i),
        .csr_dat_i     (csr_dat_i),
        .csr_dat_o     (csr_dat_o),

        // Traps
        .trap_pc_i     (trap_pc_i),
        .trap_adr_i    (trap_adr_i),
        .trap_vec_o    (trap_vec_o),
        .mret_i        (mret_i),

        // Exception
        .ex_i          (ex_i),
        .ex_cause_i    (ex_cause_i),

        // IRQs
        .irq_i         (irq_i),
        .irq_cause_i   (irq_cause_i),
        .irq_pend_i    (irq_pend_i),
        .irq_ena_o     (irq_ena_o),
        .irq_ena_vec_o (irq_ena_vec_o)
    );


    // Clock
    parameter int PERIOD = 2;
    initial clk_i = 0;
    always #PERIOD clk_i = ~clk_i;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("csr_regs_testbench.vcd");
    //     $dumpvars(0, csr_regs_testbench);
    // end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task defaults();
    begin
        hartid_i    = 0;
        priv_i      = PRIV_MODE_MACHINE;

        csr_adr_i   = 0;
        csr_we_i    = 0;
        csr_dat_i   = 0;

        trap_pc_i   = 'haaaa;
        trap_adr_i  = 'hbbbb;
        mret_i      = 0;

        ex_i        = 0;
        ex_cause_i  = EX_CAUSE_INST_ILLEGAL;

        irq_i       = 0;
        irq_cause_i = IRQ_CAUSE_MEI;
        irq_pend_i  = 0;
    end
    endtask

    task setup(msg="");
    begin
        defaults();
        reset();
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    // -------------------------------------------------------------------------------------------------------------- //
    // Helper tasks
    // -------------------------------------------------------------------------------------------------------------- //
    task reset();
    begin
        @(posedge clk_i)
        rst_i = 1'b1;

        #PERIOD;
        rst_i = 1'b0;
    end
    endtask

    task csr_read;
        input  csr_adr_t        adr;
        output logic [XLEN-1:0] dat;
    begin
        @(posedge clk_i);
        csr_adr_i = adr;
        #1
        dat = csr_dat_o;
    end
    endtask

    task csr_write;
        input  csr_adr_t        adr;
        input  logic [XLEN-1:0] dat;
    begin
        @(posedge clk_i);
        csr_adr_i = adr;
        csr_dat_i = dat;
        csr_we_i  = 1'b1;
        #1
        csr_we_i  = 1'b0;
    end
    endtask

    task exception(ex_cause_t cause);
    begin
        @(posedge clk_i);
        ex_cause_i = cause;
        ex_i = 1'b1;
        #1;
        ex_i = 1'b0;
    end
    endtask

    task mret();
    begin
        @(posedge clk_i);
        mret_i = 1'b1;
        #1;
        mret_i = 1'b0;
    end
    endtask

    `define BIT(pos) (1 << pos)

    `TEST_SUITE("CSR_REGS Test")
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

    // --- Machine Information registers ---------------------------------------------------------------------------- //
    `UNIT_TEST("mvendorid returns correct MVENDORID")
        csr_read(.adr(CSR_ADR_MVENDORID), .dat(dat));
        `FAIL_IF_NOT_EQUAL(csr_dat_o, MVENDORID);
    `UNIT_TEST_END

    `UNIT_TEST("mvendorid is r/o")
        csr_write   (.adr(CSR_ADR_MVENDORID), .dat('h4711));
        csr_read    (.adr(CSR_ADR_MVENDORID), .dat(dat));
        `FAIL_IF_NOT_EQUAL(csr_dat_o, MVENDORID);
    `UNIT_TEST_END

    `UNIT_TEST("marchid returns correct MARCHID")
        csr_read(.adr(CSR_ADR_MARCHID), .dat(dat));
        `FAIL_IF_NOT_EQUAL(csr_dat_o, MARCHID);
    `UNIT_TEST_END

    `UNIT_TEST("mvendorid is r/o")
        csr_write   (.adr(CSR_ADR_MARCHID), .dat('h4711));
        csr_read    (.adr(CSR_ADR_MARCHID), .dat(dat));
        `FAIL_IF_NOT_EQUAL(csr_dat_o, MARCHID);
    `UNIT_TEST_END

    `UNIT_TEST("mimpid returns correct MIMPID")
        csr_read(.adr(CSR_ADR_MARCHID), .dat(dat));
        `FAIL_IF_NOT_EQUAL(csr_dat_o, MARCHID);
    `UNIT_TEST_END

    `UNIT_TEST("mimpid is r/o")
        csr_write   (.adr(CSR_ADR_MIMPID), .dat('h4711));
        csr_read    (.adr(CSR_ADR_MIMPID), .dat(dat));
        `FAIL_IF_NOT_EQUAL(csr_dat_o, MIMPID);
    `UNIT_TEST_END

    `UNIT_TEST("mhartid returns correct hartid")
        hartid_i = 1;
        csr_read(.adr(CSR_ADR_MHARTID), .dat(dat));
        `FAIL_IF_NOT_EQUAL(csr_dat_o, 1);
    `UNIT_TEST_END

    `UNIT_TEST("mhartid is r/o")
        hartid_i = 1;
        csr_write   (.adr(CSR_ADR_MHARTID), .dat('h4711));
        csr_read    (.adr(CSR_ADR_MHARTID), .dat(dat));
        `FAIL_IF_NOT_EQUAL(csr_dat_o, 1);
    `UNIT_TEST_END

    // --- Machine Trap Setup --------------------------------------------------------------------------------------- //
    `UNIT_TEST("mstatus returns zero after reset")
        reset();
        csr_read(.adr(CSR_ADR_MSTATUS), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, 0);
    `UNIT_TEST_END

    `UNIT_TEST("mstatus allows write to mie bit (idx: 3)")
        csr_write(.adr(CSR_ADR_MSTATUS), .dat(`BIT(MSTATUS_MIE)));
        csr_read(.adr(CSR_ADR_MSTATUS), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, `BIT(MSTATUS_MIE));
    `UNIT_TEST_END

    `UNIT_TEST("mstatus only allows write to mie bit (idx: 3)")
        csr_write(.adr(CSR_ADR_MSTATUS), .dat(~0));
        csr_read(.adr(CSR_ADR_MSTATUS), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, `BIT(MSTATUS_MIE));
    `UNIT_TEST_END

    `UNIT_TEST("mstatus saves mie-bit (3) to mpie-bit (7) on exception")
        csr_write(.adr(CSR_ADR_MSTATUS), .dat(`BIT(MSTATUS_MIE)));
        exception(EX_CAUSE_INST_ILLEGAL);
        csr_read(.adr(CSR_ADR_MSTATUS), .dat(dat));

        `FAIL_IF_NOT_EQUAL((dat & `BIT(MSTATUS_MPIE)), `BIT(MSTATUS_MPIE));
    `UNIT_TEST_END

    `UNIT_TEST("mstatus saves machine mode to mpp-field [12:11] on exception")
        priv_i = PRIV_MODE_MACHINE;
        exception(EX_CAUSE_INST_ILLEGAL);
        csr_read(.adr(CSR_ADR_MSTATUS), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, XLEN'(MSTATUS_MPP_MACHINE) << MSTATUS_MPP);
    `UNIT_TEST_END

    `UNIT_TEST("mstatus saves machine mode to mpp-field [12:11] (user mode) on exception")
        priv_i = PRIV_MODE_USER;
        exception(EX_CAUSE_INST_ILLEGAL);
        csr_read(.adr(CSR_ADR_MSTATUS), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, XLEN'(MSTATUS_MPP_MACHINE) << MSTATUS_MPP);
    `UNIT_TEST_END

    `UNIT_TEST("mstatus cleats mie bit after exception")
        csr_write(.adr(CSR_ADR_MSTATUS), .dat(`BIT(MSTATUS_MIE)));
        exception(EX_CAUSE_INST_ILLEGAL);
        csr_read(.adr(CSR_ADR_MSTATUS), .dat(dat));

        `FAIL_IF((dat & `BIT(MSTATUS_MIE)) > 0);
    `UNIT_TEST_END

    `UNIT_TEST("mstatus recovers mie bit after mret")
        csr_write(.adr(CSR_ADR_MSTATUS), .dat(`BIT(MSTATUS_MIE)));
        exception(EX_CAUSE_INST_ILLEGAL);
        mret();

        `FAIL_IF((csr_dat_o & `BIT(MSTATUS_MIE)) == 0);
    `UNIT_TEST_END

    `UNIT_TEST("mie is 0 after reset")
        csr_write(.adr(CSR_ADR_MIE), .dat(~0));
        reset();
        csr_read (.adr(CSR_ADR_MIE), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, 0);
    `UNIT_TEST_END

    `UNIT_TEST("mie writes only mask bits")
        csr_write(.adr(CSR_ADR_MIE), .dat(~0));
        csr_read (.adr(CSR_ADR_MIE), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, MIE_MASK);
    `UNIT_TEST_END

    `UNIT_TEST("mtvec is 0 after reset")
        csr_write(.adr(CSR_ADR_MTVEC), .dat('h4711_0815));
        reset();
        csr_read (.adr(CSR_ADR_MTVEC), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, 0);
    `UNIT_TEST_END

    `UNIT_TEST("mtvec is r/w")
        csr_write(.adr(CSR_ADR_MTVEC), .dat('h4711_0815));
        csr_read (.adr(CSR_ADR_MTVEC), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, 'h4711_0815);
    `UNIT_TEST_END

    `UNIT_TEST("mcounteren is 0 after reset")
        csr_write(.adr(CSR_ADR_MCOUNTEREN), .dat(~0));
        reset();
        csr_read (.adr(CSR_ADR_MTVEC), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, 0);
    `UNIT_TEST_END

    `UNIT_TEST("mcounteren writes mask")
        csr_write(.adr(CSR_ADR_MCOUNTEREN), .dat(~0));
        csr_read (.adr(CSR_ADR_MCOUNTEREN), .dat(dat));

        `FAIL_IF_NOT_EQUAL(dat, MCOUNTEREN_MASK);
    `UNIT_TEST_END

    `UNIT_TEST("priv_prev_o keeps machine mode on exception and mret")
        reset();
        `FAIL_IF_NOT_EQUAL(priv_prev_o, PRIV_MODE_MACHINE);

        exception(EX_CAUSE_INST_ILLEGAL);
        `FAIL_IF_NOT_EQUAL(priv_prev_o, PRIV_MODE_MACHINE);

        mret();
        `FAIL_IF_NOT_EQUAL(priv_prev_o, PRIV_MODE_MACHINE);
    `UNIT_TEST_END

    // --- Machine Trap Handling ------------------------------------------------------------------------------------ //

    `TEST_SUITE_END
endmodule
