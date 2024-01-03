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

    input   funit_in_t      fu_i,
    output  funit_out_t     fu_o,

    input   funct3_csr_t    funct_i,
    input   logic           rd_zero_i,      // rd is x0
    input   logic           rs1_zero_i      // rs1 is x0 / uimm is 0
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

    // Trap
    logic mret;
    logic [XLEN-1:0] trap_pc, trap_adr, trap_vec;

    // Interrupts
    logic irq, irq_ena;
    irq_cause_t irq_cause;
    irq_vec_t irq_pend, irq_ena_vec;

    // Exeptions
    logic ex;
    ex_cause_t ex_cause;

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
        .trap_pc_i      (trap_pc),
        .trap_adr_i     (trap_adr),
        .trap_vec_o     (trap_vec),
        .mret_i         (mret),

        // Interrupts
        .irq_i          (irq),
        .irq_cause_i    (irq_cause),
        .irq_pend_i     (irq_pend),
        .irq_ena_o      (irq_ena),
        .irq_ena_vec_o  (irq_ena_vec),

        // Exceptions
        .ex_i           (ex),
        .ex_cause_i     (ex_cause)
    );


    always_comb begin
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

                default: begin
                    fu_o.err = 1'b1;
                end
            endcase
        end
    end
endmodule
