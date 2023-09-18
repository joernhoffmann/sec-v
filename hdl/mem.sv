// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Memory function unit for SEC-V processor.
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module mem #(
    parameter int XLEN = secv_pkg::XLEN,
    parameter int ADR_WIDTH = 8,
    localparam int SEL_WIDTH = XLEN/8
)

(
    input  logic clk_i,
    input  logic rst_i,

    // Control signals
    input  logic                    ena_i,          // Enable unit
    output logic                    rdy_o,          // Unit ready
    output logic                    invalid_op_o,   // Invalid operation decoded

    // Input operands
    input inst_t                    inst_i,         // Instruction to perform
    input logic [XLEN-1 : 0]        rs1_dat_i,      // Source register 1 data
    input logic [XLEN-1 : 0]        rs2_dat_i,      // Source register 2 data
    input imm_t                     imm_i,          // Immediate data

    // Output operand
    output logic [XLEN-1 : 0]       dat_o,          // Read data
    output logic                    dat_vld_o,      // Read data is valid

    // Wishbone data memory interface
    output logic                    dmem_cyc_o,
    output logic                    dmem_stb_o,
    output logic [SEL_WIDTH-1 : 0]  dmem_sel_o,
    output logic [ADR_WIDTH-1 : 0]  dmem_adr_o,
    output logic [XLEN-1      : 0]  dmem_dat_o,
    output logic                    dmem_we_o,
    input  logic                    dmem_ack_i,
    input  logic [XLEN-1      : 0]  dmem_dat_i
);

    // Internal signals
    opcode_t opcode;
    funct3_t funct3;
    logic invalid_op;
    logic [XLEN-1 : 0] dmem_dat;

    // Module is ready if
    //  (a) enabled, operation is valid and data memory has acknowledged
    //  (b) enabled, but operation is invalid
    //  (c) not enabled
    assign rdy_o = (ena_i && !invalid_op && dmem_ack_i) || (ena_i && invalid_op) || !ena_i;
    assign invalid_op_o = invalid_op;

    // Memory access logic
    assign opcode = inst_i.r_type.opcode;
    assign funct3 = inst_i.r_type.funct3;

    always_comb begin
        // Initialize memory signals
        dmem_cyc_o = 'b0;
        dmem_stb_o = 'b0;
        dmem_sel_o = 'b0;
        dmem_adr_o = 'b0;
        dmem_dat_o = 'b0;
        dmem_we_o  = 'b0;

        // Output signals
        dmem_dat    = 'b0;
        dat_o       = 'b0;
        dat_vld_o   = 'b0;
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

                // Assign register operands
                if (!invalid_op) begin
                    dat_o = dmem_dat;
                    dat_vld_o = 1'b1;
                end
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
endmodule
