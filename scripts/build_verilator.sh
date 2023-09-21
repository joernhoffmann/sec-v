#!/bin/bash
echo "Install dependencies"
sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache
sudo apt-get install libgoogle-perftools-dev numactl perl-doc
sudo apt-get install libfl2                     # Ubuntu only (ignore if gives error)
sudo apt-get install libfl-dev                  # Ubuntu only (ignore if gives error)
sudo apt-get install zlibc zlib1g zlib1g-dev    # Ubuntu only (ignore if gives error)

echo "Build"
autoconf
export VERILATOR_ROOT=`pwd`
./configure
make -j`nproc`