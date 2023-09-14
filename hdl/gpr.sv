// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Generap purpose register file
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module gpr #(
    parameter int XLEN = secv_pkg::XLEN,
    parameter int REGS = secv_pkg::REG_COUNT
) (
    input   logic clk_i,
    input   logic rst_i,

    // Register source 1
    input   regadr_t            rs1_i,
    output  logic [XLEN-1:0]    rs1_dat_o,

    // Register source 2
    input   regadr_t            rs2_i,
    output  logic [XLEN-1:0]    rs2_dat_o,

    // Register destination
    input   regadr_t            rd_i,
    input   logic [XLEN-1:0]    rd_dat_i
);

logic [XLEN-1 : 0] regfile [32];
logic [XLEN-1 : 0] regfile_next [32];
logic [XLEN-1 : 0] rs1_dat, rs2_dat, rd_dat;

always_ff @(posedge clk_i) begin
    if (rst_i)
        regfile <= '{default: 0};

    else
        regfile <= regfile_next;
end

endmodule
