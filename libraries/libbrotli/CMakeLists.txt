project(libbrotli)

include(ExternalProject)

ExternalProject_Add(
  libbrotli
  GIT_REPOSITORY https://github.com/google/brotli.git
  GIT_TAG ed738e842d2fbdf2d6459e39267a633c4a9b2f5d
  PREFIX ${CMAKE_BINARY_DIR}/_deps/libbrotli
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
    -DBUILD_TESTING=OFF
    -DBUILD_EXAMPLES=OFF
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
  INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/libbrotli
)

set_target_properties(libbrotli PROPERTIES
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/_install/libbrotli/lib/libbrotli.a
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/_install/libbrotli/include
  CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR}/_install/libbrotli/lib/cmake/brotli
  PKG_CONFIG_PATH ${CMAKE_BINARY_DIR}/_install/libbrotli/lib/pkgconfig
  INCLUDE_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libbrotli/include
  LIBRARY_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libbrotli/lib
)
