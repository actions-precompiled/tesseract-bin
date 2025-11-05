# This file is injected into Tesseract's CMake via CMAKE_PROJECT_tesseract_INCLUDE
# It creates alias targets that Leptonica's config expects

message(STATUS "Creating alias targets for Leptonica dependencies...")

# Create ZLIB::ZLIB alias
if(NOT TARGET ZLIB::ZLIB)
    add_library(ZLIB::ZLIB UNKNOWN IMPORTED)
    set_target_properties(ZLIB::ZLIB PROPERTIES
        IMPORTED_LOCATION "${CMAKE_PREFIX_PATH}/lib/libz.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_PREFIX_PATH}/include"
    )
    message(STATUS "  Created ZLIB::ZLIB -> ${CMAKE_PREFIX_PATH}/lib/libz.a")
endif()

# Create JPEG::JPEG alias
if(NOT TARGET JPEG::JPEG)
    add_library(JPEG::JPEG UNKNOWN IMPORTED)
    set_target_properties(JPEG::JPEG PROPERTIES
        IMPORTED_LOCATION "${CMAKE_PREFIX_PATH}/lib/libjpeg.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_PREFIX_PATH}/include"
    )
    message(STATUS "  Created JPEG::JPEG -> ${CMAKE_PREFIX_PATH}/lib/libjpeg.a")
endif()

# Create PNG::PNG alias
if(NOT TARGET PNG::PNG)
    add_library(PNG::PNG UNKNOWN IMPORTED)
    set_target_properties(PNG::PNG PROPERTIES
        IMPORTED_LOCATION "${CMAKE_PREFIX_PATH}/lib/libpng.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_PREFIX_PATH}/include"
        INTERFACE_LINK_LIBRARIES ZLIB::ZLIB
    )
    message(STATUS "  Created PNG::PNG -> ${CMAKE_PREFIX_PATH}/lib/libpng.a")
endif()

# Create TIFF::TIFF alias
if(NOT TARGET TIFF::TIFF)
    add_library(TIFF::TIFF UNKNOWN IMPORTED)
    set_target_properties(TIFF::TIFF PROPERTIES
        IMPORTED_LOCATION "${CMAKE_PREFIX_PATH}/lib/libtiff.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_PREFIX_PATH}/include"
    )
    message(STATUS "  Created TIFF::TIFF -> ${CMAKE_PREFIX_PATH}/lib/libtiff.a")
endif()

# Create WebP targets
if(NOT TARGET webp)
    add_library(webp UNKNOWN IMPORTED)
    set_target_properties(webp PROPERTIES
        IMPORTED_LOCATION "${CMAKE_PREFIX_PATH}/lib/libwebp.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_PREFIX_PATH}/include"
    )
    message(STATUS "  Created webp -> ${CMAKE_PREFIX_PATH}/lib/libwebp.a")
endif()

# Create WebP::webp alias (with namespace)
if(NOT TARGET WebP::webp)
    add_library(WebP::webp ALIAS webp)
    message(STATUS "  Created WebP::webp alias")
endif()

if(NOT TARGET webpdecoder)
    add_library(webpdecoder UNKNOWN IMPORTED)
    set_target_properties(webpdecoder PROPERTIES
        IMPORTED_LOCATION "${CMAKE_PREFIX_PATH}/lib/libwebpdecoder.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_PREFIX_PATH}/include"
    )
endif()

if(NOT TARGET webpdemux)
    add_library(webpdemux UNKNOWN IMPORTED)
    set_target_properties(webpdemux PROPERTIES
        IMPORTED_LOCATION "${CMAKE_PREFIX_PATH}/lib/libwebpdemux.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_PREFIX_PATH}/include"
    )
endif()

if(NOT TARGET webpmux)
    add_library(webpmux UNKNOWN IMPORTED)
    set_target_properties(webpmux PROPERTIES
        IMPORTED_LOCATION "${CMAKE_PREFIX_PATH}/lib/libwebpmux.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_PREFIX_PATH}/include"
    )
endif()

message(STATUS "Alias targets created successfully!")
