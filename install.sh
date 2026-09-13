#!/bin/bash

set -euo pipefail

REPO="https://raw.githubusercontent.com/zvzt/zxt-macos-debloat/main"

INSTALL="$HOME/.zxt-macos-debloat"
PRESETS="$INSTALL/presets"
STATE="$INSTALL/state"

TMP="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP"
}

trap cleanup EXIT

echo
echo "ZXT macOS Debloat"
echo "=================="
echo

mkdir -p "$INSTALL"
mkdir -p "$PRESETS"
mkdir -p "$STATE"

echo "Downloading latest ZXT..."

curl -fsSL \
    "$REPO/zxt?$(date +%s)" \
    -o "$TMP/zxt"

curl -fsSL \
    "$REPO/presets/zxt-default.txt?$(date +%s)" \
    -o "$TMP/zxt-default.txt"

chmod +x "$TMP/zxt"


# ============================================================
# Preserve the previously installed preset for migration.
#
# This lets the new ZXT re-enable services that an older
# version disabled but the new preset no longer targets.
# ============================================================

if [ -f "$PRESETS/zxt-default.txt" ]; then
    cp \
        "$PRESETS/zxt-default.txt" \
        "$STATE/previous-preset.txt"

    echo "Previous preset saved for migration."
fi


# ============================================================
# Install new version
# ============================================================

cp "$TMP/zxt" "$INSTALL/zxt"

cp \
    "$TMP/zxt-default.txt" \
    "$PRESETS/zxt-default.txt"

chmod +x "$INSTALL/zxt"


# ============================================================
# Remove legacy automatic startup system
#
# launchctl disable overrides already persist across restart.
# Re-running the entire preset at every boot/login is therefore
# unnecessary.
# ============================================================

UID_NUM="$(id -u)"

USER_PLIST="$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist"

if [ -f "$USER_PLIST" ]; then
    launchctl bootout \
        "gui/$UID_NUM/com.zxt.macos-debloat" \
        >/dev/null 2>&1 || true

    rm -f "$USER_PLIST"

    echo "Removed legacy ZXT login agent."
fi


SYSTEM_PLIST="/Library/LaunchDaemons/com.zxt.macos-debloat.system.plist"

if [ -f "$SYSTEM_PLIST" ]; then
    sudo launchctl bootout \
        system/com.zxt.macos-debloat.system \
        >/dev/null 2>&1 || true

    sudo rm -f "$SYSTEM_PLIST"

    echo "Removed legacy ZXT startup daemon."
fi


LEGACY_SYSTEM_DIR="/Library/Application Support/ZXTMacOSDebloat"

if [ -d "$LEGACY_SYSTEM_DIR" ]; then
    sudo rm -rf "$LEGACY_SYSTEM_DIR"

    echo "Removed legacy ZXT startup files."
fi


if [ -f "$INSTALL/auto-user.sh" ]; then
    rm -f "$INSTALL/auto-user.sh"
fi


# ============================================================
# Apply
# ============================================================

echo
echo "Applying updated ZXT preset..."
echo

"$INSTALL/zxt" apply


echo
echo "========================================"
echo "ZXT installation/update complete."
echo "========================================"
echo
echo "Installed at:"
echo "$INSTALL"
echo
echo "Commands:"
echo
echo "  $INSTALL/zxt apply"
echo "  $INSTALL/zxt status"
echo "  $INSTALL/zxt list"
echo "  $INSTALL/zxt restore"
echo
echo "A macOS restart is recommended."
echo
