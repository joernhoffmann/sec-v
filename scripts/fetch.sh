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
	git clone https://github.com/verilator/verilator.git $BASE_PATH
fi

echo "iVerilog"
if [ -d $IVERILOG_PATH ]; then
	cd $IVERILOG_PATH
	git pull
else
	git clone https://github.com/steveicarus/iverilog.git $BASE_PATH
fi

echo "SVUnit"
if [ -d $SVUNIT_PATH ]; then
	cd $SVUNIT_PATH
	git pull
else
	git clone https://github.com/svunit/svunit.git $BASE_PATH
fi

echo "SVUT"
if [ -d $SVUT_PATH ]; then
	cd $SVUT_PATH
	git pull
else
	git clone https://github.com/dpretet/svut.git $BASE_PATH
fi








	
