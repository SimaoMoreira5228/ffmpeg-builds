project(libdav1d)

find_program(MESON_BIN meson)

add_external_target(libdav1d
    GIT_REPOSITORY https://github.com/videolan/dav1d.git
    GIT_TAG 42b2b24fb8819f1ed3643aa9cf2a62f03868e3aa
    BUILD_IN_SOURCE TRUE
    CONFIGURE_COMMAND ${MESON_BIN}
        setup build
        --prefix=<INSTALL_DIR>
        --optimization=3
        --libdir=lib
        --buildtype=release
        --default-library=static
        --wrap-mode=nodownload
        -Denable_tools=false
        -Denable_tests=false
    BUILD_COMMAND ${MESON_BIN} compile -C build
    INSTALL_COMMAND ${MESON_BIN} install -C build
)

set_target_properties(libdav1d PROPERTIES
    LIBRARY_DIRECTORY ${libdav1d_INSTALL_DIR}/lib
    INCLUDE_DIRECTORY ${libdav1d_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${libdav1d_INSTALL_DIR}/lib/pkgconfig
    LIBRARY_FILE ${libdav1d_INSTALL_DIR}/lib/libdav1d${STATIC_LIBRARY_EXTENSION}
)
