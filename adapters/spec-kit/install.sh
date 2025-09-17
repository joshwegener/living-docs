#!/bin/bash

# Spec-Kit Adapter Installation Script
# Installs GitHub's specification-driven development toolkit with path rewriting

set -e

PROJECT_ROOT="${1:-.}"
ADAPTER_DIR="$(dirname "$0")"

# Source path rewriting functions
source "$ADAPTER_DIR/../common/path-rewrite.sh"

echo "📋 Installing GitHub Spec-Kit..."

# Load configuration if it exists
if [ -f "$PROJECT_ROOT/.living-docs.config" ]; then
    source "$PROJECT_ROOT/.living-docs.config"
fi

# Set default paths if not configured
LIVING_DOCS_PATH="${LIVING_DOCS_PATH:-docs}"
AI_PATH="${AI_PATH:-$LIVING_DOCS_PATH}"
SPECS_PATH="${SPECS_PATH:-$LIVING_DOCS_PATH/specs}"
MEMORY_PATH="${MEMORY_PATH:-$LIVING_DOCS_PATH/memory}"
SCRIPTS_PATH="${SCRIPTS_PATH:-$LIVING_DOCS_PATH/scripts}"

echo "  Using paths:"
echo "    Specs: $SPECS_PATH"
echo "    Memory: $MEMORY_PATH"
echo "    Scripts: $SCRIPTS_PATH"

# Create temporary directory for processing
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy templates to temp directory
cp -r "$ADAPTER_DIR/templates/"* "$TEMP_DIR/"

# Rewrite paths in all files
echo "  Rewriting paths for your configuration..."
rewrite_directory "$TEMP_DIR" "$LIVING_DOCS_PATH" "$AI_PATH" "$SPECS_PATH" "$MEMORY_PATH" "$SCRIPTS_PATH"

# Create target directories
mkdir -p "$PROJECT_ROOT/$SPECS_PATH"
mkdir -p "$PROJECT_ROOT/$MEMORY_PATH"
mkdir -p "$PROJECT_ROOT/$SCRIPTS_PATH"

# Copy memory files
if [ -d "$TEMP_DIR/memory" ]; then
    echo "  Installing memory templates..."
    cp -r "$TEMP_DIR/memory/"* "$PROJECT_ROOT/$MEMORY_PATH/" 2>/dev/null || true
fi

# Copy scripts
if [ -d "$TEMP_DIR/scripts" ]; then
    echo "  Installing scripts..."
    cp -r "$TEMP_DIR/scripts/"* "$PROJECT_ROOT/$SCRIPTS_PATH/" 2>/dev/null || true
    # Make scripts executable
    chmod +x "$PROJECT_ROOT/$SCRIPTS_PATH/"*.sh 2>/dev/null || true
fi

# Copy GitHub templates if they exist
if [ -d "$TEMP_DIR/.github" ]; then
    echo "  Installing GitHub templates..."
    mkdir -p "$PROJECT_ROOT/.github"
    cp -r "$TEMP_DIR/.github/"* "$PROJECT_ROOT/.github/" 2>/dev/null || true
fi

# Create initial spec if none exists
if [ ! "$(ls -A $PROJECT_ROOT/$SPECS_PATH 2>/dev/null)" ]; then
    echo "  Creating example specification..."
    "$PROJECT_ROOT/$SCRIPTS_PATH/create-new-feature.sh" "01" "example-feature" 2>/dev/null || \
        echo "    (Run create-new-feature.sh manually to create your first spec)"
fi

# Update .living-docs.config
if ! grep -q "spec-kit" "$PROJECT_ROOT/.living-docs.config" 2>/dev/null; then
    echo "INSTALLED_SPECS=\"${INSTALLED_SPECS} spec-kit\"" >> "$PROJECT_ROOT/.living-docs.config"
    echo "SPEC_KIT_VERSION=\"2.0.0\"" >> "$PROJECT_ROOT/.living-docs.config"
fi

echo "✅ Spec-Kit installed successfully!"
echo ""
echo "Next steps:"
echo "1. Review $MEMORY_PATH/constitution.md"
echo "2. Create new features with: $SCRIPTS_PATH/create-new-feature.sh"
echo "3. Start with specs in $SPECS_PATH/"
echo ""
echo "Quick start:"
echo "  cd $SPECS_PATH && ls"