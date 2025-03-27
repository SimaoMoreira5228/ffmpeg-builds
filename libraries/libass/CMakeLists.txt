project(libass)

find_program(MESON_BIN meson)

add_external_target(libass
    GIT_REPOSITORY https://github.com/libass/libass.git
    GIT_TAG e46aedea0a0d17da4c4ef49d84b94a7994664ab5
    BUILD_IN_SOURCE TRUE
    CONFIGURE_COMMAND ${MESON_BIN}
        setup build
        --prefix=<INSTALL_DIR>
        --optimization=3
        --libdir=lib
        --buildtype=release
        --default-library=static
        --wrap-mode=nodownload
        -Dtest=false
        -Dlibunibreak=disabled
    BUILD_COMMAND ${MESON_BIN} compile -C build
    INSTALL_COMMAND ${MESON_BIN} install -C build
    DEPENDS fribidi fontconfig libfreetype harfbuzz
)

set_target_properties(libass PROPERTIES
    LIBRARY_DIRECTORY ${libass_INSTALL_DIR}/lib
    INCLUDE_DIRECTORY ${libass_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${libass_INSTALL_DIR}/lib/pkgconfig
)
