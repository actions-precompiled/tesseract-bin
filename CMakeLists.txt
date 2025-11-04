cmake_minimum_required(VERSION 3.10)

project(tesseract-prebuilt)

include(FetchContent)

FetchContent_Declare(
  tesseract
  GIT_REPOSITORY "https://github.com/tesseract-ocr/tesseract.git"
  GIT_TAG "5.5.1" # TODO: parametrize version
)

FetchContent_Declare(
  leptonica
  GIT_REPOSITORY "https://github.com/DanBloomberg/leptonica.git"
  GIT_TAG "1.86.0" # TODO: parametrize version
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(tesseract leptonica)

