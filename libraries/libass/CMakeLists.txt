project(libass)

find_program(MESON_BIN meson REQUIRED)

if(WIN32)
    set(fontconfig disabled)
    set(directwrite enabled)
else()
    set(fontconfig enabled)
    set(directwrite disabled)
    set(ADDITIONAL_DEPS fontconfig)
endif()

add_external_target(libass
    GIT_REPOSITORY https://github.com/libass/libass.git
    GIT_TAG e46aedea0a0d17da4c4ef49d84b94a7994664ab5
    CONFIGURE_COMMAND ${MESON_BIN}
        setup <BINARY_DIR> <SOURCE_DIR>
        --prefix=<INSTALL_DIR>
        --optimization=3
        --libdir=lib
        --buildtype=release
        --default-library=static
        --wrap-mode=nodownload
        -Dfontconfig=${fontconfig}
        -Ddirectwrite=${directwrite}
        -Dtest=false
        -Dlibunibreak=disabled
    BUILD_COMMAND ${MESON_BIN} compile -C <BINARY_DIR>
    INSTALL_COMMAND ${MESON_BIN} install -C <BINARY_DIR>
    DEPENDS fribidi libfreetype harfbuzz ${ADDITIONAL_DEPS}
)

set_target_properties(libass PROPERTIES
    LIBRARY_DIRECTORY ${libass_INSTALL_DIR}/lib
    INCLUDE_DIRECTORY ${libass_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${libass_INSTALL_DIR}/lib/pkgconfig
    LIBRARY_FILE ${libass_INSTALL_DIR}/lib/libass${STATIC_LIBRARY_EXTENSION}
)
