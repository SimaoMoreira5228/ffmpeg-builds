project(ffmpeg)

include(ExternalProject)

set(FFMPEG_PREFIX ${CMAKE_BINARY_DIR}/_deps/ffmpeg)
set(FFMPEG_INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/ffmpeg)
set(FFMPEG_SOURCE_DIR ${FFMPEG_PREFIX}/src)
set(FFMPEG_TMP_DIR ${FFMPEG_PREFIX}/tmp)
set(FFMPEG_STAMP_DIR ${FFMPEG_PREFIX}/stamp)
set(FFMPEG_LOG_DIR ${FFMPEG_PREFIX}/log)
set(FFMPEG_BINARY_DIR ${FFMPEG_PREFIX}/build)

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

set(FFMPEG_DEPENDENCIES_PKG_CONFIG_PATH "")
set(FFMPEG_DEPENDENCY_ARGS "")
foreach(dependency IN LISTS FFMPEG_DEPENDENCIES)
    list(APPEND FFMPEG_DEPENDENCIES_PKG_CONFIG_PATH "$<TARGET_PROPERTY:${dependency},PKG_CONFIG_PATH>")
    list(APPEND FFMPEG_DEPENDENCY_ARGS "--enable-${dependency}")
endforeach()

list(APPEND FFMPEG_DEPENDENCIES_PKG_CONFIG_PATH "$<TARGET_PROPERTY:harfbuzz,PKG_CONFIG_PATH>")
list(APPEND FFMPEG_DEPENDENCIES_PKG_CONFIG_PATH "$<TARGET_PROPERTY:libogg,PKG_CONFIG_PATH>")
list(APPEND FFMPEG_DEPENDENCIES_PKG_CONFIG_PATH "$<TARGET_PROPERTY:fribidi,PKG_CONFIG_PATH>")
list(APPEND FFMPEG_DEPENDENCIES_PKG_CONFIG_PATH "$<TARGET_PROPERTY:fontconfig,PKG_CONFIG_PATH>")
list(APPEND FFMPEG_DEPENDENCIES_PKG_CONFIG_PATH "$<TARGET_PROPERTY:libexpat,PKG_CONFIG_PATH>")

list(JOIN FFMPEG_DEPENDENCIES_PKG_CONFIG_PATH ":" PKG_CONFIG_PATH)

ExternalProject_Add(ffmpeg
    GIT_REPOSITORY https://github.com/FFmpeg/FFmpeg.git
    GIT_TAG ${FFMPEG_TAG}
    PREFIX ${FFMPEG_PREFIX}
    TMP_DIR ${FFMPEG_TMP_DIR}
    STAMP_DIR ${FFMPEG_STAMP_DIR}
    INSTALL_DIR ${FFMPEG_INSTALL_DIR}
    SOURCE_DIR ${FFMPEG_SOURCE_DIR}
    LOG_DIR ${FFMPEG_LOG_DIR}
    UPDATE_DISCONNECTED TRUE
    WORKING_DIRECTORY ${FFMPEG_SOURCE_DIR}
    BUILD_IN_SOURCE TRUE
    LOG_CONFIGURE ON
    LOG_INSTALL ON
    LOG_BUILD ON
    LOG_OUTPUT_ON_FAILURE ON
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
        PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        ${BASH} ./configure
        "--extra-libs=-lmp3lame -lpthread -lm"
        "--extra-cflags=-I$<TARGET_PROPERTY:libmp3lame,INCLUDE_DIRECTORY>"
        "--extra-ldflags=-L$<TARGET_PROPERTY:libmp3lame,LIBRARY_DIRECTORY>"
        --prefix=${FFMPEG_INSTALL_DIR}
        --disable-static
        --enable-shared
        "--pkg-config-flags=--static --define-prefix"
        --enable-gpl
        --enable-asm
        --enable-x86asm
        --enable-nonfree
        --enable-version3
        --enable-openssl
        ${FFMPEG_DEPENDENCY_ARGS}
        --disable-autodetect
    BUILD_COMMAND make -j${CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
    DEPENDS ${FFMPEG_DEPENDENCIES}
)

