// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Branch function unit for the SEC-V processor.
 *
 * Notes
 *  - The immediate value imm_i must be proper decoded (I-, B- or J-type) in advance.
 *
 * Opcodes
 *  - Branch : BEQ, BNE, BLT, BGE, BLTU, BGEU
 *  - Jump   : JAL and JALR
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
    input   logic [XLEN-1 : 0]  rs1_i,          // Source register 1 data
    input   logic [XLEN-1 : 0]  rs2_i,          // Soruce register 2 data
    input   imm_t               imm_i,          // Decoded immediate (I-, B- or J-Type)

    // Output
    output  logic [XLEN-1:0]    pc_o,           // NextPC: branch target address    PC <= target (?)
    output  logic               pc_wb_o,        // NextPC write back: take branch   PC <= target (!)
    output  logic [XLEN-1:0]    rd_o,           // Link register data               rd <= dat (?)
    output  logic               rd_wb_o         // Link register write back         rd <= dat (!)
);

    // Instruction decoding
    opcode_t opcode;
    funct3_t funct3;
    assign opcode = inst_i.r_type.opcode;
    assign funct3 = inst_i.r_type.funct3;

    // Internal signals
    logic [XLEN-1:0] pc, pc_ret, pc_rel, pc_abs;
    logic [XLEN-1:0] rd;
    logic pc_wb, rd_wb;
    logic err;

    // Address computation
    assign pc_ret = pc_i + 4;               // Calculate return address for calls (jump and link)
    assign pc_rel = pc_i + sext32(imm_i);   // Calculate relative branch target (i-, j- or b-type imm)
    assign pc_abs = rs1_i + sext32(imm_i);  // Calculate absolut branch target

    // Branch computation
    always_comb begin
        // Initial values
        pc    =  'b0;
        rd    =  'b0;
        pc_wb = 1'b0;
        rd_wb = 1'b0;
        err   = 1'b0;

        if (opcode == OPCODE_BRANCH) begin
            pc = pc_rel;

            case (funct3)
                FUNCT3_BRANCH_BEQ : pc_wb = (rs1_i          ==  rs2_i);
                FUNCT3_BRANCH_BNE : pc_wb = (rs1_i          !=  rs2_i);
                FUNCT3_BRANCH_BLT : pc_wb = ($signed(rs1_i) <   $signed(rs2_i));
                FUNCT3_BRANCH_BGE : pc_wb = ($signed(rs1_i) >=  $signed(rs2_i));
                FUNCT3_BRANCH_BLTU: pc_wb = (rs1_i          <   rs2_i);
                FUNCT3_BRANCH_BGEU: pc_wb = (rs1_i          >=  rs2_i);
                default: begin
                    pc_wb = 1'b0;
                    err   = 1'b1;
                end
            endcase
        end

        else if (opcode == OPCODE_JAL) begin
            pc = pc_rel;
            rd = pc_ret;

            pc_wb = 1'b1;
            rd_wb = 1'b1;
        end

        else if (opcode == OPCODE_JALR) begin
            if (funct3 == 'b0) begin
                pc = pc_abs;
                rd = pc_ret;

                pc_wb = 1'b1;
                rd_wb = 1'b1;
            end

            else
                err = 1'b1;
        end
    end

    // Outputs
    assign rdy_o    = ena_i;
    assign err_o    = err;
    assign pc_o     = pc;
    assign rd_o     = rd;
    assign pc_wb_o  = pc_wb;
    assign rd_wb_o  = rd_wb;
endmodule
