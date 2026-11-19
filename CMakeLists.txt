# GCC build of the OpenEIT Spectra firmware (ADuCM350, Cortex-M3).
#
#   cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake
#   cmake --build build
#
# Produces build/openeit.elf, .hex, .bin and .map.  The source list, defines
# and include paths are the ones in iar/ImpedanceMeasurement_4Wire.ewp.
cmake_minimum_required(VERSION 3.20)
project(openeit_firmware C)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE MinSizeRel)
endif()

set(CPU_FLAGS -mcpu=cortex-m3 -mthumb)

add_executable(openeit
  OpenEIT.c
  PinMux.c
  test_common.c
  src/afe.c
  src/afe_lib.c
  src/dma.c
  src/gpio.c
  src/rtc.c
  src/startup.c
  src/system.c
  src/uart.c
  src/wdt.c
  gcc/syscalls.c
)
set_target_properties(openeit PROPERTIES SUFFIX .elf C_STANDARD 11 C_EXTENSIONS ON)

target_compile_definitions(openeit PRIVATE
  ADI_SYSTEM_CLOCK_TRANSITION
  ADI_DEBUG
)
target_include_directories(openeit PRIVATE . src inc inc/config tools)
target_compile_options(openeit PRIVATE
  ${CPU_FLAGS}
  -ffunction-sections -fdata-sections
  -fno-strict-aliasing            # the ADI drivers type-pun registers and buffers
  -fno-common
  -Wall -Wno-unknown-pragmas -Wno-format
  -g
)
target_link_options(openeit PRIVATE
  ${CPU_FLAGS}
  --specs=nano.specs
  -T${CMAKE_SOURCE_DIR}/gcc/ADuCM350.ld
  -Wl,--gc-sections
  -Wl,-Map=${CMAKE_BINARY_DIR}/openeit.map
  -Wl,--print-memory-usage
)
# CMSIS-DSP (arm_cmplx_mag_q31, arm_mult_q15, arm_q15_to_q31): prebuilt
# GCC Cortex-M3 little-endian library matching inc/arm_math.h.
target_link_libraries(openeit PRIVATE
  ${CMAKE_SOURCE_DIR}/gcc/lib/libarm_cortexM3l_math.a
  m
)
set_property(TARGET openeit APPEND PROPERTY LINK_DEPENDS ${CMAKE_SOURCE_DIR}/gcc/ADuCM350.ld)

add_custom_command(TARGET openeit POST_BUILD
  COMMAND ${CMAKE_OBJCOPY} -O ihex   $<TARGET_FILE:openeit> ${CMAKE_BINARY_DIR}/openeit.hex
  COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:openeit> ${CMAKE_BINARY_DIR}/openeit.bin
  COMMAND ${CMAKE_SIZE} $<TARGET_FILE:openeit>
)
