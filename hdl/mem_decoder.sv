// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Decodes the MEM unit operation from RISC-V instruction.
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

module mem_decoder (
    input   inst_t      inst_i,
    output  mem_op_t    op_o,       // Operation to perform
    output  logic       err_o       // Decoding error
);

    // Decode opcode
    opcode_t opcode;
    funct3_t funct3;
    assign opcode = decode_opcode(inst_i);
    assign funct3 = inst_i.r_type.funct3;

    // Decode MEM operation
    mem_op_t op;
    logic err;

    always_comb begin
        op = MEM_OP_NONE;
        err = 1'b0;

        if (opcode == OPCODE_LOAD) begin
            case(funct3)
                FUNCT3_LOAD_LB:     op = MEM_OP_LB;
                FUNCT3_LOAD_LH:     op = MEM_OP_LH;
                FUNCT3_LOAD_LW:     op = MEM_OP_LW;
                FUNCT3_LOAD_LD:     op = MEM_OP_LD;
                FUNCT3_LOAD_LBU:    op = MEM_OP_LBU;
                FUNCT3_LOAD_LHU:    op = MEM_OP_LHU;
                FUNCT3_LOAD_LWU:    op = MEM_OP_LWU;
                default:            err = 1'b1;
            endcase
        end

        else if (opcode == OPCODE_STORE) begin
            case(funct3)
                FUNCT3_STORE_SB:    op = MEM_OP_SB;
                FUNCT3_STORE_SH:    op = MEM_OP_SH;
                FUNCT3_STORE_SW:    op = MEM_OP_SW;
                FUNCT3_STORE_SD:    op = MEM_OP_SD;
                default:            err = 1'b1;
            endcase
        end

        else
            err = 1'b1;
    end

    // Ouptut
    assign op_o     = op;
    assign err_o    = err;
endmodule
