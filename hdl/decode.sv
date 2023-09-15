// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Instruction decoder of the processor
 */
 `include "secv_pkg.svh"
import secv_pkg::*;

module decode
(
    input   inst_t      inst_i,     // instruction

    // Opcode fields
    output opcode_t     opcode_o,   // opcode
    output funct3_t     funct3_o,   // funct3 field
    output funct7_t     funct7_o,   // funct7 field

    // Operands
    output regadr_t     rd_o,       // destination register
    output regadr_t     rs1_o,      // source register 1
    output regadr_t     rs2_o,      // source register 2
    output imm_t        imm_o,      // immediate operand

    // Function units
    output  funit_t     funit_o,    // function unit
    output alu_op_t     alu_op_o,   // ALU operation
    output logic        alu_32_o,   // ALU uses 32-bit operands
    output logic        alu_imm_o   // ALU uses immediate operand
);

    // Decode opcode
    opcode_t opcode;
    funct3_t funct3;
    funct7_t funct7;
    assign opcode = decode_opcode(inst_i);
    assign funct3 = inst_i.r_type.funct3;
    assign funct7 = inst_i.r_type.funct7;

    // Decode immediate
    imm_t imm, imm_i, imm_s, imm_b, imm_u, imm_j;
    assign imm_i = decode_imm_i(inst_i);
    assign imm_s = decode_imm_s(inst_i);
    assign imm_b = decode_imm_b(inst_i);
    assign imm_u = decode_imm_u(inst_i);
    assign imm_j = decode_imm_j(inst_i);

    always_comb begin : decode_imm
        case (opcode)
            OPCODE_LUI, OPCODE_AUIPC :
                imm = imm_u;

            OPCODE_JAL:
                imm = imm_j;

            OPCODE_BRANCH:
                imm = imm_b;

            OPCODE_STORE:
                imm = imm_s;

            OPCODE_JALR, OPCODE_LOAD, OPCODE_OP_IMM, OPCODE_OP_IMM_32:
                imm = imm_i;

            default:
                imm = 0;
        endcase
    end

    // Decode function unit
    funit_t funit;
    always_comb begin : decode_funit
        case (opcode_o)
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

    // Decode ALU operations
    alu_op_t alu_op;
    logic op_reg_64, op_reg_32;
    logic op_imm_64, op_imm_32;
    assign op_reg_64 = (opcode == OPCODE_OP);
    assign op_reg_32 = (opcode == OPCODE_OP_32);
    assign op_imm_64 = (opcode == OPCODE_OP_IMM);
    assign op_imm_32 = (opcode == OPCODE_OP_IMM_32);

    always_comb begin : decode_alu
        alu_op = ALU_OP_NONE;

        // Decode R- and I-type ALU operations
        if (op_reg_32 || op_imm_32 || op_reg_64 || op_imm_64) begin
            case(funct3)
                FUNCT3_ALU_AND:
                    alu_op = ALU_OP_AND;

                FUNCT3_ALU_OR:
                    alu_op = ALU_OP_OR;

                FUNCT3_ALU_XOR:
                    alu_op = ALU_OP_XOR;

                FUNCT3_ALU_ADD:
                    if (op_reg_32)
                        case (funct7)
                            FUNCT7_00h: alu_op = ALU_OP_ADDW;
                            FUNCT7_20h: alu_op = ALU_OP_SUBW;
                            default   : alu_op = ALU_OP_NONE;
                        endcase

                    else if(op_imm_32)
                        alu_op = ALU_OP_ADDW;

                    else if (op_reg_64)
                        case (funct7)
                            FUNCT7_00h: alu_op = ALU_OP_ADD;
                            FUNCT7_20h: alu_op = ALU_OP_SUB;
                            default   : alu_op = ALU_OP_NONE;
                        endcase

                    else if (op_imm_64)
                        alu_op = ALU_OP_ADD;

                FUNCT3_ALU_SLL:
                    alu_op = ALU_OP_SLLW;

                FUNCT3_ALU_SRL:
                    if (op_reg_32 || op_imm_32)
                        case (funct7)
                            FUNCT7_00h: alu_op = ALU_OP_SRLW;
                            FUNCT7_20h: alu_op = ALU_OP_SRAW;
                            default   : alu_op = ALU_OP_NONE;
                        endcase

                    else if (op_reg_64 || op_imm_64)
                        case (funct7)
                            FUNCT7_00h: alu_op = ALU_OP_SRL;
                            FUNCT7_20h: alu_op = ALU_OP_SRA;
                            default   : alu_op = ALU_OP_NONE;
                        endcase

                FUNCT3_ALU_SLT:
                    alu_op = ALU_OP_SLT;

                FUNCT3_ALU_SLTU:
                    alu_op = ALU_OP_SLTU;

                default:
                    ;
            endcase
        end
    end

    /* --- Output -------------------------------------------------------------------------------------------------- */
    // Opcode
    assign opcode_o = opcode;
    assign funct3_o = funct3;
    assign funct7_o = funct7;

    // Operands
    assign rd_o  = inst_i.r_type.rd;
    assign rs1_o = inst_i.r_type.rs1;
    assign rs2_o = inst_i.r_type.rs2;
    assign imm_o = imm;

    // Units
    assign funit_o   = funit;
    assign alu_op_o  = alu_op;
    assign alu_32_o  = (op_reg_32 | op_imm_32);
    assign alu_imm_o = (op_imm_32 | op_imm_64);
endmodule
