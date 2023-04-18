########################################################################

macro(add_ledger_library_dependencies _target)
  target_link_libraries(${_target} ${MPFR_LIB})
  target_link_libraries(${_target} ${GMP_LIB})
  if (HAVE_EDIT)
    target_link_libraries(${_target} ${EDIT_LIB})
  endif()
  if (HAVE_GETTEXT)
    target_link_libraries(${_target} ${INTL_LIB})
  endif()
  if (HAVE_GPGME)
    target_link_libraries(${_target} Gpgmepp)
  endif()
  if (HAVE_BOOST_PYTHON)
    if (CMAKE_SYSTEM_NAME STREQUAL Darwin)
      # Don't link directly to a Python framework on macOS, to avoid segfaults
      # when the module is imported from a different interpreter
      target_link_libraries(${_target} ${Boost_LIBRARIES})
      set_target_properties(${_target} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
    else()
      target_link_libraries(${_target} ${Boost_LIBRARIES} ${Python3_LIBRARIES})
    endif()
  else()
    target_link_libraries(${_target} ${Boost_LIBRARIES})
  endif()
  if (HAVE_BOOST_REGEX_UNICODE)
    target_link_libraries(${_target} icuuc)
  endif()
  target_link_libraries(${_target} ${PROFILE_LIBS})
endmacro(add_ledger_library_dependencies _target)

########################################################################

find_package(Python COMPONENTS Interpreter) # Used for running tests

if (USE_PYTHON)
  if (NOT BUILD_LIBRARY)
    message(ERROR "Building the python module requires BUILD_LIBRARY=ON.")
  endif()

  find_package(Python3
    COMPONENTS Interpreter Development)
  if (PYTHON_FOUND AND ${Python3_VERSION} VERSION_GREATER_EQUAL ${Required_Python_Version})
    set(BOOST_PYTHON "python${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}")
    set(HAVE_BOOST_PYTHON 1)
    include_directories(SYSTEM ${Python3_INCLUDE_DIRS})
  else()
    set(HAVE_BOOST_PYTHON 0)
    message("Could not find a Python library to use with Boost.Python")
  endif()
else()
  set(HAVE_BOOST_PYTHON 0)
endif()

# Set BOOST_ROOT to help CMake to find the right Boost version
find_package(Boost ${Required_Boost_Version}
  REQUIRED date_time filesystem system iostreams regex unit_test_framework
  ${BOOST_PYTHON} OPTIONAL_COMPONENTS nowide)

# enable Boost::nowide library (for UTF8 command line args on Windows)
set(HAVE_BOOST_NOWIDE 0)
if (Boost_NOWIDE_FOUND)
  set(HAVE_BOOST_NOWIDE 1)
endif()

include_directories(SYSTEM ${Boost_INCLUDE_DIRS})
link_directories(${Boost_LIBRARY_DIRS})

# Crypto
if (USE_GPGME)
  find_package(Gpgmepp ${Required_Gpgmepp_Version} REQUIRED)
  set(HAVE_GPGME 1)
  include_directories(SYSTEM ${Gpgmepp_INCLUDE_DIRS})
  link_directories(${Gpgmepp_LIBRARY_DIRS})
else()
  set(HAVE_GPGME 0)
endif()

########################################################################

include(CheckIncludeFiles)
include(CheckLibraryExists)
include(CheckFunctionExists)
include(CheckCSourceCompiles)
include(CheckCXXSourceCompiles)
include(CheckCXXSourceRuns)
include(CMakePushCheckState)

check_function_exists(getpwuid HAVE_GETPWUID)
check_function_exists(getpwnam HAVE_GETPWNAM)
check_function_exists(ioctl HAVE_IOCTL)
check_function_exists(isatty HAVE_ISATTY)

check_cxx_source_compiles("
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int main() {
  int status, pfd[2];
  status = pipe(pfd);
  status = fork();
  if (status < 0) {
    ;
  } else if (status == 0) {
    char *arg0 = NULL;

    status = dup2(pfd[0], STDIN_FILENO);

    close(pfd[1]);
    close(pfd[0]);

    execlp(\"\", arg0, (char *)0);
    perror(\"execl\");
    exit(1);
  } else {
    close(pfd[0]);
  }
  return 0;
}" UNIX_PIPES_COMPILES)

if (UNIX_PIPES_COMPILES)
  set(HAVE_UNIX_PIPES 1)
else()
  set(HAVE_UNIX_PIPES 0)
endif()

cmake_push_check_state()

set(CMAKE_REQUIRED_INCLUDES ${CMAKE_INCLUDE_PATH} ${Boost_INCLUDE_DIRS})
set(CMAKE_REQUIRED_LIBRARIES ${Boost_LIBRARIES} icuuc ${PROFILE_LIBS})

check_cxx_source_runs("
#include <boost/regex/icu.hpp>

using namespace boost;

int main() {
  std::string text = \"Активы\";
  u32regex r = make_u32regex(\"активы\", regex::perl | regex::icase);
  return u32regex_search(text, r) ? 0 : 1;
}" BOOST_REGEX_UNICODE_RUNS)

if (BOOST_REGEX_UNICODE_RUNS)
  set(HAVE_BOOST_REGEX_UNICODE 1)
else()
  set(HAVE_BOOST_REGEX_UNICODE 0)
endif()

cmake_pop_check_state()

########################################################################

include_directories(${CMAKE_INCLUDE_PATH})

macro(find_opt_library_and_header _header_var _header _lib_var _lib _have_var)
  if (${_have_var})
    find_path(${_header_var} ${_header})
    if (NOT ${_header_var})
      set(${_have_var} 0)
    else()
      find_library(${_lib_var} ${_lib})
      if (NOT ${_lib_var})
        set(${_have_var} 0)
      else()
        include_directories(SYSTEM "${${_header_var}}")
        set(${_have_var} 1)
      endif()
    endif()
  else()
    set(${_have_var} 0)
  endif()
endmacro(find_opt_library_and_header _header_var _header _lib_var _lib _have_var)

macro(find_req_library_and_header _header_var _header _lib_var _lib)
  find_path(${_header_var} ${_header})
  if (NOT ${_header_var})
    message(SEND_ERROR "Could not find ${_header} on your system")
  else()
    include_directories(SYSTEM "${${_header_var}}")
    find_library(${_lib_var} ${_lib})
    if (NOT ${_lib_var})
      message(SEND_ERROR "Could not find library ${_lib} on your system")
    endif()
  endif()
endmacro(find_req_library_and_header _header_var _header _lib_var _lib)

find_req_library_and_header(GMP_PATH gmp.h GMP_LIB gmp)
if (GMP_PATH AND EXISTS "${GMP_PATH}/gmp.h")
  file(STRINGS "${GMP_PATH}/gmp.h" gmp_header_str REGEX "^#define[\t ]+__GNU_MP_VERSION(_MINOR|_PATCHLEVEL)?[\t ]+[0-9]+")
  string(REGEX REPLACE ".*#define __GNU_MP_VERSION[\t ]+([0-9]+).*" "\\1" GMP_VERSION_MAJOR "${gmp_header_str}")
  string(REGEX REPLACE ".*#define __GNU_MP_VERSION_MINOR[\t ]+([0-9]+).*" "\\1" GMP_VERSION_MINOR "${gmp_header_str}")
  string(REGEX REPLACE ".*#define __GNU_MP_VERSION_PATCHLEVEL[\t ]+([0-9]+).*" "\\1" GMP_VERSION_PATCH "${gmp_header_str}")
  unset(gmp_header_str)
  set(GMP_VERSION_STRING "${GMP_VERSION_MAJOR}.${GMP_VERSION_MINOR}.${GMP_VERSION_PATCH}")
  if ("${GMP_VERSION_STRING}" VERSION_LESS ${Required_Gmp_Version})
    message(FATAL_ERROR "Ledger requires GMP version ${Expected_Gmp_Version} or greater, but only GMP version ${GMP_VERSION_STRING} was found")
  endif()
endif()

find_req_library_and_header(MPFR_PATH mpfr.h MPFR_LIB mpfr)
if (MPFR_PATH AND EXISTS "${MPFR_PATH}/mpfr.h")
  file(STRINGS "${MPFR_PATH}/mpfr.h" mpfr_header_str REGEX "^#define[\t ]+MPFR_VERSION_(MAJOR|MINOR|PATCHLEVEL)[\t ]+[0-9]+")
  string(REGEX REPLACE ".*#define MPFR_VERSION_MAJOR[\t ]+([0-9]+).*" "\\1" MPFR_VERSION_MAJOR "${mpfr_header_str}")
  string(REGEX REPLACE ".*#define MPFR_VERSION_MINOR[\t ]+([0-9]+).*" "\\1" MPFR_VERSION_MINOR "${mpfr_header_str}")
  string(REGEX REPLACE ".*#define MPFR_VERSION_PATCHLEVEL[\t ]+([0-9]+).*" "\\1" MPFR_VERSION_PATCH "${mpfr_header_str}")
  unset(mpfr_header_str)
  set(MPFR_VERSION_STRING "${MPFR_VERSION_MAJOR}.${MPFR_VERSION_MINOR}.${MPFR_VERSION_PATCH}")
  if ("${MPFR_VERSION_STRING}" VERSION_LESS ${Required_Mpfr_Version})
    message(FATAL_ERROR "Ledger requires MPFR version ${Expected_Mpfr_Version} or greater, but only MPFR version ${MPFR_VERSION_STRING} was found")
  endif()
endif()


check_library_exists(edit readline "" HAVE_EDIT)
find_opt_library_and_header(EDIT_PATH histedit.h EDIT_LIB edit HAVE_EDIT)

#find_package(Gettext)           # Used for running tests

#if (GETTEXT_FOUND)
#  set(HAVE_GETTEXT 1)
#else()
  set(HAVE_GETTEXT 0)
#endif()

#find_path(INTL_PATH libintl.h)
#find_library(INTL_LIB intl)
#include_directories(SYSTEM "${INTL_PATH}")
set(LEDGER_CLI_SOURCES
  global.cc
  main.cc)

set(LEDGER_SOURCES
  stats.cc
  generate.cc
  csv.cc
  convert.cc
  draft.cc
  emacs.cc
  ptree.cc
  print.cc
  output.cc
  precmd.cc
  chain.cc
  filters.cc
  report.cc
  views.cc
  select.cc
  session.cc
  option.cc
  lookup.cc
  compare.cc
  iterators.cc
  timelog.cc
  textual.cc
  temps.cc
  journal.cc
  account.cc
  xact.cc
  post.cc
  item.cc
  format.cc
  query.cc
  scope.cc
  expr.cc
  op.cc
  parser.cc
  token.cc
  value.cc
  balance.cc
  quotes.cc
  history.cc
  pool.cc
  annotate.cc
  commodity.cc
  amount.cc
  stream.cc
  mask.cc
  times.cc
  error.cc
  utils.cc
  wcwidth.cc)

if (HAVE_GPGME)
  list(APPEND LEDGER_SOURCES
    gpgme.cc)
endif()

if (HAVE_BOOST_PYTHON)
  list(APPEND LEDGER_SOURCES
    py_account.cc
    py_amount.cc
    py_balance.cc
    py_commodity.cc
    py_expr.cc
    py_format.cc
    py_item.cc
    py_journal.cc
    py_post.cc
    py_session.cc
    py_times.cc
    py_utils.cc
    py_value.cc
    py_xact.cc
    pyinterp.cc
    pyledger.cc)
endif()

set(LEDGER_INCLUDES
  account.h
  amount.h
  annotate.h
  balance.h
  chain.h
  commodity.h
  compare.h
  context.h
  convert.h
  csv.h
  draft.h
  emacs.h
  error.h
  expr.h
  exprbase.h
  filters.h
  flags.h
  format.h
  generate.h
  global.h
  gpgme.h
  history.h
  item.h
  iterators.h
  journal.h
  lookup.h
  mask.h
  op.h
  option.h
  output.h
  parser.h
  pool.h
  post.h
  precmd.h
  predicate.h
  print.h
  pstream.h
  ptree.h
  pyinterp.h
  pyutils.h
  query.h
  quotes.h
  report.h
  scope.h
  select.h
  session.h
  stats.h
  stream.h
  temps.h
  timelog.h
  times.h
  token.h
  unistring.h
  utils.h
  value.h
  views.h
  xact.h
  ${PROJECT_BINARY_DIR}/system.hh)

include(FindUtfcpp)
if (UTFCPP_FOUND)
  include_directories(${UTFCPP_INCLUDE_DIR})
else()
  message(FATAL_ERROR "Missing required header file: utf8.h\n"
    "Define UTFCPP_PATH or install utfcpp locally into the source tree below lib/utfcpp/."
    )
endif()

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})

add_definitions(
  -std=c++11
  -DBOOST_FILESYSTEM_NO_DEPRECATED
)

if (CYGWIN)
  add_definitions(-U__STRICT_ANSI__)
endif()

if (BUILD_DEBUG)
  set(CMAKE_BUILD_TYPE Debug)
  set(DEBUG_MODE 1)
else()
  set(CMAKE_BUILD_TYPE Release)
  set(DEBUG_MODE 0)
endif()

if (DISABLE_ASSERTS)
  set(NO_ASSERTS 1)
else()
  set(NO_ASSERTS 0)
endif()

if (CLANG_GCOV)
  set(PROFILE_LIBS profile_rt)
  set(CMAKE_REQUIRED_LIBRARIES ${PROFILE_LIBS})
endif()

configure_file(
  system.hh.in
  ${PROJECT_BINARY_DIR}/system.hh)

# add the binary tree to the search path for include files
# so that we will find the generated system.hh.
include_directories(${PROJECT_BINARY_DIR})

# Windows provides no strptime(), so supply our own.
if (WIN32 OR CYGWIN)
  list(APPEND LEDGER_INCLUDES
    strptime.h)
  list(APPEND LEDGER_SOURCES
    strptime.cc)
endif()

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX "-isystem ")
endif()

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    add_definitions(
      # -Weverything
      # -Wno-disabled-macro-expansion
      # -Wno-padded
      # -Wno-weak-vtables
      # -Wno-exit-time-destructors
      # -Wno-global-constructors
      # -Wno-switch-enum
      # -Wno-missing-prototypes
      # -Wno-missing-noreturn
      # -Wno-unused-parameter
      # -Wno-c++98-compat
      # -fno-limit-debug-info
      -Wno-\#pragma-messages
      -Wno-unused-local-typedef
      --system-header-prefix=include/boost/
      --system-header-prefix=boost/)

    macro(ADD_PCH_RULE _header_filename _src_list _other_srcs)
      set(_pch_filename "${_header_filename}.pch")

      set_source_files_properties(
        ${${_src_list}} PROPERTIES COMPILE_FLAGS "-include ${_header_filename}")
      if (_other_srcs)
        set_source_files_properties(
          ${_other_srcs} PROPERTIES COMPILE_FLAGS "-include ${_header_filename}")
      endif()
      list(APPEND ${_src_list} ${_pch_filename})

      set(_args ${CMAKE_CXX_FLAGS})
      list(APPEND _args ${CMAKE_CXX_FLAGS_DEBUG})
      if (BUILD_LIBRARY)
        list(APPEND _args ${CMAKE_SHARED_LIBRARY_CXX_FLAGS})
      endif()
      list(APPEND _args "-std=c++11 ")
      if (CYGWIN)
        list(APPEND _args "-U__STRICT_ANSI__")
      endif()
      list(APPEND _args "-x c++-header " ${_inc})
      list(APPEND _args -c ${_header_filename} -o ${_pch_filename})

      get_directory_property(DIRINC INCLUDE_DIRECTORIES)
      foreach(_inc ${DIRINC})
        list(APPEND _args "-isystem " ${_inc})
      endforeach(_inc ${DIRINC})

      separate_arguments(_args)

      add_custom_command(OUTPUT ${_pch_filename}
        COMMAND rm -f ${_pch_filename}
        COMMAND ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1} ${_args}
        DEPENDS ${_header_filename})
    endmacro(ADD_PCH_RULE _header_filename _src_list _other_srcs)

  elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(GXX_WARNING_FLAGS
      -pedantic
      -Wall
      -Winvalid-pch
      -Wextra
      -Wcast-align
      -Wcast-qual
      -Wfloat-equal
      -Wmissing-field-initializers
      -Wno-endif-labels
      -Wno-overloaded-virtual
      -Wsign-compare
      -Wsign-promo
      -Wwrite-strings
      -Wno-unused-parameter
      -Wno-old-style-cast
      -Wno-deprecated
      -Wno-strict-aliasing)

    add_definitions(${GXX_WARNING_FLAGS})

    macro(ADD_PCH_RULE _header_filename _src_list _other_srcs)
      set(_gch_filename "${_header_filename}.gch")

      set_source_files_properties(
        ${${_src_list}} PROPERTIES COMPILE_FLAGS "-Winvalid-pch")
      if (_other_srcs)
        set_source_files_properties(
          ${_other_srcs} PROPERTIES COMPILE_FLAGS "-Winvalid-pch")
      endif()
      list(APPEND ${_src_list} ${_gch_filename})

      set(_args ${CMAKE_CXX_FLAGS})
      list(APPEND _args ${CMAKE_CXX_FLAGS_DEBUG})
      if (BUILD_LIBRARY)
        list(APPEND _args ${CMAKE_SHARED_LIBRARY_CXX_FLAGS})
      endif()
      list(APPEND _args ${GXX_WARNING_FLAGS})
      list(APPEND _args "-std=c++11 ")
      if (CYGWIN)
        list(APPEND _args "-U__STRICT_ANSI__")
      endif()
      list(APPEND _args "-x c++-header " ${_inc})
      list(APPEND _args -c ${_header_filename} -o ${_gch_filename})

      get_directory_property(DIRINC INCLUDE_DIRECTORIES)
      foreach(_inc ${DIRINC})
        list(APPEND _args "-I" ${_inc})
      endforeach(_inc ${DIRINC})

      separate_arguments(_args)

      add_custom_command(OUTPUT ${_gch_filename}
        COMMAND rm -f ${_gch_filename}
        COMMAND ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1} ${_args}
        DEPENDS ${_header_filename})
    endmacro(ADD_PCH_RULE _header_filename _src_list _other_srcs)

  else()
    macro(ADD_PCH_RULE _header_filename _src_list _other_srcs)
    endmacro(ADD_PCH_RULE _header_filename _src_list _other_srcs)
  endif()
else()
  macro(ADD_PCH_RULE _header_filename _src_list _other_srcs)
  endmacro(ADD_PCH_RULE _header_filename _src_list _other_srcs)
endif()

if(PRECOMPILE_SYSTEM_HH AND NOT (COMMAND target_precompile_headers))
  # enable fallback for CMake versions older than 3.16 without target_precompile_headers
  add_pch_rule(${PROJECT_BINARY_DIR}/system.hh LEDGER_SOURCES LEDGER_CLI_SOURCES)
endif()

include(GNUInstallDirs)

if (BUILD_LIBRARY)
  set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
  add_library(libledger SHARED ${LEDGER_SOURCES})
  add_ledger_library_dependencies(libledger)
  set_target_properties(libledger PROPERTIES
    PREFIX ""
    INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}"
    VERSION ${Ledger_VERSION_MAJOR}
    SOVERSION ${Ledger_VERSION_MAJOR})

  add_executable(ledger main.cc global.cc)
  target_link_libraries(ledger libledger)
  if (HAVE_GPGME)
    target_link_libraries(ledger Gpgmepp)
  endif()

  if (HAVE_BOOST_PYTHON)
    target_link_libraries(ledger ${Python3_LIBRARIES})
  endif()

  install(TARGETS libledger DESTINATION ${CMAKE_INSTALL_LIBDIR})
  install(FILES ${LEDGER_INCLUDES}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/ledger)
else()
  add_executable(ledger ${LEDGER_SOURCES} main.cc global.cc)
  add_ledger_library_dependencies(ledger)
endif()

if (PRECOMPILE_SYSTEM_HH AND (COMMAND target_precompile_headers) AND (CMAKE_BUILD_TYPE STREQUAL "Debug"))
  if (BUILD_LIBRARY)
    target_precompile_headers(libledger PRIVATE ${PROJECT_BINARY_DIR}/system.hh)
    target_precompile_headers(ledger REUSE_FROM libledger)
  else()
    target_precompile_headers(ledger PRIVATE ${PROJECT_BINARY_DIR}/system.hh)
  endif()
endif()

if (USE_PYTHON)
  if (Python3_SITEARCH)
    if (WIN32 AND NOT CYGWIN)
      set(_ledger_python_module_name "ledger.pyd")
    elseif(CMAKE_SYSTEM_NAME STREQUAL Darwin)
      set(_ledger_python_module_name "ledger.so")
    else()
      set(_ledger_python_module_name "ledger${CMAKE_SHARED_LIBRARY_SUFFIX}")
    endif()

    # FIXME: symlink would be sufficient:
    # maybe using install(CODE "...") and
    # execute_process(COMMAND "${CMAKE_COMMAND}" -E create_symlink ...).
    # Windows will need a special case due to not supporting symlinks.
    add_custom_command(
      TARGET libledger POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy #_if_different
      $<TARGET_FILE:libledger> "${CMAKE_BINARY_DIR}/${_ledger_python_module_name}")
    install(
      FILES "${CMAKE_BINARY_DIR}/${_ledger_python_module_name}"
      DESTINATION ${Python3_SITEARCH})
  else()
    message(WARNING "Python3_SITEARCH not set. Will not install python module.")
  endif()
endif()

install(TARGETS ledger DESTINATION ${CMAKE_INSTALL_BINDIR})

### CMakeLists.txt ends here
