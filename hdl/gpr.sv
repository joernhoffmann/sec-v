// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : General purpose register file
 *
 * Todo
 *  [ ] Add unit tests
 *  [ ] Add formal verification
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

    // Source register 1
    input   regadr_t            rs1_adr_i,
    output  logic [XLEN-1:0]    rs1_dat_o,

    // Source register 2
    input   regadr_t            rs2_adr_i,
    output  logic [XLEN-1:0]    rs2_dat_o,

    // Destination register
    input   regadr_t            rd_adr_i,
    input   logic [XLEN-1:0]    rd_dat_i,
    input   logic               rd_wb_i
);

    // Register array
    logic [XLEN-1 : 0] regfile [REG_COUNT];

    // Write logic
    always_ff @(posedge clk_i) begin
        if (rst_i)
            for (int idx=0; idx < REG_COUNT; idx++)
                regfile[idx] <= 'b0;

        else if (rd_adr_i != 'b0 && rd_wb_i)
            regfile[rd_adr_i] <= rd_dat_i;
    end

    // Read logic
    assign rs1_dat_o = (rs1_adr_i == 'b0) ? 'b0 : regfile[rs1_adr_i];
    assign rs2_dat_o = (rs2_adr_i == 'b0) ? 'b0 : regfile[rs2_adr_i];
endmodule
