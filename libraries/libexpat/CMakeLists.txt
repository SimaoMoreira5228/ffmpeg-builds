project(libexpat)

include(ExternalProject)

add_external_target(libexpat
  GIT_REPOSITORY https://github.com/libexpat/libexpat.git
  GIT_TAG 6d4ffe856df497ac2cae33537665c3fec7ec8a00 # v2.7.0
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -G${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_INSTALL_BINDIR=bin
    -DCMAKE_INSTALL_INCLUDEDIR=include
    -DCMAKE_INSTALL_SHAREDIR=share
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DEXPAT_BUILD_TOOLS=OFF
    -DEXPAT_BUILD_DOCS=OFF
    -DEXPAT_BUILD_EXAMPLES=OFF
    -DEXPAT_BUILD_TESTS=OFF
    -DEXPAT_SHARED_LIBS=OFF
    <SOURCE_DIR>/expat
  BUILD_COMMAND ${CMAKE_COMMAND}
    --build .
    --target install
    --config ${CMAKE_BUILD_TYPE}
)

set_target_properties(libexpat PROPERTIES
  LIBRARY_DIRECTORY ${libexpat_INSTALL_DIR}/lib
  INCLUDE_DIRECTORY ${libexpat_INSTALL_DIR}/include
  PKG_CONFIG_PATH ${libexpat_INSTALL_DIR}/lib/pkgconfig
  CMAKE_PREFIX_PATH ${libexpat_INSTALL_DIR}/lib/cmake/expat-2.7.0
)
