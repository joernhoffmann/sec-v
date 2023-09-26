#!/bin/bash
SVUT=$HOME/lib/svut/svutRun

# Run specific tests
$SVUT -test alu_core_testbench.sv
$SVUT -test alu_decoder_testbench.sv
$SVUT -test branch_testbench.sv
$SVUT -test decoder_testbench.sv
$SVUT -test gpr_testbench.sv
