set(CMAKE_SYSTEM_NAME Windows)

# zig cc enables UBSan checks by default. LuaJIT's DynASM (dasm_setup)
# intentionally performs null-pointer arithmetic (buf - pos), which triggers
# a Zig runtime panic ("applying non-zero offset to null pointer") when the
# cross-built buildvm.exe is run under Wine. Disable it here, consistently
# with zig.toolchain.cmake.
set(CMAKE_C_FLAGS_INIT "-fno-sanitize=undefined -fno-sanitize-trap=undefined")
set(CMAKE_CXX_FLAGS_INIT "-fno-sanitize=undefined -fno-sanitize-trap=undefined")

IF(NOT DEFINED USE_64BITS)
  IF(DEFINED ENV{USE_64BITS})
    SET(USE_64BITS $ENV{USE_64BITS})
    IF(USE_64BITS STREQUAL "1" OR
       USE_64BITS STREQUAL "ON" OR USE_64BITS STREQUAL "TRUE")
      SET(USE_64BITS ON)
    ELSE()
      SET(USE_64BITS OFF)
    ENDIF()
  ELSE()
    SET(USE_64BITS OFF)
  ENDIF()
endif()

IF(USE_64BITS)
  SET(TARGETS x86_64-windows-gnu)
ELSE()
  SET(TARGETS x86-windows-gnu)
ENDIF()
if(DEFINED ENV{ZIG_TOOLCHAIN_PATH})
  set(ZIG_TOOLCHAIN_PATH $ENV{ZIG_TOOLCHAIN_PATH})
endif()
if(NOT ZIG_TOOLCHAIN_PATH)
  find_program(ZIG_TOOLCHAIN_PATH NAMES zig REQUIRED)
endif()
set(CROSSCOMPILER ${ZIG_TOOLCHAIN_PATH})

set(CMAKE_C_COMPILER_FORCED 1)
set(CMAKE_C_COMPILER_ID_RUN TRUE)
set(CMAKE_C_COMPILER ${CROSSCOMPILER} cc --target=${TARGETS})

set(CMAKE_CXX_COMPILER_FORCED 1)
set(CMAKE_CXX_COMPILER_ID_RUN TRUE)
set(CMAKE_CXX_COMPILER ${CROSSCOMPILER} c++ --target=${TARGETS})
set(CMAKE_RC_COMPILER ${CROSSCOMPILER} rc --target=${TARGETS})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
