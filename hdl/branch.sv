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
 * Todo
 *  [ ] Add unit tests
 *  [ ] Add formal verification
 *
 * History
 *  v1.0    - Initial version
 *  v1.1    - Reduce adder, simplify code
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module branch #(
    parameter int XLEN = secv_pkg::XLEN
) (
    input  funit_in_t  fu_i,
    output funit_out_t fu_o
);

    // Instruction decoding
    opcode_t opcode;
    funct3_t funct3;
    assign opcode = fu_i.inst.r_type.opcode;
    assign funct3 = fu_i.inst.r_type.funct3;

    // Input operands alias
    logic [XLEN-1:0] rs1_i, rs2_i, imm_i, pc_i;
    assign rs1_i = fu_i.rs1_dat;
    assign rs2_i = fu_i.rs2_dat;
    assign imm_i = fu_i.imm;
    assign pc_i  = fu_i.pc;

    // --- Target computation --------------------------------------------------------------------------------------- //
    logic [XLEN-1:0] pc, pc_ret;

    // Branch address
    always_comb begin
        pc = 'b0;

        // Relative branch target (b-type and j-type imm)
        if (opcode == OPCODE_BRANCH || opcode == OPCODE_JAL)
            pc = pc_i + imm_i;

        // Absolut branch target (i-type imm)
        else if (opcode == OPCODE_JALR)
            pc = rs1_i + imm_i;
    end

    // Return address
    assign pc_ret = fu_i.pc + 4;

    // --- Decision computation ------------------------------------------------------------------------------------- //
    logic pc_wb, rd_wb;
    logic err;
    always_comb begin
        // Initial values
        pc_wb = 1'b0;
        rd_wb = 1'b0;
        err   = 1'b0;

        if (opcode == OPCODE_BRANCH) begin
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
            pc_wb = 1'b1;
            rd_wb = 1'b1;
        end

        else if (opcode == OPCODE_JALR) begin
            if (funct3 == 'b0) begin
                pc_wb = 1'b1;
                rd_wb = 1'b1;
            end

            else
                err = 1'b1;
        end

        else
            err = 1'b1;
    end

    // Outputs
    always_comb begin
        fu_o = funit_out_default();

        if (fu_i.ena) begin
            fu_o.rdy    = 1'b1;
            fu_o.err    = err;

            // Branch target (= next pc)
            fu_o.pc     = pc;
            fu_o.pc_wb  = pc_wb;

            // Return address (= destination register)
            fu_o.rd_dat = pc_ret;
            fu_o.rd_wb  = rd_wb;
        end
    end
endmodule
