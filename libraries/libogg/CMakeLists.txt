project(libogg)

include(ExternalProject)

set(CMAKE_LD_FLAGS "-lm -pthread")

ExternalProject_Add(
  libogg
  GIT_REPOSITORY https://github.com/xiph/ogg.git
  GIT_TAG e1774cd77f471443541596e09078e78fdc342e4f # v1.3.5
  PREFIX ${CMAKE_BINARY_DIR}/_deps/libogg
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
    -DCMAKE_LD_FLAGS=${CMAKE_LD_FLAGS}
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
  INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/libogg
)

set_target_properties(libogg PROPERTIES
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/_install/libogg/lib/libogg.a
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/_install/libogg/include
  CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR}/_install/libogg/lib/cmake/Ogg
  PKG_CONFIG_PATH ${CMAKE_BINARY_DIR}/_install/libogg/lib/pkgconfig
  INCLUDE_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libogg/include
  LIBRARY_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libogg/lib
)
