// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Till Mahlburg, 2023
 *
 * Project  : Memory Tagged SEC-V
 * Author   : Till Mahlburg
 * Purpose  : Memory Tagging unit for the SEC-V processor.
 *
 * TODO:
 * - exception interrupt
 *
 * History
 *  v1.0    - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module memtag #(
    /* size of tags in bit */
    parameter int TAG_SIZE = 32,
    /* size of granules in byte */
    parameter int GRANULARITY = 8,
    /* address size in bit */
    parameter int ADR_WIDTH = 8,
    /* tag memory address width in bit */
    parameter int TADR_WIDTH = 32,
    parameter int TSEL_WIDTH = 1
) (
    input funit_in_t fu_i,

    input logic set_i,

    output logic err_o,
    output logic [ADR_WIDTH-1 : 0] err_adr,

    /* tag memory */
    output logic                    tmem_cyc_o,
    output logic                    tmem_stb_o,
    output logic [TSEL_WIDTH-1 : 0] tmem_sel_o,
    output logic [TADR_WIDTH-1 : 0] tmem_adr_o,
    output logic                    tmem_we_o,
    output logic [  TAG_SIZE-1 : 0] tmem_dat_o,
    input  logic [  TAG_SIZE-1 : 0] tmem_dat_i,
    input  logic                    tmem_ack_i
);
  logic [ADR_WIDTH-1 : 0] mem_addr;
  assign mem_adr = ADR_WIDTH'(fu_i.src1);

  logic [TAG_SIZE-1 : 0] tag;
  assign tag = mem_adr[ADR_WIDTH-1 : ADR_WIDTH-1-TAG_SIZE];

  logic set;
  assign set = set_i;

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
    tmem_dat_o = 'b0;
    tmem_we_o = 'b0;

    if (fu_i.ena) begin
      tmem_cyc_o = 1'b1;
      tmem_stb_o = 1'b1;
      tmem_adr_o = mem_adr[ADR_WIDTH-1-TAG_SIZE : 0] / GRANULARITY;

      if (set) begin
        /* set tag in tag memory */
        tmem_dat_o = tag;
        tmem_sel_o = 'b1;
        tmem_we_o  = 'b1;
      end else begin
        /* compare tag with tag memory */
        tmem_sel = 1'b1;
        if (tmem_dat_i != tag) begin
          err = 1'b1;
          err_adr = mem_adr;
        end
      end
    end
  end

endmodule
