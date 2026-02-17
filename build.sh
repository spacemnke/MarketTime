#!/bin/bash
set -e

# ============================================
#  MarketTime Build Script
#  Compiles the Swift source into a macOS .app
#  Requires: Xcode Command Line Tools
# ============================================

APP_NAME="MarketTime"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCES_DIR="$SCRIPT_DIR/Sources"
RESOURCES_SRC="$SCRIPT_DIR/Resources"

MIN_MACOS="13.0"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       MarketTime Build System        ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
echo "  Architecture:  Universal (arm64 + x86_64)"
echo "  Min macOS:     $MIN_MACOS"
echo ""

# Check for Swift compiler
if ! command -v swiftc &> /dev/null; then
    echo "  ERROR: swiftc not found."
    echo "  Install Xcode Command Line Tools:"
    echo "    xcode-select --install"
    exit 1
fi

SWIFT_VERSION=$(swiftc --version 2>&1 | head -1)
echo "  Compiler:      $SWIFT_VERSION"
echo ""

# Clean previous build
echo "  [1/5] Cleaning previous build..."
rm -rf "$BUILD_DIR"

# Create app bundle structure
echo "  [2/5] Creating app bundle..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy Info.plist
cp "$RESOURCES_SRC/Info.plist" "$CONTENTS/"

# Generate app icon
ICONSET="$RESOURCES_SRC/MarketTime.iconset"
if [ -d "$ICONSET" ]; then
    echo "  [3/5] Generating app icon..."
    iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns"
else
    echo "  [3/5] No iconset found, skipping icon..."
fi

# Compile Swift sources (Universal Binary: arm64 + x86_64)
echo "  [4/7] Compiling for arm64..."
swiftc \
    -o "$MACOS_DIR/${APP_NAME}_arm64" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Combine \
    -target "arm64-apple-macosx${MIN_MACOS}" \
    -O \
    -whole-module-optimization \
    "$SOURCES_DIR/main.swift" \
    "$SOURCES_DIR/AppDelegate.swift" \
    "$SOURCES_DIR/MarketTimer.swift" \
    "$SOURCES_DIR/MarketStatusView.swift" \
    "$SOURCES_DIR/SevenSegmentDisplay.swift"

echo "  [5/7] Compiling for x86_64..."
swiftc \
    -o "$MACOS_DIR/${APP_NAME}_x86_64" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Combine \
    -target "x86_64-apple-macosx${MIN_MACOS}" \
    -O \
    -whole-module-optimization \
    "$SOURCES_DIR/main.swift" \
    "$SOURCES_DIR/AppDelegate.swift" \
    "$SOURCES_DIR/MarketTimer.swift" \
    "$SOURCES_DIR/MarketStatusView.swift" \
    "$SOURCES_DIR/SevenSegmentDisplay.swift"

echo "  [6/7] Creating universal binary..."
lipo -create \
    "$MACOS_DIR/${APP_NAME}_arm64" \
    "$MACOS_DIR/${APP_NAME}_x86_64" \
    -output "$MACOS_DIR/$APP_NAME"
rm "$MACOS_DIR/${APP_NAME}_arm64" "$MACOS_DIR/${APP_NAME}_x86_64"

# Code sign with ad-hoc signature
echo "  [7/7] Signing with ad-hoc signature..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "  ✅  Build successful!"
echo ""
echo "  App:     $APP_BUNDLE"
echo ""

# Create distributable zip (preserving macOS metadata)
echo "  📦 Creating distributable zip..."
# Stage app + installer into a temp folder so the zip contains both
STAGE_DIR="$BUILD_DIR/MarketTime"
mkdir -p "$STAGE_DIR"
cp -R "$APP_BUNDLE" "$STAGE_DIR/"
cp "$SCRIPT_DIR/install.command" "$STAGE_DIR/"
chmod +x "$STAGE_DIR/install.command"

cd "$BUILD_DIR"
ditto -c -k --sequesterRsrc --keepParent "MarketTime" "$APP_NAME.zip"
rm -rf "MarketTime"
cd ..
ZIP_SIZE=$(du -h "$BUILD_DIR/$APP_NAME.zip" | cut -f1)
echo "  Zip:     $BUILD_DIR/$APP_NAME.zip ($ZIP_SIZE)"
echo ""
echo "  The zip contains:"
echo "    - MarketTime.app"
echo "    - install.command (double-click to install)"
echo ""
echo "  Run now:          open $APP_BUNDLE"
echo "  Install:          cp -r $APP_BUNDLE /Applications/"
echo ""
