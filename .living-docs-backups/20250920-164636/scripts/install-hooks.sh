#!/bin/bash
# Install git hooks for living-docs

echo "Installing git hooks..."

# Set git to use our hooks directory
git config core.hooksPath .githooks

echo "✓ Git hooks installed"
echo ""
echo "Hooks installed:"
echo "  - pre-commit: Checks for documentation drift"
echo ""
echo "To disable: git config --unset core.hooksPath"