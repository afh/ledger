#.rst
# FindMpfr
# --------
#
# Finds the GNU Multiple Precision Floating Point with correct Rounding Library
# See http://www.mpfr.org/
#
# This will define the following variables::
#
#   Mpfr_FOUND        - True if the system has the mpfr library
#   Mpfr_VERSION      - The version of the mpfr library which was found
#   Mpfr_INCLUDE_DIRS - Mpfr include directories
#   Mpfr_LIBRARIES    - Mpfr libraries to be linked
#
# and the following imported targets::
#
#    Mpfr::Mpfr        - The mpfr library

#=============================================================================
# Copyright 2015 Alexis Hildebrandt
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================

find_path(Mpfr_INCLUDE_DIR
  NAMES mpfr.h
  PATHS ${Mpfr_ROOT_DIR}
  PATH_SUFFIXES "include"
)

find_library(Mpfr_LIBRARY
  NAMES mpfr
  PATHS ${Mpfr_ROOT_DIR}
  PATH_SUFFIXES "lib"
)

# Set Mpfr_VERSION from mpfr header defines
if(Mpfr_INCLUDE_DIR)
  file(READ "${Mpfr_INCLUDE_DIR}/mpfr.h" _mpfr_version_header)

  string(REGEX MATCH "define[ \t]+MPFR_VERSION_MAJOR[ \t]+([0-9]+)"
    _mpfr_major_version_match "${_mpfr_version_header}")
  set(Mpfr_MAJOR_VERSION "${CMAKE_MATCH_1}")
  string(REGEX MATCH "define[ \t]+MPFR_VERSION_MINOR[ \t]+([0-9]+)"
    _mpfr_minor_version_match "${_mpfr_version_header}")
  set(Mpfr_MINOR_VERSION "${CMAKE_MATCH_1}")
  string(REGEX MATCH "define[ \t]+MPFR_VERSION_PATCHLEVEL[ \t]+([0-9]+)"
    _mpfr_patchlevel_version_match "${_mpfr_version_header}")
  set(Mpfr_PATCHLEVEL_VERSION "${CMAKE_MATCH_1}")

  set(Mpfr_VERSION
      "${Mpfr_MAJOR_VERSION}.${Mpfr_MINOR_VERSION}.${Mpfr_PATCHLEVEL_VERSION}")
endif(Mpfr_INCLUDE_DIR)

# Default Mpfr_FIND_VERSION to 1.0.0
if(NOT Mpfr_FIND_VERSION)
  if(NOT Mpfr_FIND_VERSION_MAJOR)
    set(Mpfr_FIND_VERSION_MAJOR 1)
  endif()
  if(NOT Mpfr_FIND_VERSION_MINOR)
    set(Mpfr_FIND_VERSION_MINOR 0)
  endif()
  if(NOT Mpfr_FIND_VERSION_PATCH)
    set(Mpfr_FIND_VERSION_PATCH 0)
  endif()
  set(Mpfr_FIND_VERSION
      "${Mpfr_FIND_VERSION_MAJOR}.${Mpfr_FIND_VERSION_MINOR}.${Mpfr_FIND_VERSION_PATCH}")
endif()

include(FindPackageHandleStandardArgs)
if(${CMAKE_VERSION} VERSION_GREATER "2.8.10")
find_package_handle_standard_args(Mpfr
  FOUND_VAR Mpfr_FOUND
  REQUIRED_VARS Mpfr_LIBRARY Mpfr_INCLUDE_DIR
  VERSION_VAR Mpfr_VERSION
)
else()
find_package_handle_standard_args(Mpfr
  # FOUND_VAR was introduced with CMake 2.8.11
  REQUIRED_VARS Mpfr_LIBRARY Mpfr_INCLUDE_DIR
  VERSION_VAR Mpfr_VERSION
)
set(Mpfr_FOUND ${MPFR_FOUND})
endif()

if(Mpfr_FOUND)
  set(Mpfr_LIBRARIES ${Mpfr_LIBRARY})
  set(Mpfr_INCLUDE_DIRS ${Mpfr_INCLUDE_DIR})
endif()

if(Mpfr_FOUND AND NOT TARGET Mpfr::Mpfr)
  add_library(Mpfr::Mpfr UNKNOWN IMPORTED)
  set_target_properties(Mpfr::Mpfr PROPERTIES
    IMPORTED_LOCATION "${Mpfr_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${Mpfr_INCLUDE_DIR}"
  )
endif()

mark_as_advanced(Mpfr_LIBRARY Mpfr_INCLUDE_DIR)
