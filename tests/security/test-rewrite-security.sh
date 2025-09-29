#!/bin/bash
set -euo pipefail

# Test for path injection vulnerabilities in rewrite.sh

echo "Testing rewrite.sh security..."

# Test 1: Path traversal attempt
export SCRIPTS_PATH="../../etc/passwd"
export SPECS_PATH="/etc/shadow"
export AI_PATH="'; rm -rf /; echo '"

# Source the library
source lib/adapter/rewrite.sh

# Create test file
TEST_FILE=$(mktemp)
echo "scripts/test.sh" > "$TEST_FILE"

# Try to apply rewrites - should sanitize paths
if apply_custom_paths "$TEST_FILE" 2>/dev/null | grep -E "(passwd|shadow|rm -rf)" >/dev/null; then
    echo "FAIL: Path injection vulnerability detected!"
    exit 1
else
    echo "PASS: Path injection protected"
fi

# Test 2: Command injection in sed
export SCRIPTS_PATH='$(whoami)'
if apply_custom_paths "$TEST_FILE" 2>/dev/null | grep -F '$(whoami)' >/dev/null; then
    echo "FAIL: Command injection vulnerability detected!"
    exit 1
else
    echo "PASS: Command injection protected"
fi

rm -f "$TEST_FILE"
echo "All security tests passed"