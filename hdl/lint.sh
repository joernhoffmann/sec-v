#!/bin/bash
VERILATOR=verilator
VERIBLE=verible-verilog-lint
SECV_PKG=secv_pkg.svh
CSR_PKG=csr_pkg.svh

for file in alu.sv alu_core.sv alu_decoder.sv branch.sv decoder.sv gpr.sv \
		    mem.sv ram_wb.sv rom_wb.sv secv_pkg.svh csr.sv csr_regs.sv secv.sv \

do
	$VERILATOR --lint-only -I $SECV_PKG -I $CSR_PKG $file
	$VERIBLE $file --rules=line-length=length:120
done

