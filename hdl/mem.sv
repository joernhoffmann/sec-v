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

module mem (
    input  logic clk_i,
    input  logic rst_i,

    // Opcode and Function Unit
    input opcode_t opcode_i,
    input funit_t  funit_i,

    // Control signals
    input  logic mem_enable_i,
    input  logic mem_write_i,
    input  logic [XLEN-1:0] mem_address_i,
    input  logic [XLEN-1:0] mem_data_i,

    // Memory Interface
    output logic             dmem_cyc_o,
    output logic             dmem_stb_o,
    output logic [3:0]       dmem_sel_o,
    output logic [7:0]       dmem_adr_o,
    output logic [XLEN-1:0]  dmem_dat_o,

    input  logic             dmem_ack_i,
    input  logic [XLEN-1:0]  dmem_dat_i,

    // Output to CPU core
    output logic [XLEN-1:0]  mem_data_o
);
    logic [XLEN-1:0] mem_data;
    assign mem_data = dmem_dat_i;

    always_comb begin
        // Initialize memory signals
        dmem_cyc_o = 1'b0;
        dmem_stb_o = 1'b0;
        dmem_adr_o = 'b0;
        dmem_dat_o = 'b0;

        if (mem_enable_i) begin
            dmem_cyc_o = 1'b1;
            dmem_stb_o = 1'b1;
            dmem_adr_o = mem_address_i[7:0];

            if (mem_write_i) begin
                dmem_dat_o = mem_data_i; // Write data to memory interface
            end
        end
    end

    assign mem_data_o = mem_data;
endmodule
