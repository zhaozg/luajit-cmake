if(DEFINED ENV{TARGET_SYS})
  set(TARGET_SYS $ENV{TARGET_SYS})
endif()

if(TARGET_SYS AND NOT ZIG_INIT)
  set(ZIG_INIT ON)
  if (DEFINED ENV{ZIG_HACK})
    set(ZIG_HACK $ENV{ZIG_HACK})
  endif()
  set(LLVM_VERSION 20)
  set(CMAKE_SIZEOF_VOID_P 8)
  if(DEFINED ENV{ZIG_TOOLCHAIN_PATH})
    set(ZIG_TOOLCHAIN_PATH $ENV{ZIG_TOOLCHAIN_PATH})
  endif()
  if(NOT ZIG_TOOLCHAIN_PATH)
    find_program(ZIG_TOOLCHAIN_PATH NAMES zig REQUIRED)
  endif()

  execute_process(
      COMMAND bash -c "zig version"
      OUTPUT_VARIABLE ZIG_VERSION
      OUTPUT_STRIP_TRAILING_WHITESPACE
      RESULT_VARIABLE EXIT_CODE
  )

  if(NOT EXIT_CODE EQUAL 0)
      message(FATAL_ERROR
      "Failed to get Zig version. Ensure Zig are installed.")
  endif()

  if(ZIG_VERSION MATCHES "0\.16")
      message(STATUS "Using Zig 0.16")
  elseif(ZIG_VERSION MATCHES "0\.15")
      message(STATUS "Using Zig 0.15")
  elseif(ZIG_VERSION MATCHES "0\.14")
      message(STATUS "Using Zig 0.14")
      set(ZIG_IS_014 TRUE)
  else()
      message(FATAL_ERROR "Unsupport Zig version: ${ZIG_VERSION}")
  endif()

  #https://github.com/ziglang/zig/wiki/FAQ#why-do-i-get-illegal-instruction-when-using-with-zig-cc-to-build-c-code
  set(BUILDFLAGS "-fno-sanitize=undefined -fno-sanitize-trap=undefined")
  set(BUILDFLAGS "${BUILDFLAGS} -fvisibility=hidden -fvisibility-inlines-hidden")
  set(BUILDFLAGS "${BUILDFLAGS} -fno-strict-float-cast-overflow -fno-stack-protector")
  if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
  endif()
  if (${CMAKE_BUILD_TYPE} STREQUAL Debug)
    set(BUILDFLAGS "-g ${BUILDFLAGS}")
  else()
    set(BUILDFLAGS "-O3 -ffast-math ${BUILDFLAGS}")
  endif()

  if(${TARGET_SYS} STREQUAL native)
    set(CMAKE_SIZEOF_VOID_P 8)
    set(CMAKE_SIZEOF_UNSIGNED_SHORT 2)
    set(BUILDFLAGS "-mcpu=skylake ${BUILDFLAGS}")
  else()
    string(FIND "${TARGET_SYS}" "-" CHAR_POS)
    if(CHAR_POS EQUAL -1)
        message(FATAL_ERROR "TARGET_SYS must contain a hyphen '-'")
    endif()
    string(REPLACE "-" ";" TARGETS ${TARGET_SYS})

    list(GET TARGETS 0 ARCH)
    list(GET TARGETS 1 TARGET)
    list(GET TARGETS 2 LIBC)

    string(SUBSTRING ${TARGET} 0 1 T1)
    string(TOUPPER ${T1} T1)
    string(SUBSTRING ${TARGET} 1 10 TARGET)
    set(TARGET "${T1}${TARGET}")

    if(${TARGET} STREQUAL Macos)
      set(TARGET Darwin)
      set(HAVE_FLAG_SEARCH_PATHS_FIRST 0)
      set(CMAKE_OSX_SYSROOT "")  #not use SYSROOT
      set(APPLE 1)
      set(UNIX 1)
      set(CMAKE_OSX_DEPLOYMENT_TARGET "10.09")
      set(CMAKE_INSTALL_NAME_TOOL "install")
    endif()
    if(${TARGET} STREQUAL Linux)
      set(UNIX 1)
    endif()
    if(${TARGET} STREQUAL Windows)
      set(CMAKE_C_LINK_LIBRARY_SUFFIX "")
      set(WIN32 1)
    endif()

    string(FIND ${ARCH} "64" BIT64)
    if(NOT ${BIT64} EQUAL -1)
      set(CMAKE_SIZEOF_VOID_P 8)
    else()
      set(CMAKE_SIZEOF_VOID_P 4)
    endif()
    if(${ARCH} STREQUAL x86_64)
      set(BUILDFLAGS "-mcpu=skylake ${BUILDFLAGS}")
    endif()
    if(${ARCH} STREQUAL aarch64)
      set(BUILDFLAGS "-march=armv8-a+simd+crypto -mtune=generic -funroll-loops -flto ${BUILDFLAGS}")
    endif()
    set(CMAKE_SIZEOF_UNSIGNED_SHORT 2)
    set(CMAKE_CROSSCOMPILING ON)
    set(CMAKE_SYSTEM_NAME ${TARGET})
    set(CMAKE_SYSTEM_PROCESSOR ${ARCH})
  endif()

  include(CMakeForceCompiler)

  set(CMAKE_C_COMPILER_FORCED 1)
  set(CMAKE_C_COMPILER_ID_RUN TRUE)
  set(CMAKE_C_COMPILER ${ZIG_TOOLCHAIN_PATH} cc "--target=${TARGET_SYS}")
  set(CMAKE_C_COMPILER_ID "zig")
  set(CMAKE_C_COMPILER_VERSION ${LLVM_VERSION})
  set(CMAKE_C_COMPILER_TARGET   ${TARGET_SYS})
  set(CMAKE_C_FLAGS_INIT "${BUILDFLAGS} ${ISYSTEM} ${ZIG_HACK}")

  set(CMAKE_ASM_COMPILER_FORCED 1)
  set(CMAKE_ASM_COMPILER_ID_RUN TRUE)
  set(CMAKE_ASM_COMPILER ${ZIG_TOOLCHAIN_PATH} cc "--target=${TARGET_SYS}")
  set(CMAKE_ASM_COMPILER_ID "zig")
  set(CMAKE_ASM_COMPILER_VERSION ${LLVM_VERSION})
  set(CMAKE_ASM_COMPILER_TARGET   ${TARGET_SYS})
  set(CMAKE_ASM_FLAGS_INIT "${BUILDFLAGS}  ${ISYSTEM} ${ZIG_HACK}")

  set(CMAKE_CXX_COMPILER_FORCED 1)
  set(CMAKE_CXX_COMPILER_ID_RUN TRUE)
  set(CMAKE_CXX_COMPILER ${ZIG_TOOLCHAIN_PATH} c++ "--target=${TARGET_SYS}")
  set(CMAKE_CXX_COMPILER_ID "zig")
  set(CMAKE_CXX_COMPILER_VERSION ${LLVM_VERSION})
  set(CMAKE_CXX_COMPILER_TARGET   ${TARGET_SYS})
  set(CMAKE_CXX_FLAGS_INIT "${BUILDFLAGS} ${ISYSTEM} ${ZIG_HACK}")

  SET(CMAKE_STRIP llvm-strip)
  SET(CMAKE_AR ${ZIG_TOOLCHAIN_PATH})
  SET(CMAKE_RANLIB ${ZIG_TOOLCHAIN_PATH})

  set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> ar qc <TARGET> <LINK_FLAGS> <OBJECTS>")
  SET(CMAKE_C_ARCHIVE_FINISH "<CMAKE_RANLIB> ranlib <TARGET>")
  set(CMAKE_C_ARCHIVE_APPEND "<CMAKE_AR> ar q <TARGET> <LINK_FLAGS> <OBJECTS>")

  SET(CMAKE_ASM_ARCHIVE_CREATE ${CMAKE_C_ARCHIVE_CREATE})
  SET(CMAKE_ASM_ARCHIVE_FINISH ${CMAKE_C_ARCHIVE_FINISH})
  SET(CMAKE_ASM_ARCHIVE_APPEND ${CMAKE_C_ARCHIVE_APPEND})

  SET(CMAKE_CXX_ARCHIVE_CREATE ${CMAKE_C_ARCHIVE_CREATE})
  SET(CMAKE_CXX_ARCHIVE_FINISH ${CMAKE_C_ARCHIVE_FINISH})
  SET(CMAKE_CXX_ARCHIVE_APPEND ${CMAKE_C_ARCHIVE_APPEND})

  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  message(STATUS "summary of zig toollchains build options:
    Install prefix:  ${CMAKE_INSTALL_PREFIX}
    Target system:   ${CMAKE_SYSTEM_NAME}
    Target arch:     ${CMAKE_SYSTEM_PROCESSOR}

    Compiler:
      C compiler:    ${CMAKE_C_COMPILER} (${CMAKE_C_COMPILER_ID})
      CFLAGS:        ${CMAKE_C_COMPLIER_FLAGS}
")
endif()
