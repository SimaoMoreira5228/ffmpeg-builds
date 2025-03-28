project(libvpx)

find_program(BASH_BIN bash REQUIRED)

if(WIN32)
    set(CONFIGURE_ARGS --enable-static-msvcrt --target=x86_64-win64-vs17)
elseif(APPLE AND CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
    set(CONFIGURE_ARGS --target=arm64-darwin-gcc)
elseif(APPLE AND CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    set(CONFIGURE_ARGS --target=x86_64-darwin-gcc)
elseif(UNIX AND CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64" OR CMAKE_SYSTEM_PROCESSOR MATCHES "arm64")
    set(CONFIGURE_ARGS --target=arm64-linux-gcc)
elseif(UNIX AND CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    set(CONFIGURE_ARGS --target=x86_64-linux-gcc)
else()
    message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()

add_external_target(libvpx
    GIT_REPOSITORY https://github.com/webmproject/libvpx.git
    GIT_TAG 39e8b9dcd4696d9ac3ebd4722e012488382f1adb # v1.15.1-rc1
    BUILD_IN_SOURCE TRUE
    CONFIGURE_COMMAND ${BASH_BIN} ./configure
        --prefix=<INSTALL_DIR>
        --disable-shared
        --enable-static
        --disable-examples
        --disable-tools
        --disable-docs
        --disable-unit_tests
        --disable-decode_perf_tests
        --disable-encode_perf_tests
        --enable-vp8
        --enable-vp9
        --enable-multithread
        --as=yasm
        --enable-vp9-highbitdepth
        ${CONFIGURE_ARGS}
    BUILD_COMMAND make -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
)

set_target_properties(libvpx PROPERTIES
    LIBRARY_DIRECTORY ${libvpx_INSTALL_DIR}/lib
    INCLUDE_DIRECTORY ${libvpx_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${libvpx_INSTALL_DIR}/lib/pkgconfig
    LIBRARY_FILE ${libvpx_INSTALL_DIR}/lib/libvpx${STATIC_LIBRARY_EXTENSION}
)
