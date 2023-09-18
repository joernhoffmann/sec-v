
// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Wishbone interface definition.
 * TODO
 *  [ ] Use SystemVerilog assertions for assertions below
 */

interface wishbone_if
#(
    parameter int DAT_WIDTH = 32,
    parameter int ADR_WIDTH = 32
) (
    input logic clk,
    input logic rst
);
    localparam int SEL_WIDTH = DAT_WIDTH / 8;

    // Master output signals
    logic cyc;                          // Bus cycle
    logic stb;                          // Strobe, indicates valid data/address
    logic we;                           // Write enable
    logic [SEL_WIDTH-1 : 0] sel;        // Byte selection
    logic [DAT_WIDTH-1 : 0] dat_m;      // Data out from master
    logic [ADR_WIDTH-1 : 0] adr;        // Address from master

    // Slave input signals
    logic ack;                          // Acknowledge from slave
    logic [DAT_WIDTH-1 : 0] dat_s;      // Data in from slave

    modport master(
        input clk, rst,
        output cyc, stb, we, sel, dat_m, adr,
        input  ack, dat_s
    );

    modport slave(
        input clk, rst,
        input  cyc, stb, we, sel, dat_m, adr,
        output ack, dat_s
    );

    // Assertions
    `ifndef SYNTHESIS
        initial begin
            assert (ADR_WIDTH > 0) else
            $fatal("ADR_WIDTH must be greater than 0.");

            assert (DAT_WIDTH > 0 && $countones(DAT_WIDTH) == 1) else
            $fatal("DAT_WIDTH must be a power of 2 and greater than 0.");

            assert (SEL_WIDTH === DAT_WIDTH / 8) else
            $fatal("SEL_WIDTH must match number of bytes in data word.");
        end
    `endif
endinterface
