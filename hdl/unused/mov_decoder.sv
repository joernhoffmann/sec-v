// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Decodes the MOV (transport) unit operation from RISC-V instruction.
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

module mov_decoder (
    input   inst_t      inst_i,
    output  mov_op_t    op_o,       // Operation to perform
    output  logic       err_o       // Decoding error
);

    // Decode opcode
    opcode_t opcode;
    funct3_t funct3;
    assign opcode = decode_opcode(inst_i);
    assign funct3 = inst_i.r_type.funct3;

    // Decode MEM operation
    mov_op_t op;
    logic err;

    always_comb begin
        op = MOV_OP_NONE;
        err = 1'b0;

        unique if (opcode == OPCODE_LUI)
            op = MOV_OP_LUI;

        else if (opcode == OPCODE_AUIPC)
            op = MOV_OP_AUIPC;

        else
            err = 1'b1;
    end

    // Ouptut
    assign op_o  = op;
    assign err_o = err;
endmodule
