#!/bin/bash
set -ex

SOURCE_DIR="$1"

echo "========================================="
echo "libtiff Patch Script"
echo "========================================="
echo "SOURCE_DIR: $SOURCE_DIR"
echo "========================================="

# Patch main CMakeLists.txt to use find_library instead of find_package(CMath)
MAIN_CMAKE="$SOURCE_DIR/CMakeLists.txt"
if [ -f "$MAIN_CMAKE" ]; then
    echo "Patching main CMakeLists.txt..."

    # Replace find_package(CMath REQUIRED) with find_library
    if grep -q "find_package(CMath" "$MAIN_CMAKE"; then
        sed -i 's/find_package(CMath REQUIRED)/find_library(MATH_LIBRARY m)/g' "$MAIN_CMAKE"
        echo "✓ Replaced find_package(CMath) with find_library"
    fi
fi

# Delete JPEG 12-bit source files and remove from CMakeLists.txt
# The -Djpeg12=OFF flag doesn't seem to work properly in some versions
echo "Removing JPEG 12-bit support..."

# Remove source files
find "$SOURCE_DIR" -name "tif_jpeg_12.c" -delete
find "$SOURCE_DIR" -name "*jpeg_12*" -type f -delete

# Remove references from libtiff/CMakeLists.txt
LIBTIFF_CMAKE="$SOURCE_DIR/libtiff/CMakeLists.txt"
if [ -f "$LIBTIFF_CMAKE" ]; then
    echo "Patching libtiff/CMakeLists.txt to remove tif_jpeg_12.c reference..."
    sed -i '/tif_jpeg_12\.c/d' "$LIBTIFF_CMAKE"
    echo "✓ Removed tif_jpeg_12.c from CMakeLists.txt"
fi

# Remove calls to _12 functions from tif_jpeg.c
TIF_JPEG_C="$SOURCE_DIR/libtiff/tif_jpeg.c"
if [ -f "$TIF_JPEG_C" ]; then
    echo "Patching tif_jpeg.c to remove dual-mode function calls..."
    # Comment out TIFFReInitJPEG_12 calls
    sed -i 's/TIFFReInitJPEG_12/\/\/ TIFFReInitJPEG_12/g' "$TIF_JPEG_C"
    # Comment out TIFFJPEGIsFullStripRequired_12 calls
    sed -i 's/TIFFJPEGIsFullStripRequired_12/\/\/ TIFFJPEGIsFullStripRequired_12/g' "$TIF_JPEG_C"
    echo "✓ Commented out dual-mode function calls in tif_jpeg.c"
fi

echo "✓ Removed all JPEG 12-bit related files"


# Patch all CMakeLists.txt files that link to CMath::CMath
echo "Patching target_link_libraries calls..."
find "$SOURCE_DIR" -name "CMakeLists.txt" -type f | while read -r cmake_file; do
    if grep -q "CMath::CMath" "$cmake_file"; then
        echo "  Patching: $cmake_file"
        # Replace CMath::CMath with ${MATH_LIBRARY}
        sed -i 's/CMath::CMath/${MATH_LIBRARY}/g' "$cmake_file"
    fi
done

echo "========================================="
echo "libtiff patch completed!"
echo "========================================="
