// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Wishbone-compatible memory module. Operates in little-endian byte order.
 *
 * Features :
 *   - Configurable parameters for address and data width
 *   - Byte-selectable memory access
 *   - Configurable memory reset
 *   - Synchronous reset
 *
 * History  :
 *      v1.0    Initial version
 */

module mem_wb #(
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32,
    parameter logic RESET_MEM  = 0,
    localparam int SEL_WIDTH = DATA_WIDTH / 8
) (
    input  logic                    clk_i,  // Clock input
    input  logic                    rst_i,  // Reset input
    input  logic                    cyc_i,  // Cycle signal
    input  logic                    stb_i,  // Strobe signal

    input  logic [ SEL_WIDTH-1 : 0] sel_i,  // Byte select signal
    input  logic [ADDR_WIDTH-1 : 0] adr_i,  // Address input
    input  logic                     we_i,  // Write enable signal

    input  logic [DATA_WIDTH-1 : 0] dat_i,  // Data input
    output logic [DATA_WIDTH-1 : 0] dat_o,  // Data output
    output logic                    ack_o   // Acknowledge output
);
    logic [DATA_WIDTH-1 : 0] memory [2**ADDR_WIDTH];

    `ifndef SYNTHESIS
        // Memory initialization
        initial begin
            memory = '{default: 'b0};
        end

        // Assertions
        initial begin
            assert (ADDR_WIDTH > 0) else
            $fatal("ADDR_WIDTH must be greater than 0.");

            assert (DATA_WIDTH > 0 && $countones(DATA_WIDTH) == 1) else
            $fatal("DATA_WIDTH must be a power of 2 and greater than 0.");

            assert (RESET_MEM === 0 || RESET_MEM === 1) else
            $fatal("RESET_MEM must be 0 or 1.");

            assert (SEL_WIDTH === DATA_WIDTH / 8) else
            $fatal("SEL_WIDTH must match number of bytes in data word.");
        end
    `endif

    always_ff @(posedge clk_i) begin
        // Prevent lateches
        dat_o <= 'b0;
        ack_o <= 1'b0;

        // Reset condition
        if (rst_i) begin
            dat_o <= 'b0;
            ack_o <= 1'b0;

            if (RESET_MEM)
                memory <= '{default: '0};
        end

        // Module addressed
        else if (cyc_i && stb_i) begin
            // Write operation
            if (we_i) begin
                for (int byte_idx = 0; byte_idx < SEL_WIDTH; byte_idx++)
                    if (sel_i[byte_idx])
                        memory[adr_i][byte_idx*8 +: 8] <= dat_i[byte_idx*8 +: 8];

                ack_o <= 1'b1;
            end

            // Read operation
            else begin
                for (int byte_idx = 0; byte_idx < SEL_WIDTH; byte_idx++)
                    if (sel_i[byte_idx])
                        dat_o[byte_idx*8 +: 8] <= memory[adr_i][byte_idx*8 +: 8];
                    else
                        dat_o[byte_idx*8 +: 8] <= 8'b0;

                ack_o <= 1'b1;
            end
        end
    end
endmodule
