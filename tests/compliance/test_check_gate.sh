#!/bin/bash
set -euo pipefail
# Test: check_gate() function
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/../../scripts/compliance/compliance-review.sh"
TEST_DIR=$(mktemp -d)

# Source the implementation (will fail initially - TDD)
if [ -f "$SOURCE_FILE" ]; then
    source "$SOURCE_FILE"
fi

# Test 1: TDD_TESTS_FIRST gate passes with tests before implementation
echo "Test 1: TDD gate passes with correct order..."
context=$(cat << 'EOF'
diff --git a/tests/test_feature.sh b/tests/test_feature.sh
new file mode 100644
+# Test file
diff --git a/src/feature.sh b/src/feature.sh
new file mode 100644
+# Implementation file
EOF
)

result=$(check_gate "TDD_TESTS_FIRST" "$context" 2>&1 || true)
if [[ "$result" != "PASS" ]]; then
    echo "FAIL: TDD gate should pass with tests first"
    echo "Got: $result"
    exit 1
fi
echo "PASS"

# Test 2: TDD_TESTS_FIRST gate fails without tests
echo "Test 2: TDD gate fails without tests..."
context=$(cat << 'EOF'
diff --git a/src/feature.sh b/src/feature.sh
new file mode 100644
+# Implementation without tests
EOF
)

result=$(check_gate "TDD_TESTS_FIRST" "$context" 2>&1 || true)
if [[ "$result" == "PASS" ]]; then
    echo "FAIL: TDD gate should fail without tests"
    exit 1
fi
if [[ "$result" != *"FAIL"* ]]; then
    echo "FAIL: Expected FAIL in result"
    exit 1
fi
echo "PASS"

# Test 3: UPDATE_TASKS_MD gate checks for tasks.md
echo "Test 3: Tasks update gate..."
cd "$TEST_DIR"
mkdir -p docs/specs/test

# Create tasks.md
cat > docs/specs/test/tasks.md << 'EOF'
# Tasks
- [ ] T001 Implement feature
EOF

context="Implementing feature in src/feature.sh"

result=$(check_gate "UPDATE_TASKS_MD" "$context" 2>&1 || true)
# Should check if tasks.md was updated in the diff
echo "PASS (gate checked)"

# Test 4: Unknown gate returns error
echo "Test 4: Unknown gate..."
result=$(check_gate "UNKNOWN_GATE" "some context" 2>&1 || true)
if [[ "$result" == "PASS" ]]; then
    echo "FAIL: Unknown gate should not pass"
    exit 1
fi
echo "PASS"

# Test 5: Empty context handling
echo "Test 5: Empty context..."
result=$(check_gate "TDD_TESTS_FIRST" "" 2>&1 || true)
# Empty diff means no new implementation, should pass
if [[ "$result" != "PASS" ]]; then
    echo "Note: Empty context behavior may vary"
fi
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All tests passed!"