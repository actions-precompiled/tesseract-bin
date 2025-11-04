cmake_minimum_required(VERSION 3.25)
project(tess_fullbuild LANGUAGES C CXX)
include(ExternalProject)

set(LEPT_PREFIX ${CMAKE_BINARY_DIR}/leptonica-install)
set(TESS_PREFIX ${CMAKE_BINARY_DIR}/tesseract-install)

ExternalProject_Add(leptonica
  GIT_REPOSITORY https://github.com/DanBloomberg/leptonica.git
  GIT_TAG 1.86.0
  CMAKE_ARGS -DCMAKE_BUILD_TYPE=Release
             -DCMAKE_INSTALL_PREFIX=${LEPT_PREFIX}
  LOG_BUILD ON
  LOG_OUTPUT_ON_FAILURE ON
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

ExternalProject_Add(tesseract
  GIT_REPOSITORY https://github.com/tesseract-ocr/tesseract.git
  GIT_TAG 5.5.1
  DEPENDS leptonica
  CMAKE_ARGS -DCMAKE_BUILD_TYPE=Release
             -DCMAKE_INSTALL_PREFIX=${TESS_PREFIX}
             -DLeptonica_DIR=${LEPT_PREFIX}/lib/cmake/leptonica
  LOG_BUILD ON
  LOG_OUTPUT_ON_FAILURE ON
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

add_custom_target(install-all DEPENDS leptonica-install tesseract-install)
