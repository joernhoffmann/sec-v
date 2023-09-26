// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Verilator main to support verilated testbenches.
 */

// Units
#include "build/Valu_core_testbench.h"
#include "build/Valu_decoder_testbench.h"
#include "build/Vbranch_testbench.h"
#include "build/Vdecode_testbench.h"
#include "build/Vgpr_testbench.h"
#include "verilated.h"

int main(int argc, char** argv, char** env) {


    Verilated::commandArgs(argc, argv);

    Valu_core_testbench   *alu     = new Valu_core_testbench;
    Valu_decode_testbench *alu_dec = new Valu_decode_testbench;
    Vbranch_testbench     *brn     = new Vbranch_testbench;
    Vdecode_testbench     *dec     = new Vdecode_testbench;
    Vgpr_testbench        *gpr     = new Vgpr_testbench;

    int timer = 0;

    // Simulate until $finish()
    while (!Verilated::gotFinish()) {

        // Evaluate models
        alu->eval();
        alu_dec->eval();
        brn->eval();
        dec->eval();
        gpr->eval();
    }

    // Final model cleanup
    alu->final();
    alu_dec->final();
    brn->final();
    dec->final();
    gpr->final();

    // Destroy model
    delete alu;
    delete alu_dec;
    delete brn;
    delete dec;
    delete gpr;

    // Return good completion status
    return 0;
}
