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
    parameter int GRANULARITY = 8,  // Size of granules in byte
    parameter int ADR_WIDTH = 16,   // Address size in bit
    parameter int TADR_WIDTH = 16   // Tag memory address width in bit
) (
    input  logic                   ena_i,

    input  logic [HARTS_WIDTH-1:0] hart_id,
    input  logic [XLEN-1 : 0]      adr_i,
    output logic                   err_o,

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

    logic err;
    assign err_o = err;

    always_comb begin
        err = 1'b0;

        tmem_re_o   = 'b0;
        tmem_adr_o  = 'b0;

        if (ena_i) begin
            tmem_re_o  = 1'b1;
            tmem_adr_o = TADR_WIDTH'(mem_adr / GRANULARITY);

            // Check for correct hart
            if (tmem_ack_i && tmem_dat_i[hart_id] != 1'b1) begin
                err = 1'b1;
            end
            // Compare tag with tag memory
            else if (tmem_ack_i && tmem_dat_i[TLEN-1:HARTS] != tag) begin
                err = 1'b1;
            end
        end
    end
endmodule
