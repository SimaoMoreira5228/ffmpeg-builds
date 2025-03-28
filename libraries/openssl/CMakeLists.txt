project(openssl)

if(WIN32)
    set(OPENSSL_CONFIG VC-WIN64A)
elseif(APPLE AND CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
    set(OPENSSL_CONFIG darwin64-arm64-cc)
elseif(APPLE AND CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    set(OPENSSL_CONFIG darwin64-x86_64-cc)
elseif(UNIX AND CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64" OR CMAKE_SYSTEM_PROCESSOR MATCHES "arm64")
    set(OPENSSL_CONFIG linux-aarch64)
elseif(UNIX AND CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    set(OPENSSL_CONFIG linux-x86_64)
else()
    message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()

find_program(PERL_BIN perl REQUIRED)

if(WIN32)
    find_program(MAKE_BIN jom)
    if(MAKE_BIN_NOTFOUND)
        message(STATUS "jom not found, using nmake")
        find_program(MAKE_BIN nmake REQUIRED)
    else()
        set(MAKE_ARGS /J $ENV{CMAKE_BUILD_PARALLEL_LEVEL})
        set(CONFIGURE_ARGS /FS)
    endif()

    set(ZLIB_LIB $<TARGET_PROPERTY:zlib,LIBRARY_DIRECTORY>/zlib.lib)
else()
    find_program(MAKE_BIN make REQUIRED)
    set(MAKE_ARGS -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL})

    set(ZLIB_LIB $<TARGET_PROPERTY:zlib,LIBRARY_DIRECTORY>)
    set(CONFIGURE_ARGS -fPIC)
endif()

add_external_target(openssl
    GIT_REPOSITORY https://github.com/openssl/openssl.git
    GIT_TAG 0c6656a7a31492ddd61e3d0d8b0e66645f4b2d6f # v3.5.0-beta1
    BUILD_IN_SOURCE TRUE
    CONFIGURE_COMMAND ${PERL_BIN} 
        ./Configure ${OPENSSL_CONFIG}
            --prefix=<INSTALL_DIR>
            --openssldir=<INSTALL_DIR>/ssl
            no-shared
            no-docs
            no-tests
            zlib
            --with-zlib-include=$<TARGET_PROPERTY:zlib,INCLUDE_DIRECTORY>
            --with-zlib-lib=${ZLIB_LIB}
            ${CONFIGURE_ARGS}
    BUILD_COMMAND ${MAKE_BIN} ${MAKE_ARGS}
    INSTALL_COMMAND ${MAKE_BIN} install
    DEPENDS zlib
)

set_target_properties(openssl PROPERTIES
    PKG_CONFIG_PATH ${openssl_INSTALL_DIR}/lib64/pkgconfig
    INCLUDE_DIRECTORY ${openssl_INSTALL_DIR}/include
    LIBRARY_DIRECTORY ${openssl_INSTALL_DIR}/lib64
    CMAKE_PREFIX_PATH ${openssl_INSTALL_DIR}
)
