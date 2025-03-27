project(fontconfig)

include(ExternalProject)

set(FONTCONFIG_PREFIX ${CMAKE_BINARY_DIR}/_deps/fontconfig)
set(FONTCONFIG_INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/fontconfig)
set(FONTCONFIG_SOURCE_DIR ${FONTCONFIG_PREFIX}/src)
set(FONTCONFIG_TMP_DIR ${FONTCONFIG_PREFIX}/tmp)
set(FONTCONFIG_STAMP_DIR ${FONTCONFIG_PREFIX}/stamp)
set(FONTCONFIG_LOG_DIR ${FONTCONFIG_PREFIX}/log)
set(FONTCONFIG_BINARY_DIR ${FONTCONFIG_PREFIX}/build)

find_program(MESON_BIN meson)

if(APPLE)
    set(MESON_EXTRA_ARGS "--c_link_args=-framework CoreFoundation -liconv")
endif()

ExternalProject_Add(fontconfig
    GIT_REPOSITORY https://github.com/ScuffleCloud/fontconfig-mirror.git
    GIT_TAG f511346fe16f205f087a97faf32d3c7d07d5b3c8 # v2.16.1
    PREFIX ${FONTCONFIG_PREFIX}
    TMP_DIR ${FONTCONFIG_TMP_DIR}
    STAMP_DIR ${FONTCONFIG_STAMP_DIR}
    INSTALL_DIR ${FONTCONFIG_INSTALL_DIR}
    SOURCE_DIR ${FONTCONFIG_SOURCE_DIR}
    LOG_DIR ${FONTCONFIG_LOG_DIR}
    UPDATE_DISCONNECTED TRUE
    WORKING_DIRECTORY ${FONTCONFIG_SOURCE_DIR}
    BUILD_IN_SOURCE TRUE
    LOG_CONFIGURE ON
    LOG_INSTALL ON
    LOG_BUILD ON
    LOG_OUTPUT_ON_FAILURE ON
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
        PKG_CONFIG_PATH=$<TARGET_PROPERTY:libexpat,PKG_CONFIG_PATH>:$<TARGET_PROPERTY:libpng,PKG_CONFIG_PATH>:$<TARGET_PROPERTY:zlib,PKG_CONFIG_PATH>:$<TARGET_PROPERTY:libfreetype,PKG_CONFIG_PATH>
        ${MESON_BIN} setup ${FONTCONFIG_BINARY_DIR}
        --prefix=${FONTCONFIG_INSTALL_DIR}
        --optimization=3
        --prefer-static
        --libdir=lib
        --buildtype=release
        --default-library=static
        ${MESON_EXTRA_ARGS}
        -Ddoc=disabled
        -Dtests=disabled
        -Dtools=disabled
    BUILD_COMMAND ${MESON_BIN} compile -C ${FONTCONFIG_BINARY_DIR}
    INSTALL_COMMAND ${MESON_BIN} install -C ${FONTCONFIG_BINARY_DIR}
    DEPENDS libexpat libpng zlib libfreetype
)

ExternalProject_Add_Step(
    fontconfig
    remove_shared_libs
    COMMAND ${CMAKE_COMMAND} -DGLOB_PATH=${FONTCONFIG_INSTALL_DIR}/lib/libfontconfig.so* -P ${FFMPEG_STATIC_BUILD_DIR}/cmake/remove_files_glob.cmake
    DEPENDEES install
    COMMENT "Removing shared libraries"
)

set_target_properties(fontconfig PROPERTIES
    IMPORTED_LOCATION ${FONTCONFIG_INSTALL_DIR}/lib/libfontconfig.a
    INTERFACE_INCLUDE_DIRECTORIES ${FONTCONFIG_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${FONTCONFIG_INSTALL_DIR}/lib/pkgconfig
    INCLUDE_DIRECTORY ${FONTCONFIG_INSTALL_DIR}/include
    LIBRARY_DIRECTORY ${FONTCONFIG_INSTALL_DIR}/lib
)
