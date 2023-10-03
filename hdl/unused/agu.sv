// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Address generator unit
 *
 * History
 *  v1.0    - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

// Address generation unit
typedef enum logic [1:0] {
    AGU_OP_NONE,
    AGU_OP_NEXTPC,
    AGU_OP_RS1_IMM
} agu_op_t;

/*
// Address generator unit
agu_op_t agu_op;
logic [XLEN-1 : 0] agu_nxtpc;
logic agu_err_align;
agu agu0 (
    .op_i           (agu_op),
    .pc_i           (pc),
    .rs1_i          (rs1_dat),
    .imm_i          (imm),
    .nxtpc_o        (agu_nxtpc),
    .err_align_o    (agu_err_align)
);
*/



module agu #(
    parameter int XLEN = secv_pkg::XLEN
) (
    input agu_op_t              op_i,           // Operation to perform

    // Input addresses
    input logic [XLEN-1 : 0]    pc_i,           // Program counter
    input logic [XLEN-1 : 0]    rs1_i,          // Register source 1
    input imm_t                 imm_i,          // Immediate

    // Ouptut address
    output logic [XLEN-1 : 0]   nxtpc_o,        // Next PC
    output logic                err_align_o     // Alignemnt error (not 4-byte aligned)
);

// Address computation
logic [XLEN-1 : 0] nxtpc;
always_comb begin : agu_compute
    unique case (op_i)
        AGU_OP_NONE     : nxtpc = pc_i;
        AGU_OP_NEXTPC   : nxtpc = pc_i + 4;
        AGU_OP_RS1_IMM  : nxtpc = rs1_i + imm_i;
        default         : nxtpc = pc_i;
    endcase
end

// Alignemnt error
logic err_align;
assign err_align = (nxtpc[1:0] != 2'b00);

// Output
assign nxtpc_o     = {nxtpc[XLEN-1:2], 2'b00};
assign err_align_o = err_align;

endmodule