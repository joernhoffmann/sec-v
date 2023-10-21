// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023
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
    /* size of tags in bit */
    parameter int TLEN = 16,
    /* size of granules in byte */
    parameter int GRANULARITY = 8,
    /* address size in bit */
    parameter int ADR_WIDTH = 8,
    /* tag memory address width in bit */
    parameter int TADR_WIDTH = 16,
    /* tag memory byte selection width */
    parameter int TSEL_WIDTH = TLEN / 8
) (
    input  logic                   ena_i,

    input  logic [XLEN-1 : 0]      adr_i,
    output logic                   err_o,
    output logic [ADR_WIDTH-1 : 0] err_adr_o,

    /* tag memory */
    output logic                    tmem_cyc_o,
    output logic                    tmem_stb_o,
    output logic [TSEL_WIDTH-1 : 0] tmem_sel_o,
    output logic [TADR_WIDTH-1 : 0] tmem_adr_o,
    input  logic [TLEN-1 : 0]       tmem_dat_i,
    input  logic                    tmem_ack_i
);

    logic [ADR_WIDTH-1 : 0] mem_adr;
    assign mem_adr = ADR_WIDTH'(adr_i);

    logic [TLEN-1 : 0] tag;
    assign tag = adr_i[XLEN-1 : XLEN-TLEN];

    logic err;
    assign err_o = err;

    logic [ADR_WIDTH-1 : 0] err_adr;
    assign err_adr_o = err_adr;

    always_comb begin
        err_adr = 'b0;
        err = 'b0;

        tmem_cyc_o = 'b0;
        tmem_stb_o = 'b0;
        tmem_sel_o = 'b0;
        tmem_adr_o = 'b0;

        if (ena_i) begin
            tmem_cyc_o = 1'b1;
            tmem_stb_o = 1'b1;
            tmem_adr_o = TADR_WIDTH'(mem_adr / GRANULARITY);

            /* compare tag with tag memory */
            tmem_sel_o = '1;
            if (tmem_dat_i != tag) begin
                err = 1'b1;
                err_adr = mem_adr;
            end
        end
    end

endmodule
