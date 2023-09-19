// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Main core and control logic of the SEC-V processor.
 *
 * History  :
 *  v1.0    - Initial version
 *
 * Todo
 *  [ ] Improve main fsm, separate signals
 *  [ ] Seperate units
 *  [ ] Introduce data types for interfaces etc.
 *  [ ] Simplify immediate hanlding, extend 32-bit to 64-bit imm, e. g. via sext32(imm)
 *  [ ] Use data types i/o for fuints, use array with units
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
    output  logic [7 : 0]           dmem_sel_o,
    output  logic [7 : 0]           dmem_adr_o,
    output  logic                   dmem_we_o,
    output  logic [XLEN-1 : 0]      dmem_dat_o,
    output  logic [XLEN-1 : 0]      dmem_dat_i,
    input   logic                   dmem_ack_i
);
    // Instruction
    inst_t inst;
    opcode_t opcode;
    funct3_t funct3;
    funct7_t funct7;
    imm_t imm;
    logic imm_op;

    // Program counter
    logic [XLEN-1:0] pc, pc_next;

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
    // ALU unit
    // -------------------------------------------------------------------------------------------------------------- //
    alu_op_t alu_op;
    logic [XLEN-1:0] alu_a, alu_b, alu_res;

    alu alu0 (
        .op_i   (alu_op),
        .a_i    (alu_a),
        .b_i    (alu_b),
        .res_o  (alu_res)
    );

    // -------------------------------------------------------------------------------------------------------------- //
    // BRANCH unit
    // -------------------------------------------------------------------------------------------------------------- //
    logic brn_ena, brn_rdy, brn_err;
    logic [XLEN-1:0] brn_pc, brn_rd;
    logic brn_pc_wb, brn_rd_wb;

    branch brn0 (
        // Control
        .inst_i     (inst),
        .ena_i      (brn_ena),
        .rdy_o      (brn_rdy),
        .err_o      (brn_err),

        // Input operands
        .pc_i       (pc),
        .rs1_i      (rs1_dat),
        .rs2_i      (rs2_dat),
        .imm_i     (imm),

        // Output
        .pc_o       (brn_pc),
        .pc_wb_o    (brn_pc_wb),
        .rd_o       (brn_rd),
        .rd_wb_o    (brn_rd_wb)
    );

    // -------------------------------------------------------------------------------------------------------------- //
    // MEM unit
    // -------------------------------------------------------------------------------------------------------------- //
    logic mem_ena, mem_rdy, mem_err;
    logic [XLEN-1:0] mem_rd;
    logic mem_rd_wb;

    mem mem0(
        // Control
        .ena_i      (mem_ena),
        .rdy_o      (mem_rdy),
        .err_o      (mem_err),

        // Input operands
        .inst_i     (inst),
        .rs1_dat_i  (rs1_dat),
        .rs2_dat_i  (rs2_dat),
        .imm_i      (imm),

        // Ouptut operands
        .rd_o       (mem_rd),
        .rd_wb_o    (mem_rd_wb),

        // Wishbone data memory interface
        .dmem_cyc_o (dmem_cyc_o),
        .dmem_stb_o (dmem_stb_o),
        .dmem_sel_o (dmem_sel_o),
        .dmem_adr_o (dmem_adr_o),
        .dmem_we_o  (dmem_we_o),
        .dmem_dat_o (dmem_dat_o),
        .dmem_dat_i (dmem_dat_i),
        .dmem_ack_i (dmem_ack_i)
    );

    // -------------------------------------------------------------------------------------------------------------- //
    // MOV unit
    // -------------------------------------------------------------------------------------------------------------- //
    logic mov_ena, mov_rdy, mov_err;
    logic [XLEN-1:0] mov_rd;
    logic mov_rd_wb;

    mov mov0 (
        // Control
        .inst_i     (inst),
        .ena_i      (mov_ena),
        .rdy_o      (mov_rdy),
        .err_o      (mov_err),

        // Input operands
        .pc_i       (pc),
        .imm_i      (imm),

        // Output
        .rd_o       (mov_rd),
        .rd_wb_o    (mov_rd_wb)
    );

    // -------------------------------------------------------------------------------------------------------------- //
    // Decoder unit
    // -------------------------------------------------------------------------------------------------------------- //
    funit_t funit;
    decode dec0 (
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
                    op_b_next = imm_op ? sext32(imm) : rs2_dat;
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
