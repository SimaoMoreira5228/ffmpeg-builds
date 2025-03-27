project(zlib)

include(ExternalProject)

ExternalProject_Add(
  zlib
  GIT_REPOSITORY https://github.com/madler/zlib.git
  GIT_TAG 51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf
  PREFIX ${CMAKE_BINARY_DIR}/_deps/zlib
  UPDATE_COMMAND ""
  LOG_CONFIGURE ON
  LOG_INSTALL ON
  LOG_BUILD ON
  LOG_OUTPUT_ON_FAILURE ON
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -G${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DBUILD_SHARED_LIBS=OFF
    -DZLIB_BUILD_EXAMPLES=OFF
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
  INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/zlib
)

ExternalProject_Add_Step(
    zlib
    remove_shared_libs
    COMMAND ${CMAKE_COMMAND} -DGLOB_PATH=${CMAKE_BINARY_DIR}/_install/zlib/lib/libz.so* -P ${FFMPEG_STATIC_BUILD_DIR}/cmake/remove_files_glob.cmake
    DEPENDEES install
    COMMENT "Removing shared libraries"
)

set_target_properties(zlib PROPERTIES
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/_install/zlib/lib/libz.a
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/_install/zlib/include
  PKG_CONFIG_PATH ${CMAKE_BINARY_DIR}/_install/zlib/share/pkgconfig
  INCLUDE_DIRECTORY ${CMAKE_BINARY_DIR}/_install/zlib/include
  LIBRARY_DIRECTORY ${CMAKE_BINARY_DIR}/_install/zlib/lib
)
