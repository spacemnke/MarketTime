#!/bin/bash
# ============================================
#  MarketTime Installer
#  Double-click this file to install MarketTime
# ============================================

clear
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       MarketTime Installer           ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MarketTime.app"
APP_SRC="$SCRIPT_DIR/$APP_NAME"
APP_DEST="/Applications/$APP_NAME"

# Check if the app exists next to this script
if [ ! -d "$APP_SRC" ]; then
    echo "  ❌ Error: $APP_NAME not found."
    echo "     Make sure this script is in the same folder as $APP_NAME"
    echo ""
    echo "  Press any key to close..."
    read -n 1
    exit 1
fi

# Kill running instance if any
pkill -x MarketTime 2>/dev/null

# Copy to Applications
echo "  Installing to /Applications..."
cp -R "$APP_SRC" "$APP_DEST"

# Remove quarantine flag
echo "  Clearing security quarantine..."
xattr -cr "$APP_DEST" 2>/dev/null

echo ""
echo "  ✅ MarketTime installed successfully!"
echo ""
echo "  Launching MarketTime..."
open "$APP_DEST"

echo ""
echo "  TIP: To start MarketTime at login, go to"
echo "       System Settings > General > Login Items"
echo "       and add MarketTime."
echo ""
echo "  This window will close in 5 seconds..."
sleep 5
