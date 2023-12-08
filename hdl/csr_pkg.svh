// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Control an Status Register (CSR) defines
 *
 * History
 *  v1.0    - Initial version
 */
`ifndef CSR_PKG
`define CSR_PKG

package csr_pkg;
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
        logic           sd;             // Status Dirty Bit
        logic [62:18]   reserved0;      // Reserved Bits
        logic           mprv;           // Modify Privilege Bit
        logic [1:0]     xs;             // User Extension Status
        logic [1:0]     fs;             // Floating-point Status
        logic [1:0]     mpp;            // Machine Previous Privilege
        logic [2:0]     reserved1;      // Reserved Bits
        logic           mpie;           // Machine Previous Interrupt Enable
        logic [2:0]     reserved2;      // Reserved Bits
        logic           mie;            // Machine Interrupt Enable
        logic [2:0]     reserved3;      // Reserved Bits
    } mstatus_t;

    typedef struct packed {             // Machine ISA Information Register
        logic [1:0]     mxl;            // ISA Width aka. machine x-length (1 = RV32, 2 = RV64, 3 = RV128)
        logic [35:0]    reserved;       // Reserved Bits
        logic [25:0]    extensions;     // ISA Extensions (bit position corresponds to letter, e.g., bit 0 for "A")
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
        logic [61:2]    base;           // Base address of the trap vector
        logic [1:0]     mode;           // Trap-Vector Base-Address Mode
    } mtvec_t;

    typedef struct packed {
        logic [31:3]    reserved;       // Reserved Bits
        logic           ir;             // Enable Instructions-Retired Counter
        logic           tm;             // Enable Timer Register
        logic           cy;             // Enable Cycle Counter
    } mcounteren_t;

    // --- Default values ------------------------------------------------------------------------------------------- //
    localparam logic [63:0] MVENDORID   = 64'h4254_4147;    // Bitaggregat - BTAG
    localparam logic [63:0] MARCHID     = 64'hbabe_0001;
    localparam logic [63:0] MIMPID      = 64'hcaff_0001;

    typedef enum logic [25:0] {         // RISC-V extensions
      EXT_A = 26'h00000001,             // Atomic
      EXT_B = 26'h00000002,             // Bit manipulation
      EXT_C = 26'h00000004,             // Compressed
      EXT_D = 26'h00000008,             // Double-precision floating-point
      EXT_E = 26'h00000010,             // Embedded
      EXT_F = 26'h00000020,             // Single-precision floating-point
      EXT_G = 26'h00000040,             // General-purpose registers
      EXT_H = 26'h00000080,             // Hypervisor
      EXT_I = 26'h00000100,             // Base integer
      EXT_J = 26'h00000200,             // Dynamically Translated Languages (Java)
      EXT_K = 26'h00000400,             // Custom
      EXT_L = 26'h00000800,             // 64-bit integer
      EXT_M = 26'h00001000,             // Integer multiplication and division
      EXT_N = 26'h00002000,             // User-level interrupts
      EXT_O = 26'h00004000,             // Custom
      EXT_P = 26'h00008000,             // Packed SIMD
      EXT_Q = 26'h00010000,             // Quad-precision floating-point
      EXT_R = 26'h00020000,             // Custom
      EXT_S = 26'h00040000,             // Supervisor mode
      EXT_T = 26'h00080000,             // Transactional memory
      EXT_U = 26'h00100000,             // User-level extensions
      EXT_V = 26'h00200000,             // Custom
      EXT_W = 26'h00400000,             // Custom
      EXT_X = 26'h00800000,             // Non-standard extension
      EXT_Y = 26'h01000000,             // Custom
      EXT_Z = 26'h02000000              // Custom
    } ext_t;

    typedef enum logic [5:0] {
        EXC_NONE  = 6'b000000,          // No exception occured
        EXC_IMA   = 6'b000001,          // Instruction address misaligned
        EXC_IAF   = 6'b000010,          // Instruction access fault
        EXC_II    = 6'b000011,          // Illegal instruction
        EXC_BP    = 6'b000100,          // Breakpoint
        EXC_LMA   = 6'b000101,          // Load address misaligned
        EXC_LAF   = 6'b000110,          // Load access fault
        EXC_SMA   = 6'b000111,          // Store address misaligned
        EXC_SAF   = 6'b001000,          // Store access fault
        EXC_ECU   = 6'b011100,          // Environment call from U-mode
        EXC_ECS   = 6'b011101,          // Environment call from S-mode
        EXC_ECM   = 6'b011110,          // Environment call from M-mode
        EXC_IPF   = 6'b111100,          // Instruction page fault
        EXC_LPF   = 6'b111101,          // Load page fault
        EXC_RSVD1 = 6'b111110,          // Reserved
        EXC_RSVD2 = 6'b111111           // Reserved
    } exc_t;

endpackage
`endif
