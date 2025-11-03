# - Try to find libunwind
# Once done this will define
#
#  unwind_FOUND - system has libunwind
#  unwind - cmake target for libunwind


if(CMAKE_CROSSCOMPILING)
  set(UNWIND_SEARCH_PATH
    "${CMAKE_SYSROOT}/usr/lib/${CMAKE_ANDROID_ARCH_ABI}"
    "${CMAKE_SYSROOT}/usr/lib"
    "${CMAKE_SYSROOT}/lib"
  )
  find_library(UNWIND_LIBRARY NAMES unwind
    PATHS ${UNWIND_SEARCH_PATH}
    NO_DEFAULT_PATH
    DOC "unwind library"
  )
else()
  find_library (UNWIND_LIBRARY NAMES unwind DOC "unwind library")
endif()

include (CheckIncludeFile)

check_include_file (unwind.h HAVE_UNWIND_H)
if (NOT HAVE_UNWIND_H)
    check_include_file (libunwind.h HAVE_UNWIND_H)
endif ()

string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" CMAKE_SYSTEM_PROCESSOR_LC)
if (CMAKE_SYSTEM_PROCESSOR_LC MATCHES "^arm")
    set(LIBUNWIND_ARCH "arm")
elseif (CMAKE_SYSTEM_PROCESSOR_LC MATCHES "^aarch64" OR
        CMAKE_SYSTEM_PROCESSOR_LC MATCHES "^arm64")
    set(LIBUNWIND_ARCH "aarch64")
elseif (CMAKE_SYSTEM_PROCESSOR_LC STREQUAL "x86_64" OR
        CMAKE_SYSTEM_PROCESSOR_LC STREQUAL "amd64" OR
        CMAKE_SYSTEM_PROCESSOR_LC STREQUAL "corei7-64")
    set(LIBUNWIND_ARCH "x86_64")
elseif (CMAKE_SYSTEM_PROCESSOR_LC MATCHES "^i.86$")
    set(LIBUNWIND_ARCH "x86")
elseif (CMAKE_SYSTEM_PROCESSOR_LC MATCHES "^ppc64")
    set(LIBUNWIND_ARCH "ppc64")
elseif (CMAKE_SYSTEM_PROCESSOR_LC MATCHES "^ppc")
    set(LIBUNWIND_ARCH "ppc32")
elseif (CMAKE_SYSTEM_PROCESSOR_LC MATCHES "^mips")
    set(LIBUNWIND_ARCH "mips")
elseif (CMAKE_SYSTEM_PROCESSOR_LC MATCHES "^hppa")
    set(LIBUNWIND_ARCH "hppa")
elseif (CMAKE_SYSTEM_PROCESSOR_LC MATCHES "^ia64")
    set(LIBUNWIND_ARCH "ia64")
endif()

if (UNWIND_LIBRARY MATCHES "_FOUND")
    set(UNWIND_LIBRARY unwind)
    set(HAVE_UNWIND_LIB ON)
else()
    find_library (UNWIND_LIBRARY NAMES "unwind-${LIBUNWIND_ARCH}" DOC "unwind library platform")
    if (UNWIND_LIBRARY MATCHES "_FOUND")
        set(HAVE_UNWIND_LIB ON)
        set(UNWIND_LIBRARY unwind-${LIBUNWIND_ARCH})
    endif ()
endif()

if (HAVE_UNWIND_LIB AND HAVE_UNWIND_H)
  set(unwind_FOUND ON)
elseif(HAVE_UNWIND_H)
  message(STATUS "Checking for architecture specific unwind library...")
  message(STATUS "  System processor: ${CMAKE_SYSTEM_PROCESSOR}")
  message(STATUS "  C Compiler ID: ${CMAKE_C_COMPILER_ID}")
  if (CMAKE_C_COMPILER_ID STREQUAL zig
      AND NOT ANDROID
      AND NOT IOS)
    message(STATUS "  Using zig compiler, setting unwind library to 'unwind'")
    set(UNWIND_LIBRARY "unwind")
    set(HAVE_UNWIND_LIB ON)
    set(unwind_FOUND ON)
  endif()
endif ()
