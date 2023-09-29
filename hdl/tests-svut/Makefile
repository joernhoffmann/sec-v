SVUT ?= $(HOME)/lib/svut/svutRun
OPS = -no-splash

all: alu_core alu_decoder alu branch decoder gpr mem_decoder secv

alu_core:
	$(SVUT) $(OPS) -test alu_core_testbench.sv

alu_decoder:
	$(SVUT) $(OPS) -test alu_decoder_testbench.sv

alu:
	$(SVUT) $(OPS) -test alu_testbench.sv

branch:
	$(SVUT) $(OPS) -test branch_testbench.sv

decoder:
	$(SVUT) $(OPS) -test decoder_testbench.sv

gpr:
	$(SVUT) $(OPS) -test gpr_testbench.sv

mem_decoder:
	$(SVUT) $(OPS) -test mem_decoder_testbench.sv

secv:
	$(SVUT) $(OPS) -test secv_testbench.sv

secv_verilator: sim_main.cpp
	verilator -Wall --trace --Mdir build +1800-2012ext+sv +1800-2005ext+v -Wno-STMTDLY -Wno-UNUSED \
	-Wno-UNDRIVEN -Wno-PINCONNECTEMPTY -Wpedantic -Wno-VARHIDDEN -Wno-lint -f files.f  -cc --exe \
	--build -j --top-module secv_testbench secv_testbench.sv --timing sim_main.cpp

run_verilator: secv_verilator
	./build/Vsecv_testbench

help:
	@echo "Targets: alu_core alu_decoder alu branch decoder gpr mem_decoder sec"
	@echo "Additional targets: all clean secv_verilator run_verilator"
	@echo "e. g. run make alu_core alu"

clean:
	rm -f svut.out
	rm -rf build
	rm -f *.vcd

.PHONY: all clean