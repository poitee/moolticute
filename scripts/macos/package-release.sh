#!/bin/bash
# Build a distributable macOS .dmg and .zip from build/Moolticute.app
#
# Usage: ./scripts/macos/package-release.sh [version]
# Example: ./scripts/macos/package-release.sh v1.04.0-arm64

set -eo pipefail

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTDIR/../.." && pwd)"
APP=Moolticute
ARCH="$(uname -m)"

if [ -n "${1:-}" ]; then
    VERSION="$1"
else
    VERSION="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "dev")"
fi
VERSION="${VERSION#v}"

APP_PATH="$REPO_ROOT/build/${APP}.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Missing $APP_PATH — run ./scripts/macos/build-local.sh --package first"
    exit 1
fi

# Ad-hoc sign (not notarized). macOS refuses to run unsigned arm64 code,
# so a signing failure must fail the build, not be swallowed. Sign nested
# executables inner-to-outer first: --deep is deprecated and does not
# reliably cover extra binaries in Contents/MacOS.
for nested in \
    "$APP_PATH/Contents/MacOS/moolticuted" \
    "$APP_PATH/Contents/MacOS/cli/mc-agent" \
    "$APP_PATH/Contents/MacOS/cli/mc-cli"
do
    if [ -f "$nested" ]; then
        codesign --force --sign - "$nested"
    fi
done
codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
echo "Ad-hoc signature verified"

BASENAME="${APP}-${VERSION}-macos-${ARCH}"
DMG_PATH="$REPO_ROOT/build/${BASENAME}.dmg"
ZIP_PATH="$REPO_ROOT/build/${BASENAME}.zip"

rm -f "$DMG_PATH" "$ZIP_PATH"

echo "Creating $DMG_PATH"
hdiutil create \
    -volname "$APP" \
    -srcfolder "$APP_PATH" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Creating $ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Artifacts:"
ls -lh "$DMG_PATH" "$ZIP_PATH"
file "$APP_PATH/Contents/MacOS/moolticute"
