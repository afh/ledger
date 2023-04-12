file(READ ${PROJECT_SOURCE_DIR}/LICENSE.md Ledger_LICENSE)

configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/__init__.py.in
  ${_ledger_python_module_dir}/__init__.py)

install(FILES
  ${_ledger_python_module_dir}/__init__.py
  DESTINATION "${Python_SITEARCH}/${PYPKG}")

file(COPY
  ${CMAKE_CURRENT_SOURCE_DIR}/core
  ${CMAKE_CURRENT_SOURCE_DIR}/demo
  DESTINATION "${_ledger_python_module_dir}")

if (SKBUILD)
install(DIRECTORY
  "${_ledger_python_module_dir}"
  DESTINATION "${Python_SITEARCH}")
else()
install(DIRECTORY
  "${_ledger_python_module_dir}"
  DESTINATION "${Python_SITEARCH}/${PYPKG}")
endif()

if (NOT SKBUILD)
file(COPY
  ${CMAKE_CURRENT_SOURCE_DIR}/ledger.py
  DESTINATION "${_ledger_python_module_dir}/..")

install(FILES
  ${CMAKE_CURRENT_SOURCE_DIR}/ledger.py
  DESTINATION "${Python_SITEARCH}")
endif()
