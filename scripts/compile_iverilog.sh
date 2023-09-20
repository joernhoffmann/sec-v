#!/bin/bash
apt install -y autoconf gperf make gcc g++ bison fle
sh autoconf.sh
./configure
make -j32
sudo make install
