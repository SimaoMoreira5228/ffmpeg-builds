project(ffmpeg)

include(ExternalProject)
include(GNUInstallDirs)

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

find_program(BASH_BIN bash)

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
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
        PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        ${BASH_BIN} ./configure
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
    BUILD_COMMAND make -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
    DEPENDS ${FFMPEG_DEPENDENCIES}
)

ExternalProject_Add_Step(
    ffmpeg
    set_tools_rpath
    COMMAND ${CMAKE_COMMAND} -DGLOB_PATH=${FFMPEG_INSTALL_DIR}/bin/* -P ${FFMPEG_STATIC_BUILD_DIR}/cmake/set_rpath.cmake
    DEPENDEES install
    COMMENT "Setting tools rpath"
)

ExternalProject_Add_Step(
    ffmpeg
    set_libs_rpath
    COMMAND ${CMAKE_COMMAND} -DGLOB_PATH=${FFMPEG_INSTALL_DIR}/lib/* -P ${FFMPEG_STATIC_BUILD_DIR}/cmake/set_rpath.cmake
    DEPENDEES install
    COMMENT "Setting libraries rpath"
)

install(DIRECTORY ${FFMPEG_INSTALL_DIR}/bin/ DESTINATION ${CMAKE_INSTALL_BINDIR} USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${FFMPEG_INSTALL_DIR}/lib/ DESTINATION ${CMAKE_INSTALL_LIBDIR} USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${FFMPEG_INSTALL_DIR}/include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${FFMPEG_INSTALL_DIR}/share/ DESTINATION ${CMAKE_INSTALL_DATAROOTDIR} USE_SOURCE_PERMISSIONS)
