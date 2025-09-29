#!/bin/bash
set -euo pipefail
# Test: Bootstrap content validation
# MUST FAIL before implementation (TDD)

set -e

echo "Testing bootstrap content..."

# Load config if exists
if [ -f ".living-docs.config" ]; then
    source .living-docs.config
else
    docs_path="docs"  # Default
fi

# Test 1: Bootstrap file exists
if [ ! -f ""$docs_path"/bootstrap.md" ]; then
    echo "❌ FAIL: "$docs_path"/bootstrap.md missing"
    exit 1
fi
echo "✓ Bootstrap file exists"

# Test 2: Check for spec-kit references if installed
if [ -f ".living-docs.config" ] && [ -n "$INSTALLED_SPECS" ]; then
    if echo "$INSTALLED_SPECS" | grep -q "spec-kit"; then
        if ! grep -q "spec-kit" ""$docs_path"/bootstrap.md"; then
            echo "❌ FAIL: spec-kit installed but not referenced in bootstrap"
            exit 1
        fi
        echo "✓ spec-kit referenced in bootstrap"

        # Check for specific spec-kit commands
        if ! grep -q "create-new-feature.sh" ""$docs_path"/bootstrap.md"; then
            echo "❌ FAIL: spec-kit commands not documented in bootstrap"
            exit 1
        fi
        echo "✓ spec-kit commands documented"

        # Check for workflow documentation
        if ! grep -qi "spec-kit workflow\|/plan\|/tasks" ""$docs_path"/bootstrap.md"; then
            echo "❌ FAIL: spec-kit workflow not documented in bootstrap"
            exit 1
        fi
        echo "✓ spec-kit workflow documented"
    fi

    # Check for other installed specs
    for spec in $INSTALLED_SPECS; do
        if [ "$spec" != "spec-kit" ]; then
            if ! grep -q "$spec" ""$docs_path"/bootstrap.md"; then
                echo "⚠️ Warning: "$spec" installed but not referenced in bootstrap"
            else
                echo "✓ "$spec" referenced in bootstrap"
            fi
        fi
    done
else
    echo "⚠️ No config found - skipping installed spec checks"
fi

# Test 3: Check for critical sections
required_sections=(
    "CRITICAL_CHECKLIST"
    "Project Dashboard"
    "Documentation Structure"
    "WORKFLOW GATES"
)

for section in "${required_sections[@]}"; do
    if ! grep -q "$section" ""$docs_path"/bootstrap.md"; then
        echo "❌ FAIL: Required section missing: $section"
        exit 1
    fi
    echo "✓ Section found: $section"
done

# Test 4: Check for installed frameworks section
if [ -f ".living-docs.config" ] && [ -n "$INSTALLED_SPECS" ]; then
    if ! grep -q "Installed.*Frameworks\|Available Commands" ""$docs_path"/bootstrap.md"; then
        echo "❌ FAIL: No 'Installed Frameworks' or 'Available Commands' section in bootstrap"
        exit 1
    fi
    echo "✓ Installed frameworks section exists"
fi

echo "✅ All bootstrap tests passed!"