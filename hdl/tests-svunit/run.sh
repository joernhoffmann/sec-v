#!/bin/bash
JOBS=`nproc`
runSVUnit -s verilator -c "--build-jobs $JOBS" -f files.f
