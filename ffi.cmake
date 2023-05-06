cmake_minimum_required(VERSION 2.8.12)
project(lua-ffi C)

set(CMAKE_MACOSX_RPATH 1)
option(BUILD_SHARED_LUA_FFI "Shared or Static lua-ffi" ON)

include(GNUInstallDirs)

find_package(PkgConfig REQUIRED)
pkg_check_modules (FFI REQUIRED libffi)

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)

if(BUILD_SHARED_LUA_FFI)
    set(LUA_FFI_LIBTYPE MODULE)
    if(WIN32)
        add_definitions(-DLUA_BUILD_AS_DLL)
    endif()
else()
    set(LUA_FFI_LIBTYPE STATIC)
endif()

add_library(luaffi ${LUA_FFI_LIBTYPE}
    ${CMAKE_CURRENT_LIST_DIR}/../thirdparty/ffi/ffi.c
)

target_include_directories(luaffi PUBLIC
    ${FFI_INCLUDE_DIR}
    ${LUA_INCLUDE_DIR}
    ${CMAKE_CURRENT_LIST_DIR}/../thirdparty/compat-5.3
)

if(BUILD_SHARED_LUA_FFI)
    target_link_libraries(luaffi PUBLIC
        ${FFI_LIBRARIES}
        Threads::Threads
    )

    if(WIN32)
        target_link_libraries(luaffi PUBLIC ${LUA_LIBRARIES})
    endif()

    if(APPLE)
        target_link_options(luaffi PUBLIC -bundle -undefined dynamic_lookup)
    endif()

    set_target_properties(luaffi PROPERTIES
        PREFIX ""
        OUTPUT_NAME "ffi"
    )

    install(TARGETS luaffi
        LIBRARY DESTINATION
        ${CMAKE_INSTALL_LIBDIR}/lua/${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}
    )
else()
    get_directory_property(hasParent PARENT_DIRECTORY)
    if(hasParent)
        set(LUA_FFI_LIBS luaffi ${FFI_LIBRARIES} PARENT_SCOPE)
    else()
        set(LUA_FFI_LIBS luaffi ${FFI_LIBRARIES})
    endif()
endif()
