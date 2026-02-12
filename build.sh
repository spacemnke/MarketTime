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

ARCH=$(uname -m)
MIN_MACOS="13.0"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       MarketTime Build System        ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
echo "  Architecture:  $ARCH"
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

# Compile Swift sources
echo "  [4/5] Compiling Swift sources..."
swiftc \
    -o "$MACOS_DIR/$APP_NAME" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Combine \
    -target "${ARCH}-apple-macosx${MIN_MACOS}" \
    -O \
    -whole-module-optimization \
    "$SOURCES_DIR/main.swift" \
    "$SOURCES_DIR/AppDelegate.swift" \
    "$SOURCES_DIR/MarketTimer.swift" \
    "$SOURCES_DIR/MarketStatusView.swift" \
    "$SOURCES_DIR/SevenSegmentDisplay.swift"

# Code sign with ad-hoc signature
echo "  [5/5] Signing with ad-hoc signature..."
codesign --force --sign - "$APP_BUNDLE" 2>/dev/null || true

echo ""
echo "  ✅  Build successful!"
echo ""
echo "  App:     $APP_BUNDLE"
echo ""
echo "  Run now:          open $APP_BUNDLE"
echo "  Install:          cp -r $APP_BUNDLE /Applications/"
echo "  Share with others: Zip the $APP_NAME.app and send it"
echo ""
