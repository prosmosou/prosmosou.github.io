#!/bin/bash

# Save the current directory
INITIAL_DIR="$(pwd)"

# Directory for downloading and installing
mkdir -p /tmp/vscode-insiders
cd /tmp/vscode-insiders

# Download the .deb package for Insiders
curl -L -o vscode-insiders.deb "https://code.visualstudio.com/sha/download?build=insider&os=linux-deb-x64"

# Check if the uninstall argument is passed
if [ "$1" == "uninstall" ]; then
    echo "Uninstalling Visual Studio Code Insiders..."
    sudo dpkg --remove code-insiders

    # Copy the settings.json file from VS Code Insiders settings directory
    if [ -f ~/.config/Code\ -\ Insiders/User/settings.json ]; then
        cp ~/.config/Code\ -\ Insiders/User/settings.json "$INITIAL_DIR/"
        echo "Copied settings.json to the script's directory."
    else
        echo "No settings.json found in the VS Code Insiders settings directory."
    fi
    
    # Remove the configuration and data directories
    echo "Removing configuration and data directories..."
    rm -rf ~/.config/Code\ -\ Insiders
    rm -rf ~/.vscode-insiders

    echo "Visual Studio Code Insiders and its data have been uninstalled."

# Check if the update argument is passed
elif [ "$1" == "update" ]; then
    echo "Updating Visual Studio Code Insiders..."
    sudo dpkg -i vscode-insiders.deb

else
    # Install the downloaded package
    echo "Installing Visual Studio Code Insiders..."
    sudo dpkg -i vscode-insiders.deb

    # Copy the settings.json file to the VS Code Insiders settings directory
    mkdir -p ~/.config/Code\ -\ Insiders/User
    cp "$INITIAL_DIR/settings.json" ~/.config/Code\ -\ Insiders/User/

    # Move back to the initial directory
    cd "$INITIAL_DIR"

    # Install plugins from extensions.txt
    if [ -f "extensions.txt" ]; then
        echo "Installing plugins from extensions.txt..."
        while IFS= read -r plugin; do
            code-insiders --install-extension "$plugin"
        done < extensions.txt
    else
        echo "No extensions.txt file found. Skipping plugin installation."
    fi

    # Additional command to add a Visual Studio Code Insiders shortcut to the dock
    echo "Adding Visual Studio Code Insiders to the dock..."

    # Create a .desktop file for Visual Studio Code Insiders
    VSCODE_DESKTOP_FILE=~/.local/share/applications/code-insiders.desktop
    echo "[Desktop Entry]" > "$VSCODE_DESKTOP_FILE"
    echo "Type=Application" >> "$VSCODE_DESKTOP_FILE"
    echo "Name=VS Code Insiders" >> "$VSCODE_DESKTOP_FILE"
    echo "Icon=code-insiders" >> "$VSCODE_DESKTOP_FILE"
    echo "Exec=code-insiders" >> "$VSCODE_DESKTOP_FILE"
    echo "Terminal=false" >> "$VSCODE_DESKTOP_FILE"
    echo "Categories=Development;IDE;" >> "$VSCODE_DESKTOP_FILE"

    # Use `gsettings` to add the shortcut to the favorites in the dock
    FAVORITES=$(gsettings get org.gnome.shell favorite-apps)
    MODIFIED_FAVORITES=$(echo "$FAVORITES" | sed -e "s/]/, 'code-insiders.desktop']/")
    gsettings set org.gnome.shell favorite-apps "$MODIFIED_FAVORITES"
fi

# Remove the temporary directory
echo "Cleaning up..."
rm -rf /tmp/vscode-insiders
