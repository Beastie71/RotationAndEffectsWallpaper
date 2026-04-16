#!/bin/bash

# Configuration
PLUGIN_ID="org.kde.plasma.rotationandeffects"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function: Uninstall
uninstall_plugin() {
    echo -e "${YELLOW}Uninstalling $PLUGIN_ID...${NC}"
    kpackagetool6 --type Plasma/Wallpaper --remove "$PLUGIN_ID" &> /dev/null
    rm -rf "$HOME/.local/share/plasma/wallpapers/$PLUGIN_ID"
    rm -f /tmp/plasma_wallpaper_*.png 2>/dev/null
    rm -rf ~/.cache/plasma* 2>/dev/null
    rm -rf ~/.cache/qmlcache 2>/dev/null
    echo -e "${GREEN}Uninstallation complete.${NC}"
}

if [[ "$1" == "--uninstall" ]]; then
    uninstall_plugin
    exit 0
fi

echo -e "${GREEN}Starting installation for $PLUGIN_ID...${NC}"

# 1. Dependency Checks
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed.${NC}"
        return 1
    fi
    return 0
}

tools=("python3" "plasmashell" "kpackagetool6")
for tool in "${tools[@]}"; do
    if ! check_tool "$tool"; then exit 1; fi
done

# 2. Clean Installation
echo "Removing old plugin version if exists..."
kpackagetool6 --type Plasma/Wallpaper --remove "$PLUGIN_ID" &> /dev/null
rm -rf "$HOME/.local/share/plasma/wallpapers/$PLUGIN_ID"

echo "Installing new version from current directory..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kpackagetool6 --type Plasma/Wallpaper --install "$SCRIPT_DIR"

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}kpackagetool6 reported an error, attempting manual installation...${NC}"
    INSTALL_PATH="$HOME/.local/share/plasma/wallpapers/$PLUGIN_ID"
    mkdir -p "$INSTALL_PATH"
    cp -r "$SCRIPT_DIR"/* "$INSTALL_PATH/"
    echo -e "${GREEN}Manual copy to $INSTALL_PATH successful.${NC}"
fi

# 3. Permissions
chmod +x "$SCRIPT_DIR/contents/code/backend.py"

# 4. Cache clearing
echo "Clearing system caches..."
rm -rf ~/.cache/plasma* 2>/dev/null
rm -rf ~/.cache/qmlcache 2>/dev/null
kbuildsycoca6 --noincremental &> /dev/null

echo -e "${GREEN}Installation finished successfully.${NC}"
echo -e "${YELLOW}MANUAL ACTION REQUIRED:${NC}"
echo "1. Run: plasmashell --replace &"
echo "2. Check for errors: journalctl -f | grep rotationandeffects"
