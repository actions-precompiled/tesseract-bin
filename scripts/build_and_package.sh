#!/usr/bin/env bash
# Build tesseract from upstream and produce a relocatable tarball with tessdata.
set -euo pipefail

TESSERACT_VERSION="${TESSERACT_VERSION:?TESSERACT_VERSION is required}"
BUILD_TARGET="${BUILD_TARGET:-linux-amd64}"
OUTPUT_DIR="${OUTPUT_DIR:-/out}"
LEPTONICA_VERSION="${LEPTONICA_VERSION:-1.85.0}"
UPSTREAM_REPO="${UPSTREAM_REPO:-https://github.com/tesseract-ocr/tesseract.git}"
LEPTONICA_REPO="${LEPTONICA_REPO:-https://github.com/DanBloomberg/leptonica.git}"
TESSDATA_REPO="${TESSDATA_REPO:-https://github.com/tesseract-ocr/tessdata_fast.git}"
# Space-separated language codes; "all" clones the full tessdata_fast tree.
TESSDATA_LANGS="${TESSDATA_LANGS:-eng osd}"
JOBS="${JOBS:-$(nproc)}"
KEEP_SYMBOLS="${KEEP_SYMBOLS:-0}"

RAW_VERSION="${TESSERACT_VERSION}"
if [[ "$RAW_VERSION" =~ ^v ]]; then
  TAG="${RAW_VERSION#v}"
  NORMALIZED_TAG="$RAW_VERSION"
else
  TAG="$RAW_VERSION"
  NORMALIZED_TAG="$RAW_VERSION"
fi

case "$BUILD_TARGET" in
  linux-amd64|linux-x86_64) ARCHIVE_SUFFIX="linux-amd64" ;;
  linux-aarch64|linux-arm64) ARCHIVE_SUFFIX="linux-aarch64" ;;
  *)
    echo "Unsupported BUILD_TARGET: $BUILD_TARGET (linux-amd64, linux-aarch64; windows later)" >&2
    exit 1
    ;;
esac

WORKDIR="${WORKDIR:-/tmp/tesseract-build}"
SRC_DIR="${WORKDIR}/src"
LEPT_SRC="${WORKDIR}/leptonica"
BUILD_DIR="${WORKDIR}/build"
LEPT_BUILD="${WORKDIR}/lept-build"
DEPS_PREFIX="${WORKDIR}/deps"
STAGE_DIR="${WORKDIR}/stage"
PREFIX_DIR="${STAGE_DIR}/tesseract"

rm -rf "$WORKDIR"
mkdir -p "$SRC_DIR" "$LEPT_SRC" "$BUILD_DIR" "$LEPT_BUILD" "$DEPS_PREFIX" \
  "$PREFIX_DIR" "$OUTPUT_DIR"

echo "========================================="
echo "Building tesseract ${TESSERACT_VERSION}"
echo "  BUILD_TARGET:     ${BUILD_TARGET}"
echo "  ARCHIVE:          tesseract-${TAG}-${ARCHIVE_SUFFIX}.tar.gz"
echo "  Leptonica:        ${LEPTONICA_VERSION}"
echo "  TESSDATA_LANGS:   ${TESSDATA_LANGS}"
echo "========================================="

# --- leptonica ---
echo "Cloning leptonica ${LEPTONICA_VERSION}..."
git clone --depth 1 --branch "${LEPTONICA_VERSION}" "$LEPTONICA_REPO" "$LEPT_SRC" \
  || git clone --depth 1 --branch "v${LEPTONICA_VERSION}" "$LEPTONICA_REPO" "$LEPT_SRC"

cmake -G Ninja -S "$LEPT_SRC" -B "$LEPT_BUILD" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$DEPS_PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_PROG=OFF \
  -DCMAKE_INSTALL_RPATH='\$ORIGIN'

cmake --build "$LEPT_BUILD" --parallel "$JOBS"
cmake --install "$LEPT_BUILD"

export PKG_CONFIG_PATH="${DEPS_PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
export CMAKE_PREFIX_PATH="${DEPS_PREFIX}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export LD_LIBRARY_PATH="${DEPS_PREFIX}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

# --- tesseract ---
clone_tag() {
  local try_tag="$1"
  git clone --depth 1 --branch "$try_tag" "$UPSTREAM_REPO" "$SRC_DIR"
}

echo "Cloning tesseract ${NORMALIZED_TAG}..."
if ! clone_tag "$NORMALIZED_TAG" 2>/dev/null; then
  rm -rf "$SRC_DIR"
  mkdir -p "$SRC_DIR"
  if ! clone_tag "$TAG"; then
    echo "Failed to clone tag ${NORMALIZED_TAG} or ${TAG} from ${UPSTREAM_REPO}" >&2
    exit 1
  fi
fi

cmake -G Ninja -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_PREFIX_PATH="${DEPS_PREFIX}" \
  -DBUILD_TRAINING_TOOLS=OFF \
  -DBUILD_TESTS=OFF \
  -DBUILD_SHARED_LIBS=ON \
  -DLeptonica_DIR="${DEPS_PREFIX}/lib/cmake/leptonica" \
  -DCMAKE_INSTALL_RPATH='\$ORIGIN/../lib' \
  -DCMAKE_BUILD_RPATH_USE_ORIGIN=ON \
  -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF

cmake --build "$BUILD_DIR" --parallel "$JOBS"
DESTDIR="$PREFIX_DIR" cmake --install "$BUILD_DIR"

# Flatten DESTDIR/usr → package root
if [[ -d "$PREFIX_DIR/usr" ]]; then
  shopt -s dotglob nullglob
  for entry in "$PREFIX_DIR"/usr/*; do
    base="$(basename "$entry")"
    if [[ -e "$PREFIX_DIR/$base" ]]; then
      cp -a "$entry"/. "$PREFIX_DIR/$base"/ 2>/dev/null || mv "$entry"/* "$PREFIX_DIR/$base"/
    else
      mv "$entry" "$PREFIX_DIR/$base"
    fi
  done
  shopt -u dotglob nullglob
  rm -rf "$PREFIX_DIR/usr"
fi

# Collapse multi-arch lib dirs into lib/ (belt and suspenders)
for archdir in "$PREFIX_DIR"/lib/*-linux-gnu; do
  [[ -d "$archdir" ]] || continue
  shopt -s nullglob
  for entry in "$archdir"/*; do
    base="$(basename "$entry")"
    if [[ -e "$PREFIX_DIR/lib/$base" ]]; then
      rm -rf "$entry"
    else
      mv "$entry" "$PREFIX_DIR/lib/"
    fi
  done
  shopt -u nullglob
  rm -rf "$archdir"
done

# Drop dev junk
rm -rf \
  "$PREFIX_DIR/include" \
  "$PREFIX_DIR/lib/cmake" \
  "$PREFIX_DIR/lib/pkgconfig" \
  "$PREFIX_DIR/lib"/*.a \
  "$PREFIX_DIR/lib"/*.la \
  2>/dev/null || true

if [[ ! -x "$PREFIX_DIR/bin/tesseract" ]]; then
  echo "Install did not produce bin/tesseract" >&2
  find "$PREFIX_DIR" -type f | head -80 >&2
  exit 1
fi

# Real binary as tesseract.bin; public name is a wrapper
mv "$PREFIX_DIR/bin/tesseract" "$PREFIX_DIR/bin/tesseract.bin"

mkdir -p "$PREFIX_DIR/lib" "$PREFIX_DIR/share/tessdata"

# --- bundle shared libs ---
is_system_lib() {
  # Only leave the core ABI on the host. Bundle everything else so the
  # tarball runs on a stock Ubuntu 24.04-class glibc system without
  # hunting down libarchive/libnettle/… skew.
  local base
  base="$(basename "$1")"
  case "$base" in
    libc.so*|libm.so*|libdl.so*|librt.so*|libpthread.so*|libresolv.so*|libutil.so*|libcrypt.so*|libnsl.so*|libanl.so*|ld-linux*.so*|ld-*.so|libstdc++.so*|libgcc_s.so*|libgomp.so*|linux-vdso.so*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

declare -A SEEN_LIBS=()

copy_lib() {
  local src="$1"
  [[ -z "$src" || ! -e "$src" ]] && return 0
  local real
  real="$(readlink -f "$src")"
  [[ -z "$real" || ! -f "$real" ]] && return 0
  if [[ -n "${SEEN_LIBS[$real]+x}" ]]; then
    return 0
  fi
  SEEN_LIBS[$real]=1

  if is_system_lib "$real"; then
    return 0
  fi

  local base dest
  base="$(basename "$real")"
  dest="$PREFIX_DIR/lib/$base"
  case "$base" in
    ld-linux*.so*|ld-*.so) return 0 ;;
  esac

  # Skip no-op copy when the file is already under lib/ (same inode/path)
  if [[ ! -e "$dest" ]]; then
    echo "  bundling $real"
    cp -a "$real" "$dest"
  elif [[ "$(readlink -f "$dest")" != "$real" ]]; then
    echo "  bundling $real (replace existing $base)"
    cp -a "$real" "$dest"
  fi

  # Preserve/create the DT_SONAME link (e.g. libleptonica.so.6 → libleptonica.so.6.0.0)
  local soname srcbase
  soname="$(patchelf --print-soname "$dest" 2>/dev/null || true)"
  if [[ -n "$soname" && "$soname" != "$base" && ! -e "$PREFIX_DIR/lib/$soname" ]]; then
    ln -sfn "$base" "$PREFIX_DIR/lib/$soname"
  fi
  srcbase="$(basename "$src")"
  if [[ "$srcbase" != "$base" && ! -e "$PREFIX_DIR/lib/$srcbase" ]]; then
    ln -sfn "$base" "$PREFIX_DIR/lib/$srcbase"
  fi

  local dep
  while read -r dep; do
    [[ -z "$dep" ]] && continue
    copy_lib "$dep"
  done < <(ldd "$real" 2>/dev/null | awk '/=> \// { print $3 }' || true)
}

echo "Collecting shared library dependencies..."
# Prefer leptonica from our deps prefix
for f in "${DEPS_PREFIX}/lib/"libleptonica.so* "${DEPS_PREFIX}/lib/"liblept.so*; do
  [[ -e "$f" ]] || continue
  copy_lib "$f"
done

mapfile -d '' ELF_FILES < <(find "$PREFIX_DIR" -type f -print0)

for bin in "${ELF_FILES[@]}"; do
  file "$bin" | grep -q 'ELF' || continue
  while read -r dep; do
    [[ -z "$dep" ]] && continue
    copy_lib "$dep"
  done < <(ldd "$bin" 2>/dev/null | awk '/=> \// { print $3 }' || true)
done

# --- tessdata ---
TESSDATA_DIR="$PREFIX_DIR/share/tessdata"
echo "Fetching tessdata (${TESSDATA_LANGS}) from ${TESSDATA_REPO}..."
if [[ "${TESSDATA_LANGS}" == "all" ]]; then
  git clone --depth 1 "$TESSDATA_REPO" "${WORKDIR}/tessdata"
  # Keep traineddata only
  find "${WORKDIR}/tessdata" -maxdepth 1 -type f -name '*.traineddata' -exec cp -a {} "$TESSDATA_DIR"/ \;
else
  # Sparse-ish: download each language file from raw main
  # shellcheck disable=SC2206
  langs=(${TESSDATA_LANGS})
  for lang in "${langs[@]}"; do
    url="${TESSDATA_REPO%.git}/raw/main/${lang}.traineddata"
    # tessdata_* repos are under tesseract-ocr; normalize raw URL
    case "$TESSDATA_REPO" in
      *github.com/*)
        owner_repo="$(echo "$TESSDATA_REPO" | sed -E 's|https?://github.com/||; s|\.git$||')"
        url="https://github.com/${owner_repo}/raw/main/${lang}.traineddata"
        ;;
    esac
    echo "  downloading ${lang}.traineddata"
    curl --fail --silent --show-error --location --retry 3 \
      -o "${TESSDATA_DIR}/${lang}.traineddata" "$url"
    # sanity: traineddata is not a tiny HTML error page
    size="$(wc -c < "${TESSDATA_DIR}/${lang}.traineddata" | tr -d ' ')"
    if [[ "$size" -lt 10000 ]]; then
      echo "tessdata download looks too small for ${lang}: ${size} bytes" >&2
      exit 1
    fi
  done
fi

if ! compgen -G "${TESSDATA_DIR}/*.traineddata" >/dev/null; then
  echo "No traineddata files installed under ${TESSDATA_DIR}" >&2
  exit 1
fi

# Launcher: relocatable lib path + TESSDATA_PREFIX
cat > "$PREFIX_DIR/bin/tesseract" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export LD_LIBRARY_PATH="${ROOT}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
# Prefer packaged tessdata unless the user already set TESSDATA_PREFIX
if [[ -z "${TESSDATA_PREFIX:-}" ]]; then
  export TESSDATA_PREFIX="${ROOT}/share/tessdata"
fi
exec "${ROOT}/bin/tesseract.bin" "$@"
WRAP
chmod +x "$PREFIX_DIR/bin/tesseract"

echo "Setting RPATH on ELF files..."
while IFS= read -r -d '' elf; do
  file "$elf" | grep -q 'ELF' || continue
  case "$elf" in
    */bin/*)
      patchelf --set-rpath '$ORIGIN/../lib' "$elf" 2>/dev/null || true
      ;;
    */lib/*)
      patchelf --set-rpath '$ORIGIN' "$elf" 2>/dev/null || true
      ;;
  esac
done < <(find "$PREFIX_DIR" -type f -print0)

if [[ "$KEEP_SYMBOLS" != "1" ]]; then
  echo "Stripping binaries..."
  while IFS= read -r -d '' elf; do
    file "$elf" | grep -q 'ELF' || continue
    strip --strip-unneeded "$elf" 2>/dev/null || true
  done < <(find "$PREFIX_DIR" -type f -print0)
fi

cat > "$PREFIX_DIR/BUILDINFO.txt" <<META
package=tesseract
version=${TAG}
upstream_tag=${NORMALIZED_TAG}
leptonica_version=${LEPTONICA_VERSION}
build_target=${BUILD_TARGET}
tessdata_langs=${TESSDATA_LANGS}
tessdata_repo=${TESSDATA_REPO}
built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
META

echo "Smoke check (dynamic linker)..."
if ! LD_LIBRARY_PATH="$PREFIX_DIR/lib" ldd "$PREFIX_DIR/bin/tesseract.bin" | tee /tmp/tess-ldd.txt | grep -q 'not found'; then
  echo "All linked libraries resolved."
else
  echo "Unresolved libraries:" >&2
  grep 'not found' /tmp/tess-ldd.txt >&2 || true
  exit 1
fi

set +e
LD_LIBRARY_PATH="$PREFIX_DIR/lib" TESSDATA_PREFIX="$PREFIX_DIR/share/tessdata" \
  "$PREFIX_DIR/bin/tesseract.bin" --version >/tmp/tess-ver.txt 2>&1
set -e
if grep -qi 'error while loading shared libraries\|cannot open shared object' /tmp/tess-ver.txt; then
  cat /tmp/tess-ver.txt >&2
  exit 1
fi
cat /tmp/tess-ver.txt || true

ARCHIVE_NAME="tesseract-${TAG}-${ARCHIVE_SUFFIX}.tar.gz"
echo "Creating ${ARCHIVE_NAME}..."
tar -czf "${OUTPUT_DIR}/${ARCHIVE_NAME}" -C "$STAGE_DIR" tesseract

echo "========================================="
echo "Done: ${OUTPUT_DIR}/${ARCHIVE_NAME}"
ls -lh "${OUTPUT_DIR}/${ARCHIVE_NAME}"
echo "Contents (top):"
tar -tzf "${OUTPUT_DIR}/${ARCHIVE_NAME}" | head -n 40 || true
echo "========================================="
