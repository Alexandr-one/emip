#!/usr/bin/env bash
# Build the Emip plugin against the APX GCS sources.
#
# Usage: scripts/build.sh [options]
#   -s DIR   existing apx-gcs checkout (with submodules); default: clone into ./apx-gcs
#   -r REF   apx-gcs git ref to clone (branch, tag or commit); default: the GCS release the plugin
#            tag is made for (tag v11.2.32.1 -> release-11.2.32 when it exists, main otherwise)
#   -b DIR   build directory, default: ./build
#   -o DIR   output directory for the packaged plugin, default: ./dist
# Env: APX_GCS_REPO, APX_GCS_REF (clone source), APX_GCS_SKIP_PLUGINS (space separated GCS plugin
# directories to drop from the configuration, e.g. "VideoStreaming Joystick").
#
# The plugin directory is copied into <apx-gcs>/src/Plugins/Tools and registered in the
# Tools CMakeLists, then only the plugin target (and the GCS libraries it links to) is built.
#
# Plugin releases are tagged with the GCS version plus the plugin build number: v11.2.32.1 is the
# first build for GCS 11.2.32. The GCS loads a plugin only when the versions match, so the build
# fails when the configured GCS version differs from the tag.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGIN=Emip
REPO=${APX_GCS_REPO:-https://github.com/uavos/apx-gcs.git}
REF=${APX_GCS_REF:-}
SRC=
BUILD=$ROOT/build
OUT=$ROOT/dist

while getopts "s:r:b:o:" opt; do
    case $opt in
    s) SRC=$OPTARG ;;
    r) REF=$OPTARG ;;
    b) BUILD=$OPTARG ;;
    o) OUT=$OPTARG ;;
    *) exit 2 ;;
    esac
done

# the GCS version from the plugin tag (v11.2.32.1 -> 11.2.32), empty when not on a version tag
PLUGIN_TAG=${GITHUB_REF_NAME:-}
[ "${GITHUB_REF_TYPE:-}" = "tag" ] || PLUGIN_TAG=$(git -C "$ROOT" describe --tags --exact-match 2>/dev/null || true)
GCS_VERSION=$(echo "$PLUGIN_TAG" | sed -nE 's/^v?([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$/\1/p')
echo "plugin tag: ${PLUGIN_TAG:-none}, GCS version: ${GCS_VERSION:-any}"

if [ -z "$REF" ]; then
    REF=main
    if [ -n "$GCS_VERSION" ] && [ -n "$(git ls-remote --tags "$REPO" "release-$GCS_VERSION")" ]; then
        REF=release-$GCS_VERSION
    fi
fi

if [ -z "$SRC" ]; then
    SRC=$ROOT/apx-gcs
    if [ ! -d "$SRC/.git" ]; then
        echo "Cloning $REPO ($REF) into $SRC"
        git clone "$REPO" "$SRC"
    fi
    git -C "$SRC" fetch --tags origin
    git -C "$SRC" checkout --quiet "$REF"
    git -C "$SRC" submodule update --init --recursive
fi
SRC=$(cd "$SRC" && pwd)
echo "apx-gcs: $(git -C "$SRC" describe --tags --always) ($(git -C "$SRC" rev-parse --short HEAD))"

# put the plugin into the GCS tree
TOOLS=$SRC/src/Plugins/Tools
rm -rf "$TOOLS/$PLUGIN"
cp -r "$ROOT/$PLUGIN" "$TOOLS/$PLUGIN"
grep -q "add_subdirectory(\"$PLUGIN\")" "$TOOLS/CMakeLists.txt" ||
    echo "add_subdirectory(\"$PLUGIN\")" >>"$TOOLS/CMakeLists.txt"

# plugins that need extra native libraries (SDL, GStreamer) and are not needed to build ours
for skip in ${APX_GCS_SKIP_PLUGINS:-}; do
    sed -i.bak "/add_subdirectory(\"$skip\")/d" "$SRC"/src/Plugins/*/CMakeLists.txt
    echo "skipped GCS plugin: $skip"
done

cmake -S "$SRC" -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=Release

# the plugin is built for exactly the GCS version of the tag
BUILT_VERSION=$(grep -m1 '^CMAKE_PROJECT_VERSION:' "$BUILD/CMakeCache.txt" | cut -d= -f2)
echo "apx-gcs version: $BUILT_VERSION"
if [ -n "$GCS_VERSION" ] && [ "$BUILT_VERSION" != "$GCS_VERSION" ]; then
    echo "error: plugin tag $PLUGIN_TAG is for GCS $GCS_VERSION but the sources are version $BUILT_VERSION" >&2
    exit 1
fi

cmake --build "$BUILD" --target "$PLUGIN"

# package: <out>/Emip-<os>-<arch>.<so|dylib> (the GCS renames it back to Emip.<ext>) and build info
mkdir -p "$OUT"
case "$(uname -s)" in
Darwin)
    LIB=$BUILD/out/plugins/$PLUGIN.dylib
    OS=macos
    ARCH=$(lipo -archs "$LIB" 2>/dev/null | tr ' ' '_')
    [ "$ARCH" = "x86_64_arm64" ] || [ "$ARCH" = "arm64_x86_64" ] && ARCH=universal
    ;;
*)
    LIB=$BUILD/out/plugins/$PLUGIN.so
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    ;;
esac
QT_DIR=$(grep -m1 '^Qt6_DIR:' "$BUILD/CMakeCache.txt" | cut -d= -f2 || true)
cp -f "$LIB" "$OUT/$PLUGIN-$OS-$ARCH.${LIB##*.}"
{
    echo "plugin: $PLUGIN $(git -C "$ROOT" describe --tags --always --dirty 2>/dev/null || echo unknown)"
    echo "apx-gcs: $BUILT_VERSION $(git -C "$SRC" describe --tags --always) ($(git -C "$SRC" rev-parse HEAD))"
    echo "qt: ${QT_DIR:-unknown}"
    echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ) on $OS-$ARCH"
} | tee "$OUT/BUILD_INFO-$OS-$ARCH.txt"
ls -la "$OUT"
