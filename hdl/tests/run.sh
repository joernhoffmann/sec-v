#!/bin/bash
SVUT=$HOME/.svut/svutRun

# Run specific tests
$SVUT -test alu_testbench.sv
$SVUT -test decode_testbench.sv
