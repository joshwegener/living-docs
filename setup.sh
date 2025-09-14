#!/bin/bash

# living-docs Setup Script
# Usage: ./setup.sh [project-name] [project-path]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📚 living-docs Setup Script${NC}"
echo "================================"

# Get project name
PROJECT_NAME=${1:-"my-project"}
PROJECT_PATH=${2:-"./$PROJECT_NAME"}

echo -e "${BLUE}Setting up living-docs for: ${GREEN}$PROJECT_NAME${NC}"

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_PATH" ]; then
    mkdir -p "$PROJECT_PATH"
    echo -e "${GREEN}✓${NC} Created project directory"
fi

# Copy structure
cp -r templates/docs "$PROJECT_PATH/"
echo -e "${GREEN}✓${NC} Created docs structure"

# Determine project type
echo -e "${BLUE}Is this an AI/Claude project? (y/n):${NC} "
read -r IS_AI_PROJECT

if [[ "$IS_AI_PROJECT" =~ ^[Yy]$ ]]; then
    cp templates/ai-projects/CLAUDE.md.template "$PROJECT_PATH/CLAUDE.md"
    echo -e "${GREEN}✓${NC} Created CLAUDE.md for AI project"
else
    cp templates/PROJECT.md.template "$PROJECT_PATH/PROJECT.md"
    echo -e "${GREEN}✓${NC} Created PROJECT.md for standard project"
fi

# Copy bugs.md
cp templates/bugs.md.template "$PROJECT_PATH/bugs.md"
echo -e "${GREEN}✓${NC} Created bugs.md"

# Customize current.md
CURRENT_DATE=$(date +"%B %d, %Y")
sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$PROJECT_PATH/docs/current.md.template"
sed -i '' "s/{{DATE}}/$CURRENT_DATE/g" "$PROJECT_PATH/docs/current.md.template"
sed -i '' "s/{{STATUS}}/INITIAL SETUP/g" "$PROJECT_PATH/docs/current.md.template"
sed -i '' "s/{{VERSION}}/0.1.0/g" "$PROJECT_PATH/docs/current.md.template"
mv "$PROJECT_PATH/docs/current.md.template" "$PROJECT_PATH/docs/current.md"
echo -e "${GREEN}✓${NC} Customized dashboard"

# Create initial directories
mkdir -p "$PROJECT_PATH/docs/"{active,completed,issues,procedures,examples,contributing,templates}
echo -e "${GREEN}✓${NC} Created documentation directories"

# Create initial log
echo "# Development Log" > "$PROJECT_PATH/docs/log.md"
echo "" >> "$PROJECT_PATH/docs/log.md"
echo "## $CURRENT_DATE" >> "$PROJECT_PATH/docs/log.md"
echo "- Project initialized with living-docs framework" >> "$PROJECT_PATH/docs/log.md"
echo -e "${GREEN}✓${NC} Created development log"

# Success message
echo ""
echo -e "${GREEN}🎉 Success!${NC} living-docs has been set up for $PROJECT_NAME"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_PATH"
echo "  2. Edit PROJECT.md or CLAUDE.md with your project details"
echo "  3. Check docs/current.md for your project dashboard"
echo "  4. Start documenting!"
echo ""
echo -e "${BLUE}Documentation that stays alive!${NC}"