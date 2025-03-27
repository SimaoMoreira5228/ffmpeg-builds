project(gperf)

find_program(BASH_BIN bash)

add_external_target(gperf
    URL https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz
    URL_HASH SHA256=588546b945bba4b70b6a3a616e80b4ab466e3f33024a352fc2198112cdbb3ae2
    DOWNLOAD_NO_PROGRESS TRUE
    BUILD_IN_SOURCE TRUE
    CONFIGURE_COMMAND ${BASH_BIN} ./configure
        --prefix=<INSTALL_DIR>
    BUILD_COMMAND make -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
)


set_target_properties(gperf PROPERTIES
    PATH ${gperf_INSTALL_DIR}/bin
    EXECUTABLE ${gperf_INSTALL_DIR}/bin/gperf${EXECUTABLE_EXTENSION}
)
