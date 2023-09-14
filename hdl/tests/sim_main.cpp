// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 *
 * Purpose  : Verilator main to support verilated testbenches.
 */


#include "build/Vdecode_testbench.h"
#include "verilated.h"

int main(int argc, char** argv, char** env) {

    Verilated::commandArgs(argc, argv);
    Vdecode_testbench* top = new Vdecode_testbench;
    int timer = 0;

    // Simulate until $finish()
    while (!Verilated::gotFinish()) {

        // Evaluate model;
        top->eval();
    }

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;

    // Return good completion status
    return 0;
}
