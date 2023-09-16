// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Main defines of the processor.
 */

`ifndef SECV_PKG
`define SECV_PKG

package secv_pkg;
    parameter int ILEN = 32;                            // Instruction width
    parameter int XLEN = 64;                            // Data width
    parameter int REG_COUNT = 32;                       // Number of general purpose integer registers
    parameter int REG_ADDR_WIDTH = $clog2(REG_COUNT);   // Width to address registers

    /* --- Program counter and programm execution ------------------------------------------------------------------- */
    // parameter int IMEM_ADDR_WIDTH = 8;
    // typedef logic [IMEM_ADDR_WIDTH-1 : 0 ] imem_adr_t;

    /* --- Function units ------------------------------------------------------------------------------------------- */
    typedef enum {
        FUNIT_NONE,     // No operation
        FUNIT_MOV,      // LUI, AUIPC etc.
        FUNIT_ALU,      // ADD, SUB etc.
        FUNIT_BRANCH,   // JAL, JALR, BEQ, BNE etc.
        FUNIT_MEM,      // L, S, FENCE
        FUNIT_SYSTEM,   // ECALL, EBREAK, CSR etc.
        FUNIT_CSR       // CSRRW etc.
//      FUNIT_MUL,
//      FUNIT_DIV
    } funit_t;

    /* --- Decoder -------------------------------------------------------------------------------------------------- */
    // Opcodes
    // Note: not all will be finally supported and therefore uncommented
    typedef enum logic [6:0] {
        OPCODE_LOAD         = 7'b00_000_11,     // Load from memory
//      OPCODE_LOAD_FP      = 7'b00_001_11,     // Load floating point from memory
//      OPCODE_CUSTOM_0     = 7'b00_010_11,     // Custom operation 0
        OPCODE_MISC_MEM     = 7'b00_011_11,     // Misc. memory access (e.g. fence instructions)
        OPCODE_OP_IMM       = 7'b00_100_11,     // Operation immediate
        OPCODE_AUIPC        = 7'b00_101_11,     // Add unsigned immediate to pc
        OPCODE_OP_IMM_32    = 7'b00_110_11,     // Operation immediate 32-bit
//      OPCODE_LEN_48_1     = 7'b00_111_11,     // Length 48-bits

        OPCODE_STORE        = 7'b01_000_11,     // Store to memory
//      OPCODE_STORE_FP     = 7'b01_001_11,     // Store floating point
//      OPCODE_CUSTOM_1     = 7'b01_010_11,     // Custom operation 1
//      OPCODE_AMO          = 7'b01_011_11,     // Atomic memory operation
        OPCODE_OP           = 7'b01_100_11,     // 64-bit register operation
        OPCODE_LUI          = 7'b01_101_11,     // Load upper immediate
        OPCODE_OP_32        = 7'b01_110_11,     // 32-bit register operation
//      OPCODE_LEN_64       = 7'b01_111_11,     // 64-bit length operation (vector op)

//      OPCODE_MADD         = 7'b10_000_11,
//      OPCODE_MSUB         = 7'b10_001_11,
//      OPCODE_NMSUB        = 7'b10_010_11,
//      OPCODE_NMADD        = 7'b10_011_11,
//      OPCODE_OP_FP        = 7'b10_100_11,
//      OPCODE_RESERVED_15  = 7'b10_101_11,
//      OPCODE_CUSTOM_2     = 7'b10_110_11,
//      OPCODE_LEN_48_2     = 7'b10_111_11,

        OPCODE_BRANCH       = 7'b11_000_11,     // Branch (unconditional)
        OPCODE_JALR         = 7'b11_001_11,     // Jump and link (to) register (call)
//      OPCODE_RESERVED_1A  = 7'b11_010_11,
        OPCODE_JAL          = 7'b11_011_11      // Jump and link (call)
//      OPCODE_SYSTEM       = 7'b11_100_11,     // System call
//      OPCODE_RESERVED_1D  = 7'b11_101_11,
//      OPCODE_CUSTOM_3     = 7'b11_110_11,
//      OPCODE_LEN_80       = 7'b11_111_11
    } opcode_t;

    // Opcode = {op, pre}
    // typedef struct packed {
    //    op_t        op;    // Operation
    //    logic [1:0] pre;   // Prefix (2'b11 = 4 byte)
    // } opcode_t;

    // Instruction fields
    typedef logic [6:0] funct7_t;
    typedef logic [2:0] funct3_t;
    typedef logic [4:0] regadr_t;
    typedef logic signed [31:0] imm_t;

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
        inst_r_t  r_type;    // Register
        inst_i_t  i_type;    // Immediate (12' bits)
        inst_s_t  s_type;    // Store
        inst_b_t  b_type;    // Branch
        inst_u_t  u_type;    // Bpper immediate (20'bits)
        inst_j_t  j_type;    // Jump
    } inst_t;

    // funct3 - ALU
    typedef enum logic [$bits(funct3_t)-1:0] {
        FUNCT3_ALU_ADD  = 3'b000,   // Add / sub, funct7[5] == 0 ? ADD : SUB
        FUNCT3_ALU_SLL  = 3'b001,   // Shift left logic
        FUNCT3_ALU_SLT  = 3'b010,   // Set less than
        FUNCT3_ALU_SLTU = 3'b011,   // Set less than (unsigned)
        FUNCT3_ALU_XOR  = 3'b100,   // Logic xor
        FUNCT3_ALU_SRL  = 3'b101,   // Shift right logic / shift right arithmetic, funct7[5] == 0 ? SRL : SRA
        FUNCT3_ALU_OR   = 3'b110,   // Logic or
        FUNCT3_ALU_AND  = 3'b111    // Logic and
    } funct3_alu_t;

    // funct3 - Branch
    typedef enum logic [$bits(funct3_t)-1:0] {
        FUNCT3_BRANCH_BEQ   = 3'b000,   // Branch equal                  ==
        FUNCT3_BRANCH_BNQ   = 3'b001,   // Branch not equal              !=
        //
        FUNCT3_BRANCH_BLT   = 3'b100,   // Branch less than              <
        FUNCT3_BRANCH_BGE   = 3'b101,   // Branch greater equal          >=
        FUNCT3_BRANCH_BLTU  = 3'b110,   // Branch less than usigned      <  (u)
        FUNCT3_BRANCH_BGEU  = 3'b111    // Branch greater equal unsigned >= (u)
    } funct3_branch_t;

    // funct3 - Load
    typedef enum logic [$bits(funct3_t)-1:0] {
        FUNCT3_LOAD_LB  = 3'b000,   // Load byte
        FUNCT3_LOAD_LH  = 3'b001,   // Load half
        FUNCT3_LOAD_LW  = 3'b010,   // Load word
        FUNCT3_LOAD_LD  = 3'b011,   // load double word
        //
        FUNCT3_LOAD_LBU = 3'b100,   // Load byte unsigned
        FUNCT3_LOAD_LHU = 3'b101    // Load half unsigned
    } funct3_load_t;

    // funct3 - Store
    typedef enum logic [$bits(funct3_t)-1:0] {
        FUNCT3_STORE_LB = 3'b000,   // Store byte
        FUNCT3_STORE_LH = 3'b001,   // Store half
        FUNCT3_STORE_LW = 3'b010,   // Store word
        FUNCT3_STORE_LD = 3'b011    // Store double word
    } funct3_store_t;

    // funct3 - Atomic
    // fucnt3 - CSR

    // funct7
    const funct7_t FUNCT7_00h = 7'h00;
    const funct7_t FUNCT7_20h = 7'h20;

    /* --- Special instructions ------------------------------------------------------------------------------------- */
    const inst_t INST_NOP = {25'b0, OPCODE_OP_IMM};     // ADDI 0, 0, $0

    /* --- Decode functions ----------------------------------------------------------------------------------------- */
    // Decodes the opcode of the instruction
    function automatic opcode_t decode_opcode (inst_t inst_i);
        return opcode_t'(inst_i[6:0]);
    endfunction

    // Decode I-immediate (lower 12'bits)
    function automatic imm_t decode_imm_i (inst_t inst);
        return  {{21{inst[31]}}, inst[30:20]};
    endfunction

    // Decode S-immediate (store)
    function automatic imm_t decode_imm_s (inst_t inst);
        return  {{21{inst[31]}}, inst[30:25],  inst[11:7]};
    endfunction

    // Decode B-immediate (branch)
    function automatic imm_t decode_imm_b (inst_t inst);
        return {{20{inst[31]}}, inst[7],  inst[30:25],  inst[11:8], 1'b0 };
    endfunction

    // Decode U-immediate (upper 20'bits)
    function automatic imm_t decode_imm_u (inst_t inst);
        return {inst[31], inst[30:12], 12'b0};
    endfunction

    // Decode J-immediate (jump)
    function automatic imm_t decode_imm_j (inst_t inst);
        return {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
    endfunction

    /* --- ALU ------------------------------------------------------------------------------------------------------ */
    typedef enum bit [15:0] {
        ALU_OP_NONE = 0,

        // Logic
        ALU_OP_AND  = 1 << 1,   // Logical AND
        ALU_OP_OR   = 1 << 2,   // Logical OR
        ALU_OP_XOR  = 1 << 3,   // Logical XOR

        // Arithmetic
        ALU_OP_ADD  = 1 << 4,   // Addition
        ALU_OP_SUB  = 1 << 5,   // Substraction
        ALU_OP_ADDW = 1 << 6,   // Addition (32-bit)
        ALU_OP_SUBW = 1 << 7,  // Substraction (32-bit)

        // Shift
        ALU_OP_SLL  = 1 << 8,   // Shift left logic
        ALU_OP_SRL  = 1 << 9,   // Shift right logic
        ALU_OP_SRA  = 1 << 10,   // Shift right arithmetic (keep sign bit)
        ALU_OP_SLLW = 1 << 11,  // Shift left logic (32-bit)
        ALU_OP_SRLW = 1 << 12,  // Shift right logic (32-bit)
        ALU_OP_SRAW = 1 << 13,  // Shift right arithmetic (keep sign bit, 32-bit)

        // Compares
        ALU_OP_SLT  = 1 << 14,  // set less than
        ALU_OP_SLTU = 1 << 15   // set less than unsigned
    } alu_op_t;
endpackage
`endif
