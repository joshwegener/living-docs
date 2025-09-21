#!/bin/bash

# Check for updates to adapters from their source repositories
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Adapter repository mappings (using portable format)
# Format: adapter_name:repo_path
ADAPTER_REPOS="
spec-kit:github/spec-kit
bmad-method:bmad-code-org/BMAD-METHOD
agent-os:buildermethods/agent-os
aider:Aider-AI/conventions
cursor:cursor/rules
continue:continue/rules
"

# Function: Check GitHub for latest release/commit
check_github_version() {
    local repo="$1"
    local adapter="$2"

    # Try to get latest release first
    local latest_release=$(curl -s "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -n "$latest_release" ]; then
        echo "$latest_release"
    else
        # Fall back to latest commit
        local latest_commit=$(curl -s "https://api.github.com/repos/$repo/commits/main" 2>/dev/null | grep '"sha":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/' | cut -c1-7)
        if [ -n "$latest_commit" ]; then
            echo "commit-$latest_commit"
        else
            echo "unknown"
        fi
    fi
}

# Function: Check local adapter version
check_local_version() {
    local adapter="$1"
    local adapter_dir="$(dirname "$0")/$adapter"

    if [ -f "$adapter_dir/config.yml" ]; then
        # Look for upstream_version first, fall back to version
        local upstream=$(grep "upstream_version:" "$adapter_dir/config.yml" | cut -d: -f2 | tr -d ' ' | cut -d'#' -f1)
        if [ -n "$upstream" ] && [ "$upstream" != "none" ]; then
            echo "$upstream"
        else
            grep "version:" "$adapter_dir/config.yml" | head -1 | cut -d: -f2 | tr -d ' ' | cut -d'#' -f1
        fi
    else
        echo "not-installed"
    fi
}

# Function: Check for adapter updates
check_adapter_updates() {
    echo -e "${CYAN}🔍 Checking for Adapter Updates${NC}"
    echo ""

    local updates_available=false

    # Parse adapter repos into arrays
    while IFS= read -r line; do
        [ -z "$line" ] && continue

        local adapter="${line%%:*}"
        local repo="${line#*:}"
        local local_version=$(check_local_version "$adapter")

        if [ "$local_version" = "not-installed" ]; then
            continue
        fi

        echo -n "Checking $adapter... "

        # Special handling for adapters without official repos
        if [[ "$repo" == "cursor/rules" || "$repo" == "continue/rules" ]]; then
            echo -e "${GREEN}✓${NC} (No upstream repo to check)"
            continue
        fi

        local remote_version=$(check_github_version "$repo" "$adapter")

        if [ "$remote_version" = "unknown" ]; then
            echo -e "${YELLOW}⚠${NC} Could not check remote version"
        elif [ "$remote_version" != "$local_version" ]; then
            echo -e "${YELLOW}Update available:${NC} $local_version → $remote_version"
            updates_available=true
        else
            echo -e "${GREEN}✓${NC} Up to date ($local_version)"
        fi
    done <<< "$ADAPTER_REPOS"

    echo ""

    if [ "$updates_available" = true ]; then
        echo -e "${YELLOW}Updates are available!${NC}"
        echo "Run './adapters/update-all.sh' to update adapters"
    else
        echo -e "${GREEN}All adapters are up to date!${NC}"
    fi
}

# Function: Check living-docs core updates
check_core_updates() {
    echo -e "${CYAN}🔍 Checking for Living-Docs Core Updates${NC}"
    echo ""

    local REPO="joshwegener/living-docs"

    # Check wizard.sh
    if [ -f "wizard.sh" ]; then
        local current_version=$(grep "^WIZARD_VERSION=" wizard.sh | cut -d'"' -f2 || echo "0.0.0")
        local latest_version=$(curl -sL "https://raw.githubusercontent.com/$REPO/main/wizard.sh" | grep "^WIZARD_VERSION=" | cut -d'"' -f2 || echo "0.0.0")

        if [ "$latest_version" != "$current_version" ]; then
            echo -e "${YELLOW}wizard.sh update available:${NC} $current_version → $latest_version"
        else
            echo -e "${GREEN}wizard.sh:${NC} Up to date ($current_version)"
        fi
    fi

    # Check update.sh
    if [ -f "update.sh" ]; then
        local current_version=$(grep "^UPDATE_SCRIPT_VERSION=" update.sh | cut -d'"' -f2 || echo "0.0.0")
        local latest_version=$(curl -sL "https://raw.githubusercontent.com/$REPO/main/update.sh" | grep "^UPDATE_SCRIPT_VERSION=" | cut -d'"' -f2 || echo "0.0.0")

        if [ "$latest_version" != "$current_version" ]; then
            echo -e "${YELLOW}update.sh update available:${NC} $current_version → $latest_version"
        else
            echo -e "${GREEN}update.sh:${NC} Up to date ($current_version)"
        fi
    fi

    echo ""
}

# Main execution
main() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}       Living-Docs Update Check${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    check_core_updates
    check_adapter_updates

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

# Export functions for use in other scripts
export -f check_github_version
export -f check_local_version
export -f check_adapter_updates
export -f check_core_updates