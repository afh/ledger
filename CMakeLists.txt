set(Required_CMake_Version 3.16.2)
set(Required_CMake_Policy 3.22)
set(Required_Boost_Version 1.72)
set(Required_Gmp_Version 6.1.2)
set(Required_Mpfr_Version 4.0.2)
set(Required_Icu_Version 63)
set(Required_Python_Version 3.10)
set(Required_Gpgmepp_Version 1.13.1)

cmake_minimum_required(
  VERSION ${Required_CMake_Version}..${Required_CMake_Policy})
cmake_policy(SET CMP0167 NEW)

# Point CMake at any custom modules we may ship
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

PROJECT(ledger)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/doc")
include(LedgerVersion)

enable_testing()

set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard")
if (CYGWIN)
  add_compile_options(-U__STRICT_ANSI__)
endif()

########################################################################

option(USE_PYTHON "Build support for the Python scripting bridge" OFF)
option(USE_DOXYGEN "Build reference documentation using Doxygen" OFF)

option(DISABLE_ASSERTS "Build without any internal consistency checks" OFF)
option(PRECOMPILE_SYSTEM_HH "Precompile system.hh" ON)

option(USE_GPGME "Build with support for encrypted journals" OFF)
option(BUILD_LIBRARY "Build and install Ledger as a library" ON)
option(BUILD_DOCS "Build and install documentation" OFF)
option(BUILD_WEB_DOCS "Build version of documentation suitable for viewing online" OFF)

option(CMAKE_BUILD_TYPE "CMake Build type" "Release")
option(BUILD_DEBUG "Build support for runtime debugging" OFF)
if (BUILD_DEBUG)
  message(DEPRECATION "BUILD_DEBUG is deprecated! Set CMAKE_BUILD_TYPE to Debug instead!")
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "CMake Build type" FORCE)
  unset(BUILD_DEBUG CACHE)
endif()

########################################################################

if (USE_PYTHON)
  if (NOT BUILD_LIBRARY)
    message(ERROR "Building the python module requires BUILD_LIBRARY=ON.")
  endif()

  find_package(Python3
    COMPONENTS Interpreter Development)
  if (Python3_FOUND AND ${Python3_VERSION} VERSION_GREATER_EQUAL ${Required_Python_Version})
    set(BOOST_PYTHON "python${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}")
    set(HAVE_BOOST_PYTHON 1)
    include_directories(SYSTEM ${Python3_INCLUDE_DIRS})
  else()
    set(HAVE_BOOST_PYTHON 0)
    message("Could not find a Python3 library to use with Boost.Python")
  endif()
else()
  set(HAVE_BOOST_PYTHON 0)
endif()

add_subdirectory(src)
add_subdirectory(doc)
add_subdirectory(contrib)
add_subdirectory(test)

########################################################################

# build a CPack driven installer package
include (InstallRequiredSystemLibraries)

set (CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.md")
set (CPACK_PACKAGE_VERSION_MAJOR "${Ledger_VERSION_MAJOR}")
set (CPACK_PACKAGE_VERSION_MINOR "${Ledger_VERSION_MINOR}")
set (CPACK_PACKAGE_VERSION_PATCH "${Ledger_VERSION_PATCH}${Ledger_VERSION_PRERELEASE}")

set (CPACK_GENERATOR "TBZ2")
set (CPACK_SOURCE_GENERATOR "TBZ2")
set (CPACK_SOURCE_PACKAGE_FILE_NAME
  "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
set (CPACK_SOURCE_IGNORE_FILES "/.git*;/.dir-locals.el;~$;/doc/website/;/doc/wiki/;/lib/*.sh;/lib/Makefile;/tools/;${CPACK_SOURCE_IGNORE_FILES}")

include (CPack)

### CMakeLists.txt ends here
