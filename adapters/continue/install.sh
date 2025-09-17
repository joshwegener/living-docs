#!/bin/bash

# Continue.dev Adapter Installation Script
# Simple installation - just copies .continuerules to project root

set -e

PROJECT_ROOT="${1:-.}"
ADAPTER_DIR="$(dirname "$0")"

echo "🚀 Installing Continue.dev rules..."

# Check if .continuerules already exists
if [ -f "$PROJECT_ROOT/.continuerules" ]; then
    echo "⚠️  .continuerules already exists. Creating backup..."
    cp "$PROJECT_ROOT/.continuerules" "$PROJECT_ROOT/.continuerules.backup"
fi

# Copy the rules file
cp "$ADAPTER_DIR/templates/.continuerules" "$PROJECT_ROOT/"

echo "✅ Continue.dev rules installed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit .continuerules to match your project's needs"
echo "2. Continue.dev will automatically use these rules"
echo "3. Restart your IDE if Continue is already running"