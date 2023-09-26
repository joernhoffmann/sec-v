#"!/bin/bash
BASE_PATH=$HOME/lib
VERILATOR_PATH=$BASE_PATH/verilator
IVERILOG_PATH=$BASE_PATH/iverilog
SVUNIT_PATH=$BASE_PATH/svunit
SVUT_PATH=$BASE_PATH/svut

VERIBLE_PATH=$BASE_PATH/verible
VERIBLE_VERSION=verible-v0.0-3416-g470e0b95
VERBILE_FILE=$VERIBLE_VERSION-Ubuntu-22.04-jammy-x86_64

echo "Verilator"
if [ -d $VERILATOR_PATH ]; then
	cd $VERILATOR_PATH
	git pull
else
	mkdir -p $VERILATOR_PATH
	git clone https://github.com/verilator/verilator.git $VERILATOR_PATH
fi

echo "iVerilog"
if [ -d $IVERILOG_PATH ]; then
	cd $IVERILOG_PATH
	git pull
else
	mkdir -p $IVERILOG_PATH
	git clone https://github.com/steveicarus/iverilog.git $IVERILOG_PATH
fi

echo "SVUnit"
if [ -d $SVUNIT_PATH ]; then
	cd $SVUNIT_PATH
	git pull
else
	mkdir -p $SVUNIT_PATH
	git clone https://github.com/svunit/svunit.git $SVUNIT_PATH
fi

echo "SVUT"
if [ -d $SVUT_PATH ]; then
	cd $SVUT_PATH
	git pull
else
	mkdir -p $SVUT_PATH
	git clone https://github.com/dpretet/svut.git $SVUT_PATH
fi

echo "Verible"
if [ -d $VERIBLE_PATH ]; then
	cd $VERIBLE_PATH
else
	mkdir -p $VERIBLE_PATH
	cd $VERIBLE_PATH
	wget https://github.com/chipsalliance/verible/releases/download/v0.0-3416-g470e0b95/$VERIBLE_FILE\.tar.gz
	tar -xzf $VERIBLE_FILE\.tar.gz
	rm -rf bin
	rm -rf share
	mv $VERIBLE_VERSION/* .
fi








	
