#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build/macos"
APP_NAME="ContextChat"
APP_BUNDLE_NAME="ContextChat.app"
DMG_NAME="${APP_NAME}.dmg"
FINAL_DMG_PATH="$HOME/Desktop/$DMG_NAME"

cd "$ROOT_DIR"

echo "Building Flutter macOS app..."
rm -rf "$BUILD_DIR" "$FINAL_DMG_PATH"
fvm flutter build macos --release

echo "Locating built app..."
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_BUNDLE_NAME"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at expected path: $APP_PATH"
    echo "Searching for app in build directory..."
    APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -n 1)
    if [ -z "$APP_PATH" ]; then
        echo "❌ Could not find .app bundle"
        exit 1
    fi
    echo "Found app at: $APP_PATH"
fi

echo "Creating temporary directory for DMG..."
TEMP_DIR=$(mktemp -d)
DMG_TEMP_DIR="$TEMP_DIR/dmg"
mkdir -p "$DMG_TEMP_DIR"

echo "Copying app to temporary directory..."
cp -R "$APP_PATH" "$DMG_TEMP_DIR/"

echo "Creating symlink to Applications folder..."
ln -s /Applications "$DMG_TEMP_DIR/Applications"

echo "Creating DMG..."
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP_DIR" \
    -ov \
    -format UDZO \
    "$FINAL_DMG_PATH"

echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "✅ DMG created successfully at: $FINAL_DMG_PATH"
echo ""
echo "Verifying code signing..."
codesign --verify --verbose=4 "$APP_PATH" || echo "⚠️ Code signing verification failed (app may be unsigned)"

echo ""
echo "Done! You can distribute: $FINAL_DMG_PATH"
