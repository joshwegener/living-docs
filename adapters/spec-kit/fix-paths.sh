#!/bin/bash
# Quick fix for spec-kit v0.0.47 hardcoded paths
# This should be integrated into the installer eventually

echo "Fixing hardcoded paths in spec-kit templates..."

# Fix paths in command files
for file in templates/commands/*.md; do
    if [ -f "$file" ]; then
        echo "  Fixing: $file"
        # On macOS, sed requires -i ''
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's|scripts/bash/|{{SCRIPTS_PATH}}/|g' "$file"
            sed -i '' 's|scripts/powershell/|{{SCRIPTS_PATH}}/powershell/|g' "$file"
        else
            sed -i 's|scripts/bash/|{{SCRIPTS_PATH}}/|g' "$file"
            sed -i 's|scripts/powershell/|{{SCRIPTS_PATH}}/powershell/|g' "$file"
        fi
    fi
done

# Fix paths in template files
for file in templates/*.md; do
    if [ -f "$file" ]; then
        echo "  Fixing: $file"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's|scripts/bash/|{{SCRIPTS_PATH}}/|g' "$file"
            sed -i '' 's|scripts/powershell/|{{SCRIPTS_PATH}}/powershell/|g' "$file"
        else
            sed -i 's|scripts/bash/|{{SCRIPTS_PATH}}/|g' "$file"
            sed -i 's|scripts/powershell/|{{SCRIPTS_PATH}}/powershell/|g' "$file"
        fi
    fi
done

echo "✓ Path fixes applied"
echo ""
echo "Note: These templates use {{SCRIPTS_PATH}} placeholders that will be"
echo "replaced with actual paths during installation by the wizard."