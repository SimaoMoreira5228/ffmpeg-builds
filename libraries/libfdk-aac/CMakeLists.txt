project(libfdk-aac)

include(ExternalProject)

ExternalProject_Add(
  libfdk-aac
  GIT_REPOSITORY https://github.com/mstorsjo/fdk-aac.git
  GIT_TAG 716f4394641d53f0d79c9ddac3fa93b03a49f278 # v2.0.3
  PREFIX ${CMAKE_BINARY_DIR}/_deps/libfdk-aac
  LOG_CONFIGURE ON
  LOG_INSTALL ON
  LOG_BUILD ON
  LOG_OUTPUT_ON_FAILURE ON
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -G${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DBUILD_SHARED_LIBS=OFF
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
  INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/libfdk-aac
)

set_target_properties(libfdk-aac PROPERTIES
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/_install/libfdk-aac/lib/libfdk-aac.a
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/_install/libfdk-aac/include
  CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR}/_install/libfdk-aac/lib/cmake/fdk-aac
  PKG_CONFIG_PATH ${CMAKE_BINARY_DIR}/_install/libfdk-aac/lib/pkgconfig
  INCLUDE_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libfdk-aac/include
  LIBRARY_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libfdk-aac/lib
)
