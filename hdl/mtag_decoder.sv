// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023
 *
 * Project  : Memory Tagged SEC-V
 * Author   : Till Mahlburg
 * Purpose  : Memory Tagging decoder for the SEC-V processor.
 *
 * History
 *  v1.0    - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module mtag_decoder (
    input  inst_t    inst_i,
    output mtag_op_t op_o,
    output logic     err_o
);

    funct3_t funct3;
    assign funct3 = inst_i.r_type.funct3;

    opcode_t opcode;
    assign opcode = decode_opcode(inst_i);

    mtag_op_t op;
    logic err;

    always_comb begin
        op = MTAG_OP_NONE;
        err = 1'b0;

        if (opcode == OPCODE_CUSTOM_0) begin
            case(funct3)
                FUNCT3_MTAG_TADR:   op = MTAG_OP_TADR;
                FUNCT3_MTAG_TADRE:  op = MTAG_OP_TADRE;
                default:            err = 1'b1;
            endcase
        end
        else begin
            err = 1'b1;
        end
    end

    assign op_o = op;
    assign err_o = err;
endmodule
