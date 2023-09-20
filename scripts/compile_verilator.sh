#!/bin/bash

autoconf
export VERILATOR_ROOT=`pwd`
./configure
make -j32
