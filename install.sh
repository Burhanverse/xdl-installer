#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

REPO_URL="https://raw.githubusercontent.com/Burhanverse/xdl-installer/main/xdl.sh"
SCRIPT_NAME="xdl"
INSTALL_DIR="/data/data/com.termux/files/usr/bin"

echo -e "${YELLOW}Downloading the script from GitHub...${RESET}"
curl -L "$REPO_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download the script.${RESET}"
    exit 1
fi

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
echo -e "${GREEN}Successfully installed $SCRIPT_NAME to $INSTALL_DIR${RESET}"

echo -e "${GREEN}Installation complete! You can now run the tool using the command: $SCRIPT_NAME${RESET}"