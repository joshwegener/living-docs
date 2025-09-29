#!/bin/bash
set -euo pipefail

# Cursor Adapter Installation Script
# Simple installation - just copies .cursorrules to project root

set -e

PROJECT_ROOT="${1:-.}"
ADAPTER_DIR="$(dirname "$0")"

echo "🎯 Installing Cursor rules..."

# Check if .cursorrules already exists
if [ -f "$PROJECT_ROOT/.cursorrules" ]; then
    echo "⚠️  .cursorrules already exists. Creating backup..."
    cp "$PROJECT_ROOT/.cursorrules" "$PROJECT_ROOT/.cursorrules.backup"
fi

# Copy the rules file
cp "$ADAPTER_DIR/templates/.cursorrules" "$PROJECT_ROOT/"

echo "✅ Cursor rules installed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit .cursorrules to match your project's needs"
echo "2. Restart Cursor to load the new rules"
echo "3. The rules will automatically apply to AI assistance"