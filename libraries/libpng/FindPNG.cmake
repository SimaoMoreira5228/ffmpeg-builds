# FindPNG.cmake
#
# Copyright (C) 2019-2024 by
# David Turner, Robert Wilhelm, and Werner Lemberg.
#
# Written by Werner Lemberg <wl@gnu.org>
#
# This file is part of the FreeType project, and may only be used, modified,
# and distributed under the terms of the FreeType project license,
# LICENSE.TXT.  By continuing to use, modify, or distribute this file you
# indicate that you have read the license and understand and accept it
# fully.
#
#
# Try to find libbrotlidec include and library directories.
#   PNG_LIBRARIES
#   PNG_INCLUDE_DIRS

find_package(PkgConfig QUIET)

pkg_check_modules(PC_PNG QUIET libpng)

if (PC_PNG_VERSION)
  set(PNG_VERSION "${PC_PNG_VERSION}")
endif ()


find_path(PNG_INCLUDE_DIRS
  NAMES png.h
  HINTS ${PC_PNG_INCLUDEDIR}
        ${PC_PNG_INCLUDE_DIRS}
  PATH_SUFFIXES libpng)

find_library(PNG_LIBRARIES
  NAMES png
  HINTS ${PC_PNG_LIBDIR}
        ${PC_PNG_LIBRARY_DIRS})


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  PNG
  REQUIRED_VARS PNG_INCLUDE_DIRS PNG_LIBRARIES
  FOUND_VAR PNG_FOUND
  VERSION_VAR PNG_VERSION)

mark_as_advanced(
  PNG_INCLUDE_DIRS
  PNG_LIBRARIES)
