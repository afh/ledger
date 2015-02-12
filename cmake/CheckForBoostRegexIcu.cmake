#.rst
# CheckForBoostRegexIcu
# ---------------------
#
# Finds the GNU Multiple Precision Arithmetic Library
# See https://gmplib.org/
#
# This will define the following variables::
#
#   BOOST_REGEX_UNICODE_RUNS

#=============================================================================
# Copyright 2012-2015 John Wiegley
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================

include(CheckCXXSourceRuns)
include(CMakePushCheckState)

cmake_push_check_state()

set(CMAKE_REQUIRED_INCLUDES ${CMAKE_INCLUDE_PATH} ${Boost_INCLUDE_DIRS})
set(CMAKE_REQUIRED_LIBRARIES ${Boost_LIBRARIES} ${Icu_LIBRARY})

check_cxx_source_runs("
#include <boost/regex/icu.hpp>

using namespace boost;

int main() {
  std::string text = \"Активы\";
  u32regex r = make_u32regex(\"активы\", regex::perl | regex::icase);
  return u32regex_search(text, r) ? 0 : 1;
}" BOOST_REGEX_UNICODE_RUNS)

cmake_pop_check_state()
