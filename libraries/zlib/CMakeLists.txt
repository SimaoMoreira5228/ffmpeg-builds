project(zlib)

include(ExternalProject)

add_external_target(zlib
  GIT_REPOSITORY https://github.com/madler/zlib.git
  GIT_TAG 51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    -G${CMAKE_GENERATOR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_INSTALL_BINDIR=bin
    -DCMAKE_INSTALL_INCLUDEDIR=include
    -DCMAKE_INSTALL_SHAREDIR=share
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DBUILD_SHARED_LIBS=OFF
    -DZLIB_BUILD_EXAMPLES=OFF
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    <SOURCE_DIR>
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --config ${CMAKE_BUILD_TYPE}
  INSTALL_COMMAND ${CMAKE_COMMAND} --install .
)

ExternalProject_Add_Step(
    zlib
    remove_shared_libs
    COMMAND ${CMAKE_COMMAND} -DGLOB_PATH=${zlib_INSTALL_DIR}/lib/*${SHARED_LIBRARY_EXTENSION}* -P ${FFMPEG_STATIC_BUILD_DIR}/cmake/remove_files_glob.cmake
    DEPENDEES install
    COMMENT "Removing zlib shared libraries"
)

set_target_properties(zlib PROPERTIES
  LIBRARY_DIRECTORY ${zlib_INSTALL_DIR}/lib
  INCLUDE_DIRECTORY ${zlib_INSTALL_DIR}/include
  PKG_CONFIG_PATH ${zlib_INSTALL_DIR}/share/pkgconfig
  LIBRARY_FILE ${zlib_INSTALL_DIR}/lib/libz${STATIC_LIBRARY_EXTENSION}
)
