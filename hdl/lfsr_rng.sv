// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023
 *
 * Project    : Memory Tagged SEC-V
 * Author     : Till Mahlburg
 * Purpose    : Random Number Generator for the Memory Tagging function unit of the SEC-V processor.
 *
 * History
 *    v1.0        - Initial version
 */

module lfsr_rng #(
    parameter WIDTH = 32,
    parameter POLY = 'h911111FB,
    parameter SEED = 'h4569ab90
) (
    input logic clk_i,
    input logic rst_i,

    output logic [WIDTH-1:0] lfsr_o
);
    logic [WIDTH-1:0] feedback;
    logic [WIDTH-1:0] lfsr;

    always_ff @( posedge clk_i ) begin
        if (rst_i) begin
            feedback <= 0;
            lfsr <= SEED;
            lfsr_o <= 0;
        end else begin
            feedback <= lfsr & 'h1;
            lfsr <= lfsr >> 1;

            if (feedback != 0) begin
                lfsr <= lfsr ^ POLY;
            end
            lfsr_o <= lfsr;
        end
    end

endmodule
