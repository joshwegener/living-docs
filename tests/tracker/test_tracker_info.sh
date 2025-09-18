#!/bin/bash
# Test: get_tracker_info() function
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/../../scripts/tracker/tracker-lifecycle.sh"
TEST_DIR=$(mktemp -d)

# Source the implementation (will fail initially - TDD)
if [ -f "$SOURCE_FILE" ]; then
    source "$SOURCE_FILE"
fi

# Test 1: Extract basic info
echo "Test 1: Extract basic tracker info..."
TRACKER="$TEST_DIR/test-tracker.md"
cat > "$TRACKER" << 'EOF'
---
spec: /docs/specs/002-modular-rules/
status: implementing
current_phase: 1
started: 2025-09-16
framework: spec-kit
tasks_completed: [1, 2, 3]
---

# Test Tracker
EOF

result=$(get_tracker_info "$TRACKER")

# Check for JSON structure
if ! echo "$result" | grep -q '"spec".*"002-modular-rules"'; then
    echo "FAIL: Missing or incorrect spec in JSON"
    exit 1
fi

if ! echo "$result" | grep -q '"status".*"implementing"'; then
    echo "FAIL: Missing or incorrect status in JSON"
    exit 1
fi

if ! echo "$result" | grep -q '"phase".*1'; then
    echo "FAIL: Missing or incorrect phase in JSON"
    exit 1
fi
echo "PASS"

# Test 2: Handle all status values
echo "Test 2: Different status values..."
for status in planning implementing testing completed blocked failed; do
    cat > "$TRACKER" << EOF
---
spec: /docs/specs/test/
status: $status
current_phase: 2
started: 2025-09-16
framework: aider
tasks_completed: []
---
EOF
    result=$(get_tracker_info "$TRACKER")
    if ! echo "$result" | grep -q "\"status\".*\"$status\""; then
        echo "FAIL: Status '$status' not extracted correctly"
        exit 1
    fi
done
echo "PASS"

# Test 3: Handle different phases
echo "Test 3: Different phases..."
for phase in 0 1 2 3 4; do
    cat > "$TRACKER" << EOF
---
spec: /docs/specs/test/
status: implementing
current_phase: $phase
started: 2025-09-16
framework: cursor
tasks_completed: []
---
EOF
    result=$(get_tracker_info "$TRACKER")
    if ! echo "$result" | grep -q "\"phase\".*$phase"; then
        echo "FAIL: Phase '$phase' not extracted correctly"
        exit 1
    fi
done
echo "PASS"

# Test 4: Extract spec name correctly
echo "Test 4: Spec name extraction..."
cat > "$TRACKER" << 'EOF'
---
spec: /docs/specs/123-complex-feature-name/
status: testing
current_phase: 3
started: 2025-09-16
framework: spec-kit
tasks_completed: [1, 2]
---
EOF

result=$(get_tracker_info "$TRACKER")
if ! echo "$result" | grep -q "123-complex-feature-name"; then
    echo "FAIL: Complex spec name not extracted"
    exit 1
fi
echo "PASS"

# Test 5: Handle missing file
echo "Test 5: Missing tracker file..."
result=$(get_tracker_info "$TEST_DIR/nonexistent.md" 2>&1 || true)
if echo "$result" | grep -q '"spec"'; then
    echo "FAIL: Should not return valid JSON for missing file"
    exit 1
fi
echo "PASS"

# Test 6: Handle malformed tracker
echo "Test 6: Malformed tracker..."
cat > "$TRACKER" << 'EOF'
This is not a valid tracker file
No YAML frontmatter here
EOF

result=$(get_tracker_info "$TRACKER" 2>&1 || true)
if echo "$result" | grep -q '"status".*"implementing"'; then
    echo "FAIL: Should not extract data from malformed file"
    exit 1
fi
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All tests passed!"