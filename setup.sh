#!/bin/bash

# living-docs Setup Script
# Usage: ./setup.sh [project-name] [project-path]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📚 living-docs Setup Script${NC}"
echo "============================"

# Get project name
PROJECT_NAME=${1:-"my-project"}
PROJECT_PATH=${2:-"./$PROJECT_NAME"}

echo -e "${BLUE}Setting up living-docs for: ${GREEN}$PROJECT_NAME${NC}"
echo ""

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_PATH" ]; then
    mkdir -p "$PROJECT_PATH"
    echo -e "${GREEN}✓${NC} Created project directory"
fi

# Ask for documentation location
echo -e "${BLUE}Where should your documentation live?${NC}"
echo "  1) docs/              (standard)"
echo "  2) .docs/             (hidden standard)"
echo "  3) .claude/docs/      (AI projects with Claude)"
echo "  4) .github/docs/      (GitHub-centric)"
echo "  5) .documentation/    (enterprise)"
echo "  6) Custom path..."
echo ""
read -p "Choice (1-6): " DOC_CHOICE

case $DOC_CHOICE in
    1)
        DOCS_PATH="docs"
        ;;
    2)
        DOCS_PATH=".docs"
        ;;
    3)
        DOCS_PATH=".claude/docs"
        ;;
    4)
        DOCS_PATH=".github/docs"
        ;;
    5)
        DOCS_PATH=".documentation"
        ;;
    6)
        read -p "Enter custom path (e.g., 'my-docs'): " DOCS_PATH
        ;;
    *)
        DOCS_PATH="docs"
        echo -e "${YELLOW}Using default: docs/${NC}"
        ;;
esac

echo -e "${GREEN}✓${NC} Documentation path: ${BLUE}$DOCS_PATH/${NC}"
echo ""

# Ask for project type
echo -e "${BLUE}Is this an AI/Claude project?${NC} (y/n): "
read -r IS_AI_PROJECT

if [[ "$IS_AI_PROJECT" =~ ^[Yy]$ ]]; then
    PROJECT_FILE="CLAUDE.md"
    PROJECT_TYPE="ai"
else
    PROJECT_FILE="PROJECT.md"
    PROJECT_TYPE="standard"
fi

# Ask for spec system
echo -e "${BLUE}Choose your development methodology:${NC}"
echo "  1) GitHub Spec-Kit    (community-driven)"
echo "  2) BMAD Method        (AI-driven development)"
echo "  3) Agent OS           (agent coordination)"
echo "  4) None               (just living-docs)"
echo "  5) Custom             (bring your own)"
echo ""
read -p "Choice (1-5): " SPEC_CHOICE

case $SPEC_CHOICE in
    1)
        SPEC_SYSTEM="github-spec-kit"
        ;;
    2)
        SPEC_SYSTEM="bmad-method"
        ;;
    3)
        SPEC_SYSTEM="agent-os"
        ;;
    4)
        SPEC_SYSTEM="none"
        ;;
    5)
        read -p "Enter custom spec name: " SPEC_SYSTEM
        ;;
    *)
        SPEC_SYSTEM="none"
        ;;
esac

echo -e "${GREEN}✓${NC} Methodology: ${BLUE}$SPEC_SYSTEM${NC}"
echo ""

# Ask about auto-updates
echo -e "${BLUE}Enable auto-updates for spec system?${NC} (y/n): "
read -r AUTO_UPDATE

if [[ "$AUTO_UPDATE" =~ ^[Yy]$ ]]; then
    AUTO_UPDATE_ENABLED="true"
    echo -e "${BLUE}Update frequency:${NC}"
    echo "  1) Daily"
    echo "  2) Weekly"
    echo "  3) Monthly"
    read -p "Choice (1-3): " UPDATE_FREQ
    case $UPDATE_FREQ in
        1) UPDATE_FREQUENCY="daily" ;;
        2) UPDATE_FREQUENCY="weekly" ;;
        3) UPDATE_FREQUENCY="monthly" ;;
        *) UPDATE_FREQUENCY="weekly" ;;
    esac
else
    AUTO_UPDATE_ENABLED="false"
    UPDATE_FREQUENCY="manual"
fi

# Create configuration file
echo -e "${BLUE}Creating configuration...${NC}"
cat > "$PROJECT_PATH/.living-docs.config" << EOF
# living-docs Configuration
version: 1.0
project:
  name: "$PROJECT_NAME"
  type: "$PROJECT_TYPE"
paths:
  docs: "$DOCS_PATH"
  bugs: "bugs.md"
  project_file: "$PROJECT_FILE"
spec_system: "$SPEC_SYSTEM"
auto_update: $AUTO_UPDATE_ENABLED
update_frequency: "$UPDATE_FREQUENCY"
created: $(date +"%Y-%m-%d")
EOF
echo -e "${GREEN}✓${NC} Created .living-docs.config"

# Create directory structure
mkdir -p "$PROJECT_PATH/$DOCS_PATH"/{active,completed,issues,procedures,examples,contributing,templates}
echo -e "${GREEN}✓${NC} Created documentation structure at $DOCS_PATH/"

# Copy and customize templates
if [ "$PROJECT_TYPE" = "ai" ]; then
    cp templates/ai-projects/CLAUDE.md.template "$PROJECT_PATH/$PROJECT_FILE"
else
    cp templates/PROJECT.md.template "$PROJECT_PATH/$PROJECT_FILE"
fi

# Replace variables in templates
sed -i '' "s|{{DOCS_PATH}}|$DOCS_PATH|g" "$PROJECT_PATH/$PROJECT_FILE"
sed -i '' "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$PROJECT_PATH/$PROJECT_FILE"
echo -e "${GREEN}✓${NC} Created $PROJECT_FILE"

# Copy bugs.md
cp templates/bugs.md.template "$PROJECT_PATH/bugs.md"
echo -e "${GREEN}✓${NC} Created bugs.md"

# Create customized dashboard
CURRENT_DATE=$(date +"%B %d, %Y")
cp templates/docs/current.md.template "$PROJECT_PATH/$DOCS_PATH/current.md"
sed -i '' "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$PROJECT_PATH/$DOCS_PATH/current.md"
sed -i '' "s|{{DATE}}|$CURRENT_DATE|g" "$PROJECT_PATH/$DOCS_PATH/current.md"
sed -i '' "s|{{STATUS}}|INITIAL SETUP|g" "$PROJECT_PATH/$DOCS_PATH/current.md"
sed -i '' "s|{{VERSION}}|0.1.0|g" "$PROJECT_PATH/$DOCS_PATH/current.md"
sed -i '' "s|{{DOCS_PATH}}|$DOCS_PATH|g" "$PROJECT_PATH/$DOCS_PATH/current.md"
echo -e "${GREEN}✓${NC} Created dashboard at $DOCS_PATH/current.md"

# Create initial log
cat > "$PROJECT_PATH/$DOCS_PATH/log.md" << EOF
# Development Log

## $CURRENT_DATE
- Project initialized with living-docs framework
- Documentation path: $DOCS_PATH/
- Methodology: $SPEC_SYSTEM
- Configuration: .living-docs.config
EOF
echo -e "${GREEN}✓${NC} Created development log"

# Apply spec system if selected
if [ "$SPEC_SYSTEM" != "none" ] && [ -d "specs/$SPEC_SYSTEM" ]; then
    echo -e "${BLUE}Applying $SPEC_SYSTEM methodology...${NC}"
    if [ -f "specs/$SPEC_SYSTEM/apply.sh" ]; then
        bash "specs/$SPEC_SYSTEM/apply.sh" "$PROJECT_PATH"
        echo -e "${GREEN}✓${NC} Applied $SPEC_SYSTEM"
    fi
fi

# Success message
echo ""
echo -e "${GREEN}🎉 Success!${NC} living-docs has been set up for $PROJECT_NAME"
echo ""
echo -e "${BLUE}Configuration Summary:${NC}"
echo "  📁 Documentation: $DOCS_PATH/"
echo "  📄 Project file: $PROJECT_FILE"
echo "  🔧 Methodology: $SPEC_SYSTEM"
echo "  🔄 Auto-update: $AUTO_UPDATE_ENABLED ($UPDATE_FREQUENCY)"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. cd $PROJECT_PATH"
echo "  2. Edit $PROJECT_FILE with your project details"
echo "  3. Check $DOCS_PATH/current.md for your dashboard"
echo "  4. Start documenting!"
echo ""
echo -e "${GREEN}Documentation that stays alive - wherever you want it!${NC}"