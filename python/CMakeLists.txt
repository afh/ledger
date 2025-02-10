file(READ ${PROJECT_SOURCE_DIR}/LICENSE.md Ledger_LICENSE)

set(PYPKG lpy)
if (SKBUILD)
  set(PYPKG_DEST ${CMAKE_CURRENT_BINARY_DIR}/${PYPKG})
else()
  set(PYPKG_DEST ${Python3_SITEARCH}/${PYPKG})
endif()

configure_file(
  __init__.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/__init__.py)

install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/__init__.py
  DESTINATION ${PYPKG_DEST})

if (NOT SKBUILD)
  set(_ledger_python_module_dir ${CMAKE_CURRENT_BINARY_DIR})

  #file(COPY
  #  ${CMAKE_CURRENT_SOURCE_DIR}/ledger.py
  #  DESTINATION "${_ledger_python_module_dir}/..")

  #file(COPY
  install(DIRECTORY
    ${CMAKE_CURRENT_SOURCE_DIR}/lpy/core
    ${CMAKE_CURRENT_SOURCE_DIR}/lpy/demo
    DESTINATION "${PYPKG_DEST}")

  #install(
  #  DIRECTORY "${_ledger_python_module_dir}"
  #  DESTINATION ${PYPKG_DEST})

  install(FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/ledger.py
    DESTINATION ${Python3_SITEARCH})
endif()
