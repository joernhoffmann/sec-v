#!/bin/bash
echo "Install dependencies"
apt install -y autoconf gperf make gcc g++ bison flex

echo "Build"
sh autoconf.sh
./configure
make -j`nproc`
sudo make install
