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
ELF2HEX = riscv64-unknown-elf-elf2hex

# Compile Flags
CFLAGS 	= -march=rv64i
LINKER_SCRIPT = io_write.ld
LDFLAGS = -T $(LINKER_SCRIPT)

# Source files
SRC = io_write.asm
OBJ = $(SRC:.asm=.o)
ELF = $(SRC:.asm=.elf)
HEX = $(SRC:.asm=.hex)
IHEX = $(SRC:.asm=.ihex)

all: $(HEX) $(IHEX)

disasm: $(ELF)
	$(OBJDUMP) -D $<

$(HEX): $(ELF)
	$(ELF2HEX) --bit-width 64 --input $< --output $@

$(IHEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

$(ELF):$(OBJ) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) $< -o $@

$(OBJ): $(SRC)
	$(AS) $(CFLAGS) -o $@ $<

clean:
	rm -f $(ELF) $(HEX) $(IHEX) $(ELF) $(OBJ)

.PHONY: all clean
