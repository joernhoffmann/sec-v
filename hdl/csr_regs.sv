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
import secv_pkg::*;

module csr_regs #(
    parameter int HARTS = 2

) (
    input   logic                   clk_i,
    input   logic                   rst_i,

    input   logic [HARTS_WIDTH-1:0] hartid_i,   // Current hardware thread id

    input   logic [11:0]            addr_i,     // CSR address
    input   logic [31:0]            data_i,     // CSR input
    input   logic                   we_i,       // CSR input write enable
    output  logic [31:0]            data_o      // CSR output
);

    localparam HARTS_WIDTH = $clog2(HARTS);

    // --- Addresses ------------------------------------------------------------------------------------------------ //
    // Machine Mode
    // Machine Trap Setup
    localparam MSTATUS_ADDR     = 12'h300;      // Machine Status
    localparam MISA_ADDR        = 12'h301;      // ISA and Extensions
    localparam MIE_ADDR         = 12'h304;      // Machine Interrupt Enable
    localparam MTVEC_ADDR       = 12'h305;      // Machine Trap-Vector Base-Address
    localparam MCOUNTEREN_ADDR  = 12'h306;      // Machine Counter Enable

    // Machine Trap Handling
    localparam MSCRATCH_ADDR    = 12'h340;      // Machine Scratch
    localparam MEPC_ADDR        = 12'h341;      // Machine Exception Program Counter
    localparam MCAUSE_ADDR      = 12'h342;      // Machine Cause
    localparam MTVAL_ADDR       = 12'h343;      // Machine Trap Value
    localparam MIP_ADDR         = 12'h344;      // Machine Interrupt Pending

    // Machine Memory Protection
    localparam PMPCFG0          = 12'h3A0;      // Configuration for PMP entries 0-3
    localparam PMPCFG1          = 12'h3A1;      // Configuration for PMP entries 4-7
    localparam PMPADDR0         = 12'h3B0;
    localparam PMPADDR1         = 12'h3B1;
    localparam PMPADDR2         = 12'h3B2;
    localparam PMPADDR3         = 12'h3B3;
    localparam PMPADDR4         = 12'h3B4;
    localparam PMPADDR5         = 12'h3B5;
    localparam PMPADDR6         = 12'h3B6;
    localparam PMPADDR7         = 12'h3B7;

    // Machine Timer Registers
    localparam MCYCLE_ADDR      = 12'hB00;      // Machine Cycle Counter
    localparam MINSTRET_ADDR    = 12'hB02;      // Machine Instructions-Retired Counter

    // Machine Information Registers
    localparam MVENDORID_ADDR   = 12'hF11;      // Vendor ID
    localparam MARCHID_ADDR     = 12'hF12;      // Architecture ID
    localparam MIMPID_ADDR      = 12'hF13;      // Implementation ID
    localparam MHARTID_ADDR     = 12'hF14;      // Hardware Thread ID

    // User Mode
    // User Trap Setup
    localparam USTATUS_ADDR     = 12'h000;      // User Status Register
    localparam UIE_ADDR         = 12'h004;      // User Interrupt Enable Register
    localparam UTVEC_ADDR       = 12'h005;      // User Trap-Vector Base-Address Register

    // User Trap Handling
    localparam USCRATCH_ADDR    = 12'h040;      // User Scratch Register
    localparam UEPC_ADDR        = 12'h041;      // User Exception Program Counter
    localparam UCAUSE_ADDR      = 12'h042;      // User Cause Register
    localparam UTVAL_ADDR       = 12'h043;      // User Trap Value
    localparam UIP_ADDR         = 12'h044;      // User Interrupt Pending

    // --- Defaults ----------------------------------------------------------------------------------------------------- //
    localparam MVENDORID        = 32'h4254_4147;    // Bitaggregat - BTAG
    localparam MARCHID          = 32'hbabe_0001;
    localparam MIMPID           = 32'hcaff_0001;

    // --- Register definitions ------------------------------------------------------------------------------------- //
    // Machine Mode
    logic [31:0] mstatus;      // Machine Status
    logic [31:0] misa;         // ISA and Extensions
    logic [31:0] mie;          // Machine Interrupt Enable
    logic [31:0] mtvec;        // Machine Trap-Vector Base-Address
    logic [31:0] mcounteren;   // Machine Counter Enable

    logic [31:0] mscratch;     // Machine Scratch
    logic [31:0] mepc;         // Machine Exception Program Counter
    logic [31:0] mcause;       // Machine Cause
    logic [31:0] mtval;        // Machine Trap Value
    logic [31:0] mip;          // Machine Interrupt Pending

    logic [31:0] pmpcfg0;      // Configuration for PMP entries 0-3
    logic [31:0] pmpcfg1;      // Configuration for PMP entries 4-7
    logic [31:0] pmpaddr0;     // PMP Address Register 0
    logic [31:0] pmpaddr1;     // ...
    logic [31:0] pmpaddr2;
    logic [31:0] pmpaddr3;
    logic [31:0] pmpaddr4;
    logic [31:0] pmpaddr5;
    logic [31:0] pmpaddr6;
    logic [31:0] pmpaddr7;

    logic [31:0] mcycle;       // Machine Cycle Counter
    logic [31:0] minstret;     // Machine Instructions-Retired Counter

    logic [31:0] mvendorid;    // Vendor ID
    logic [31:0] marchid;      // Architecture ID
    logic [31:0] mimpid;       // Implementation ID
    logic [31:0] mhartid;      // Hardware Thread ID

    // User Mode
    logic [31:0] ustatus;      // User Status Register
    logic [31:0] uie;          // User Interrupt Enable Register
    logic [31:0] utvec;        // User Trap-Vector Base-Address Register

    logic [31:0] uscratch;     // User Scratch Register
    logic [31:0] uepc;         // User Exception Program Counter
    logic [31:0] ucause;       // User Cause Register
    logic [31:0] utval;        // User Trap Value
    logic [31:0] uip;          // User Interrupt Pending

    always_ff @( posedge clk_i ) begin: csr_reset
        if (rst_i) begin
            // Machine mode
            mstatus     <= 32'h0;
            misa        <= 32'h0;
            mie         <= 32'h0;
            mtvec       <= 32'h0;
            mcounteren  <= 32'h0;

            mscratch    <= 32'h0;
            mepc        <= 32'h0;
            mcause      <= 32'h0;
            mtval       <= 32'h0;
            mip         <= 32'h0;

            pmpcfg0     <= 32'h0;
            pmpcfg1     <= 32'h0;
            pmpaddr0    <= 32'h0;
            pmpaddr1    <= 32'h0;
            pmpaddr2    <= 32'h0;
            pmpaddr3    <= 32'h0;
            pmpaddr4    <= 32'h0;
            pmpaddr5    <= 32'h0;
            pmpaddr6    <= 32'h0;
            pmpaddr7    <= 32'h0;

            mcycle      <= 32'h0;
            minstret    <= 32'h0;
            mhartid     <= 32'h0;

            // User mode
            ustatus     <= 32'h0;
            uie         <= 32'h0;
            utvec       <= 32'h0;

            uscratch    <= 32'h0;
            uepc        <= 32'h0;
            ucause      <= 32'h0;
            utval       <= 32'h0;
            uip         <= 32'h0;
        end

    else
        mcycle   <= mcycle + 1;
        minstret <= mcycle;

    end


    always_comb begin : csr_read
        data_o = 32'h0;

        case (addr_i)
            // Machine Timer
            MCYCLE_ADDR     : data_o = mcycle;
            MINSTRET_ADDR   : data_o = minstret;

            // Machine Information Registers
            MVENDORID_ADDR  : data_o = MVENDORID;
            MARCHID_ADDR    : data_o = MARCHID;
            MIMPID_ADDR     : data_o = MIMPID;
            MHARTID_ADDR    : data_o = {{(32-HARTS_WIDTH){1'b0}}, hartid_i};

            default:
                data_o = 32'h0;
        endcase
    end

endmodule
