// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023 - 2024
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Ext.     : Zicsr
 * Purpose  : Control and status register (access, encoding etc.) implementation
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
    input   logic [HARTS_WIDTH-1 : 0]   hartid_i,       // Hardware thread id
    input   priv_mode_t                 priv_i,         // Privilege mode of the hart
    output  priv_mode_t                 priv_prev_o,    // Revious privilege mode of the hart

    // CSR access
    input   logic [11:0]                csr_adr_i,      // CSR address
    input   logic [XLEN-1:0]            csr_dat_i,      // CSR write data
    input   logic                       csr_we_i,       // CSR write enable
    output  logic [XLEN-1:0]            csr_dat_o,      // CSR read data

    // Trap: interrupt (async), exception (execution), fault (mem-access)
    input   logic [XLEN-1:0]            trap_pc_i,      // Current PC when trap occurs
    input   logic [XLEN-1:0]            trap_adr_i,     // Trap address (faulting memory address etc.)
    input   logic                       mret_i,         // Return from trap

    input   logic                       intr_i,         // Interrupt occured
    input   intr_cause_t                intr_cause_i,   // Interrupt type
    input   logic                       except_i,       // Exception occured
    input   except_cause_t              except_cause_i  // Exception type
);

    localparam int HARTS_WIDTH = HARTS > 1 ? $clog2(HARTS) : 1;

    /* TODO:
        - Privilege mode (user mode / machine mode)
        - mret instruction / trap_clear
        - Setting of old interrupt counter
     */

    // --- Default register values ---------------------------------------------------------------------------------- //
    // Machine ISA register
    localparam logic [25:0] SECV_EXT = MISA_EXT_U | MISA_EXT_I;
    function automatic logic [XLEN-1:0] misa_default();
        misa_t misa     = 'b0;
        misa.mxl        = MISA_MXL_RV64;
        misa.extensions = SECV_EXT;
        return misa;
    endfunction

    // Converts hid to register value
    function automatic logic [XLEN-1:0] hartid_reg(logic [HARTS_WIDTH-1:0] hartid);
        return {{(XLEN - HARTS_WIDTH){1'b0}}, hartid_i};
    endfunction;

    // Machine status register when trap occurs
    function automatic mstatus_t mstatus_trap (mstatus_t mstatus_i, priv_mode_t priv_mode);
        mstatus_t mstatus = mstatus_i;

        // Currently only machine mode supported, otherwise:
        // mstatus.mpp = (priv_mode == PRIV_MODE_MACHINE) ? MSTATUS_MPP_MACHINE : MSTATUS_MPP_USER;
        mstatus.mpp  = MSTATUS_PRIV_MACHINE;
        mstatus.mpie = mstatus_i.mie;
        mstatus.mie  = 1'b0;
        return mstatus;
    endfunction;

    // Machine status register on mret instruction
    function automatic mstatus_t mstatus_mret(mstatus_t mstatus_i);
        mstatus_t mstatus = mstatus_i;
        mstatus.mpp  <= MSTATUS_PRIV_MACHINE;
        mstatus.mpie <= 1'b0;
        mstatus.mie  <= mstatus_i.mpie;
        return mstatus;
    endfunction;


    // --- Registers ------------------------------------------------------------------------------------------------ //
    // Machine Mode
    mstatus_t mstatus;              // Machine Status
    logic [XLEN-1:0] misa;          // ISA and Extensions
    logic [XLEN-1:0] mie;           // Machine Interrupt Enable
    logic [XLEN-1:0] mtvec;         // Machine Trap-Vector Base-Address
    logic [XLEN-1:0] mcounteren;    // Machine Counter Enable

    logic [XLEN-1:0] mscratch;      // Machine Scratch
    logic [XLEN-1:0] mepc;          // Machine Exception Program Counter
    mcause_t         mcause;        // Machine Cause
    logic [XLEN-1:0] mtval;         // Machine Trap Value
    logic [XLEN-1:0] mip;           // Machine Interrupt Pending

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

    logic [XLEN-1:0] mcycle;        // Machine Cycle Counter
    logic [XLEN-1:0] minstret;      // Machine Instructions-Retired Counter

    logic [XLEN-1:0] mvendorid;     // Vendor ID
    logic [XLEN-1:0] marchid;       // Architecture ID
    logic [XLEN-1:0] mimpid;        // Implementation ID

    // User Mode
    logic [XLEN-1:0] ustatus;       // User Status Register
    logic [XLEN-1:0] uie;           // User Interrupt Enable Register
    logic [XLEN-1:0] utvec;         // User Trap-Vector Base-Address Register

    logic [XLEN-1:0] uscratch;      // User Scratch Register
    logic [XLEN-1:0] uepc;          // User Exception Program Counter
    logic [XLEN-1:0] ucause;        // User Cause Register
    logic [XLEN-1:0] utval;         // User Trap Value
    logic [XLEN-1:0] uip;           // User Interrupt Pending

    always_ff @( posedge clk_i ) begin: csr_reset
        if (rst_i) begin
            // Machine mode
            mstatus     <= 'h0;
            misa        <= 'h0;
            mie         <= 'h0;
            mtvec       <= 'h0;
            mcounteren  <= 'h0;

            mscratch    <= 'h0;
            mepc        <= 'h0;
            mcause      <= 'h0;
            mtval       <= 'h0;
            mip         <= 'h0;

            pmpcfg0     <= 'h0;
            pmpcfg1     <= 'h0;
            pmpaddr0    <= 'h0;
            pmpaddr1    <= 'h0;
            pmpaddr2    <= 'h0;
            pmpaddr3    <= 'h0;
            pmpaddr4    <= 'h0;
            pmpaddr5    <= 'h0;
            pmpaddr6    <= 'h0;
            pmpaddr7    <= 'h0;

            mcycle      <= 'h0;
            minstret    <= 'h0;

            // User mode
            ustatus     <= 'h0;
            uie         <= 'h0;
            utvec       <= 'h0;

            uscratch    <= 'h0;
            uepc        <= 'h0;
            ucause      <= 'h0;
            utval       <= 'h0;
            uip         <= 'h0;
        end // rst_i

    else
        mcycle   <= mcycle + 1;
        minstret <= mcycle;

        // Interrupt handling
        if (intr_i) begin
            mcause       <= 'h0;
            mcause.intr  <= 1'b1;
            mcause.cause <= intr_cause_i;
            mepc         <= trap_pc_i;
            mtval        <= 'h0;
            mstatus <= mstatus_trap(mstatus, priv_i);
        end

        // Fault and exception handling
        else if (except_i) begin
            mcause       <= 'h0;
            mcause.intr  <= 1'b0;
            mcause.cause <= except_cause_i;
            mepc         <= trap_pc_i;

            // Set machine trap value (trap address)
            if (except_cause_i == EXCEPT_CAUSE_LOAD_ADDRESS_MISALIGNED  ||
                except_cause_i == EXCEPT_CAUSE_LOAD_ACCESS_FAULT        ||
                except_cause_i == EXCEPT_CAUSE_STORE_ADDRESS_MISALIGNED ||
                except_cause_i == EXCEPT_CAUSE_STORE_ACCESS_FAULT       ||
                except_cause_i == EXCEPT_CAUSE_MTAG_INVLD)
            begin
                mtval <= trap_adr_i;
            end

            mstatus <= mstatus_trap(mstatus, priv_i);
        end

        else if (mret_i) begin
            mcause  <= 'h0;
            mepc    <= 'h0;
            mtval   <= 'h0;
            mstatus <= mstatus_mret(mstatus);
        end
    end

    always_comb begin : csr_read
        csr_dat_o = 'h0;

        case (csr_adr_i)
            // Machine Timer
            CSR_ADDR_MCYCLE     : csr_dat_o = mcycle;
            CSR_ADDR_MINSTRET   : csr_dat_o = minstret;

            // Macine Status and Control
            CSR_ADDR_MISA       : csr_dat_o = misa_default();

            // Machine Trap Handling
            CSR_ADDR_MCAUSE     : csr_dat_o = mcause;
            CSR_ADDR_MTVAL      : csr_dat_o = mtval;

            // Machine Information Registers
            CSR_ADDR_MVENDORID  : csr_dat_o = MVENDORID;
            CSR_ADDR_MARCHID    : csr_dat_o = MARCHID;
            CSR_ADDR_MIMPID     : csr_dat_o = MIMPID;
            CSR_ADDR_MHARTID    : csr_dat_o = hartid_reg(hartid_i);

            default:
                csr_dat_o = 'h0;
        endcase
    end

endmodule
