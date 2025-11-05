cmake_minimum_required(VERSION 3.25)
project(tesseract-prebuilt LANGUAGES C CXX)
include(ExternalProject)

# set(TESSERACT_VERSION "5.5.1")
# Accept TESSERACT_VERSION from environment variable or CMake -D flag
if(NOT DEFINED TESSERACT_VERSION)
  if(DEFINED ENV{TESSERACT_VERSION})
    set(TESSERACT_VERSION $ENV{TESSERACT_VERSION})
    message(STATUS "Using TESSERACT_VERSION from environment: ${TESSERACT_VERSION}")
  else()
    message(FATAL_ERROR "TESSERACT_VERSION must be defined via -DTESSERACT_VERSION=... or environment variable")
  endif()
endif()

set(LEPTONICA_VERSION "1.86.0")

set(TARGET_NAME "tesseract-${TESSERACT_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Target: ${TARGET_NAME}")
message(STATUS "System: ${CMAKE_SYSTEM_NAME}")
message(STATUS "Processor: ${CMAKE_SYSTEM_PROCESSOR}")

set(STAGING_DIR ${CMAKE_BINARY_DIR}/staging/${TARGET_NAME})
file(MAKE_DIRECTORY ${STAGING_DIR})

set(LEPT_PREFIX ${STAGING_DIR})
set(TESS_PREFIX ${STAGING_DIR})

# Prepare toolchain arguments for ExternalProject
set(TOOLCHAIN_ARGS "")
if(CMAKE_TOOLCHAIN_FILE)
  list(APPEND TOOLCHAIN_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
  )
  message(STATUS "Using toolchain: ${CMAKE_TOOLCHAIN_FILE}")
endif()

ExternalProject_Add(leptonica
  PREFIX ${CMAKE_BINARY_DIR}/deps/leptonica         # Separate build directory
  GIT_REPOSITORY https://github.com/DanBloomberg/leptonica.git
  GIT_TAG ${LEPTONICA_VERSION}
  CMAKE_ARGS
    ${TOOLCHAIN_ARGS}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${LEPT_PREFIX}
    -DBUILD_PROG=OFF
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

ExternalProject_Add(tesseract
  PREFIX ${CMAKE_BINARY_DIR}/deps/tesseract         # Separate build directory
  GIT_REPOSITORY https://github.com/tesseract-ocr/tesseract.git
  GIT_TAG ${TESSERACT_VERSION}
  DEPENDS leptonica
  CMAKE_ARGS
    ${TOOLCHAIN_ARGS}
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
  WORKING_DIRECTORY ${STAGING_DIR}/..
  COMMENT "Packing ${STAGING_DIR} into zip"
)
