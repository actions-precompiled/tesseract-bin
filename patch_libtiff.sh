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

    # Disable JPEG 12-bit support (rarely used for OCR, simplifies build)
    if grep -q "JPEG12_FOUND" "$MAIN_CMAKE"; then
        sed -i 's/if(JPEG12_FOUND)/if(FALSE) # JPEG12_FOUND/g' "$MAIN_CMAKE"
        echo "✓ Disabled JPEG 12-bit support"
    fi
fi

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
