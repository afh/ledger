#.rst
# FindIcu
# -------
#
# Finds the International Components for Unicode Library
# See http://site.icu-project.org/
#
# This will define the following variables::
#
#   Icu_FOUND        - True if the system has the icu4c library
#   Icu_VERSION      - The version of the icu4c library which was found
#   Icu_INCLUDE_DIRS - The version of the icu4c library which was found
#   Icu_LIBRARIES    - The version of the icu4c library which was found
#
# and the following imported targets::
#
#    Icu::Icu        - The icu4c library

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

# TODO: Add support for pkg-config
#find_package(PkgConfig)
#pkg_check_modules(PC_Icu QUIET icu-uc)

find_path(Icu_INCLUDE_DIR
  NAMES uvernum.h
  PATHS ${Icu_ROOT_DIR}
  PATH_SUFFIXES "include/unicode"
)

foreach(COMPONENT ${Icu_FIND_COMPONENTS})
  string(TOUPPER ${COMPONENT} UPPERCOMPONENT)
  find_library(Icu_${UPPERCOMPONENT}_LIBRARY
    NAMES ${COMPONENT}
    PATHS ${Icu_ROOT_DIR}
    PATH_SUFFIXES "lib"
  )
  if(Icu_${UPPERCOMPONENT}_LIBRARY)
    list(APPEND Icu_LIBS ${Icu_${UPPERCOMPONENT}_LIBRARY})
  endif()
endforeach()

# Set Icu_VERSION from icu4c header defines
if(Icu_INCLUDE_DIR)
  file(READ "${Icu_INCLUDE_DIR}/uvernum.h" _icu_version_header)

  string(REGEX MATCH "define[ \t]+U_ICU_VERSION_MAJOR_NUM[ \t]+([0-9]+)"
    _icu_major_version_match "${_icu_version_header}")
  set(Icu_MAJOR_VERSION "${CMAKE_MATCH_1}")
  string(REGEX MATCH "define[ \t]+U_ICU_VERSION_MINOR_NUM[ \t]+([0-9]+)"
    _icu_minor_version_match "${_icu_version_header}")
  set(Icu_MINOR_VERSION "${CMAKE_MATCH_1}")
  string(REGEX MATCH "define[ \t]+U_ICU_VERSION_PATCHLEVEL_NUM[ \t]+([0-9]+)"
    _icu_patchlevel_version_match "${_icu_version_header}")
  set(Icu_PATCHLEVEL_VERSION "${CMAKE_MATCH_1}")

  set(Icu_VERSION
      "${Icu_MAJOR_VERSION}.${Icu_MINOR_VERSION}.${Icu_PATCHLEVEL_VERSION}")
endif(Icu_INCLUDE_DIR)

# Default Icu_FIND_VERSION to 1.0,
if(NOT Icu_FIND_VERSION)
  if(NOT Icu_FIND_VERSION_MAJOR)
    set(Icu_FIND_VERSION_MAJOR 1)
  endif()
  if(NOT Icu_FIND_VERSION_MINOR)
    set(Icu_FIND_VERSION_MINOR 0)
  endif()
  set(Icu_FIND_VERSION "${Icu_FIND_VERSION_MAJOR}.${Icu_FIND_VERSION_MINOR}")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Icu
  FOUND_VAR Icu_FOUND
  REQUIRED_VARS Icu_LIBS Icu_INCLUDE_DIR
  VERSION_VAR Icu_VERSION
)

if(Icu_FOUND)
  set(Icu_LIBRARIES ${Icu_LIBS})
  set(Icu_INCLUDE_DIRS ${Icu_INCLUDE_DIR})

  if(NOT Icu_FIND_QUIETLY)
    message(STATUS "ICU version: ${Icu_MAJOR_VERSION}.${Icu_MINOR_VERSION}.${Icu_SUBMINOR_VERSION}")
    if(Icu_FIND_COMPONENTS)
      message(STATUS "Found the following ICU libraries:")
      foreach(COMPONENT ${Icu_FIND_COMPONENTS})
        string(TOUPPER ${COMPONENT} UPPERCOMPONENT)
        if(Icu_${UPPERCOMPONENT}_LIBRARY)
          message (STATUS "  ${COMPONENT}")
        endif()
      endforeach()
    endif(Icu_FIND_COMPONENTS)
  endif(NOT Icu_FIND_QUIETLY)
endif(Icu_FOUND)

if(Icu_FOUND AND NOT TARGET Icu::Icu)
  add_library(Icu::Icu UNKNOWN IMPORTED)
  set_target_properties(Icu::Icu PROPERTIES
    IMPORTED_LOCATION "${Icu_LIBS}"
    INTERFACE_INCLUDE_DIRECTORIES "${Icu_INCLUDE_DIR}"
  )
endif()

mark_as_advanced(Icu_LIBS Icu_INCLUDE_DIR)
