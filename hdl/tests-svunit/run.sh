#!/bin/bash

if [[ $OSTYPE == 'darwin'* ]]; then
  echo 'macOS'
  JOBS=`sysctl -n hw.logicalcpu`
else
    JOBS=`nproc`
fi

#runSVUnit -s verilator -c "--build-jobs $JOBS --debug" -f files.f
runSVUnit -s verilator -c "--build-jobs $JOBS" -f files.f
