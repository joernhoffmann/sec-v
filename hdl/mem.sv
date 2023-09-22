// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Memory function unit for the SEC-V processor.
 *
 * Opcodes
 *  - loads (sign-ext)  : LB, LH, LW, LD
 *  - loads (zero-ext)  : LBU, LHU, LWU
 *  - stores            : SB, SH, SW, SD
 *
 * Todo
 *  [ ] Consider separate blocks for load and store
 *  [ ] Add functions etc. to generalize code
 *  [ ] Add unit tests
 *  [ ] Add formal verification
 *
 * History
 *  v1.0    - Initial version
 *
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module mem #(
    parameter int XLEN = secv_pkg::XLEN,
    parameter int ADR_WIDTH = 8,
    localparam int SEL_WIDTH = XLEN/8
) (
    // Function unit interface
    input  funit_in_t  fu_i,
    output funit_out_t fu_o,

    // Wishbone data memory interface
    output logic                    dmem_cyc_o,
    output logic                    dmem_stb_o,
    output logic [SEL_WIDTH-1 : 0]  dmem_sel_o,
    output logic [ADR_WIDTH-1 : 0]  dmem_adr_o,
    output logic                    dmem_we_o,
    output logic [XLEN-1      : 0]  dmem_dat_o,
    input  logic [XLEN-1      : 0]  dmem_dat_i,
    input  logic                    dmem_ack_i
);

    // Internal signals
    opcode_t opcode;
    funct3_t funct3;
    logic err;
    logic [XLEN-1 : 0] dmem_dat;

    // Memory access logic
    assign opcode = fu_i.inst.r_type.opcode;
    assign funct3 = fu_i.inst.r_type.funct3;

    always_comb begin
        // Bus signals
        dmem_cyc_o = 'b0;
        dmem_stb_o = 'b0;
        dmem_sel_o = 'b0;
        dmem_adr_o = 'b0;
        dmem_dat_o = 'b0;
        dmem_we_o  = 'b0;

        // Data signals
        dmem_dat    = 'b0;
        err = 'b0;

        if (fu_i.ena) begin
            dmem_cyc_o = 1'b1;
            dmem_stb_o = 1'b1;
            dmem_adr_o = ADR_WIDTH'(fu_i.rs1_dat + fu_i.imm);

            if (opcode == OPCODE_LOAD) begin
                case(funct3)
                    FUNCT3_LOAD_LB: begin
                        dmem_dat   = sext8(dmem_dat_i[ 7:0]);
                        dmem_sel_o = 'b01;
                    end

                    FUNCT3_LOAD_LH:  begin
                        dmem_dat = sext16(dmem_dat_i[15:0]);
                        dmem_sel_o = 'b011;
                    end

                    FUNCT3_LOAD_LW:  begin
                        dmem_dat = sext32(dmem_dat_i[31:0]);
                        dmem_sel_o = 'b01111;
                    end

                    FUNCT3_LOAD_LD: begin
                        dmem_dat = dmem_dat_i;
                        dmem_sel_o = 'b01111_1111;
                    end

                    FUNCT3_LOAD_LBU: begin
                        dmem_dat[ 7:0] = dmem_dat_i[ 7:0];
                        dmem_sel_o = 'b01;
                    end

                    FUNCT3_LOAD_LHU: begin
                        dmem_dat[15:0] = dmem_dat_i[15:0];
                        dmem_sel_o = 'b011;
                    end

                    FUNCT3_LOAD_LWU: begin
                        dmem_dat[31:0] = dmem_dat_i[31:0];
                        dmem_sel_o = 'b01111_1111;
                    end

                    default:
                        err = 1'b1;
                endcase
            end

            else if (opcode == OPCODE_STORE) begin
                case(funct3)
                    FUNCT3_STORE_SB: begin
                        dmem_dat_o[ 7:0] = fu_i.rs2_dat[7:0];
                        dmem_sel_o       = 'b01;
                        dmem_we_o        = 'b1;
                    end

                    FUNCT3_STORE_SH: begin
                        dmem_dat_o[15:0] = fu_i.rs2_dat[15:0];
                        dmem_sel_o       = 'b011;
                        dmem_we_o        = 'b1;
                    end

                    FUNCT3_STORE_SW: begin
                        dmem_dat_o[31:0] = fu_i.rs2_dat[31:0];
                        dmem_sel_o       = 'b01111;
                        dmem_we_o        = 'b1;
                    end

                    FUNCT3_STORE_SD: begin
                        dmem_dat_o = fu_i.rs2_dat;
                        dmem_sel_o = 'b01111_1111;
                        dmem_we_o  = 'b1;
                    end

                    default:
                        err = 1'b1;
                endcase
            end

            else
                err = 1'b1;
        end
    end

    // Ouptut
    always_comb begin
        fu_o = funit_out_default();

        if (fu_i.ena) begin
                // Module is ready if unit enabled and
                //  (a) operation valid and data memory has acknowledged
                //  (b) operation invalid
                fu_o.rdy = (!err && dmem_ack_i) || err;

                // Error output
                fu_o.err = err;

            // Operand output
            if (opcode == OPCODE_LOAD && !err) begin
                fu_o.rd_dat = dmem_dat;
                fu_o.rd_wb  = 1'b1;
            end
        end
    end
endmodule
