# Missing Image Libraries in buildenv

## Issue

When building Tesseract using the `actions-precompiled/buildenv` container, Leptonica builds without support for common image formats:

```
Could NOT find PkgConfig (missing: PKG_CONFIG_EXECUTABLE)
Found leptonica version: 1.86.0
Leptonica was build without TIFF support! Disabling TIFF support...
-- TIFF support disabled.
```

This happens because the buildenv container lacks image library development packages.

## Root Cause

The buildenv Dockerfile only includes compiler toolchains and basic build tools, but not image libraries:

```dockerfile
RUN apt update && apt install -y \
  build-essential \
  cmake \
  ninja-build \
  git \
  crossbuild-essential-arm64 \
  g++-mingw-w64-x86-64 \
  # ... no image libraries
```

## Required Libraries

Tesseract/Leptonica need these libraries for full functionality:

| Package | Purpose | Priority |
|---------|---------|----------|
| `libtiff-dev` | TIFF image format | **Critical** |
| `libjpeg-dev` | JPEG image format | **Critical** |
| `libpng-dev` | PNG image format | **Critical** |
| `libwebp-dev` | WebP image format | Recommended |
| `libopenjp2-7-dev` | JPEG 2000 format | Optional |
| `zlib1g-dev` | Compression support | **Critical** |
| `pkg-config` | Library detection | **Critical** |

## Proposed Solution

Add image libraries to buildenv Dockerfile:

```dockerfile
RUN apt update && apt install -y \
  build-essential \
  cmake \
  ninja-build \
  git \
  pkg-config \
  crossbuild-essential-arm64 \
  g++-mingw-w64-x86-64 \
  gcc-mingw-w64-x86-64 \
  g++-mingw-w64-i686 \
  gcc-mingw-w64-i686 \
  # Image libraries (native)
  libtiff-dev \
  libjpeg-dev \
  libpng-dev \
  libwebp-dev \
  libopenjp2-7-dev \
  zlib1g-dev \
  # Image libraries (ARM64 cross-compile)
  libtiff-dev:arm64 \
  libjpeg-dev:arm64 \
  libpng-dev:arm64 \
  libwebp-dev:arm64 \
  libopenjp2-7-dev:arm64 \
  zlib1g-dev:arm64 \
  && rm -rf /var/lib/apt/lists/*
```

## Cross-Compilation Considerations

For ARM64 cross-compilation to work, we need **both**:
1. Native libraries (for build tools)
2. ARM64 libraries (for linking)

This requires enabling multi-arch:

```dockerfile
# Enable ARM64 architecture
RUN dpkg --add-architecture arm64

# Then install both native and :arm64 versions
RUN apt update && apt install -y \
  libtiff-dev \
  libtiff-dev:arm64 \
  ...
```

For Windows cross-compilation (MinGW), we might need Windows-compatible libraries, which is more complex.

## Temporary Workaround

Until buildenv is updated, users can:

1. Build a custom buildenv image
2. Accept limited image format support
3. Use system-installed Tesseract instead of prebuilt binaries

## References

- Leptonica dependencies: http://www.leptonica.org/source/README.html
- Tesseract dependencies: https://tesseract-ocr.github.io/tessdoc/Compiling.html
- Issue: actions-precompiled/buildenv#[TBD]
