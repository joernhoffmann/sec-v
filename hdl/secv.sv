// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Main control logic of the SEC-V processor.
 *
 * Todo
 *  [ ] Code improvements
*       [ ] Improve main fsm
 *      [ ] Seperate units (e.g. main fsm, pipeline etc.)
 *      [ ] Introduce more data types (e. g. wishbone, function unit, function unit array)
 *  [ ] Micro-arch improvements
 *      [ ] Implement pipeline
 *          [ ] a) regular pipelin
 *          [ ] b) interleaved multi threading
 *      [ ] Add Out-of-order or superscalar processing
 *      [ ] Add security functions (mem tagging)
 *  [ ] ISA extension
 *      [ ] Add CSR
 *      [ ] Add bit manipulation
 *      [ ] Add crypto
 *  [ ] Testing
 *      [ ] Add unit-tests
 *      [ ] Add formal verification
 *      [ ] Add verilator stuff
 *
 * History
 *  v1.0    - Initial version
 *  v1.1    - Add function unit bus
 *  v1.2    - Add muxer, reduce funit signals
 */
`include "secv_pkg.svh"
import secv_pkg::*;

module secv #(
    parameter int TLEN       = 16,       // Tag size

    parameter int IADR_WIDTH = 8,        // Instruction memory address width
    parameter int DADR_WIDTH = 8,        // Data memory address width
    parameter int TADR_WIDTH = 16,       // Tag memory address width

    parameter int ISEL_WIDTH = ILEN/8,  // Instruction memory byte selection width
    parameter int DSEL_WIDTH = XLEN/8,  // Data memory byte selection width
    parameter int TSEL_WIDTH = TLEN/8   // Tag memory byte selection width
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
    input   logic                       dmem_ack_i,

    // Tag memory
    output logic                        tmem_cyc_o,
    output logic                        tmem_stb_o,
    output logic [TSEL_WIDTH-1 : 0]     tmem_sel_o,
    output logic [TADR_WIDTH-1 : 0]     tmem_adr_o,
    output logic                        tmem_we_o,
    output logic [TLEN-1 : 0]           tmem_dat_o,
    input  logic [TLEN-1 : 0]           tmem_dat_i,
    input  logic                        tmem_ack_i
);
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

    // --- Decoder -------------------------------------------------------------------------------------------------- //
    // General decoder
    inst_t          inst;
    opcode_t        opcode;
    funct3_t        funct3;
    funct7_t        funct7;
    funit_t         funit;
    src1_sel_t      src1_sel;
    src2_sel_t      src2_sel;
    imm_sel_t       imm_sel;
    rd_sel_t        rd_sel;
    pc_sel_t        pc_sel;
    alu_op_sel_t    alu_op_sel;
    logic           dec_err;

    assign inst = ir;
    decoder dec0 (
        .inst_i         (inst),

        // Opcode fields
        .opcode_o       (opcode),
        .funct3_o       (funct3),
        .funct7_o       (funct7),

        // Operands
        .rs1_adr_o      (rs1_adr),
        .rs2_adr_o      (rs2_adr),
        .rd_adr_o       (rd_adr),

        // Function unit
        .funit_o        (funit),
        .alu_op_sel_o   (alu_op_sel),
        .src1_sel_o     (src1_sel),
        .src2_sel_o     (src2_sel),
        .imm_sel_o      (imm_sel),
        .rd_sel_o       (rd_sel),
        .pc_sel_o       (pc_sel),

        // Errors
        .err_o          (dec_err)
    );

    // ALU decoder
    alu_op_t alu_dec_op;
    logic alu_dec_err;
    alu_decoder alu_dec0 (
        .inst_i     (inst),
        .op_o       (alu_dec_op),
        .err_o      (alu_dec_err)
    );

    // ALU operation selection
    alu_op_t alu_op;
    always_comb begin : alu_op_mux
        unique case (alu_op_sel)
            ALU_OP_SEL_DECODER: alu_op = alu_dec_op;
            ALU_OP_SEL_ADD:     alu_op = ALU_OP_ADD;
            default:            alu_op = ALU_OP_NONE;
        endcase
    end

    // MEM decoder
    mem_op_t mem_op;
    logic mem_dec_err;
    mem_decoder mem_dec0 (
        .inst_i     (inst),
        .op_o       (mem_op),
        .err_o      (mem_dec_err)
    );

    // Memory Tagging decoder
    mtag_op_t mtag_op;
    logic mtag_dec_err;
    mtag_decoder mtag_dec0 (
        .inst_i (inst),
        .op_o   (mtag_op),
        .err_o  (mtag_dec_err)
    );

    // Funit operation selection
    funit_op_t funit_op;
    always_comb begin : funit_op_mux
        unique case (funit)
            FUNIT_NONE  : funit_op = '0;
            FUNIT_ALU   : funit_op = alu_op;
            FUNIT_MEM   : funit_op = mem_op;
            FUNIT_MTAG  : funit_op = mtag_op;
            default     : funit_op = '0;
        endcase
    end

    // --- Internal units ------------------------------------------------------------------------------------------- //
    // Branch decision unit
    logic brn_take, brn_err;
    branch brn0 (
        .funct3_i   (funct3),
        .rs1_i      (rs1_dat),
        .rs2_i      (rs2_dat),
        .take_o     (brn_take),
        .err_o      (brn_err)
    );


    // --- Function units ------------------------------------------------------------------------------------------- //
    // Arithmetic-logic unit
    alu alu0 (
        .fu_i (funit_in_bus[FUNIT_ALU]),
        .fu_o (funit_out_bus[FUNIT_ALU])
    );

    logic [DADR_WIDTH-1 : 0] tag_err_adr;
    // Data memory inteface unit
    mem  #(
        .ADR_WIDTH(DADR_WIDTH)
    ) mem0 (
        // Control
        .fu_i (funit_in_bus[FUNIT_MEM]),
        .fu_o (funit_out_bus[FUNIT_MEM]),

        .tag_err_adr_o(tag_err_adr),

        // Wishbone data memory interface
        .dmem_cyc_o (dmem_cyc_o),
        .dmem_stb_o (dmem_stb_o),
        .dmem_sel_o (dmem_sel_o),
        .dmem_adr_o (dmem_adr_o),
        .dmem_we_o  (dmem_we_o),
        .dmem_dat_o (dmem_dat_o),
        .dmem_dat_i (dmem_dat_i),
        .dmem_ack_i (dmem_ack_i),

        // Wishbone tag memory interface
        .tmem_cyc_o (tmem_cyc_o_bus[FUNIT_MEM]),
        .tmem_stb_o (tmem_stb_o_bus[FUNIT_MEM]),
        .tmem_sel_o (tmem_sel_o_bus[FUNIT_MEM]),
        .tmem_adr_o (tmem_adr_o_bus[FUNIT_MEM]),
        .tmem_dat_i (tmem_dat_i),
        .tmem_ack_i (tmem_ack_i_bus[FUNIT_MEM])
    );

    mtag #(
        .ADR_WIDTH(DADR_WIDTH)
    ) mtag0 (
        .fu_i      (funit_in_bus[FUNIT_MTAG]),
        .fu_o      (funit_out_bus[FUNIT_MTAG]),

        // Wishbone tag memory interface
        .tmem_cyc_o (tmem_cyc_o_bus[FUNIT_MTAG]),
        .tmem_stb_o (tmem_stb_o_bus[FUNIT_MTAG]),
        .tmem_sel_o (tmem_sel_o_bus[FUNIT_MTAG]),
        .tmem_adr_o (tmem_adr_o_bus[FUNIT_MTAG]),
        .tmem_we_o  (tmem_we_o),
        .tmem_dat_o (tmem_dat_o),
        .tmem_ack_i (tmem_ack_i_bus[FUNIT_MTAG])
    );

    // Function unit bus
    funit_in_t  funit_in_bus[FUNIT_COUNT];
    funit_out_t funit_out_bus[FUNIT_COUNT];
    funit_in_t  funit_in;
    funit_out_t funit_out;

    // Tag memory bus
    logic                   tmem_cyc_o_bus[FUNIT_COUNT];
    logic                   tmem_stb_o_bus[FUNIT_COUNT];
    logic [TSEL_WIDTH-1: 0] tmem_sel_o_bus[FUNIT_COUNT];
    logic [TADR_WIDTH-1: 0] tmem_adr_o_bus[FUNIT_COUNT];
    logic                   tmem_ack_i_bus[FUNIT_COUNT];

    // I/O of selected function unit
    always_comb begin
        funit_in_bus[funit] = funit_in;
        tmem_ack_i_bus[funit] = tmem_ack_i;
    end
    assign funit_out = funit_out_bus[funit];
    assign tmem_cyc_o = tmem_cyc_o_bus[funit];
    assign tmem_stb_o = tmem_stb_o_bus[funit];
    assign tmem_sel_o = tmem_sel_o_bus[funit];
    assign tmem_adr_o = tmem_adr_o_bus[funit];

    // --- MUXer ---------------------------------------------------------------------------------------------------- //
    // Source 1 selection
    logic [XLEN-1:0] src1;
    always_comb begin: src1_mux
        unique case (src1_sel)
            SRC1_SEL_0          : src1 = '0;
            SRC1_SEL_RS1        : src1 = rs1_dat;
            SRC1_SEL_RS1_IMM    : src1 = rs1_dat + imm;
            SRC1_SEL_PC         : src1 = pc;
            default             : src1 = '0;
        endcase
    end

    // Source 2 selection
    logic [XLEN-1:0] src2;
    always_comb begin: src2_mux
        unique case (src2_sel)
            SRC2_SEL_0   : src2 = '0;
            SRC2_SEL_RS2 : src2 = rs2_dat;
            SRC2_SEL_IMM : src2 = imm;
            default      : src2 = '0;
        endcase
    end

    // Immediate muxer
    imm_t imm;
    always_comb begin : imm_mux
        unique case (imm_sel)
            IMM_SEL_0 : imm = '0;
            IMM_SEL_I : imm = decode_imm_i(inst);
            IMM_SEL_S : imm = decode_imm_s(inst);
            IMM_SEL_B : imm = decode_imm_b(inst);
            IMM_SEL_U : imm = decode_imm_u(inst);
            IMM_SEL_J : imm = decode_imm_j(inst);
            default   : imm = '0;
        endcase
    end

    // Destination register update (wb-stage)
    logic [XLEN-1:0] wbstage_rd_dat;
    always_comb begin: rd_mux
        unique case (rd_sel)
            RD_SEL_NONE  : wbstage_rd_dat = '0;
            RD_SEL_FUNIT : wbstage_rd_dat = funit_out.res;
            RD_SEL_IMM   : wbstage_rd_dat = imm;
            RD_SEL_NXTPC : wbstage_rd_dat = nxtpc;
            default      : wbstage_rd_dat = '0;
        endcase
    end

    // Program counter update (wb-stage)
    logic [XLEN-1:0] wbstage_pc;
    always_comb begin: wbstage_pc_mux
        unique case (pc_sel)
            PC_SEL_NXTPC  : wbstage_pc = nxtpc;             // Write-back next pc
            PC_SEL_FUNIT  : wbstage_pc = funit_out.res;     // Write-back funit output
            PC_SEL_BRANCH : wbstage_pc = brn_target;        // Write-back branch target
            default       : wbstage_pc = nxtpc;
        endcase
    end

    // -------------------------------------------------------------------------------------------------------------- //
    // Main state machine
    // -------------------------------------------------------------------------------------------------------------- //
    // FSM register
    state_t state, state_next;
    logic [XLEN-1:0] pc, pc_next;       // Program counter register
    logic [ILEN-1:0] ir, ir_next;       // Instruction register
    logic [XLEN-1:0] nxtpc;             // Next pc

    assign nxtpc = pc + 4;
    always_ff @( posedge clk_i) begin: fsm_regs
        if (rst_i) begin
            state <= STATE_IDLE;
            pc    <= '0;
            ir    <= INST_NOP;
        end

        else begin
            state <= state_next;
            pc    <= pc_next;
            ir    <= ir_next;
        end
    end

    // Branch target computation
    // If branch, take address from funit else progress with next address
    logic [XLEN-1:0] brn_target;
    assign brn_target = brn_take ? funit_out.res : nxtpc;

    // --- Next state logic ----------------------------------------------------------------------------------------- //
    always_comb begin : main_fsm
        // Default state transition
        state_next = state;
        pc_next = pc;
        ir_next = ir;

        // Prevent latches
        imem_cyc_o = 1'b0;
        imem_stb_o = 1'b0;
        imem_adr_o =   '0;
        imem_sel_o =   '0;
        rd_dat     =   '0;
        rd_wb      = 1'b0;

        // Function unit input
        funit_in = funit_in_default();
        funit_in.ena  = 1'b0;
        funit_in.op   = funit_op;
        funit_in.src1 = src1;
        funit_in.src2 = src2;

        // State transistion
        unique case (state)
            STATE_IDLE: begin
                state_next = STATE_FETCH;
            end

            STATE_FETCH: begin
                // Access instruction memory
                imem_cyc_o = 1'b1;
                imem_stb_o = 1'b1;
                imem_sel_o =   '1;
                imem_adr_o = pc[IADR_WIDTH-1 : 0];

                if (imem_ack_i) begin
                    ir_next = imem_dat_i;
                    state_next = STATE_DECODE;
                end
            end

            STATE_DECODE: begin
                // Here, the intstruction is decoded. Therefore,
                // (1) the source and destination register are addressed
                // (2) the immediate, if any, is decoded
                // (3) the function unit is determined, selected and connected via the bus interface.
                state_next = STATE_EXECUTE;
            end

            STATE_EXECUTE: begin
                // Start execution
                funit_in.ena = 1'b1;

                // Check if unit is ready
                if (funit_out.rdy || funit == FUNIT_NONE)
                    state_next = STATE_WB;
            end

            STATE_WB: begin
                funit_in.ena = 1'b1;
                rd_dat     = wbstage_rd_dat;
                pc_next    = wbstage_pc;
                state_next = STATE_FETCH;

                // Enable destination register update
                unique case (rd_sel)
                    RD_SEL_NONE  : rd_wb = 1'b0;
                    RD_SEL_FUNIT : rd_wb = !funit_out.err;
                    RD_SEL_IMM   : rd_wb = 1'b1;
                    RD_SEL_NXTPC : rd_wb = 1'b1;
                    default      : rd_wb = 1'b0;
                endcase

                // Check pc update from funit
                if (pc_sel == PC_SEL_FUNIT)
                    pc_next = funit_out.err ? nxtpc : wbstage_pc;
            end

            default:
                state_next = state;
        endcase
    end
endmodule
