// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : General purpose register file
 *
 * History
 *  v1.0    - Initial version
 */
`include "secv_pkg.svh"
import secv_pkg::*;

module gpr #(
    parameter int XLEN = secv_pkg::XLEN
) (
    input   logic clk_i,
    input   logic rst_i,

    // Register operands
    input   regadr_t            rs1_i,
    output  logic [XLEN-1:0]    rs1_dat_o,

    input   regadr_t            rs2_i,
    output  logic [XLEN-1:0]    rs2_dat_o,

    input   regadr_t            rd_i,
    input   logic [XLEN-1:0]    rd_dat_i,
    input   logic               rd_ena_i
);

logic [XLEN-1 : 0] regfile [REG_COUNT];
logic [XLEN-1 : 0] regfile_next [REG_COUNT];

always_ff @(posedge clk_i) begin
    if (rst_i)
        regfile <= '{default: 0};
    else
        regfile <= regfile_next;
end

always_comb begin
    regfile_next = regfile;

    // Write destination register if requested and not zero
    if (rd_ena_i && rd_i != 'b0)
        regfile_next[rd_i] = rd_dat_i;
end

// Outputs
assign rs1_dat_o = (rs1_i == 'b0) ? 'b0 : regfile[rs1_i];
assign rs2_dat_o = (rs2_i == 'b0) ? 'b0 : regfile[rs2_i];

endmodule
