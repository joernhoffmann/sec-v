// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Decodes the ALU operation from RISC-V instruction.
 *
 * History
 *  v1.0    - Initial version
 */
 `include "secv_pkg.svh"
import secv_pkg::*;

module alu_decoder (
    input   inst_t      inst_i,

    output  alu_op_t    op_o,           // ALU operation to perform
    output  logic       op_imm_o,       // Operation uses immediate as 2nd operand
    output  logic       op_32_o        // Operation uses 32-bit
);

    // Decode opcode
    opcode_t opcode;
    funct3_t funct3;
    funct7_t funct7;
    assign opcode = decode_opcode(inst_i);
    assign funct3 = inst_i.r_type.funct3;
    assign funct7 = inst_i.r_type.funct7;

    // Decode 32- or 64-bit operation types
    logic   op_reg_32, op_imm_32;
    assign  op_reg_32 = (opcode == OPCODE_OP_32);
    assign  op_imm_32 = (opcode == OPCODE_OP_IMM_32);

    logic   op_reg_64, op_imm_64;
    assign  op_reg_64 = (opcode == OPCODE_OP);
    assign  op_imm_64 = (opcode == OPCODE_OP_IMM);

    // Decode ALU operation
    alu_op_t op;
    always_comb begin : decode_alu
        op = ALU_OP_NONE;

        // Check if ALU addressed
        if (op_reg_32 || op_imm_32 ||
            op_reg_64 || op_imm_64)
        begin

            // Decode operation to perform
            case(funct3)
                FUNCT3_ALU_AND:
                    op = ALU_OP_AND;

                FUNCT3_ALU_OR:
                    op = ALU_OP_OR;

                FUNCT3_ALU_XOR:
                    op = ALU_OP_XOR;

                FUNCT3_ALU_ADD:
                    if (op_reg_32)
                        case (funct7)
                            FUNCT7_00h: op = ALU_OP_ADDW;
                            FUNCT7_20h: op = ALU_OP_SUBW;
                            default   : op = ALU_OP_NONE;
                        endcase

                    else if(op_imm_32)
                        op = ALU_OP_ADDW;

                    else if (op_reg_64)
                        case (funct7)
                            FUNCT7_00h: op = ALU_OP_ADD;
                            FUNCT7_20h: op = ALU_OP_SUB;
                            default   : op = ALU_OP_NONE;
                        endcase

                    else if (op_imm_64)
                        op = ALU_OP_ADD;

                FUNCT3_ALU_SLL:
                    op = ALU_OP_SLLW;

                FUNCT3_ALU_SRL:
                    if (op_reg_32 || op_imm_32)
                        case (funct7)
                            FUNCT7_00h: op = ALU_OP_SRLW;
                            FUNCT7_20h: op = ALU_OP_SRAW;
                            default   : op = ALU_OP_NONE;
                        endcase

                    else if (op_reg_64 || op_imm_64)
                        case (funct7)
                            FUNCT7_00h: op = ALU_OP_SRL;
                            FUNCT7_20h: op = ALU_OP_SRA;
                            default   : op = ALU_OP_NONE;
                        endcase

                FUNCT3_ALU_SLT:
                    op = ALU_OP_SLT;

                FUNCT3_ALU_SLTU:
                    op = ALU_OP_SLTU;

                default:
                    op = ALU_OP_NONE;
            endcase
        end
    end

    // Ouptut
    assign op_o = op;
    assign op_imm_o = (op_imm_32 | op_imm_64);
    assign op_32_o  = (op_reg_32 | op_imm_32);
endmodule
