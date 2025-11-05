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

**Local build (build without creating releases or uploading):**
```bash
LOCAL_BUILD=1 ./create_releases 5.5.1
```

### Build Process

For each version, the script:
1. Builds Tesseract + Leptonica for all three targets using the buildenv container
2. Creates a GitHub release (if it doesn't exist)
3. Uploads the ZIP artifacts for each platform to the release

### Output Structure

Build artifacts are placed in `target/` by default (or `$BUILD_OUTPUT_DIR` if set):
```
target/
├── linux-amd64/
│   └── tesseract-5.5.1-Linux-x86_64.zip
├── linux-aarch64/
│   └── tesseract-5.5.1-Linux-aarch64.zip
└── windows-amd64/
    └── tesseract-5.5.1-Windows-AMD64.zip
```

**Note:** The script automatically creates target directories before running Docker to avoid permission issues with mount points.

## Continuous Integration

### PR Build Testing

A GitHub Actions workflow runs on every pull request to validate that builds work correctly:

- **Workflow**: `.github/workflows/pr-build-test.yml`
- **Trigger**: Pull requests to main/master
- **Action**: Builds the latest Tesseract version for all three targets
- **Artifacts**: Uploads build outputs as workflow artifacts (not as releases)

The workflow uses `LOCAL_BUILD=1` to skip release creation and upload, ensuring PR builds don't pollute the releases.

### Automated Release Publishing

A scheduled workflow automatically builds and publishes new Tesseract releases:

- **Workflow**: `.github/workflows/build-releases.yml`
- **Triggers**:
  - **Schedule**: Every Saturday at 2:00 AM UTC (automatic)
  - **Manual**: Via workflow_dispatch in GitHub Actions UI
- **Action**:
  - Detects new Tesseract versions from upstream (tesseract-ocr/tesseract)
  - Builds missing versions for all three targets
  - Creates GitHub releases with the compiled artifacts
- **Permissions**: Requires `contents: write` to create releases and upload assets

This workflow runs the `create_releases` script without `LOCAL_BUILD`, so it creates actual releases and uploads artifacts to GitHub.

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

### Environment Variables

The `create_releases` script supports the following environment variables:

- **`DRY_RUN`**: If set, lists versions that would be built without actually building
- **`LOCAL_BUILD`**: If set, builds locally without creating GitHub releases or uploading artifacts
  - Useful for testing builds locally
  - Used automatically by the PR build workflow
- **`BUILD_OUTPUT_DIR`**: Override the build output directory (default: `$PWD/target`)
  - Useful when working with mount points that have permission restrictions
  - Example: `BUILD_OUTPUT_DIR=/tmp/tesseract-builds ./create_releases 5.5.1`

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
