#!/bin/bash
set -euo pipefail
# Test: update_tracker_status() function
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
status: planning
current_phase: 0
started: 2025-09-16
framework: spec-kit
tasks_completed: []
---

# Test Tracker
EOF
}

# Test 1: Update from planning to implementing
echo "Test 1: Update status to implementing..."
mkdir -p "$TEST_DIR/docs/active"
TRACKER="$TEST_DIR/docs/active/002-test-tracker.md"
create_test_tracker "$TRACKER"

result=$(update_tracker_status "$TRACKER" "implementing")
if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Expected 'SUCCESS', got '$result'"
    exit 1
fi

if ! grep -q "^status: implementing" "$TRACKER"; then
    echo "FAIL: Status not updated"
    exit 1
fi
echo "PASS"

# Test 2: Update to testing
echo "Test 2: Update status to testing..."
result=$(update_tracker_status "$TRACKER" "testing")
if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Expected 'SUCCESS', got '$result'"
    exit 1
fi

if ! grep -q "^status: testing" "$TRACKER"; then
    echo "FAIL: Status not updated to testing"
    exit 1
fi
echo "PASS"

# Test 3: Update to completed
echo "Test 3: Update status to completed..."
result=$(update_tracker_status "$TRACKER" "completed")
if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Expected 'SUCCESS', got '$result'"
    exit 1
fi

if ! grep -q "^status: completed" "$TRACKER"; then
    echo "FAIL: Status not updated to completed"
    exit 1
fi
echo "PASS"

# Test 4: Handle blocked status
echo "Test 4: Update to blocked..."
create_test_tracker "$TRACKER"
result=$(update_tracker_status "$TRACKER" "blocked")
if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Expected 'SUCCESS', got '$result'"
    exit 1
fi

if ! grep -q "^status: blocked" "$TRACKER"; then
    echo "FAIL: Status not updated to blocked"
    exit 1
fi
echo "PASS"

# Test 5: Invalid status
echo "Test 5: Invalid status..."
result=$(update_tracker_status "$TRACKER" "invalid-status" 2>&1 || true)
if [[ "$result" == "SUCCESS" ]]; then
    echo "FAIL: Should reject invalid status"
    exit 1
fi
if [[ "$result" != *"invalid"* ]] && [[ "$result" != *"Invalid"* ]]; then
    echo "FAIL: Expected 'invalid' error, got '$result'"
    exit 1
fi
echo "PASS"

# Test 6: Missing file
echo "Test 6: Missing tracker file..."
result=$(update_tracker_status "$TEST_DIR/nonexistent.md" "testing" 2>&1 || true)
if [[ "$result" == "SUCCESS" ]]; then
    echo "FAIL: Should fail for missing file"
    exit 1
fi
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All tests passed!"