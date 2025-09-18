#!/bin/bash
# Test: complete_tracker() function
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/../../scripts/tracker/tracker-lifecycle.sh"
TEST_DIR=$(mktemp -d)

# Source the implementation (will fail initially - TDD)
if [ -f "$SOURCE_FILE" ]; then
    source "$SOURCE_FILE"
fi

# Helper: Create test tracker
create_test_tracker() {
    cat > "$1" << 'EOF'
---
spec: /docs/specs/002-test/
status: testing
current_phase: 3
started: 2025-09-16
framework: spec-kit
tasks_completed: [1, 2, 3]
---

# Test Tracker

Implementation in progress.
EOF
}

# Test 1: Complete and move tracker
echo "Test 1: Complete tracker..."
mkdir -p "$TEST_DIR/docs/active" "$TEST_DIR/docs/completed"
TRACKER="$TEST_DIR/docs/active/002-test-tracker.md"
create_test_tracker "$TRACKER"
cd "$TEST_DIR"

result=$(complete_tracker "$TRACKER")
expected_pattern="docs/completed/*-test-tracker.md"

# Check if result matches pattern
if [[ ! "$result" == docs/completed/*-test-tracker.md ]]; then
    echo "FAIL: Expected path matching '$expected_pattern', got '$result'"
    exit 1
fi

# Verify file was moved
if [ -f "$TRACKER" ]; then
    echo "FAIL: Original file still exists"
    exit 1
fi

if [ ! -f "$TEST_DIR/$result" ]; then
    echo "FAIL: Completed file not found at '$result'"
    exit 1
fi
echo "PASS"

# Test 2: Verify status updated to completed
echo "Test 2: Status updated..."
if ! grep -q "^status: completed" "$TEST_DIR/$result"; then
    echo "FAIL: Status not updated to completed"
    exit 1
fi
echo "PASS"

# Test 3: Verify date prefix added
echo "Test 3: Date prefix..."
basename=$(basename "$result")
if ! [[ "$basename" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}- ]]; then
    echo "FAIL: Date prefix not added to filename"
    exit 1
fi
echo "PASS"

# Test 4: Complete already completed tracker
echo "Test 4: Already completed tracker..."
TRACKER2="$TEST_DIR/docs/active/003-another-tracker.md"
create_test_tracker "$TRACKER2"
sed -i.bak 's/status: testing/status: completed/' "$TRACKER2"
result=$(complete_tracker "$TRACKER2")

# Should still move the file
if [ -f "$TRACKER2" ]; then
    echo "FAIL: Already completed tracker not moved"
    exit 1
fi
echo "PASS"

# Test 5: Handle missing tracker
echo "Test 5: Missing tracker..."
result=$(complete_tracker "$TEST_DIR/docs/active/nonexistent.md" 2>&1 || true)
if [[ "$result" != *"not found"* ]] && [[ "$result" != *"does not exist"* ]]; then
    echo "FAIL: Expected error for missing file, got '$result'"
    exit 1
fi
echo "PASS"

# Test 6: Preserve metadata during move
echo "Test 6: Preserve metadata..."
TRACKER3="$TEST_DIR/docs/active/004-metadata-tracker.md"
cat > "$TRACKER3" << 'EOF'
---
spec: /docs/specs/004-test/
status: testing
current_phase: 2
started: 2025-09-15
framework: aider
tasks_completed: [1, 2, 3, 4, 5]
custom_field: preserved
---

# Metadata Test

Content here.
EOF

result=$(complete_tracker "$TRACKER3")
if ! grep -q "^custom_field: preserved" "$TEST_DIR/$result"; then
    echo "FAIL: Custom metadata not preserved"
    exit 1
fi
if ! grep -q "^tasks_completed: \[1, 2, 3, 4, 5\]" "$TEST_DIR/$result"; then
    echo "FAIL: Task list not preserved"
    exit 1
fi
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All tests passed!"