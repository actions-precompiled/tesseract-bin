cmake_minimum_required(VERSION 3.25)
project(tesseract-prebuilt LANGUAGES C CXX)
include(FetchContent)
include(ExternalProject)

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

set(CMAKE_PREFIX_PATH ${STAGING_DIR} ${CMAKE_PREFIX_PATH})
set(ZLIB_LIBRARY "${STAGING_DIR}/lib/libzlibstatic.a")
set(ZLIB_INCLUDE_DIR "${STAGING_DIR}/include")
set(Leptonica_DIR "${STAGING_DIR}")

set(TARGET_NAME "tesseract-${TESSERACT_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Target: ${TARGET_NAME}")
message(STATUS "System: ${CMAKE_SYSTEM_NAME}")
message(STATUS "Processor: ${CMAKE_SYSTEM_PROCESSOR}")

# Global settings
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libraries" FORCE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_BUILD_TYPE Release)
set(FETCHCONTENT_QUIET OFF)

# Add CMath module
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Install prefix
set(STAGING_DIR "${CMAKE_BINARY_DIR}/staging/${TARGET_NAME}")
set(CMAKE_INSTALL_PREFIX ${STAGING_DIR})

# ============================================================================
# Image Libraries
# ============================================================================

# 1. zlib
FetchContent_Declare(zlib
  URL https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz
)

# 2. libjpeg-turbo
# libjpeg como ExternalProject
ExternalProject_Add(libjpeg
  DEPENDENCIES zlib
  PREFIX ${CMAKE_BINARY_DIR}/deps/libjpeg
  URL https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${JPEG_VERSION}/libjpeg-turbo-${JPEG_VERSION}.tar.gz
  CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX=${STAGING_DIR}
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=OFF
    -DZLIB_LIBRARY=${STAGING_DIR}/lib/libzlibstatic.a
    -DZLIB_INCLUDE_DIR=${STAGING_DIR}/include
)

# 3. libpng
set(PNG_TESTS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(libpng
  URL https://downloads.sourceforge.net/libpng/libpng-${PNG_VERSION}.tar.gz
)

# 4. libtiff
set(tiff-docs OFF CACHE BOOL "" FORCE)
set(tiff-tests OFF CACHE BOOL "" FORCE)
FetchContent_Declare(libtiff
  URL https://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz
)

# 5. libwebp
set(WEBP_BUILD_SHARPYUV ON CACHE BOOL "" FORCE)
FetchContent_Declare(libwebp
  URL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP_VERSION}.tar.gz
)

# 6. leptonica
set(BUILD_PROG OFF CACHE BOOL "" FORCE)
set(SW_BUILD OFF CACHE BOOL "" FORCE)
FetchContent_Declare(leptonica
  URL https://github.com/DanBloomberg/leptonica/archive/refs/tags/${LEPTONICA_VERSION}.tar.gz
)

# 7. tesseract
set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(BUILD_TRAINING_TOOLS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(tesseract
  URL https://github.com/tesseract-ocr/tesseract/archive/refs/tags/${TESSERACT_VERSION}.tar.gz
)

# Download and make available
FetchContent_MakeAvailable(zlib libpng libtiff libwebp leptonica tesseract)

# ============================================================================
# Installation
# ============================================================================

install(TARGETS tesseract DESTINATION bin)
install(DIRECTORY ${CMAKE_BINARY_DIR}/_deps/tesseract-src/tessdata 
        DESTINATION share/tessdata
        OPTIONAL)

# Package target
add_custom_target(package-zip
  COMMAND ${CMAKE_COMMAND} --install ${CMAKE_BINARY_DIR} --prefix ${STAGING_DIR}
  COMMAND ${CMAKE_COMMAND} -E tar "cfv" ${CMAKE_BINARY_DIR}/${TARGET_NAME}.zip --format=zip ${STAGING_DIR}
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  COMMENT "Packing ${STAGING_DIR} into zip"
)
