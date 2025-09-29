#!/bin/bash
set -euo pipefail
# Test: create_tracker() function
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/../../scripts/tracker/tracker-lifecycle.sh"
TEST_DIR=$(mktemp -d)

# Source the implementation (will fail initially - TDD)
if [ -f "$SOURCE_FILE" ]; then
    source "$SOURCE_FILE"
fi

# Test 1: Create basic tracker
echo "Test 1: Create basic tracker..."
mkdir -p "$TEST_DIR/docs/active"
cd "$TEST_DIR"
result=$(create_tracker "002" "modular-spec-rules" "spec-kit")
expected="docs/active/002-modular-spec-rules-tracker.md"

if [ "$result" != "$expected" ]; then
    echo "FAIL: Expected '$expected', got '$result'"
    exit 1
fi

if [ ! -f "$TEST_DIR/$expected" ]; then
    echo "FAIL: Tracker file not created"
    exit 1
fi

# Verify YAML frontmatter
if ! grep -q "^spec: /docs/specs/002-modular-spec-rules/" "$TEST_DIR/$expected"; then
    echo "FAIL: Missing or incorrect spec reference"
    exit 1
fi

if ! grep -q "^status: planning" "$TEST_DIR/$expected"; then
    echo "FAIL: Missing or incorrect initial status"
    exit 1
fi

if ! grep -q "^framework: spec-kit" "$TEST_DIR/$expected"; then
    echo "FAIL: Missing or incorrect framework"
    exit 1
fi
echo "PASS"

# Test 2: Create tracker with different framework
echo "Test 2: Different framework..."
result=$(create_tracker "003" "test-feature" "aider")
if [ ! -f "$TEST_DIR/docs/active/003-test-feature-tracker.md" ]; then
    echo "FAIL: Tracker not created for aider framework"
    exit 1
fi

if ! grep -q "^framework: aider" "$TEST_DIR/docs/active/003-test-feature-tracker.md"; then
    echo "FAIL: Incorrect framework in tracker"
    exit 1
fi
echo "PASS"

# Test 3: Handle special characters in name
echo "Test 3: Special characters in name..."
result=$(create_tracker "004" "feature-with-dash" "spec-kit")
if [ ! -f "$TEST_DIR/docs/active/004-feature-with-dash-tracker.md" ]; then
    echo "FAIL: Failed with dashed name"
    exit 1
fi
echo "PASS"

# Test 4: Verify initial phase is 0
echo "Test 4: Initial phase..."
create_tracker "005" "test" "spec-kit" >/dev/null
if ! grep -q "^current_phase: 0" "$TEST_DIR/docs/active/005-test-tracker.md"; then
    echo "FAIL: Initial phase should be 0"
    exit 1
fi
echo "PASS"

# Test 5: Verify ISO date format
echo "Test 5: Date format..."
create_tracker "006" "test" "spec-kit" >/dev/null
if ! grep -E "^started: [0-9]{4}-[0-9]{2}-[0-9]{2}" "$TEST_DIR/docs/active/006-test-tracker.md"; then
    echo "FAIL: Date not in ISO format"
    exit 1
fi
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All tests passed!"