#!/bin/bash
set -ex

LEPT_PREFIX="$1"
STAGING_DIR="$2"

echo "========================================="
echo "Leptonica Config Patch Script"
echo "========================================="
echo "Patching installed LeptonicaTargets.cmake to use absolute library paths"
echo "========================================="

CONFIG_FILE="${LEPT_PREFIX}/lib/cmake/leptonica/LeptonicaTargets.cmake"

if [ -f "$CONFIG_FILE" ]; then
    echo "Found config file: $CONFIG_FILE"

    # Build the replacement string with absolute paths
    LIBS="${STAGING_DIR}/lib/libpng.a;${STAGING_DIR}/lib/libjpeg.a;${STAGING_DIR}/lib/libtiff.a;${STAGING_DIR}/lib/libwebp.a;${STAGING_DIR}/lib/libsharpyuv.a;${STAGING_DIR}/lib/libz.a;m"

    # Replace INTERFACE_LINK_LIBRARIES with absolute paths
    sed -i "s|INTERFACE_LINK_LIBRARIES \"[^\"]*\"|INTERFACE_LINK_LIBRARIES \"${LIBS}\"|g" "$CONFIG_FILE"

    echo "✓ Replaced INTERFACE_LINK_LIBRARIES with absolute paths"
    echo "  Libraries: $LIBS"
else
    echo "Warning: Config file not found: $CONFIG_FILE"
fi

echo "========================================="
echo "Leptonica config patch completed!"
echo "========================================="
