#!/bin/bash
SVUT=$HOME/lib/svut/svutRun

# Check if arguments given
if [ -z "$*" ]; then
    tests=("alu_core" "alu_decoder" "alu" "branch" "decoder" "gpr")
else
    tests=$*
fi

# Run tests
for name in $tests
do
    if [ "$name" == "alu_core" ]; then
        $SVUT -test alu_core_testbench.sv

    elif [ "$name" == "alu_decoder" ]; then
        $SVUT -test alu_decoder_testbench.sv

    elif [ "$name" == "alu" ]; then
        $SVUT -test alu_testbench.sv

    elif [ "$name" == "branch" ]; then
        $SVUT -test branch_testbench.sv

    elif [ "$name" == "decoder" ]; then
        $SVUT -test decoder_testbench.sv

    elif [ "$name" == "gpr" ]; then
        $SVUT -test gpr_testbench.sv

    else
        echo "Test $name unknown"

    fi
done
