project(fribidi)

find_program(MESON_BIN meson REQUIRED)

add_external_target(fribidi
    GIT_REPOSITORY https://github.com/fribidi/fribidi.git
    GIT_TAG 68162babff4f39c4e2dc164a5e825af93bda9983 # v1.0.16
    CONFIGURE_COMMAND ${MESON_BIN} 
        setup <BINARY_DIR> <SOURCE_DIR>
        --prefix=<INSTALL_DIR>
        --optimization=3
        --libdir=lib
        --buildtype=release
        --default-library=static
        --wrap-mode=nodownload
        -Ddocs=false
        -Dtests=false
        -Dbin=false
    BUILD_COMMAND ${MESON_BIN} compile -C <BINARY_DIR>
    INSTALL_COMMAND ${MESON_BIN} install -C <BINARY_DIR>
)

set_target_properties(fribidi PROPERTIES
    LIBRARY_DIRECTORY ${fribidi_INSTALL_DIR}/lib
    INCLUDE_DIRECTORY ${fribidi_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${fribidi_INSTALL_DIR}/lib/pkgconfig
    LIBRARY_FILE ${fribidi_INSTALL_DIR}/lib/libfribidi${STATIC_LIBRARY_EXTENSION}
)
