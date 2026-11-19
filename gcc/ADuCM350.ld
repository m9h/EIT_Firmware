/*
 * GNU linker script for the ADuCM350 running the OpenEIT / Spectra firmware.
 *
 * The layout mirrors the IAR configuration the released images were built
 * with (ADuCM350BBCZ.icf), as read back from programming_helper/hex/openeit.out:
 *
 *   0x00000000  interrupt vector table (0x134 bytes)
 *   0x000007F8  RSIGNATURE  (4 bytes, reserved, left erased)
 *   0x000007FC  CHECKSUM    (4 bytes, reserved, left erased)
 *   0x00000800  code + read-only data
 *   0x0003E000  PARITY0 / CHECKSUM0 (reserved, top of flash block 0)
 *   0x20000000  RAM; the IAR build keeps everything, stack included,
 *               below 0x20002000 and so does this script.
 *
 * Symbols _etext/_data/_edata/_bss/_ebss are the ones src/startup.c
 * (ResetISR, __GNUC__ branch) uses to initialise RAM.
 */

ENTRY(ResetISR)

MEMORY
{
  VECTORS (rx)  : ORIGIN = 0x00000000, LENGTH = 0x000007F8
  FLASH   (rx)  : ORIGIN = 0x00000800, LENGTH = 0x0003D800   /* up to PARITY0 at 0x3E000 */
  RAM     (rwx) : ORIGIN = 0x20000000, LENGTH = 0x00002000
}

/*
 * The IAR CSTACK is 0x400, but multiplex_adg732() alone has an ~850 byte
 * frame on top of main(), so the stack really runs deeper than that (under
 * IAR it grows down into RAM nothing else uses).  Reserve 4 KB here; what is
 * left between .bss and the stack is the newlib heap.
 */
_stack_size = 0x1000;
_estack     = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
  .isr_vector :
  {
    KEEP(*(.isr_vector))
  } > VECTORS

  .text :
  {
    . = ALIGN(4);
    *(.text .text.*)
    *(.rodata .rodata.*)
    *(.glue_7 .glue_7t)
    KEEP(*(.init)) KEEP(*(.fini))
    . = ALIGN(4);
    __preinit_array_start = .; KEEP(*(.preinit_array)) __preinit_array_end = .;
    __init_array_start = .; KEEP(*(SORT(.init_array.*))) KEEP(*(.init_array)) __init_array_end = .;
    __fini_array_start = .; KEEP(*(SORT(.fini_array.*))) KEEP(*(.fini_array)) __fini_array_end = .;
    . = ALIGN(4);
  } > FLASH

  .ARM.extab : { *(.ARM.extab* .gnu.linkonce.armextab.*) } > FLASH
  __exidx_start = .;
  .ARM.exidx : { *(.ARM.exidx* .gnu.linkonce.armexidx.*) } > FLASH
  __exidx_end = .;

  . = ALIGN(4);
  _etext = .;                              /* load address of .data */

  .data : AT(_etext)
  {
    . = ALIGN(4);
    _data = .;
    *(.data .data.*)
    . = ALIGN(4);
    _edata = .;
  } > RAM

  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    _bss = .;
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > RAM

  /* heap grows up from here to the bottom of the stack (see gcc/syscalls.c) */
  . = ALIGN(8);
  _heap_start = .;
  _heap_end   = _estack - _stack_size;
  ASSERT(_heap_start <= _heap_end, "RAM overflow: data + bss collide with the stack")
}
