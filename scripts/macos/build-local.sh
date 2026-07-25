#!/bin/bash
# Build Moolticute natively on macOS (Intel or Apple Silicon).
#
# Requirements:
#   brew install qt go
#
# Usage:
#   ./scripts/macos/build-local.sh
#   ./scripts/macos/build-local.sh --package

set -eo pipefail

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTDIR/../.." && pwd)"
PACKAGE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --package) PACKAGE=1 ;;
        -h|--help)
            echo "Usage: $0 [--package]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# shellcheck source=../ci/osx/env.sh
source "$SCRIPTDIR/../ci/osx/env.sh"
# shellcheck source=../ci/funcs.sh
source "$SCRIPTDIR/../ci/funcs.sh"

detect_qtdir
QMAKE_BIN="$(qmake_bin)"
MACDEPLOYQT_BIN="$(macdeployqt_bin)"

echo "Building Moolticute for $MACOS_ARCH using Qt at $QTDIR"

cd "$REPO_ROOT"
make_version . macos

mkdir -p build
cd build

export PATH="$QTDIR/bin:$PATH"
"$QMAKE_BIN" ../Moolticute.pro
make -j"$(sysctl -n hw.ncpu)"

if [ "$PACKAGE" -eq 0 ]; then
    echo "Build complete: $REPO_ROOT/build/Moolticute.app"
    file "$REPO_ROOT/build/Moolticute.app/Contents/MacOS/moolticute"
    exit 0
fi

APP=Moolticute
cp "$SCRIPTDIR/../ci/osx/Info.plist" "$APP.app/Contents/Info.plist"

# Stamp the bundle version (the template plist carries none)
BUNDLE_VERSION="$(get_version "$REPO_ROOT" 2>/dev/null || echo v0.0.0)"
BUNDLE_VERSION="${BUNDLE_VERSION#v}"
PLIST="$APP.app/Contents/Info.plist"
for key in CFBundleShortVersionString CFBundleVersion; do
    /usr/libexec/PlistBuddy -c "Delete :$key" "$PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :$key string $BUNDLE_VERSION" "$PLIST"
done

cp moolticuted "$APP.app/Contents/MacOS/"

mkdir -p "$APP.app/Contents/MacOS/cli"
bundle_mc_cli_tools "$REPO_ROOT/build/$APP.app/Contents/MacOS/cli"

"$MACDEPLOYQT_BIN" "$APP.app"

echo "Packaged app: $REPO_ROOT/build/$APP.app"
file "$APP.app/Contents/MacOS/moolticute" "$APP.app/Contents/MacOS/cli/mc-agent"
