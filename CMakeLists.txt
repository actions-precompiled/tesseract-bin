cmake_minimum_required(VERSION 3.25)
project(tesseract-prebuilt LANGUAGES C CXX)
include(ExternalProject)

set(STAGING_DIR ${CMAKE_BINARY_DIR}/staging)
file(MAKE_DIRECTORY ${STAGING_DIR})

set(LEPT_PREFIX ${STAGING_DIR})
set(TESS_PREFIX ${STAGING_DIR})

ExternalProject_Add(leptonica
  PREFIX ${CMAKE_BINARY_DIR}/deps/leptonica         # build separado
  GIT_REPOSITORY https://github.com/DanBloomberg/leptonica.git
  GIT_TAG 1.86.0
  CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${LEPT_PREFIX}
    -DBUILD_PROG=OFF
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

ExternalProject_Add(tesseract
  PREFIX ${CMAKE_BINARY_DIR}/deps/tesseract         # build separado
  GIT_REPOSITORY https://github.com/tesseract-ocr/tesseract.git
  GIT_TAG 5.5.1
  DEPENDS leptonica
  CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${TESS_PREFIX}
    -DLeptonica_DIR=${LEPT_PREFIX}/lib/cmake/leptonica
    -DBUILD_TESTS=OFF
    -DBUILD_TRAINING_TOOLS=OFF
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

add_custom_target(stage-all
  DEPENDS leptonica-install tesseract-install
  COMMENT "Staging Leptonica and Tesseract builds under ${STAGING_DIR}"
)

# add_custom_target(package-tar
#   DEPENDS stage-all
#   COMMAND ${CMAKE_COMMAND} -E tar "cfvz"
#           ${CMAKE_BINARY_DIR}/tesseract-prebuilt.tar.gz
#           --format=gnutar
#           -C ${STAGING_DIR} .
#   COMMENT "Packing ${STAGING_DIR} into tar.gz"
# )

