cmake_minimum_required(VERSION 3.25)
project(tesseract-prebuilt LANGUAGES C CXX)
include(ExternalProject)

set(TESSERACT_VERSION "5.5.1")
set(LEPTONICA_VERSION "1.86.0")

set(TARGET_NAME "tesseract-${TESSERACT_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Target: ${TARGET_NAME}")

set(STAGING_DIR ${CMAKE_BINARY_DIR}/staging/${TARGET_NAME})
file(MAKE_DIRECTORY ${STAGING_DIR})

set(LEPT_PREFIX ${STAGING_DIR})
set(TESS_PREFIX ${STAGING_DIR})

ExternalProject_Add(leptonica
  PREFIX ${CMAKE_BINARY_DIR}/deps/leptonica         # build separado
  GIT_REPOSITORY https://github.com/DanBloomberg/leptonica.git
  GIT_TAG ${LEPTONICA_VERSION}
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
  GIT_TAG ${TESSERACT_VERSION}
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
  DEPENDS leptonica tesseract
  COMMENT "Staging Leptonica and Tesseract builds under ${STAGING_DIR}"
)

add_custom_target(package-zip
  DEPENDS stage-all
  COMMAND ${CMAKE_COMMAND} -E tar "cfv"
          ${CMAKE_BINARY_DIR}/${TARGET_NAME}.zip
          --format=zip
          ${STAGING_DIR}
  COMMENT "Packing ${STAGING_DIR} into zip"
)
