// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Control and status register unit
 *
 * Opcodes
 *  - CSRRW,  CSRRS,  CSRRC
 *  - CSRRWI, CSRRSI, CSRRCI
 *
 * Todo
 *  [ ] Add basic (machine mode) functionality
 *  [ ] Add timer
 *
 * History
 *  v1.0    - Initial version
 */

`include "secv_pkg.svh"
`include "csr_pkg.svh"
import secv_pkg::*;
import csr_pkg::*;

module csr #(
    parameter int XLEN = secv_pkg::XLEN
) (
    input   logic clk_i,
    input   logic rst_i,

    // FU interface
    input   funit_in_t          fu_i,           // Function unit input
    output  funit_out_t         fu_o,           // Function unit output

    // Control signals
    input   funct3_csr_t        funct_i,        // Function to perform
    input   logic               rd_zero_i,      // Destination register is register x0
    input   logic               rs1_zero_i,     // Source register 1 is register x0 or uimm is 0

    // Trap signals
    input   logic [XLEN-1:0]    trap_pc_i,      // Trapping PC
    input   logic [XLEN-1:0]    trap_adr_i,     // Trapping memory access address
    output  logic [XLEN-1:0]    trap_vec_o,     // Trap vector to jump to
    input   logic               mret_i,         // Mret instruction issued

    // Exceptions
    input   logic               ex_i,           // Exception occured
    input   ex_cause_t          ex_cause_i      // Exception cause

    // Interrupts
);
    // Alias signals
    logic [XLEN-1:0] src1, src2;
    assign src1 = fu_i.src1;
    assign src2 = fu_i.src2;

    // CSR access
    logic csr_we;
    logic [XLEN-1:0] csr_dat_i, csr_dat_o;
    logic [11:0] csr_adr;
    priv_mode_t priv_prev;

    // Interrupts
    logic intr, intr_ena;
    intr_cause_t intr_cause;
    ivec_t intr_pend, intr_ena_vec;

    /*
     * CSR Register
     */
    csr_regs #(
        .HARTS(1)
    ) csr_regs0 (
        .clk_i  (clk_i),
        .rst_i  (rst_i),

        // Generic
        .hartid_i       (0),
        .priv_i         (PRIV_MODE_MACHINE),
        .priv_prev_o    (priv_prev),

        // CSR access
        .csr_adr_i      (csr_adr),
        .csr_we_i       (csr_we),
        .csr_dat_i      (csr_dat_i),
        .csr_dat_o      (csr_dat_o),

        // Traps
        .trap_pc_i      (trap_pc_i),
        .trap_adr_i     (trap_adr_i),
        .trap_vec_o     (trap_vec_o),
        .mret_i         (mret_i),

        // Exceptions
        .ex_i           (ex_i),
        .ex_cause_i     (ex_cause_i),

        // Interrupts
        .intr_i          (intr),
        .intr_cause_i    (intr_cause),
        .intr_pend_i     (intr_pend),
        .intr_ena_o      (intr_ena),
        .intr_ena_vec_o  (intr_ena_vec)
    );


    always_comb begin : csr_access
        fu_o = funit_out_default();
        csr_adr     = '0;
        csr_we      = '0;
        csr_dat_i   = '0;

        if (fu_i.ena) begin
            fu_o.rdy = 1'b1;
            csr_adr  = src2[11:0];

            case (funct_i)
                FUNCT3_CSR_RW,
                FUNCT3_CSR_RWI : begin
                    fu_o.res = csr_dat_o;

                    csr_dat_i = src1;
                    csr_we    = 1'b1;
                end

                FUNCT3_CSR_RS,
                FUNCT3_CSR_RSI : begin
                    fu_o.res = csr_dat_o;

                    // Only write CSR if rs1 != 0
                    csr_dat_i = csr_dat_o | src1;
                    csr_we    = 1'b1 & !rs1_zero_i;
                end

                FUNCT3_CSR_RC,
                FUNCT3_CSR_RCI: begin
                    fu_o.res = csr_dat_o;

                    // Only write CSR if rs1 != 0
                    csr_dat_i = csr_dat_o & ~src1;
                    csr_we    = 1'b1 & !rs1_zero_i;
                end

                default:
                    fu_o.err = ERROR_OP_INVALID;
            endcase
        end
    end
endmodule
