#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build/macos"
APP_NAME="ContextChat"
APP_BUNDLE_NAME="ContextChat.app"
DMG_NAME="${APP_NAME}.dmg"
FINAL_DMG_PATH="$HOME/Desktop/$DMG_NAME"

# Optional release signing/notarization settings.
# SIGN_IDENTITY example: Developer ID Application: Your Name (TEAMID)
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
ENABLE_SIGN="${ENABLE_SIGN:-0}"
ENABLE_NOTARIZE="${ENABLE_NOTARIZE:-0}"

# Load credentials from .env (overrides shell defaults)
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

echo "Starting macOS deployment script with settings:"
echo "  ENABLE_SIGN: $ENABLE_SIGN"
echo "  SIGN_IDENTITY: ${SIGN_IDENTITY:-<not set>}"
echo "  ENABLE_NOTARIZE: $ENABLE_NOTARIZE"
echo "  NOTARY_PROFILE: ${NOTARY_PROFILE:-<not set>}"

if [ "$ENABLE_NOTARIZE" = "1" ] && [ "$ENABLE_SIGN" != "1" ]; then
    echo "❌ Notarization requires signing. Set ENABLE_SIGN=1 when ENABLE_NOTARIZE=1."
    exit 1
fi

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

if [ "$ENABLE_SIGN" = "1" ]; then
    if [ -z "$SIGN_IDENTITY" ]; then
        echo "❌ ENABLE_SIGN=1 but SIGN_IDENTITY is empty."
        echo "   Example: SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)'"
        exit 1
    fi

    echo "Signing app with identity: $SIGN_IDENTITY"
    # Hardened runtime + timestamp are required for notarization.
    codesign --force --deep --timestamp --options runtime --sign "$SIGN_IDENTITY" "$APP_PATH"
fi

echo "Creating temporary directory for DMG..."
TEMP_DIR=$(mktemp -d)
DMG_TEMP_DIR="$TEMP_DIR/dmg"
mkdir -p "$DMG_TEMP_DIR"

echo "Copying app to temporary directory..."
ditto "$APP_PATH" "$DMG_TEMP_DIR/$APP_BUNDLE_NAME"

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

if [ "$ENABLE_NOTARIZE" = "1" ]; then
    if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
        echo "❌ ENABLE_NOTARIZE=1 but credentials missing from .env (APPLE_ID, TEAM_ID, APP_SPECIFIC_PASSWORD)"
        exit 1
    fi
    if [ "$ENABLE_SIGN" != "1" ]; then
        echo "❌ Notarization requires signing. Set ENABLE_SIGN=1 when ENABLE_NOTARIZE=1."
        exit 1
    fi

    echo "Submitting DMG for notarization..."
    xcrun notarytool submit "$FINAL_DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --wait

    echo "Stapling notarization ticket..."
    xcrun stapler staple "$FINAL_DMG_PATH"
    xcrun stapler staple "$APP_PATH"
fi

echo ""
echo "Verifying code signing..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH" || echo "⚠️ Code signing verification failed (app may be unsigned)"

echo "Checking Gatekeeper assessment..."
spctl --assess --type execute -vv "$APP_PATH" || echo "⚠️ Gatekeeper assessment failed"

echo ""
echo "Done! You can distribute: $FINAL_DMG_PATH"
