cmake_minimum_required(VERSION 3.16)
project(tesseract-prebuilt)
include(FetchContent)

set(BUILD_PROG OFF CACHE BOOL "No tools")
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Static")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

FetchContent_Declare(
  leptonica
  GIT_REPOSITORY https://github.com/DanBloomberg/leptonica.git
  GIT_TAG 1.86.0
)
FetchContent_MakeAvailable(leptonica)

# força instalação local do leptonica
install(TARGETS leptonica DESTINATION lib)
install(DIRECTORY ${leptonica_SOURCE_DIR}/src/ DESTINATION include FILES_MATCHING PATTERN "*.h")

set(Leptonica_DIR "${leptonica_BINARY_DIR}")
set(Leptonica_INCLUDE_DIRS "${leptonica_BINARY_DIR}/src" "${leptonica_SOURCE_DIR}/src")
set(Leptonica_LIBRARIES leptonica)

FetchContent_Declare(
  tesseract
  GIT_REPOSITORY https://github.com/tesseract-ocr/tesseract.git
  GIT_TAG 5.5.1
)
FetchContent_MakeAvailable(tesseract)

# força CMake do tesseract a usar o leptonica buildado
set_target_properties(tesseract PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${Leptonica_INCLUDE_DIRS}"
)

