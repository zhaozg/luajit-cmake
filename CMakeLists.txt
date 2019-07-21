cmake_minimum_required(VERSION 3.0)

if(LUAJIT_DIR)
  project(luajit)
  include(LuaJIT.cmake)
elseif(LUA_DIR)
  project(lua)
  include(lua.cmake)
else()
  message(FATAL_ERROR
    "Must set LUAJIT_DIR or LUA_DIR to build with CMake")
endif()
