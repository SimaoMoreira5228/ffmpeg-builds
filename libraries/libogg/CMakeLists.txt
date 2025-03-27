project(libogg)

include(ExternalProject)

add_external_target(libogg
  GIT_REPOSITORY https://github.com/xiph/ogg.git
  GIT_TAG e1774cd77f471443541596e09078e78fdc342e4f # v1.3.5
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -G${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DBUILD_SHARED_LIBS=OFF
    "-DCMAKE_LD_FLAGS=-lm -pthread"
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND}
    --build .
    --target install
    --config ${CMAKE_BUILD_TYPE}
)

set_target_properties(libogg PROPERTIES
  LIBRARY_DIRECTORY ${libogg_INSTALL_DIR}/lib
  INCLUDE_DIRECTORY ${libogg_INSTALL_DIR}/include
  PKG_CONFIG_PATH ${libogg_INSTALL_DIR}/lib/pkgconfig
  CMAKE_MODULE_PATH ${libogg_INSTALL_DIR}/lib/cmake/Ogg
)
