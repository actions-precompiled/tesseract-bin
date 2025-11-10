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


# Image library versions
set(LEPTONICA_VERSION "1.86.0")
set(ZLIB_VERSION "1.3.1")
set(JPEG_VERSION "3.1.2")
set(PNG_VERSION "1.6.44")
set(TIFF_VERSION "4.7.0")
set(WEBP_VERSION "1.4.0")

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

# ============================================================================
# Image Libraries - Build dependencies from source for self-contained binaries
# ============================================================================

# 1. zlib - Compression library (base dependency)
ExternalProject_Add(zlib
  PREFIX ${CMAKE_BINARY_DIR}/deps/zlib
  URL https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz
  CMAKE_ARGS
    ${TOOLCHAIN_ARGS}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${STAGING_DIR}
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

ExternalProject_Add(libjpeg
  PREFIX ${CMAKE_BINARY_DIR}/deps/libjpeg
  URL https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${JPEG_VERSION}/libjpeg-turbo-${JPEG_VERSION}.tar.gz
  DEPENDS zlib
  CMAKE_ARGS
    ${TOOLCHAIN_ARGS}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${STAGING_DIR}
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

# 3. libpng - PNG support
ExternalProject_Add(libpng
  PREFIX ${CMAKE_BINARY_DIR}/deps/libpng
  URL https://downloads.sourceforge.net/libpng/libpng-${PNG_VERSION}.tar.gz
  DEPENDS zlib
  CMAKE_ARGS
    ${TOOLCHAIN_ARGS}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${STAGING_DIR}
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DPNG_TESTS=ON
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

# 4. libtiff - TIFF support
ExternalProject_Add(libtiff
  PREFIX ${CMAKE_BINARY_DIR}/deps/libtiff
  URL https://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz
  DEPENDS zlib libjpeg
  CMAKE_ARGS
    ${TOOLCHAIN_ARGS}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${STAGING_DIR}
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/cmake
    -Dtiff-docs=OFF
    -Dtiff-tests=OFF
    -DBUILD_SHARED_LIBS=OFF
    -DCMAKE_C_STANDARD_LIBRARIES=-lm
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

# 5. libwebp - WebP support
ExternalProject_Add(libwebp
  PREFIX ${CMAKE_BINARY_DIR}/deps/libwebp
  URL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP_VERSION}.tar.gz
  DEPENDS zlib libjpeg libpng libtiff
  CMAKE_ARGS
    ${TOOLCHAIN_ARGS}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${STAGING_DIR}
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DWEBP_BUILD_SHARPYUV=ON
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

# ============================================================================
# Leptonica & Tesseract
# ============================================================================

ExternalProject_Add(leptonica
  PREFIX ${CMAKE_BINARY_DIR}/deps/leptonica
  GIT_REPOSITORY https://github.com/DanBloomberg/leptonica.git
  GIT_TAG ${LEPTONICA_VERSION}
  DEPENDS zlib libjpeg libpng libtiff libwebp
  UPDATE_COMMAND ""
  CMAKE_ARGS
    ${TOOLCHAIN_ARGS}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${LEPT_PREFIX}
    -DCMAKE_PREFIX_PATH=${STAGING_DIR}
    -DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/cmake
    -DBUILD_PROG=OFF
    -DSW_BUILD=OFF
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

ExternalProject_Add_Step(leptonica fix_cmake_config
    COMMAND ${CMAKE_SOURCE_DIR}/fix_leptonica_targets.sh ${STAGING_DIR}
    DEPENDEES install
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
    -DCMAKE_FIND_ROOT_PATH=${STAGING_DIR}  # Para cross-compile
    -DLEPT_TIFF_RESULT=0
  USES_TERMINAL_BUILD 1
  USES_TERMINAL_INSTALL 1
)

add_custom_target(stage-all
  DEPENDS zlib libjpeg libpng libtiff libwebp leptonica tesseract
  COMMENT "Staging all dependencies under ${STAGING_DIR}"
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
