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
actions-precompiled packages (Docker + `create_releases`).

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

Two workflows:

| Workflow | Trigger | What |
|----------|---------|------|
| **Build** (`build.yml`) | **push** / PR → latest tag; **`workflow_dispatch`** → one version | Arch matrix (`linux-amd64`, `linux-aarch64`); upload workflow artifacts; optional **GitHub Release** if `publish=true` |
| **Dispatch Missing** (`dispatch-missing.yml`) | **`workflow_dispatch` only** | Fan-out: `gh workflow run build.yml` **once per version** |

### Releases are mutable (re-issueable)

We do **not** rely on GitHub “Immutable releases”. Publishing is meant to be fixable:

| Mode | Behavior |
|------|----------|
| `publish=true` | Create release if missing; `gh release upload --clobber` replaces same-named assets |
| `publish=true` + `recreate=true` | `gh release delete … --yes --cleanup-tag`, then create + upload (clean re-issue) |

**Dispatch version selection** (empty `versions` input):

| `recreate` | Versions dispatched |
|------------|---------------------|
| `false` | only tags **not yet** released here |
| `true` | **every** upstream tag (rebuild/re-publish all) |

On a bad release: either re-run **Build** with `publish` + `recreate`, or run **Dispatch Missing** with `publish` + `recreate` (empty versions) to rebuild everything.

Keep **Settings → General → Immutable releases** off for this repo if you want that workflow.

### Failure isolation

- Each version is its **own workflow run**. One bad version never cancels the others.
- Inside a Build run, arches use `fail-fast: false`.
- Release (when enabled) only runs if **both** arches succeeded and both tarballs are present — no half releases.

### Typical flows

```text
# Smoke / PR / push
push → Build(latest) → artifacts only

# One version, maybe release
Actions → Build → version=5.5.3, publish=true

# Fan-out missing (safe start: cap + no publish)
Actions → Dispatch Missing → max=3, publish=false

# Fill releases for missing only
Actions → Dispatch Missing → versions empty, publish=true

# Recreate ALL upstream tags (rebuild + re-publish)
Actions → Dispatch Missing → versions empty, publish=true, recreate=true
```

Download intermediate tarballs from each Build run’s **Artifacts**. Released assets (if publish) also appear under the repo **Releases** page.

Orchestration is `create_releases` (uv script, stdlib + `curl`/`docker`/`gh`).

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
