// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Move function unit for the SEC-V processor.
 *
 * Opcodes
 *  simple loads: LUI, AUIPC
 *
 * History
 *  v1.0    - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module branch #(
    parameter int XLEN = secv_pkg::XLEN,
    parameter int ILEN = secv_pkg::ILEN
) (
    // Control
    input   inst_t              inst_i,         // Instruction
    input   logic               ena_i,          // Enable unit
    output  logic               rdy_o,          // Unit is ready
    output  logic               err_o,          // Error occured

    // Input operands
    input   logic [XLEN-1 : 0]  pc_i,           // Current PC
    input   imm_t               imm_i,          // Decoded immediate (I-, B- or J-Type)

    // Output
    output  logic [XLEN-1:0]    rd_o,           // Link register data               rd <= dat (?)
    output  logic               rd_wb_o         // Link register write back         rd <= dat (!)
);

    // Instruction decoding
    opcode_t opcode;
    funct3_t funct3;
    assign opcode = inst_i.r_type.opcode;
    assign funct3 = inst_i.r_type.funct3;

    // Branch computation
    logic [XLEN-1:0] rd;
    logic rd_wb;
    logic err;

    always_comb begin
        // Initial values
        rd    =  'b0;
        rd_wb = 1'b0;
        err   = 1'b0;

        if (opcode == OPCODE_LUI) begin
        end

        else if (opcode == OPCODE_AUIPC) begin
        end
    end

    // Output
    assign rdy_o = ena_i;
    assign err_o = err;
    assign rd_o    = rd;
    assign rd_wb_o = rd_wb;

endmodule