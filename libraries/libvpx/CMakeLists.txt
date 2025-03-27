project(libvpx)

include(ExternalProject)

set(LIBVPX_PREFIX ${CMAKE_BINARY_DIR}/_deps/libvpx)
set(LIBVPX_INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/libvpx)
set(LIBVPX_SOURCE_DIR ${LIBVPX_PREFIX}/src)
set(LIBVPX_TMP_DIR ${LIBVPX_PREFIX}/tmp)
set(LIBVPX_STAMP_DIR ${LIBVPX_PREFIX}/stamp)
set(LIBVPX_LOG_DIR ${LIBVPX_PREFIX}/log)
set(LIBVPX_BINARY_DIR ${LIBVPX_PREFIX}/build)

find_program(BASH_BIN bash)

ExternalProject_Add(libvpx
    GIT_REPOSITORY https://github.com/webmproject/libvpx.git
    GIT_TAG 39e8b9dcd4696d9ac3ebd4722e012488382f1adb # v1.15.1-rc1
    PREFIX ${LIBVPX_PREFIX}
    TMP_DIR ${LIBVPX_TMP_DIR}
    STAMP_DIR ${LIBVPX_STAMP_DIR}
    INSTALL_DIR ${LIBVPX_INSTALL_DIR}
    SOURCE_DIR ${LIBVPX_SOURCE_DIR}
    LOG_DIR ${LIBVPX_LOG_DIR}
    UPDATE_DISCONNECTED TRUE
    WORKING_DIRECTORY ${LIBVPX_SOURCE_DIR}
    BUILD_IN_SOURCE TRUE
    LOG_CONFIGURE ON
    LOG_INSTALL ON
    LOG_BUILD ON
    LOG_OUTPUT_ON_FAILURE ON
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${BASH_BIN} ./configure
        --prefix=${LIBVPX_INSTALL_DIR}
        --disable-shared
        --enable-static
        --disable-examples
        --disable-tools
        --disable-docs
        --disable-unit_tests
        --disable-decode_perf_tests
        --disable-encode_perf_tests
        --enable-vp8
        --enable-vp9
        --enable-multithread
    BUILD_COMMAND make -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
)

set_target_properties(libvpx PROPERTIES
    IMPORTED_LOCATION ${LIBVPX_INSTALL_DIR}/lib/libvpx.a
    INTERFACE_INCLUDE_DIRECTORIES ${LIBVPX_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${LIBVPX_INSTALL_DIR}/lib/pkgconfig
    INCLUDE_DIRECTORY ${LIBVPX_INSTALL_DIR}/include
    LIBRARY_DIRECTORY ${LIBVPX_INSTALL_DIR}/lib
)
