#.rst:
# FindGMP
# -----------
#
# Find libgmp library and headers
#
# The module defines the following variables:
#
# ::
#
#   GMP_FOUND          - true if libgmp was found
#   GMP_INCLUDE_DIRS   - include search path
#   GMP_LIBRARY         - library to link
#   GMP_VERSION_STRING - version number

find_package(PkgConfig QUIET)
pkg_check_modules(PC_LIBGMP QUIET libgmp)

find_path(GMP_INCLUDE_DIRS NAMES gmp.h HINTS ${PC_LIBEDIT_INCLUDE_DIRS})
find_library(GMP_LIBRARY NAMES gmp HINTS ${PC_LIBEDIT_LIBRARY_DIRS})

include(CheckIncludeFile)
if(GMP_INCLUDE_DIRS AND EXISTS "${GMP_INCLUDE_DIRS}/gmp.h")
  include(CMakePushCheckState)
  cmake_push_check_state()
  list(APPEND CMAKE_REQUIRED_INCLUDES ${GMP_INCLUDE_DIRS})
  list(APPEND CMAKE_REQUIRED_LIBRARIES ${GMP_LIBRARY})
  check_include_file(gmp.h HAVE_GMP_H)
  cmake_pop_check_state()
  if (HAVE_GMP_H)
    file(STRINGS "${GMP_INCLUDE_DIRS}/gmp.h"
          libgmp_version_str
          REGEX "^#define[ \t]+__GNU_MP_VERSION(_MINOR|_PATCHLEVEL)?[ \t]+[0-9]+")
    string(REGEX REPLACE ".*#define[ \t]+__GNU_MP_VERSION[ \t]+([0-9]+).*" "\\1"
          libgmp_major_version "${libgmp_version_str}")
    string(REGEX REPLACE ".*#define[ \t]+__GNU_MP_VERSION_MINOR[ \t]+([0-9]+).*" "\\1"
          libgmp_minor_version "${libgmp_version_str}")
    string(REGEX REPLACE ".*#define[ \t]+__GNU_MP_VERSION_PATCHLEVEL[ \t]+([0-9]+).*" "\\1"
          libgmp_patch_version "${libgmp_version_str}")
    set(GMP_VERSION_STRING "${libgmp_major_version}.${libgmp_minor_version}.${libgmp_patch_version}")
  else()
    set(GMP_INCLUDE_DIRS "")
    set(GMP_LIBRARY "")
  endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GMP
                                  FOUND_VAR
                                    GMP_FOUND
                                  REQUIRED_VARS
                                    GMP_INCLUDE_DIRS
                                    GMP_LIBRARY
                                  VERSION_VAR
                                    GMP_VERSION_STRING)
mark_as_advanced(GMP_INCLUDE_DIRS GMP_LIBRARY)

if (GMP_FOUND AND NOT TARGET GMP::GMP)
  add_library(GMP::GMP UNKNOWN IMPORTED)
  set_target_properties(GMP::GMP PROPERTIES
                        IMPORTED_LOCATION ${GMP_LIBRARY}
                        INTERFACE_INCLUDE_DIRECTORIES ${GMP_INCLUDE_DIRS})
endif()
