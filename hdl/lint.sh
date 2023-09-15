#!/bin/bash
VERILATOR=verilator
VERIBLE=verible-verilog-lint
SECV_PKG=secv_pkg.svh

for file in gpr.sv secv.sv alu.sv decode.sv
do
	$VERILATOR --lint-only -I $SECV_PKG  $file
	$VERIBLE $file
done

