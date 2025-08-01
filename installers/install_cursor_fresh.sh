#!/bin/bash

# Variables
# this uses the latest cursor AppImage from downloads and removes all cursor settings and fixes the layout

APP_NAME="Cursor"
APPIMAGE_URL="https://downloads.cursor.com/production/96e5b01ca25f8fbd4c4c10bc69b15f6228c80771/linux/x64/Cursor-0.50.5-x86_64.AppImage"
ICON_URL="https://avatars.githubusercontent.com/u/126759922?s=48&v=4"
INSTALL_DIR="/opt/$APP_NAME"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"
APPIMAGE_FILE="$INSTALL_DIR/$APP_NAME.AppImage"
DOWNLOADS_DIR="$HOME/Downloads"

CURSOR_CONFIG_DIR="$HOME/.config/Cursor"
CURSOR_CACHE_DIR="$HOME/.cache/Cursor"
CURSOR_LOCAL_DIR="$HOME/.local/share/Cursor"

# Clear Cursor data
clear_cursor_data() {
    echo "Clearing all Cursor settings and cache..."

    killall -9 cursor 2>/dev/null || true
    killall -9 Cursor 2>/dev/null || true
    pkill -9 -f "Cursor\.AppImage" 2>/dev/null || true
    pkill -9 -f "Cursor.*AppImage" 2>/dev/null || true
    pkill -9 -f "/opt/Cursor" 2>/dev/null || true
    pkill -9 -f "/tmp/.mount_Cursor" 2>/dev/null || true

    CURSOR_PIDS=$(ps -ef | grep -i cursor | grep -v grep | grep -v "cursor.sh" | grep -v "bash.*cursor" | awk '{print $2}')
    for pid in $CURSOR_PIDS; do
        if [ "$pid" != "$$" ]; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    done

    APPIMAGE_PIDS=$(ps -ef | grep -i "\.appimage" | grep -v grep | grep -v "cursor.sh" | awk '{print $2}')
    for pid in $APPIMAGE_PIDS; do
        if ps -p "$pid" -o cmd= | grep -i cursor > /dev/null && [ "$pid" != "$$" ]; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    done

    rm -rf "$CURSOR_CONFIG_DIR" "$CURSOR_CACHE_DIR" "$CURSOR_LOCAL_DIR"

    RECENT_FILES="$HOME/.local/share/recently-used.xbel"
    [ -f "$RECENT_FILES" ] && sed -i '/Cursor/d' "$RECENT_FILES" 2>/dev/null || true

    echo "Cursor settings and cache cleared."
}

# Check for recent AppImage
check_recent_appimage() {
    LATEST_APPIMAGE=$(find "$DOWNLOADS_DIR" -name "*Cursor*.AppImage" -type f -print0 2>/dev/null | xargs -0 -r ls -t | head -n 1)
    if [ -n "$LATEST_APPIMAGE" ]; then
        echo "Found latest Cursor AppImage: $LATEST_APPIMAGE"
        RECENT_APPIMAGE="$LATEST_APPIMAGE"
        return 0
    else
        echo "No Cursor AppImage found in Downloads."
        return 1
    fi
}

# Check FUSE
echo "Checking FUSE dependency..."
if ! dpkg -l | grep -q "^ii.*libfuse2"; then
    echo "Installing libfuse2..."
    sudo apt-get update
    sudo apt-get install -y libfuse2
fi

# Clear existing Cursor data
clear_cursor_data

# Create installation directory
sudo mkdir -p "$INSTALL_DIR"

# Download or use existing AppImage
if check_recent_appimage; then
    sudo cp "$RECENT_APPIMAGE" "$APPIMAGE_FILE"
else
    sudo wget -O "$APPIMAGE_FILE" "$APPIMAGE_URL"
fi

sudo chmod +x "$APPIMAGE_FILE"

# Download app icon
sudo wget -O "$INSTALL_DIR/$APP_NAME.png" "$ICON_URL"

# Create desktop file
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Exec=$APPIMAGE_FILE --no-sandbox
Icon=$INSTALL_DIR/$APP_NAME.png
Terminal=false
Categories=Utility;
EOF

chmod +x "$DESKTOP_FILE"
update-desktop-database "$HOME/.local/share/applications/"

# Add to taskbar if GNOME
if command -v gsettings >/dev/null 2>&1; then
    FAV_APPS=$(gsettings get org.gnome.shell favorite-apps)
    UPDATED_FAV_APPS=$(echo "$FAV_APPS" | sed "s/\[/[\'$APP_NAME.desktop\',/")
    gsettings set org.gnome.shell favorite-apps "$UPDATED_FAV_APPS"
fi

# Apply Cursor settings
echo "Configuring Cursor settings..."

SETTINGS_PATH="$HOME/.config/Cursor/User/settings.json"
mkdir -p "$(dirname "$SETTINGS_PATH")"
touch "$SETTINGS_PATH"

if ! command -v jq >/dev/null 2>&1; then
    echo "Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
fi

read -r -d '' NEW_SETTINGS <<EOF
{
  "window.commandCenter": true,
  "workbench.colorTheme": "Visual Studio Light",
  "workbench.activityBar.orientation": "vertical"
}
EOF

tmpfile=$(mktemp)
jq -s '.[0] * .[1]' <(cat "$SETTINGS_PATH") <(echo "$NEW_SETTINGS") > "$tmpfile" && mv "$tmpfile" "$SETTINGS_PATH"

echo "Installation complete! You can now launch $APP_NAME from your taskbar or application menu."
echo "VSCode Cursor settings updated. Please restart Cursor to apply changes."
