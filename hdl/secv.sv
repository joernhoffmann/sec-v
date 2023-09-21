// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Main core and control logic of the SEC-V processor.
 *
 * Todo
 *  [ ] Improve main fsm
 *  [ ] Seperate units (e.g. main fsm, pipeline etc.)
 *  [ ] Introduce more data types (e. g. wishbone, function unit, function unit array)
 *  [ ] Improve pipeline,  implement
 *      [ ] a) regular pipeline processing
 *      [ ] b) interleaved multi threading pipeline
 *      [ ] c) Out-of-order or superscalar processing
 *  [ ] Add security functions
 *
 * History
 *  v1.0    - Initial version
 *  v1.1    - Add function unit bus
 */
`include "secv_pkg.svh"
import secv_pkg::*;

module secv #(
    parameter int ILEN = secv_pkg::ILEN,
    parameter int XLEN = secv_pkg::XLEN,

    parameter int IADR_WIDTH = 8,        // Instruction memory address width
    parameter int DADR_WIDTH = 8,        // Data memory address width

    localparam int ISEL_WIDTH = ILEN/8,  // Instruction memory byte selection width
    localparam int DSEL_WIDTH = XLEN/8   // Data memory byte selection width
) (
    input   logic   clk_i,
    input   logic   rst_i,

    // Instruction memory
    output  logic                       imem_cyc_o,
    output  logic                       imem_stb_o,
    output  logic [ISEL_WIDTH-1 : 0]    imem_sel_o,
    output  logic [IADR_WIDTH-1 : 0]    imem_adr_o,
    input   logic [ILEN-1       : 0]    imem_dat_i,
    input   logic                       imem_ack_i,

    // Data memory
    output  logic                       dmem_cyc_o,
    output  logic                       dmem_stb_o,
    output  logic [DSEL_WIDTH-1 : 0]    dmem_sel_o,
    output  logic [DADR_WIDTH-1 : 0]    dmem_adr_o,
    output  logic                       dmem_we_o,
    output  logic [XLEN-1 : 0]          dmem_dat_o,
    input   logic [XLEN-1 : 0]          dmem_dat_i,
    input   logic                       dmem_ack_i
);
    // Program counter
    logic [XLEN-1:0] pc, pc_next;

    // --- General purpose register file ---------------------------------------------------------------------------- //
    logic [XLEN-1:0] rs1_dat, rs2_dat, rd_dat;
    regadr_t rs1_adr, rs2_adr, rd_adr;
    logic rd_wb;

    gpr gpr0 (
        .clk_i        (clk_i),
        .rst_i        (rst_i),

         // Source Register 1
        .rs1_adr_i    (rs1_adr),
        .rs1_dat_o    (rs1_dat),

        // Source register 2
        .rs2_adr_i    (rs2_adr),
        .rs2_dat_o    (rs2_dat),

        // Destination register
        .rd_adr_i     (rd_adr),
        .rd_dat_i     (rd_dat),
        .rd_wb_i      (rd_wb)
    );

    // ---Decoder --------------------------------------------------------------------------------------------------- //
    inst_t inst;
    opcode_t opcode;
    funct3_t funct3;
    funct7_t funct7;
    imm_t imm;
    logic imm_op;
    funit_t funit;

    decoder dec0 (
        .inst_i     (inst),
        // Opcode fields
        .opcode_o   (opcode),
        .funct3_o   (funct3),
        .funct7_o   (funct7),

        // Operands
        .rs1_adr_o  (rs1_adr),
        .rs2_adr_o  (rs2_adr),
        .rd_adr_o   (rd_adr),
        .imm_o      (imm),
        .imm_use_o  (imm_op),

        // Function unit
        .funit_o    (funit)
    );

    // --- Function units ------------------------------------------------------------------------------------------- //
    // Arithmetic-logic unit
    alu alu0 (
        .fu_i   (fui_bus[FUNIT_ALU]),
        .fu_o   (fuo_bus[FUNIT_ALU])
    );

    // Branch unit
    branch brn0 (
        .fu_i   (fui_bus[FUNIT_BRANCH]),
        .fu_o   (fuo_bus[FUNIT_BRANCH])
    );

    // Data memory inteface unit
    mem mem0(
        // Control
        .fu_i   (fui_bus[FUNIT_MEM]),
        .fu_o   (fuo_bus[FUNIT_MEM]),

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

    // Move (transport) unit
    mov mov0 (
        .fu_i (fui_bus[FUNIT_MOV]),
        .fu_o (fuo_bus[FUNIT_MOV])
    );

    // --- Function unit bus ---------------------------------------------------------------------------------------- //
    funit_in_t  fui_bus[FUNIT_COUNT];
    funit_out_t fuo_bus[FUNIT_COUNT];
    funit_in_t  fui;
    funit_out_t fuo;

    // Connect decoded function unit
    assign fui_bus[funit] = fui;
    assign fuo = fuo_bus[funit];

    // -------------------------------------------------------------------------------------------------------------- //
    // Main state machine
    // -------------------------------------------------------------------------------------------------------------- //
    typedef enum logic [3:0] {
        STATE_IDLE,
        STATE_FETCH,
        STATE_DECODE,
        STATE_EXECUTE,
        STATE_WB
    } state_t;
    state_t state, state_next;

    // Registers
    logic [ILEN-1:0] ir, ir_next;
    assign inst = ir;
    always_ff @( posedge clk_i) begin
        if (rst_i) begin
            state <= STATE_IDLE;
            pc    <= 'b0;
            ir    <= INST_NOP;
        end

        else begin
            state <= state_next;
            pc    <= pc_next;
            ir    <= ir_next;
        end
    end

    // Next state logic
    always_comb begin : main_fsm
        // Default values
        state_next = state;
        pc_next = pc;
        ir_next = ir;

        // Prevent latches
        imem_cyc_o = 1'b0;
        imem_stb_o = 1'b0;
        imem_adr_o =  'b0;
        imem_sel_o =  'b0;
        rd_dat     =  'b0;
        rd_wb      = 1'b0;

        // Function unit
        fui = funit_in_default();
        fui.ena     = 1'b0;
        fui.inst    = inst;
        fui.rs1_dat = rs1_dat;
        fui.rs2_dat = rs2_dat;
        fui.imm     = imm;
        fui.pc      = pc;

        // State transistion
        case (state)
            STATE_IDLE: begin
                state_next = STATE_FETCH;
            end

            STATE_FETCH: begin
                // Access instruction memory
                imem_cyc_o = 1'b1;
                imem_stb_o = 1'b1;
                imem_sel_o =  'b1;
                imem_adr_o = pc[IADR_WIDTH-1 : 0];

                if (imem_ack_i) begin
                    state_next = STATE_DECODE;
                    ir_next = imem_dat_i;
                end
            end

            STATE_DECODE: begin
                // Here, the intstruction is decoded via the decoder module.
                // - the source registers an destination register are addressed,
                // - the function unit is determined, selected and connected via the bus interface.
                state_next = STATE_EXECUTE;
            end

            STATE_EXECUTE: begin
                // Start execution
                fui.ena = 1'b1;

                // Check ouptut reads
                if (fuo.rdy)
                    state_next = STATE_WB;
            end

            STATE_WB: begin
                pc_next = pc + 4;
                state_next = STATE_FETCH;

                // Write back register if no error occured
                if (!fuo.err) begin
                    if (fuo.pc_wb)
                        pc_next = fuo.pc;

                    if (fuo.rd_wb) begin
                        rd_dat = fuo.rd_dat;
                        rd_wb  = 1'b1;
                    end
                end
            end

            default:
                state_next = state;
        endcase
    end
endmodule;
