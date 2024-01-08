#!/bin/bash
VERILATOR=verilator
VERIBLE=verible-verilog-lint
SECV_PKG=secv_pkg.svh

for file in alu.sv alu_core.sv alu_decoder.sv branch.sv decoder.sv gpr.sv \
		    mem.sv mtag.sv mtag_chk.sv mtag_decoder.sv csr.sv csr_regs.sv \
		    ram_wb.sv rom_wb.sv secv_pkg.svh csr_pkg.svh secv.sv
do
	$VERILATOR --lint-only -I $SECV_PKG $file
	$VERIBLE $file --rules=line-length=length:120
done

