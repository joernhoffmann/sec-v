# Install toolchain
# Mac:
# 	brew tap riscv-software-src/riscv
# 	brew install riscv-tools
#
# Linux (todo)
#	Use newlib
#   Use riscv6464-unknown-elf-*

# Define the RISC-V toolchain and flags
CC = riscv64-unknown-elf-gcc
LD = riscv64-unknown-elf-ld
OBJCOPY = riscv64-unknown-elf-objcopy

# Compile Flags
# CFLAGS = -march=rv32i -nostartfiles
CFLAGS = -march=rv64i -nostartfiles
LDFLAGS = -T link_script.ld

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