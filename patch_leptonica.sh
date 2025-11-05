#!/bin/bash
set -ex

SOURCE_DIR="$1"
TARGET_FILE="$SOURCE_DIR/src/CMakeLists.txt"

echo "========================================="
echo "Leptonica Patch Script"
echo "========================================="
echo "SOURCE_DIR: $SOURCE_DIR"
echo "TARGET_FILE: $TARGET_FILE"
echo "========================================="

# Check if file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "ERROR: Target file not found: $TARGET_FILE"
    exit 1
fi

# Show before patch
echo "BEFORE PATCH:"
grep -n "CMath" "$TARGET_FILE" || echo "No CMath found (this is OK if already patched)"

# Apply patch
echo "Applying patch..."
sed -i 's/CMath::CMath/m/g' "$TARGET_FILE"

# Show after patch
echo "AFTER PATCH:"
grep -n "CMath" "$TARGET_FILE" || echo "No CMath found (patch successful!)"

# Verify patch worked
if grep -q "CMath::CMath" "$TARGET_FILE"; then
    echo "ERROR: Patch failed - CMath::CMath still present!"
    exit 1
fi

echo "========================================="
echo "Patch completed successfully!"
echo "========================================="
