project(libx264)

find_program(BASH_BIN bash REQUIRED)

add_external_target(libx264
    GIT_REPOSITORY https://github.com/ScuffleCloud/x264-mirror.git
    GIT_TAG 0e48d072c28b6e5283d94109391f8efbb52593f2 # v1.15.1-rc1
    BUILD_IN_SOURCE TRUE
    CONFIGURE_COMMAND ${BASH_BIN} ./configure
        --prefix=<INSTALL_DIR>
        --enable-static
        --disable-opencl
        --disable-bashcompletion
        --enable-pic
    BUILD_COMMAND make -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
)

set_target_properties(libx264 PROPERTIES
    LIBRARY_DIRECTORY ${libx264_INSTALL_DIR}/lib
    INCLUDE_DIRECTORY ${libx264_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${libx264_INSTALL_DIR}/lib/pkgconfig
    LIBRARY_FILE ${libx264_INSTALL_DIR}/lib/libx264${STATIC_LIBRARY_EXTENSION}
)
