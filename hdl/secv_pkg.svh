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
    parameter int ILEN = 32;                        // Instruction width
    parameter int XLEN = 64;                        // Data width
    parameter int REG_COUNT = 32;                   // Number of general purpose integer registers
    parameter int REG_ADR   = $clog2(REG_COUNT);    // Width to address registers

    // -------------------------------------------------------------------------------------------------------------- //
    // Modes / States etc.
    // -------------------------------------------------------------------------------------------------------------- //
    // States
    typedef enum logic [3:0] {
        STATE_IDLE,
        STATE_FETCH,
        STATE_DECODE,
        STATE_EXECUTE,
        STATE_WB
    } state_t;

    // Privilege modes
    typedef enum logic {
        PRIV_MODE_USER,         // User mode (least privilge)
        PRIV_MODE_MACHINE       // Machine mode (highes privilege)
    } priv_mode_t;

    // -------------------------------------------------------------------------------------------------------------- //
    // Instruction
    // -------------------------------------------------------------------------------------------------------------- //
    // Opcodes
    typedef enum logic [6:0] {
        OPCODE_LOAD         = 7'b00_000_11,     // Load from memory
        OPCODE_CUSTOM_0     = 7'b00_010_11,     // Custom opcoide (memtag)

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
        OPCODE_JAL          = 7'b11_011_11,     // Jump and link (call)
        OPCODE_SYSTEM       = 7'b11_100_11      // Ecall, Ebreak, CSRxx
    } opcode_t;

    // Instruction fields
    typedef logic [6:0] funct7_t;
    typedef logic [2:0] funct3_t;
    typedef logic [REG_ADR-1:0] regadr_t;
    typedef logic signed [XLEN-1:0] imm_t;

    // Instruction formats
    typedef struct packed {
        funct7_t        funct7;
        regadr_t        rs2;
        regadr_t        rs1;
        funct3_t        funct3;
        regadr_t        rd;
        opcode_t        opcode;
    } inst_r_t;

    typedef struct packed {
        logic [11: 0]   imm_11_0;
        regadr_t        rs1;
        funct3_t        funct3;
        regadr_t        rd;
        opcode_t        opcode;
    } inst_i_t;

    typedef struct packed {
        logic [11: 5]   imm_11_5;
        logic [ 4: 0]   shamt;
        regadr_t        rs1;
        funct3_t        funct3;
        regadr_t        rd;
        opcode_t        opcode;
    } inst_i_shft_t;

    typedef struct packed {
        logic [11: 5]   imm_11_5;
        regadr_t        rs2;
        regadr_t        rs1;
        funct3_t        funct3;
        logic [4: 0]    imm_4_0;
        opcode_t opcode;
    } inst_s_t;

    typedef struct packed {
        logic [12:12]   imm_12;
        logic [10: 5]   imm_10_5;
        regadr_t        rs2;
        regadr_t        rs1;
        funct3_t        funct3;
        logic [4: 1]    imm_4_1;
        logic [11:11]   imm_11;
        opcode_t        opcode;
    } inst_b_t;

    typedef struct packed {
        logic [31:12] imm_31_12;
        regadr_t rd;
        opcode_t opcode;
    } inst_u_t;

    typedef struct packed {
        logic [20:20]   imm_20;
        logic [10:1]    imm_10_1;
        logic [11:11]   imm_11;
        logic [19:12]   imm_19_12;
        regadr_t        rd;
        opcode_t        opcode;
    } inst_j_t;

    // Instruction type
    typedef union packed {
        inst_r_t        r_type;         // Register
        inst_i_t        i_type;         // Immediate (12' bits)
        inst_s_t        s_type;         // Store
        inst_b_t        b_type;         // Branch
        inst_u_t        u_type;         // Upper immediate (20'bits)
        inst_j_t        j_type;         // Jump
    } inst_t;

    // --- funct3 --------------------------------------------------------------------------------------------------- //
    // funct3 - MTAG
    typedef enum logic [2:0] {
        FUNCT3_MTAG_TADR                // Tag memory address
    } funct3_mtag_t;

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

    // funct3 - CSR
    typedef enum logic [2:0] {
        FUNCT3_ECALL_EBREAK = 3'b000,   // Ebreak / Ecall
        FUNCT3_CSR_RW       = 3'b001,   // CSR Read and Write
        FUNCT3_CSR_RS       = 3'b010,   // CSR Read and Set
        FUNCT3_CSR_RC       = 3'b011,   // CSR Read and Clear
        FUNCT3_CSR_RWI      = 3'b101,   // CSR Read and Write Immediate
        FUNCT3_CSR_RSI      = 3'b110,   // CSR Read and Set Immediate
        FUNCT3_CSR_RCI      = 3'b111    // CSR Read and Clear Immediate
    } funct3_csr_t;

    /*
     * Returns true if funct3 encodes an immediate.
     */
    function automatic csr_is_imm(funct3_t funct);
        return funct[2] == 1'b1;
    endfunction

    // funct7
    localparam funct7_t FUNCT7_00h = 7'h00;
    localparam funct7_t FUNCT7_20h = 7'h20;
    localparam inst_t   INST_NOP   = {25'b0, OPCODE_OP_IMM};

    // -------------------------------------------------------------------------------------------------------------- //
    // Functions
    // -------------------------------------------------------------------------------------------------------------- //
    // --- Decode functions ----------------------------------------------------------------------------------------- //
    /*
     * Decodes the opcode of the instruction
     */
    function automatic opcode_t decode_opcode (inst_t inst_i);
        return opcode_t'(inst_i[6:0]);
    endfunction

    /*
     * Decode I-immediate (lower 12'bits)
     */
    function automatic imm_t decode_imm_i (inst_t inst);
        //      {         sext[11]},      [10: 0]}
        return  {{XLEN-11{inst[31]}}, inst[30:20]};
    endfunction

    /*
     * Decode S-immediate (store)
     */
    function automatic imm_t decode_imm_s (inst_t inst);
        //     {         sext[11],       [10: 5],       [4:0]}
        return {{XLEN-11{inst[31]}}, inst[30:25],  inst[11:7]};
    endfunction

    /*
     * Decode B-immediate (branch)
     */
    function automatic imm_t decode_imm_b (inst_t inst);
        //     {         sext[12],      [11],      [10: 5],       [4:1],   [0]}
        return {{XLEN-12{inst[31]}}, inst[7],  inst[30:25],  inst[11:8], 1'b0 };
    endfunction

    /*
     * Decode U-immediate (upper 20'bits)
     */
    function automatic imm_t decode_imm_u (inst_t inst);
        //     {         sext[31],       [30:12],   [11:0]}
        return {{XLEN-31{inst[31]}}, inst[30:12],   12'b0};
    endfunction

    /*
     * Decode J-immediate (jump)
     */
    function automatic imm_t decode_imm_j (inst_t inst);
        //     {         sext[20],      [19:12],     [11],      [10:1],    [0]}
        return {{XLEN-20{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
    endfunction

    // --- Signum extension function -------------------------------------------------------------------------------- //
    /*
     * Sign extends the 8-bit byte operand to XLEN bits
     */
    function automatic [XLEN-1:0] sext8(logic [7:0] operand);
        return {{XLEN-8{operand[7]}}, operand[7:0]};
    endfunction

    /*
     * Sign extends 12-bit operand (immediate usually) to XLEN bits
     */
    function automatic [XLEN-1:0] sext12(logic [11:0] operand);
        return {{XLEN-12{operand[11]}}, operand[11:0]};
    endfunction

    /*
     * Sign extends the 16-bit half operand to XLEN bits
     */
    function automatic [XLEN-1:0] sext16(logic [15:0] operand);
        return {{XLEN-16{operand[15]}}, operand[15:0]};
    endfunction

    /*
     * Sign extends the 32-bit word operand to XLEN bits
     */
    function automatic [XLEN-1:0] sext32(logic [31:0] operand);
        return {{XLEN-32{operand[31]}}, operand[31:0]};
    endfunction

    // -------------------------------------------------------------------------------------------------------------- //
    // Function units
    // -------------------------------------------------------------------------------------------------------------- //
    typedef enum int {
        FUNIT_NONE,     // No function unit
        FUNIT_ALU,      // Arithmetic-logic unit (ADD, SUB etc.)
        FUNIT_MEM,      // Memory unit           (Loads, Stores, FENCE etc.)
        FUNIT_CSR,      // Control and status register unit
        FUNIT_COUNT
    } funit_t;

    /*
     * Error codes (not yet used)
     * Considerations:
     *      [x] Define codes only for FUNIT, not other cases (op instead of inst)
     *      [ ] Separate memory computation from access / operation etc.
     *      [ ] Use bitvectors?
     */
    typedef enum bit [2:0] {
        // Operation
        ERROR_OP_INVALID,

        // Data
        ERROR_LOAD_ADDRESS_MISALIGNED,
        ERROR_LOAD_ACCESS_FAULT,
        ERROR_STORE_ADDRESS_MISALIGNED,
        ERROR_STORE_ACCESS_FAULT,

        // Other
        ERROR_MTAG_LOAD_INVLD,
        ERROR_MTAG_STORE_INVLD
    } error_t;

    // --- Function unit operations --------------------------------------------------------------------------------- //
    // ALU
    typedef enum bit [3:0] {
        ALU_OP_NONE = 0,

        // Logic
        ALU_OP_AND,     // 1
        ALU_OP_OR,      // 2
        ALU_OP_XOR,     // 3

        // Arithmetic
        ALU_OP_ADD,     // 4
        ALU_OP_SUB,     // 5
        ALU_OP_ADDW,    // 6
        ALU_OP_SUBW,    // 7

        // Shifts
        ALU_OP_SLL,     // 8
        ALU_OP_SRL,     // 9
        ALU_OP_SRA,     // 10
        ALU_OP_SLLW,    // 11
        ALU_OP_SRLW,    // 12
        ALU_OP_SRAW,    // 13

        // Compares
        ALU_OP_SLT,     // 14
        ALU_OP_SLTU     // 15
    } alu_op_t;

    // Mem
    typedef enum bit [3:0] {
        MEM_OP_NONE = 0,

        // Loads
        MEM_OP_LB,      // 1
        MEM_OP_LH,      // 2
        MEM_OP_LW,      // 3
        MEM_OP_LD,      // 4
        MEM_OP_LBU,     // 5
        MEM_OP_LHU,     // 6
        MEM_OP_LWU,     // 7

        // Stores
        MEM_OP_SB,      // 8
        MEM_OP_SH,      // 9
        MEM_OP_SW,      // 10
        MEM_OP_SD       // 11
    } mem_op_t;

    // Funit operation (input)
    typedef union packed {
        alu_op_t alu;
        mem_op_t mem;
    } funit_op_t;

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
        logic               rdy;        // Unit ready, operation completed
        logic               err;        // Error occured
        logic               res_wb;     // Result is valid, write-back to register
        logic               reserved;

        // Payload
        logic   [XLEN-1:0]  res;        // Result
    } funit_out_t;

    // FU input defaults
    function automatic funit_in_t funit_in_default();
        funit_in_t fu;
        fu.ena      = 1'b0;
        fu.op       =  '0;
        fu.src1     =  '0;
        fu.src2     =  '0;
        return fu;
    endfunction

    // FU output defaults
    function automatic funit_out_t funit_out_default();
        funit_out_t fu;
        fu.rdy      = 1'b0;
        fu.err      = 1'b0;
        fu.res_wb   = 1'b0;
        fu.reserved = 1'b0;
        fu.res      =   '0;
        return fu;
    endfunction

    // --- Internal units and multiplexer operations ---------------------------------------------------------------- //
    // Select the ALU operation
    typedef enum logic {
        ALU_OP_SEL_DECODER,  // Decode Instruction
        ALU_OP_SEL_ADD       // Use Add operation
    } alu_op_sel_t;

    // Source 1 selection
    typedef enum logic [2:0] {
        SRC1_SEL_0,          // 0: Value '0'
        SRC1_SEL_RS1,        // 1: Register source 1
        SRC1_SEL_RS1_IMM,    // 2: Register source 1 + imm (for load, store)
        SRC1_SEL_PC,         // 3: Current program counter
        SRC1_SEL_UIMM        // 4: Unsigned 4-bit zero extended IMM (for csr)
    } src1_sel_t;

    // Source 2 selection
    typedef enum logic [1:0] {
        SRC2_SEL_0,          // 0: Value '0'
        SRC2_SEL_RS2,        // 1: Register source 2
        SRC2_SEL_IMM         // 2: Immediate
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
        RD_SEL_NONE,        // 0: No input
        RD_SEL_FUNIT,       // 1: Function unit
        RD_SEL_IMM,         // 2: Immediate
        RD_SEL_NXTPC        // 3: Next pc
    } rd_sel_t;

    // Program counter selection
    typedef enum logic [1:0] {
        PC_SEL_NXTPC,       // 0: Next pc
        PC_SEL_FUNIT,       // 1: Function unit
        PC_SEL_BRANCH       // 2: Branch decision unit
     } pc_sel_t;
endpackage
`endif
