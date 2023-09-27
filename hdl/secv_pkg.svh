// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Main defines for the SEC-V processor.
 *
 * Todo
 *  [ ] Cleanup and reorder
 *  [ ] Add unit test
 *
 * History
 *  v1.0    - Initial version
 */

`ifndef SECV_PKG
`define SECV_PKG

package secv_pkg;
    parameter int ILEN = 32;                            // Instruction width
    parameter int XLEN = 64;                            // Data width
    parameter int REG_COUNT = 32;                       // Number of general purpose integer registers
    parameter int REG_ADDR_WIDTH = $clog2(REG_COUNT);   // Width to address registers

    // -------------------------------------------------------------------------------------------------------------- //
    // Instruction
    // -------------------------------------------------------------------------------------------------------------- //
    // Opcodes
    typedef enum logic [6:0] {
        OPCODE_LOAD         = 7'b00_000_11,     // Load from memory
        OPCODE_MISC_MEM     = 7'b00_011_11,     // Misc. memory access (e.g. fence instructions)
        OPCODE_OP_IMM       = 7'b00_100_11,     // Operation immediate
        OPCODE_AUIPC        = 7'b00_101_11,     // Add unsigned immediate to pc
        OPCODE_OP_IMM_32    = 7'b00_110_11,     // Operation immediate 32-bit

        OPCODE_STORE        = 7'b01_000_11,     // Store to memory
        OPCODE_OP           = 7'b01_100_11,     // 64-bit register operation
        OPCODE_LUI          = 7'b01_101_11,     // Load upper immediate
        OPCODE_OP_32        = 7'b01_110_11,     // 32-bit register operation

        OPCODE_BRANCH       = 7'b11_000_11,     // Branch (unconditional)
        OPCODE_JALR         = 7'b11_001_11,     // Jump and link (to) register (call)
        OPCODE_JAL          = 7'b11_011_11      // Jump and link (call)
    } opcode_t;

    // Instruction fields
    typedef logic [6:0] funct7_t;
    typedef logic [2:0] funct3_t;
    typedef logic [4:0] regadr_t;
    typedef logic signed [XLEN-1:0] imm_t;

    // Instruction formats
    typedef struct packed {funct7_t funct7;                                 regadr_t rs2;   regadr_t rs1;   funct3_t funct3;    regadr_t rd;                                opcode_t opcode;} inst_r_t;
    typedef struct packed {logic [11: 0] imm_11_0;                                          regadr_t rs1;   funct3_t funct3;    regadr_t rd;                                opcode_t opcode;} inst_i_t;
    typedef struct packed {logic [11: 5] imm_11_5;  logic [ 4:0] shamt;                     regadr_t rs1;   funct3_t funct3;    regadr_t rd;                                opcode_t opcode;} inst_i_shft_t;
    typedef struct packed {logic [11: 5] imm_11_5;                          regadr_t rs2;   regadr_t rs1;   funct3_t funct3;    logic [4:0] imm_4_0;                        opcode_t opcode;} inst_s_t;
    typedef struct packed {logic [12:12] imm_12;    logic [10:5] imm_10_5;  regadr_t rs2;   regadr_t rs1;   funct3_t funct3;    logic [4:1] imm_4_1; logic [11:11] imm_11;  opcode_t opcode;} inst_b_t;
    typedef struct packed {logic [31:12] imm_31_12;                                                                             regadr_t rd;                                opcode_t opcode;} inst_u_t;
    typedef struct packed {logic [20:20] imm_20;    logic [10:1] imm_10_1;  logic [11:11]   imm_11; logic [19:12] imm_19_12;    regadr_t rd;                                opcode_t opcode;} inst_j_t;

    // Instruction type
    typedef union packed {
        inst_r_t  r_type;   // Register
        inst_i_t  i_type;   // Immediate (12' bits)
        inst_s_t  s_type;   // Store
        inst_b_t  b_type;   // Branch
        inst_u_t  u_type;   // Upper immediate (20'bits)
        inst_j_t  j_type;   // Jump
    } inst_t;

    // --- funct3 --------------------------------------------------------------------------------------------------- //
    // funct3 - ALU
    typedef enum logic [2:0] {
        FUNCT3_ALU_ADD      = 3'b000,   // Add ? sub, funct7[5] == 0 ? ADD : SUB
        FUNCT3_ALU_SLL      = 3'b001,   // Shift left logic
        FUNCT3_ALU_SLT      = 3'b010,   // Set less than
        FUNCT3_ALU_SLTU     = 3'b011,   // Set less than (unsigned)
        FUNCT3_ALU_XOR      = 3'b100,   // Logic xor
        FUNCT3_ALU_SRL      = 3'b101,   // Shift right logic ? shift right arithmetic, funct7[5] == 0 ? SRL : SRA
        FUNCT3_ALU_OR       = 3'b110,   // Logic or
        FUNCT3_ALU_AND      = 3'b111    // Logic and
    } funct3_alu_t;

    // funct3 - Branch
    typedef enum logic [2:0] {
        FUNCT3_BRANCH_BEQ   = 3'b000,   // Branch equal                  a == b
        FUNCT3_BRANCH_BNE   = 3'b001,   // Branch not equal              a != b
        // .. //
        FUNCT3_BRANCH_BLT   = 3'b100,   // Branch less than              a <  b
        FUNCT3_BRANCH_BGE   = 3'b101,   // Branch greater equal          a >= b
        FUNCT3_BRANCH_BLTU  = 3'b110,   // Branch less than usigned      a <  b (u)
        FUNCT3_BRANCH_BGEU  = 3'b111    // Branch greater equal unsigned a >= b (u)
    } funct3_branch_t;

    // funct3 - Load
    typedef enum logic [2:0] {
        FUNCT3_LOAD_LB      = 3'b000,   // Load byte (sign extended)
        FUNCT3_LOAD_LH      = 3'b001,   // Load half (sign extended)
        FUNCT3_LOAD_LW      = 3'b010,   // Load word (sign extended)
        FUNCT3_LOAD_LD      = 3'b011,   // load double word
        // .. //
        FUNCT3_LOAD_LBU     = 3'b100,   // Load byte unsigned (zero extended)
        FUNCT3_LOAD_LHU     = 3'b101,   // Load half unsigned (zero extended)
        FUNCT3_LOAD_LWU     = 3'b110    // Load word unsigned (zero extended)
    } funct3_load_t;

    // funct3 - Store
    typedef enum logic [2:0] {
        FUNCT3_STORE_SB     = 3'b000,   // Store byte
        FUNCT3_STORE_SH     = 3'b001,   // Store half
        FUNCT3_STORE_SW     = 3'b010,   // Store word
        FUNCT3_STORE_SD     = 3'b011    // Store double word
    } funct3_store_t;

    // funct7
    localparam funct7_t FUNCT7_00h = 7'h00;
    localparam funct7_t FUNCT7_20h = 7'h20;
    localparam inst_t   INST_NOP   = {25'b0, OPCODE_OP_IMM};

    // -------------------------------------------------------------------------------------------------------------- //
    // Functions
    // -------------------------------------------------------------------------------------------------------------- //
    // --- Decode functions ----------------------------------------------------------------------------------------- //
    // Decodes the opcode of the instruction
    function automatic opcode_t decode_opcode (inst_t inst_i);
        return opcode_t'(inst_i[6:0]);
    endfunction

    // Decode I-immediate (lower 12'bits)
    function automatic imm_t decode_imm_i (inst_t inst);
        //      {         sext[11]},      [10: 0]}
        return  {{XLEN-11{inst[31]}}, inst[30:20]};
    endfunction

    // Decode S-immediate (store)
    function automatic imm_t decode_imm_s (inst_t inst);
        //     {         sext[11],       [10: 5],       [4:0]}
        return {{XLEN-11{inst[31]}}, inst[30:25],  inst[11:7]};
    endfunction

    // Decode B-immediate (branch)
    function automatic imm_t decode_imm_b (inst_t inst);
        //     {         sext[12],      [11],      [10: 5],       [4:1],   [0]}
        return {{XLEN-12{inst[31]}}, inst[7],  inst[30:25],  inst[11:8], 1'b0 };
    endfunction

    // Decode U-immediate (upper 20'bits)
    function automatic imm_t decode_imm_u (inst_t inst);
        //     {         sext[31],       [30:12],   [11:0]}
        return {{XLEN-31{inst[31]}}, inst[30:12],   12'b0};
    endfunction

    // Decode J-immediate (jump)
    function automatic imm_t decode_imm_j (inst_t inst);
        //     {         sext[20],      [19:12],     [11],      [10:1],    [0]}
        return {{XLEN-20{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
    endfunction

    // --- Signum extension function -------------------------------------------------------------------------------- //
    // Sign extends the 8-bit byte operand to XLEN bits
    function automatic [XLEN-1:0] sext8(logic [7:0] operand);
        return {{XLEN-8{operand[7]}}, operand[7:0]};
    endfunction

    // Sign extends 12-bit operand (immediate usually) to XLEN bits
    function automatic [XLEN-1:0] sext12(logic [11:0] operand);
        return {{XLEN-12{operand[11]}}, operand[11:0]};
    endfunction

    // Sign extends the 16-bit half operand to XLEN bits
    function automatic [XLEN-1:0] sext16(logic [15:0] operand);
        return {{XLEN-16{operand[15]}}, operand[15:0]};
    endfunction

    // Sign extends the 32-bit word operand to XLEN bits
    function automatic [XLEN-1:0] sext32(logic [31:0] operand);
        return {{XLEN-32{operand[31]}}, operand[31:0]};
    endfunction

    // -------------------------------------------------------------------------------------------------------------- //
    // Function units
    // -------------------------------------------------------------------------------------------------------------- //
    typedef enum int {
        FUNIT_NONE,     // No function unit
        FUNIT_ALU,      // Arithmetic logic unit (ADD, SUB etc.)
        FUNIT_MEM,      // Memory unit           (Loads, Stores, FENCE etc.)
        FUNIT_COUNT
    } funit_t;

    // Error codes (not yet used)
    typedef enum {
        FUNIT_ERROR_NONE = 0,
        FUNIT_ERROR_INVALID_OPCODE,
        FUNIT_ERROR_NOT_IMPLEMENTED
    } funit_error_t;

    // --- Function unit operations --------------------------------------------------------------------------------- //
    // ALU
    typedef enum bit [3:0] {
        ALU_OP_NONE = 0,

        // Logic
        ALU_OP_AND,
        ALU_OP_OR,
        ALU_OP_XOR,

        // Arithmetic
        ALU_OP_ADD,
        ALU_OP_SUB,
        ALU_OP_ADDW,
        ALU_OP_SUBW,

        // Shifts
        ALU_OP_SLL,
        ALU_OP_SRL,
        ALU_OP_SRA,
        ALU_OP_SLLW,
        ALU_OP_SRLW,
        ALU_OP_SRAW,

        // Compares
        ALU_OP_SLT,
        ALU_OP_SLTU
    } alu_op_t;

    // Mem
    typedef enum bit [3:0] {
        MEM_OP_NONE = 0,

        // Loads
        MEM_OP_LB,
        MEM_OP_LH,
        MEM_OP_LW,
        MEM_OP_LD,
        MEM_OP_LBU,
        MEM_OP_LHU,
        MEM_OP_LWU,

        // Stores
        MEM_OP_SB,
        MEM_OP_SH,
        MEM_OP_SW,
        MEM_OP_SD
    } mem_op_t;

    // --- Function unit interface ---------------------------------------------------------------------------------- //
    // Funit operation (input)
    typedef union packed {
        alu_op_t alu;
        mem_op_t mem;
    } funit_op_t;

    // Source 1 selection
    typedef enum logic [1:0] {
        SRC1_SEL_0,          // Value '0'
        SRC1_SEL_RS1,        // Register source 1
        SRC1_SEL_PC          // Current program counter
    } src1_sel_t;

    // Source 2 selection
    typedef enum logic [1:0] {
        SRC2_SEL_0,          // Value '0'
        SRC2_SEL_RS2,        // Register source 2
        SRC2_SEL_IMM         // Immediate
    } src2_sel_t;

    // Immediate type selection
    typedef enum logic [2:0]{
        IMM_SEL_0,
        IMM_SEL_I,
        IMM_SEL_S,
        IMM_SEL_B,
        IMM_SEL_U,
        IMM_SEL_J
    } imm_sel_t;

    // Destination register selection
    typedef enum logic [1:0] {
        RD_SEL_NONE,        // No input
        RD_SEL_FUNIT,       // Function unit
        RD_SEL_IMM,         // Immediate
        RD_SEL_NXTPC        // Next pc
    } rd_sel_t;

    // Program counter selection
    typedef enum logic [1:0] {
        PC_SEL_NXTPC,       // Next pc
        PC_SEL_FUNIT,       // Function unit
        PC_SEL_BRANCH       // Branch decision unit
     } pc_sel_t;

    // Function unit input interface
    typedef struct packed {
        // Control
        logic               ena;    // Enable unit (input is valid)

        // Payload
        funit_op_t          op;     // Operation
        logic   [XLEN-1:0]  src1;   // 1st source operand
        logic   [XLEN-1:0]  src2;   // 2nd source operand
    } funit_in_t;

    // Function unit output interface
    typedef struct packed {
        // Control
        logic               rdy;    // Unit ready, operation completed
        logic               err;    // Error occured

        // Payload
        logic   [XLEN-1:0]  res;    // Result
        logic               res_wb; // Result is valid (write back)
    } funit_out_t;

    // FU input defaults
    function automatic funit_in_t funit_in_default();
        funit_in_t fu;
        fu.ena      = 1'b0;
        fu.op       =  'b0;
        fu.src1     =  'b0;
        fu.src2     =  'b0;
        return fu;
    endfunction

    // FU output defaults
    function automatic funit_out_t funit_out_default();
        funit_out_t fu;
        fu.rdy      = 1'b0;
        fu.err      = 1'b0;
        fu.res      =  'b0;
        fu.res_wb   = 1'b0;
        return fu;
    endfunction
endpackage
`endif
