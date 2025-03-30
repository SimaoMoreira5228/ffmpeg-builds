project(ffmpeg)

include(ExternalProject)
include(GNUInstallDirs)

set(FFMPEG_DEPENDENCIES
    openssl
    libass
    libfdk-aac
    libfreetype
    libmp3lame
    libopus
    libdav1d
    libvorbis
    libvpx
    libx264
    libx265
    libaom
    libwebp
    zlib
)

set(FFMPEG_EXTRA_CONFIG_ARGS "")
foreach(dependency IN LISTS FFMPEG_DEPENDENCIES)
    list(APPEND FFMPEG_EXTRA_CONFIG_ARGS "--enable-${dependency}")
endforeach()

if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "x86_64")
    list(APPEND FFMPEG_EXTRA_CONFIG_ARGS "--enable-x86asm")
endif()

if(WIN32)
    list(APPEND FFMPEG_EXTRA_CONFIG_ARGS "--arch=x86_64" "--target-os=win64" "--toolchain=msvc")
endif()

add_external_target(ffmpeg
    GIT_REPOSITORY https://github.com/FFmpeg/FFmpeg.git
    GIT_TAG ${FFMPEG_TAG}
    CONFIGURE_COMMAND ${BASH_BIN} <SOURCE_DIR>/configure
        "--extra-libs=-lpthread -lm"
        --prefix=<INSTALL_DIR>
        --disable-static
        --enable-shared
        "--pkg-config-flags=--static --define-prefix"
        --enable-gpl
        --enable-asm
        --enable-nonfree
        --enable-version3
        --enable-openssl
        --disable-autodetect
        ${FFMPEG_EXTRA_CONFIG_ARGS}
    BUILD_COMMAND ${MAKE_BIN} -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND ${MAKE_BIN} install
    DEPENDS ${FFMPEG_DEPENDENCIES}
    ENV_ARGS ${ENV_ARGS}
)

ExternalProject_Add_Step(
    ffmpeg
    set_tools_rpath
    COMMAND ${CMAKE_COMMAND} -DGLOB_PATH=${ffmpeg_INSTALL_DIR}/bin/* -P ${FFMPEG_STATIC_BUILD_DIR}/cmake/set_rpath.cmake
    DEPENDEES install
    COMMENT "Setting tools rpath"
)

ExternalProject_Add_Step(
    ffmpeg
    set_libs_rpath
    COMMAND ${CMAKE_COMMAND} -DGLOB_PATH=${ffmpeg_INSTALL_DIR}/lib/* -P ${FFMPEG_STATIC_BUILD_DIR}/cmake/set_rpath.cmake
    DEPENDEES install
    COMMENT "Setting libraries rpath"
)

install(DIRECTORY ${ffmpeg_INSTALL_DIR}/bin/ DESTINATION ${CMAKE_INSTALL_BINDIR} USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${ffmpeg_INSTALL_DIR}/lib/ DESTINATION ${CMAKE_INSTALL_LIBDIR} USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${ffmpeg_INSTALL_DIR}/include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${ffmpeg_INSTALL_DIR}/share/ DESTINATION ${CMAKE_INSTALL_DATAROOTDIR} USE_SOURCE_PERMISSIONS)
