// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Ext.     : Zicsr
 * Purpose  : Control and status register implementation
 *
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
    input   logic [HARTS_WIDTH-1 : 0]   hartid_i,      // Hardware thread id
    input   priv_mode_t                 mpriv_i,       // Privilege mode of the hart
    output  priv_mode_t                 mpriv_prev_o,  // Revious privilege mode of the hart

    // CSR access
    input   logic [11:0]                csr_adr_i,      // CSR address
    input   logic [63:0]                csr_dat_i,      // CSR write data
    input   logic                       csr_we_i,       // CSR write enable
    output  logic [63:0]                csr_dat_o,      // CSR read data

    // Trap (interrupt, exception or fault)
    input   logic [XLEN-1 : 0]          trap_pc_i,      // Current PC when trap occurs
    input   logic [XLEN-1 : 0]          trap_adr_i,     // Trap address (faulting memory address etc.)
    input   logic                       mret_i,         // Return from trap
    output  logic [XLEN-1 : 0]          mret_pc_o,      // Returning IP

    input   logic                       intr_i,         // Interrupt occured
    input   intr_cause_t                intr_cause_i,   // Interrupt type
    input   logic                       except_i,       // Exception occured
    input   except_cause_t              except_cause_i  // Exception type
);

    localparam int HARTS_WIDTH = HARTS > 1 ? $clog2(HARTS) : 1;
    localparam logic [25:0] SECV_EXT = RVEXT_U | RVEXT_I;

    /* TODO:
        -   Privilege mode
        -   mret instruction / trap_clear
        -   Setting of old interrupt counter
     */


    // --- Signal instances  ---------------------------------------------------------------------------------------- //
    // Machine Mode
    mstatus_t mstatus;         // Machine Status
    logic [63:0] misa;         // ISA and Extensions
    logic [63:0] mie;          // Machine Interrupt Enable
    logic [63:0] mtvec;        // Machine Trap-Vector Base-Address
    logic [63:0] mcounteren;   // Machine Counter Enable

    logic [63:0] mscratch;     // Machine Scratch
    logic [63:0] mepc;         // Machine Exception Program Counter
    mcause_t     mcause;       // Machine Cause
    logic [63:0] mtval;        // Machine Trap Value
    logic [63:0] mip;          // Machine Interrupt Pending

    logic [63:0] pmpcfg0;      // Configuration for PMP entries 0-3
    logic [63:0] pmpcfg1;      // Configuration for PMP entries 4-7
    logic [63:0] pmpaddr0;     // PMP Address Register 0
    logic [63:0] pmpaddr1;     // ...
    logic [63:0] pmpaddr2;
    logic [63:0] pmpaddr3;
    logic [63:0] pmpaddr4;
    logic [63:0] pmpaddr5;
    logic [63:0] pmpaddr6;
    logic [63:0] pmpaddr7;

    logic [63:0] mcycle;       // Machine Cycle Counter
    logic [63:0] minstret;     // Machine Instructions-Retired Counter

    logic [63:0] mvendorid;    // Vendor ID
    logic [63:0] marchid;      // Architecture ID
    logic [63:0] mimpid;       // Implementation ID

    // User Mode
    logic [63:0] ustatus;      // User Status Register
    logic [63:0] uie;          // User Interrupt Enable Register
    logic [63:0] utvec;        // User Trap-Vector Base-Address Register

    logic [63:0] uscratch;     // User Scratch Register
    logic [63:0] uepc;         // User Exception Program Counter
    logic [63:0] ucause;       // User Cause Register
    logic [63:0] utval;        // User Trap Value
    logic [63:0] uip;          // User Interrupt Pending

    always_ff @( posedge clk_i ) begin: csr_reset
        if (rst_i) begin
            // Machine mode
            mstatus     <= 64'h0;
            misa        <= 64'h0;
            mie         <= 64'h0;
            mtvec       <= 64'h0;
            mcounteren  <= 64'h0;

            mscratch    <= 64'h0;
            mepc        <= 64'h0;
            mcause      <= 64'h0;
            mtval       <= 64'h0;
            mip         <= 64'h0;

            pmpcfg0     <= 64'h0;
            pmpcfg1     <= 64'h0;
            pmpaddr0    <= 64'h0;
            pmpaddr1    <= 64'h0;
            pmpaddr2    <= 64'h0;
            pmpaddr3    <= 64'h0;
            pmpaddr4    <= 64'h0;
            pmpaddr5    <= 64'h0;
            pmpaddr6    <= 64'h0;
            pmpaddr7    <= 64'h0;

            mcycle      <= 64'h0;
            minstret    <= 64'h0;

            // User mode
            ustatus     <= 64'h0;
            uie         <= 64'h0;
            utvec       <= 64'h0;

            uscratch    <= 64'h0;
            uepc        <= 64'h0;
            ucause      <= 64'h0;
            utval       <= 64'h0;
            uip         <= 64'h0;
        end // rst_i

    else
        mcycle   <= mcycle + 1;
        minstret <= mcycle;

        // Interrupt handling
        if (intr_i) begin
            mcause <= 'b0;
            mcause.intr  <= 1'b1;
            mcause.cause <= intr_cause_i;
            mepc         <= trap_pc_i;
            mtval <= 'b0;
        end

        // Fault and exception handling
        else if (except_i) begin
            mcause       <= 'b0;
            mcause.intr  <= 1'b0;
            mcause.cause <= except_cause_i;
            mepc         <= trap_pc_i;
            mstatus.mpp  <= (mpriv_i == PRIV_MODE_MACHINE) ? 2'b11 : 2'b00;

            // Set machine trap value (trap address)
            if (except_cause_i == EXCEPT_CAUSE_LOAD_ADDRESS_MISALIGNED  ||
                except_cause_i == EXCEPT_CAUSE_LOAD_ACCESS_FAULT        ||
                except_cause_i == EXCEPT_CAUSE_STORE_ADDRESS_MISALIGNED ||
                except_cause_i == EXCEPT_CAUSE_STORE_ACCESS_FAULT       ||
                except_cause_i == EXCEPT_CAUSE_MTAG_INVLD)
            begin
                mtval <= trap_adr_i;
            end
        end

        if (!intr_i && !except_i && mret_i) begin
            mret_pc_o <= mepc;
            mcause <= 'b0;
            mepc   <= 'b0;
            mtval  <= 'b0;
        end
    end

    always_comb begin : csr_read
        csr_dat_o = 64'h0;

        case (csr_adr_i)
            // Machine Timer
            CSR_ADDR_MCYCLE     : csr_dat_o = mcycle;
            CSR_ADDR_MINSTRET   : csr_dat_o = minstret;

            // Machine Information Registers
            CSR_ADDR_MVENDORID  : csr_dat_o = MVENDORID;
            CSR_ADDR_MARCHID    : csr_dat_o = MARCHID;
            CSR_ADDR_MIMPID     : csr_dat_o = MIMPID;
            CSR_ADDR_MHARTID    : csr_dat_o = {{(XLEN-HARTS_WIDTH){1'b0}}, hartid_i};

            default:
                csr_dat_o = 64'h0;
        endcase
    end

endmodule
