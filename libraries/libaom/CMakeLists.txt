project(libaom)

include(ExternalProject)

add_external_target(libaom
  GIT_REPOSITORY https://github.com/ScuffleCloud/aom-mirror.git
  GIT_TAG 3b624af45b86646a20b11a9ff803aeae588cdee6 # v3.12.0
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -G${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DBUILD_SHARED_LIBS=OFF
    -DENABLE_TESTS=OFF
    -DENABLE_DOCS=OFF
    -DENABLE_EXAMPLES=OFF
    -DENABLE_TOOLS=OFF
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND}
    --build .
    --target install
    --config ${CMAKE_BUILD_TYPE}
)

set_target_properties(libaom PROPERTIES
  LIBRARY_DIRECTORY ${libaom_INSTALL_DIR}/lib
  INCLUDE_DIRECTORY ${libaom_INSTALL_DIR}/include
  PKG_CONFIG_PATH ${libaom_INSTALL_DIR}/lib/pkgconfig
)
