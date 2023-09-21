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

    // Decode ALU operation
    alu_op_t op;
    logic op_imm, op_32, err;
    alu_decoder alu_dec0 (
        .inst_i     (fu_i.inst),
        .op_o       (op),
        .op_imm_o   (op_imm),
        .op_32_o    (op_32),
        .err_o      (err)
    );

    // Perform ALU operation
    logic [XLEN-1 : 0] a, b, res;
    alu_core #(
        .XLEN (XLEN)
    ) alu0 (
        .op_i   (op),
        .a_i    (a),
        .b_i    (b),
        .res_o  (res)
    );

    // Output
    always_comb begin
        fu_o = funit_out_default();

        if (fu_i.ena) begin
            fu_o.rdy    = 1'b1;
            fu_o.err    = err;
            fu_o.rd_dat = res;
            fu_o.rd_wb  = !err;
        end
    end
endmodule
