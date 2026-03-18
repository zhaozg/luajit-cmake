# - Try to find libunwind
# Once done this will define unwind_FOUND etc.
#
function(check_unwind_tables output_var)
  # 创建临时测试目录
  set(TEST_DIR "${CMAKE_CURRENT_BINARY_DIR}/CMakeUnwindCheck")
  file(MAKE_DIRECTORY "${TEST_DIR}")

  # 测试源文件：一个简单的函数调用，用于触发 unwind 表生成
  set(TEST_SRC_FILE "${TEST_DIR}/test.c")
  file(WRITE "${TEST_SRC_FILE}" "
      extern void b(void);
      int a(void) { b(); return 0; }
  ")

  # 目标文件
  set(OBJ_FILE "${TEST_DIR}/test.o")

  # 将 CMAKE_C_FLAGS 转换为列表，确保参数正确分割
  separate_arguments(C_FLAGS_LIST UNIX_COMMAND "${CMAKE_C_FLAGS}")

  # 构建编译命令（使用列表形式）
  set(COMPILE_CMD ${CMAKE_C_COMPILER} ${C_FLAGS_LIST} -c "${TEST_SRC_FILE}" -o "${OBJ_FILE}")

  # 执行编译
  execute_process(
      COMMAND ${COMPILE_CMD}
      WORKING_DIRECTORY "${TEST_DIR}"
      RESULT_VARIABLE COMPILE_RESULT
      OUTPUT_VARIABLE COMPILE_OUT
      ERROR_VARIABLE COMPILE_ERR
  )

  # 默认输出为假
  set(${output_var} FALSE PARENT_SCOPE)

  if(COMPILE_RESULT EQUAL 0 AND EXISTS "${OBJ_FILE}")
    # 查找可用的工具
    find_program(READELF NAMES readelf)
    find_program(OBJDUMP NAMES objdump)

    set(HAS_UNWIND FALSE)

    if(READELF)
      execute_process(
              COMMAND ${READELF} -S "${OBJ_FILE}"
              OUTPUT_VARIABLE SECTIONS
              ERROR_QUIET
          )
      if(SECTIONS MATCHES "\\.eh_frame|\\.eh_frame_hdr")
        set(HAS_UNWIND TRUE)
      endif()
    elseif(OBJDUMP)
      execute_process(
              COMMAND ${OBJDUMP} -h "${OBJ_FILE}"
              OUTPUT_VARIABLE HEADERS
              ERROR_QUIET
          )
      if(HEADERS MATCHES "\\.eh_frame")
        set(HAS_UNWIND TRUE)
      endif()
    else()
      # 回退方案：检查文件大小（包含 unwind 信息的文件通常较大）
      file(SIZE "${OBJ_FILE}" OBJ_SIZE)
      # 阈值可能需要根据实际情况调整（此处为经验值）
      if(OBJ_SIZE GREATER 500)
        set(HAS_UNWIND TRUE)
      endif()
    endif()

    if(HAS_UNWIND)
      set(${output_var} TRUE PARENT_SCOPE)
      message(STATUS "Checking unwind tables: yes")
    else()
      message(STATUS "Checking unwind tables: no")
    endif()
  else()
    # 编译失败，输出错误信息（可选）
    message(STATUS "Compilation test for unwind tables failed: ${COMPILE_ERR}")
  endif()

  file(REMOVE_RECURSE "${TEST_DIR}")
endfunction()

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
endif()
