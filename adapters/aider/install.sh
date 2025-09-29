#!/bin/bash
set -euo pipefail

# Aider Adapter Installation Script
# Simple installation - just copies CONVENTIONS.md to project root

set -e

PROJECT_ROOT="${1:-.}"
ADAPTER_DIR="$(dirname "$0")"

echo "📝 Installing Aider conventions..."

# Check if CONVENTIONS.md already exists
if [ -f "$PROJECT_ROOT/CONVENTIONS.md" ]; then
    echo "⚠️  CONVENTIONS.md already exists. Creating backup..."
    cp "$PROJECT_ROOT/CONVENTIONS.md" "$PROJECT_ROOT/CONVENTIONS.md.backup"
fi

# Copy the conventions file
cp "$ADAPTER_DIR/templates/CONVENTIONS.md" "$PROJECT_ROOT/"

echo "✅ Aider conventions installed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit CONVENTIONS.md to match your project's needs"
echo "2. Run aider with: aider --read CONVENTIONS.md"
echo "3. Or add to .aider.conf.yml for automatic loading"