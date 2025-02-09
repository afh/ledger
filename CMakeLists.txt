set(Required_CMake_Version   3.16.2)
set(Required_CMake_Policy    3.22)
set(Required_Boost_Version   1.72)
set(Required_Icu_Version     63)
set(Required_Gmp_Version     6.1.2)
set(Required_Mpfr_Version    4.0.2)
set(Required_Python_Version  3.9)
set(Required_Gpgmepp_Version 1.13.1)

set(Ledger_VERSION            3.3.2)
set(Ledger_VERSION_PRERELEASE "")
set(Ledger_VERSION_DATE       20230330)

cmake_minimum_required(
  VERSION ${Required_CMake_Version}..${Required_CMake_Policy})

if (NOT SKBUILD)
  set(SKBUILD_PROJECT_NAME ledger)
  set(SKBUILD_PROJECT_VERSION ${Ledger_VERSION})
endif()

project(
  ${SKBUILD_PROJECT_NAME}
  VERSION ${SKBUILD_PROJECT_VERSION}
  LANGUAGES CXX C
  HOMEPAGE_URL "https://ledger-cli.org"
  )

#[[
# Targets
option(BUILD_BINARY "" ON) # Build ledger and depending on ENABLE_LIBRARY linked libledger
option(BUILD_LIBRARY "" OFF) # Only Build libledger, sets ENABLE_LIBRARY
option(BUILD_PACKAGE "" OFF) # Builds libledger as Python module

# Features
option(ENABLE_PYTHON "" OFF)
option(ENABLE_GPGME "" OFF)
# Misc
option(ENABLE_LIBRARY "" ON)
option(ENABLE_ASSERTS "" ON)
option(ENABLE_DEBUG "" OFF)
#
option(ENABLE_INFO "" OFF)
option(ENABLE_WEB_DOCS "" OFF)
option(ENABLE_API_DOCS "" OFF)

#list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/doc")
#include(LedgerVersion)
]]

#[[
ENABLE_PYTHON OFF [USE_PYTHON]
ENABLE_GPGME OFF  [USE_GPGME]
ENABLE_LIBRARY ON [✗ BUILD_LIBRARY]
ENABLE_DEBUG OFF  [BUILD_DEBUG]
ENABLE_ASSERTS ON [DISABLE_ASSERTS]

BUILD_BINARY✗ (ledger + opt libledger)
BUILD_LIBRARY (libledger)
BUILD_PACKAGE (lpy)

BUILD_MANUAL   (info + opt html + pdf) [ BUILD_DOCS + BUILD_WEB_DOCS ]
BUILD_API_DOCS (doxygen html + opt pdf) [USE_DOXYGEN]

docs:
  - manpage
  - manual: info, html, pdf
  - apidocs: html (pdf)
]]

# Point CMake at any custom modules we may ship
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

enable_testing()

########################################################################

option(USE_PYTHON "Build support for the Python scripting bridge" OFF)
option(USE_DOXYGEN "Build reference documentation using Doxygen" OFF)

option(DISABLE_ASSERTS "Build without any internal consistency checks" OFF)
option(PRECOMPILE_SYSTEM_HH "Precompile system.hh" ON)

option(USE_GPGME "Build with support for encrypted journals" OFF)
option(BUILD_LIBRARY "Build and install Ledger as a library" ON)
option(BUILD_DOCS "Build and install documentation" OFF)
option(BUILD_WEB_DOCS "Build version of documentation suitable for viewing online" OFF)
option(BUILD_DEBUG "Build support for runtime debugging" OFF) # Deprecated in favor of CMAKE_BUILD_TYPE Debug

########################################################################

add_subdirectory(src)
add_subdirectory(test)
add_subdirectory(python)
add_subdirectory(doc)

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
