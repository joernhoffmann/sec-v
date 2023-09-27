MEMORY
{
    ROM (rx)    : ORIGIN = 0x00000000, LENGTH = 0x400   /* 1k   */
    RAM (wrx)   : ORIGIN = 0x00001000, LENGTH = 0x400   /* 1k   */
    IO  (rw)    : ORIGIN = 0x00010000, LENGTH = 0xFFFF  /* 64k  */
}

SECTIONS
{
    .text :
    {
        *(.vectors)         /* Interrupt, service vectors etc.  */
        *(.text)
        *(.text.*)
    } > ROM

    .rodata :
    {
        *(.rodata)
        *(.rodata.*)
    } > ROM

    .data :
    {
        . = ALIGN(8);
        _sdata = .;         /* Start of .data */
        *(.data)
        *(.data.*)
        . = ALIGN(4);
        _edata = .;         /* End of .data */
    } > RAM AT> ROM         /* Section copied from rom to ram */

    .bss :
    {
        . = ALIGN(8);
        _sbss = .;          /* Start of .bss */
        *(.bss)
        *(.bss.*)
        *(COMMON)

        . = ALIGN(8);
        _ebss = .;          /* End of .bss */
    } > RAM

    .stack (NOLOAD) :
    {
        . = ALIGN(8);
        . += 0x100;         /* Reserve 256 Bytes for the stack */
    } > RAM
}