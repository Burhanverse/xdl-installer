#!/bin/bash

# Define text colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
LAVENDER='\033[1;35m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

REQUIRED_PKGS=("jq" "curl")
REPO_JSON_URL="https://raw.githubusercontent.com/Burhanverse/xdl-installer/main/repos.json"

confirmContinue() {
    echo -e "${YELLOW}XDL is made possible by Aqua (@burhanverse)${RESET}"
    read -p "Do you want to continue ? (y/n): " choice
    case "$choice" in
        [Yy]* ) ;;
        [Nn]* ) echo -e "${YELLOW}Exiting...${RESET}"; exit 0;;
        * ) echo -e "${RED}Invalid choice. Exiting...${RESET}"; exit 1;;
    esac
}

installPkgs() {
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            echo -e "${YELLOW}Package $pkg is not installed. Installing...${RESET}"
            pkg install -y "$pkg"
            if [ $? -ne 0 ]; then
                echo -e "${RED}Failed to install $pkg. Please install it manually.${RESET}"
                exit 1
            else
                echo -e "${GREEN}Successfully installed $pkg.${RESET}"
            fi
        else
            echo -e ""
        fi
    done
}

fetchRepos() {
    echo -e "${CYAN}Fetching repository list...${RESET}"
    REPO_JSON=$(curl -s "$REPO_JSON_URL")
    if [ -z "$REPO_JSON" ]; then
        echo -e "${RED}Failed to fetch repository list.${RESET}"
        exit 1
    fi

    mapfile -t NAMES < <(echo "$REPO_JSON" | jq -r '.[].name')
    mapfile -t REPOS < <(echo "$REPO_JSON" | jq -r '.[].repo')

    if [ ${#REPOS[@]} -eq 0 ]; then
        echo -e "${RED}No repositories found in the JSON.${RESET}"
        exit 1
    fi

    echo -e "${YELLOW}Select a repository source:${RESET}"
    for i in "${!NAMES[@]}"; do
        echo -e "${BLUE}$((i + 1))) ${CYAN}${NAMES[i]}${RESET}"
    done

    echo -e "${BLUE}Enter your choice: ${RESET}"
    read -r choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#NAMES[@]}" ]; then
        echo -e "${RED}Invalid selection. Please try again.${RESET}"
        exit 1
    fi

    REPO="${REPOS[$((choice - 1))]}"
    echo -e "${GREEN}Selected repository: $REPO${RESET}"
}

updateProps() {
    if ! grep -q '^allow-external-apps = true' "$HOME/.termux/termux.properties"; then
        echo "Updating termux.properties..."
        echo 'allow-external-apps = true' >> "$HOME/.termux/termux.properties"
        termux-reload-settings
    fi
}

revertProps() {
    echo "Reverting termux.properties..."
    sed -i '/^allow-external-apps = true/d' "$HOME/.termux/termux.properties"
    termux-reload-settings
}

isRooted() {
    command -v su &> /dev/null && su -c 'exit' &> /dev/null
}

inRooted() {
    echo -e "${CYAN}Installing $APK_FILE silently (rooted device)...${RESET}"
    su -c "pm install -r $APK_FILE"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Installation completed successfully!${RESET}"
    else
        echo -e "${RED}Silent installation failed.${RESET}"
    fi
}

nonRooted() {
    echo -e "${CYAN}Installing $APK_FILE (normal install)...${RESET}"
    termux-open "$APK_FILE"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Installation completed successfully!${RESET}"
    else
        echo -e "${RED}Installation failed.${RESET}"
    fi
}

cleanUp() {
    read -p "Do you want to delete the APK file? (y/n): " choice
    case "$choice" in
        [Yy]* ) rm "$APK_FILE"; echo -e "${GREEN}APK file removed.${RESET}";;
        [Nn]* ) echo -e "${YELLOW}APK file not removed.${RESET}";;
        * ) echo -e "${RED}Invalid choice. APK file not removed.${RESET}";;
    esac
}

apkFetch() {
    echo -e "${CYAN}Fetching latest release information...${RESET}"
    RELEASE_JSON=$(curl -s https://api.github.com/repos/$REPO/releases/latest)

    RELEASE_NAME=$(echo "$RELEASE_JSON" | grep -Po '"tag_name": "\K.*?(?=")')
    echo -e "${GREEN}Latest Release: $RELEASE_NAME${RESET}"

    RELEASE_NOTES=$(echo "$RELEASE_JSON" | jq -r '.body')
    if [ -n "$RELEASE_NOTES" ]; then
        echo -e "${YELLOW}What's new in $RELEASE_NAME:${RESET}"
        echo -e "${LAVENDER}$RELEASE_NOTES${RESET}"
    else
        echo -e "${RED}No release notes available for $RELEASE_NAME.${RESET}"
    fi

    APK_URLS=$(echo "$RELEASE_JSON" | grep -Po '"browser_download_url": "\K.*?\.apk(?=")')
    if [ -z "$APK_URLS" ]; then
        echo -e "${RED}No APK files found in the latest release.${RESET}"
        exit 1
    fi
}

apkDL() {
    APK_FILES=()
    for URL in $APK_URLS; do
        APK_FILES+=("$(basename "$URL")")
    done

    echo -e "${YELLOW}Select an APK to download (or press Enter to go back to the repository list):${RESET}"
    
    for i in "${!APK_FILES[@]}"; do
        echo -e "${BLUE}$((i + 1))) ${CYAN}${APK_FILES[i]}${RESET}"
    done
    
    echo -e "${GREEN}Press ENTER KEY to go back to main menu.${RESET}"
    echo -e "${BLUE}Enter your choice: ${RESET}"
    read -r choice
    
    if [ -z "$choice" ]; then
        echo -e "${YELLOW}Returning to repository list...${RESET}"
        fetchRepos
        apkFetch
        apkDL
        return
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#APK_FILES[@]}" ]; then
        echo -e "${RED}Invalid selection. Please try again.${RESET}"
        apkDL
        return
    fi

    APK_FILE="${APK_FILES[$((choice - 1))]}"
    APK_URL=$(echo "$APK_URLS" | grep "$APK_FILE")
    echo -e "${BLUE}You selected: $APK_FILE${RESET}"
    echo -e "${CYAN}Downloading $APK_FILE...${RESET}"
    curl -L "$APK_URL" -o "$APK_FILE" --progress-bar
}

installMore() {
    read -p "Do you want to install more apps? (y/n): " choice
    case "$choice" in
        [Yy]* ) fetchRepos; apkFetch; apkDL; updateProps; if isRooted; then inRooted; else nonRooted; fi; cleanUp; installMore;;
        [Nn]* ) echo -e "${YELLOW}Exiting...${RESET}"; exit 0;;
        * ) echo -e "${RED}Invalid choice. Exiting...${RESET}"; exit 1;;
    esac
}

confirmContinue
installPkgs
fetchRepos
apkFetch
apkDL
updateProps
if isRooted; then
    inRooted
else
    nonRooted
fi
cleanUp
installMore
revertProps
