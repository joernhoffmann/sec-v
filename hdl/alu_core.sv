// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Performs decoded alu operations. Main part of the ALU.
 *
 * Todo
 *  [ ] Improve shift operations with barrel shifter
 *  [ ] Code improvements
 *      [ ] Consider using a separate flag for 32-bit operations
 *      [ ] Consider single sext32() for 32-bit operations
 *
 * History
 *  v1.0    - Initial version
 */
`include "secv_pkg.svh"
import secv_pkg::*;

module alu_core #(
    parameter int XLEN = secv_pkg::XLEN
) (
    input   alu_op_t            op_i,   // Operation to perform
    input   logic [XLEN-1:0]    a_i,    // 1st operand
    input   logic [XLEN-1:0]    b_i,    // 2nd operand

    // Output
    output  logic [XLEN-1:0]    res_o   // Result
);

    // Main logic
    logic [31:0] a32, b32;
    assign a32 = a_i[31:0];
    assign b32 = b_i[31:0];

    always_comb begin
        unique case(op_i)
            // Logic
            ALU_OP_AND:
                res_o = a_i & b_i;

            ALU_OP_OR:
                res_o = a_i | b_i;

            ALU_OP_XOR:
                res_o = a_i ^ b_i;

            // Arithmetic
            ALU_OP_ADD:
                res_o = a_i + b_i;

            ALU_OP_SUB:
                res_o = a_i - b_i;

            // Arithmetic (32-bit)
            ALU_OP_ADDW:
                res_o = sext32(a32 + b32);

            ALU_OP_SUBW:
                res_o = sext32(a32 - b32);

            // Shift
            ALU_OP_SLL:
                res_o = a_i << b_i;

            ALU_OP_SRL:
                res_o = a_i >> b_i;

            ALU_OP_SRA:
                res_o = $signed(a_i) >>> b_i;

            // Shift (32-bit)
            ALU_OP_SLLW:
                res_o = sext32(a32 << b32);

            ALU_OP_SRLW:
                res_o = sext32(a32 >> b32);

            ALU_OP_SRAW:
                res_o = sext32($signed(a32) >>> b32);

            // Compares
            ALU_OP_SLT:
                res_o = {~a_i[XLEN-1], a_i[XLEN-2:0]} < {~b_i[XLEN-1], b_i[XLEN-2:0]} ? 'h1 : 'h0;

            ALU_OP_SLTU:
                res_o = $unsigned(a_i) < $unsigned(b_i) ? 'h1 : 'h0;

            default:
                res_o = 0;
        endcase
    end
endmodule
