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
    parameter WIDTH = 32
) (
    input logic clk_i,
    input logic rst_i,

    input logic  [WIDTH-1:0] poly,
    input logic  [WIDTH-1:0] lfsr_i,
    output logic [WIDTH-1:0] lfsr_o
);
    logic [WIDTH-1:0] feedback;
    logic [WIDTH-1:0] lfsr;

    always_ff @( posedge clk_i ) begin
        if (rst_i) begin
            feedback <= 0;
            lfsr <= 0;
            lfsr_o <= 0;
        end else begin
            feedback <= lfsr_i & 'h1;
            lfsr <= lfsr_i >> 1;

            if (feedback != 0) begin
                lfsr_o <= lfsr ^ poly;
            end else begin
                lfsr_o <= lfsr;
            end
        end
    end
endmodule
