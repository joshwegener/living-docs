#!/bin/bash
# living-docs Update Script - Keeps everything current
set -euo pipefail

# Version of this update script
UPDATE_SCRIPT_VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# GitHub repository
REPO="joshwegener/living-docs"
BRANCH="main"

# Function: Compare versions (semantic versioning)
version_compare() {
    local ver1="$1"
    local ver2="$2"

    # Convert to comparable format
    local v1_major=$(echo "$ver1" | cut -d. -f1)
    local v1_minor=$(echo "$ver1" | cut -d. -f2)
    local v1_patch=$(echo "$ver1" | cut -d. -f3)

    local v2_major=$(echo "$ver2" | cut -d. -f1)
    local v2_minor=$(echo "$ver2" | cut -d. -f2)
    local v2_patch=$(echo "$ver2" | cut -d. -f3)

    if [ "$v1_major" -gt "$v2_major" ]; then
        echo "newer"
    elif [ "$v1_major" -lt "$v2_major" ]; then
        echo "older"
    elif [ "$v1_minor" -gt "$v2_minor" ]; then
        echo "newer"
    elif [ "$v1_minor" -lt "$v2_minor" ]; then
        echo "older"
    elif [ "$v1_patch" -gt "$v2_patch" ]; then
        echo "newer"
    elif [ "$v1_patch" -lt "$v2_patch" ]; then
        echo "older"
    else
        echo "equal"
    fi
}

# Function: Get latest version from GitHub
get_latest_version() {
    local file="$1"
    local url="https://raw.githubusercontent.com/$REPO/$BRANCH/$file"

    # Try to extract version from file
    curl -sL "$url" | grep -E "^(WIZARD_VERSION|UPDATE_SCRIPT_VERSION|VERSION)" | head -1 | cut -d'"' -f2 || echo "0.0.0"
}

# Function: Download file from GitHub
download_file() {
    local file="$1"
    local target="${2:-$file}"
    local url="https://raw.githubusercontent.com/$REPO/$BRANCH/$file"

    echo -e "${CYAN}Downloading $file...${NC}"
    if curl -sL "$url" -o "$target.tmp"; then
        mv "$target.tmp" "$target"
        chmod +x "$target" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Updated $target"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to download $file"
        rm -f "$target.tmp"
        return 1
    fi
}

# Function: Update wizard.sh
update_wizard() {
    echo -e "${BLUE}Checking wizard.sh...${NC}"

    # Check if wizard.sh exists locally
    if [ ! -f "wizard.sh" ]; then
        echo -e "${YELLOW}wizard.sh not found locally${NC}"
        download_file "wizard.sh" "wizard.sh"
        return
    fi

    # Get current version
    local current_version=$(grep "^WIZARD_VERSION=" wizard.sh 2>/dev/null | cut -d'"' -f2 || echo "0.0.0")
    local latest_version=$(get_latest_version "wizard.sh")

    local comparison=$(version_compare "$latest_version" "$current_version")

    if [ "$comparison" = "newer" ]; then
        echo -e "${YELLOW}New version available:${NC} $current_version → $latest_version"

        # Backup current wizard
        cp wizard.sh wizard.sh.bak

        if download_file "wizard.sh" "wizard.sh"; then
            echo -e "${GREEN}✓${NC} wizard.sh updated successfully"
        else
            mv wizard.sh.bak wizard.sh
            echo -e "${RED}✗${NC} Update failed, restored backup"
        fi
    else
        echo -e "${GREEN}✓${NC} wizard.sh is up to date (v$current_version)"
    fi
}

# Function: Update spec-kit templates
update_spec_kit() {
    echo -e "${BLUE}Checking spec-kit templates...${NC}"

    # Check if spec-kit is in use
    if [ ! -f ".living-docs.config" ]; then
        echo -e "${YELLOW}No .living-docs.config found${NC}"
        return
    fi

    local spec_system=$(grep "^spec_system:" .living-docs.config | cut -d'"' -f2)

    if [ "$spec_system" != "github-spec-kit" ]; then
        echo -e "${CYAN}Spec-kit not in use${NC}"
        return
    fi

    local spec_location=$(grep "^spec_location:" .living-docs.config | cut -d'"' -f2 || echo ".github")
    spec_location="${spec_location:-.github}"

    echo -e "${CYAN}Updating spec-kit in $spec_location...${NC}"

    # Create adapter directory structure
    mkdir -p adapters/spec-kit/templates

    # Download latest spec-kit adapter
    download_file "adapters/spec-kit.sh" "adapters/spec-kit.sh"

    # Template files to update
    local templates=(
        "CODE_OF_CONDUCT.md"
        "CONTRIBUTING.md"
        "SECURITY.md"
        "pull_request_template.md"
        "ISSUE_TEMPLATE/bug_report.md"
        "ISSUE_TEMPLATE/feature_request.md"
        "ISSUE_TEMPLATE/config.yml"
    )

    # Download templates to adapter directory
    for template in "${templates[@]}"; do
        local template_path="adapters/spec-kit/templates/$template"
        local template_dir=$(dirname "$template_path")
        mkdir -p "$template_dir"
        download_file "adapters/spec-kit/templates/$template" "$template_path"
    done

    # Update version.json
    download_file "adapters/spec-kit/version.json" "adapters/spec-kit/version.json"

    # Copy to project location if different from templates
    echo -e "${CYAN}Syncing to $spec_location...${NC}"
    for template in "${templates[@]}"; do
        local src="adapters/spec-kit/templates/$template"
        local dst="$spec_location/$template"
        local dst_dir=$(dirname "$dst")

        if [ -f "$src" ]; then
            mkdir -p "$dst_dir"
            cp "$src" "$dst"
            echo -e "${GREEN}✓${NC} Updated $dst"
        fi
    done
}

# Function: Update documentation structure
update_docs_structure() {
    echo -e "${BLUE}Checking documentation structure...${NC}"

    if [ ! -f ".living-docs.config" ]; then
        return
    fi

    local docs_path=$(grep "^  docs:" .living-docs.config | cut -d'"' -f2 || echo "docs")
    docs_path="${docs_path:-docs}"

    # Ensure all required directories exist
    local required_dirs=(
        "$docs_path/active"
        "$docs_path/completed"
        "$docs_path/issues"
        "$docs_path/procedures"
    )

    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo -e "${GREEN}✓${NC} Created $dir"
        fi
    done

    # Update bootstrap.md if it exists
    if [ -f "$docs_path/bootstrap.md" ]; then
        local temp_bootstrap="/tmp/bootstrap.md.new"
        if download_file "templates/bootstrap.md" "$temp_bootstrap" 2>/dev/null; then
            # Check if significantly different
            if ! diff -q "$docs_path/bootstrap.md" "$temp_bootstrap" >/dev/null 2>&1; then
                echo -e "${YELLOW}New bootstrap.md template available${NC}"
                echo "Keep your current version? (y/n)"
                read -p "> " keep_current

                if [ "$keep_current" != "y" ]; then
                    cp "$docs_path/bootstrap.md" "$docs_path/bootstrap.md.bak"
                    mv "$temp_bootstrap" "$docs_path/bootstrap.md"
                    echo -e "${GREEN}✓${NC} Updated bootstrap.md (backup saved)"
                fi
            fi
            rm -f "$temp_bootstrap"
        fi
    fi
}

# Function: Update helper scripts
update_scripts() {
    echo -e "${BLUE}Checking helper scripts...${NC}"

    # Scripts to update
    local scripts=(
        "scripts/check-drift.sh"
        "scripts/pre-commit"
    )

    for script in "${scripts[@]}"; do
        local script_dir=$(dirname "$script")

        if [ -f "$script" ] || [ -d "$script_dir" ]; then
            mkdir -p "$script_dir"
            if download_file "$script" "$script"; then
                chmod +x "$script"
            fi
        fi
    done
}

# Function: Self-update this script
self_update() {
    echo -e "${BLUE}Checking for update.sh updates...${NC}"

    local current_version="$UPDATE_SCRIPT_VERSION"
    local latest_version=$(get_latest_version "update.sh")

    local comparison=$(version_compare "$latest_version" "$current_version")

    if [ "$comparison" = "newer" ]; then
        echo -e "${YELLOW}New update.sh version available:${NC} $current_version → $latest_version"

        # Download new version
        if download_file "update.sh" "update.sh.new"; then
            chmod +x update.sh.new
            echo -e "${GREEN}✓${NC} Downloaded new update.sh"
            echo -e "${CYAN}Restarting with new version...${NC}"
            exec ./update.sh.new "$@"
        fi
    else
        echo -e "${GREEN}✓${NC} update.sh is current (v$current_version)"
    fi
}

# Main execution
echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}    📚 living-docs Update System                      ${BLUE}║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Check what to update
if [ "${1:-}" = "--self" ]; then
    self_update
    exit 0
fi

# Full update process
echo -e "${CYAN}Starting update check...${NC}"
echo ""

# 1. Self-update first
self_update

# 2. Update wizard
update_wizard

# 3. Update spec-kit if in use
update_spec_kit

# 4. Update documentation structure
update_docs_structure

# 5. Update helper scripts
update_scripts

echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Update check complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

# Show next steps if this was first update
if [ ! -f ".living-docs.config" ]; then
    echo ""
    echo -e "${CYAN}To set up living-docs, run:${NC}"
    echo "  ./wizard.sh"
fi