project(libopus)

include(ExternalProject)

ExternalProject_Add(
  libopus
  GIT_REPOSITORY https://github.com/xiph/opus.git
  GIT_TAG ddbe48383984d56acd9e1ab6a090c54ca6b735a6 # v1.5.2
  PREFIX ${CMAKE_BINARY_DIR}/_deps/libopus
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
    -DOPUS_BUILD_SHARED_LIBRARY=OFF
    -DOPUS_BUILD_TESTING=OFF
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
  INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/libopus
)

set_target_properties(libopus PROPERTIES
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/_install/libopus/lib/libopus.a
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/_install/libopus/include
  CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR}/_install/libopus/lib/cmake/Opus
  PKG_CONFIG_PATH ${CMAKE_BINARY_DIR}/_install/libopus/lib/pkgconfig
  INCLUDE_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libopus/include
  LIBRARY_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libopus/lib
)
