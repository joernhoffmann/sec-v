MEMORY
{
    instruction_memory (rx) : ORIGIN = 0x00000000, LENGTH = 0x1000
    data_memory (rwx) : ORIGIN = 0x10000000, LENGTH = 0x1000
}

SECTIONS
{
    .text :
    {
        *(.text)
    } > instruction_memory

    .data :
    {
        *(.data)
    } > data_memory
}