#!/bin/bash
# Test for wizard.sh help output - should not have duplicate Options sections
# This test MUST fail initially (TDD red phase)

set -e

echo "Testing wizard.sh help output for duplicates..."

# Get the help output
HELP_OUTPUT=$(./wizard.sh --help 2>&1)

# Count how many times "Options:" appears
OPTIONS_COUNT=$(echo "$HELP_OUTPUT" | grep -c "^Options:" || true)

# Test: Should only have one "Options:" section
if [ "$OPTIONS_COUNT" -eq 1 ]; then
    echo "✓ Help output has exactly one Options section"
    exit 0
else
    echo "✗ FAIL: Help output has $OPTIONS_COUNT Options sections (expected 1)"
    echo "Help output:"
    echo "$HELP_OUTPUT"
    exit 1
fi