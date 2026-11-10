#!/usr/bin/env bash
# Build the Emip plugin against the APX GCS sources.
#
# Usage: scripts/build.sh [options]
#   -s DIR   existing apx-gcs checkout (with submodules); default: clone into ./apx-gcs
#   -r REF   apx-gcs git ref to clone (branch, tag or commit), default: main
#   -b DIR   build directory, default: ./build
#   -o DIR   output directory for the packaged plugin, default: ./dist
#
# The plugin directory is copied into <apx-gcs>/src/Plugins/Tools and registered in the
# Tools CMakeLists, then only the plugin target (and the GCS libraries it links to) is built.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGIN=Emip
REPO=${APX_GCS_REPO:-https://github.com/uavos/apx-gcs.git}
REF=${APX_GCS_REF:-main}
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

cmake -S "$SRC" -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD" --target "$PLUGIN"

# package
mkdir -p "$OUT"
case "$(uname -s)" in
Darwin) LIB=$BUILD/out/plugins/$PLUGIN.dylib ;;
*) LIB=$BUILD/out/plugins/$PLUGIN.so ;;
esac
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
cp -f "$LIB" "$OUT/$PLUGIN-$OS-$ARCH.${LIB##*.}"
{
    echo "plugin: $PLUGIN $(git -C "$ROOT" describe --tags --always --dirty 2>/dev/null || echo unknown)"
    echo "apx-gcs: $(git -C "$SRC" describe --tags --always) ($(git -C "$SRC" rev-parse HEAD))"
    echo "qt: $(grep -m1 'Qt6_VERSION:' "$BUILD/CMakeCache.txt" | cut -d= -f2 || true)"
    echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ) on $OS-$ARCH"
} | tee "$OUT/BUILD_INFO.txt"
ls -la "$OUT"
