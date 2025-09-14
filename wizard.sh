#!/bin/bash

# living-docs Wizard - Universal Setup & Repair
# One script for everything: new projects, existing projects, repairs, migrations
# Usage: ./wizard.sh [optional-path]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Banner
clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                       ║${NC}"
echo -e "${BLUE}║${NC}     ${CYAN}📚 living-docs${NC} - Documentation That Stays Alive  ${BLUE}║${NC}"
echo -e "${BLUE}║                                                       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect if we're in an existing project
PROJECT_PATH=${1:-"."}
cd "$PROJECT_PATH"

# Auto-detection function
detect_project_state() {
    if [ -f ".living-docs.config" ]; then
        echo "configured"
    elif [ -f "README.md" ] || [ -f "package.json" ] || [ -f "requirements.txt" ] || [ -d ".git" ]; then
        echo "existing"
    else
        echo "new"
    fi
}

PROJECT_STATE=$(detect_project_state)

# Main wizard flow
echo -e "${CYAN}🔮 Welcome to the living-docs wizard!${NC}"
echo ""

# Determine what to do based on project state
case $PROJECT_STATE in
    "configured")
        echo -e "${GREEN}✓${NC} This project already uses living-docs!"
        echo ""
        echo -e "${BLUE}What would you like to do?${NC}"
        echo "  1) Update configuration"
        echo "  2) Migrate to new structure"
        echo "  3) Check for methodology updates"
        echo "  4) View current status"
        echo "  5) Exit"
        echo ""
        read -p "Choice (1-5): " ACTION

        case $ACTION in
            1) MODE="reconfigure" ;;
            2) MODE="migrate" ;;
            3) MODE="update" ;;
            4)
                cat .living-docs.config
                exit 0
                ;;
            *) exit 0 ;;
        esac
        ;;

    "existing")
        echo -e "${YELLOW}📂${NC} Detected existing project!"
        echo ""

        # Show what we found
        echo -e "${CYAN}Found:${NC}"
        [ -f "README.md" ] && echo "  ✓ README.md"
        [ -f "package.json" ] && echo "  ✓ package.json (Node.js)"
        [ -f "requirements.txt" ] && echo "  ✓ requirements.txt (Python)"
        [ -d ".git" ] && echo "  ✓ Git repository"
        [ -d "docs" ] && echo "  ✓ docs/ directory"
        [ -f "CLAUDE.md" ] && echo "  ✓ CLAUDE.md (AI instructions)"
        echo ""

        echo -e "${BLUE}How would you like to add living-docs?${NC}"
        echo "  1) Quick Add       (minimal changes, adds on top)"
        echo "  2) Full Integration (reorganize documentation)"
        echo "  3) Custom Setup    (choose every option)"
        echo ""
        read -p "Choice (1-3): " EXISTING_MODE

        case $EXISTING_MODE in
            1) MODE="bootstrap" ;;
            2) MODE="integrate" ;;
            3) MODE="custom" ;;
            *) MODE="bootstrap" ;;
        esac
        ;;

    "new")
        echo -e "${GREEN}🎉${NC} Starting fresh!"
        echo ""
        echo -e "${BLUE}Project name?${NC}"
        read -p "> " PROJECT_NAME
        PROJECT_NAME=${PROJECT_NAME:-"my-project"}

        # Create project directory if needed
        if [ "$PROJECT_PATH" = "." ]; then
            PROJECT_PATH="./$PROJECT_NAME"
            mkdir -p "$PROJECT_PATH"
            cd "$PROJECT_PATH"
        fi

        MODE="new"
        ;;
esac

# Common configuration for all modes
echo ""
echo -e "${MAGENTA}━━━ Configuration ━━━${NC}"
echo ""

# Documentation location
echo -e "${BLUE}📁 Where should documentation live?${NC}"
echo "  1) docs/              (standard)"
echo "  2) .docs/             (hidden)"
echo "  3) .claude/docs/      (AI-specific)"
echo "  4) .github/docs/      (GitHub-centric)"
echo "  5) .documentation/    (enterprise)"
echo "  6) Custom..."
read -p "Choice (1-6): " DOC_CHOICE

case $DOC_CHOICE in
    1) DOCS_PATH="docs" ;;
    2) DOCS_PATH=".docs" ;;
    3) DOCS_PATH=".claude/docs" ;;
    4) DOCS_PATH=".github/docs" ;;
    5) DOCS_PATH=".documentation" ;;
    6)
        read -p "Enter path: " DOCS_PATH
        ;;
    *) DOCS_PATH="docs" ;;
esac

# AI Assistant
echo ""
echo -e "${BLUE}🤖 Which AI assistant(s) do you use?${NC}"
echo "  1) Claude (Anthropic)"
echo "  2) ChatGPT (OpenAI)"
echo "  3) GitHub Copilot"
echo "  4) Cursor AI"
echo "  5) JetBrains AI"
echo "  6) Multiple/All"
echo "  7) None"
read -p "Choice (1-7): " AI_CHOICE

case $AI_CHOICE in
    1) AI_FILE="CLAUDE.md" ;;
    2) AI_FILE="OPENAI.md" ;;
    3) AI_FILE="COPILOT.md" ;;
    4) AI_FILE="CURSOR.md" ;;
    5) AI_FILE="JETBRAINS.md" ;;
    6) AI_FILE="AI.md" ;;
    7) AI_FILE="PROJECT.md" ;;
    *) AI_FILE="AI.md" ;;
esac

# Development methodology
echo ""
echo -e "${BLUE}⚙️  Development methodology?${NC}"
echo "  1) GitHub Spec-Kit    (community-driven)"
echo "  2) BMAD Method        (AI-driven)"
echo "  3) Agent OS           (agent coordination)"
echo "  4) None               (just living-docs)"
echo "  5) Auto-detect        (analyze project)"
echo "  6) Custom"
read -p "Choice (1-6): " SPEC_CHOICE

case $SPEC_CHOICE in
    1) SPEC_SYSTEM="github-spec-kit" ;;
    2) SPEC_SYSTEM="bmad-method" ;;
    3) SPEC_SYSTEM="agent-os" ;;
    4) SPEC_SYSTEM="none" ;;
    5)
        # Auto-detect methodology
        if [ -d ".github/ISSUE_TEMPLATE" ]; then
            SPEC_SYSTEM="github-spec-kit"
        elif [ -f "PRD.md" ] || [ -d "agents" ]; then
            SPEC_SYSTEM="bmad-method"
        else
            SPEC_SYSTEM="none"
        fi
        echo -e "${GREEN}Detected: $SPEC_SYSTEM${NC}"
        ;;
    6)
        read -p "Enter name: " SPEC_SYSTEM
        ;;
    *) SPEC_SYSTEM="none" ;;
esac

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

# Implementation based on mode
echo ""
echo -e "${MAGENTA}━━━ Setting up... ━━━${NC}"
echo ""

# Create configuration
cat > .living-docs.config << EOF
# living-docs Configuration
version: 1.0
mode: "$MODE"
project:
  name: "${PROJECT_NAME:-$(basename "$PWD")}"
  type: "$([[ "$AI_FILE" == "PROJECT.md" ]] && echo "standard" || echo "ai")"
paths:
  docs: "$DOCS_PATH"
  bugs: "bugs.md"
  ai_file: "$AI_FILE"
spec_system: "$SPEC_SYSTEM"
auto_update: $AUTO_UPDATE_ENABLED
update_frequency: "$UPDATE_FREQUENCY"
created: $(date +"%Y-%m-%d")
EOF
echo -e "${GREEN}✓${NC} Configuration saved"

# Create directory structure if needed
if [ "$MODE" != "bootstrap" ]; then
    mkdir -p "$DOCS_PATH"/{active,completed,issues,procedures,examples,contributing,templates}
    echo -e "${GREEN}✓${NC} Created $DOCS_PATH/ structure"
fi

# Create or update AI/PROJECT file
if [ ! -f "$AI_FILE" ]; then
    if [ -f "$(dirname "$0")/templates/ai-projects/$AI_FILE.template" ]; then
        cp "$(dirname "$0")/templates/ai-projects/$AI_FILE.template" "$AI_FILE"
    else
        cat > "$AI_FILE" << 'EOF'
# Project Guidelines

## Documentation System
This project uses [living-docs](https://github.com/joshwegener/living-docs) for documentation.

## Quick Reference
- Track issues in `bugs.md`
- Check status in `$DOCS_PATH/current.md`
- Active work in `$DOCS_PATH/active/`

---
*Powered by living-docs - documentation that stays alive*
EOF
    fi

    # Replace variables
    sed -i '' "s|{{DOCS_PATH}}|$DOCS_PATH|g" "$AI_FILE" 2>/dev/null || true
    sed -i '' "s|{{PROJECT_NAME}}|${PROJECT_NAME:-$(basename "$PWD")}|g" "$AI_FILE" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Created $AI_FILE"
else
    echo "" >> "$AI_FILE"
    echo "## living-docs Integration" >> "$AI_FILE"
    echo "This project now uses [living-docs](https://github.com/joshwegener/living-docs)" >> "$AI_FILE"
    echo -e "${GREEN}✓${NC} Updated existing $AI_FILE"
fi

# Create bugs.md if doesn't exist
if [ ! -f "bugs.md" ]; then
    cat > bugs.md << 'EOF'
# Quick Bug Tracker

## 🔴 Critical
<!-- Blocking issues -->

## 🟡 High Priority
<!-- Important bugs -->

## 🟢 Normal
<!-- Standard issues -->

## ✅ Recently Fixed
<!-- Completed items with date -->

---
*Track quick issues here. Promote to $DOCS_PATH/issues/ for investigation.*
EOF
    echo -e "${GREEN}✓${NC} Created bugs.md"
fi

# Create dashboard if full setup
if [ "$MODE" != "bootstrap" ]; then
    cat > "$DOCS_PATH/current.md" << EOF
# ${PROJECT_NAME:-$(basename "$PWD")} - Project Dashboard

**Status**: INITIAL | **Created**: $(date +"%B %d, %Y")

## 🎯 Overview
Project documentation powered by living-docs.

## 🔥 Active Tasks
- See [$DOCS_PATH/active/]($DOCS_PATH/active/)

## 🐛 Issues
- See [bugs.md](../bugs.md)

## 📚 Documentation
- [Procedures]($DOCS_PATH/procedures/)
- [Examples]($DOCS_PATH/examples/)

---
*Powered by [living-docs](https://github.com/joshwegener/living-docs)*
EOF
    echo -e "${GREEN}✓${NC} Created dashboard"
fi

# Success message
echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}        🎉 Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Configuration:${NC}"
echo "  📁 Documentation: $DOCS_PATH/"
echo "  🤖 AI File: $AI_FILE"
echo "  ⚙️  Methodology: $SPEC_SYSTEM"
echo "  🔄 Updates: $UPDATE_FREQUENCY"
echo ""

# Mode-specific next steps
case $MODE in
    "bootstrap")
        echo -e "${YELLOW}Next steps (Bootstrap Mode):${NC}"
        echo "  1. Add project info to $AI_FILE"
        echo "  2. Track issues in bugs.md"
        echo "  3. Run wizard again for full migration"
        ;;
    "new"|"integrate")
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  1. Edit $AI_FILE with project details"
        echo "  2. Check $DOCS_PATH/current.md dashboard"
        echo "  3. Start documenting in $DOCS_PATH/active/"
        ;;
esac

echo ""
echo -e "${BLUE}Thank you for using living-docs!${NC}"
echo -e "${CYAN}Documentation that stays alive 📚${NC}"