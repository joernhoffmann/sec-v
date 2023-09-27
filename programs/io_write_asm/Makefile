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
LD = riscv64-unknown-elf-ld
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump

# Compile Flags
CFLAGS 	= -march=rv64i
LINKER_SCRIPT = io_write.ld
LDFLAGS = -T $(LINKER_SCRIPT)

# Source files
SRC = io_write.asm
OBJ = $(SRC:.asm=.o)
ELF = $(SRC:.asm=.elf)
HEX = $(SRC:.asm=.hex)

all: $(HEX)

disasm: $(ELF)
	$(OBJDUMP) -D $<

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

$(ELF):$(OBJ) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) $< -o $@

$(OBJ): $(SRC)
	$(AS) $(CFLAGS) -o $@ $<

clean:
	rm -f $(ELF) $(HEX) $(ELF)

.PHONY: all clean
