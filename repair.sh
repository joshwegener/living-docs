#!/bin/bash

# living-docs Documentation Repair System
# For adding living-docs to existing (brownfield) projects
# Usage: ./repair.sh [project-path]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔧 living-docs Documentation Repair System${NC}"
echo "==========================================="
echo ""

# Get project path
PROJECT_PATH=${1:-"."}
cd "$PROJECT_PATH"

echo -e "${CYAN}Analyzing existing documentation...${NC}"
echo ""

# Auto-discovery functions
detect_methodology() {
    local methodology="unknown"

    # Check for BMAD Method
    if [ -f "PRD.md" ] || [ -f "architecture.md" ] || [ -d "agents" ]; then
        methodology="bmad-method"
    # Check for Agent OS
    elif [ -f "agent-config.yaml" ] || [ -d "standards" ]; then
        methodology="agent-os"
    # Check for GitHub Spec-Kit
    elif [ -d ".github/ISSUE_TEMPLATE" ] || [ -d ".github/workflows" ]; then
        methodology="github-spec-kit"
    # Check for existing living-docs
    elif [ -f ".living-docs.config" ]; then
        methodology="living-docs"
        echo -e "${GREEN}✓${NC} Already using living-docs!"
        exit 0
    fi

    echo "$methodology"
}

# Scan existing documentation
scan_docs() {
    local found_items=""

    [ -f "README.md" ] && found_items="${found_items}✓ Found README.md\n"
    [ -f "CONTRIBUTING.md" ] && found_items="${found_items}✓ Found CONTRIBUTING.md\n"
    [ -d "docs" ] && found_items="${found_items}✓ Found docs/ directory\n"
    [ -d ".github" ] && found_items="${found_items}✓ Found .github/ directory\n"
    [ -f "CLAUDE.md" ] && found_items="${found_items}✓ Found CLAUDE.md (AI instructions)\n"
    [ -f "TODO.md" ] && found_items="${found_items}✓ Found TODO.md\n"
    [ -f "CHANGELOG.md" ] && found_items="${found_items}✓ Found CHANGELOG.md\n"

    echo -e "$found_items"
}

# Main discovery
echo -e "${CYAN}Discovered files:${NC}"
scan_docs

DETECTED_METHOD=$(detect_methodology)
echo -e "${CYAN}Detected methodology:${NC} ${YELLOW}$DETECTED_METHOD${NC}"
echo ""

# Choose repair mode
echo -e "${BLUE}Choose repair mode:${NC}"
echo "  1) Quick Bootstrap    (adds living-docs on top, minimal changes)"
echo "  2) Full Migration     (reorganizes documentation structure)"
echo "  3) Analyze Only       (see recommendations without changes)"
echo ""
read -p "Choice (1-3): " REPAIR_MODE

# Choose AI assistant
echo ""
echo -e "${BLUE}Which AI assistant do you primarily use?${NC}"
echo "  1) Claude (Anthropic)"
echo "  2) ChatGPT (OpenAI)"
echo "  3) GitHub Copilot"
echo "  4) Cursor AI"
echo "  5) JetBrains AI"
echo "  6) Multiple/All (creates AI.md)"
echo ""
read -p "Choice (1-6): " AI_CHOICE

case $AI_CHOICE in
    1) AI_FILE="CLAUDE.md" ;;
    2) AI_FILE="OPENAI.md" ;;
    3) AI_FILE="COPILOT.md" ;;
    4) AI_FILE="CURSOR.md" ;;
    5) AI_FILE="JETBRAINS.md" ;;
    6) AI_FILE="AI.md" ;;
    *) AI_FILE="AI.md" ;;
esac

# Documentation location
echo ""
echo -e "${BLUE}Where should living-docs documentation live?${NC}"
echo "  1) docs/              (standard)"
echo "  2) .docs/             (hidden)"
echo "  3) .claude/docs/      (AI-specific)"
echo "  4) .github/docs/      (GitHub-centric)"
echo "  5) Keep existing structure"
echo ""
read -p "Choice (1-5): " DOCS_CHOICE

case $DOCS_CHOICE in
    1) DOCS_PATH="docs" ;;
    2) DOCS_PATH=".docs" ;;
    3) DOCS_PATH=".claude/docs" ;;
    4) DOCS_PATH=".github/docs" ;;
    5) DOCS_PATH=$([ -d "docs" ] && echo "docs" || echo "docs") ;;
    *) DOCS_PATH="docs" ;;
esac

# Execute based on mode
case $REPAIR_MODE in
    1)  # Quick Bootstrap
        echo ""
        echo -e "${GREEN}Applying Quick Bootstrap...${NC}"

        # Create minimal config
        cat > .living-docs.config << EOF
# living-docs Configuration (Bootstrap Mode)
version: 1.0
mode: bootstrap
project:
  name: "$(basename "$PWD")"
  type: "brownfield"
paths:
  docs: "$DOCS_PATH"
  bugs: "bugs.md"
  ai_file: "$AI_FILE"
methodology:
  detected: "$DETECTED_METHOD"
  using: "living-docs-overlay"
created: $(date +"%Y-%m-%d")
EOF
        echo -e "${GREEN}✓${NC} Created .living-docs.config"

        # Create AI guidance file with bootstrap
        if [ ! -f "$AI_FILE" ]; then
            cat > "$AI_FILE" << 'EOF'
# AI Assistant Guidelines

## Documentation System
This project uses [living-docs](https://github.com/joshwegener/living-docs) for documentation management.

@.living-docs-guide.md

## Project-Specific Instructions
<!-- Add your project-specific AI instructions below -->

### Project Overview
[Add project description]

### Development Guidelines
[Add development rules]

### Key Files
- `bugs.md` - Quick issue tracking
- `$DOCS_PATH/` - Documentation (if organized)

---
*This file was bootstrapped by living-docs. Add project-specific instructions above.*
EOF
            echo -e "${GREEN}✓${NC} Created $AI_FILE with living-docs bootstrap"
        else
            # Append to existing file
            echo "" >> "$AI_FILE"
            echo "## living-docs Integration" >> "$AI_FILE"
            echo "@.living-docs-guide.md" >> "$AI_FILE"
            echo -e "${GREEN}✓${NC} Updated existing $AI_FILE"
        fi

        # Create bugs.md if doesn't exist
        if [ ! -f "bugs.md" ]; then
            cp "$(dirname "$0")/templates/bugs.md.template" bugs.md 2>/dev/null || \
            cat > bugs.md << 'EOF'
# Quick Bug Tracker

## Open Issues
- [ ] Add your first bug here

## Completed ✅
<!-- Move completed items here with date -->

---
*Promote to $DOCS_PATH/issues/ when investigation needed*
EOF
            echo -e "${GREEN}✓${NC} Created bugs.md"
        fi

        # Create bootstrap guide
        cat > .living-docs-guide.md << 'EOF'
# living-docs Quick Reference

## Core Workflow
1. Track bugs in `bugs.md`
2. When ready, organize docs in `$DOCS_PATH/`
3. Use temporal organization (date completed work)

## Documentation Structure (When Ready)
```
$DOCS_PATH/
├── current.md    # Dashboard
├── active/       # Current work
├── completed/    # Dated completions
└── procedures/   # How-to guides
```

## Git Discipline
- Commit every 30 minutes
- Use meaningful messages
- Tag stable versions

## Getting Started
Run `living-docs migrate` when ready for full organization.
EOF
        echo -e "${GREEN}✓${NC} Created .living-docs-guide.md"

        echo ""
        echo -e "${GREEN}🎉 Bootstrap Complete!${NC}"
        echo ""
        echo "Added:"
        echo "  📄 $AI_FILE (AI instructions)"
        echo "  🐛 bugs.md (issue tracking)"
        echo "  ⚙️  .living-docs.config"
        echo "  📚 .living-docs-guide.md"
        echo ""
        echo "Next steps:"
        echo "  1. Add project-specific instructions to $AI_FILE"
        echo "  2. Start tracking issues in bugs.md"
        echo "  3. Run 'living-docs migrate' when ready for full structure"
        ;;

    2)  # Full Migration
        echo ""
        echo -e "${YELLOW}Full Migration - Coming Soon!${NC}"
        echo "This will:"
        echo "  • Reorganize existing docs"
        echo "  • Create dashboard at $DOCS_PATH/current.md"
        echo "  • Extract TODOs to $DOCS_PATH/active/"
        echo "  • Archive old structure"
        echo ""
        echo "For now, use Bootstrap mode."
        ;;

    3)  # Analyze Only
        echo ""
        echo -e "${CYAN}Analysis Complete${NC}"
        echo ""
        echo "Recommendations:"
        echo "  • Use Bootstrap mode to start"
        echo "  • Track new issues in bugs.md"
        echo "  • Gradually migrate to full structure"
        ;;
esac

echo ""
echo -e "${BLUE}Documentation repair complete!${NC}"