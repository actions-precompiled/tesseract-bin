cmake_minimum_required(VERSION 3.25)

# Accept TESSERACT_VERSION from environment variable or CMake -D flag
if(NOT DEFINED TESSERACT_VERSION)
  if(DEFINED ENV{TESSERACT_VERSION})
    set(TESSERACT_VERSION $ENV{TESSERACT_VERSION})
    message(STATUS "Using TESSERACT_VERSION from environment: ${TESSERACT_VERSION}")
  else()
    message(FATAL_ERROR "TESSERACT_VERSION must be defined via -DTESSERACT_VERSION=... or environment variable")
  endif()
endif()


# Baixa vcpkg
include(FetchContent)
FetchContent_Declare(vcpkg
  GIT_REPOSITORY https://github.com/microsoft/vcpkg.git
  GIT_TAG master
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(vcpkg)

# Bootstrap vcpkg se necessário
if(NOT EXISTS ${vcpkg_SOURCE_DIR}/vcpkg)
  message(STATUS "Bootstrapping vcpkg...")
  execute_process(
    COMMAND ${vcpkg_SOURCE_DIR}/bootstrap-vcpkg.sh -disableMetrics
    WORKING_DIRECTORY ${vcpkg_SOURCE_DIR}
  )
endif()

set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE ${CMAKE_TOOLCHAIN_FILE})
set(CMAKE_TOOLCHAIN_FILE ${vcpkg_SOURCE_DIR}/scripts/buildsystems/vcpkg.cmake CACHE STRING "" FORCE)

project(tesseract-prebuilt LANGUAGES C CXX)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(VCPKG_TARGET_TRIPLET "x64-mingw-static")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    set(VCPKG_TARGET_TRIPLET "x64-linux-release")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    set(VCPKG_TARGET_TRIPLET "arm64-linux-release")
  endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64")
    set(VCPKG_TARGET_TRIPLET "arm64-osx-release")
  else()
    set(VCPKG_TARGET_TRIPLET "x64-osx-release")
  endif()
endif()

message(STATUS "VCPKG_TARGET_TRIPLET: ${VCPKG_TARGET_TRIPLET}")

set(TARGET_NAME "tesseract-${TESSERACT_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
set(STAGING_DIR "${CMAKE_BINARY_DIR}/staging/${TARGET_NAME}")

message(STATUS "Target: ${TARGET_NAME}")
message(STATUS "Installing to: ${STAGING_DIR}")

# Instala tesseract via vcpkg
message(STATUS "Installing tesseract via vcpkg...")
execute_process(
  COMMAND
    ${vcpkg_SOURCE_DIR}/vcpkg
    install
    tesseract:${VCPKG_TARGET_TRIPLET}
    --debug
    --clean-after-build
  WORKING_DIRECTORY ${vcpkg_SOURCE_DIR}
  RESULT_VARIABLE VCPKG_RESULT
  COMMAND_ECHO STDERR
)

if(NOT VCPKG_RESULT EQUAL 0)
  message(FATAL_ERROR "vcpkg install failed")
endif()

# Encontra tesseract instalado
find_package(Tesseract CONFIG REQUIRED)
find_program(TESSERACT_EXE tesseract REQUIRED)

# Copia binários e dependências para staging
file(MAKE_DIRECTORY ${STAGING_DIR}/bin)
file(COPY ${TESSERACT_EXE} DESTINATION ${STAGING_DIR}/bin)

# Copia tessdata se existir
set(VCPKG_INSTALLED ${vcpkg_SOURCE_DIR}/installed/${VCPKG_TARGET_TRIPLET})
if(EXISTS ${VCPKG_INSTALLED}/share/tessdata)
  file(COPY ${VCPKG_INSTALLED}/share/tessdata DESTINATION ${STAGING_DIR}/share)
endif()

# Target para empacotar
add_custom_target(package-zip ALL
  COMMAND ${CMAKE_COMMAND} -E tar cfv ${CMAKE_BINARY_DIR}/${TARGET_NAME}.zip --format=zip .
  WORKING_DIRECTORY ${STAGING_DIR}
  COMMENT "Creating ${TARGET_NAME}.zip"
)

message(STATUS "Build complete. Run 'cmake --build . --target package-zip' to create zip")
