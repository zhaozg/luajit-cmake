# - Try to find libunwind
# Once done this will define
#
function(check_unwind_tables output_var)
  # 创建测试目录
  set(TEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/unwind_check)
  file(MAKE_DIRECTORY ${TEST_DIR})

  # 测试源代码
  set(TEST_SRC_FILE ${TEST_DIR}/test.c)
  file(WRITE ${TEST_SRC_FILE} "
      extern void b(void);
      int a(void) { b(); return 0; }
  ")

  # 编译测试文件
  set(OBJ_FILE ${TEST_DIR}/test.o)
  execute_process(
      COMMAND ${CMAKE_C_COMPILER} ${CMAKE_C_FLAGS} -c ${TEST_SRC_FILE} -o ${OBJ_FILE}
      WORKING_DIRECTORY ${TEST_DIR}
      RESULT_VARIABLE COMPILE_RESULT
      ERROR_QUIET
      OUTPUT_QUIET
  )

  if(COMPILE_RESULT EQUAL 0 AND EXISTS ${OBJ_FILE})
      # 检查目标文件
      find_program(READELF readelf)
      find_program(OBJDUMP objdump)

      if(READELF)
          execute_process(
              COMMAND ${READELF} -S ${OBJ_FILE}
              OUTPUT_VARIABLE SECTIONS
              ERROR_QUIET
          )
          if(SECTIONS MATCHES "\.eh_frame|\.eh_frame_hdr")
              set(${output_var} TRUE PARENT_SCOPE)
          else()
              set(${output_var} FALSE PARENT_SCOPE)
          endif()
      elseif(OBJDUMP)
          execute_process(
              COMMAND ${OBJDUMP} -h ${OBJ_FILE}
              OUTPUT_VARIABLE HEADERS
              ERROR_QUIET
          )
          if(HEADERS MATCHES "\.eh_frame")
              set(${output_var} TRUE PARENT_SCOPE)
          else()
              set(${output_var} FALSE PARENT_SCOPE)
          endif()
      else()
          # 回退方案：检查文件大小（包含 unwind 信息的文件通常更大）
          file(SIZE ${OBJ_FILE} OBJ_SIZE)
          if(OBJ_SIZE GREATER 500)  # 阈值可能需要调整
              set(${output_var} TRUE PARENT_SCOPE)
          else()
              set(${output_var} FALSE PARENT_SCOPE)
          endif()
      endif()
  else()
      set(${output_var} FALSE PARENT_SCOPE)
  endif()

  # 清理
  file(REMOVE_RECURSE ${TEST_DIR})
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
endif ()
