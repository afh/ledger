file(READ ${PROJECT_SOURCE_DIR}/LICENSE.md Ledger_LICENSE)

configure_file(
  __init__.py.in
  __init__.py)

if (SKBUILD)
  set(PYPKG_DEST lpy)
else()
  set(PYPKG_DEST ${Python3_SITEARCH}/${PYPKG})
endif()

install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/__init__.py
  DESTINATION ${PYPKG_DEST})

if (NOT SKBUILD)
  set(_ledger_python_module_dir ${CMAKE_CURRENT_BINARY_DIR})

  install(
    DIRECTORY "${_ledger_python_module_dir}"
    DESTINATION ${PYPKG_DEST})

  file(
    COPY ${CMAKE_CURRENT_SOURCE_DIR}/ledger.py
    DESTINATION "${_ledger_python_module_dir}/..")

  install(FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/ledger.py
    DESTINATION ${PYPKG_DEST})

  file(COPY
    ${CMAKE_CURRENT_SOURCE_DIR}/lpy/core
    ${CMAKE_CURRENT_SOURCE_DIR}/lpy/demo
    DESTINATION "${_ledger_python_module_dir}")
endif()
