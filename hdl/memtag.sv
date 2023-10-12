// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023
 *
 * Project  : Memory Tagged SEC-V
 * Author   : Till Mahlburg
 * Purpose  : Memory Tagging unit for the SEC-V processor.
 *
 * TODO:
 * - use opcode instead of set_i
 * - better use of mem_adr vs fu_i.src1
 *
 * History
 *  v1.0    - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module memtag #(
    /* size of tags in bit */
    parameter int TLEN = 16,
    /* size of granules in byte */
    parameter int GRANULARITY = 8,
    /* address size in bit */
    parameter int ADR_WIDTH = 8,
    /* tag memory address width in bit */
    parameter int TADR_WIDTH = 16,
    parameter int TSEL_WIDTH = 1
) (
    input funit_in_t fu_i,
    output funit_out_t fu_o,

    input logic set_i,

    output logic [ADR_WIDTH-1 : 0] err_adr_o,

    /* tag memory */
    output logic                    tmem_cyc_o,
    output logic                    tmem_stb_o,
    output logic [TSEL_WIDTH-1 : 0] tmem_sel_o,
    output logic [TADR_WIDTH-1 : 0] tmem_adr_o,
    output logic                    tmem_we_o,
    output logic [TLEN-1 : 0]       tmem_dat_o,
    input  logic [TLEN-1 : 0]       tmem_dat_i,
    input  logic                    tmem_ack_i
);
  logic [ADR_WIDTH-1 : 0] mem_adr;
  assign mem_adr = ADR_WIDTH'(fu_i.src1);

  logic [TLEN-1 : 0] tag;
  assign tag = fu_i.src1[XLEN-1 : XLEN-TLEN];

  logic set;
  assign set = set_i;

  logic err;

  logic [ADR_WIDTH-1 : 0] err_adr;
  assign err_adr_o = err_adr;

  always_comb begin
    err_adr = 'b0;
    err = 'b0;

    tmem_cyc_o = 'b0;
    tmem_stb_o = 'b0;
    tmem_sel_o = 'b0;
    tmem_adr_o = 'b0;
    tmem_dat_o = 'b0;
    tmem_we_o = 'b0;

    if (fu_i.ena) begin
      tmem_cyc_o = 1'b1;
      tmem_stb_o = 1'b1;
      tmem_adr_o = mem_adr / GRANULARITY;

      if (fu_i.op == OPCODE_CUSTOM_0) begin
        /* set tag in tag memory */
        tmem_dat_o = tag;
        tmem_sel_o = 'b1;
        tmem_we_o  = 'b1;
      end else begin
        /* compare tag with tag memory */
        tmem_sel_o = 1'b1;
        if (tmem_dat_i != tag) begin
          err = 1'b1;
          err_adr = mem_adr;
        end
      end
    end
  end

  always_comb begin
    fu_o = funit_out_default();

    if (fu_i.ena) begin
      fu_o.rdy = err;
      fu_o.err = err;
   end
 end

endmodule
