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
 *      [ ] Trap, fault, exception handling
 *      [ ] Implement pipeline
 *          [ ] a) regular pipelin
 *          [ ] b) interleaved multi threading
 *      [ ] Add Out-of-order or superscalar processing (for a variant)
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
`include "csr_pkg.svh"
import secv_pkg::*;
import csr_pkg::*;

module secv #(
    parameter int HARTS      = 1,
    parameter int TLEN       = 16,       // Tag size
    /* Size of granules as amount of bits to shift the memory address to the right
     * Shift in bits    | actual granule size in byte
     * 0                | 1
     * 1                | 2
     * 2                | 4
     * 3                | 8
     * n                | 2^n
     */
    parameter int GRANULARITY = 2,

    parameter int IADR_WIDTH = 8,        // Instruction memory address width
    parameter int DADR_WIDTH = 8,        // Data memory address width
    // Tag memory address width
    parameter int TADR_WIDTH = DADR_WIDTH-GRANULARITY,

    parameter int ISEL_WIDTH = ILEN/8,  // Instruction memory byte selection width
    parameter int DSEL_WIDTH = XLEN/8   // Data memory byte selection width
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

    // --- Tag memory ----------------------------------------------------------------------------------------------- //
    logic                       tmem_re;
    logic [TADR_WIDTH-1 : 0]    tmem_radr;
    logic [TLEN-1 : 0]          tmem_rdat;
    logic                       tmem_rack;

    logic                       tmem_we;
    logic [TADR_WIDTH-1 : 0]    tmem_wadr;
    logic [TLEN-1 : 0]          tmem_wdat;
    logic                       tmem_wack;

    mtag_mem #(
        .ADR_WIDTH(TADR_WIDTH),
        .DAT_WIDTH(TLEN),
        .RESET_MEM(1)
    ) mtag_mem0 (
        .clk_i  (clk_i),
        .rst_i  (rst_i),

        .re_i   (tmem_re),
        .radr_i (tmem_radr),
        .dat_o  (tmem_rdat),
        .rack_o (tmem_rack),

        .we_i   (tmem_we),
        .wadr_i (tmem_wadr),
        .dat_i  (tmem_wdat),
        .wack_o (tmem_wack)
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

    // MEM funit decoder
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
    logic brn_take, brn_dec_err;
    branch brn0 (
        .funct3_i   (funct3),
        .rs1_i      (rs1_dat),
        .rs2_i      (rs2_dat),
        .take_o     (brn_take),
        .err_o      (brn_dec_err)
    );

    // Random number generator

    logic [31:0] rnd;
    lfsr_rng lfsr_rng0 (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .lfsr_o(rnd)
    );

    // --- Function units ------------------------------------------------------------------------------------------- //
    // Arithmetic-logic unit
    alu alu0 (
        .fu_i (funit_in_bus[FUNIT_ALU]),
        .fu_o (funit_out_bus[FUNIT_ALU])
    );

    // Data memory inteface unit
    mem  #(
        .HARTS(HARTS),
        .ADR_WIDTH(DADR_WIDTH)
        .TLEN(TLEN),
        .GRANULARITY(GRANULARITY)
    ) mem0 (
        // Control
        .fu_i (funit_in_bus[FUNIT_MEM]),
        .fu_o (funit_out_bus[FUNIT_MEM]),

        .hartid_i   (0),

        // Wishbone data memory interface
        .dmem_cyc_o (dmem_cyc_o),
        .dmem_stb_o (dmem_stb_o),
        .dmem_sel_o (dmem_sel_o),
        .dmem_adr_o (dmem_adr_o),
        .dmem_we_o  (dmem_we_o),
        .dmem_dat_o (dmem_dat_o),
        .dmem_dat_i (dmem_dat_i),
        .dmem_ack_i (dmem_ack_i),

        // Tag memory
        .tmem_re_o  (tmem_re),
        .tmem_adr_o (tmem_radr),
        .tmem_dat_i (tmem_rdat),
        .tmem_ack_i (tmem_rack)
    );

    mtag #(
        .HARTS(HARTS),
        .TLEN(TLEN),
        .GRANULARITY(GRANULARITY),
        .ADR_WIDTH(DADR_WIDTH)
    ) mtag0 (
        .fu_i       (funit_in_bus[FUNIT_MTAG]),
        .fu_o       (funit_out_bus[FUNIT_MTAG]),

        .rnd_i      (rnd),

        .tmem_we_o  (tmem_we),
        .tmem_adr_o (tmem_wadr),
        .tmem_dat_o (tmem_wdat),
        .tmem_ack_i (tmem_wack)
    );

    // Control and status register unit
    logic [XLEN-1:0] trap_adr, trap_vec;
    logic mret;
    logic ex;
    ex_cause_t ex_cause;

    csr csr0 (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        // Funit Interface
        .fu_i           (funit_in_bus[FUNIT_CSR]),
        .fu_o           (funit_out_bus[FUNIT_CSR]),

        // Control
        .rd_zero_i      (rd_adr == '0),
        .rs1_zero_i     (rs1_adr == '0),
        .funct_i        (funct3),

        // Trap
        .trap_pc_i      (pc),
        .trap_adr_i     (trap_adr),
        .trap_vec_o     (trap_vec),
        .mret_i         (mret),

        // Exceptions
        .ex_i           (ex),
        .ex_cause_i     (ex_cause)
    );

    // Function unit bus
    funit_in_t  funit_in_bus[FUNIT_COUNT];
    funit_out_t funit_out_bus[FUNIT_COUNT];
    funit_in_t  funit_in;
    funit_out_t funit_out;

    // I/O of selected function unit
    always_comb begin
        funit_in_bus[funit] = funit_in;
    end
    assign funit_out = funit_out_bus[funit];

    // --- Exception handling --------------------------------------------------------------------------------------- //
    function automatic ex_cause_t to_ex_cause(ecode_t ecode);
        case (ecode)
            ECODE_OP_INVALID                : return EX_CAUSE_INST_ILLEGAL;
            ECODE_LOAD_ACCESS_FAULT         : return EX_CAUSE_LOAD_ACCESS_FAULT;
            ECODE_LOAD_ADDRESS_MISALIGNED   : return EX_CAUSE_LOAD_ADDRESS_MISALIGNED;
            ECODE_STORE_ACCESS_FAULT        : return EX_CAUSE_STORE_ACCESS_FAULT;
            ECODE_STORE_ADDRESS_MISALIGNED  : return EX_CAUSE_STORE_ADDRESS_MISALIGNED;
            ECODE_MTAG_COLOR_INVLD          : return EX_CAUSE_MTAG_COLOR_INVLD;
            ECODE_MTAG_HART_INVLD           : return EX_CAUSE_MTAG_HART_INVLD;
            default: return EX_CAUSE_INST_MISALIGNED;
        endcase;
    endfunction

    assign ex = pc_align_err | dec_err |
        funit == FUNIT_ALU && alu_dec_err |
        funit == FUNIT_ALU && brn_dec_err |
        funit == FUNIT_MEM && mem_dec_err |
        funit_out.err;

    logic funit_err;
    assign funit_err = funit_out.err;

    always_comb begin : ex_cause_impl
        ex_cause = EX_CAUSE_INST_MISALIGNED;

        if (pc_align_err)
            ex_cause = EX_CAUSE_INST_MISALIGNED;

        else if (dec_err || mem_dec_err || alu_dec_err || brn_dec_err || mtag_dec_err)
            ex_cause = EX_CAUSE_INST_ILLEGAL;

        else if (funit_err) begin
            ex_cause = to_ex_cause(funit_out.ecode);
        end
    end

    // --- MUXer ---------------------------------------------------------------------------------------------------- //
    // Source 1 selection
    logic [XLEN-1:0] src1;
    always_comb begin: src1_mux
        unique case (src1_sel)
            SRC1_SEL_0          : src1 = '0;
            SRC1_SEL_RS1        : src1 = rs1_dat;
            SRC1_SEL_RS1_IMM    : src1 = rs1_dat + imm;
            SRC1_SEL_PC         : src1 = pc;
            SRC1_SEL_UIMM       : src1 = {(XLEN - REG_ADR)'(0), rs1_adr};
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
            RD_SEL_NXTPC : wbstage_rd_dat = pc_inc;
            default      : wbstage_rd_dat = '0;
        endcase
    end

    // Program counter update (wb-stage)
    logic [XLEN-1:0] wbstage_pc;
    always_comb begin: wbstage_pc_mux
        unique case (pc_sel)
            PC_SEL_NXTPC  : wbstage_pc = pc_inc;            // Write-back next pc (pc + 4)
            PC_SEL_FUNIT  : wbstage_pc = funit_out.res;     // Write-back funit output
            PC_SEL_BRANCH : wbstage_pc = pc_target;         // Write-back branch target
            default       : wbstage_pc = pc_inc;
        endcase
    end

    // -------------------------------------------------------------------------------------------------------------- //
    // Main state machine
    // -------------------------------------------------------------------------------------------------------------- //
    // FSM register
    state_t state, state_next;
    logic [XLEN-1:0] pc, pc_next;       // Program counter register
    logic [ILEN-1:0] ir, ir_next;       // Instruction register
    logic [XLEN-1:0] pc_inc;            // Next PC (PC + 4)
    logic pc_align_err;

    // PC computations
    assign pc_inc = pc + 4;
    assign pc_align_err = pc[1:0] != 0; // Must be 4 byte aligned

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
    logic [XLEN-1:0] pc_target;
    assign pc_target = brn_take ? funit_out.res : pc_inc;

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
                    pc_next = funit_out.err ? pc_inc : wbstage_pc;
            end

            default:
                state_next = state;
        endcase
    end
endmodule
