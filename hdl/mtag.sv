// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023 - 2024
 *
 * Project    : Memory Tagged SEC-V
 * Author     : Till Mahlburg
 * Purpose    : Memory Tagging function unit for the SEC-V processor.
 *
 * History
 *    v1.0        - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module mtag #(
    parameter int HARTS = 1,
    parameter int TLEN = 16,        // Size of tags in bit
    /* Size of granules as amount of bits to shift the memory address to the right
     * Shift in bits    | actual granule size in byte
     * n                | 2^n
     */
    parameter int GRANULARITY = 2,
    parameter int ADR_WIDTH = 16,   // Address size in bit
    parameter int TADR_WIDTH = ADR_WIDTH-GRANULARITY   // Tag memory address width in bit
) (
    input funit_in_t fu_i,
    output funit_out_t fu_o,

    input logic [31:0] rnd_i,

    // Tag memory
    output logic                    tmem_we_o,
    output logic [TADR_WIDTH-1 : 0] tmem_adr_o,
    output logic [TLEN-1 : 0]       tmem_dat_o,
    input  logic                    tmem_ack_i
);
    logic [ADR_WIDTH-1 : 0] mem_adr;
    assign mem_adr = ADR_WIDTH'(fu_i.src1);

    // Decode encoded color, decode hart bitvector from rs2
    logic [TLEN-1 : 0] enc_tag;
    assign enc_tag = {fu_i.src1[XLEN-1 : XLEN-TLEN+HARTS], HARTS'(fu_i.src2)};

    // Decode tag from rs2
    logic [TLEN-1 : 0] r_tag;
    assign r_tag = TLEN'(fu_i.src2);

    // Generate random color from rnd_i, decode hart bitvector from rs2
    logic [TLEN-1 : 0] rnd_tag;
    assign rnd_tag = {(TLEN-HARTS)'(rnd_i != 0 ? rnd_i : 'b1), HARTS'(fu_i.src2)};

    logic [XLEN-1 : 0] res;
    logic err;

    always_comb begin
        err = 'b0;

        tmem_adr_o = 'b0;
        tmem_dat_o = 'b0;
        tmem_we_o  = 'b0;

        if (fu_i.ena) begin
            tmem_adr_o = TADR_WIDTH'(mem_adr >> GRANULARITY);

            case (fu_i.op)
                MTAG_OP_TADR: begin
                    tmem_dat_o = r_tag;
                    tmem_we_o  = 'b1;
                    res        = {r_tag[TLEN-1:TLEN-(TLEN-HARTS)],
                                 {(XLEN-(TLEN-HARTS)-ADR_WIDTH){1'b0}},
                                 mem_adr};
                end
                MTAG_OP_TADRE: begin
                    tmem_dat_o = enc_tag;
                    tmem_we_o  = 'b1;
                    res        = {enc_tag[TLEN-1:TLEN-(TLEN-HARTS)],
                                 {(XLEN-(TLEN-HARTS)-ADR_WIDTH){1'b0}},
                                 mem_adr};
                end
                MTAG_OP_TADRR: begin
                    tmem_dat_o = rnd_tag;
                    tmem_we_o  = 'b1;
                    res        = {rnd_tag[TLEN-1:TLEN-(TLEN-HARTS)],
                                 {(XLEN-(TLEN-HARTS)-ADR_WIDTH){1'b0}},
                                 mem_adr};
                end
                default: begin
                    // Unknown opcode
                    err = 'b1;
                    res = 'b0;
                end
            endcase
        end
    end

    // Output
    always_comb begin
        fu_o = funit_out_default();

        if (fu_i.ena) begin
            fu_o.rdy = 1'b1;
            fu_o.err = err;
            fu_o.res = res;
        end
    end

endmodule
