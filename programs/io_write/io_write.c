#include <stdint.h>

int main() {
    volatile uint64_t *mem = (uint64_t *)0x10000000;
    uint64_t value         = 0xDEADBEEF;

    *mem = value;
    return 0;
}