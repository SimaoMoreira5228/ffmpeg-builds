project(libfreetype)

include(ExternalProject)

ExternalProject_Add(
  libfreetype
  GIT_REPOSITORY https://github.com/freetype/freetype.git
  GIT_TAG 42608f77f20749dd6ddc9e0536788eaad70ea4b5 # v2.13.3
  PREFIX ${CMAKE_BINARY_DIR}/_deps/libfreetype
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
    -DZLIB_INCLUDE_DIR=$<TARGET_PROPERTY:zlib,INTERFACE_INCLUDE_DIRECTORIES>
    -DZLIB_LIBRARY=$<TARGET_PROPERTY:zlib,IMPORTED_LOCATION>
    -DFT_DISABLE_BZIP2=ON
    -DFT_REQUIRE_ZLIB=ON
    -DFT_DISABLE_PNG=ON
    -DFT_DISABLE_HARFBUZZ=ON
    -DFT_DISABLE_BROTLI=ON
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
  INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/libfreetype
  DEPENDS zlib
)

set_target_properties(libfreetype PROPERTIES
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/_install/libfreetype/lib/libfreetype.a
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/_install/libfreetype/include
  CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR}/_install/libfreetype/lib/cmake/freetype
  PKG_CONFIG_PATH ${CMAKE_BINARY_DIR}/_install/libfreetype/lib/pkgconfig
  INCLUDE_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libfreetype/include
  LIBRARY_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libfreetype/lib
)
