#!/bin/bash
set -e

SOURCE_DIR="$1"
echo "Patching Leptonica in: $SOURCE_DIR"

# Replace CMath::CMath with m (math library)
if grep -q "CMath::CMath" "$SOURCE_DIR/src/CMakeLists.txt"; then
    echo "Applying CMath::CMath -> m patch..."
    sed -i 's/CMath::CMath/m/g' "$SOURCE_DIR/src/CMakeLists.txt"
    echo "Patch applied successfully"
else
    echo "Patch already applied or not needed"
fi
