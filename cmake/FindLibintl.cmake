#.rst
# FindLibintl
# ----------
#
# Finds the GNU Multiple Precision Arithmetic Library
# See http://thrysoee.dk/editline/
#
# This will define the following variables::
#
#   Libintl_FOUND        - True if the system has the libintl library
#   Libintl_VERSION      - The version of the libintl library which was found
#   Libintl_INCLUDE_DIRS - The version of the libintl library which was found
#   Libintl_LIBRARIES    - The version of the libintl library which was found
#
# and the following imported targets::
#
#    Libintl::Libintl   - The libintl library

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

find_path(Libintl_INCLUDE_DIR
  NAMES libintl.h
  PATHS ${Libintl_ROOT_DIR}
  PATH_SUFFIXES "include"
)

find_library(Libintl_LIBRARY
  NAMES intl libintl.a
  PATHS ${Libintl_ROOT_DIR}
  PATH_SUFFIXES "lib"
)

# Set Libintl_VERSION from libintl header defines
if(Libintl_INCLUDE_DIR)
  # Thanks to +ngladitz in #cmake on irc.freenode.net
  # for the hex2dec function (see http://pastebin.com/DVzTTPC6).
  function(hex2dec INPUT OUTPUT)
    set(_HEX_LOOKUP_TABLE "0123456789abcdef")
    string(TOLOWER ${INPUT} INPUT)
    set(result 0)
    string(LENGTH "${INPUT}" length)
    math(EXPR start "${length} - 1")
    set(factor 1)
    foreach(index RANGE ${start} 0 -1)
      string(SUBSTRING "${INPUT}" ${index} 1 digit)
      string(FIND "${_HEX_LOOKUP_TABLE}" ${digit} digit_value)
      math(EXPR result "${result} + ${digit_value} * ${factor}")
      math(EXPR factor "${factor} * 16")
    endforeach()
    set(${OUTPUT} ${result} PARENT_SCOPE)
  endfunction()

  file(READ "${Libintl_INCLUDE_DIR}/libintl.h" _libintl_version_header)
  string(REGEX MATCH
    "define[ \t]+LIBINTL_VERSION[ \t]+0x([0-9][0-9])([0-9][0-9])([0-9][0-9])"
    _libintl_version_match "${_libintl_version_header}")
  #/* Version number: (major<<16) + (minor<<8) + subminor */
  if(CMAKE_MATCH_1)
    hex2dec(${CMAKE_MATCH_1} Libintl_VERSION_MAJOR)
    hex2dec(${CMAKE_MATCH_2} Libintl_VERSION_MINOR)
    hex2dec(${CMAKE_MATCH_3} Libintl_VERSION_PATCH)
    set(Libintl_VERSION
      "${Libintl_VERSION_MAJOR}.${Libintl_VERSION_MINOR}.${Libintl_VERSION_PATCH}")
  endif()
endif()

include(FindPackageHandleStandardArgs)
if(${CMAKE_VERSION} VERSION_GREATER "2.8.10")
find_package_handle_standard_args(Libintl
  FOUND_VAR Libintl_FOUND
  REQUIRED_VARS Libintl_INCLUDE_DIR
  VERSION_VAR Libintl_VERSION
)
else()
find_package_handle_standard_args(Libintl
  # FOUND_VAR was introduced with CMake 2.8.11
  REQUIRED_VARS Libintl_INCLUDE_DIR
  VERSION_VAR Libintl_VERSION
)
set(Libintl_FOUND ${LIBINTL_FOUND})
endif()

if(Libintl_FOUND)
  set(Libintl_LIBRARIES ${Libintl_LIBRARY})
  set(Libintl_INCLUDE_DIRS ${Libintl_INCLUDE_DIR})
endif()

if(Libintl_FOUND AND NOT TARGET Libintl::Libintl)
  add_library(Libintl::Libintl UNKNOWN IMPORTED)
  if(${Libintl_LIBRARY} MATCHES "LIBRARY-NOTFOUND")
    # On some system libintl is part of libc
    find_library(Libc_LIBRARY NAMES c)
    set_target_properties(Libintl::Libintl PROPERTIES
      IMPORTED_LOCATION "${Libc_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Libintl_INCLUDE_DIR}"
    )
  else()
    set_target_properties(Libintl::Libintl PROPERTIES
      IMPORTED_LOCATION "${Libintl_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Libintl_INCLUDE_DIR}"
    )
  endif()
endif()

mark_as_advanced(Libintl_LIBRARY Libintl_INCLUDE_DIR)
