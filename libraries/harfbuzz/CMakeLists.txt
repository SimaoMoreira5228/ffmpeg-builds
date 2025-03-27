project(harfbuzz)

include(ExternalProject)

ExternalProject_Add(
  harfbuzz
  GIT_REPOSITORY https://github.com/harfbuzz/harfbuzz.git
  GIT_TAG ea6a172f84f2cbcfed803b5ae71064c7afb6b5c2 # v1.0.16
  PREFIX ${CMAKE_BINARY_DIR}/_deps/harfbuzz
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
    -DFREETYPE_INCLUDE_DIR=$<TARGET_PROPERTY:libfreetype,INTERFACE_INCLUDE_DIRECTORIES>
    -DFREETYPE_LIBRARY=$<TARGET_PROPERTY:libfreetype,IMPORTED_LOCATION>
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
  INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/harfbuzz
  DEPENDS libfreetype
)

set_target_properties(harfbuzz PROPERTIES
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/_install/harfbuzz/lib/libharfbuzz.a
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/_install/harfbuzz/include
  CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR}/_install/harfbuzz/lib/cmake/harfbuzz
  PKG_CONFIG_PATH ${CMAKE_BINARY_DIR}/_install/harfbuzz/lib/pkgconfig
  INCLUDE_DIRECTORY ${CMAKE_BINARY_DIR}/_install/harfbuzz/include
  LIBRARY_DIRECTORY ${CMAKE_BINARY_DIR}/_install/harfbuzz/lib
)
