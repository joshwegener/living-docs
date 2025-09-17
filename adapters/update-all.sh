#!/bin/bash

# Master Update Script for All Adapters
# Updates all installed spec adapters

set -e

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="${1:-.}"

# Source common update functions
source "$SCRIPT_DIR/common/update.sh"

echo "🚀 Living-Docs Adapter Update Manager"
echo "====================================="
echo ""

# Check for updates first
check_updates "$PROJECT_ROOT"

echo ""
echo "Would you like to update all adapters? [y/N]"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    update_all_adapters "$PROJECT_ROOT"
else
    echo "Update cancelled."
fi