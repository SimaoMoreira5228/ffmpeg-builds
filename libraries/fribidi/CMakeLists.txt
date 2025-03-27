project(fribidi)

include(ExternalProject)

set(FRIBIDI_PREFIX ${CMAKE_BINARY_DIR}/_deps/fribidi)
set(FRIBIDI_INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/fribidi)
set(FRIBIDI_SOURCE_DIR ${FRIBIDI_PREFIX}/src)
set(FRIBIDI_TMP_DIR ${FRIBIDI_PREFIX}/tmp)
set(FRIBIDI_STAMP_DIR ${FRIBIDI_PREFIX}/stamp)
set(FRIBIDI_LOG_DIR ${FRIBIDI_PREFIX}/log)
set(FRIBIDI_BINARY_DIR ${FRIBIDI_PREFIX}/build)

find_program(MESON_BIN meson)

ExternalProject_Add(fribidi
    GIT_REPOSITORY https://github.com/fribidi/fribidi.git
    GIT_TAG 68162babff4f39c4e2dc164a5e825af93bda9983 # v1.0.16
    PREFIX ${FRIBIDI_PREFIX}
    TMP_DIR ${FRIBIDI_TMP_DIR}
    STAMP_DIR ${FRIBIDI_STAMP_DIR}
    INSTALL_DIR ${FRIBIDI_INSTALL_DIR}
    SOURCE_DIR ${FRIBIDI_SOURCE_DIR}
    LOG_DIR ${FRIBIDI_LOG_DIR}
    UPDATE_DISCONNECTED TRUE
    WORKING_DIRECTORY ${FRIBIDI_SOURCE_DIR}
    BUILD_IN_SOURCE TRUE
    LOG_CONFIGURE ON
    LOG_INSTALL ON
    LOG_BUILD ON
    LOG_OUTPUT_ON_FAILURE ON
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${MESON_BIN} setup ${FRIBIDI_BINARY_DIR}
        --prefix=${FRIBIDI_INSTALL_DIR}
        --optimization=3
        --prefer-static
        --libdir=lib
        --buildtype=release
        --default-library=static
        -Ddocs=false
        -Dtests=false
        -Dbin=false
    BUILD_COMMAND ${MESON_BIN} compile -C ${FRIBIDI_BINARY_DIR}
    INSTALL_COMMAND ${MESON_BIN} install -C ${FRIBIDI_BINARY_DIR}
)

set_target_properties(fribidi PROPERTIES
    IMPORTED_LOCATION ${FRIBIDI_INSTALL_DIR}/lib/libfribidi.a
    INTERFACE_INCLUDE_DIRECTORIES ${FRIBIDI_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${FRIBIDI_INSTALL_DIR}/lib/pkgconfig
    INCLUDE_DIRECTORY ${FRIBIDI_INSTALL_DIR}/include
    LIBRARY_DIRECTORY ${FRIBIDI_INSTALL_DIR}/lib
)
