cmake_minimum_required(VERSION 3.0)

if(NOT LUAJIT_DIR)
  message(FATAL_ERROR "Must set LUAJIT_DIR to build luajit with CMake")
endif()

project(luajit)

include(LuaJIT.cmake)

