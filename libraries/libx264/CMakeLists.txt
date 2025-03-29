project(libx264)

find_program(BASH_BIN bash REQUIRED)

if(WIN32)
    set(ENV_ARGS "CC=cl" "CXX=cl" "LD=link" )
else()
    set(ENV_ARGS "CFLAGS=-O3")
endif()

add_external_target(libx264
    GIT_REPOSITORY https://github.com/ScuffleCloud/x264-mirror.git
    GIT_TAG 0e48d072c28b6e5283d94109391f8efbb52593f2 # v1.15.1-rc1
    CONFIGURE_COMMAND ${BASH_BIN} <SOURCE_DIR>/configure
        --prefix=<INSTALL_DIR>
        --disable-opencl
        --disable-cli
        --enable-strip
        --enable-static
        --disable-bashcompletion
        --enable-pic
    BUILD_COMMAND make lib-static -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install-lib-static
    ENV_ARGS ${ENV_ARGS}
)

set_target_properties(libx264 PROPERTIES
    LIBRARY_DIRECTORY ${libx264_INSTALL_DIR}/lib
    INCLUDE_DIRECTORY ${libx264_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${libx264_INSTALL_DIR}/lib/pkgconfig
    LIBRARY_FILE ${libx264_INSTALL_DIR}/lib/libx264${STATIC_LIBRARY_EXTENSION}
)
