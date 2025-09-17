#!/bin/bash
set -euo pipefail

# Version
WIZARD_VERSION="3.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Box drawing characters
BOX_TOP_LEFT="╔"
BOX_TOP_RIGHT="╗"
BOX_BOTTOM_LEFT="╚"
BOX_BOTTOM_RIGHT="╝"
BOX_HORIZONTAL="═"
BOX_VERTICAL="║"

# Available adapters - using parallel arrays for compatibility
ADAPTER_KEYS=("spec-kit" "bmad-method" "agent-os" "aider" "cursor" "continue")
ADAPTER_DESCS=(
    "GitHub specification-driven development toolkit"
    "Multi-agent development system (requires Node.js 20+)"
    "Dated specification folders methodology"
    "AI coding conventions (CONVENTIONS.md)"
    "Cursor IDE rules (.cursorrules)"
    "Continue.dev rules (.continuerules)"
)

# Selected adapters
SELECTED_ADAPTERS=()

# Function: Draw centered text in box
draw_box_line() {
    local text="$1"
    local width=60
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#clean_text}
    local padding=$(( (width - text_len) / 2 ))
    local right_padding=$(( width - text_len - padding ))

    local left_spaces=""
    local right_spaces=""
    for ((i=0; i<padding; i++)); do left_spaces="$left_spaces "; done
    for ((i=0; i<right_padding; i++)); do right_spaces="$right_spaces "; done

    echo -e "${BLUE}${BOX_VERTICAL}${NC}${left_spaces}${text}${right_spaces}${BLUE}${BOX_VERTICAL}${NC}"
}

# Function: Draw box top/bottom
draw_box_border() {
    local type="$1"
    local width=60
    local border=""
    for ((i=0; i<width; i++)); do border="${border}${BOX_HORIZONTAL}"; done

    if [ "$type" = "top" ]; then
        echo -e "${BLUE}${BOX_TOP_LEFT}${border}${BOX_TOP_RIGHT}${NC}"
    else
        echo -e "${BLUE}${BOX_BOTTOM_LEFT}${border}${BOX_BOTTOM_RIGHT}${NC}"
    fi
}

# Function: Multi-select menu for adapters
select_adapters() {
    local cursor_pos=0
    local done=false

    # Initialize selection array (0=unselected, 1=selected)
    local selected=()
    for i in "${!ADAPTER_KEYS[@]}"; do
        selected[$i]=0
    done

    clear
    while [ "$done" = false ]; do
        # Display header
        echo ""
        echo -e "${CYAN}━━━ Select Specification Frameworks ━━━${NC}"
        echo ""
        echo "Use arrow keys to navigate, SPACE to select, ENTER when done"
        echo ""

        # Display options
        for i in "${!ADAPTER_KEYS[@]}"; do
            local key="${ADAPTER_KEYS[$i]}"
            local desc="${ADAPTER_DESCS[$i]}"

            # Determine checkbox state
            if [ "${selected[$i]}" = "1" ]; then
                local checkbox="[✓]"
            else
                local checkbox="[ ]"
            fi

            # Highlight current position
            if [ "$i" = "$cursor_pos" ]; then
                echo -e "${CYAN}→ $checkbox $key${NC} - $desc"
            else
                echo "  $checkbox $key - $desc"
            fi
        done

        echo ""
        echo -e "${YELLOW}Press ENTER when done selecting${NC}"

        # Read user input
        read -rsn1 key

        case "$key" in
            # Up arrow
            $'\x1b')
                read -rsn2 key
                case "$key" in
                    '[A') # Up
                        ((cursor_pos--))
                        [ "$cursor_pos" -lt 0 ] && cursor_pos=$((${#ADAPTER_KEYS[@]} - 1))
                        ;;
                    '[B') # Down
                        ((cursor_pos++))
                        [ "$cursor_pos" -ge "${#ADAPTER_KEYS[@]}" ] && cursor_pos=0
                        ;;
                esac
                ;;
            # Space - toggle selection
            ' ')
                if [ "${selected[$cursor_pos]}" = "1" ]; then
                    selected[$cursor_pos]=0
                else
                    selected[$cursor_pos]=1
                fi
                ;;
            # Enter - done selecting
            '')
                done=true
                ;;
        esac

        # Clear screen for next iteration unless done
        [ "$done" = false ] && clear
    done

    # Collect selected adapters
    SELECTED_ADAPTERS=()
    for i in "${!ADAPTER_KEYS[@]}"; do
        if [ "${selected[$i]}" = "1" ]; then
            SELECTED_ADAPTERS+=("${ADAPTER_KEYS[$i]}")
        fi
    done
}

# Function: Install selected adapters
install_adapters() {
    local project_root="$1"
    local living_docs_path="$2"

    if [ ${#SELECTED_ADAPTERS[@]} -eq 0 ]; then
        echo -e "${YELLOW}No adapters selected${NC}"
        return
    fi

    echo ""
    echo -e "${CYAN}Installing ${#SELECTED_ADAPTERS[@]} adapter(s)...${NC}"
    echo ""

    # Source path rewriting if available
    if [ -f "adapters/common/path-rewrite.sh" ]; then
        source adapters/common/path-rewrite.sh
    fi

    # Install each selected adapter
    for adapter in "${SELECTED_ADAPTERS[@]}"; do
        echo -e "${BLUE}Installing $adapter...${NC}"

        local adapter_dir="adapters/$adapter"
        if [ -f "$adapter_dir/install.sh" ]; then
            # Set environment for adapter installation
            export LIVING_DOCS_PATH="$living_docs_path"
            export AI_PATH="$living_docs_path"
            export SPECS_PATH="$living_docs_path/specs"
            export MEMORY_PATH="$living_docs_path/memory"
            export SCRIPTS_PATH="$living_docs_path/scripts"

            if bash "$adapter_dir/install.sh" "$project_root"; then
                echo -e "${GREEN}✓${NC} $adapter installed successfully"
            else
                echo -e "${RED}✗${NC} Failed to install $adapter"
            fi
        else
            echo -e "${YELLOW}⚠${NC} Adapter $adapter not found locally"

            # Try to download from repository
            echo "Attempting to download adapter..."
            local repo_url="https://raw.githubusercontent.com/joshwegener/living-docs/main"

            mkdir -p "$adapter_dir/templates"

            # Download adapter files
            if curl -sL "$repo_url/adapters/$adapter/install.sh" -o "$adapter_dir/install.sh" && \
               curl -sL "$repo_url/adapters/$adapter/config.yml" -o "$adapter_dir/config.yml"; then
                chmod +x "$adapter_dir/install.sh"
                echo -e "${GREEN}✓${NC} Downloaded $adapter"

                # Try installation again
                if bash "$adapter_dir/install.sh" "$project_root"; then
                    echo -e "${GREEN}✓${NC} $adapter installed successfully"
                else
                    echo -e "${RED}✗${NC} Failed to install $adapter"
                fi
            else
                echo -e "${RED}✗${NC} Could not download $adapter"
            fi
        fi
        echo ""
    done

    # Update config with installed adapters
    if [ ${#SELECTED_ADAPTERS[@]} -gt 0 ]; then
        echo "INSTALLED_SPECS=\"${SELECTED_ADAPTERS[*]}\"" >> "$project_root/.living-docs.config"
        echo -e "${GREEN}✓${NC} Updated .living-docs.config with installed adapters"
    fi
}

# Function: Main installation flow
main() {
    clear

    # Display header
    draw_box_border "top"
    draw_box_line "${CYAN}🚀 Living-Docs Setup Wizard v$WIZARD_VERSION${NC}"
    draw_box_line "Multi-Spec Adapter Support Edition"
    draw_box_border "bottom"
    echo ""

    # Check if already installed
    if [ -f ".living-docs.config" ]; then
        echo -e "${YELLOW}living-docs is already installed in this project${NC}"
        echo ""
        echo "What would you like to do?"
        echo "  1) Add/update adapters"
        echo "  2) Check for updates"
        echo "  3) Reconfigure paths"
        echo "  4) Exit"
        echo ""
        read -p "Choice [1-4]: " choice

        case $choice in
            1)
                # Load existing config
                source .living-docs.config
                ;;
            2)
                # Check updates
                if [ -f "adapters/check-updates.sh" ]; then
                    bash adapters/check-updates.sh
                else
                    echo "Update checker not found"
                fi
                exit 0
                ;;
            3)
                # Reconfigure - continue with setup
                ;;
            4)
                exit 0
                ;;
        esac
    fi

    # Ask for documentation location
    echo -e "${CYAN}Where should documentation and specs be stored?${NC}"
    echo "  1) .claude/       (Recommended for Claude)"
    echo "  2) .github/       (GitHub integration)"
    echo "  3) docs/          (Traditional)"
    echo "  4) .docs/         (Hidden)"
    echo "  5) Custom path"
    echo ""
    read -p "Choice [1-5]: " path_choice

    case $path_choice in
        1) DOCS_PATH=".claude" ;;
        2) DOCS_PATH=".github" ;;
        3) DOCS_PATH="docs" ;;
        4) DOCS_PATH=".docs" ;;
        5)
            read -p "Enter custom path: " DOCS_PATH
            ;;
        *)
            DOCS_PATH="docs"
            ;;
    esac

    # Select adapters
    echo ""
    select_adapters

    # Create base structure
    echo ""
    echo -e "${CYAN}Creating living-docs structure...${NC}"

    mkdir -p "$DOCS_PATH/active"
    mkdir -p "$DOCS_PATH/completed"
    mkdir -p "$DOCS_PATH/issues"
    mkdir -p "$DOCS_PATH/procedures"

    # Create base files
    cat > "$DOCS_PATH/current.md" << 'EOF'
# Project Dashboard

**Status**: Active | **Updated**: $(date +%Y-%m-%d)

## 🔥 Active Development
<!-- Current work -->

## ✅ Recently Completed
<!-- Completed tasks -->

## 📂 Documentation Map
<!-- Project structure -->

---
*Single source of truth for project documentation*
EOF

    # Create configuration
    cat > .living-docs.config << EOF
# living-docs configuration
docs_path: "$DOCS_PATH"
version: "$WIZARD_VERSION"
created: "$(date +%Y-%m-%d)"
EOF

    echo -e "${GREEN}✓${NC} Created documentation structure"

    # Install adapters
    install_adapters "." "$DOCS_PATH"

    # Success
    echo ""
    draw_box_border "top"
    draw_box_line "${GREEN}🎉 Installation Complete!${NC}"
    draw_box_border "bottom"
    echo ""

    echo -e "${CYAN}Installed:${NC}"
    echo "  • Documentation structure in $DOCS_PATH/"
    if [ ${#SELECTED_ADAPTERS[@]} -gt 0 ]; then
        echo "  • ${#SELECTED_ADAPTERS[@]} specification framework(s):"
        for adapter in "${SELECTED_ADAPTERS[@]}"; do
            echo "    - $adapter"
        done
    fi

    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Review $DOCS_PATH/current.md"
    echo "  2. Start documenting in $DOCS_PATH/active/"
    if [[ " ${SELECTED_ADAPTERS[*]} " =~ " spec-kit " ]]; then
        echo "  3. Create specs with: $DOCS_PATH/scripts/create-new-feature.sh"
    fi
    if [[ " ${SELECTED_ADAPTERS[*]} " =~ " agent-os " ]]; then
        echo "  3. Create dated specs with: $DOCS_PATH/agent-os/new-spec.sh"
    fi
    if [[ " ${SELECTED_ADAPTERS[*]} " =~ " bmad-method " ]]; then
        echo "  3. Run BMAD agents with: $DOCS_PATH/bmad/bmad.sh"
    fi

    echo ""
    echo -e "${BLUE}Thank you for using living-docs!${NC}"
}

# Run main if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi