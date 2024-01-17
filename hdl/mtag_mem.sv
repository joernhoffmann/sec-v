// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2024
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project    : Memory Tagged SEC-V
 * Author     : Till Mahlburg
 * Purpose    : Memory Tagging memory unit for the SEC-V processor.
 *
 * History
 *    v1.0        - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module mtag_mem #(
    /* tag memory data width (should be the same as TLEN) */
    parameter int DAT_WIDTH = 16,
    /* tag memory address width in bit */
    parameter int ADR_WIDTH = 16,
    parameter bit RESET_MEM = 0
) (
    input  logic                    clk_i,  // Clock input
    input  logic                    rst_i,  // Reset input

    // read interface
    input  logic [ADR_WIDTH-1 : 0]  radr_i, // Address read input
    output logic [DAT_WIDTH-1 : 0]  dat_o,  // Data output
    input  logic                    re_i,   // Read enable signal
    output logic                    rack_o, // Read acknowledge output

    // write interface
    input  logic [ADR_WIDTH-1 : 0]  wadr_i, // Address write input
    input  logic [DAT_WIDTH-1 : 0]  dat_i,  // Data input
    input  logic                    we_i,   // Write enable signal
    output logic                    wack_o  // Write acknowledge output
);
    logic [DAT_WIDTH-1 : 0] memory [2**ADR_WIDTH];


    `ifndef SYNTHESIS
        // Memory initialization
        initial begin
            for (int idx=0; idx < 2**ADR_WIDTH; idx++)
                memory[idx] = '0;
        end

        // Assertions
        initial begin
            assert (ADR_WIDTH > 0) else
            $fatal("ADR_WIDTH must be greater than 0.");

            assert (DAT_WIDTH > 0) else
            $fatal("DAT_WIDTH greater than 0.");

            assert (RESET_MEM === 0 || RESET_MEM === 1) else
            $fatal("RESET_MEM must be 0 or 1.");
        end
    `endif

    always_ff @(posedge clk_i) begin
        // Prevent latches
        dat_o <= 'b0;
        rack_o <= 1'b0;
        wack_o <= 1'b0;
        wack_o <= 1'b0;

        // Reset condition
        if (rst_i) begin
            dat_o <= 'b0;
            rack_o <= 1'b0;
            wack_o <= 1'b0;

            if (RESET_MEM) begin
`ifdef VERILATOR
                memory <= '{default:'0};
`else
                for (int idx=0; idx < 2**ADR_WIDTH; idx++)
                    memory[idx] <= '0;
`endif
            end
        end else begin
            // read access
            if (re_i) begin
                dat_o  <= memory[radr_i];
                rack_o <= 1'b1;
            end

            // write access
            if (we_i) begin
                memory[wadr_i] <= dat_i;
                wack_o <= 1'b1;
            end
        end
    end
endmodule
