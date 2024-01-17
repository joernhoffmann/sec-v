// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Memory function unit for the SEC-V processor.
 *
 * Opcodes
 *  - loads (sign-ext)  : LB, LH, LW, LD
 *  - loads (zero-ext)  : LBU, LHU, LWU
 *  - stores            : SB, SH, SW, SD
 *
 * Todo
 *  [ ] Consider separate blocks for load and store
 *  [ ] Add functions etc. to generalize code
 *  [ ] Add unit tests
 *  [ ] Add formal verification
 *
 * History
 *  v1.0    - Initial version
 *
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module mem #(
    parameter int HARTS = 1,
    parameter int XLEN = secv_pkg::XLEN,
    parameter int ADR_WIDTH = 8,
    parameter int SEL_WIDTH = XLEN/8,
    parameter logic [ADR_WIDTH-1:0] ADR_FAULT_MASK = 0,
    parameter int TLEN = 16,
    parameter int TADR_WIDTH = 16
) (
    // Function unit interface
    input  funit_in_t  fu_i,
    output funit_out_t fu_o,

    input logic [HARTS_WIDTH -1 : 0] hart_id,

    // Wishbone data memory interface
    output logic                    dmem_cyc_o,
    output logic                    dmem_stb_o,
    output logic [SEL_WIDTH-1 : 0]  dmem_sel_o,
    output logic [ADR_WIDTH-1 : 0]  dmem_adr_o,
    output logic                    dmem_we_o,
    output logic [XLEN-1      : 0]  dmem_dat_o,
    input  logic [XLEN-1      : 0]  dmem_dat_i,
    input  logic                    dmem_ack_i,

    // Tag memory
    output logic                    tmem_re_o,
    output logic [TADR_WIDTH-1 : 0] tmem_adr_o,
    input  logic [TLEN-1       : 0] tmem_dat_i,
    input  logic                    tmem_ack_i
);
    localparam int HARTS_WIDTH = (HARTS > 1) ? $clog2(HARTS) : 1;

    // Signals
    logic [ADR_WIDTH-1 : 0] dmem_adr;
    logic [XLEN-1      : 0] dmem_dat;
    logic load;
    logic err;
    ecode_t ecode;
    mem_op_t op;

    logic tag_err;

    // Tag checking
    mtag_chk #(
        .HARTS(HARTS)
    ) mtag_chk0 (
        .ena_i      (fu_i.ena),
        .adr_i      (fu_i.src1),
        .err_o      (tag_err),
        .hart_id    (hart_id),

        .tmem_re_o  (tmem_re_o),
        .tmem_adr_o (tmem_adr_o),
        .tmem_dat_i (tmem_dat_i),
        .tmem_ack_i (tmem_ack_i)
    );

    // Mem access
    assign op = mem_op_t'(fu_i.op.mem);
    assign dmem_adr = ADR_WIDTH'(fu_i.src1);
    always_comb begin : mem_access
        // Bus signals
        dmem_cyc_o = 1'b0;
        dmem_stb_o = 1'b0;
        dmem_sel_o =   '0;
        dmem_adr_o =   '0;
        dmem_dat_o =   '0;
        dmem_we_o  = 1'b0;

        // Data signals
        dmem_dat = '0;
        load     = 1'b0;
        err      = 1'b0;
        ecode    = ECODE_OP_INVALID;

        if (fu_i.ena) begin
            dmem_cyc_o = 1'b1;
            dmem_stb_o = 1'b1;
            dmem_adr_o = dmem_adr;

            unique case(op)
                // Loads
                MEM_OP_LB: begin
                    dmem_dat   = sext8(dmem_dat_i[ 7:0]);
                    dmem_sel_o = 'b01;
                    load       = 1'b1;
                end

                MEM_OP_LH:  begin
                    dmem_dat = sext16(dmem_dat_i[15:0]);
                    dmem_sel_o = 'b011;
                    load       = 1'b1;
                end

                MEM_OP_LW:  begin
                    dmem_dat = sext32(dmem_dat_i[31:0]);
                    dmem_sel_o = 'b01111;
                    load       = 1'b1;
                end

                MEM_OP_LD: begin
                    dmem_dat = dmem_dat_i;
                    dmem_sel_o = 'b01111_1111;
                    load       = 1'b1;
                end

                MEM_OP_LBU: begin
                    dmem_dat[ 7:0] = dmem_dat_i[ 7:0];
                    dmem_sel_o = 'b01;
                    load       = 1'b1;
                end

                MEM_OP_LHU: begin
                    dmem_dat[15:0] = dmem_dat_i[15:0];
                    dmem_sel_o = 'b011;
                    load       = 1'b1;
                end

                MEM_OP_LWU: begin
                    dmem_dat[31:0] = dmem_dat_i[31:0];
                    dmem_sel_o = 'b01111_1111;
                    load       = 1'b1;
                end

                // Stores
                MEM_OP_SB: begin
                    dmem_dat_o[ 7:0] = fu_i.src2[7:0];
                    dmem_sel_o       = 'b01;
                    dmem_we_o        = 'b1;
                end

                MEM_OP_SH: begin
                    dmem_dat_o[15:0] = fu_i.src2[15:0];
                    dmem_sel_o       = 'b011;
                    dmem_we_o        = 'b1;
                end

                MEM_OP_SW: begin
                    dmem_dat_o[31:0] = fu_i.src2[31:0];
                    dmem_sel_o       = 'b01111;
                    dmem_we_o        = 'b1;
                end

                MEM_OP_SD: begin
                    dmem_dat_o = fu_i.src2;
                    dmem_sel_o = 'b01111_1111;
                    dmem_we_o  = 'b1;
                end

                default:
                    err = 1'b1;
            endcase

            // Access fault simulation (example for later MEMTAG, PMP implementation)
            if (((dmem_adr & ADR_FAULT_MASK) != 0) || tag_err) begin
                dmem_cyc_o = 0;
                dmem_stb_o = 0;
                dmem_dat_o = 0;
                dmem_adr_o = 0;
                dmem_we_o  = 0;
                err = 1'b1;
                if (tag_err) begin
                    ecode = ecode_t'(load ? ECODE_MTAG_LOAD_INVLD : ECODE_MTAG_STORE_INVLD);
                end else begin
                    ecode = ecode_t'(load ? ECODE_LOAD_ACCESS_FAULT : ECODE_STORE_ACCESS_FAULT);
                end
            end
        end
    end

    // Ouptut
    always_comb begin
        fu_o = funit_out_default();

        if (fu_i.ena) begin
            // Control output
            fu_o.rdy = err || dmem_ack_i;

            // Error output
            fu_o.err = err;
            fu_o.ecode = ecode;

            // Result output
            fu_o.res = dmem_dat;
            fu_o.res_wb = load && !err;
        end
    end
endmodule
