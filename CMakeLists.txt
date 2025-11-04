cmake_minimum_required(VERSION 3.10)

project(tesseract-prebuilt)

include(FetchContent)

FetchContent_Declare(
  leptonica
  GIT_REPOSITORY "https://github.com/DanBloomberg/leptonica.git"
  GIT_TAG "1.86.0" # TODO: parametrize version
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(leptonica)

FetchContent_GetProperties(leptonica)
if(NOT leptonica_POPULATED)
  FetchContent_Populate(leptonica)
  add_subdirectory(${leptonica_SOURCE_DIR} ${leptonica_BINARY_DIR})
endif()

# definir manualmente antes de tesseract procurar
set(Leptonica_INCLUDE_DIRS ${leptonica_SOURCE_DIR}/src)
set(Leptonica_LIBRARIES leptonica)

FetchContent_Declare(
  tesseract
  GIT_REPOSITORY "https://github.com/tesseract-ocr/tesseract.git"
  GIT_TAG "5.5.1" # TODO: parametrize version
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(tesseract)

