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
# sudo apt-get install picolibc-riscv64-unknown-elf

# RISC-V toolchain and flags
CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump

# Compile Flags
CFLAGS = -march=rv64i -mabi=lp64 -Wall -g -O2 -specs=picolibc.specs
LINKER_SCRIPT = io_write.ld
LDFLAGS = -T $(LINKER_SCRIPT)

# Source files
SRC = io_write.c
ELF = $(SRC:.c=.elf)
HEX = $(SRC:.c=.hex)

all: $(HEX)

disasm: $(ELF)
	$(OBJDUMP) -S -d $<

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

$(ELF): $(SRC) $(LINKER_SCRIPT)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(ELF) $(HEX)

.PHONY: all clean
