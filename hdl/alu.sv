// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Arithmetic-logic unit for the SEC-V processor.
 *
 * Opcodes
 *  - 64-Bit: ADD, SUB, SLL, SRL, SRA, SLT, SLTU, AND, OR, XOR
 *  - 32-Bit: ADDW, SUBW, SLLW, SRLW, SRAW
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

module alu #(
    parameter int XLEN = secv_pkg::XLEN
) (
    input  funit_in_t  fu_i,
    output funit_out_t fu_o
);

    // Decode operation by alu_decoder
    alu_op_t op;
    logic op_imm, err;
    alu_decoder alu_dec0 (
        .inst_i     (fu_i.inst),
        .op_o       (op),
        .op_imm_o   (op_imm),
        .err_o      (err)
    );

    // Perform operation by alu_core
    logic [XLEN-1 : 0] a, b, result;
    assign a = fu_i.rs1_dat;                            // Operand a is always register
    assign b = op_imm ? fu_i.imm : fu_i.rs2_dat;        // Operand b is either register or immediate
    alu_core #(
        .XLEN (XLEN)
    ) alu0 (
        .op_i   (op),
        .a_i    (a),
        .b_i    (b),
        .res_o  (result)
    );

    // Output
    always_comb begin
        fu_o = funit_out_default();

        // Assign output if unit is enabled
        if (fu_i.ena) begin
            fu_o.rdy    = 1'b1;         // Ready when enabled
            fu_o.err    = err;          // Return error
            fu_o.rd_dat = result;       // Assign result to destination register
            fu_o.rd_wb  = !err;         // If no error occured, write back result
        end
    end
endmodule
