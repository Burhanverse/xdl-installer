#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

REPO_URL="https://raw.githubusercontent.com/Burhanverse/xdl-installer/main/xdl.sh"
SCRIPT_NAME="xdl"
INSTALL_DIR="$HOME/bin"

if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}curl is not installed. Installing...${RESET}"
    pkg install curl -y
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install curl. Please install it manually.${RESET}"
        exit 1
    fi
fi

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Creating directory $INSTALL_DIR...${RESET}"
    mkdir -p "$INSTALL_DIR"
fi

# Download the script from GitHub
echo -e "${YELLOW}Downloading the script from GitHub...${RESET}"
curl -L "$REPO_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download the script.${RESET}"
    exit 1
fi

# Make the script executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
echo -e "${GREEN}Successfully installed $SCRIPT_NAME to $INSTALL_DIR${RESET}"

# Add the install directory to PATH if it's not already in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}Adding $INSTALL_DIR to your PATH...${RESET}"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
    source "$HOME/.zshrc"
    echo -e "${GREEN}$INSTALL_DIR added to PATH.${RESET}"
else
    echo -e "${GREEN}$INSTALL_DIR is already in PATH.${RESET}"
fi

echo -e "${GREEN}Installation complete! You can now run the tool using the command: $SCRIPT_NAME${RESET}"
