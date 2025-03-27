project(libmp3lame)

include(ExternalProject)

set(LIBMP3LAME_PREFIX ${CMAKE_BINARY_DIR}/_deps/libmp3lame)
set(LIBMP3LAME_INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/libmp3lame)
set(LIBMP3LAME_SOURCE_DIR ${LIBMP3LAME_PREFIX}/src)
set(LIBMP3LAME_TMP_DIR ${LIBMP3LAME_PREFIX}/tmp)
set(LIBMP3LAME_STAMP_DIR ${LIBMP3LAME_PREFIX}/stamp)
set(LIBMP3LAME_LOG_DIR ${LIBMP3LAME_PREFIX}/log)
set(LIBMP3LAME_BINARY_DIR ${LIBMP3LAME_PREFIX}/build)

find_program(BASH_BIN bash)

ExternalProject_Add(libmp3lame
    URL https://sourceforge.net/projects/lame/files/lame/3.100/lame-3.100.tar.gz/download
    URL_HASH SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
    DOWNLOAD_NO_PROGRESS TRUE
    PREFIX ${LIBMP3LAME_PREFIX}
    TMP_DIR ${LIBMP3LAME_TMP_DIR}
    STAMP_DIR ${LIBMP3LAME_STAMP_DIR}
    INSTALL_DIR ${LIBMP3LAME_INSTALL_DIR}
    SOURCE_DIR ${LIBMP3LAME_SOURCE_DIR}
    LOG_DIR ${LIBMP3LAME_LOG_DIR}
    UPDATE_DISCONNECTED TRUE
    WORKING_DIRECTORY ${LIBMP3LAME_SOURCE_DIR}
    BUILD_IN_SOURCE TRUE
    LOG_CONFIGURE ON
    LOG_INSTALL ON
    LOG_BUILD ON
    LOG_OUTPUT_ON_FAILURE ON
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${BASH_BIN} ./configure
            --prefix=${LIBMP3LAME_INSTALL_DIR}
            --enable-static
            --disable-shared
            --enable-nasm
            --disable-gtktest
            --disable-frontend
            --with-pic
    BUILD_COMMAND make -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
    DEPENDS zlib
)

set(LIBMP3LAME_PKG_OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/libmp3lame.pc)

configure_file(
    ${CMAKE_CURRENT_LIST_DIR}/libmp3lame.pc.in
    ${LIBMP3LAME_PKG_OUTPUT_FILE}
    @ONLY
)

ExternalProject_Add_Step(
    libmp3lame
    generate_pc
    COMMAND ${CMAKE_COMMAND} -E make_directory
        ${LIBMP3LAME_INSTALL_DIR}/lib/pkgconfig
    COMMAND ${CMAKE_COMMAND} -E copy
        ${LIBMP3LAME_PKG_OUTPUT_FILE}
        ${LIBMP3LAME_INSTALL_DIR}/lib/pkgconfig/libmp3lame.pc
    DEPENDEES install
    DEPENDS ${LIBMP3LAME_PKG_OUTPUT_FILE}
    COMMENT "Generating libmp3lame.pc"
)

set_target_properties(libmp3lame PROPERTIES
    IMPORTED_LOCATION ${LIBMP3LAME_INSTALL_DIR}/lib/libmp3lame.a
    INTERFACE_INCLUDE_DIRECTORIES ${LIBMP3LAME_INSTALL_DIR}/include
    INCLUDE_DIRECTORY ${LIBMP3LAME_INSTALL_DIR}/include
    LIBRARY_DIRECTORY ${LIBMP3LAME_INSTALL_DIR}/lib
    PKG_CONFIG_PATH ${LIBMP3LAME_INSTALL_DIR}/lib/pkgconfig
)
