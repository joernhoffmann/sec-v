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
    parameter int HARTS = 1

) (
    input   logic                       clk_i,
    input   logic                       rst_i,

    input   logic [HARTS_WIDTH-1 : 0]   hartid_i,   // Hart ID requesting
    input   logic [XLEN-1 : 0]          pc_i,       // Current PC

    input   logic [11:0]                addr_i,     // CSR address
    input   logic [63:0]                data_i,     // CSR input
    input   logic                       we_i,       // CSR input write enable
    output  logic [63:0]                data_o      // CSR output
);

    localparam int HARTS_WIDTH = $clog2(HARTS) + 1;

    // --- CSR Adresses --------------------------------------------------------------------------------------------- //
    typedef enum logic [11:0] {
        // User Mode
        CSR_ADDR_USTATUS     = 12'h000, // User Status Register
        CSR_ADDR_UIE         = 12'h004, // User Interrupt Enable Register
        CSR_ADDR_UTVEC       = 12'h005, // User Trap-Vector Base-Address Register

        // User Trap Handling
        CSR_ADDR_USCRATCH    = 12'h040, // User Scratch Register
        CSR_ADDR_UEPC        = 12'h041, // User Exception Program Counter
        CSR_ADDR_UCAUSE      = 12'h042, // User Cause Register
        CSR_ADDR_UTVAL       = 12'h043, // User Trap Value
        CSR_ADDR_UIP         = 12'h044, // User Interrupt Pending

        // Machine Status and Control
        CSR_ADDR_MSTATUS     = 12'h300, // Machine Status
        CSR_ADDR_MISA        = 12'h301, // ISA and Extensions
        CSR_ADDR_MIE         = 12'h304, // Machine Interrupt Enable
        CSR_ADDR_MTVEC       = 12'h305, // Machine Trap-Vector Base-Address
        CSR_ADDR_MCOUNTEREN  = 12'h306, // Machine Counter Enable

        // Machine Trap Handling
        CSR_ADDR_MSCRATCH    = 12'h340, // Machine Scratch
        CSR_ADDR_MEPC        = 12'h341, // Machine Exception Program Counter
        CSR_ADDR_MCAUSE      = 12'h342, // Machine Cause
        CSR_ADDR_MTVAL       = 12'h343, // Machine Trap Value
        CSR_ADDR_MIP         = 12'h344, // Machine Interrupt Pending

        // Machine Memory Protection
        CSR_ADDR_PMPCFG0     = 12'h3A0, // Configuration for PMP entries 0-3
        CSR_ADDR_PMPCFG1     = 12'h3A1, // Configuration for PMP entries 4-7
        CSR_ADDR_PMPADDR0    = 12'h3B0,
        CSR_ADDR_PMPADDR1    = 12'h3B1,
        CSR_ADDR_PMPADDR2    = 12'h3B2,
        CSR_ADDR_PMPADDR3    = 12'h3B3,
        CSR_ADDR_PMPADDR4    = 12'h3B4,
        CSR_ADDR_PMPADDR5    = 12'h3B5,
        CSR_ADDR_PMPADDR6    = 12'h3B6,
        CSR_ADDR_PMPADDR7    = 12'h3B7,

        // Machine Timer Registers
        CSR_ADDR_MCYCLE      = 12'hB00, // Machine Cycle Counter
        CSR_ADDR_MINSTRET    = 12'hB02, // Machine Instructions-Retired Counter

        // Machine Information Registers
        CSR_ADDR_MVENDORID   = 12'hF11, // Vendor ID
        CSR_ADDR_MARCHID     = 12'hF12, // Architecture ID
        CSR_ADDR_MIMPID      = 12'hF13, // Implementation ID
        CSR_ADDR_MHARTID     = 12'hF14  // Hardware Thread ID
    } csr_addr_t;

    // --- CSR bitfields -------------------------------------------------------------------------------------------- //
    typedef struct packed {             // Machine Status Information Register
        logic        sd;                // Status Dirty Bit
        logic [62:18] reserved0;        // Reserved Bits
        logic        mprv;              // Modify Privilege Bit
        logic [1:0]  xs;                // User Extension Status
        logic [1:0]  fs;                // Floating-point Status
        logic [1:0]  mpp;               // Machine Previous Privilege
        logic [2:0]  reserved1;         // Reserved Bits
        logic        mpie;              // Machine Previous Interrupt Enable
        logic [2:0]  reserved2;         // Reserved Bits
        logic        mie;               // Machine Interrupt Enable
        logic [2:0]  reserved3;         // Reserved Bits
    } mstatus_t;


    typedef struct packed {             // Machine ISA Information Register
        logic [1:0]  mxl;               // ISA Width aka. machine x-length (1 = RV32, 2 = RV64, 3 = RV128)
        logic [35:0] reserved;          // Reserved Bits
        logic [25:0] extensions;        // ISA Extensions (bit position corresponds to letter, e.g., bit 0 for "A")
    } misa_t;

    typedef struct packed {             // Machine Interrupt Enable Register
        logic [63:12]   reserved;       // Reserved Bits
        logic           meie;           // Machine External Interrupt Enable
        logic [2:0]     reserved1;      // Reserved Bits
        logic           mtie;           // Machine Timer Interrupt Enable
        logic [2:0]     reserved2;      // Reserved Bits
        logic           msie;           // Machine Software Interrupt Enable
        logic [2:0]     reserved3;      // Reserved Bits
    } mie_t;

    typedef struct packed {             // Machine Trap Vector Register
        logic [61:2] base;              // Base address of the trap vector
        logic [1:0]  mode;              // Trap-Vector Base-Address Mode
    } mtvec_t;

    typedef struct packed {
        logic [31:3] reserved;          // Reserved Bits
        logic ir;                       // Enable Instructions-Retired Counter
        logic tm;                       // Enable Timer Register
        logic cy;                       // Enable Cycle Counter
    } mcounteren_t;

    // --- Default values ------------------------------------------------------------------------------------------- //
    localparam logic [63:0] MVENDORID   = 64'h4254_4147;    // Bitaggregat - BTAG
    localparam logic [63:0] MARCHID     = 64'hbabe_0001;
    localparam logic [63:0] MIMPID      = 64'hcaff_0001;
    localparam logic [25:0] EXTENSIONS  = 26'h100100;       // User mode (20), Integer (8)

    // --- Signal instances  ---------------------------------------------------------------------------------------- //
    // Machine Mode
    mstatus_t mstatus;         // Machine Status
    logic [63:0] misa;         // ISA and Extensions
    logic [63:0] mie;          // Machine Interrupt Enable
    logic [63:0] mtvec;        // Machine Trap-Vector Base-Address
    logic [63:0] mcounteren;   // Machine Counter Enable

    logic [63:0] mscratch;     // Machine Scratch
    logic [63:0] mepc;         // Machine Exception Program Counter
    logic [63:0] mcause;       // Machine Cause
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
    logic [63:0] mhartid;      // Hardware Thread ID

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
            mhartid     <= 64'h0;

            // User mode
            ustatus     <= 64'h0;
            uie         <= 64'h0;
            utvec       <= 64'h0;

            uscratch    <= 64'h0;
            uepc        <= 64'h0;
            ucause      <= 64'h0;
            utval       <= 64'h0;
            uip         <= 64'h0;
        end

    else
        mcycle   <= mcycle + 1;
        minstret <= mcycle;

    end


    always_comb begin : csr_read
        data_o = 64'h0;

        case (addr_i)
            // Machine Timer
            CSR_ADDR_MCYCLE     : data_o = mcycle;
            CSR_ADDR_MINSTRET   : data_o = minstret;

            // Machine Information Registers
            CSR_ADDR_MVENDORID  : data_o = MVENDORID;
            CSR_ADDR_MARCHID    : data_o = MARCHID;
            CSR_ADDR_MIMPID     : data_o = MIMPID;
            CSR_ADDR_MHARTID    : data_o = {{(XLEN-HARTS_WIDTH){1'b0}}, hartid_i};

            default:
                data_o = 64'h0;
        endcase
    end

endmodule
