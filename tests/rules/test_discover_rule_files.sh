#!/bin/bash
set -euo pipefail
# Test: discover_rule_files() function
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/../../scripts/rules/rule-loading.sh"
TEST_RULES_DIR=$(mktemp -d)

# Source the implementation (will fail initially - TDD)
if [ -f "$SOURCE_FILE" ]; then
    source "$SOURCE_FILE"
fi

# Test 1: Discover single rule file
echo "Test 1: Single rule file..."
mkdir -p "$TEST_RULES_DIR/docs/rules"
touch "$TEST_RULES_DIR/docs/rules/spec-kit-rules.md"
cd "$TEST_RULES_DIR"
result=$(discover_rule_files "spec-kit")
expected="docs/rules/spec-kit-rules.md"
if [ "$result" != "$expected" ]; then
    echo "FAIL: Expected '$expected', got '$result'"
    exit 1
fi
echo "PASS"

# Test 2: Discover multiple rule files
echo "Test 2: Multiple rule files..."
touch "$TEST_RULES_DIR/docs/rules/aider-rules.md"
touch "$TEST_RULES_DIR/docs/rules/cursor-rules.md"
result=$(discover_rule_files "spec-kit aider cursor" | sort)
expected=$(echo -e "docs/rules/aider-rules.md\ndocs/rules/cursor-rules.md\ndocs/rules/spec-kit-rules.md")
if [ "$result" != "$expected" ]; then
    echo "FAIL: Expected '$expected', got '$result'"
    exit 1
fi
echo "PASS"

# Test 3: Handle missing rule files
echo "Test 3: Missing rule files..."
rm "$TEST_RULES_DIR/docs/rules/cursor-rules.md"
result=$(discover_rule_files "spec-kit aider cursor" | wc -l | tr -d ' ')
expected="2"  # Only 2 files exist
if [ "$result" != "$expected" ]; then
    echo "FAIL: Expected $expected files, got $result"
    exit 1
fi
echo "PASS"

# Test 4: Handle non-existent frameworks
echo "Test 4: Non-existent framework..."
result=$(discover_rule_files "nonexistent-framework")
if [ -n "$result" ]; then
    echo "FAIL: Expected empty for non-existent framework, got '$result'"
    exit 1
fi
echo "PASS"

# Test 5: Handle empty input
echo "Test 5: Empty framework list..."
result=$(discover_rule_files "")
if [ -n "$result" ]; then
    echo "FAIL: Expected empty for empty input, got '$result'"
    exit 1
fi
echo "PASS"

# Cleanup
rm -rf "$TEST_RULES_DIR"
echo "All tests passed!"