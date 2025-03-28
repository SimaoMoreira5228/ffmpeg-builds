project(libx264)

find_program(BASH_BIN bash REQUIRED)

if(WIN32)
    set(CMAKE_C_COMPILER_PATH cl)
    set(CMAKE_CXX_COMPILER_PATH cl)
    set(CMAKE_LINKER_PATH link)
else()
    set(CMAKE_C_COMPILER_PATH ${CMAKE_C_COMPILER})
    set(CMAKE_CXX_COMPILER_PATH ${CMAKE_CXX_COMPILER})
    set(CMAKE_LINKER_PATH ${CMAKE_LINKER})
endif()

add_external_target(libx264
    GIT_REPOSITORY https://github.com/ScuffleCloud/x264-mirror.git
    GIT_TAG 0e48d072c28b6e5283d94109391f8efbb52593f2 # v1.15.1-rc1
    CONFIGURE_COMMAND ${BASH_BIN} <SOURCE_DIR>/configure
        --prefix=<INSTALL_DIR>
        --disable-opencl
        --enable-static
        --disable-bashcompletion
        --enable-pic
    BUILD_COMMAND make lib-static -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install-lib-static
    ENV_ARGS
        "CC=${CMAKE_C_COMPILER_PATH}"
        "CXX=${CMAKE_CXX_COMPILER_PATH}"
        "LD=${CMAKE_LINKER_PATH}"
)

set_target_properties(libx264 PROPERTIES
    LIBRARY_DIRECTORY ${libx264_INSTALL_DIR}/lib
    INCLUDE_DIRECTORY ${libx264_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${libx264_INSTALL_DIR}/lib/pkgconfig
    LIBRARY_FILE ${libx264_INSTALL_DIR}/lib/libx264${STATIC_LIBRARY_EXTENSION}
)
