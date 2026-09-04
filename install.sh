#!/bin/bash

set -e

REPO="https://raw.githubusercontent.com/zvzt/zxt-macos-debloat/main"
INSTALL="$HOME/.zxt-macos-debloat"
UID_NUM="$(id -u)"

mkdir -p "$INSTALL/presets"

curl -fsSL "$REPO/zxt" -o "$INSTALL/zxt"
curl -fsSL "$REPO/presets/zxt-default.txt" -o "$INSTALL/presets/zxt-default.txt"

chmod +x "$INSTALL/zxt"

"$INSTALL/zxt" apply

echo
printf "Enable automatic debloat after every login/startup? [y/N]: " >/dev/tty
IFS= read -r ANSWER < /dev/tty

case "$ANSWER" in
    y|Y|yes|YES|Yes)

        mkdir -p "$HOME/Library/LaunchAgents"

        cat > "$INSTALL/auto-user.sh" <<'AUTOUSER'
#!/bin/bash

PRESET="$HOME/.zxt-macos-debloat/presets/zxt-default.txt"
UID_NUM="$(id -u)"

while IFS= read -r line; do
    label="${line%%#*}"
    label="$(echo "$label" | xargs)"

    [ -z "$label" ] && continue

    found=0

    for dir in \
        /System/Library/LaunchAgents \
        /Library/LaunchAgents \
        /Library/Apple/System/Library/LaunchAgents \
        /System/Cryptexes/App/System/Library/LaunchAgents
    do
        if [ -e "$dir/$label.plist" ]; then
            found=1
            break
        fi
    done

    if [ "$found" -eq 1 ]; then
        launchctl disable "gui/$UID_NUM/$label" >/dev/null 2>&1 || true
    fi
done < "$PRESET"
AUTOUSER

        chmod +x "$INSTALL/auto-user.sh"

        cat > "$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zxt.macos-debloat</string>

    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL/auto-user.sh</string>
    </array>

    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

        launchctl bootout \
            "gui/$UID_NUM/com.zxt.macos-debloat" \
            >/dev/null 2>&1 || true

        launchctl bootstrap \
            "gui/$UID_NUM" \
            "$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist"

        sudo mkdir -p "/Library/Application Support/ZXTMacOSDebloat"

        sudo cp "$INSTALL/presets/zxt-default.txt" \
            "/Library/Application Support/ZXTMacOSDebloat/zxt-default.txt"

        sudo tee "/Library/Application Support/ZXTMacOSDebloat/auto-system.sh" >/dev/null <<'AUTOSYSTEM'
#!/bin/bash

PRESET="/Library/Application Support/ZXTMacOSDebloat/zxt-default.txt"

while IFS= read -r line; do
    label="${line%%#*}"
    label="$(echo "$label" | xargs)"

    [ -z "$label" ] && continue

    found=0

    for dir in \
        /System/Library/LaunchDaemons \
        /Library/LaunchDaemons \
        /Library/Apple/System/Library/LaunchDaemons \
        /System/Cryptexes/App/System/Library/LaunchDaemons
    do
        if [ -e "$dir/$label.plist" ]; then
            found=1
            break
        fi
    done

    if [ "$found" -eq 1 ]; then
        launchctl disable "system/$label" >/dev/null 2>&1 || true
    fi
done < "$PRESET"

mdutil -a -i off >/dev/null 2>&1 || true
AUTOSYSTEM

        sudo chmod +x \
            "/Library/Application Support/ZXTMacOSDebloat/auto-system.sh"

        sudo tee /Library/LaunchDaemons/com.zxt.macos-debloat.system.plist >/dev/null <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zxt.macos-debloat.system</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Library/Application Support/ZXTMacOSDebloat/auto-system.sh</string>
    </array>

    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST

        sudo chown root:wheel \
            /Library/LaunchDaemons/com.zxt.macos-debloat.system.plist

        sudo chmod 644 \
            /Library/LaunchDaemons/com.zxt.macos-debloat.system.plist

        sudo launchctl bootout \
            system/com.zxt.macos-debloat.system \
            >/dev/null 2>&1 || true

        sudo launchctl bootstrap \
            system \
            /Library/LaunchDaemons/com.zxt.macos-debloat.system.plist

        echo
        echo "Automatic startup debloat: ENABLED"
        ;;

    *)
        echo
        echo "Automatic startup debloat: DISABLED"
        ;;
esac
