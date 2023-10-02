#"!/bin/bash
BASE_PATH=$HOME/lib

echo "Verilator"
VERILATOR_PATH=$BASE_PATH/verilator
if [ -d $VERILATOR_PATH ]; then
	cd $VERILATOR_PATH
	git pull
else
	mkdir -p $VERILATOR_PATH
	git clone https://github.com/verilator/verilator.git $VERILATOR_PATH
fi

echo "iVerilog"
IVERILOG_PATH=$BASE_PATH/iverilog
if [ -d $IVERILOG_PATH ]; then
	cd $IVERILOG_PATH
	git pull
else
	mkdir -p $IVERILOG_PATH
	git clone https://github.com/steveicarus/iverilog.git $IVERILOG_PATH
fi

echo "SVUnit"
SVUNIT_PATH=$BASE_PATH/svunit
if [ -d $SVUNIT_PATH ]; then
	cd $SVUNIT_PATH
	git pull
else
	mkdir -p $SVUNIT_PATH
	git clone https://github.com/svunit/svunit.git $SVUNIT_PATH
fi

echo "SVUT"
SVUT_PATH=$BASE_PATH/svut
if [ -d $SVUT_PATH ]; then
	cd $SVUT_PATH
	git pull
else
	mkdir -p $SVUT_PATH
	git clone https://github.com/dpretet/svut.git $SVUT_PATH
fi

echo "Verible"
VERIBLE_PATH=$BASE_PATH/verible
VERIBLE_VERSION=verible-v0.0-3416-g470e0b95
VERBILE_FILE=$VERIBLE_VERSION-Ubuntu-22.04-jammy-x86_64
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

echo "elf2hex"
ELF2HEX_PATH=$BASE_PATH/elf2hex
if [ -d $ELF2HEX_PATH ]; then
	cd $ELF2HEX_PATH
	git pull
else
	mkdir -p $ELF2HEX_PATH
	git clone https://github.com/sifive/elf2hex.git $ELF2HEX_PATH
fi









	
