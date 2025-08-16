#!/bin/bash

# Save the current directory
INITIAL_DIR="$(pwd)"

# Directory for downloading and installing
mkdir -p /tmp/vscode
cd /tmp/vscode

# Download the .deb package for stable VS Code
curl -L -o vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"

# Check if the uninstall argument is passed
if [ "$1" == "uninstall" ]; then
    echo "Uninstalling Visual Studio Code..."
    sudo dpkg --remove code

    # Copy the settings.json file from VS Code settings directory
    if [ -f ~/.config/Code/User/settings.json ]; then
        cp ~/.config/Code/User/settings.json "$INITIAL_DIR/"
        echo "Copied settings.json to the script's directory."
    else
        echo "No settings.json found in the VS Code settings directory."
    fi
    
    # Remove the configuration and data directories
    echo "Removing configuration and data directories..."
    rm -rf ~/.config/Code
    rm -rf ~/.vscode

    echo "Visual Studio Code and its data have been uninstalled."

# Check if the update argument is passed
elif [ "$1" == "update" ]; then
    echo "Updating Visual Studio Code..."
    sudo dpkg -i vscode.deb

else
    # Install the downloaded package
    echo "Installing Visual Studio Code..."
    sudo dpkg -i vscode.deb

    # Copy the settings.json file to the VS Code settings directory
    mkdir -p ~/.config/Code/User
    cp "$INITIAL_DIR/settings.json" ~/.config/Code/User/ 2>/dev/null || true

    # Move back to the initial directory
    cd "$INITIAL_DIR"

    # Install plugins from extensions.txt
    if [ -f "extensions.txt" ]; then
        echo "Installing plugins from extensions.txt..."
        while IFS= read -r plugin; do
            code --install-extension "$plugin"
        done < extensions.txt
    else
        echo "No extensions.txt file found. Skipping plugin installation."
    fi

    # Additional command to add a Visual Studio Code shortcut to the dock
    echo "Adding Visual Studio Code to the dock..."

    # Create a .desktop file for Visual Studio Code
    VSCODE_DESKTOP_FILE=~/.local/share/applications/code.desktop
    echo "[Desktop Entry]" > "$VSCODE_DESKTOP_FILE"
    echo "Type=Application" >> "$VSCODE_DESKTOP_FILE"
    echo "Name=Visual Studio Code" >> "$VSCODE_DESKTOP_FILE"
    echo "Icon=code" >> "$VSCODE_DESKTOP_FILE"
    echo "Exec=code" >> "$VSCODE_DESKTOP_FILE"
    echo "Terminal=false" >> "$VSCODE_DESKTOP_FILE"
    echo "Categories=Development;IDE;" >> "$VSCODE_DESKTOP_FILE"

    # Use `gsettings` to add the shortcut to the favorites in the dock
    FAVORITES=$(gsettings get org.gnome.shell favorite-apps)
    MODIFIED_FAVORITES=$(echo "$FAVORITES" | sed -e "s/]/, 'code.desktop']/")
    gsettings set org.gnome.shell favorite-apps "$MODIFIED_FAVORITES"
fi

# Remove the temporary directory
echo "Cleaning up..."
rm -rf /tmp/vscode
