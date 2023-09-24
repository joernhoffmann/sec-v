// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Decodes the BRANCH unit operation from RISC-V instruction.
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

module branch_decoder (
    input   inst_t      inst_i,     // RISC-V instruction
    output  branch_op_t op_o,       // Operation to perform
    output  logic       err_o       // Decoding error
);

    // Get funct3
    funct3_t funct3;
    assign funct3 = inst_i.r_type.funct3;

    // Decode operation
    branch_op_t op;
    logic err;
    always_comb begin
        op = BRANCH_OP_NONE;
        err = 1'b0;

        case(funct3)
            FUNCT3_BRANCH_BEQ:  op = BRANCH_OP_BEQ;
            FUNCT3_BRANCH_BNE:  op = BRANCH_OP_BNE;
            FUNCT3_BRANCH_BLT:  op = BRANCH_OP_BLT;
            FUNCT3_BRANCH_BGE:  op = BRANCH_OP_BGE;
            FUNCT3_BRANCH_BLTU: op = BRANCH_OP_BLTU;
            FUNCT3_BRANCH_BGEU: op = BRANCH_OP_BGEU;
            default:            err = 1'b1;
        endcase
    end

    // Ouptut
    assign op_o  = op;
    assign err_o = err;
endmodule
