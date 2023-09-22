// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Move function unit for the SEC-V processor.
 *
 * Note
 * - Immediate is expected to be decoded from U-type instruction.
 *
 * Opcodes
 *  - LUI, AUIPC
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

module mov #(
    parameter int XLEN = secv_pkg::XLEN
) (
    // Function unit interface
    input  funit_in_t  fu_i,
    output funit_out_t fu_o
);

    // Instruction decoding
    opcode_t opcode;
    assign opcode = fu_i.inst.r_type.opcode;

    // Branch computation
    logic [XLEN-1:0] rd;
    logic rd_wb;
    logic err;

    always_comb begin
        rd    =  'b0;
        rd_wb = 1'b0;
        err   = 1'b0;

        if (fu_i.ena) begin
            if (opcode == OPCODE_LUI) begin
                rd = fu_i.imm;
                rd_wb = 1'b1;
            end

            else if (opcode == OPCODE_AUIPC) begin
                rd = fu_i.pc + fu_i.imm;
                rd_wb = 1'b1;
            end

            else
                err = 1'b1;
        end
    end

    // Output
    always_comb begin
        fu_o = funit_out_default();

        if (fu_i.ena) begin
            fu_o.rdy    = 1'b1;
            fu_o.err    = err;
            fu_o.rd_dat = rd;
            fu_o.rd_wb  = rd_wb;
        end
    end
endmodule
