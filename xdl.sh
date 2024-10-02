#!/bin/bash

width=$(tput cols)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
LAVENDER='\033[1;35m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

REQUIRED_PKGS=("jq" "curl")
REPO_JSON_URL="https://raw.githubusercontent.com/Burhanverse/xdl-installer/main/repos.json"

line=$(printf '%*s' "$width" '' | tr ' ' '=')

center_text() {
  local text="$1"
  local text_length=${#text}
  local padding=$((($width - $text_length) / 2))
  printf "%${padding}s%s\n" "" "$text"
}

confirmContinue() {
    read -p "Do you want to continue? (y/n): " choice
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

    page=1
    per_page=9

    while true; do
        clear
        start=$(( (page - 1) * per_page ))
        end=$(( start + per_page ))
        total_pages=$(( (${#NAMES[@]} + per_page - 1) / per_page ))
        
        echo -e "${CYAN}${line}${RESET}"
        echo -e "${GREEN}"
        center_text "        ______   _       "
        center_text "|\     /|(  __  \ ( \      "
        center_text "( \   / )| (  \  )| (      "
        center_text " \ (_) / | |   ) || |      "
        center_text "  ) _ (  | |   | || |      "
        center_text " / ( ) \ | |   ) || |      "
        center_text "( /   \ )| (__/  )| (____/\\"
        center_text "|/     \|(______/ (_______/ "
        echo -e "${RESET}"
        
        echo -e "${CYAN}${line}${RESET}"
        echo -e "${YELLOW}Source code available at:${RESET} ${BLUE}https://github.com/Burhanverse/xdl-installer${RESET}"
        echo -e "${YELLOW}Created by: Aqua (@burhanverse)${RESET}"
        echo -e "${CYAN}${line}${RESET}"


        echo -e "${YELLOW}Select a repository source (Page $page/$total_pages):${RESET}"

        for i in $(seq $start $(( end - 1 ))); do
            if [ $i -ge ${#NAMES[@]} ]; then
                break
            fi
            echo -e "${BLUE}$((i - start + 1))) ${CYAN}${NAMES[i]}${RESET}"
        done

        if [ $page -lt $total_pages ]; then
            echo -e "${BLUE}0) Next Page${RESET}"
        fi
        if [ $page -gt 1 ]; then
            echo -e "${BLUE}00) Previous Page${RESET}"
        fi

        echo -e "${BLUE}Enter your choice: ${RESET}"
        read -r choice

        # If choice is '00' and we are not on the first page, go back
        if [[ "$choice" == "00" ]] && [ $page -gt 1 ]; then
            page=$((page - 1))
            continue
        fi

        # If choice is '0' and we are not on the last page, go forward
        if [[ "$choice" == "0" ]] && [ $page -lt $total_pages ]; then
            page=$((page + 1))
            continue
        fi

        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Invalid selection. Please try again.${RESET}"
            continue
        fi

        index=$((start + choice - 1))
        if [ "$choice" -gt 0 ] && [ "$index" -lt "${#NAMES[@]}" ]; then
            REPO="${REPOS[$index]}"
            echo -e "${GREEN}Selected repository: $REPO${RESET}"
            break
        else
            echo -e "${RED}Invalid selection. Please try again.${RESET}"
        fi
    done
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

isRoot() {
    command -v su &> /dev/null && su -c 'exit' &> /dev/null
}

Rooted() {
    echo -e "${CYAN}Installing $APK_FILE silently (rooted device)...${RESET}"
    su -c "pm install -r $APK_FILE"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Installation completed successfully!${RESET}"
    else
        echo -e "${RED}Installation failed.${RESET}"
    fi
}

nonRoot() {
    echo -e "${CYAN}Installing $APK_FILE (normal install)...${RESET}"
    termux-open "$APK_FILE"
}

apkSave() {
    read -p "Save the APK file to internal storage? (y/n): " choice
    case "$choice" in
        [Yy]* ) 
            DEST_DIR="/storage/emulated/0/Download/XDL"
            if [ ! -d "$DEST_DIR" ]; then
                mkdir -p "$DEST_DIR"
                echo -e "${GREEN}Directory XDL created in Download.${RESET}"
            fi
            mv "$APK_FILE" "$DEST_DIR/"
            echo -e "${GREEN}APK file saved to $DEST_DIR.${RESET}"
            ;;
        [Nn]* ) 
            echo -e "${YELLOW}APK file not saved.${RESET}"
            ;;
        * ) 
            echo -e "${RED}Invalid choice. APK file not saved.${RESET}"
            ;;
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
if isRoot; then
    Rooted
else
    nonRoot
fi
apkSave
installMore
revertProps
