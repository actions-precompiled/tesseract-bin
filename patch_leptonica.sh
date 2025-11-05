#!/bin/bash
set -ex

SOURCE_DIR="$1"

echo "========================================="
echo "Leptonica Patch Script"
echo "========================================="
echo "Patching Leptonica to use static linking without exported targets"
echo "========================================="

# Patch src/CMakeLists.txt to link libraries privately (not as INTERFACE)
# This prevents exporting ZLIB::ZLIB and other imported targets
SRC_CMAKE="$SOURCE_DIR/src/CMakeLists.txt"

if [ -f "$SRC_CMAKE" ]; then
    echo "Patching src/CMakeLists.txt..."

    # Change all target_link_libraries to use PRIVATE instead of PUBLIC/INTERFACE
    # This prevents exporting the dependencies to consumers
    sed -i 's/target_link_libraries(leptonica /target_link_libraries(leptonica PRIVATE /g' "$SRC_CMAKE"

    echo "✓ Changed target_link_libraries to use PRIVATE linkage"
fi

# Patch cmake/Configure.cmake to not export dependencies
CONFIGURE_CMAKE="$SOURCE_DIR/cmake/Configure.cmake"
if [ -f "$CONFIGURE_CMAKE" ]; then
    echo "Patching cmake/Configure.cmake..."

    # Comment out the entire INTERFACE_LINK_LIBRARIES block
    # This prevents consumers from needing to find ZLIB::ZLIB, WebP::webp, etc.
    sed -i '/set_property.*INTERFACE_LINK_LIBRARIES/,/)/s/^/#/' "$CONFIGURE_CMAKE"

    # Also remove any INTERFACE_LINK_LIBRARIES property setting
    sed -i '/INTERFACE_LINK_LIBRARIES/d' "$CONFIGURE_CMAKE"

    echo "✓ Removed INTERFACE_LINK_LIBRARIES export"
fi

# Patch the installed config file template if it exists
CONFIG_IN="$SOURCE_DIR/cmake/templates/LeptonicaConfig.cmake.in"
if [ -f "$CONFIG_IN" ]; then
    echo "Patching LeptonicaConfig.cmake.in..."

    # Remove INTERFACE_LINK_LIBRARIES from the template
    sed -i '/INTERFACE_LINK_LIBRARIES/d' "$CONFIG_IN"

    echo "✓ Removed INTERFACE_LINK_LIBRARIES from config template"
fi

echo "========================================="
echo "Leptonica patch completed!"
echo "========================================="
