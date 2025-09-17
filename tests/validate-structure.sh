#!/bin/bash
# Test: Directory structure validation
# MUST FAIL before implementation (TDD)

set -e

echo "Testing directory structure..."

# Load config if exists
if [ -f ".living-docs.config" ]; then
    source .living-docs.config
else
    docs_path="docs"  # Default
fi

# Test 1: Specs should be in docs/specs not root
if [ -d "specs" ]; then
    echo "❌ FAIL: specs/ exists in root (should be in $docs_path/specs/)"
    exit 1
fi
echo "✓ No specs/ in root"

if [ ! -d "$docs_path/specs" ]; then
    echo "❌ FAIL: $docs_path/specs/ directory missing"
    exit 1
fi
echo "✓ $docs_path/specs/ exists"

# Test 2: Required directories exist
for dir in active completed archived procedures; do
    if [ ! -d "$docs_path/$dir" ]; then
        echo "❌ FAIL: $docs_path/$dir/ directory missing"
        exit 1
    fi
    echo "✓ $docs_path/$dir/ exists"
done

# Test 3: Required files exist
for file in current.md bootstrap.md; do
    if [ ! -f "$docs_path/$file" ]; then
        echo "❌ FAIL: $docs_path/$file missing"
        exit 1
    fi
    echo "✓ $docs_path/$file exists"
done

# Test 4: Check if specs are in correct location
spec_count=$(ls "$docs_path/specs/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$spec_count" -eq 0 ]; then
    echo "⚠️ Warning: No specs found in $docs_path/specs/"
else
    echo "✓ $spec_count spec(s) in correct location"
fi

# Test 5: Verify no broken references in current.md
if grep -q "specs/" "$docs_path/current.md" 2>/dev/null; then
    if ! grep -q "docs/specs/" "$docs_path/current.md" 2>/dev/null; then
        echo "❌ FAIL: current.md has references to specs/ instead of docs/specs/"
        exit 1
    fi
fi
echo "✓ current.md references are correct"

echo "✅ All structure tests passed!"