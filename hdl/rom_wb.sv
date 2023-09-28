// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Wishbone-compatible RAM module.
 *
 * Notes
 *  - Memory addressing operates in little-endian byte order.
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
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32,
    parameter int SEL_WIDTH = DATA_WIDTH/8
) (
    input  logic                    clk_i,  // Clock input
    input  logic                    rst_i,  // Reset input
    input  logic                    cyc_i,  // Cycle signal
    input  logic                    stb_i,  // Strobe signal

    input  logic [ SEL_WIDTH-1 : 0] sel_i,  // Byte select signal
    input  logic [ADDR_WIDTH-1 : 0] adr_i,  // Address input

    output logic [DATA_WIDTH-1 : 0] dat_o,  // Data output
    output logic                    ack_o   // Acknowledge output
);
    logic [DATA_WIDTH-1 : 0] memory [2**ADDR_WIDTH];

    `ifndef SYNTHESIS
        // Memory initialization
        initial begin
            // hello.asm
            memory[0] = 32'h0ca00093;
            memory[1] = 32'h00809093;
            memory[2] = 32'h0fe08093;
            memory[3] = 32'h0ff00113;
            memory[4] = 32'h00113023;
            memory[5] = 32'h00000033;
            memory[6] = 32'hffdff06f;
        end

        // Assertions
        initial begin
            assert (ADDR_WIDTH > 0) else
            $fatal("ADDR_WIDTH must be greater than 0.");

            assert (DATA_WIDTH > 0 && $countones(DATA_WIDTH) == 1) else
            $fatal("DATA_WIDTH must be a power of 2 and greater than 0.");

            assert (SEL_WIDTH === DATA_WIDTH / 8) else
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
