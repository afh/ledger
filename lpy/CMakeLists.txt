file(READ ${PROJECT_SOURCE_DIR}/LICENSE.md Ledger_LICENSE)

configure_file(
  __init__.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/__init__.py)

if (NOT SKBUILD)
install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/__init__.py
  DESTINATION ${PYPKG_DEST})
else()
install(
  FILES ${CMAKE_CURRENT_BINARY_DIR}/__init__.py
  DESTINATION ${SKBUILD_PLATLIB_DIR}/${Ledger_MODULE})
endif()

#if (NOT SKBUILD)
  set(_ledger_python_module_dir ${CMAKE_CURRENT_BINARY_DIR})

  #file(COPY
  #  ${CMAKE_CURRENT_SOURCE_DIR}/ledger.py
  #  DESTINATION "${_ledger_python_module_dir}/..")

  #file(COPY
  install(DIRECTORY
    #${PYPKG_DEST}/${Ledger_MODULE}
    ${CMAKE_CURRENT_SOURCE_DIR}/${Ledger_MODULE_EXT}
    ${CMAKE_CURRENT_SOURCE_DIR}/demo
    DESTINATION ${PYPKG_DEST})

  #install(
  #  DIRECTORY "${_ledger_python_module_dir}"
  #  DESTINATION ${PYPKG_DEST})

  install(FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/ledger.py
    DESTINATION ${Python3_SITEARCH})
  #endif()
