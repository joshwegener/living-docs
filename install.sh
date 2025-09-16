#!/bin/bash
# living-docs Quick Install/Update Script
# Always gets the latest version from GitHub

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}    📚 living-docs Installer/Updater                  ${BLUE}║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Download latest wizard.sh
echo -e "${CYAN}Downloading latest wizard.sh...${NC}"

if curl -L "https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh" -o wizard.sh 2>/dev/null; then
    chmod +x wizard.sh
    echo -e "${GREEN}✓${NC} Downloaded wizard.sh"
else
    echo -e "${RED}✗${NC} Failed to download wizard.sh"
    exit 1
fi

# Download update.sh for future updates
echo -e "${CYAN}Downloading update.sh...${NC}"

if curl -L "https://raw.githubusercontent.com/joshwegener/living-docs/main/update.sh" -o update.sh 2>/dev/null; then
    chmod +x update.sh
    echo -e "${GREEN}✓${NC} Downloaded update.sh"
else
    echo -e "${YELLOW}⚠${NC} Could not download update.sh (optional)"
fi

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""

# Check if this is an update or new install
if [ -f ".living-docs.config" ]; then
    echo -e "${CYAN}Existing living-docs project detected.${NC}"
    echo -e "${CYAN}Run ./wizard.sh to check for updates or reconfigure.${NC}"
else
    echo -e "${CYAN}Run ./wizard.sh to set up living-docs for your project.${NC}"
fi

echo ""
echo -e "${BLUE}For future updates, run:${NC}"
echo "  ./update.sh    # Update everything"
echo "  ./wizard.sh    # Configure or check updates"