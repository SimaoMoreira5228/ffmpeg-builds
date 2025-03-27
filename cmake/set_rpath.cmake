# set-rpath.cmake
if(NOT DEFINED GLOB_PATH)
  message(FATAL_ERROR "GLOB_PATH is not defined")
endif()

# Glob for the files
file(GLOB files "${GLOB_PATH}")

if(APPLE)
    set(rpath "@loader_path/../lib")
    find_program(RPATH_TOOL install_name_tool)
elseif(UNIX)
    set(rpath "\$ORIGIN/../lib")
    find_program(RPATH_TOOL patchelf)
else()
    message(STATUS "Unsupported OS: ${CMAKE_SYSTEM_NAME}")
    return()
endif()

foreach(file_path ${files})
    if(APPLE)
        message(STATUS "Setting rpath for ${file_path} to ${rpath}")
        execute_process(COMMAND ${RPATH_TOOL} -add_rpath ${rpath} ${file_path})
    elseif(UNIX)
        message(STATUS "Setting rpath for ${file_path} to ${rpath}")
        execute_process(COMMAND ${RPATH_TOOL} --set-rpath ${rpath} ${file_path})
    endif()
endforeach()
