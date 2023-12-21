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
   // --- Addresses ------------------------------------------------------------------------------------------------- //
    typedef enum logic [11:0] {
        // User Mode
        CSR_ADDR_USTATUS     = 12'h000,     // User Status Register
        CSR_ADDR_UIE         = 12'h004,     // User Interrupt Enable Register
        CSR_ADDR_UTVEC       = 12'h005,     // User Trap-Vector Base-Address Register

        // User Trap Handling
        CSR_ADDR_USCRATCH    = 12'h040,     // User Scratch Register
        CSR_ADDR_UEPC        = 12'h041,     // User Exception Program Counter
        CSR_ADDR_UCAUSE      = 12'h042,     // User Cause Register
        CSR_ADDR_UTVAL       = 12'h043,     // User Trap Value
        CSR_ADDR_UIP         = 12'h044,     // User Interrupt Pending

        // Machine Status and Control
        CSR_ADDR_MSTATUS     = 12'h300,     // Machine Status
        CSR_ADDR_MISA        = 12'h301,     // ISA and Extensions
        CSR_ADDR_MIE         = 12'h304,     // Machine Interrupt Enable
        CSR_ADDR_MTVEC       = 12'h305,     // Machine Trap-Vector Base-Address
        CSR_ADDR_MCOUNTEREN  = 12'h306,     // Machine Counter Enable

        // Machine Trap Handling
        CSR_ADDR_MSCRATCH    = 12'h340,     // Machine Scratch
        CSR_ADDR_MEPC        = 12'h341,     // Machine Exception Program Counter
        CSR_ADDR_MCAUSE      = 12'h342,     // Machine Cause
        CSR_ADDR_MTVAL       = 12'h343,     // Machine Trap Value (WARL)
        CSR_ADDR_MIP         = 12'h344,     // Machine Interrupt Pending

        // Machine Memory Protection
        CSR_ADDR_PMPCFG0     = 12'h3A0,     // Configuration for PMP entries 0-3
        CSR_ADDR_PMPCFG1     = 12'h3A1,     // Configuration for PMP entries 4-7
        CSR_ADDR_PMPADDR0    = 12'h3B0,
        CSR_ADDR_PMPADDR1    = 12'h3B1,
        CSR_ADDR_PMPADDR2    = 12'h3B2,
        CSR_ADDR_PMPADDR3    = 12'h3B3,
        CSR_ADDR_PMPADDR4    = 12'h3B4,
        CSR_ADDR_PMPADDR5    = 12'h3B5,
        CSR_ADDR_PMPADDR6    = 12'h3B6,
        CSR_ADDR_PMPADDR7    = 12'h3B7,

        // Machine Timer Registers
        CSR_ADDR_MCYCLE      = 12'hB00,     // Machine Cycle Counter
        CSR_ADDR_MINSTRET    = 12'hB02,     // Machine Instructions-Retired Counter

        // Machine Information Registers
        CSR_ADDR_MVENDORID   = 12'hF11,     // Vendor ID
        CSR_ADDR_MARCHID     = 12'hF12,     // Architecture ID
        CSR_ADDR_MIMPID      = 12'hF13,     // Implementation ID
        CSR_ADDR_MHARTID     = 12'hF14      // Hardware Thread ID
    } csr_addr_t;

    // --- Registers ------------------------------------------------------------------------------------------------ //
    /*
     * Machine Status
     */
    typedef struct packed {
        logic [63:13]   reserved0;
        logic [1:0]     mpp;                // Machine Previous Privilege
        logic [2:0]     reserved1;
        logic           mpie;               // Machine Previous Interrupt Enable
        logic [2:0]     reserved2;
        logic           mie;                // Machine Interrupt Enable
        logic [2:0]     reserved3;
    } mstatus_t;

    /*
     * Machine ISA register
     */
    typedef struct packed {
        logic [1:0]     mxl;                // Machine x-length (1 = RV32, 2 = RV64, 3 = RV128)
        logic [35:0]    reserved;
        logic [25:0]    extensions;         // Extensions (bit position corresponds to letter, e.g., bit 0 for "A")
    } misa_t;

    /*
     * Interrupt Enable  (mie, sie, ...)
     * Interrupt Pending (mip, sip, ...)
     */
    typedef struct packed {
        logic [63:12]   reserved;
        logic           mei;                // Machine External Interrupt (Enable / Pending)
        logic [2:0]     reserved1;
        logic           mti;                // Machine Timer Interrupt (Enable / Pending)
        logic [2:0]     reserved2;
        logic           msi;                // Machine Software Interrupt (Enable / Pending)
        logic [2:0]     reserved3;
    } mintr_t;

    /*
     * Interrupt Vector
     */
    typedef struct packed {
        logic           mei;               // Machine External Interrupt
        logic           mti;               // Machine Timer Interrupt Enable
        logic           msi;               // Machine Softwarte Interrupt Enable
    } intr_vec_t;

    /*
     * Machine Trap Vector
     */
    typedef struct packed {
        logic [63:2]    base;               // Base address of the trap vector
        logic [1:0]     mode;               // Trap-Vector Base-Address Mode
    } mtvec_t;

    /*
     * Machine Counter Enable
     */
    typedef struct packed {
        logic [31:3]    reserved;
        logic           ir;                 // Enable Instructions-Retired Counter
        logic           tm;                 // Enable Timer Register
        logic           cy;                 // Enable Cycle Counter
    } mcounteren_t;

    /*
     * Machine Trap Cause
     */
    typedef struct packed {
        logic           intr;               // Interrupt occured
        logic [62: 6]   unused;
        logic [ 5: 0]   cause;              // Trap cause
    } mcause_t;

    // --- Default values ------------------------------------------------------------------------------------------- //
    localparam logic [63:0] MVENDORID   = 64'h4254_4147;    // Bitaggregat - BTAG
    localparam logic [63:0] MARCHID     = 64'hbabe_0001;
    localparam logic [63:0] MIMPID      = 64'hcaff_0001;

    /*
     * Machine Status Privileges
     */
    typedef enum logic [1:0] {
        MSTATUS_PRIV_USER        = 2'b00,
        MSTATUS_PRIV_SUPERVISOR  = 2'b01,
        MSTATUS_PRIV_RESERVED    = 2'b10,
        MSTATUS_PRIV_MACHINE     = 2'b11
    } mstatus_priv_t;

    /*
     * Machine X-Length field
     */
    typedef enum logic [1:0] {
        MISA_MXL_RES    = 2'b00,
        MISA_MXL_RV32   = 2'b01,
        MISA_MXL_RV64   = 2'b10,
        MISA_MXL_RV128  = 2'b11
    } misa_mxl_t;

    /*
     * ISA extensions
     */
    typedef enum logic [25:0] {
        MISA_EXT_A = 26'h00000001,      // Atomic
        MISA_EXT_B = 26'h00000002,      // Bit manipulation
        MISA_EXT_C = 26'h00000004,      // Compressed
        MISA_EXT_D = 26'h00000008,      // Double-precision floating-point
        MISA_EXT_E = 26'h00000010,      // Embedded
        MISA_EXT_F = 26'h00000020,      // Single-precision floating-point
        MISA_EXT_G = 26'h00000040,      // General-purpose registers
        MISA_EXT_H = 26'h00000080,      // Hypervisor
        MISA_EXT_I = 26'h00000100,      // Base integer
        MISA_EXT_J = 26'h00000200,      // Dynamically Translated Languages (Java)
        MISA_EXT_K = 26'h00000400,      // Custom
        MISA_EXT_L = 26'h00000800,      // 64-bit integer
        MISA_EXT_M = 26'h00001000,      // Integer multiplication and division
        MISA_EXT_N = 26'h00002000,      // User-level interrupts
        MISA_EXT_O = 26'h00004000,      // Custom
        MISA_EXT_P = 26'h00008000,      // Packed SIMD
        MISA_EXT_Q = 26'h00010000,      // Quad-precision floating-point
        MISA_EXT_R = 26'h00020000,      // Custom
        MISA_EXT_S = 26'h00040000,      // Supervisor mode
        MISA_EXT_T = 26'h00080000,      // Transactional memory
        MISA_EXT_U = 26'h00100000,      // User-level extensions
        MISA_EXT_V = 26'h00200000,      // Custom
        MISA_EXT_W = 26'h00400000,      // Custom
        MISA_EXT_X = 26'h00800000,      // Non-standard extension
        MISA_EXT_Y = 26'h01000000,      // Custom
        MISA_EXT_Z = 26'h02000000       // Custom
    } misa_ext_t;

    /*
     * Exception cause (0-prefix in mcause)
     */
    typedef enum logic [5:0] {
        EXCEPT_CAUSE_INST_MISALIGNED            = 0,    // Instruction address misaligned
        EXCEPT_CAUSE_INST_ACCESS_FAULT          = 1,    // Instruction access fault
        EXCEPT_CAUSE_INST_ILLEGAL               = 2,    // Illegal instruction
        EXCEPT_CAUSE_LOAD_ADDRESS_MISALIGNED    = 4,    // Load address misaligned
        EXCEPT_CAUSE_LOAD_ACCESS_FAULT          = 5,    // Load access fault
        EXCEPT_CAUSE_STORE_ADDRESS_MISALIGNED   = 6,    // Store / AMO address misaligned
        EXCEPT_CAUSE_STORE_ACCESS_FAULT         = 7,    // Store / AMO access fault
        EXCEPT_CAUSE_ENV_CALL_U                 = 8,    // Environment call from U-mode
        EXCEPT_CAUSE_ENV_CALL_M                 = 11,   // Environment call from M-mode
        // 16 .. 23 Reserved
        // 24 .. 31 Custom use
        EXCEPT_CAUSE_MTAG_INVLD                 = 24    // Memory Tag Invalid (needed? cf. LD_ or ST_ACCESS_FAULT)
    } except_cause_t;

    /*
     * Interrupt cause (1-prefix in mcause)
     */
    typedef enum logic [5:0] {
        INTR_CAUSE_MSI                  = 3,    // Machine software interrupt
        INTR_CAUSE_MTI                  = 7,    // Machine timer interrupt
        INTR_CAUSE_MEI                  = 11    // Machine external interrupt
        // 12 .. 15 Reserved
        //    >= 16 Platform use
    } intr_cause_t;

endpackage
`endif
