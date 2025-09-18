#!/bin/bash
# Test: validate_rule_file() function
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/../../scripts/rules/rule-loading.sh"
TEST_DIR=$(mktemp -d)

# Source the implementation (will fail initially - TDD)
if [ -f "$SOURCE_FILE" ]; then
    source "$SOURCE_FILE"
fi

# Test 1: Valid rule file
echo "Test 1: Valid rule file..."
cat > "$TEST_DIR/valid-rules.md" << 'EOF'
# spec-kit Rules

## Gate: TDD_TESTS_FIRST
- Tests must be written before implementation
- Tests must fail initially (RED phase)

## Gate: UPDATE_TASKS_MD
- Update tasks.md immediately after completing each task
EOF
result=$(validate_rule_file "$TEST_DIR/valid-rules.md")
if [ "$result" != "VALID" ]; then
    echo "FAIL: Expected 'VALID', got '$result'"
    exit 1
fi
echo "PASS"

# Test 2: Missing file
echo "Test 2: Missing file..."
result=$(validate_rule_file "$TEST_DIR/nonexistent.md" 2>&1 || true)
if [[ "$result" == "VALID" ]]; then
    echo "FAIL: Missing file should not be valid"
    exit 1
fi
if [[ "$result" != *"not found"* ]] && [[ "$result" != *"does not exist"* ]]; then
    echo "FAIL: Expected 'not found' error, got '$result'"
    exit 1
fi
echo "PASS"

# Test 3: Empty file
echo "Test 3: Empty file..."
touch "$TEST_DIR/empty-rules.md"
result=$(validate_rule_file "$TEST_DIR/empty-rules.md" 2>&1 || true)
if [[ "$result" == "VALID" ]]; then
    echo "FAIL: Empty file should not be valid"
    exit 1
fi
if [[ "$result" != *"no gates"* ]] && [[ "$result" != *"empty"* ]]; then
    echo "FAIL: Expected 'no gates' or 'empty' error, got '$result'"
    exit 1
fi
echo "PASS"

# Test 4: File without gates
echo "Test 4: File without gates..."
cat > "$TEST_DIR/no-gates.md" << 'EOF'
# Some Rules

This file has content but no gates defined.
Just some regular text.
EOF
result=$(validate_rule_file "$TEST_DIR/no-gates.md" 2>&1 || true)
if [[ "$result" == "VALID" ]]; then
    echo "FAIL: File without gates should not be valid"
    exit 1
fi
if [[ "$result" != *"Gate"* ]] && [[ "$result" != *"gate"* ]]; then
    echo "FAIL: Expected gate-related error, got '$result'"
    exit 1
fi
echo "PASS"

# Test 5: Invalid markdown (binary file)
echo "Test 5: Binary file..."
echo -e "\x00\x01\x02" > "$TEST_DIR/binary.md"
result=$(validate_rule_file "$TEST_DIR/binary.md" 2>&1 || true)
if [[ "$result" == "VALID" ]]; then
    echo "FAIL: Binary file should not be valid"
    exit 1
fi
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All tests passed!"