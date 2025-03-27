project(libvorbis)

include(ExternalProject)

set(CMAKE_LD_FLAGS "-lm -pthread")

ExternalProject_Add(
  libvorbis
  GIT_REPOSITORY https://github.com/xiph/vorbis.git
  GIT_TAG 0657aee69dec8508a0011f47f3b69d7538e9d262 # v1.3.7
  PREFIX ${CMAKE_BINARY_DIR}/_deps/libvorbis
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
    -DOGG_INCLUDE_DIR=$<TARGET_PROPERTY:libogg,INTERFACE_INCLUDE_DIRECTORIES>
    -DOGG_LIBRARY=$<TARGET_PROPERTY:libogg,IMPORTED_LOCATION>
    -DCMAKE_LD_FLAGS=${CMAKE_LD_FLAGS}
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE}
  INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/libvorbis
  DEPENDS libogg
)

if(APPLE)
    ExternalProject_Add_Step(
        libvorbis
        apply_patch
        COMMAND sed -i "" "s/ -force_cpusubtype_ALL//g" ${CMAKE_BINARY_DIR}/_deps/libvorbis/src/libvorbis/configure.ac
        DEPENDEES download
        COMMENT "Applying patch to libvorbis"
    )
endif()

set_target_properties(libvorbis PROPERTIES
  IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/_install/libvorbis/lib/libvorbis.a
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/_install/libvorbis/include
  CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR}/_install/libvorbis/lib/cmake/Vorbis
  PKG_CONFIG_PATH ${CMAKE_BINARY_DIR}/_install/libvorbis/lib/pkgconfig
  INCLUDE_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libvorbis/include
  LIBRARY_DIRECTORY ${CMAKE_BINARY_DIR}/_install/libvorbis/lib
)
