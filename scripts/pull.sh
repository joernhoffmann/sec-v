#"!/bin/bash
BASE_PATH=$HOME/lib
VERILATOR_PATH=$BASE_PATH/verilator
IVERILOG_PATH=$BASE_PATH/iverilog
SVUNIT_PATH=$BASE_PATH/svunit
SVUT_PATH=$BASE_PATH/svut

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








	
