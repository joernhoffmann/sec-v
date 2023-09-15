// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Main core and control logic of the SEC-V processor.
 *
 */
`include "secv_pkg.svh"
import secv_pkg::*;

module secv (
    input   logic   clk_i,
    input   logic   rst_i,

    // Instruction memory
    output  logic                   imem_cyc_o,
    output  logic                   imem_stb_o,
    output  logic [3 : 0]           imem_sel_o,
    output  logic [7 : 0]           imem_adr_o,
    output  logic [XLEN-1 : 0]      imem_dat_i,
    input   logic                   imem_ack_i,

    // Data memory
    output  logic                   dmem_cyc_o,
    output  logic                   dmem_stb_o,
    output  logic [3 : 0]           dmem_sel_o,
    output  logic [7 : 0]           dmem_adr_o,
    output  logic [XLEN-1 : 0]      dmem_dat_o,
    output  logic [XLEN-1 : 0]      dmem_dat_i,
    input   logic                   dmem_ack_i
);

    // Register file
    regadr_t rs1, rs2, rd;
    logic [XLEN-1:0] rs1_dat, rs2_dat, rd_dat;
    logic rd_ena;
    gpr gpr0 (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .rs1_i        (rs1),        // Source Register 1
        .rs1_dat_o    (rs1_dat),
        .rs2_i        (rs2),        // Source register 2
        .rs2_dat_o    (rs2_dat),
        .rd_i         (rd),         // Destination register
        .rd_dat_i     (rd_dat),
        .rd_ena_i     (rd_ena)
    );

    // ALU




endmodule;
