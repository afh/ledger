#.rst
# FindGmp
# -------
#
# Finds the GNU Multiple Precision Arithmetic Library
# See https://gmplib.org/
#
# This will define the following variables::
#
#   Gmp_FOUND        - True if the system has the gmp library
#   Gmp_VERSION      - The version of the gmp library which was found
#   Gmp_INCLUDE_DIRS - Gmp include directories
#   Gmp_LIBRARIES    - Gmp libraries to be linked
#
# and the following imported targets::
#
#    Gmp::Gmp        - The gmp library

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

find_path(Gmp_INCLUDE_DIR
  NAMES gmp.h
  PATHS ${Gmp_ROOT_DIR}
  PATH_SUFFIXES "include"
)

find_library(Gmp_LIBRARY
  NAMES gmp
  PATHS ${Gmp_ROOT_DIR}
  PATH_SUFFIXES "lib"
)

# Set Gmp_VERSION from gmp header defines
if(Gmp_INCLUDE_DIR)
  function(gmp_version HEADER OUTPUT)
    file(READ "${HEADER}" _gmp_version_header)
    string(REGEX MATCH "define[ \t]+__GNU_MP_VERSION[ \t]+([0-9]+)"
      _gmp_major_version_match "${_gmp_version_header}")
    set(Gmp_MAJOR_VERSION "${CMAKE_MATCH_1}")
    string(REGEX MATCH "define[ \t]+__GNU_MP_VERSION_MINOR[ \t]+([0-9]+)"
      _gmp_minor_version_match "${_gmp_version_header}")
    set(Gmp_MINOR_VERSION "${CMAKE_MATCH_1}")
    string(REGEX MATCH "define[ \t]+__GNU_MP_VERSION_PATCHLEVEL[ \t]+([0-9]+)"
      _gmp_patchlevel_version_match "${_gmp_version_header}")
    set(Gmp_PATCHLEVEL_VERSION "${CMAKE_MATCH_1}")
    set(${OUTPUT}
      "${Gmp_MAJOR_VERSION}.${Gmp_MINOR_VERSION}.${Gmp_PATCHLEVEL_VERSION}"
      PARENT_SCOPE)
  endfunction()

  gmp_version("${Gmp_INCLUDE_DIR}/gmp.h" Gmp_VERSION)
  if("${Gmp_VERSION}" STREQUAL "..")
    gmp_version("${Gmp_INCLUDE_DIR}/gmp-${CMAKE_SYSTEM_PROCESSOR}.h" Gmp_VERSION)
  endif()
endif(Gmp_INCLUDE_DIR)

# Default Gmp_FIND_VERSION to 2.0,
# which is the first release to include version information in gmp.h.
if(NOT Gmp_FIND_VERSION)
  if(NOT Gmp_FIND_VERSION_MAJOR)
    set(Gmp_FIND_VERSION_MAJOR 2)
  endif()
  if(NOT Gmp_FIND_VERSION_MINOR)
    set(Gmp_FIND_VERSION_MINOR 0)
  endif()
  set(Gmp_FIND_VERSION "${Gmp_FIND_VERSION_MAJOR}.${Gmp_FIND_VERSION_MINOR}")
endif()

include(FindPackageHandleStandardArgs)
if(${CMAKE_VERSION} VERSION_GREATER "2.8.10")
find_package_handle_standard_args(Gmp
  FOUND_VAR Gmp_FOUND
  REQUIRED_VARS Gmp_LIBRARY Gmp_INCLUDE_DIR
  VERSION_VAR Gmp_VERSION
)
else()
find_package_handle_standard_args(Gmp
  # FOUND_VAR was introduced with CMake 2.8.11
  REQUIRED_VARS Gmp_LIBRARY Gmp_INCLUDE_DIR
  VERSION_VAR Gmp_VERSION
)
set(Gmp_FOUND ${GMP_FOUND})
endif()

if(Gmp_FOUND)
  set(Gmp_LIBRARIES ${Gmp_LIBRARY})
  set(Gmp_INCLUDE_DIRS ${Gmp_INCLUDE_DIR})
endif()

if(Gmp_FOUND AND NOT TARGET Gmp::Gmp)
  add_library(Gmp::Gmp UNKNOWN IMPORTED)
  set_target_properties(Gmp::Gmp PROPERTIES
    IMPORTED_LOCATION "${Gmp_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${Gmp_INCLUDE_DIR}"
  )
endif()

mark_as_advanced(Gmp_LIBRARY Gmp_INCLUDE_DIR)
