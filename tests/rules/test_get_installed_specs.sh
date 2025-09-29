#!/bin/bash
set -euo pipefail
# Test: get_installed_specs() function
set -e

# Setup
TEST_CONFIG=$(mktemp)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/../../scripts/rules/rule-loading.sh"

# Test data
cat > "$TEST_CONFIG" << 'EOF'
DOCS_DIR="docs"
INSTALLED_SPECS="spec-kit aider cursor"
BOOTSTRAP_FILE="bootstrap.md"
EOF

# Source the implementation (will fail initially - TDD)
if [ -f "$SOURCE_FILE" ]; then
    source "$SOURCE_FILE"
fi

# Test 1: Parse single framework
echo "Test 1: Single framework..."
echo 'INSTALLED_SPECS="spec-kit"' > "$TEST_CONFIG"
result=$(LIVING_DOCS_CONFIG="$TEST_CONFIG" get_installed_specs)
expected="spec-kit"
if [ "$result" != "$expected" ]; then
    echo "FAIL: Expected '$expected', got '$result'"
    exit 1
fi
echo "PASS"

# Test 2: Parse multiple frameworks
echo "Test 2: Multiple frameworks..."
echo 'INSTALLED_SPECS="spec-kit aider cursor"' > "$TEST_CONFIG"
result=$(LIVING_DOCS_CONFIG="$TEST_CONFIG" get_installed_specs)
expected="spec-kit aider cursor"
if [ "$result" != "$expected" ]; then
    echo "FAIL: Expected '$expected', got '$result'"
    exit 1
fi
echo "PASS"

# Test 3: Handle empty INSTALLED_SPECS
echo "Test 3: Empty INSTALLED_SPECS..."
echo 'INSTALLED_SPECS=""' > "$TEST_CONFIG"
result=$(LIVING_DOCS_CONFIG="$TEST_CONFIG" get_installed_specs)
if [ -n "$result" ]; then
    echo "FAIL: Expected empty, got '$result'"
    exit 1
fi
echo "PASS"

# Test 4: Handle missing config file
echo "Test 4: Missing config file..."
result=$(LIVING_DOCS_CONFIG="/nonexistent/config" get_installed_specs 2>/dev/null)
if [ -n "$result" ]; then
    echo "FAIL: Expected empty for missing config, got '$result'"
    exit 1
fi
echo "PASS"

# Cleanup
rm -f "$TEST_CONFIG"
echo "All tests passed!"