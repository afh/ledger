

# add the binary tree to the search path for include files so that we will
# find system.hh
include_directories(
  ${PROJECT_BINARY_DIR}
  ${PROJECT_SOURCE_DIR}/src)

find_package(Python3
  COMPONENTS Interpreter Development)
include_directories(${Python3_INCLUDE_DIRS})

macro(add_ledger_test _name)
  target_link_libraries(${_name} libledger ${Python3_LIBRARIES})
  add_test(Ledger${_name} ${CMAKE_CURRENT_BINARY_DIR}/${_name})
  set_tests_properties(Ledger${_name}
    PROPERTIES ENVIRONMENT "TZ=${Ledger_TEST_TIMEZONE}")
endmacro(add_ledger_test _name)

if (BUILD_LIBRARY)
  add_executable(UtilTests t_times.cc t_format.cc)
  if (HAVE_BOOST_PYTHON)
    target_link_libraries(UtilTests ${Python3_LIBRARIES})
  endif()
  add_ledger_test(UtilTests)

  add_executable(MathTests t_amount.cc t_commodity.cc t_balance.cc t_expr.cc t_value.cc)
  set_source_files_properties(t_amount.cc t_value.cc PROPERTIES COMPILE_FLAGS "-Wno-unused-comparison")
  if (HAVE_BOOST_PYTHON)
    target_link_libraries(MathTests ${Python3_LIBRARIES})
  endif()
  add_ledger_test(MathTests)
endif()
