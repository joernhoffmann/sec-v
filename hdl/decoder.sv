// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Instruction decoder for the SEC-V processor.
 *
 * Todo
 *  [ ] Move alu decoder to ALU.
 *  [ ] Improve decoder to only output rs1, rs2 etc. regarding to instruction type
 *
 * History
 *  v1.0    - Initial version
 */
 `include "secv_pkg.svh"
import secv_pkg::*;

module decoder (
    input   inst_t      inst_i,     // Instruction

    // Opcode
    output opcode_t     opcode_o,   // Opcode
    output funct3_t     funct3_o,   // Funct3 field
    output funct7_t     funct7_o,   // Funct7 field

    // Operands
    output regadr_t     rs1_adr_o,  // Source register 1
    output regadr_t     rs2_adr_o,  // Source register 2
    output regadr_t     rd_adr_o,   // Destination register
    output imm_t        imm_o,      // Immediate operand
    output logic        imm_use_o,  // Operation uses immediate

    // Function unit
    output  funit_t     funit_o     // Selected function unit
);

    // --- Opcode --------------------------------------------------------------------------------------------------- //
    opcode_t opcode;
    funct3_t funct3;
    funct7_t funct7;
    assign opcode = decode_opcode(inst_i);
    assign funct3 = inst_i.r_type.funct3;
    assign funct7 = inst_i.r_type.funct7;

    // --- Immediate ------------------------------------------------------------------------------------------------ //
    logic imm_use;
    imm_t imm, imm_i, imm_s, imm_b, imm_u, imm_j;
    assign imm_i = decode_imm_i(inst_i);
    assign imm_s = decode_imm_s(inst_i);
    assign imm_b = decode_imm_b(inst_i);
    assign imm_u = decode_imm_u(inst_i);
    assign imm_j = decode_imm_j(inst_i);

    always_comb begin : decode_imm
        unique case (opcode)
            OPCODE_LUI, OPCODE_AUIPC : begin
                imm = imm_u;
                imm_use = 1'b1;
            end

            OPCODE_JAL: begin
                imm = imm_j;
                imm_use = 1'b1;
            end

            OPCODE_BRANCH: begin
                imm = imm_b;
                imm_use = 1'b1;
            end

            OPCODE_STORE: begin
                imm = imm_s;
                imm_use = 1'b1;
            end

            OPCODE_JALR, OPCODE_LOAD, OPCODE_OP_IMM, OPCODE_OP_IMM_32: begin
                imm = imm_i;
                imm_use = 1'b1;
            end

            default: begin
                imm = 'b0;
                imm_use = 1'b0;
            end
        endcase
    end

    // --- Function unit -------------------------------------------------------------------------------------------- //
    funit_t funit;

    always_comb begin : decode_funit
        unique case (opcode_o)
            OPCODE_LUI, OPCODE_AUIPC:
                funit = FUNIT_MOV;

            OPCODE_JAL, OPCODE_JALR, OPCODE_BRANCH:
                funit = FUNIT_BRANCH;

            OPCODE_LOAD, OPCODE_STORE, OPCODE_MISC_MEM:
                funit = FUNIT_MEM;

            OPCODE_OP, OPCODE_OP_IMM, OPCODE_OP_32, OPCODE_OP_IMM_32:
                funit = FUNIT_ALU;

            default:
                funit = FUNIT_NONE;
        endcase
    end

    // --- Output --------------------------------------------------------------------------------------------------- //
    // Opcode
    assign opcode_o = opcode;
    assign funct3_o = funct3;
    assign funct7_o = funct7;

    // Operands
    assign rs1_adr_o  = inst_i.r_type.rs1;
    assign rs2_adr_o  = inst_i.r_type.rs2;
    assign rd_adr_o   = inst_i.r_type.rd;
    assign imm_o      = imm;
    assign imm_use_o  = imm_use;

    // Function unit
    assign funit_o  = funit;
endmodule
