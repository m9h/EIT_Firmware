# CMake toolchain file for the Arm GNU Toolchain (arm-none-eabi-gcc).
# Set ARM_TOOLCHAIN_DIR (cache or environment) to the toolchain's bin/ folder
# if it is not on PATH.
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

if(NOT ARM_TOOLCHAIN_DIR AND DEFINED ENV{ARM_TOOLCHAIN_DIR})
  set(ARM_TOOLCHAIN_DIR "$ENV{ARM_TOOLCHAIN_DIR}")
endif()
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES ARM_TOOLCHAIN_DIR)
if(ARM_TOOLCHAIN_DIR)
  set(_p "${ARM_TOOLCHAIN_DIR}/")
endif()

set(CMAKE_C_COMPILER   "${_p}arm-none-eabi-gcc")
set(CMAKE_ASM_COMPILER "${_p}arm-none-eabi-gcc")
set(CMAKE_OBJCOPY      "${_p}arm-none-eabi-objcopy" CACHE FILEPATH "")
set(CMAKE_SIZE         "${_p}arm-none-eabi-size"    CACHE FILEPATH "")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
