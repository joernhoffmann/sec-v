#!/bin/bash
SVUT=$HOME/lib/svut/svutRun

# Run specific tests
$SVUT -test alu_testbench.sv
$SVUT -test decoder_testbench.sv
