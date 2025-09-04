file(READ ${PROJECT_SOURCE_DIR}/LICENSE.md Ledger_LICENSE)

configure_file(
  ${PROJECT_SOURCE_DIR}/python/lpy/__init__.py.in
  ${PROJECT_BINARY_DIR}/lpy/__init__.py)

file(COPY
  ${PROJECT_SOURCE_DIR}/python/lpy/core/__init__.py
  DESTINATION ${PROJECT_BINARY_DIR}/lpy/core)

install(DIRECTORY
  "${PROJECT_BINARY_DIR}/lpy"
  DESTINATION ${PYPKG_DEST})

#if (NOT SKBUILD_PLATLIB_DIR)
#  set(SKBUILD_PLATLIB_DIR ${PYPKG_DEST})
#endif()
#install(FILES
#${PROJECT_BINARY_DIR}/lpy/__init__.py
#DESTINATION ${SKBUILD_PLATLIB_DIR}/lpy)
#install(FILES
#${PROJECT_SOURCE_DIR}/python/lpy/core/__init__.py
#DESTINATION ${SKBUILD_PLATLIB_DIR}/lpy/core)
#install(FILES
#${PROJECT_SOURCE_DIR}/python/ledger.py
#DESTINATION ${SKBUILD_PLATLIB_DIR})

#if (NOT SKBUILD)
#set(_ledger_python_module_dir ${PROJECT_BINARY_DIR})

  #file(COPY
  #  ${CMAKE_CURRENT_SOURCE_DIR}/ledger.py
  #  DESTINATION "${_ledger_python_module_dir}/..")

  #file(COPY
 #install(DIRECTORY
 #  #${PYPKG_DEST}/${Ledger_MODULE}
 #  ${CMAKE_CURRENT_SOURCE_DIR}/${Ledger_MODULE_EXT}
 #  #${CMAKE_CURRENT_SOURCE_DIR}/demo
 #  DESTINATION ${PYPKG_DEST})

  #install(
  #  DIRECTORY "${_ledger_python_module_dir}"
  #  DESTINATION ${PYPKG_DEST})

  #endif()
