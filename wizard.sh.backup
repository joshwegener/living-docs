#!/bin/bash
set -euo pipefail

# Version
WIZARD_VERSION="2.1.0"

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

# Function: Draw centered text in box
draw_box_line() {
    local text="$1"
    local width=55
    # Remove ANSI codes for length calculation
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#clean_text}
    local padding=$(( (width - text_len) / 2 ))
    local right_padding=$(( width - text_len - padding ))

    # Create spaces
    local left_spaces=""
    local right_spaces=""
    for ((i=0; i<padding; i++)); do left_spaces="$left_spaces "; done
    for ((i=0; i<right_padding; i++)); do right_spaces="$right_spaces "; done

    echo -e "${BLUE}${BOX_VERTICAL}${NC}${left_spaces}${text}${right_spaces}${BLUE}${BOX_VERTICAL}${NC}"
}

# Function: Draw box top/bottom
draw_box_border() {
    local type="$1"  # top or bottom
    local width=55

    local border=""
    for ((i=0; i<width; i++)); do border="${border}${BOX_HORIZONTAL}"; done

    if [ "$type" = "top" ]; then
        echo -e "${BLUE}${BOX_TOP_LEFT}${border}${BOX_TOP_RIGHT}${NC}"
    else
        echo -e "${BLUE}${BOX_BOTTOM_LEFT}${border}${BOX_BOTTOM_RIGHT}${NC}"
    fi
}

# Function: Detect AI assistant
detect_ai_assistant() {
    local detected=""
    local confidence="high"

    # Check for AI-specific directories and files
    if [ -d ".claude" ] || [ -f "CLAUDE.md" ] || [ -f "claude.json" ]; then
        detected="claude"
    elif [ -d ".openai" ] || [ -f "OPENAI.md" ] || [ -d ".chatgpt" ] || [ -f "gpt.config" ]; then
        detected="openai"
    elif [ -d ".cursor" ] || [ -f "cursor.toml" ] || [ -f "CURSOR.md" ]; then
        detected="cursor"
    elif [ -f ".github/copilot-settings.json" ] || [ -f "COPILOT.md" ] || [ -d ".github/copilot" ]; then
        detected="copilot"
    elif [ -d ".windsurf" ] || [ -f "WINDSURF.md" ]; then
        detected="windsurf"
    elif [ -d ".continue" ] || [ -f "continue.config.json" ] || [ -f "CONTINUE.md" ]; then
        detected="continue"
    elif [ -d ".cody" ] || [ -f "cody.json" ] || [ -f "CODY.md" ]; then
        detected="cody"
    elif [ -f ".idea/ai_assistant.xml" ] || [ -f "JETBRAINS.md" ]; then
        detected="jetbrains"
    elif [ -d ".aws/amazonq" ] || [ -f "AMAZONQ.md" ]; then
        detected="amazonq"
    else
        # Fallback: check for generic AI files
        if [ -f "AI.md" ] || [ -f "ai.md" ] || [ -f ".ai/config" ]; then
            detected="generic"
            confidence="medium"
        fi
    fi

    echo "$detected:$confidence"
}

# Function: Detect existing spec system
detect_spec_system() {
    local spec=""

    if [ -d ".github/ISSUE_TEMPLATE" ] && [ -f ".github/CODE_OF_CONDUCT.md" ]; then
        spec="github-spec-kit"
    elif [ -d ".github" ] && [ -f ".github/pull_request_template.md" ]; then
        spec="github-spec-kit"
    elif [ -d ".specify" ] || [ -f "specify.json" ]; then
        spec="specify"
    elif [ -f "PRD.md" ] || [ -d "agents" ]; then
        spec="bmad-method"
    elif [ -d ".agent-os" ]; then
        spec="agent-os"
    fi

    echo "$spec"
}

# Function: Detect documentation structure
detect_docs_structure() {
    local docs_path=""

    # Check common documentation locations
    if [ -d "docs" ]; then
        docs_path="docs"
    elif [ -d ".docs" ]; then
        docs_path=".docs"
    elif [ -d ".github/docs" ]; then
        docs_path=".github/docs"
    elif [ -d ".claude/docs" ]; then
        docs_path=".claude/docs"
    elif [ -d "documentation" ]; then
        docs_path="documentation"
    elif [ -d ".documentation" ]; then
        docs_path=".documentation"
    fi

    echo "$docs_path"
}

# Function: Map AI to file name
get_ai_filename() {
    local ai="$1"

    case $ai in
        "claude") echo "CLAUDE.md" ;;
        "openai") echo "OPENAI.md" ;;
        "cursor") echo "CURSOR.md" ;;
        "copilot") echo "COPILOT.md" ;;
        "windsurf") echo "WINDSURF.md" ;;
        "continue") echo "CONTINUE.md" ;;
        "cody") echo "CODY.md" ;;
        "jetbrains") echo "JETBRAINS.md" ;;
        "amazonq") echo "AMAZONQ.md" ;;
        *) echo "AI.md" ;;
    esac
}

# Function: Map AI to display name
get_ai_display_name() {
    local ai="$1"

    case $ai in
        "claude") echo "Claude (Anthropic)" ;;
        "openai") echo "ChatGPT/GPT-4 (OpenAI)" ;;
        "cursor") echo "Cursor AI" ;;
        "copilot") echo "GitHub Copilot" ;;
        "windsurf") echo "Windsurf" ;;
        "continue") echo "Continue" ;;
        "cody") echo "Cody (Sourcegraph)" ;;
        "jetbrains") echo "JetBrains AI" ;;
        "amazonq") echo "Amazon Q" ;;
        "generic") echo "Generic AI Assistant" ;;
        *) echo "Unknown" ;;
    esac
}

# Function: Show detection results and confirm
show_detection_results() {
    local ai="$1"
    local ai_confidence="$2"
    local spec="$3"
    local docs="$4"

    echo ""
    echo -e "${CYAN}━━━ Environment Detection ━━━${NC}"
    echo ""

    if [ -n "$ai" ]; then
        echo -e "${GREEN}✓${NC} AI Assistant: $(get_ai_display_name "$ai")"
        if [ "$ai_confidence" = "medium" ]; then
            echo -e "  ${YELLOW}(confidence: medium - please confirm)${NC}"
        fi
    else
        echo -e "${YELLOW}?${NC} AI Assistant: Not detected"
    fi

    if [ -n "$spec" ]; then
        echo -e "${GREEN}✓${NC} Spec System: $spec"
    else
        echo -e "${YELLOW}?${NC} Spec System: None detected"
    fi

    if [ -n "$docs" ]; then
        echo -e "${GREEN}✓${NC} Docs Location: $docs/"
    else
        echo -e "${YELLOW}?${NC} Docs Location: Not found (will create)"
    fi

    echo ""
    echo -e "${BLUE}Is this correct?${NC} (y)es, (c)ustomize, (s)kip"
    read -p "> " CONFIRM

    # Don't return, set global variable
    DETECTION_CONFIRM="$CONFIRM"
}

# Function: Show what will be created
show_creation_preview() {
    local docs_path="$1"
    local ai_file="$2"
    local spec_system="$3"
    local spec_location="${4:-.github}"

    echo ""
    echo -e "${CYAN}━━━ Installation Preview ━━━${NC}"
    echo ""
    echo -e "${BLUE}The following files will be created:${NC}"
    echo ""

    # Documentation structure
    echo "  📁 Documentation Structure:"
    echo "    ├── $docs_path/"
    echo "    │   ├── current.md        (project dashboard)"
    echo "    │   ├── bootstrap.md      (AI instructions)"
    echo "    │   ├── log.md           (activity log)"
    echo "    │   ├── active/          (current work)"
    echo "    │   ├── completed/       (finished work)"
    echo "    │   ├── issues/          (bug investigations)"
    echo "    │   └── procedures/      (how-to guides)"

    # AI file
    echo ""
    echo "  🤖 AI Configuration:"
    echo "    └── $ai_file             (AI assistant instructions)"

    # Quick trackers
    echo ""
    echo "  📝 Quick Trackers:"
    echo "    ├── bugs.md              (lightweight bug tracker)"
    echo "    └── ideas.md             (feature ideas)"

    # Spec system files
    if [ "$spec_system" = "github-spec-kit" ]; then
        echo ""
        echo "  📦 GitHub Spec-Kit:"
        echo "    └── $spec_location/"
        echo "        ├── CODE_OF_CONDUCT.md"
        echo "        ├── CONTRIBUTING.md"
        echo "        ├── SECURITY.md"
        echo "        ├── pull_request_template.md"
        echo "        └── ISSUE_TEMPLATE/"
        echo "            ├── bug_report.md"
        echo "            ├── feature_request.md"
        echo "            └── config.yml"
    fi

    # Configuration
    echo ""
    echo "  ⚙️  Configuration:"
    echo "    └── .living-docs.config  (settings & preferences)"

    echo ""
    echo -e "${YELLOW}Additionally, we will add this line to $ai_file:${NC}"
    echo -e "${CYAN}  @$docs_path/bootstrap.md${NC}"
    echo ""
    echo -e "${BLUE}Continue with installation?${NC} ([y]es/[n]o/[c]ustomize)"
    read -p "> " CONTINUE

    # Don't return, set global variable
    CREATION_CONFIRM="$CONTINUE"
}

# Main script
clear

# Header
draw_box_border "top"
draw_box_line ""
draw_box_line "${CYAN}📚 living-docs${NC} - Documentation That Stays Alive"
draw_box_line ""
draw_box_border "bottom"

echo ""
echo -e "${CYAN}🔮 Welcome to the living-docs wizard!${NC}"
echo ""

# Check if this is an existing living-docs project
if [ -f ".living-docs.config" ]; then
    echo -e "${GREEN}✓${NC} This project already uses living-docs!"
    echo ""
    echo -e "${BLUE}What would you like to do?${NC}"
    echo "  1) Check for all updates (recommended)"
    echo "  2) Check spec-kit updates only"
    echo "  3) Reconfigure"
    echo "  4) Exit"
    read -p "Choice (1-4): " UPDATE_CHOICE

    case $UPDATE_CHOICE in
        1)
            # Full update - download and run update.sh
            echo ""
            echo -e "${MAGENTA}━━━ Checking for Updates ━━━${NC}"
            echo ""

            # Download update.sh from GitHub
            echo -e "${CYAN}Downloading update script...${NC}"
            if curl -sL "https://raw.githubusercontent.com/joshwegener/living-docs/main/update.sh" -o update.sh.tmp; then
                chmod +x update.sh.tmp
                mv update.sh.tmp update.sh
                echo -e "${GREEN}✓${NC} Downloaded update.sh"
                echo -e "${CYAN}Running update check...${NC}"
                echo ""
                exec ./update.sh
            else
                echo -e "${RED}✗${NC} Failed to download update script"
                echo "Please check your internet connection and try again"
                exit 1
            fi
            ;;
        2)
            # Spec-kit update only
            echo ""
            echo -e "${MAGENTA}━━━ Checking for Updates ━━━${NC}"
            echo ""

            # Extract spec_system and spec_location from config
            SPEC_SYSTEM=$(grep "^spec_system:" .living-docs.config | cut -d'"' -f2)
            SPEC_LOCATION=$(grep "^spec_location:" .living-docs.config | cut -d'"' -f2)

            # Check what spec system is in use
            if [ "$SPEC_SYSTEM" = "github-spec-kit" ]; then
                echo -e "${BLUE}📦 Checking GitHub Spec-Kit files...${NC}"

                # Determine spec location (default to .github if not set)
                SPEC_DIR="${SPEC_LOCATION:-.github}"

                # Check for missing files
                MISSING_FILES=()
                SPEC_FILES=(
                    "CODE_OF_CONDUCT.md"
                    "CONTRIBUTING.md"
                    "SECURITY.md"
                    "pull_request_template.md"
                    "ISSUE_TEMPLATE/bug_report.md"
                    "ISSUE_TEMPLATE/feature_request.md"
                    "ISSUE_TEMPLATE/config.yml"
                )

                for file in "${SPEC_FILES[@]}"; do
                    if [ ! -f "$SPEC_DIR/$file" ]; then
                        MISSING_FILES+=("$file")
                    fi
                done

                if [ ${#MISSING_FILES[@]} -eq 0 ]; then
                    echo -e "${GREEN}✓${NC} All spec-kit files are present in $SPEC_DIR"
                else
                    echo -e "${YELLOW}⚠${NC} Missing ${#MISSING_FILES[@]} spec-kit files:"
                    for file in "${MISSING_FILES[@]}"; do
                        echo "    - $file"
                    done

                    echo ""
                    echo -e "${BLUE}Would you like to restore missing files?${NC} (y/n)"
                    read -p "> " RESTORE

                    if [[ "$RESTORE" =~ ^[Yy]$ ]]; then
                        # Find the wizard script location
                        WIZARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                        ADAPTER_SCRIPT="$WIZARD_DIR/adapters/spec-kit.sh"

                        if [ -f "$ADAPTER_SCRIPT" ]; then
                            echo -e "${CYAN}Restoring missing files to $SPEC_DIR...${NC}"
                            if SPEC_LOCATION="$SPEC_DIR" bash "$ADAPTER_SCRIPT" install; then
                                echo -e "${GREEN}✓${NC} Missing files restored successfully"
                            else
                                echo -e "${RED}✗${NC} Failed to restore files"
                            fi
                        else
                            echo -e "${RED}✗${NC} Spec-kit adapter not found at $ADAPTER_SCRIPT"
                        fi
                    fi
                fi
            else
                echo -e "${YELLOW}No updateable methodology detected${NC}"
            fi

            echo ""
            echo -e "${GREEN}✓${NC} Update check complete"
            exit 0
            ;;
        3)
            echo -e "${CYAN}Reconfiguration not yet implemented${NC}"
            exit 0
            ;;
        *)
            exit 0
            ;;;
    esac
fi

# Step 1: Detect environment for new installations
echo -e "${BLUE}Analyzing your project...${NC}"

AI_DETECTION=$(detect_ai_assistant)
AI_DETECTED=$(echo "$AI_DETECTION" | cut -d: -f1)
AI_CONFIDENCE=$(echo "$AI_DETECTION" | cut -d: -f2)
SPEC_DETECTED=$(detect_spec_system)
DOCS_DETECTED=$(detect_docs_structure)

# Step 2: Show detection and confirm
show_detection_results "$AI_DETECTED" "$AI_CONFIDENCE" "$SPEC_DETECTED" "$DOCS_DETECTED"

# Initialize variables
if [ "$DETECTION_CONFIRM" = "y" ] || [ "$DETECTION_CONFIRM" = "yes" ]; then
    # Use detected values
    if [ -n "$AI_DETECTED" ]; then
        AI_FILE=$(get_ai_filename "$AI_DETECTED")
    else
        AI_FILE="AI.md"
    fi

    if [ -n "$DOCS_DETECTED" ]; then
        DOCS_PATH="$DOCS_DETECTED"
    else
        DOCS_PATH="docs"
    fi

    if [ -n "$SPEC_DETECTED" ]; then
        SPEC_SYSTEM="$SPEC_DETECTED"
        INSTALL_SPEC="no"  # Already installed
    else
        # Ask if they want to install spec-kit
        echo ""
        echo -e "${BLUE}No specification framework detected.${NC}"
        echo -e "${YELLOW}Would you like to install one?${NC}"
        echo ""
        echo "  1) GitHub Spec-Kit (recommended for open source)"
        echo "  2) Skip for now"
        echo ""
        read -p "Choice (1-2): " SPEC_CHOICE

        case $SPEC_CHOICE in
            1)
                SPEC_SYSTEM="github-spec-kit"
                INSTALL_SPEC="yes"
                ;;
            *)
                SPEC_SYSTEM="none"
                INSTALL_SPEC="no"
                ;;
        esac
    fi

    # Auto-updates for auto-detected setup
    echo ""
    echo -e "${BLUE}🔄 Enable auto-updates?${NC} (y/n)"
    read -p "> " AUTO_UPDATE

    if [[ "$AUTO_UPDATE" =~ ^[Yy]$ ]]; then
        AUTO_UPDATE_ENABLED="true"
        echo "Update frequency: (d)aily, (w)eekly, (m)onthly?"
        read -p "> " UPDATE_FREQ
        case $UPDATE_FREQ in
            d) UPDATE_FREQUENCY="daily" ;;
            w) UPDATE_FREQUENCY="weekly" ;;
            m) UPDATE_FREQUENCY="monthly" ;;
            *) UPDATE_FREQUENCY="weekly" ;;
        esac
    else
        AUTO_UPDATE_ENABLED="false"
        UPDATE_FREQUENCY="manual"
    fi

elif [ "$DETECTION_CONFIRM" = "c" ] || [ "$DETECTION_CONFIRM" = "customize" ]; then
    # Manual configuration
    echo ""
    echo -e "${MAGENTA}━━━ Manual Configuration ━━━${NC}"
    echo ""

    # Choose AI
    echo -e "${BLUE}Which AI assistant do you use?${NC}"
    echo "  1) Claude (Anthropic)"
    echo "  2) ChatGPT (OpenAI)"
    echo "  3) Cursor AI"
    echo "  4) GitHub Copilot"
    echo "  5) Windsurf"
    echo "  6) Continue"
    echo "  7) Other/Multiple"
    read -p "Choice (1-7): " AI_CHOICE

    case $AI_CHOICE in
        1) AI_FILE="CLAUDE.md" ;;
        2) AI_FILE="OPENAI.md" ;;
        3) AI_FILE="CURSOR.md" ;;
        4) AI_FILE="COPILOT.md" ;;
        5) AI_FILE="WINDSURF.md" ;;
        6) AI_FILE="CONTINUE.md" ;;
        *) AI_FILE="AI.md" ;;
    esac

    # Choose docs location
    echo ""
    echo -e "${BLUE}Where should documentation live?${NC}"
    echo "  1) docs/              (standard)"
    echo "  2) .docs/             (hidden)"
    echo "  3) .github/docs/      (GitHub-centric)"
    echo "  4) Custom..."
    read -p "Choice (1-4): " DOCS_CHOICE

    case $DOCS_CHOICE in
        1) DOCS_PATH="docs" ;;
        2) DOCS_PATH=".docs" ;;
        3) DOCS_PATH=".github/docs" ;;
        4)
            read -p "Enter path: " DOCS_PATH
            ;;
        *) DOCS_PATH="docs" ;;
    esac

    # Spec system
    echo ""
    echo -e "${BLUE}Install GitHub Spec-Kit?${NC} (y/n)"
    read -p "> " SPEC_INSTALL

    if [[ "$SPEC_INSTALL" =~ ^[Yy]$ ]]; then
        SPEC_SYSTEM="github-spec-kit"
        INSTALL_SPEC="yes"
    else
        SPEC_SYSTEM="none"
        INSTALL_SPEC="no"
    fi

    # Auto-updates
    echo ""
    echo -e "${BLUE}🔄 Enable auto-updates?${NC} (y/n)"
    read -p "> " AUTO_UPDATE

    if [[ "$AUTO_UPDATE" =~ ^[Yy]$ ]]; then
        AUTO_UPDATE_ENABLED="true"
        echo "Update frequency: (d)aily, (w)eekly, (m)onthly?"
        read -p "> " UPDATE_FREQ
        case $UPDATE_FREQ in
            d) UPDATE_FREQUENCY="daily" ;;
            w) UPDATE_FREQUENCY="weekly" ;;
            m) UPDATE_FREQUENCY="monthly" ;;
            *) UPDATE_FREQUENCY="weekly" ;;
        esac
    else
        AUTO_UPDATE_ENABLED="false"
        UPDATE_FREQUENCY="manual"
    fi
else
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

# Determine spec location for non-GitHub projects
SPEC_LOCATION=".github"
if [ "$INSTALL_SPEC" = "yes" ] && [ "$AI_FILE" != "CLAUDE.md" ]; then
    AI_PREFIX=$(echo "$AI_FILE" | sed 's/\.md$//' | tr '[:upper:]' '[:lower:]')
    SPEC_LOCATION=".$AI_PREFIX"
fi

# Step 3: Show what will be created and get final confirmation
show_creation_preview "$DOCS_PATH" "$AI_FILE" "$SPEC_SYSTEM" "$SPEC_LOCATION"

if [ "$CREATION_CONFIRM" != "y" ] && [ "$CREATION_CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

# Step 4: Create everything
echo ""
echo -e "${MAGENTA}━━━ Installing living-docs ━━━${NC}"
echo ""

# Create configuration first
cat > .living-docs.config << EOF
# living-docs Configuration
version: 1.0
project:
  name: "$(basename "$PWD")"
  type: "ai"
paths:
  docs: "$DOCS_PATH"
  ai_file: "$AI_FILE"
spec_system: "$SPEC_SYSTEM"
$([ "$SPEC_LOCATION" != ".github" ] && echo "spec_location: \"$SPEC_LOCATION\"")
auto_update: ${AUTO_UPDATE_ENABLED:-false}
update_frequency: "${UPDATE_FREQUENCY:-manual}"
created: $(date +%Y-%m-%d)
EOF
echo -e "${GREEN}✓${NC} Created configuration"

# Create documentation structure
mkdir -p "$DOCS_PATH"/{active,completed,issues,procedures}
echo -e "${GREEN}✓${NC} Created $DOCS_PATH/ structure"

# Create current.md dashboard
cat > "$DOCS_PATH/current.md" << 'EOF'
# Project Dashboard

## 📊 Metrics
- **Active Tasks**: 0
- **Open Bugs**: 0
- **Completed This Week**: 0

## 🔥 Active Development
<!-- Tasks in docs/active/ -->

## 🐛 Bug Status
<!-- Quick bugs in ../bugs.md -->

## ✅ Recently Completed
<!-- Tasks in docs/completed/ -->

## 📚 Documentation Map
- [Bootstrap](bootstrap.md) - AI instructions
- [Activity Log](log.md) - Timestamped updates
- [Bug Tracker](../bugs.md) - Quick issue tracking
- [Ideas](../ideas.md) - Feature backlog

---
*Dashboard auto-updated by living-docs*
EOF
echo -e "${GREEN}✓${NC} Created dashboard"

# Create bootstrap.md
cat > "$DOCS_PATH/bootstrap.md" << 'EOF'
# Bootstrap - AI Assistant Instructions

## Quick Start
This project uses living-docs to keep documentation alive.

## Documentation Structure
- `docs/current.md` - Project dashboard
- `docs/active/` - Current work
- `docs/completed/` - Finished tasks
- `bugs.md` - Quick issue tracking
- `ideas.md` - Feature ideas

## Workflow
1. Check dashboard for current state
2. Document work in active/
3. Move to completed/ when done
4. Update bugs.md as needed

---
*Keep docs alive by using them*
EOF
echo -e "${GREEN}✓${NC} Created bootstrap"

# Create log.md
cat > "$DOCS_PATH/log.md" << EOF
# Activity Log

## $(date +%Y-%m-%d)
$(date '+%I:%M %p') - SYSTEM: living-docs installed successfully

---
*One-line updates with timestamps*
EOF
echo -e "${GREEN}✓${NC} Created activity log"

# Create or update AI file
if [ -f "$AI_FILE" ]; then
    # Check if bootstrap line already exists
    if ! grep -q "@$DOCS_PATH/bootstrap.md" "$AI_FILE"; then
        echo "" >> "$AI_FILE"
        echo "## Documentation" >> "$AI_FILE"
        echo "@$DOCS_PATH/bootstrap.md - Project documentation system" >> "$AI_FILE"
        echo -e "${GREEN}✓${NC} Updated $AI_FILE with bootstrap reference"
    else
        echo -e "${GREEN}✓${NC} $AI_FILE already has bootstrap reference"
    fi
else
    cat > "$AI_FILE" << EOF
# AI Assistant Configuration

## Documentation
@$DOCS_PATH/bootstrap.md - Project documentation system

## Project Overview
[Add project description here]

## Key Principles
[Add coding standards and principles]

---
*Powered by living-docs*
EOF
    echo -e "${GREEN}✓${NC} Created $AI_FILE with bootstrap reference"
fi

# Create bugs.md
cat > bugs.md << 'EOF'
# Quick Bug Tracker

## 🔴 Critical
<!-- Blocking issues -->

## 🟡 High Priority
<!-- Important bugs -->

## 🟢 Normal
<!-- Standard issues -->

## ✅ Recently Fixed
<!-- Completed with date -->

---
*Quick tracking - promote to docs/issues/ for investigation*
EOF
echo -e "${GREEN}✓${NC} Created bug tracker"

# Create ideas.md
cat > ideas.md << 'EOF'
# Feature Ideas

## 💡 Next Up
<!-- Ready to implement -->

## 🔬 Research Needed
<!-- Requires investigation -->

## 🎯 Future Vision
<!-- Long-term goals -->

---
*Capture ideas quickly, refine in docs/active/*
EOF
echo -e "${GREEN}✓${NC} Created ideas tracker"

# Install spec-kit if requested
if [ "$INSTALL_SPEC" = "yes" ] && [ "$SPEC_SYSTEM" = "github-spec-kit" ]; then
    echo ""
    echo -e "${BLUE}Installing GitHub Spec-Kit to $SPEC_LOCATION...${NC}"

    # Find the adapter script
    WIZARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ADAPTER_SCRIPT="$WIZARD_DIR/adapters/spec-kit.sh"

    if [ -f "$ADAPTER_SCRIPT" ]; then
        if SPEC_LOCATION="$SPEC_LOCATION" bash "$ADAPTER_SCRIPT" install; then
            echo -e "${GREEN}✓${NC} GitHub Spec-Kit installed"
        else
            echo -e "${YELLOW}⚠${NC} Spec-Kit installation failed (continuing anyway)"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Spec-Kit adapter not found"
    fi
fi

# Success message
echo ""
draw_box_border "top"
draw_box_line "${GREEN}🎉 Installation Complete!${NC}"
draw_box_border "bottom"
echo ""

echo -e "${CYAN}Next steps:${NC}"
echo "  1. Review $AI_FILE"
echo "  2. Check $DOCS_PATH/current.md"
echo "  3. Start documenting in $DOCS_PATH/active/"
echo ""
echo -e "${BLUE}Thank you for using living-docs!${NC}"
echo -e "${CYAN}Documentation that stays alive 📚${NC}"