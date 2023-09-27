#define LED_ADDR 0x80000000UL

int main() {
    volatile long *led_adr = (long *) LED_ADDR;

    while (1) {
        for (int value = 0; value < 0xff; value++)
            *led_adr = value;

        // Delay
        for (int i = 0; i < 65535; i++)
            ;
    }
}