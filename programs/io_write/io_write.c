#include <stdint.h>

// Memory-mapped address for data memory
volatile uint64_t *data_memory = (uint64_t *)0x10000000;

int main() {
    // Address and data to write
    uint64_t address = 0x10000004;  // Example address in data memory
    uint64_t value = 0xDEADBEEF;   // Example data to write

    // Write the value to the specified address
    *data_memory = value;
    return 0;
}