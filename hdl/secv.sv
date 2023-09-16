// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Main core and control logic of the SEC-V processor.
 * Todo
 *  [ ] Improve main fsm, separate signals
 *  [ ] Seperate units
 *  [ ] Introduce data types for interfaces etc.
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
    output  logic [ILEN-1 : 0]      imem_dat_i,
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
    // -------------------------------------------------------------------------------------------------------------- //
    // GPR
    // -------------------------------------------------------------------------------------------------------------- //
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

    // -------------------------------------------------------------------------------------------------------------- //
    // ALU
    // -------------------------------------------------------------------------------------------------------------- //
    alu_op_t alu_op;
    logic [XLEN-1:0] alu_a, alu_b, alu_res;

    alu alu0(
        .op_i   (alu_op),
        .a_i    (alu_a),
        .b_i    (alu_b),
        .res_o  (alu_res)
    );

    // -------------------------------------------------------------------------------------------------------------- //
    // BRANCH
    // -------------------------------------------------------------------------------------------------------------- //


    // -------------------------------------------------------------------------------------------------------------- //
    // Decoder
    // -------------------------------------------------------------------------------------------------------------- //
    inst_t inst;
    opcode_t opcode;
    funct3_t funct3;
    funct7_t funct7;
    imm_t imm;
    logic imm_op;
    funit_t funit;

    decode dec0(
        .inst_i     (inst),
        // Opcode fields
        .opcode_o   (opcode),
        .funct3_o   (funct3),
        .funct7_o   (funct7),

        // Operands
        .rs1_o      (rs1),
        .rs2_o      (rs2),
        .rd_o       (rd),
        .imm_o      (imm),
        .imm_use_o  (imm_op),

        // Function units
        .alu_op_o   (alu_op),
        .funit_o    (funit)
    );

    // -------------------------------------------------------------------------------------------------------------- //
    // Main FSM
    // -------------------------------------------------------------------------------------------------------------- //
    typedef enum logic [3:0] {
        STATE_IDLE,
        STATE_FETCH,
        STATE_DECODE,
        STATE_EXECUTE,
        STATE_WB
    } state_t;
    state_t state, state_next;

    // Instruction
    logic [XLEN-1:0] pc, pc_next;
    logic [ILEN-1:0] ir, ir_next;
    logic [XLEN-1:0] op_a, op_b, op_a_next, op_b_next;
    logic [XLEN-1:0] res, res_next;

    assign inst = ir;   // Assign decoder input to instruction register
    assign alu_a = op_a;
    assign alu_b = op_b;

    always_ff @( posedge clk_i) begin
        if (rst_i) begin
            state <= STATE_IDLE;
            pc    <= 'b0;
            ir    <= INST_NOP;
            op_a  <= 'b0;
            op_b  <= 'b0;
            res   <= 'b0;
        end

        else begin
            state <= state_next;
            pc    <= pc_next;
            ir    <= ir_next;
            op_a  <= op_a_next;
            op_b  <= op_b_next;
            res   <= res_next;
        end
    end

    always_comb begin
        state_next = state;
        pc_next = pc;
        ir_next = ir;
        op_a_next = op_a;
        op_b_next = op_b;
        res_next = res;

        imem_cyc_o = 0;
        imem_stb_o = 0;
        imem_adr_o = 'b0;

        case (state)
            STATE_IDLE: begin
                state_next = STATE_FETCH;
            end

            STATE_FETCH: begin
                // Access instruction memory
                imem_cyc_o = 1'b1;
                imem_stb_o = 1'b1;
                imem_adr_o = pc[7:0];

                if (imem_ack_i) begin
                    state_next = STATE_DECODE;
                    ir_next = imem_dat_i;
                end
            end

            STATE_DECODE: begin
                // Start decoder
                // ...

                // Function unit
                if (funit == FUNIT_ALU) begin
                    op_a_next = rs1_dat;
                    op_b_next = imm_op ? {32'b0, imm} : rs2_dat;
                end

                else if (funit == FUNIT_MEM) begin

                end

                // Other
                // ...

                // Select GPRs
                // ...
                state_next = STATE_EXECUTE;
            end

            STATE_EXECUTE: begin
                // Start execution
                // ...

                // Save result output's
                // ...

                state_next = STATE_WB;
            end

            STATE_WB: begin
                // Update register file
                // ...

                // Update pc
                // ...

                state_next = STATE_FETCH;
            end

            default:
                state_next = state;
        endcase
    end
endmodule;
