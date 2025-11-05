# Tesseract Prebuilt Binaries

Cross-platform prebuilt binaries for Tesseract OCR, built using the [buildenv](https://github.com/actions-precompiled/buildenv) container.

## Supported Platforms

- **linux-amd64** - Linux x86_64 (native compilation)
- **linux-aarch64** - Linux ARM64 (cross-compilation)
- **windows-amd64** - Windows x86_64 (MinGW-w64 cross-compilation)

## Building Releases

### Prerequisites

- Docker
- GitHub CLI (`gh`)
- Access to push releases to this repository

### Build Script

The `create_releases` script builds Tesseract binaries for all supported platforms and publishes them as GitHub releases.

**Build specific version:**
```bash
./create_releases 5.5.1
```

**Build multiple versions:**
```bash
./create_releases 5.5.0 5.5.1 5.6.0
```

**Auto-detect versions to build:**
```bash
# Builds all versions from tesseract-ocr/tesseract that don't have releases here yet
./create_releases
```

**Dry run (see what would be built without building):**
```bash
DRY_RUN=1 ./create_releases
```

### Build Process

For each version, the script:
1. Builds Tesseract + Leptonica for all three targets using the buildenv container
2. Creates a GitHub release (if it doesn't exist)
3. Uploads the ZIP artifacts for each platform to the release

### Output Structure

Build artifacts are placed in:
```
target/
├── linux-amd64/
│   └── tesseract-5.5.1-Linux-x86_64.zip
├── linux-aarch64/
│   └── tesseract-5.5.1-Linux-aarch64.zip
└── windows-amd64/
    └── tesseract-5.5.1-Windows-AMD64.zip
```

## Configuration

### Container Version

The buildenv container version is pinned at the top of `create_releases`:

```bash
BUILDENV_VERSION=0.0.1
```

To use a newer version, update this constant.

### Leptonica Version

Leptonica version is configured in `CMakeLists.txt`:

```cmake
set(LEPTONICA_VERSION "1.86.0")
```

## How It Works

1. **Cross-Compilation Container**: Uses `ghcr.io/actions-precompiled/buildenv` which includes:
   - GCC toolchains for all platforms
   - CMake toolchain files for cross-compilation
   - All necessary build dependencies

2. **CMake Build**: The `CMakeLists.txt` uses `ExternalProject_Add` to:
   - Clone and build Leptonica
   - Clone and build Tesseract (depends on Leptonica)
   - Package everything into a ZIP file

3. **Toolchain Propagation**: The toolchain file is automatically passed to all ExternalProject builds, ensuring Leptonica and Tesseract are built for the correct target platform.

## CMake Details

The project automatically detects the target platform from the toolchain:
- `CMAKE_SYSTEM_NAME` - e.g., "Linux" or "Windows"
- `CMAKE_SYSTEM_PROCESSOR` - e.g., "x86_64", "aarch64", or "AMD64"

Output naming follows the pattern:
```
tesseract-{VERSION}-{SYSTEM_NAME}-{PROCESSOR}.zip
```
