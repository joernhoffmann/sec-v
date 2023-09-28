#!/bin/bash
SVUT=$HOME/lib/svut/svutRun
TESTS_AVAIL=("alu_core" "alu_decoder" "alu" "branch" "decoder" "gpr" "ram2port_wb" "mem_decoder")

# Check if arguments given
TESTS=""
if [ -z "$*" ]; then
    TESTS=${TESTS_AVAIL[*]}
    test_count=${#TESTS_AVAIL[*]}
else
    TESTS=$*
    test_count=$#
fi

# Run tests
success=0
for name in $TESTS
do
    if [ "$name" == "alu_core" ]; then
        $SVUT -test alu_core_testbench.sv && success=$((success+1))

    elif [ "$name" == "alu_decoder" ]; then
        $SVUT -test alu_decoder_testbench.sv && success=$((success+1))

    elif [ "$name" == "alu" ]; then
        $SVUT -test alu_testbench.sv && success=$((success+1))

    elif [ "$name" == "branch" ]; then
        $SVUT -test branch_testbench.sv && success=$((success+1))

    elif [ "$name" == "decoder" ]; then
        $SVUT -test decoder_testbench.sv && success=$((success+1))

    elif [ "$name" == "gpr" ]; then
        $SVUT -test gpr_testbench.sv && success=$((success+1))

    elif [ "$name" == "ram2port_wb" ]; then
        $SVUT -test ram2port_wb_testbench.sv && success=$((success+1))

    elif [ "$name" == "mem_decoder" ]; then
        $SVUT -test mem_decoder_testbench.sv && success=$((success+1))

    else
        echo "Test name '$name' unknown"
        echo "Available tests:"
        echo "   ${TESTS_AVAIL[*]}"
    fi
done

if [ $test_count -gt 0 ]; then
    echo "Tests $success / $test_count successful"
fi

