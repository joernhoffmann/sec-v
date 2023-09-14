// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Wishbone-compliant instruction memory. Operates in little-endian byte order.
 * Features
 *   - Configurable parameters for address and data width
 *   - Byte-selectable memory access
 *   - Configurable memory reset
 *   - Synchronous reset
 *
 * History
 *      v1.0    - Initial version
 *      v1.1    - Use wb interface definitions
 */
`include "wishbone_if.svh"

module mem_wb #(
    parameter logic RESET_MEM  = 0
) (
    wishbone_if.slave wb
);
    // Alias
    localparam int ADR_WIDTH = wb.ADR_WIDTH;
    localparam int DAT_WIDTH = wb.DAT_WIDTH;
    localparam int SEL_WIDTH = wb.SEL_WIDTH;

    // Memory, realized as array
    logic [DAT_WIDTH-1 : 0] memory [2**ADR_WIDTH];

    `ifndef SYNTHESIS
        // Memory initialization
        initial begin
            memory = '{default: 'b0};
        end

        // Assertions
        initial begin
            assert (RESET_MEM === 0 || RESET_MEM === 1) else
            $fatal("RESET_MEM must be 0 or 1.");
        end
    `endif

    // Main logic
    always_ff @(posedge wb.clk) begin
        // Prevent lateches
        wb.dat_s <= 'b0;
        wb.ack   <= 1'b0;

        // Reset condition
        if (wb.rst) begin
            wb.dat_s <= 'b0;
            wb.ack   <= 1'b0;

            if (RESET_MEM)
                memory <= '{default: '0};
        end

        // Module addressed
        else if (wb.cyc && wb.stb) begin
            // Write operation
            if (wb.we) begin
                for (int byte_idx = 0; byte_idx < SEL_WIDTH; byte_idx++)
                    if (wb.sel[byte_idx])
                        memory[wb.adr][byte_idx*8 +: 8] <= wb.dat_m[byte_idx*8 +: 8];

                wb.ack <= 1'b1;
            end

            // Read operation
            else begin
                for (int byte_idx = 0; byte_idx < SEL_WIDTH; byte_idx++)
                    if (wb.sel[byte_idx])
                        wb.dat_s[byte_idx*8 +: 8] <= memory[wb.adr][byte_idx*8 +: 8];
                    else
                        wb.dat_s[byte_idx*8 +: 8] <= 8'b0;

                wb.ack <= 1'b1;
            end
        end
    end
endmodule
