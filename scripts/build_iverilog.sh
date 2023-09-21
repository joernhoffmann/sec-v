#!/bin/bash
echo "Install dependencies"
sudo apt-get install -y autoconf gperf make gcc g++ bison flex

echo "Build & install"
sh autoconf.sh
./configure
make -j`nproc`
sudo make install
