// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Decodes the ALU operation from RISC-V instruction.
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

module alu_decoder (
    input   inst_t      inst_i,     // RISC-V instruction
    output  alu_op_t    op_o,       // Decoded ALU operation to perform
    output  logic       err_o       // Decoding error, invalid opcode etc.
);

    // Decode opcode
    opcode_t opcode;
    funct3_t funct3;
    funct7_t funct7;
    assign opcode = decode_opcode(inst_i);
    assign funct3 = inst_i.r_type.funct3;
    assign funct7 = inst_i.r_type.funct7;

    // Decode 32- or 64-bit operation types
    logic   opcode_op, opcode_op_imm, opcode_op_32, opcode_op_imm_32;
    assign  opcode_op        = (opcode == OPCODE_OP);
    assign  opcode_op_imm    = (opcode == OPCODE_OP_IMM);
    assign  opcode_op_32     = (opcode == OPCODE_OP_32);
    assign  opcode_op_imm_32 = (opcode == OPCODE_OP_IMM_32);

    // Decode ALU operation
    alu_op_t op;
    logic err;

    always_comb begin : decode_alu
        op = ALU_OP_NONE;
        err = 1'b0;

        // Check if ALU is addressed
        if (opcode_op    || opcode_op_imm || opcode_op_32 || opcode_op_imm_32)
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
                    if (opcode_op)
                        case (funct7)
                            FUNCT7_00h: op = ALU_OP_ADD;
                            FUNCT7_20h: op = ALU_OP_SUB;
                            default:    err = 1'b1;
                        endcase

                    else if (opcode_op_imm)
                        op = ALU_OP_ADD;

                    else if (opcode_op_32)
                        case (funct7)
                            FUNCT7_00h: op = ALU_OP_ADDW;
                            FUNCT7_20h: op = ALU_OP_SUBW;
                            default:    err = 1'b1;
                        endcase

                    else if(opcode_op_imm_32)
                        op = ALU_OP_ADDW;

                FUNCT3_ALU_SLL:
                    op = ALU_OP_SLLW;

                FUNCT3_ALU_SRL:
                    if (opcode_op || opcode_op_imm)
                        case (funct7)
                            FUNCT7_00h: op = ALU_OP_SRL;
                            FUNCT7_20h: op = ALU_OP_SRA;
                            default:    err = 1'b1;
                        endcase

                    else if (opcode_op_32 || opcode_op_imm_32)
                        case (funct7)
                            FUNCT7_00h: op = ALU_OP_SRLW;
                            FUNCT7_20h: op = ALU_OP_SRAW;
                            default:    err = 1'b1;
                        endcase

                FUNCT3_ALU_SLT:
                    op = ALU_OP_SLT;

                FUNCT3_ALU_SLTU:
                    op = ALU_OP_SLTU;

                default:
                    err = 1'b1;
            endcase
        end

        // ALU not addressed
        else
            err = 1'b1;
    end

    // Ouptut
    assign op_o  = op;
    assign err_o = err;
endmodule
