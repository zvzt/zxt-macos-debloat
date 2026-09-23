#!/bin/bash
set -euo pipefail

INSTALL="$HOME/.zxt-macos-debloat"
USER_AGENT="$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist"
SYSTEM_DAEMON="/Library/LaunchDaemons/com.zxt.macos-debloat.system.plist"
UID_NUM="$(id -u)"

printf '\nZXT macOS Debloat - Uninstall\n=============================\n\n'

if [ -x "$INSTALL/zxt" ]; then
    echo "Restoring ZXT-managed changes first..."
    "$INSTALL/zxt" restore || true
fi

launchctl bootout "gui/$UID_NUM/com.zxt.macos-debloat" >/dev/null 2>&1 || true
rm -f "$USER_AGENT"

sudo launchctl bootout system/com.zxt.macos-debloat.system >/dev/null 2>&1 || true
sudo rm -f "$SYSTEM_DAEMON"

if [ -L /usr/local/bin/zxt ] || [ -f /usr/local/bin/zxt ]; then
    sudo rm -f /usr/local/bin/zxt
fi

rm -rf "$INSTALL"

echo "ZXT has been uninstalled."
echo "Restart macOS if you want restored services to return immediately."
