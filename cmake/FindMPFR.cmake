#.rst:
# FindMPFR
# -----------
#
# Find libmpfr library and headers
#
# The module defines the following variables:
#
# ::
#
#   MPFR_FOUND          - true if libmpfr was found
#   MPFR_INCLUDE_DIRS   - include search path
#   MPFR_LIBRARY        - libraries to link
#   MPFR_VERSION_STRING - version number

find_package(PkgConfig QUIET)
pkg_check_modules(PC_LIBEDIT QUIET libmpfr)

find_path(MPFR_INCLUDE_DIRS NAMES mpfr.h HINTS ${PC_LIBEDIT_INCLUDE_DIRS})
find_library(MPFR_LIBRARY NAMES mpfr HINTS ${PC_LIBEDIT_LIBRARY_DIRS})

include(CheckIncludeFile)
if(MPFR_INCLUDE_DIRS AND EXISTS "${MPFR_INCLUDE_DIRS}/mpfr.h")
  include(CMakePushCheckState)
  cmake_push_check_state()
  list(APPEND CMAKE_REQUIRED_INCLUDES ${MPFR_INCLUDE_DIRS})
  list(APPEND CMAKE_REQUIRED_LIBRARIES ${MPFR_LIBRARY})
  check_include_file(mpfr.h HAVE_HISTEDIT_H)
  cmake_pop_check_state()
  if (HAVE_HISTEDIT_H)
    file(STRINGS "${MPFR_INCLUDE_DIRS}/mpfr.h"
          libmpfr_version_str
          REGEX "^#define[ \t]+MPFR_VERSION_(M(IN|AJ)OR|PATCHLEVEL)[ \t]+[0-9]+")
    string(REGEX REPLACE ".*#define[ \t]+MPFR_VERSION_MAJOR[ \t]+([0-9]+).*" "\\1"
        libmpfr_major_version "${libmpfr_version_str}")
    string(REGEX REPLACE ".*#define[ \t]+MPFR_VERSION_MINOR[ \t]+([0-9]+).*" "\\1"
          libmpfr_minor_version "${libmpfr_version_str}")
        string(REGEX REPLACE ".*#define[ \t]+MPFR_VERSION_PATCHLEVEL[ \t]+([0-9]+).*" "\\1"
          libmpfr_patch_version "${libmpfr_version_str}")

    set(MPFR_VERSION_STRING "${libmpfr_major_version}.${libmpfr_minor_version}.${libmpfr_patch_version}")
  else()
    set(MPFR_INCLUDE_DIRS "")
    set(MPFR_LIBRARY "")
  endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MPFR
                                  FOUND_VAR
                                    MPFR_FOUND
                                  REQUIRED_VARS
                                    MPFR_INCLUDE_DIRS
                                    MPFR_LIBRARY
                                  VERSION_VAR
                                    MPFR_VERSION_STRING)
mark_as_advanced(MPFR_INCLUDE_DIRS MPFR_LIBRARY)

if (MPFR_FOUND AND NOT TARGET MPFR::MPFR)
  add_library(MPFR::MPFR UNKNOWN IMPORTED)
  set_target_properties(MPFR::MPFR PROPERTIES
                        IMPORTED_LOCATION ${MPFR_LIBRARY}
                        INTERFACE_INCLUDE_DIRECTORIES ${MPFR_INCLUDE_DIRS})
endif()
