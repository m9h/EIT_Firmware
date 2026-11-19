# Building the Spectra firmware with GCC

The firmware has so far only been buildable with IAR Embedded Workbench
(Windows, paid licence: the image is over the 32 KB limit of the free
edition).  This folder adds a build with the free Arm GNU Toolchain that
runs on Linux, macOS and Windows.

**Status: builds and links; not yet verified on a Spectra board.**  Until
someone has flashed it and compared its output with the IAR image, treat the
released `hex_files/openeit.hex` as the known-good firmware, and back up your
board's flash before writing anything (see below).

## Build

Needs `arm-none-eabi-gcc` with newlib (Arm GNU Toolchain, or
`gcc-arm-none-eabi` + `libnewlib-arm-none-eabi` on Debian/Ubuntu), CMake
3.20 or newer, and Ninja or Make.

    cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake
    cmake --build build

If the toolchain is not on `PATH`, set `ARM_TOOLCHAIN_DIR` to its `bin`
folder.  Outputs: `build/openeit.elf`, `.hex`, `.bin`, `.map`.

The build compiles exactly the sources listed in
`iar/ImpedanceMeasurement_4Wire.ewp`, with the same defines
(`ADI_SYSTEM_CLOCK_TRANSITION`, `ADI_DEBUG`) and include paths.  The IAR
project is untouched and still builds the same way.

## What was needed

| File | Change |
|---|---|
| `inc/device.h` | accept GCC in the supported-compiler check |
| `src/startup.c` | vector table placement and stack pointer for GCC |
| `src/system.c`, `src/uart.c` | `NULL` was used to initialise enums and integers, which IAR accepts and GCC rejects |
| `OpenEIT.c` | `delay()` is an empty counting loop, which GCC deletes when optimising; an empty `asm` statement keeps it |
| `gcc/ADuCM350.ld` | linker script reproducing the IAR memory layout |
| `gcc/syscalls.c` | newlib stubs (heap, discarded `printf`) |
| `gcc/lib/libarm_cortexM3l_math.a` | CMSIS-DSP built for GCC, taken from the `gcc-toolchain` branch (the libraries in `iar/` are IAR-format) |

The memory layout was read back from the IAR ELF shipped in
`programming_helper/hex/openeit.out`: vectors at `0x0`, the reserved
signature and checksum words at `0x7F8`/`0x7FC`, code from `0x800`, RAM and
initial stack pointer below `0x20002000`.  The GCC image has the same
vector-table size (0x134), the same initial stack pointer, and overrides the
same interrupt slots.

## Things to check on hardware

- **Timing.**  `delay()` and any other busy-wait loops run at a different
  speed than under IAR.  `delay()` is only called with 2,000,000 counts at
  start-up, so this should be harmless, but frame timing may differ.
- **Stack.**  Measurement functions keep 800+ byte buffers on the stack.
  The linker script reserves 4 KB.
- **Output.**  Compare frames from this build against the IAR image on a
  fixed load (resistor phantom or saline tank).

## Flashing with a J-Link

Back up first.  This reads the whole flash to `spectra_flash_backup.bin`
and also tells you whether SWD is reachable on your board (see issue #12):

    JLinkExe -device ADUCM350 -if SWD -speed 1000 -autoconnect 1 -CommanderScript gcc/backup.jlink

Then, from the repository root:

    JLinkExe -device ADUCM350 -if SWD -speed 1000 -autoconnect 1 -CommanderScript gcc/flash.jlink

On the Spectra board the ADuCM350 is on the `SWD2` header (`SWD1` is the
Bluetooth module).
