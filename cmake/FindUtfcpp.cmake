#.rst
# FindUtfcpp
# ----------
#
# Finds the Utfcpp headers
# See http://utfcpp.sourceforge.net/
#
# This will define the following variables::
#
#   Utfcpp_FOUND        - True if the system has utfcpp headers
#   Utfcpp_INCLUDE_DIRS - Utfcpp include directories
#

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

find_path(Utfcpp_INCLUDE_DIR
    NAMES utf8.h
    PATHS "${Utfcpp_ROOT_DIR}"
    PATH_SUFFIXES include
)

include(FindPackageHandleStandardArgs)
if(${CMAKE_VERSION} VERSION_GREATER "2.8.10")
find_package_handle_standard_args(Utfcpp
  FOUND_VAR Utfcpp_FOUND
  REQUIRED_VARS Utfcpp_INCLUDE_DIR
)
else()
find_package_handle_standard_args(Utfcpp
  # FOUND_VAR was introduced with CMake 2.8.11
  REQUIRED_VARS Utfcpp_INCLUDE_DIR
)
set(Utfcpp_FOUND ${UTFCPP_FOUND})
endif()

if(Utfcpp_FOUND)
  set(Utfcpp_INCLUDE_DIRS ${Utfcpp_INCLUDE_DIR})
endif()

mark_as_advanced(Utfcpp_INCLUDE_DIR)
