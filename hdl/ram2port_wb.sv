// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Wishbone-compatible 2-port memory module intended for SEC-V processor ROM and RAM.
 *
 * History
 *  v1.0    - Initial version
 */

module ram2port_wb #(
    parameter int ADDR_WIDTH    = 8,
    parameter int INST_WIDTH    = 32,
    parameter int DATA_WIDTH    = 64,
    parameter logic RESET_MEM   = 0,

    localparam int ISEL_WIDTH = INST_WIDTH / 8,
    localparam int DSEL_WIDTH = DATA_WIDTH / 8
) (
    // Control
    input  logic                    clk_i,
    input  logic                    rst_i,

    // Port 1 (instruction)
    input  logic                    cyc1_i,
    input  logic                    stb1_i,
    input  logic [ISEL_WIDTH-1 : 0] sel1_i,
    input  logic [ADDR_WIDTH-1 : 0] adr1_i,
    output logic [INST_WIDTH-1 : 0] dat1_o,
    output logic                    ack1_o,

    // Port 2 (data)
    input  logic                    cyc2_i,
    input  logic                    stb2_i,
    input  logic [DSEL_WIDTH-1 : 0] sel2_i,
    input  logic [ADDR_WIDTH-1 : 0] adr2_i,
    input  logic                     we2_i,
    input  logic [DATA_WIDTH-1 : 0] dat2_i,
    output logic [DATA_WIDTH-1 : 0] dat2_o,
    output logic                    ack2_o

);
    logic [DATA_WIDTH-1 : 0] memory [2**ADDR_WIDTH];

    `ifndef SYNTHESIS
        // Memory initialization
        initial begin
            for (int idx=0; idx < 2**ADDR_WIDTH; idx++)
                memory[idx] = 'b0;
        end

        // Assertions
        initial begin
            // Misc. checks
            assert (RESET_MEM === 0 || RESET_MEM === 1) else
            $fatal("RESET_MEM must be 0 or 1.");

            assert (ADDR_WIDTH > 0) else
            $fatal("ADDR_WIDTH must be greater than 0.");

            // Inst. checks
            assert (INST_WIDTH > 0 && $countones(INST_WIDTH) == 1) else
            $fatal("INST_WIDTH must be a power of 2 and greater than 0.");

            assert (INST_WIDTH == 32) else
            $fatal("INST_WIDTH must be 32 for now.");

            assert (ISEL_WIDTH === INST_WIDTH / 8) else
            $fatal("ISEL_WIDTH must match number of bytes in data word.");

            // Data checks
            assert (DATA_WIDTH > 0 && $countones(DATA_WIDTH) == 1) else
            $fatal("DATA_WIDTH must be a power of 2 and greater than 0.");

            assert (DATA_WIDTH == 64) else
            $fatal("DATA_WIDTH must be 64 for now.");

            assert (DSEL_WIDTH === DATA_WIDTH / 8) else
            $fatal("DSEL_WIDTH must match number of bytes in data word.");
        end
    `endif

    always @(posedge clk_i) begin
        // Blocked assignements (selections)
        logic [ADDR_WIDTH-1 : 0] dmem_adr;
        logic [INST_WIDTH-1 : 0] imem;
        dmem_adr = {adr1_i[ADDR_WIDTH-1:1], 1'b0};
        imem     = (adr1_i[0] == 1) ? memory[dmem_adr][63:32] : memory[dmem_adr][31:0];

        // Prevent latches
        dat1_o <= 'b0;
        dat2_o <= 'b0;
        ack1_o <= 1'b0;
        ack2_o <= 1'b0;


        // Reset condition
        if (rst_i) begin
            dat1_o <= 'b0;
            dat2_o <= 'b0;
            ack1_o <= 1'b0;
            ack2_o <= 1'b0;

            if (RESET_MEM)
                for (int idx=0; idx < 2**ADDR_WIDTH; idx++)
                    memory[idx] <= 'b0;
        end

        else begin
            // IMEM addressed
            if (cyc1_i && stb1_i) begin
                for (int byte_idx = 0; byte_idx < ISEL_WIDTH; byte_idx++)
                    if (sel1_i[byte_idx])
                        dat1_o[byte_idx*8 +: 8] <= imem[byte_idx*8 +: 8];
                    else
                        dat1_o[byte_idx*8 +: 8] <= 8'b0;

                ack1_o <= 1'b1;
            end

            // DMEM addressed
            if (cyc2_i && stb2_i) begin
                // Write
                if (we2_i) begin
                    for (int byte_idx = 0; byte_idx < DSEL_WIDTH; byte_idx++)
                        if (sel2_i[byte_idx])
                            memory[adr2_i][byte_idx*8 +: 8] <= dat2_i[byte_idx*8 +: 8];

                    ack2_o <= 1'b1;
                end

                // Read
                else begin
                    for (int byte_idx = 0; byte_idx < DSEL_WIDTH; byte_idx++)
                        if (sel2_i[byte_idx])
                            dat2_o[byte_idx*8 +: 8] <= memory[adr2_i][byte_idx*8 +: 8];
                        else
                            dat2_o[byte_idx*8 +: 8] <= 8'b0;

                    ack2_o <= 1'b1;
                end
            end
        end
    end
endmodule
