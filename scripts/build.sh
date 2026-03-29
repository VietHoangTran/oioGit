#!/bin/bash
set -euo pipefail

# --- Config ---
SCHEME="oioGit"
PROJECT="oioGit.xcodeproj"
BUILD_DIR="build"
APP_NAME="oioGit"

# --- Clean & Build ---
echo "▸ Cleaning..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "▸ Archiving Release..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    archive \
    SKIP_INSTALL=NO \
    | tail -5

# --- Export .app from archive ---
echo "▸ Exporting app..."
ARCHIVE_APP="$BUILD_DIR/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app"
RELEASE_DIR="$BUILD_DIR/Release"
mkdir -p "$RELEASE_DIR"
cp -R "$ARCHIVE_APP" "$RELEASE_DIR/"

# --- Read version from built app ---
VERSION=$(defaults read "$(pwd)/$RELEASE_DIR/$APP_NAME.app/Contents/Info.plist" CFBundleShortVersionString)

# --- Ad-hoc codesign (for local distribution without Developer ID) ---
echo "▸ Code signing (ad-hoc)..."
codesign --force --deep --sign - "$RELEASE_DIR/$APP_NAME.app"

# --- Create DMG ---
echo "▸ Creating DMG..."
DMG_PATH="$BUILD_DIR/${APP_NAME}-v${VERSION}.dmg"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$RELEASE_DIR/$APP_NAME.app" \
    -ov -format UDZO \
    "$DMG_PATH"

echo ""
echo "✅ Build complete!"
echo "   App: $RELEASE_DIR/$APP_NAME.app"
echo "   DMG: $DMG_PATH"
echo "   Version: $VERSION"
