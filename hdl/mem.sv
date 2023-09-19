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
 * History
 *  v1.0    - Initial version
 *
 * Todo
 *  [ ] Consider separate blocks for load and store
 *  [ ] Add functions etc. to generalize code
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module mem #(
    parameter int XLEN = secv_pkg::XLEN,
    parameter int ADR_WIDTH = 8,
    localparam int SEL_WIDTH = XLEN/8
) (
    // Control
    input  logic                    ena_i,          // Enable unit
    output logic                    rdy_o,          // Unit ready
    output logic                    err_o,          // Error occured

    // Input operands
    input inst_t                    inst_i,         // Instruction to perform
    input logic [XLEN-1 : 0]        rs1_dat_i,      // Source register 1 data
    input logic [XLEN-1 : 0]        rs2_dat_i,      // Source register 2 data
    input imm_t                     imm_i,          // Immediate data

    // Output operands
    output logic [XLEN-1 : 0]       rd_o,           // Destination register (read data)
    output logic                    rd_wb_o,        // Destination register write-back (read data is valid)

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
    logic invalid_op;
    logic [XLEN-1 : 0] dmem_dat;

    // Memory access logic
    assign opcode = inst_i.r_type.opcode;
    assign funct3 = inst_i.r_type.funct3;

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
        invalid_op  = 'b0;

        if (ena_i) begin
            dmem_cyc_o = 1'b1;
            dmem_stb_o = 1'b1;
            dmem_adr_o = ADR_WIDTH'(rs1_dat_i + sext32(imm_i));

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
                        invalid_op = 1'b1;
                endcase
            end

            else if (opcode == OPCODE_STORE) begin
                case(funct3)
                    FUNCT3_STORE_SB: begin
                        dmem_dat_o[ 7:0] = rs2_dat_i[7:0];
                        dmem_sel_o       = 'b01;
                        dmem_we_o        = 'b1;
                    end

                    FUNCT3_STORE_SH: begin
                        dmem_dat_o[15:0] = rs2_dat_i[15:0];
                        dmem_sel_o       = 'b011;
                        dmem_we_o        = 'b1;
                    end

                    FUNCT3_STORE_SW: begin
                        dmem_dat_o[31:0] = rs2_dat_i[31:0];
                        dmem_sel_o       = 'b01111;
                        dmem_we_o        = 'b1;
                    end

                    FUNCT3_STORE_SD: begin
                        dmem_dat_o = rs2_dat_i;
                        dmem_sel_o = 'b01111_1111;
                        dmem_we_o  = 'b1;
                    end

                    default:
                        invalid_op = 1'b1;
                endcase
            end
        end
    end

    // Module is ready if enabled and
    //  (a) operation valid and data memory has acknowledged
    //  (b) operation invalid
    assign rdy_o = ena_i && ((!invalid_op && dmem_ack_i) || invalid_op);
    assign err_o = invalid_op;

    // Data Ouptut
    always_comb begin
        rd_o       = 'b0;
        rd_wb_o   = 'b0;

        if (ena_i && opcode == OPCODE_LOAD && !invalid_op) begin
            rd_o = dmem_dat;
            rd_wb_o = 1'b1;
        end
    end
endmodule
