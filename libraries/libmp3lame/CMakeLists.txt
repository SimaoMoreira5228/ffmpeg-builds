project(libmp3lame)

find_program(BASH_BIN bash)

add_external_target(libmp3lame
    URL https://sourceforge.net/projects/lame/files/lame/3.100/lame-3.100.tar.gz/download
    URL_HASH SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
    BUILD_IN_SOURCE TRUE
    CONFIGURE_COMMAND ${BASH_BIN} ./configure
        --prefix=<INSTALL_DIR>
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
    CFLAGS "-I${libmp3lame_INSTALL_DIR}/include"
    CXXFLAGS "-I${libmp3lame_INSTALL_DIR}/include"
    LDFLAGS "-L${libmp3lame_INSTALL_DIR}/lib -lmp3lame"
)
