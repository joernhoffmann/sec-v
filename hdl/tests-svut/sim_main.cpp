// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Verilator main to support verilated testbenches.
 */

#include "build/Vbranch_testbench.h"
#include "build/Vdecode_testbench.h"
#include "verilated.h"

int main(int argc, char** argv, char** env) {

    Verilated::commandArgs(argc, argv);
    Vbranch_testbench* brn = new Vbranch_testbench;
    Vdecode_testbench* dec = new Vdecode_testbench;
    
    int timer = 0;

    // Simulate until $finish()
    while (!Verilated::gotFinish()) {

        // Evaluate model;
        brn->eval();
        dec->eval();
    }

    // Final model cleanup
    brn->final();
    dec->final();

    // Destroy model
    delete top;

    // Return good completion status
    return 0;
}

