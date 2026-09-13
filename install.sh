#!/bin/bash

set -euo pipefail

REPO="https://raw.githubusercontent.com/zvzt/zxt-macos-debloat/main"

INSTALL="$HOME/.zxt-macos-debloat"
PRESETS="$INSTALL/presets"
STATE="$INSTALL/state"

USER_AGENT="$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist"

SYSTEM_DAEMON="/Library/LaunchDaemons/com.zxt.macos-debloat.system.plist"

SYSTEM_DIR="/Library/Application Support/ZXTMacOSDebloat"

TMP="$(mktemp -d)"

UID_NUM="$(id -u)"


cleanup() {
    rm -rf "$TMP"
}


trap cleanup EXIT


mkdir -p \
    "$PRESETS" \
    "$STATE" \
    "$HOME/Library/LaunchAgents"


printf '\n'
printf 'ZXT macOS Debloat\n'
printf '==================\n'
printf '\n'


echo "Downloading latest files..."


curl -fsSL \
    "$REPO/zxt?$(date +%s)" \
    -o "$TMP/zxt"


curl -fsSL \
    "$REPO/presets/zxt-default.txt?$(date +%s)" \
    -o "$TMP/zxt-default.txt"


chmod +x "$TMP/zxt"


# Preserve the currently installed preset.
#
# The new ZXT uses this only to selectively
# restore services removed from an older preset.

if [ -f "$PRESETS/zxt-default.txt" ]; then

    cp \
        "$PRESETS/zxt-default.txt" \
        "$STATE/previous-preset.txt"

    echo "Previous preset saved for migration."

fi


# Install latest files.

cp \
    "$TMP/zxt" \
    "$INSTALL/zxt"


cp \
    "$TMP/zxt-default.txt" \
    "$PRESETS/zxt-default.txt"


chmod +x "$INSTALL/zxt"


# ------------------------------------------------------------
# Remove ONLY ZXT's old startup implementation.
#
# Nothing unrelated is deleted.
# ------------------------------------------------------------

launchctl bootout \
    "gui/$UID_NUM/com.zxt.macos-debloat" \
    >/dev/null 2>&1 || true


rm -f "$USER_AGENT"

rm -f "$INSTALL/auto-user.sh"


sudo launchctl bootout \
    system/com.zxt.macos-debloat.system \
    >/dev/null 2>&1 || true


sudo rm -f "$SYSTEM_DAEMON"

sudo rm -rf "$SYSTEM_DIR"


# ------------------------------------------------------------
# Install command
#
# After this, you can simply type:
#
# zxt status
# zxt apply
# zxt restore
# ------------------------------------------------------------

sudo mkdir -p /usr/local/bin


sudo ln -sf \
    "$INSTALL/zxt" \
    /usr/local/bin/zxt


# ------------------------------------------------------------
# Apply preset once now.
#
# This also performs selective migration from
# an older preset.
#
# It does NOT enable or disable Spotlight indexing.
# ------------------------------------------------------------

"$INSTALL/zxt" apply


# ------------------------------------------------------------
# USER STARTUP REAPPLY
#
# macOS 26 can reset launchctl overrides on some
# systems across restart.
#
# Reapply only the USER services in the ZXT preset.
# ------------------------------------------------------------

cat > "$USER_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE plist PUBLIC
"-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">

<dict>

    <key>Label</key>
    <string>com.zxt.macos-debloat</string>

    <key>ProgramArguments</key>

    <array>
        <string>$INSTALL/zxt</string>
        <string>reapply-user</string>
        <string>--quiet</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

</dict>

</plist>
EOF


launchctl bootstrap \
    "gui/$UID_NUM" \
    "$USER_AGENT" \
    >/dev/null 2>&1 || true


# ------------------------------------------------------------
# SYSTEM STARTUP REAPPLY
#
# Reapply only the SYSTEM services in the preset.
#
# Spotlight is intentionally untouched.
# ------------------------------------------------------------

sudo tee \
    "$SYSTEM_DAEMON" \
    >/dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE plist PUBLIC
"-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">

<dict>

    <key>Label</key>
    <string>com.zxt.macos-debloat.system</string>

    <key>ProgramArguments</key>

    <array>
        <string>$INSTALL/zxt</string>
        <string>reapply-system</string>
        <string>--quiet</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

</dict>

</plist>
EOF


sudo chown \
    root:wheel \
    "$SYSTEM_DAEMON"


sudo chmod \
    644 \
    "$SYSTEM_DAEMON"


sudo launchctl bootstrap \
    system \
    "$SYSTEM_DAEMON" \
    >/dev/null 2>&1 || true


printf '\n'
printf '========================================\n'
printf 'ZXT installation/update complete.\n'
printf '========================================\n'
printf '\n'

printf 'Commands:\n'
printf '\n'

printf '  zxt apply\n'
printf '  zxt status\n'
printf '  zxt list\n'
printf '  zxt restore\n'

printf '\n'
printf 'Spotlight indexing was not changed.\n'
printf 'Restart macOS once.\n'
printf '\n'
