    // --- Opcode vector -------------------------------------------------------------------------------------------- //

    function automatic logic[4:0] op_idx(opcode_t opcode);
        return (opcode[6:2]);
    endfunction

    logic [31:0] op;
    generate
        genvar idx;
        for (idx = 0; idx < 31; idx++) begin
            assign op[idx] = (op_idx(opcode) == idx);
        end
    endgenerate

     // ALU
    logic  opcode_op, opcode_op_imm, opcode_op_32, opcode_op_imm_32;
    assign opcode_op        = (opcode == OPCODE_OP);
    assign opcode_op_imm    = (opcode == OPCODE_OP_IMM);
    assign opcode_op_32     = (opcode == OPCODE_OP_32);
    assign opcode_op_imm_32 = (opcode == OPCODE_OP_IMM_32);

    // Branch
    logic  opcode_branch, opcode_jal, opcode_jalr;
    assign opcode_branch    = (opcode == OPCODE_BRANCH);
    assign opcode_jal       = (opcode == OPCODE_JAL);
    assign opcode_jalr      = (opcode == OPCODE_JALR);

    // Mem
    logic  opcode_load, opcode_store, opcode_misc_mem;
    assign opcode_load      = (opcode == OPCODE_LOAD);
    assign opcode_store     = (opcode == OPCODE_STORE);
    assign opcode_misc_mem  = (opcode == OPCODE_MISC_MEM);

    // Mov
    logic  opcode_auipc, opcode_lui;
    assign opcode_auipc     = (opcode == OPCODE_AUIPC);
    assign opcode_lui       = (opcode == OPCODE_LUI);

    // --- Function field ------------------------------------------------------------------------------------------- //