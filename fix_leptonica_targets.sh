#!/bin/bash
set -e

STAGING_DIR="$1"
TARGETS_FILE="${STAGING_DIR}/lib/cmake/leptonica/LeptonicaTargets.cmake"

if [ ! -f "$TARGETS_FILE" ]; then
    echo "Error: $TARGETS_FILE not found"
    exit 1
fi

sed -i 's|INTERFACE_LINK_LIBRARIES ".*"|INTERFACE_LINK_LIBRARIES "'"${STAGING_DIR}"'/lib/libtiff.a;m;'"${STAGING_DIR}"'/lib/libjpeg.a;'"${STAGING_DIR}"'/lib/libwebp.a;'"${STAGING_DIR}"'/lib/libsharpyuv.a;'"${STAGING_DIR}"'/lib/libpng.a;'"${STAGING_DIR}"'/lib/libz.a;pthread"|' "$TARGETS_FILE"

echo "Fixed $TARGETS_FILE"
