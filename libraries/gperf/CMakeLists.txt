project(gperf)

if(WIN32)
    set(ENV_ARGS "CFLAGS=/O2 /Ob2 /Gy /DNDEBUG")
else()
    set(ENV_ARGS "CFLAGS=-O3")
endif()

add_external_target(gperf
    URL https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz
    URL_HASH SHA256=588546b945bba4b70b6a3a616e80b4ab466e3f33024a352fc2198112cdbb3ae2
    DOWNLOAD_NO_PROGRESS TRUE
    CONFIGURE_COMMAND ${BASH_BIN} <SOURCE_DIR>/configure
        --prefix=<INSTALL_DIR>
    BUILD_COMMAND make -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
    ENV_ARGS ${ENV_ARGS}
)


set_target_properties(gperf PROPERTIES
    PATH ${gperf_INSTALL_DIR}/bin
    EXECUTABLE ${gperf_INSTALL_DIR}/bin/gperf${EXECUTABLE_EXTENSION}
)
