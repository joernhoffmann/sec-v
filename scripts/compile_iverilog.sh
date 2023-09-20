#!/bin/bash
sh autoconf.sh
./configure
make -j32
make install
