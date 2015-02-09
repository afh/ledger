#.rst
# FindEditline
# ------------
#
# Finds the GNU Multiple Precision Arithmetic Library
# See http://thrysoee.dk/editline/
#
# This will define the following variables::
#
#   Editline_FOUND        - True if the system has the editline library
#   Editline_VERSION      - The version of the editline library which was found
#   Editline_INCLUDE_DIRS - Editline include directories
#   Editline_LIBRARIES    - Editline libraries to be linked
#
# and the following imported targets::
#
#    Editline::Editline   - The editline library

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

find_package(PkgConfig)
pkg_check_modules(PC_Editline QUIET libedit)

find_path(Editline_INCLUDE_DIR
  NAMES histedit.h
  PATHS ${Editline_ROOT_DIR} ${PC_Editline_INCLUDE_DIRS}
  PATH_SUFFIXES "include"
)

find_library(Editline_LIBRARY
  NAMES edit
  PATHS ${Editline_ROOT_DIR} ${PC_Editline_LIBRARY_DIRS}
  PATH_SUFFIXES "lib"
)

set(Editline_VERSION ${PC_Editline_VERSION})

include(FindPackageHandleStandardArgs)
if(${CMAKE_VERSION} VERSION_GREATER "2.8.10")
find_package_handle_standard_args(Editline
  FOUND_VAR Editline_FOUND
  REQUIRED_VARS Editline_LIBRARY Editline_INCLUDE_DIR
  VERSION_VAR Editline_VERSION
)
else()
find_package_handle_standard_args(Editline
  # FOUND_VAR was introduced with CMake 2.8.11
  REQUIRED_VARS Editline_LIBRARY Editline_INCLUDE_DIR
  VERSION_VAR Editline_VERSION
)
set(Editline_FOUND ${EDITLINE_FOUND})
endif()

if(Editline_FOUND)
  set(Editline_LIBRARIES ${Editline_LIBRARY})
  set(Editline_INCLUDE_DIRS ${Editline_INCLUDE_DIR})
endif()

if(Editline_FOUND AND NOT TARGET Editline::Editline)
  add_library(Editline::Editline UNKNOWN IMPORTED)
  set_target_properties(Editline::Editline PROPERTIES
    IMPORTED_LOCATION "${Editline_LIBRARY}"
    INTERACE_INCLUDE_DIRECTORIES "${Editline_INCLUDE_DIR}"
  )
endif()

mark_as_advanced(Editline_LIBRARY Editline_INCLUDE_DIR)
