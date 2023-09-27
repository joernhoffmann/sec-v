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
AS = riscv64-unknown-elf-as
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump

# Compile Flags
CFLAGS = -march=rv64i

# Source files
SRC = io_write.asm
ELF = $(SRC:.asm=.elf)
HEX = $(SRC:.asm=.hex)

all: $(HEX)

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

$(ELF): $(SRC) $(LINKER_SCRIPT)
	$(AS) $(CFLAGS) -o $@ $<

clean:
	rm -f $(ELF) $(HEX)

.PHONY: all clean
