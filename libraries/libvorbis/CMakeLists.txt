project(libvorbis)

if(UNIX)
    set(CONFIGURE_ARGS "-DCMAKE_LD_FLAGS=-lm -pthread")
endif()

add_external_target(
  libvorbis
  GIT_REPOSITORY https://github.com/xiph/vorbis.git
  GIT_TAG 0657aee69dec8508a0011f47f3b69d7538e9d262 # v1.3.7
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -G${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_INSTALL_BINDIR=bin
    -DCMAKE_INSTALL_INCLUDEDIR=include
    -DCMAKE_INSTALL_SHAREDIR=share
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ${CONFIGURE_ARGS}
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --config ${CMAKE_BUILD_TYPE}
  INSTALL_COMMAND ${CMAKE_COMMAND} --install .
  DEPENDS libogg
)

if(APPLE)
    ExternalProject_Add_Step(
        libvorbis
        apply_patch
        COMMAND sed -i "" "s/ -force_cpusubtype_ALL//g" ${libvorbis_SOURCE_DIR}/configure.ac
        DEPENDEES download
        COMMENT "Applying patch to libvorbis"
    )
endif()

set_target_properties(libvorbis PROPERTIES
  LIBRARY_DIRECTORY ${libvorbis_INSTALL_DIR}/lib
  INCLUDE_DIRECTORY ${libvorbis_INSTALL_DIR}/include
  PKG_CONFIG_PATH ${libvorbis_INSTALL_DIR}/lib/pkgconfig
  CMAKE_PREFIX_PATH ${libvorbis_INSTALL_DIR}
)
