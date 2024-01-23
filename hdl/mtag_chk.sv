// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023 - 2024
 *
 * Project    : Memory Tagged SEC-V
 * Author     : Till Mahlburg
 * Purpose    : Memory Tagging checking unit for the SEC-V processor.
 *
 * History
 *    v1.0        - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module mtag_chk #(
    parameter int HARTS = 1,
    parameter int TLEN = 16,        // Size of tags in bit
    /* Size of granules as amount of bits to shift the memory address to the right
     * Shift in bits    | actual granule size in byte
     * 0                | 1
     * 1                | 2
     * 2                | 4
     * 3                | 8
     * n                | 2^n
     */
    parameter int GRANULARITY = 2,
    parameter int ADR_WIDTH = 16,   // Address size in bit
    parameter int TADR_WIDTH = ADR_WIDTH - GRANULARITY  // Tag memory address width in bit
) (
    input  logic                   ena_i,

    input  logic [HARTS_WIDTH-1:0] hartid_i,
    input  logic [XLEN-1 : 0]      adr_i,

    output logic                   hart_mismatch_o,
    output logic                   color_mismatch_o,

    // Tag memory
    output logic                    tmem_re_o,
    output logic [TADR_WIDTH-1 : 0] tmem_adr_o,
    input  logic [TLEN-1 : 0]       tmem_dat_i,
    input  logic                    tmem_ack_i
);
    localparam int HARTS_WIDTH = (HARTS > 1) ? $clog2(HARTS) : 1;

    logic [ADR_WIDTH-1 : 0] mem_adr;
    assign mem_adr = ADR_WIDTH'(adr_i);

    logic [TLEN-1-HARTS : 0] tag;
    assign tag = adr_i[XLEN-1 : XLEN-TLEN+HARTS];

    logic hart_mismatch;
    assign hart_mismatch_o = hart_mismatch;

    logic color_mismatch;
    assign color_mismatch_o = color_mismatch;

    always_comb begin
        hart_mismatch = 1'b0;
        color_mismatch = 1'b0;

        tmem_re_o   = 'b0;
        tmem_adr_o  = 'b0;

        if (ena_i) begin
            tmem_re_o  = 1'b1;
            tmem_adr_o = TADR_WIDTH'(mem_adr >> GRANULARITY);

            // Check for correct hart
            if (tmem_ack_i && tmem_dat_i[hartid_i] != 1'b1) begin
                hart_mismatch = 1'b1;
            end
            // Compare tag with tag memory
            else if (tmem_ack_i && tmem_dat_i[TLEN-1:HARTS] != tag) begin
                color_mismatch = 1'b1;
            end
        end
    end
endmodule
