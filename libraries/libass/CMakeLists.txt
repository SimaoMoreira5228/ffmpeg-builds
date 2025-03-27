project(libass)

include(ExternalProject)

set(LIBASS_PREFIX ${CMAKE_BINARY_DIR}/_deps/libass)
set(LIBASS_INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/libass)
set(LIBASS_SOURCE_DIR ${LIBASS_PREFIX}/src)
set(LIBASS_TMP_DIR ${LIBASS_PREFIX}/tmp)
set(LIBASS_STAMP_DIR ${LIBASS_PREFIX}/stamp)
set(LIBASS_LOG_DIR ${LIBASS_PREFIX}/log)
set(LIBASS_BINARY_DIR ${LIBASS_PREFIX}/build)

set(DEPENDENCIES fribidi fontconfig libfreetype harfbuzz)
foreach(dependency IN LISTS DEPENDENCIES)
    list(APPEND DEPENDENCIES_PKG_CONFIG_PATH "$<TARGET_PROPERTY:${dependency},PKG_CONFIG_PATH>")
endforeach()

list(JOIN DEPENDENCIES_PKG_CONFIG_PATH ":" PKG_CONFIG_PATH)

ExternalProject_Add(libass
    GIT_REPOSITORY https://github.com/libass/libass.git
    GIT_TAG e46aedea0a0d17da4c4ef49d84b94a7994664ab5
    PREFIX ${LIBASS_PREFIX}
    TMP_DIR ${LIBASS_TMP_DIR}
    STAMP_DIR ${LIBASS_STAMP_DIR}
    INSTALL_DIR ${LIBASS_INSTALL_DIR}
    SOURCE_DIR ${LIBASS_SOURCE_DIR}
    LOG_DIR ${LIBASS_LOG_DIR}
    UPDATE_DISCONNECTED TRUE
    WORKING_DIRECTORY ${LIBASS_SOURCE_DIR}
    BUILD_IN_SOURCE TRUE
    LOG_CONFIGURE ON
    LOG_INSTALL ON
    LOG_BUILD ON
    LOG_OUTPUT_ON_FAILURE ON
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
        PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        ${MESON} setup ${LIBASS_BINARY_DIR}
        --prefix=${LIBASS_INSTALL_DIR}
        --optimization=3
        --prefer-static
        --libdir=lib
        --buildtype=release
        --default-library=static
        -Dtest=false
        -Dlibunibreak=disabled
    BUILD_COMMAND ${MESON} compile -C ${LIBASS_BINARY_DIR}
    INSTALL_COMMAND ${MESON} install -C ${LIBASS_BINARY_DIR}
    DEPENDS ${DEPENDENCIES}
)

set_target_properties(libass PROPERTIES
    IMPORTED_LOCATION ${LIBASS_INSTALL_DIR}/lib/libass.a
    INTERFACE_INCLUDE_DIRECTORIES ${LIBASS_INSTALL_DIR}/include
    PKG_CONFIG_PATH ${LIBASS_INSTALL_DIR}/lib/pkgconfig
    INCLUDE_DIRECTORY ${LIBASS_INSTALL_DIR}/include
    LIBRARY_DIRECTORY ${LIBASS_INSTALL_DIR}/lib
)
