// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Wishbone-compatible RAM module.
 *
 * Note:
 *  Module is only word addressable. Bytes could be selected.
 *
 * Features
 *  - Configurable parameters for address and data width
 *  - Byte-selectable memory access
 *  - Configurable memory reset
 *  - Synchronous reset
 *
 * Todo
 *  [ ] Add unit tests
 *  [ ] Add formal verification
 *
 * History
 *  v1.0    - Initial version
 */

module rom_wb #(
    parameter int ADR_WIDTH = 8,            // Addressable words
    parameter int DAT_WIDTH = 32,           // Data width (word width)
    parameter int SEL_WIDTH = DAT_WIDTH/8,  // Byte select
    parameter string FILE = ""
) (
    input  logic                    clk_i,  // Clock input
    input  logic                    rst_i,  // Reset input
    input  logic                    cyc_i,  // Cycle signal
    input  logic                    stb_i,  // Strobe signal

    input  logic [SEL_WIDTH-1 : 0]  sel_i,  // Byte select signal
    input  logic [ADR_WIDTH-1 : 0]  adr_i,  // Address input (word granule, last bytes don't count)

    output logic [DAT_WIDTH-1 : 0]  dat_o,  // Data output
    output logic                    ack_o   // Acknowledge output
);
    // Memory array
    logic [DAT_WIDTH-1 : 0] memory [2**ADR_WIDTH];

    `ifndef SYNTHESIS
        // Memory initialization
        initial begin
            if (FILE.len() != 0) begin
                $display("Load hex file %s", FILE);
                $readmemh(FILE, memory);
            end
        end

        // Assertions
        initial begin
            assert (ADR_WIDTH > 0) else
            $fatal("ADR_WIDTH must be greater than 0.");

            assert (DAT_WIDTH > 0 && $countones(DAT_WIDTH) == 1) else
            $fatal("DAT_WIDTH must be a power of 2 and greater than 0.");

            assert (SEL_WIDTH === DAT_WIDTH / 8) else
            $fatal("SEL_WIDTH must match number of bytes in data word.");
        end
    `endif

    always_ff @(posedge clk_i) begin
        // Prevent lateches
        dat_o <=  'b0;
        ack_o <= 1'b0;

        // Reset condition
        if (rst_i) begin
            dat_o <= 'b0;
            ack_o <= 1'b0;
        end

        // Module addressed
        else if (cyc_i && stb_i) begin
            for (int byte_idx = 0; byte_idx < SEL_WIDTH; byte_idx++)
                if (sel_i[byte_idx])
                    dat_o[byte_idx*8 +: 8] <= memory[adr_i][byte_idx*8 +: 8];
                else
                    dat_o[byte_idx*8 +: 8] <= 8'b0;

            ack_o <= 1'b1;
        end
    end
endmodule
