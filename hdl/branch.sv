// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Branch function unit for the SEC-V processor.
 * History  :
 *      v1.0    - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module branch #(
    parameter int XLEN = secv_pkg::XLEN,
    parameter int ILEN = secv_pkg::ILEN
) (
    // Control
    input   inst_t              inst_i,
    input   logic               ena_i,
    output  logic               rdy_o,
    output  logic               err_o,

    // Input operands
    input   logic [XLEN-1 : 0]  pc_i,
    input   logic [XLEN-1 : 0]  rs1_dat_i,
    input   logic [XLEN-1 : 0]  rs2_dat_i,
    input   imm_t               imm_i,

    // Output
    output  logic               branch_taken_o,
    output  logic [XLEN-1:0]    branch_target_o
);

    // Instruction decoding
    opcode_t opcode;
    funct3_t funct3;
    assign opcode = inst_i.r_type.opcode;
    assign funct3 = inst_i.r_type.funct3;

    // Branch taken computation
    logic branch_taken;
    logic err;
    always_comb begin
        branch_taken = 1'b0;
        err = 1'b0;
        case (funct3)
            FUNCT3_BRANCH_BEQ : branch_taken = (rs1_dat_i           ==  rs2_dat_i);
            FUNCT3_BRANCH_BNE : branch_taken = (rs1_dat_i           !=  rs2_dat_i);
            FUNCT3_BRANCH_BLT : branch_taken = ($signed(rs1_dat_i)  <   $signed(rs2_dat_i));
            FUNCT3_BRANCH_BGE : branch_taken = ($signed(rs1_dat_i)  >=  $signed(rs2_dat_i));
            FUNCT3_BRANCH_BLTU: branch_taken = (rs1_dat_i           <   rs2_dat_i);
            FUNCT3_BRANCH_BGEU: branch_taken = (rs1_dat_i           >=  rs2_dat_i);
            default: begin
                branch_taken = 1'b0;
                err = 1'b1;
            end
        endcase
    end

    // Outputs
    assign rdy_o = ena_i;
    assign err_o = err;
    assign branch_taken_o = branch_taken;
    assign branch_target_o = pc_i + sext32(imm_i);
endmodule
