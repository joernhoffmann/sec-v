#!/bin/bash
VERILATOR=verilator
VERIBLE=verible-verilog-lint
SECV_PKG=secv_pkg.svh

for file in alu.sv branch.sv decode.sv gpr.sv mem_wb.sv mem.sv mov.sv secv_pkg.svh secv.sv
do
	$VERILATOR --lint-only -I $SECV_PKG  $file
	$VERIBLE $file --rules=line-length=length:120
done

