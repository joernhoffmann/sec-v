// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Instruction decoder for the SEC-V processor.
 *
 * Todo
 *  [ ] Add muxer control for ex input / output operands
 *  [ ] Remove unnecessary funits
 *  [ ] Reduce adder, decoder etc. by reusing alu.
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
    output regadr_t     rs1_adr_o,  // Source register 1 address
    output regadr_t     rs2_adr_o,  // Source register 2 address
    output regadr_t     rd_adr_o,   // Dest.  register address
    output imm_sel_t    imm_sel_o,  // Immediate operand type

    // Muxer
    output  funit_t     funit_o,    // Function unit
    output  src1_sel_t  src1_sel_o,   // Source 1 selection
    output  src2_sel_t  src2_sel_o,   // Source 2 selection
    output  rd_sel_t    rd_sel_o,   // Dest. register selection
    output  pc_sel_t    pc_sel_o,   // PC register selector

    // Error codes
    output  logic       err_o       // Decoding error, invalid opcode
);

    // Opcode
    opcode_t opcode;
    funct3_t funct3;
    funct7_t funct7;
    assign opcode = decode_opcode(inst_i);
    assign funct3 = inst_i.r_type.funct3;
    assign funct7 = inst_i.r_type.funct7;

    // Function unit, operands and destination selection
    funit_t    funit;
    src1_sel_t src1_sel;
    src2_sel_t src2_sel;
    imm_sel_t  imm_sel;
    rd_sel_t   rd_sel;
    pc_sel_t   pc_sel;
    logic      err;

    always_comb begin : decode_op
        funit     = FUNIT_NONE;
        src1_sel  = SRC1_SEL_0;
        src2_sel  = SRC2_SEL_0;
        imm_sel   = IMM_SEL_0;
        rd_sel    = RD_SEL_NONE;
        pc_sel    = PC_SEL_NXTPC;
        err       = 1'b0;

        unique case (opcode)
            OPCODE_LUI: begin
                funit       = FUNIT_NONE;
                imm_sel     = IMM_SEL_U;
                rd_sel      = RD_SEL_IMM;
            end

            OPCODE_AUIPC: begin
                funit       = FUNIT_ALU;
                src1_sel    = SRC1_SEL_PC;
                src2_sel    = SRC2_SEL_IMM;
                imm_sel     = IMM_SEL_U;
                rd_sel      = RD_SEL_FUNIT;
            end

            OPCODE_JAL: begin
                funit       = FUNIT_ALU;
                src1_sel    = SRC1_SEL_PC;
                src2_sel    = SRC2_SEL_IMM;
                imm_sel     = IMM_SEL_J;
                rd_sel      = RD_SEL_NXTPC;
            end

            OPCODE_JALR: begin
                funit       = FUNIT_ALU;
                src1_sel    = SRC1_SEL_RS1;
                src2_sel    = SRC2_SEL_IMM;
                imm_sel     = IMM_SEL_I;
                rd_sel      = RD_SEL_NXTPC;
            end

            OPCODE_BRANCH: begin
                funit       = FUNIT_ALU;
                src1_sel    = SRC1_SEL_PC;
                src2_sel    = SRC2_SEL_IMM;
                imm_sel     = IMM_SEL_B;
                pc_sel      = PC_SEL_BRANCH;
            end

            OPCODE_LOAD: begin
                funit       = FUNIT_MEM;
                src1_sel    = SRC1_SEL_RS1;
                src2_sel    = SRC2_SEL_IMM;
                imm_sel     = IMM_SEL_I;
                rd_sel      = RD_SEL_FUNIT;
            end

            OPCODE_STORE: begin
                funit       = FUNIT_MEM;
                src1_sel    = SRC1_SEL_RS1;
                src2_sel    = SRC2_SEL_IMM;
                imm_sel     = IMM_SEL_S;
                rd_sel      = RD_SEL_FUNIT;
            end

            OPCODE_OP, OPCODE_OP_32: begin
                funit       = FUNIT_ALU;
                src1_sel    = SRC1_SEL_RS1;
                src2_sel    = SRC2_SEL_RS2;
                rd_sel      = RD_SEL_FUNIT;
            end

            OPCODE_OP_IMM, OPCODE_OP_IMM_32: begin
                funit       = FUNIT_ALU;
                src1_sel    = SRC1_SEL_RS1;
                src2_sel    = SRC2_SEL_IMM;
                imm_sel     = IMM_SEL_I;
                rd_sel      = RD_SEL_FUNIT;
            end

            default:
                err = 1'b1;
        endcase
    end



    // --- Output --------------------------------------------------------------------------------------------------- //
    // Opcode
    assign opcode_o = opcode;
    assign funct3_o = funct3;
    assign funct7_o = funct7;

    // Operands
    assign rs1_adr_o = inst_i.r_type.rs1;
    assign rs2_adr_o = inst_i.r_type.rs2;
    assign rd_adr_o  = inst_i.r_type.rd;
    assign imm_sel_o = imm_sel;

    // Function unit
    assign funit_o    = funit;
    assign src1_sel_o = src1_sel;
    assign src2_sel_o = src2_sel;
    assign rd_sel_o   = rd_sel;
    assign pc_sel_o   = pc_sel;

    // Errors
    assign err_o = err;
endmodule
