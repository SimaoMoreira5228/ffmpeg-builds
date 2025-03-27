# remove_files_glob.cmake

if(NOT DEFINED GLOB_PATH)
  message(FATAL_ERROR "GLOB_PATH is not defined")
endif()

# Glob for the files
file(GLOB files "${GLOB_PATH}")

if(files)
  foreach(file_path ${files})
    message(STATUS "Removing file: ${file_path}")
    file(REMOVE "${file_path}")
  endforeach()
else()
  message(STATUS "No files matching ${GLOB_PATH} were found.")
endif()
