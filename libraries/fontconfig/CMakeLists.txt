project(fontconfig)

find_program(MESON_BIN meson)

add_external_target(fontconfig
    GIT_REPOSITORY https://github.com/ScuffleCloud/fontconfig-mirror.git
    GIT_TAG f511346fe16f205f087a97faf32d3c7d07d5b3c8 # v2.16.1
    BUILD_IN_SOURCE TRUE
    CONFIGURE_COMMAND ${MESON_BIN}
        setup build
        --prefix=<INSTALL_DIR>
        --optimization=3
        --libdir=lib
        --buildtype=release
        --default-library=static
        --wrap-mode=nodownload
        -Ddoc=disabled
        -Dtests=disabled
        -Dtools=disabled
    BUILD_COMMAND ${MESON_BIN} compile -C build
    INSTALL_COMMAND ${MESON_BIN} install -C build
    DEPENDS libexpat libpng zlib libfreetype gperf
    ENV_ARGS 
        --modify PATH=path_list_prepend:$<TARGET_PROPERTY:gperf,PATH>
        ${EXTRA_LDFLAGS}
)

ExternalProject_Add_Step(
    fontconfig
    remove_shared_libs
    COMMAND ${CMAKE_COMMAND} -DGLOB_PATH=${fontconfig_INSTALL_DIR}/lib/libfontconfig${SHARED_LIBRARY_EXTENSION}* -P ${FFMPEG_STATIC_BUILD_DIR}/cmake/remove_files_glob.cmake
    DEPENDEES install
    COMMENT "Removing fontconfig shared libraries"
)

set_target_properties(fontconfig PROPERTIES
    LIBRARY_DIRECTORY ${fontconfig_INSTALL_DIR}/lib
    INCLUDE_DIRECTORY ${fontconfig_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${fontconfig_INSTALL_DIR}/lib/pkgconfig
    LIBRARY_FILE ${fontconfig_INSTALL_DIR}/lib/libfontconfig${STATIC_LIBRARY_EXTENSION}
)
