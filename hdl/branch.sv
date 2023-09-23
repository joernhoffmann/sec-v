// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Branch decision unit for the SEC-V processor.
 *
 * Opcodes
 *  - Branch : BEQ, BNE, BLT, BGE, BLTU, BGEU
 *
 * Todo
 *  [ ] Add unit tests
 *  [ ] Add formal verification
 *
 * History
 *  v1.0    - Initial version
 *  v1.1    - Reduce adder, simplify code
 *  v2.0    - Reduce to decision unit
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module branch #(
    parameter int XLEN = secv_pkg::XLEN
) (
    input   funct3_t        funct3_i,
    input   [XLEN-1 : 0]    rs1_i,
    input   [XLEN-1 : 0]    rs2_i,

    output  logic           take_o,
    output  logic           err_o
);

    logic take, err;
    always_comb begin
        take = 1'b0;
        err  = 1'b0;

        unique case (funct3_i)
            FUNCT3_BRANCH_BEQ   : take = (rs1_i          ==  rs2_i);
            FUNCT3_BRANCH_BNE   : take = (rs1_i          !=  rs2_i);
            FUNCT3_BRANCH_BLT   : take = ($signed(rs1_i) <   $signed(rs2_i));
            FUNCT3_BRANCH_BGE   : take = ($signed(rs1_i) >=  $signed(rs2_i));
            FUNCT3_BRANCH_BLTU  : take = (rs1_i          <   rs2_i);
            FUNCT3_BRANCH_BGEU  : take = (rs1_i          >=  rs2_i);
            default:
                err = 1'b1;
        endcase
    end

    // Outputs
    assign take_o = take & !err;
    assign err_o  = err;
endmodule
