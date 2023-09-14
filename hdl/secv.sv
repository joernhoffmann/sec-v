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

module sec_v (
    input   logic   clk_i,
    input   logic   rst_i,

    // Instruction memory
    output  logic                   cyc_o,
    output  logic                   stb_o,
    output  logic [3 : 0]           sel_o,
    output  logic [ XLEN-1 : 0 ]    dat_i,
    input   logic                   ack_i,

    );


endmodule;
