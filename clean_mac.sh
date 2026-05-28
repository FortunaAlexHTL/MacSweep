#!/bin/bash
# ==============================================================================
# Script Name:  clean_mac.sh
# Description:  Cloud-Safe macOS Storage Analyzer & Optimization Utility
# Version:      1.0.0
# License:      MIT License
# ==============================================================================

# Color matrix for standardized log levels
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

VERSION="1.0.0"

# --- SYSTEM TITLE ---
echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN} MacSweep CLI | v${VERSION}${NC}"
echo -e "${CYAN} This is a free and open-source utility (MIT License)${NC}"
echo -e "${CYAN}======================================================================${NC}"

# --- GLOBAL SAFETY DISCLOSURE (NOW AT THE TOP) ---
echo -e "\n${YELLOW}[SECURITY]${NC}"
echo -e "${YELLOW}----------------------------------------------------------------------${NC}"
echo -e "  ${GREEN}[✓] IGNORING Microsoft OneDrive:${NC}   $HOME/OneDrive/*"
echo -e "  ${GREEN}[✓] IGNORING Apple iCloud Drive:${NC}  $HOME/Library/Mobile Documents/*"
echo -e "  ${GREEN}[✓] IGNORING Third-Party Cloud:${NC}  $HOME/Library/CloudStorage/*"
echo -e "  ${CYAN}[→] AUTHORIZED SCAN AREA:${NC}         $HOME/ (Local Disk Space Only)"
echo -e "${YELLOW}----------------------------------------------------------------------${NC}\n"

# --- PRE-FLIGHT DIRECTORY ANALYSIS ---
echo -e "${CYAN}[INFO]${NC} Analyzing cumulative directory usage metrics...\n"
echo -e "${YELLOW}[ANALYSIS]${NC} Top high-volume subdirectories (Excluding Cloud Storage Cache):"
echo -e "${YELLOW}----------------------------------------------------------------------${NC}"
du -sh ~/Library/* ~/.* 2>/dev/null | grep -vE "CloudStorage|OneDrive|Mobile Documents" | sort -rh | head -n 7
echo -e "${YELLOW}----------------------------------------------------------------------${NC}"
echo ""

# --- GLOBAL INITIALIZATION GATE ---
read -p "Initialize Mac Sweep toolkit? (y/n): " init_choice
if [[ "$init_choice" != "y" && "$init_choice" != "Y" ]]; then
    echo -e "${YELLOW}[INFO]${NC} Session aborted by user. Exiting safely."
    exit 0
fi

# --- PHASE 1: AUTOMATED APPLICATION CACHE PURGE ---
echo -e "\n${CYAN}[INFO]${NC} Initializing pre-scan optimization routines..."
read -p "Execute automated application cache purge? (y/n): " quick_choice
if [[ "$quick_choice" == "y" || "$quick_choice" == "Y" ]]; then
    echo -e "${YELLOW}[PROGRESS]${NC} Purging target application caches..."
    [ -d ~/Library/Caches/com.spotify.client ] && rm -rf ~/Library/Caches/com.spotify.client/*
    [ -d ~/Library/Containers/com.microsoft.teams2 ] && rm -rf ~/Library/Containers/com.microsoft.teams2/Data/Library/Caches/*
    [ -d ~/Library/Application\ Support/Code/User/workspaceStorage ] && rm -rf ~/Library/Application\ Support/Code/User/workspaceStorage/*
    command -v dotnet &> /dev/null && dotnet nuget locals all --clear > /dev/null
    rm -rf ~/Library/Logs/*
    echo -e "${GREEN}[SUCCESS]${NC} Cache purge completed successfully."
fi

# --- PHASE 2: CLOUD-SAFE ISOLATED FILE SCAN LOOP ---
while true; do
    echo -e "\n${CYAN}[INFO]${NC} Commencing local disk traversal for unmanaged objects > 100MB..."
    echo -e "${YELLOW}[SCAN]${NC} Traversal active. Processing deep disk indices..."

    LARGE_FILES=()
    while IFS= read -r line; do
        if [ ! -z "$line" ] && [ -f "$line" ]; then
            LARGE_FILES+=("$line")
        fi
    done < <(find "$HOME" \( -path "*/OneDrive*" -o -path "*/CloudStorage*" -o -path "*/Library/Mobile Documents*" \) -prune -o -type f -size +100M -print 2>/dev/null)

    if [ ${#LARGE_FILES[@]} -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} File scan complete. No unmanaged files > 100MB detected."
        break
    fi

    echo -e "\n${YELLOW}[RESULT]${NC} Identified ${#LARGE_FILES[@]} unmanaged file(s) exceeding 100MB:"
    options=()
    for file in "${LARGE_FILES[@]}"; do
        size=$(du -sh "$file" | cut -f1)
        options+=("$size -> $(basename "$file")")
    done

    PS3=$(echo -e "\n${CYAN}[INPUT] Enter item number to delete (or press 'X' to exit): ${NC}")
    select opt in "${options[@]}"; do
        
        if [[ "$REPLY" == "X" || "$REPLY" == "x" ]]; then
            echo -e "${GREEN}[INFO]${NC} Terminating Storage Manager utility session."
            break 2
        fi

        if [ -z "$opt" ]; then
            echo -e "${RED}[ERROR] Invalid input. Please enter a number from the list or 'X' to exit.${NC}"
            continue
        fi

        idx=$((REPLY - 1))
        chosen_file="${LARGE_FILES[$idx]}"

        echo -e "\n${RED}===================== TARGET METADATA =====================${NC}"
        echo -e "${YELLOW}File Name:${NC}   $(basename "$chosen_file")"
        echo -e "${YELLOW}File Size:${NC}   $(du -sh "$chosen_file" | cut -f1)"
        echo -e "${YELLOW}System Path:${NC}  $chosen_file"
        echo -e "${RED}===========================================================${NC}"
        
        read -p "Confirm permanent deletion of target file? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            rm -f "$chosen_file"
            echo -e "${GREEN}[SUCCESS] Target object purged from storage.${NC}"
        else
            echo -e "${YELLOW}[INFO] Target object bypassed.${NC}"
        fi
        break 
    done
done