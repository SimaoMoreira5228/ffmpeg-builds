project(libmp3lame)

if(WIN32)
    set(ENV_ARGS "LD=link" "MSYS_NO_PATHCONV=1" "CONFIG_SHELL=bash")
else()
    set(ENV_ARGS "CFLAGS=-O3")
    set(CONFIGURE_ARGS "--with-pic" "--enable-nasm")
endif()

add_external_target(libmp3lame
    URL https://sourceforge.net/projects/lame/files/lame/3.100/lame-3.100.tar.gz/download
    URL_HASH SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
    CONFIGURE_COMMAND ${BASH_BIN} <SOURCE_DIR>/configure
        --prefix=<INSTALL_DIR>
        --enable-static
        --disable-shared
        --disable-gtktest
        --disable-frontend
        ${CONFIGURE_ARGS}
    BUILD_COMMAND ${MAKE_BIN} -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND ${MAKE_BIN} install
    DEPENDS zlib
    ENV_ARGS ${ENV_ARGS}
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
        ${libmp3lame_INSTALL_DIR}/lib/pkgconfig
    COMMAND ${CMAKE_COMMAND} -E copy
        ${LIBMP3LAME_PKG_OUTPUT_FILE}
        ${libmp3lame_INSTALL_DIR}/lib/pkgconfig/libmp3lame.pc
    DEPENDEES install
    DEPENDS ${LIBMP3LAME_PKG_OUTPUT_FILE}
    COMMENT "Generating libmp3lame.pc"
)

set_target_properties(libmp3lame PROPERTIES
    INCLUDE_DIRECTORY ${libmp3lame_INSTALL_DIR}/include
    LIBRARY_DIRECTORY ${libmp3lame_INSTALL_DIR}/lib
    PKG_CONFIG_PATH ${libmp3lame_INSTALL_DIR}/lib/pkgconfig
    LIBRARY_FILE ${libmp3lame_INSTALL_DIR}/lib/libmp3lame${STATIC_LIBRARY_EXTENSION}
    CFLAGS "-I${libmp3lame_INSTALL_DIR}/include"
    CXXFLAGS "-I${libmp3lame_INSTALL_DIR}/include"
    LDFLAGS "-L${libmp3lame_INSTALL_DIR}/lib -lmp3lame"
)
