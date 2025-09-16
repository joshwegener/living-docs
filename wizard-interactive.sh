#!/bin/bash
# Interactive wizard with arrow key navigation
# Optional enhancement for living-docs

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function: Interactive menu with arrow keys
select_option() {
    local options=("$@")
    local selected=0
    local key=""

    # Hide cursor
    tput civis

    while true; do
        # Clear previous menu
        for ((i=0; i<${#options[@]}; i++)); do
            tput cuu1
            tput el
        done

        # Display menu
        for ((i=0; i<${#options[@]}; i++)); do
            if [ $i -eq $selected ]; then
                echo -e "${CYAN}▶${NC} ${BOLD}${options[$i]}${NC}"
            else
                echo -e "  ${options[$i]}"
            fi
        done

        # Read single key
        read -rsn1 key

        # Handle arrow keys (escape sequences)
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case $key in
                '[A') # Up arrow
                    ((selected--))
                    if [ $selected -lt 0 ]; then
                        selected=$((${#options[@]} - 1))
                    fi
                    ;;
                '[B') # Down arrow
                    ((selected++))
                    if [ $selected -ge ${#options[@]} ]; then
                        selected=0
                    fi
                    ;;
            esac
        elif [[ $key == "" ]]; then # Enter key
            break
        fi
    done

    # Show cursor again
    tput cnorm

    # Return selected index
    echo $selected
}

# Function: Multi-select with spacebar
multi_select() {
    local options=("$@")
    local selected=0
    local checked=()
    local key=""

    # Initialize all as unchecked
    for ((i=0; i<${#options[@]}; i++)); do
        checked[$i]=false
    done

    # Hide cursor
    tput civis

    echo -e "${CYAN}Use arrows to navigate, space to select, Enter to confirm${NC}"
    echo ""

    while true; do
        # Clear previous menu
        for ((i=0; i<${#options[@]}; i++)); do
            tput cuu1
            tput el
        done

        # Display menu
        for ((i=0; i<${#options[@]}; i++)); do
            local checkbox="[ ]"
            if [ "${checked[$i]}" = true ]; then
                checkbox="[✓]"
            fi

            if [ $i -eq $selected ]; then
                echo -e "${CYAN}▶${NC} $checkbox ${BOLD}${options[$i]}${NC}"
            else
                echo -e "  $checkbox ${options[$i]}"
            fi
        done

        # Read single key
        read -rsn1 key

        # Handle keys
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case $key in
                '[A') # Up arrow
                    ((selected--))
                    if [ $selected -lt 0 ]; then
                        selected=$((${#options[@]} - 1))
                    fi
                    ;;
                '[B') # Down arrow
                    ((selected++))
                    if [ $selected -ge ${#options[@]} ]; then
                        selected=0
                    fi
                    ;;
            esac
        elif [[ $key == " " ]]; then # Spacebar
            if [ "${checked[$selected]}" = true ]; then
                checked[$selected]=false
            else
                checked[$selected]=true
            fi
        elif [[ $key == "" ]]; then # Enter key
            break
        fi
    done

    # Show cursor again
    tput cnorm

    # Return checked indices
    local result=""
    for ((i=0; i<${#options[@]}; i++)); do
        if [ "${checked[$i]}" = true ]; then
            result="$result$i "
        fi
    done
    echo $result
}

# Demo the interactive menus
clear

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}    ${CYAN}📚 living-docs${NC} - Interactive Wizard Demo          ${BLUE}║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Select your AI assistant:${NC}"
echo ""

AI_OPTIONS=(
    "Claude (Anthropic)"
    "ChatGPT (OpenAI)"
    "Cursor AI"
    "GitHub Copilot"
    "Other/Multiple"
)

AI_SELECTED=$(select_option "${AI_OPTIONS[@]}")
echo ""
echo -e "${GREEN}✓${NC} Selected: ${AI_OPTIONS[$AI_SELECTED]}"
echo ""

echo -e "${YELLOW}Select features to install:${NC}"
echo ""

FEATURE_OPTIONS=(
    "GitHub Spec-Kit"
    "Bug Tracker"
    "Ideas Board"
    "Activity Log"
    "Bootstrap Integration"
)

FEATURES_SELECTED=$(multi_select "${FEATURE_OPTIONS[@]}")
echo ""

if [ -n "$FEATURES_SELECTED" ]; then
    echo -e "${GREEN}✓${NC} Selected features:"
    for idx in $FEATURES_SELECTED; do
        echo "    - ${FEATURE_OPTIONS[$idx]}"
    done
else
    echo -e "${YELLOW}No features selected${NC}"
fi

echo ""
echo -e "${CYAN}This is a demo of interactive menus for living-docs${NC}"
echo -e "${CYAN}The full implementation would integrate with wizard.sh${NC}"