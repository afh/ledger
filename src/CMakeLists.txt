if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(DEBUG_MODE 1)
else()
  set(DEBUG_MODE 0)
endif()

if (DISABLE_ASSERTS)
  set(NO_ASSERTS 1)
else()
  set(NO_ASSERTS 0)
endif()

add_compile_definitions(BOOST_FILESYSTEM_NO_DEPRECATED)

# Set BOOST_ROOT to help CMake to find the right Boost version
find_package(Boost ${Required_Boost_Version}
  REQUIRED date_time filesystem iostreams regex unit_test_framework
  ${BOOST_PYTHON} OPTIONAL_COMPONENTS nowide
  CONFIG)

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

if (CLANG_GCOV)
  set(PROFILE_LIBS profile_rt)
  set(CMAKE_REQUIRED_LIBRARIES ${PROFILE_LIBS})
endif()

########################################################################

include(FindGMP)
find_package(GMP ${Required_Gmp_Version} REQUIRED)
include(FindMPFR)
find_package(MPFR ${Required_Mpfr_Version} REQUIRED)
include(FindICU)
find_package(ICU ${Required_Icu_Version} OPTIONAL_COMPONENTS uc i18n)

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

check_c_source_compiles("
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

set(CMAKE_REQUIRED_INCLUDES ${CMAKE_INCLUDE_PATH} ${Boost_INCLUDE_DIRS} ${ICU_INCLUDE_DIRS})
set(CMAKE_REQUIRED_LIBRARIES Boost::regex ${ICU_LIBRARIES} ${PROFILE_LIBS})

check_cxx_source_runs("
#include <boost/regex/icu.hpp>

using namespace boost;

int main() {
  std::string text = \"Активы\";
  std::basic_string<boost::uint32_t> expr_str = \"Активы\";
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
    message("-- Looking for ${_header} in ${_lib}")
    find_path(${_header_var} ${_header})
    if (NOT ${_header_var})
      message("-- Looking for ${_header} in ${_lib} - not found")
      set(${_have_var} 0)
    else()
      find_library(${_lib_var} ${_lib})
      if (NOT ${_lib_var})
        message("-- Looking for ${_header} in ${_lib} - not found")
        set(${_have_var} 0)
      else()
        message("-- Looking for ${_header} in ${_lib} - found")
        include_directories(SYSTEM "${${_header_var}}")
        set(${_have_var} 1)
      endif()
    endif()
  else()
    set(${_have_var} 0)
  endif()
endmacro(find_opt_library_and_header _header_var _header _lib_var _lib _have_var)

check_library_exists(edit add_history "" HAVE_EDIT)
find_opt_library_and_header(EDIT_PATH editline/readline.h EDIT_LIB edit HAVE_EDIT)
if (NOT HAVE_EDIT)
check_library_exists(readline add_history "" HAVE_READLINE)
find_opt_library_and_header(READLINE_PATH readline/history.h READLINE_LIB readline HAVE_READLINE)
endif (NOT HAVE_EDIT)


#find_package(Gettext)           # Used for running tests

#if (GETTEXT_FOUND)
#  set(HAVE_GETTEXT 1)
#else()
  set(HAVE_GETTEXT 0)
#endif()

#find_path(INTL_PATH libintl.h)
#find_library(INTL_LIB intl)
#include_directories(SYSTEM "${INTL_PATH}")

########################################################################

macro(add_ledger_library_dependencies _target)
  target_link_libraries(${_target} ${Boost_LIBRARIES})
  target_link_libraries(${_target} ${GMP_LIBRARY})
  target_link_libraries(${_target} ${MPFR_LIBRARY})
  target_link_libraries(${_target} PRIVATE ${PROFILE_LIBS})
  if (HAVE_EDIT)
    target_link_libraries(${_target} ${EDIT_LIB})
  endif()
  if (HAVE_READLINE)
    target_link_libraries(${_target} ${READLINE_LIB})
  endif()
  if (HAVE_GETTEXT)
    target_link_libraries(${_target} ${INTL_LIB})
  endif()
  if (HAVE_GPGME)
    target_link_libraries(${_target} Gpgmepp)
  endif()
  if (HAVE_BOOST_REGEX_UNICODE AND ICU_FOUND)
    target_link_libraries(${_target} ${ICU_LIBRARIES})
  endif()
  if (HAVE_BOOST_PYTHON)
    if (CMAKE_SYSTEM_NAME STREQUAL Darwin)
      # Don't link directly to a Python framework on macOS, to avoid segfaults
      # when the module is imported from a different interpreter
      set_target_properties(${_target} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
    else()
      target_link_libraries(${_target} ${Python3_LIBRARIES})
    endif()
  endif()
endmacro(add_ledger_library_dependencies _target)

########################################################################

include(FindUtfcpp)
if (UTFCPP_FOUND)
  include_directories("${UTFCPP_INCLUDE_DIR}")
else()
  message(FATAL_ERROR "Missing required header file: utf8.h\n"
    "Define UTFCPP_PATH or install utfcpp locally into the source tree below lib/utfcpp/."
    )
endif()

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/system.hh.in
  ${PROJECT_BINARY_DIR}/system.hh)

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/ledger.hh.in
  ${PROJECT_BINARY_DIR}/ledger.hh)

# add the binary tree to the search path for include files
# so that we will find system.hh and ledger.hh
include_directories(SYSTEM ${PROJECT_BINARY_DIR})

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX "-isystem ")
endif()

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
  wcwidth.cc
  sha512.cc)

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
  xact.h
  ${PROJECT_BINARY_DIR}/ledger.hh
  ${PROJECT_BINARY_DIR}/system.hh)

if (HAVE_BOOST_PYTHON)
  list(APPEND LEDGER_INCLUDES
    pyinterp.h
    pyutils.h)
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

if (HAVE_GPGME)
  list(APPEND LEDGER_INCLUDES
    gpgme.h)
  list(APPEND LEDGER_SOURCES
    gpgme.cc)
endif()

# Windows provides no strptime(), so supply our own.
if (WIN32 OR CYGWIN)
  list(APPEND LEDGER_INCLUDES
    strptime.h)
  list(APPEND LEDGER_SOURCES
    strptime.cc)
endif()

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    add_compile_options(
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

    add_compile_options(${GXX_WARNING_FLAGS})
  endif()
endif()

include(GNUInstallDirs)

if (BUILD_LIBRARY)
  set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
  add_library(${Ledger_LIB} SHARED ${LEDGER_SOURCES})
  add_ledger_library_dependencies(${Ledger_LIB})
  set_target_properties(${Ledger_LIB} PROPERTIES
    PREFIX ""
    INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}"
    VERSION ${Ledger_VERSION_MAJOR}
    SOVERSION ${Ledger_VERSION_MAJOR})
  set_source_files_properties(
    ${LEDGER_CLI_SOURCES} PROPERTIES COMPILE_FLAGS "-fPIC")

  if (NOT SKBUILD)
    add_executable(${Ledger_CLI} ${LEDGER_CLI_SOURCES})
    target_link_libraries(${Ledger_CLI} ${Ledger_LIB})
    if (HAVE_GPGME)
      target_link_libraries(${Ledger_CLI} Gpgmepp)
    endif()

    if (HAVE_BOOST_PYTHON)
      target_link_libraries(${Ledger_CLI} ${Python3_LIBRARIES})
    endif()

    install(TARGETS ${Ledger_LIB}
      DESTINATION ${CMAKE_INSTALL_LIBDIR})
    install(FILES ${LEDGER_INCLUDES}
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${Ledger_CLI})
  endif()
elseif (NOT SKBUILD)
  add_executable(ledger ${LEDGER_SOURCES} ${LEDGER_CLI_SOURCES})
  add_ledger_library_dependencies(${Ledger_CLI})
endif()

if (PRECOMPILE_SYSTEM_HH)
  if (BUILD_LIBRARY)
    target_precompile_headers(${Ledger_LIB} PRIVATE ${PROJECT_BINARY_DIR}/system.hh)
    if (NOT SKBUILD)
      target_precompile_headers(${Ledger_CLI} REUSE_FROM ${Ledger_LIB})
    endif()
  elseif (NOT SKBUILD)
    target_precompile_headers(${Ledger_CLI} PRIVATE ${PROJECT_BINARY_DIR}/system.hh)
  endif()
endif()

if (USE_PYTHON)
  if (Python3_SITEARCH)
    if (WIN32 AND NOT CYGWIN)
      set(_ledger_python_module_name "${Ledger_MODULE_EXT}.pyd")
    elseif(CMAKE_SYSTEM_NAME STREQUAL Darwin)
      set(_ledger_python_module_name "${Ledger_MODULE_EXT}.so")
    else()
      set(_ledger_python_module_name "${Ledger_MODULE_EXT}${CMAKE_SHARED_LIBRARY_SUFFIX}")
    endif()

    # FIXME: symlink would be sufficient:
    # maybe using install(CODE "...") and
    # execute_process(COMMAND "${CMAKE_COMMAND}" -E create_symlink ...).
    # Windows will need a special case due to not supporting symlinks.
    add_custom_command(
      TARGET ${Ledger_LIB} POST_BUILD
      COMMAND ${CMAKE_COMMAND}  -E copy #_if_different # The lpy core modules neeeds always to be copied
      $<TARGET_FILE:${Ledger_LIB}> "${CMAKE_BINARY_DIR}/${_ledger_python_module_name}")
    if (SKBUILD)
      install(
        FILES ${CMAKE_BINARY_DIR}/${_ledger_python_module_name} # _${_ledger_python_module_name}
        DESTINATION "${PYPKG_DEST}") #/${Ledger_MODULE}/${Ledger_MODULE_EXT}")
    else()
      install(
        FILES ${CMAKE_BINARY_DIR}/${_ledger_python_module_name} # _${_ledger_python_module_name}
        DESTINATION "${PYPKG_DEST}") #/${Ledger_MODULE_EXT}")
    endif()
  else()
    message(WARNING "Python3_SITEARCH not set. Will not install python module.")
  endif()
endif()


if (NOT SKBUILD)
  install(TARGETS ${Ledger_CLI} DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

### CMakeLists.txt ends here
