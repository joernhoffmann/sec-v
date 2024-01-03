// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023 - 2024
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Ext.     : Zicsr
 * Purpose  : Control and status register (access, encoding etc.) implementation
 *
 * TODO
 *  [ ] User mode
 *  [ ] Physical Memory Protection (PMP)
 *  [ ] Counter
 *
 * History
 *  v1.0    - Initial version
 */
`include "secv_pkg.svh"
`include "csr_pkg.svh"
import secv_pkg::*;
import csr_pkg::*;

module csr_regs #(
    parameter int HARTS = 1
) (
    input   logic                       clk_i,
    input   logic                       rst_i,

    // Generic
    input   logic [HARTS_WIDTH-1 : 0]   hartid_i,               // Hardware thread id
    input   priv_mode_t                 priv_i,                 // Privilege mode of the hart
    output  priv_mode_t                 priv_prev_o,            // Revious privilege mode of the hart

    // CSR access
    input   logic [11:0]                csr_adr_i,              // CSR address
    input   logic                       csr_we_i,               // CSR write enable
    input   logic [XLEN-1:0]            csr_dat_i,              // CSR write data
    output  logic [XLEN-1:0]            csr_dat_o,              // CSR read data (old value)

    // Traps: interrupts, exceptions, faults
    input   logic [XLEN-1:0]            trap_pc_i,              // Current PC when trap occurs
    input   logic [XLEN-1:0]            trap_adr_i,             // Trap address (faulting memory address etc.)
    output  logic [XLEN-1:0]            trap_vec_o,             // Trap vector address (= next pc or base address)
    input   logic                       mret_i,                 // Return from trap

    // Interrupts
    input   logic                       irq_i,                  // Interrupt occured
    input   irq_cause_t                 irq_cause_i,            // Interrupt cause
    input   irq_vec_t                   irq_pend_i,             // Interrupt pending
    output  logic                       irq_ena_o,              // Interrupt handling enabled
    output  irq_vec_t                   irq_ena_vec_o,          // Enabled interrupts (external, timer etc.)

    // Exceptions
    input   logic                       ex_i,                   // Exception occured
    input   ex_cause_t                  ex_cause_i              // Exception type
);
    localparam int HARTS_WIDTH = HARTS > 1 ? $clog2(HARTS) : 1;
    // --- Functions ------------------------------------------------------------------------------------------------ //
    /*
     * Machine ISA register
     */
    localparam logic [25:0] SECV_EXT = MISA_EXT_U | MISA_EXT_I;
    function automatic logic [XLEN-1:0] misa_default();
        misa_t misa     = 'b0;
        misa.mxl        = MISA_MXL_RV64;
        misa.extensions = SECV_EXT;
        return misa;
    endfunction

    /*
     * Converts hid to register value
     */
    function automatic logic [XLEN-1:0] hartid_reg(logic [HARTS_WIDTH-1:0] hartid);
        return {{(XLEN - HARTS_WIDTH){1'b0}}, hartid_i};
    endfunction;

    /*
     * Machine status register when trap occurs
     */
    function automatic mstatus_t mstatus_trap (mstatus_t mstatus_i, priv_mode_t priv_mode);
        mstatus_t mstatus = mstatus_i;

        // Currently only machine mode supported, otherwise:
        // mstatus.mpp = (priv_mode == PRIV_MODE_MACHINE) ? MSTATUS_MPP_MACHINE : MSTATUS_MPP_USER;
        mstatus.mpp  = MSTATUS_PRIV_MACHINE;
        mstatus.mpie = mstatus_i.mie;
        mstatus.mie  = 1'b0;
        return mstatus;
    endfunction;

    /*
     * Machine status register on mret instruction
     */
    function automatic mstatus_t mstatus_mret(mstatus_t mstatus_i);
        mstatus_t mstatus = mstatus_i;
        mstatus.mpp  = MSTATUS_PRIV_MACHINE;
        mstatus.mpie = 1'b0;
        mstatus.mie  = mstatus_i.mpie;
        return mstatus;
    endfunction;

    // --- Internal signals  ------------------------------------------------------------------------------------------ //
    logic m_mode;
    assign m_mode = !rst_i && (priv_i == PRIV_MODE_MACHINE);

    // --- Register Implementation ---------------------------------------------------------------------------------- //
    /*
     * Machine Status and Control
     */
    mstatus_t        mstatus;       // Machine Status
    irq_reg_t        mie;           // Machine Interrupt Enable
    logic [XLEN-1:0] mtvec;         // Machine Trap-Vector Base-Address
    logic [XLEN-1:0] mcounteren;    // Machine Counter Enable

    always_ff @( posedge clk_i ) begin: status_control_impl
        if (rst_i) begin
            mstatus     <= 'h0;
            mie         <= 'h0;
            mtvec       <= 'h0;
            mcounteren  <= 'h0;
        end

        else begin
            if (irq_i) begin
                mstatus <= mstatus_trap(mstatus, priv_i);
            end

            else if (ex_i) begin
                mstatus <= mstatus_trap(mstatus, priv_i);
            end

            else if (mret_i) begin
                mstatus <= mstatus_mret(mstatus);
            end

            // Write
            else if (m_mode && csr_we_i) begin
                case (csr_adr_i)
                    CSR_ADR_MSTATUS:
                        mstatus <= (mstatus & ~MSTATUS_MASK) | (csr_dat_i & MSTATUS_MASK);

                    CSR_ADR_MIE:
                        mie <=csr_dat_i & IRQ_REG_MASK;

                    CSR_ADR_MTVEC:
                        mtvec <= csr_dat_i & MTVEC_MASK;

                    CSR_ADR_MCOUNTEREN:
                        mcounteren <= csr_dat_i & MCOUNTEREN_MASK;

                    default:
                        ;
                endcase
            end


        end
    end

    /*
     * Machine Trap Handling
     */
    logic [XLEN-1:0] mscratch;                  // Machine Scratch
    logic [XLEN-1:0] mepc;                      // Machine Exception Program Counter
    mcause_t         mcause;                    // Machine Cause
    logic [XLEN-1:0] mtval;                     // Machine Trap Value
    irq_reg_t        mip;                       // Machine Interrupt Pending

    // Registers
    always_ff @( posedge clk_i ) begin: trap_impl
        if (rst_i) begin
            mscratch    <= 'h0;
            mepc        <= 'h0;
            mcause      <= 'h0;
            mtval       <= 'h0;
            mip         <= 'h0;
        end

        else begin
            if (irq_i) begin
                mepc         <= trap_pc_i;
                mcause       <= 'h0;
                mcause.intr  <= 1'b1;
                mcause.cause <= irq_cause_i;
                mtval        <= 'h0;
            end

            else if (ex_i) begin
                mepc         <= trap_pc_i;
                mcause       <= 'h0;
                mcause.intr  <= 1'b0;
                mcause.cause <= ex_cause_i;

                if (ex_cause_i == EX_CAUSE_LOAD_ADDRESS_MISALIGNED  ||
                    ex_cause_i == EX_CAUSE_LOAD_ACCESS_FAULT        ||
                    ex_cause_i == EX_CAUSE_STORE_ADDRESS_MISALIGNED ||
                    ex_cause_i == EX_CAUSE_STORE_ACCESS_FAULT       ||
                    ex_cause_i == EX_CAUSE_MTAG_INVLD)
                begin
                    mtval <= trap_adr_i;
                end
            end

            else if (mret_i) begin
                mepc    <= 'h0;
                mcause  <= 'h0;
                mtval   <= 'h0;
                mstatus <= mstatus_mret(mstatus);
            end

            // Writes
            if (m_mode && csr_we_i) begin
                if (csr_adr_i == CSR_ADR_MSCRATCH)
                    mscratch <= csr_dat_i;

                 // TODO: machine interrupt pending (mip)
            end
        end
    end

    // Outputs
    assign irq_ena_o = mstatus.mie;
    always_comb begin : intr_en_impl
        irq_ena_vec_o = 'b0;
        irq_ena_vec_o.mei = mie.mei;
        irq_ena_vec_o.mti = mie.mti;
        irq_ena_vec_o.msi = mie.msi;
    end


    /*
     * Machine Memory Protection
     */
    logic [XLEN-1:0] pmpcfg0;       // Configuration for PMP entries 0-3
    logic [XLEN-1:0] pmpcfg1;       // Configuration for PMP entries 4-7
    logic [XLEN-1:0] pmpaddr0;      // PMP Address Register 0
    logic [XLEN-1:0] pmpaddr1;      // ...
    logic [XLEN-1:0] pmpaddr2;
    logic [XLEN-1:0] pmpaddr3;
    logic [XLEN-1:0] pmpaddr4;
    logic [XLEN-1:0] pmpaddr5;
    logic [XLEN-1:0] pmpaddr6;
    logic [XLEN-1:0] pmpaddr7;

    always_ff @( posedge clk_i ) begin: pmp_impl
        if (rst_i) begin
            pmpcfg0  <= 'h0;
            pmpcfg1  <= 'h0;
            pmpaddr0 <= 'h0;
            pmpaddr1 <= 'h0;
            pmpaddr2 <= 'h0;
            pmpaddr3 <= 'h0;
            pmpaddr4 <= 'h0;
            pmpaddr5 <= 'h0;
            pmpaddr6 <= 'h0;
            pmpaddr7 <= 'h0;
        end

        // TODO...
    end

    /*
     * Machhine Timer Registers
     */
    logic [XLEN-1:0] mcycle;        // Machine Cycle Counter
    logic [XLEN-1:0] minstret;      // Machine Instructions-Retired Counter

    always_ff @( posedge clk_i ) begin: counter_impl
        if (rst_i) begin
            mcycle      <= 'h0;
            minstret    <= 'h0;
        end

        else begin
            mcycle   <= mcycle + 1;
            minstret <= mcycle[1:0] == 2'b11 ? minstret + 1 : minstret;
        end
    end

    // --- CSR Read ------------------------------------------------------------------------------------------------- //
    always_comb begin : csr_read
        csr_dat_o = 'h0;

        case (csr_adr_i)
            // Machine Status and Control
            CSR_ADR_MSTATUS    : csr_dat_o = mstatus;
            CSR_ADR_MISA       : csr_dat_o = misa_default();
            CSR_ADR_MIE        : csr_dat_o = mie;
            CSR_ADR_MTVEC      : csr_dat_o = mtvec;
            CSR_ADR_MCOUNTEREN : csr_dat_o = mcounteren;

            // Machine Trap Handling
            CSR_ADR_MSCRATCH   : csr_dat_o = mscratch;
            CSR_ADR_MEPC       : csr_dat_o = mepc;
            CSR_ADR_MCAUSE     : csr_dat_o = mcause;
            CSR_ADR_MTVAL      : csr_dat_o = mtval;
            CSR_ADR_MIP        : csr_dat_o = mip;

            // Machine Timer
            CSR_ADR_MCYCLE     : csr_dat_o = mcycle;
            CSR_ADR_MINSTRET   : csr_dat_o = minstret;

            // Machine Information Registers
            CSR_ADR_MVENDORID  : csr_dat_o = MVENDORID;
            CSR_ADR_MARCHID    : csr_dat_o = MARCHID;
            CSR_ADR_MIMPID     : csr_dat_o = MIMPID;
            CSR_ADR_MHARTID    : csr_dat_o = hartid_reg(hartid_i);

            default:
                csr_dat_o = 'h0;
        endcase
    end
endmodule
