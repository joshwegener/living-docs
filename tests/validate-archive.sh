#!/bin/bash
# Test: Archive functionality validation
# MUST FAIL before implementation (TDD)

set -e

echo "Testing archive functionality..."

# Load config if exists
if [ -f ".living-docs.config" ]; then
    source .living-docs.config
else
    docs_path="docs"  # Default
fi

# Test 1: Archive directory exists
if [ ! -d "$docs_path/archived" ]; then
    echo "❌ FAIL: $docs_path/archived/ directory missing"
    exit 1
fi
echo "✓ Archive directory exists"

# Test 2: Check for old files that should be archived
old_file_count=0
for file in "$docs_path/completed/"*.md; do
    if [ -f "$file" ]; then
        # Check if file date is Sept 14 (our test case for "old" files)
        if echo "$file" | grep -q "2025-09-14"; then
            ((old_file_count++))
        fi
    fi
done

if [ $old_file_count -gt 0 ]; then
    echo "❌ FAIL: Found $old_file_count old files in completed/ that should be archived"
    exit 1
fi
echo "✓ No old files in completed/"

# Test 3: Check archived directory has content
archived_count=$(ls "$docs_path/archived/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$archived_count" -eq 0 ]; then
    echo "⚠️ Warning: Archive directory is empty"
else
    echo "✓ Archive contains $archived_count file(s)"
fi

# Test 4: Verify archived files follow naming convention
for file in "$docs_path/archived/"*.md; do
    if [ -f "$file" ]; then
        basename=$(basename "$file")
        if ! echo "$basename" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-'; then
            echo "❌ FAIL: Archived file doesn't follow date naming: $basename"
            exit 1
        fi
    fi
done
echo "✓ Archived files follow naming convention"

# Test 5: Check if archive script exists
if [ ! -f "scripts/archive-old-work.sh" ]; then
    echo "⚠️ Warning: Archive script not found (scripts/archive-old-work.sh)"
else
    echo "✓ Archive script exists"
fi

echo "✅ All archive tests passed!"