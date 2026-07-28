# Tesseract prebuilt binaries

Relocatable [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) builds for
Linux, published as tarballs you can unpack and use with [mise](https://mise.jdx.dev/),
asdf, or a plain `PATH` entry.

Each package includes the `tesseract` binary, bundled shared libraries, and
**tessdata** (`eng` + `osd` from [tessdata_fast](https://github.com/tesseract-ocr/tessdata_fast)
by default) so OCR works out of the box.

## Why not `buildenv`?

The generic [buildenv](https://github.com/actions-precompiled/buildenv) image is
aimed at small C/C++ cross builds. Here we want a native multi-arch Docker image,
a relocatable layout with tessdata, and the same orchestration shape as the other
actions-precompiled packages (Docker + `create_releases`, no Dagger).

## Supported targets

| Target | Builder | Notes |
|--------|---------|--------|
| `linux-amd64` | `ubuntu-latest` | Native build on Ubuntu 24.04 |
| `linux-aarch64` | `ubuntu-24.04-arm` | Native build (no QEMU) |

Windows is **in scope later**, not in this first turn.

Native builds only. GitHub’s free arm64 runners are for **public** repos; private
repos need paid arm runners or self-hosted.

## Artifact layout

```text
tesseract-5.5.3-linux-amd64.tar.gz
└── tesseract/
    ├── bin/
    │   ├── tesseract       (wrapper: lib path + TESSDATA_PREFIX)
    │   └── tesseract.bin
    ├── lib/                (bundled leptonica + image stack)
    ├── share/tessdata/     (eng.traineddata, osd.traineddata, …)
    └── BUILDINFO.txt
```

Install example:

```bash
mkdir -p ~/.local/tesseract
tar -xzf tesseract-5.5.3-linux-amd64.tar.gz -C ~/.local/tesseract --strip-components=1
export PATH="$HOME/.local/tesseract/bin:$PATH"
tesseract --version
tesseract --list-langs
```

The wrapper sets `TESSDATA_PREFIX` to the packaged `share/tessdata` unless you
already exported one (so you can drop in more languages).

## Building

### Prerequisites

- Docker
- Network (clones upstream + pulls base image + tessdata)
- GitHub CLI (`gh`) only if you use `--publish`

### Commands

```bash
# Build one version locally (default — no GitHub release)
./create_releases 5.5.3

# Auto-detect upstream releases not published here yet, still local-only
./create_releases

# See what would be built
./create_releases --dry-run
# or: DRY_RUN=1 ./create_releases

# Explicit target(s)
TARGETS=linux-amd64 ./create_releases 5.5.3
TARGETS="linux-amd64 linux-aarch64" ./create_releases 5.5.3

# Extra languages (space-separated) or full tessdata_fast tree
TESSDATA_LANGS="eng por spa" ./create_releases 5.5.3
TESSDATA_LANGS=all ./create_releases 5.5.3

# Optional: also create a GitHub Release (usually not used — prefer CI artifacts)
./create_releases --publish 5.5.3
```

`create_releases` is a uv script (`#!/usr/bin/env -S uv run --script`, stdlib deps only).
Install tools with `mise install` (see `mise.toml`). Default `TARGETS` matches the
host (`linux-amd64` or `linux-aarch64`). **Publish is off by default** so local
builds are safe.

| Flag / env | Meaning |
|------------|---------|
| `--publish` / `PUBLISH=1` | Create GitHub releases and upload tarballs |
| `--dry-run` / `DRY_RUN=1` | List versions, do not build |
| `--skip-smoke` / `SKIP_SMOKE=1` | Skip post-build smoke test |
| `--smoke-only` | Only smoke-test existing `target/` tarballs (no build) |
| `TARGETS` | Space-separated targets (default: host arch) |
| `BUILD_OUTPUT_DIR` | Output root (default `$PWD/target`) |
| `SKIP_IMAGE_BUILD` | Reuse an already-built `tesseract-buildenv:local` |
| `IMAGE_NAME` / `IMAGE_TAG` | Override image name |
| `LEPTONICA_VERSION` | Pin leptonica (default `1.85.0`) |
| `TESSDATA_LANGS` | Languages to ship (`eng osd` default; `all` = full tessdata_fast) |
| `TESSDATA_REPO` | Git URL for tessdata_fast (or compatible tree) |

Smoke tests extract the tarball and run `tesseract --version` / `--list-langs`.
CI uploads the tarball first, then runs smoke.

### What the container does

1. Clones [DanBloomberg/leptonica](https://github.com/DanBloomberg/leptonica) at the pinned tag  
2. Clones [tesseract-ocr/tesseract](https://github.com/tesseract-ocr/tesseract) at the requested tag  
3. Builds both with CMake/Ninja and installs into a staging prefix  
4. Bundles shared libraries under `lib/` and writes a relocatable `bin/tesseract` wrapper  
5. Downloads tessdata into `share/tessdata/`  
6. Emits `tesseract-<version>-linux-amd64.tar.gz` under `target/<target>/`

## CI

| Workflow | Trigger | What |
|----------|---------|------|
| `build-artifacts.yml` | **push** / PR to main | Dry-run plan + smoke-build latest for `linux-amd64` and `linux-aarch64`; upload **workflow artifacts** |
| `build-releases.yml` | **`workflow_dispatch` only** | Build one or more versions (or auto-detect missing) for both arches; upload **workflow artifacts** |

This repo does **not** create GitHub Releases. Download tarballs from the Actions run:
**Actions → select run → Artifacts**.

No schedule cron. Orchestration is `create_releases` (uv script, stdlib + `curl`/`docker`):
HTTPS via **curl** (system CA store), then it puppets `docker`.

## Versioning

Release tags track **upstream** release tags (`5.5.3`, `5.5.2`, …). The tarball
name uses the bare version (`tesseract-5.5.3-linux-amd64.tar.gz`).

## Notes / limitations

- glibc is from Ubuntu 24.04 — older distros may not run the binary.
- Image codecs still rely on libraries bundled from the builder (png/jpeg/tiff/webp/…).
- Default tessdata is **fast** models for `eng` and `osd` only; set `TESSDATA_LANGS`
  or drop more `*.traineddata` into `share/tessdata`.
- Windows packaging is deferred.

## License

Upstream tesseract is Apache-2.0. Tessdata has its own terms. This packaging glue
is provided under the same terms as other actions-precompiled repos unless noted
otherwise.
