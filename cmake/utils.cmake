include(ExternalProject)
include(CMakeParseArguments)

# Helper function to add an external project target
function(add_external_target TARGET)
    set(oneValueArgs
        GIT_REPOSITORY
        GIT_TAG
        URL
        URL_HASH
        BUILD_IN_SOURCE
    )
    set(multiValueArgs
        CONFIGURE_COMMAND
        BUILD_COMMAND
        INSTALL_COMMAND
        DEPENDS
        ENV_ARGS
    )

    # Parse the arguments passed to the function.
    cmake_parse_arguments(EXTERNAL "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    # Verify that a GIT_REPOSITORY is provided
    if(NOT EXTERNAL_GIT_REPOSITORY AND NOT EXTERNAL_URL)
        message(FATAL_ERROR "GIT_REPOSITORY or URL is required for add_external_target(${TARGET})")
    elseif(EXTERNAL_GIT_REPOSITORY AND EXTERNAL_URL)
        message(FATAL_ERROR "GIT_REPOSITORY and URL cannot both be provided for add_external_target(${TARGET})")
    endif()

    if(EXTERNAL_GIT_REPOSITORY)
        unset(EXTERNAL_URL)
        unset(EXTERNAL_URL_HASH)
    elseif(EXTERNAL_URL)
        unset(EXTERNAL_GIT_REPOSITORY)
        unset(EXTERNAL_GIT_TAG)
    endif()

    foreach(DEPEND ${EXTERNAL_DEPENDS})
        if(TARGET ${DEPEND})
            get_target_property(${DEPEND}_PKG_CONFIG_PATH ${DEPEND} PKG_CONFIG_PATH)
            if(${DEPEND}_PKG_CONFIG_PATH)
                file(TO_CMAKE_PATH ${${DEPEND}_PKG_CONFIG_PATH} DEPEND_PKG_CONFIG_PATH)
                foreach(DEPEND_PKG_CONFIG_PATH_ITEM ${DEPEND_PKG_CONFIG_PATH})
                    list(APPEND EXTERNAL_ENV_ARGS "--modify" "PKG_CONFIG_PATH=path_list_prepend:${DEPEND_PKG_CONFIG_PATH_ITEM}")
                endforeach()
            endif()
        endif()
    endforeach()

    if(NOT EXTERNAL_CONFIGURE_COMMAND)
        set(EXTERNAL_CONFIGURE_COMMAND ${CMAKE_COMMAND} -E true)
    endif()

    if(NOT EXTERNAL_BUILD_COMMAND)
        set(EXTERNAL_BUILD_COMMAND ${CMAKE_COMMAND} -E true)
    endif()

    if(NOT EXTERNAL_INSTALL_COMMAND)
        set(EXTERNAL_INSTALL_COMMAND ${CMAKE_COMMAND} -E true)
    endif() 

    if(NOT EXTERNAL_UPDATE_COMMAND)
        set(EXTERNAL_UPDATE_COMMAND ${CMAKE_COMMAND} -E true)
    endif()

    if(NOT EXTERNAL_BUILD_IN_SOURCE)
        set(EXTERNAL_BUILD_IN_SOURCE FALSE)
    endif()

    set(PREFIX ${CMAKE_BINARY_DIR}/_deps/${TARGET})

    set(TMP_DIR ${PREFIX}/tmp)
    set(${TARGET}_TMP_DIR ${TMP_DIR} PARENT_SCOPE)
    set(STAMP_DIR ${PREFIX}/stamp)
    set(${TARGET}_STAMP_DIR ${STAMP_DIR} PARENT_SCOPE)
    set(INSTALL_DIR ${CMAKE_BINARY_DIR}/_install/${TARGET})
    set(${TARGET}_INSTALL_DIR ${INSTALL_DIR} PARENT_SCOPE)
    set(SOURCE_DIR ${PREFIX}/src)
    set(${TARGET}_SOURCE_DIR ${SOURCE_DIR} PARENT_SCOPE)
    set(LOG_DIR ${PREFIX}/log)
    set(${TARGET}_LOG_DIR ${LOG_DIR} PARENT_SCOPE)

    if(EXTERNAL_BUILD_IN_SOURCE)
        set(${TARGET}_BUILD_DIR ${SOURCE_DIR} PARENT_SCOPE)
    else()
        set(BUILD_DIR ${PREFIX}/build)
        set(${TARGET}_BUILD_DIR ${BUILD_DIR} PARENT_SCOPE)
    endif()

    
    message(STATUS "Adding external target ${TARGET}")

    ExternalProject_Add(${TARGET}
        GIT_REPOSITORY ${EXTERNAL_GIT_REPOSITORY}
        GIT_TAG ${EXTERNAL_GIT_TAG}
        URL ${EXTERNAL_URL}
        URL_HASH ${EXTERNAL_URL_HASH}
        PREFIX ${PREFIX}
        TMP_DIR ${TMP_DIR}
        STAMP_DIR ${STAMP_DIR}
        INSTALL_DIR ${INSTALL_DIR}
        SOURCE_DIR ${SOURCE_DIR}
        BINARY_DIR ${BUILD_DIR}
        LOG_DIR ${LOG_DIR}
        LOG_DOWNLOAD ON
        LOG_UPDATE ON
        LOG_PATCH ON
        LOG_CONFIGURE ON
        LOG_BUILD ON
        LOG_INSTALL ON
        LOG_OUTPUT_ON_FAILURE ON
        BUILD_IN_SOURCE ${EXTERNAL_BUILD_IN_SOURCE}
        CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
            ${EXTERNAL_ENV_ARGS}
            --
            ${EXTERNAL_CONFIGURE_COMMAND}
        BUILD_COMMAND ${CMAKE_COMMAND} -E env
            ${EXTERNAL_ENV_ARGS}
            --
            ${EXTERNAL_BUILD_COMMAND}
        INSTALL_COMMAND ${CMAKE_COMMAND} -E env
            ${EXTERNAL_ENV_ARGS}
            --
            ${EXTERNAL_INSTALL_COMMAND}
        DEPENDS ${EXTERNAL_DEPENDS}
    )
endfunction()
