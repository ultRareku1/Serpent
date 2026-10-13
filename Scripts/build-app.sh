#!/bin/bash
# Build an Apple Silicon macOS app with no third-party dependencies.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Serpent must be packaged on macOS with the Xcode command line tools installed." >&2
    exit 1
fi

echo "Building Serpent for Apple Silicon…"
swift build -c release --arch arm64
BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"

if [ ! -f "$ROOT/Support/Serpent.icns" ] || [ "$ROOT/Scripts/make-icon.swift" -nt "$ROOT/Support/Serpent.icns" ]; then
    echo "Drawing the app icon…"
    swift "$ROOT/Scripts/make-icon.swift" "$ROOT/Support/Serpent.iconset"
    iconutil -c icns "$ROOT/Support/Serpent.iconset" -o "$ROOT/Support/Serpent.icns"
fi

APP="$ROOT/dist/Serpent.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Serpent" "$APP/Contents/MacOS/Serpent"
chmod 755 "$APP/Contents/MacOS/Serpent"
cp "$ROOT/Support/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Support/Serpent.icns" "$APP/Contents/Resources/Serpent.icns"

# SwiftPM's Bundle.module accessor searches the app's resources on macOS.
# Preserve the resource bundle (and its own localization metadata) intact.
RESOURCE_BUNDLE="$BIN_DIR/Serpent_Serpent.bundle"
if [ ! -d "$RESOURCE_BUNDLE" ]; then
    echo "Missing SwiftPM resources: $RESOURCE_BUNDLE" >&2
    exit 1
fi
ditto "$RESOURCE_BUNDLE" "$APP/Contents/Resources/Serpent_Serpent.bundle"

plutil -lint "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ROOT/dist/Serpent-Apple-Silicon.zip"

# Opt in with BUILD_DMG=1 ./Scripts/build-app.sh.
if [ "${BUILD_DMG:-0}" = "1" ]; then
    DMG_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/serpent-dmg.XXXXXX")"
    trap 'rmdir "$DMG_ROOT" 2>/dev/null || true' EXIT
    ditto "$APP" "$DMG_ROOT/Serpent.app"
    ln -s /Applications "$DMG_ROOT/Applications"
    if hdiutil create -volname Serpent -srcfolder "$DMG_ROOT" -ov -format UDZO "$ROOT/dist/Serpent-Apple-Silicon.dmg"; then
        echo "Disk image ready: dist/Serpent-Apple-Silicon.dmg"
    else
        echo "Disk image creation was unavailable; the app and ZIP are ready." >&2
    fi
fi

echo "Ready: dist/Serpent.app and dist/Serpent-Apple-Silicon.zip"
