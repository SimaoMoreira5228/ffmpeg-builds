project(harfbuzz)

include(ExternalProject)

add_external_target(harfbuzz
  GIT_REPOSITORY https://github.com/harfbuzz/harfbuzz.git
  GIT_TAG ea6a172f84f2cbcfed803b5ae71064c7afb6b5c2 # v1.0.16
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -G${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_INSTALL_BINDIR=bin
    -DCMAKE_INSTALL_INCLUDEDIR=include
    -DCMAKE_INSTALL_SHAREDIR=share
    -DBUILD_SHARED_LIBS=OFF
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND}
    --build .
    --target install
    --config ${CMAKE_BUILD_TYPE}
  DEPENDS libfreetype
)

set_target_properties(harfbuzz PROPERTIES
  LIBRARY_DIRECTORY ${harfbuzz_INSTALL_DIR}/lib
  INCLUDE_DIRECTORY ${harfbuzz_INSTALL_DIR}/include
  PKG_CONFIG_PATH ${harfbuzz_INSTALL_DIR}/lib/pkgconfig
  CMAKE_PREFIX_PATH ${harfbuzz_INSTALL_DIR}`
  LIBRARY_FILE ${harfbuzz_INSTALL_DIR}/lib/libharfbuzz${STATIC_LIBRARY_EXTENSION}
)
