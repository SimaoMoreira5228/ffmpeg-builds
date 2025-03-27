project(libbrotli)

add_external_target(libbrotli
  GIT_REPOSITORY https://github.com/google/brotli.git
  GIT_TAG ed738e842d2fbdf2d6459e39267a633c4a9b2f5d
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -G${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_TESTING=OFF
    -DBUILD_EXAMPLES=OFF
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND}
    --build .
    --target install
    --config ${CMAKE_BUILD_TYPE}
)

set_target_properties(libbrotli PROPERTIES
  LIBRARY_DIRECTORY ${libbrotli_INSTALL_DIR}/lib
  INCLUDE_DIRECTORY ${libbrotli_INSTALL_DIR}/include
  PKG_CONFIG_PATH ${libbrotli_INSTALL_DIR}/lib/pkgconfig
)
