# Install toolchain
# Mac:
# 	brew tap riscv-software-src/riscv
# 	brew install riscv-tools
#
# Linux (todo)
# sudo apt-get update
# sudo apt-get install gcc-riscv64-unknown-elf
# sudo apt-get install gdb-riscv64-unknown-elf
# sudo apt-get install binutils-riscv64-unknown-elf
# sudo apt-get install libnewlib-dev

# Define the RISC-V toolchain and flags
CC = riscv64-unknown-elf-gcc
LD = riscv64-unknown-elf-ld
OBJCOPY = riscv64-unknown-elf-objcopy

# Compile Flags
# CFLAGS = -march=rv32i -nostartfiles
CFLAGS = -march=rv64i -nostartfiles -std=c11 -Wall -g -O2
LDFLAGS = -T link_script.ld

# Use newlib
# NEWLIB_DIR = /path/to/your/newlib
# NEWLIB_LIB_DIR = $(NEWLIB_DIR)/lib
# NEWLIB_INC_DIR = $(NEWLIB_DIR)/include
# CFLAGS += -I$(NEWLIB_INC_DIR)
# LDFLAGS += -L$(NEWLIB_LIB_DIR) -lc
LDFLAGS += -lc -lgcc

# Define the source files
SRC = io_write.c
ELF = $(SRC:.c=.elf)
HEX = $(SRC:.c=.hex)

# Define the linker script
LINKER_SCRIPT = link_script.ld

all: $(HEX)

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

$(ELF): $(SRC) $(LINKER_SCRIPT)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(ELF) $(HEX)

.PHONY: all clean