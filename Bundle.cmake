# Modfied from luajit.cmake Added LUA_ADD_EXECUTABLE Ryan Phillips <ryan at
# trolocsis.com> This CMakeLists.txt has been first taken from LuaDist Copyright
# (C) 2007-2011 LuaDist. Created by Peter Drahoš Redistribution and use of this
# file is allowed according to the terms of the MIT license. Debugged and (now
# seriously) modIFied by Ronan Collobert, for Torch7

if(NOT DEFINED BUNDLE_CMD)
  if(BUNDLE_USE_LUA2C)
    set(BUNDLE_CMD lua CACHE STRING "Use lua to do lua file bundle")
  else()
    set(BUNDLE_CMD luajit CACHE STRING "Use luajit to do lua file bundle")
  endif()
endif()
if(DEFINED ENV{BUNDLE_CMD})
  set(BUNDLE_CMD $ENV{BUNDLE_CMD})
endif()

if(NOT DEFINED BUNDLE_CMD_ARGS)
  set(BUNDLE_CMD_ARGS "" CACHE STRING "Bundle args for cross compile")
endif()
if(NOT DEFINED BUNDLE_USE_LUA2C)
  set(BUNDLE_USE_LUA2C OFF CACHE BOOL "Use bin2c.lua do lua file bundle")
endif()

include (TestBigEndian)
TEST_BIG_ENDIAN(IS_BIG_ENDIAN)
if(IS_BIG_ENDIAN)
  message(STATUS "BIG_ENDIAN")
else()
  message(STATUS "LITTLE_ENDIAN")
endif()

if(NOT DEFINED BUNDLE_DEBUG)
  if(CMAKE_BUILD_TYPE)
    string(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_LOWER)
    if(${CMAKE_BUILD_TYPE_LOWER} STREQUAL "debug"
        OR ${CMAKE_BUILD_TYPE_LOWER} STREQUAL "relwithdebinfo")
      set(BUNDLE_DEBUG ON)
    endif()
  else()
    set(BUNDLE_DEBUG OFF)
  endif()
endif()

if(BUNDLE_USE_LUA2C)
  file(COPY ${CMAKE_CURRENT_LIST_DIR}/lua2c.lua DESTINATION ${LUA_TARGET_PATH})

  if(CMAKE_CROSSCOMPILING AND NOT DEFINED BUNDLE_SOURCE)
    if(${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES 64)
      set(HOST_64 TRUE)
    else()
      set(HOST_64 FALSE)
    endif()
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(TARGET_64 TRUE)
    else()
      set(TARGET_64 FALSE)
    endif()
    if (NOT HOST_64 EQUAL TARGET_64)
      set(BUNDLE_SOURCE ON)
    endif ()
  endif()

  if (BUNDLE_SOURCE)
    set(BUNDLE_WITH_SOURCE "-s")
  elseif (BUNDLE_DEBUG)
    set(BUNDLE_ENABLE_DEBUG "-g")
  endif ()

  macro(LUA_add_custom_commands luajit_target)
    set(target_srcs "")
    foreach(file ${ARGN})
      if(${file} MATCHES ".*\\.lua$")
        if(NOT IS_ABSOLUTE ${file})
          set(file "${CMAKE_CURRENT_SOURCE_DIR}/${file}")
        endif()
        set(source_file ${file})
        string(LENGTH ${CMAKE_SOURCE_DIR} _luajit_source_dir_length)
        string(LENGTH ${file} _luajit_file_length)
        math(EXPR _begin "${_luajit_source_dir_length} + 1")
        math(EXPR _stripped_file_length
              "${_luajit_file_length} - ${_luajit_source_dir_length} - 1")
        string(SUBSTRING  ${file}
                          ${_begin}
                          ${_stripped_file_length}
                          stripped_file)

        set(
          generated_file
          "${CMAKE_BINARY_DIR}/luacode_tmp/${stripped_file}_${luajit_target}_generated.c"
          )

        add_custom_command(
          OUTPUT ${generated_file}
          MAIN_DEPENDENCY ${source_file}
          DEPENDS ${LUA_TARGET}
          COMMAND ${BUNDLE_CMD} ARGS
            ${BUNDLE_CMD_ARGS} lua2c.lua ${BUNDLE_ENABLE_DEBUG} ${BUNDLE_WITH_SOURCE} ${source_file} ${generated_file}
          COMMENT "${BUNDLE_CMD} ${BUNDLE_CMD_ARGS} lua2c.lua ${BUNDLE_ENABLE_DEBUG} ${BUNDLE_WITH_SOURCE} ${source_file} ${generated_file}"
          WORKING_DIRECTORY ${LUA_TARGET_PATH})

        get_filename_component(basedir ${generated_file} PATH)
        file(MAKE_DIRECTORY ${basedir})

        set(target_srcs ${target_srcs} ${generated_file})
        set_source_files_properties(${generated_file}
                                    properties
                                    generated
                                    true  # to say that "it is OK that the obj-
                                          # files do not exist before build time"
                                    )
      else()
        set(target_srcs ${target_srcs} ${file})
      endif()
    endforeach()
  endmacro()

  macro(LUA_ADD_CUSTOM luajit_target)
    lua_add_custom_commands(${luajit_target} ${ARGN})
  endmacro()

  macro(LUA_ADD_EXECUTABLE luajit_target)
    lua_add_custom_commands(${luajit_target} ${ARGN})
    add_executable(${luajit_target} ${target_srcs})
  endmacro()
else()
  if (LJ_TARGET_ARCH)
    message(STATUS "Using user-specified target architecture: ${LJ_TARGET_ARCH}")
    set(BUNDLE_TARGET_ARCH ${LJ_TARGET_ARCH})
  else ()
    if ( CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86|i[3-6]86)$" )
      set(BUNDLE_TARGET_ARCH "x86")
    elseif ( CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64)$" )
      set(BUNDLE_TARGET_ARCH "x64")
    elseif ( CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$" )
      set(BUNDLE_TARGET_ARCH "arm64")
    elseif ( CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm|armv7l|armv8l)$" )
      set(BUNDLE_TARGET_ARCH "arm")
    elseif ( CMAKE_SYSTEM_PROCESSOR MATCHES "^(loongarch64)$" )
      set(BUNDLE_TARGET_ARCH "loongarch64")
    elseif ( CMAKE_SYSTEM_PROCESSOR MATCHES "^(mips64)$" )
      if (IS_BIG_ENDIAN)
        set(BUNDLE_TARGET_ARCH "mips64")
      else()
        set(BUNDLE_TARGET_ARCH "mips64el")
      endif ()
    elseif ( CMAKE_SYSTEM_PROCESSOR MATCHES "^(mips|mipsel)$" )
      if (IS_BIG_ENDIAN)
        set(BUNDLE_TARGET_ARCH "mips")
      else()
        set(BUNDLE_TARGET_ARCH "mipsel")
      endif ()
    elseif ( CMAKE_SYSTEM_PROCESSOR MATCHES "^(ppc64le)$" )
      set(BUNDLE_TARGET_ARCH "ppc64")
    elseif ( CMAKE_SYSTEM_PROCESSOR MATCHES "^(ppc|ppc64)$" )
      if (IS_BIG_ENDIAN)
        set(BUNDLE_TARGET_ARCH "ppc64")
      else()
        set(BUNDLE_TARGET_ARCH "ppc")
      endif()
    else()
      message(FATAL_ERROR "Unsupported target architecture: '${BUNDLE_TARGET_ARCH}'")
    endif()
  endif()

  macro(LUAJIT_add_custom_commands luajit_target)
    set(target_srcs "")

    if(WIN32)
      set(LJDUMP_OPT -b -a ${BUNDLE_TARGET_ARCH} -o windows)
    elseif(APPLE)
      set(LJDUMP_OPT -b -a ${BUNDLE_TARGET_ARCH} -o osx)
    elseif(ANDROID OR ${CMAKE_SYSTEM_NAME} STREQUAL Linux)
      set(LJDUMP_OPT -b -a ${BUNDLE_TARGET_ARCH} -o linux)
    else()
      set(LJDUMP_OPT -b -a ${BUNDLE_TARGET_ARCH})
    endif()
    if (BUNDLE_DEBUG)
      list(APPEND LJDUMP_OPT -g)
    endif ()

    foreach(file ${ARGN})
      if(${file} MATCHES ".*\\.lua$")
        if(NOT IS_ABSOLUTE ${file})
          set(file "${CMAKE_CURRENT_SOURCE_DIR}/${file}")
        endif()
        set(source_file ${file})
        string(LENGTH ${CMAKE_SOURCE_DIR} _luajit_source_dir_length)
        string(LENGTH ${file} _luajit_file_length)
        math(EXPR _begin "${_luajit_source_dir_length} + 1")
        math(EXPR _stripped_file_length
              "${_luajit_file_length} - ${_luajit_source_dir_length} - 1")
        string(SUBSTRING ${file}
                          ${_begin}
                          ${_stripped_file_length}
                          stripped_file)

        set(
          generated_file
          "${CMAKE_CURRENT_BINARY_DIR}/jitted_tmp/${stripped_file}_${luajit_target}_generated${CMAKE_C_OUTPUT_EXTENSION}"
          )
        string(REPLACE ";" " " LJDUMP_OPT_STR "${LJDUMP_OPT}")

        add_custom_command(
          OUTPUT ${generated_file}
          MAIN_DEPENDENCY ${source_file}
          DEPENDS ${LUA_TARGET}
          COMMAND ${BUNDLE_CMD} ARGS
            ${BUNDLE_CMD_ARGS}
            ${LJDUMP_OPT} ${source_file} ${generated_file}
          COMMENT "${BUNDLE_CMD} ${BUNDLE_CMD_ARGS} ${LJDUMP_OPT_STR} ${source_file} ${generated_file}"
          WORKING_DIRECTORY ${LUA_TARGET_PATH})
        get_filename_component(basedir ${generated_file} PATH)
        file(MAKE_DIRECTORY ${basedir})

        set(target_srcs ${target_srcs} ${generated_file})
        set_source_files_properties(${generated_file}
                                    properties
                                    external_object
                                    true # this is an object file
                                    generated
                                    true  # to say that "it is OK that the obj-
                                          # files do not exist before build time"
                                    )
      else()
        set(target_srcs ${target_srcs} ${file})
      endif()
    endforeach()
  endmacro()

  macro(LUA_ADD_CUSTOM luajit_target)
    luajit_add_custom_commands(${luajit_target} ${ARGN})
  endmacro()

  macro(LUA_ADD_EXECUTABLE luajit_target)
    luajit_add_custom_commands(${luajit_target} ${ARGN})
    add_executable(${luajit_target} ${target_srcs})
  endmacro()

endif()
