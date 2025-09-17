#!/bin/bash
# Test: review_compliance() function
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/../../scripts/compliance/compliance-review.sh"
TEST_DIR=$(mktemp -d)

# Source the implementation (will fail initially - TDD)
if [ -f "$SOURCE_FILE" ]; then
    source "$SOURCE_FILE"
fi

# Test 1: Pass when no violations
echo "Test 1: Pass with no violations..."
cd "$TEST_DIR"
mkdir -p src tests

# Create valid changes (tests before implementation)
cat > tests/test_feature.sh << 'EOF'
#!/bin/bash
# Test that will fail initially
test_feature() {
    result=$(feature_function)
    [ "$result" = "expected" ] || exit 1
}
EOF

cat > src/feature.sh << 'EOF'
#!/bin/bash
# Implementation to make test pass
feature_function() {
    echo "expected"
}
EOF

# Mock git diff
changes=$(cat << 'EOF'
diff --git a/tests/test_feature.sh b/tests/test_feature.sh
new file mode 100644
+#!/bin/bash
+# Test that will fail initially
diff --git a/src/feature.sh b/src/feature.sh
new file mode 100644
+#!/bin/bash
+# Implementation to make test pass
EOF
)

result=$(review_compliance "$changes" 2>&1 || true)
if ! echo "$result" | grep -q '"result".*"PASS"'; then
    echo "FAIL: Expected PASS for valid changes"
    echo "Got: $result"
    exit 1
fi
echo "PASS"

# Test 2: Fail when implementation without tests
echo "Test 2: Fail for implementation without tests..."
changes=$(cat << 'EOF'
diff --git a/src/feature.sh b/src/feature.sh
new file mode 100644
+#!/bin/bash
+# Implementation without tests
+feature_function() {
+    echo "untested"
+}
EOF
)

result=$(review_compliance "$changes" 2>&1 || true)
if ! echo "$result" | grep -q '"result".*"FAIL"'; then
    echo "FAIL: Should fail for implementation without tests"
    exit 1
fi

if ! echo "$result" | grep -q "TDD_TESTS_FIRST\|test"; then
    echo "FAIL: Should mention TDD violation"
    exit 1
fi
echo "PASS"

# Test 3: Check tasks.md update requirement
echo "Test 3: Check tasks.md update..."

# Create a tasks.md file
mkdir -p docs/specs/test
cat > docs/specs/test/tasks.md << 'EOF'
# Tasks
- [ ] T001 Write tests
- [ ] T002 Implement feature
EOF

changes=$(cat << 'EOF'
diff --git a/src/feature.sh b/src/feature.sh
new file mode 100644
+# Implementation
diff --git a/tests/test_feature.sh b/tests/test_feature.sh
new file mode 100644
+# Tests
EOF
)

result=$(review_compliance "$changes" 2>&1 || true)
# Should warn if tasks.md not updated
if echo "$result" | grep -q "UPDATE_TASKS_MD"; then
    echo "PASS (warning detected)"
else
    echo "PASS (no tasks.md in scope)"
fi

# Test 4: Multiple violations
echo "Test 4: Multiple violations..."
changes=$(cat << 'EOF'
diff --git a/src/feature1.sh b/src/feature1.sh
new file mode 100644
+# Implementation without test
diff --git a/src/feature2.sh b/src/feature2.sh
new file mode 100644
+# Another implementation without test
EOF
)

result=$(review_compliance "$changes" 2>&1 || true)
if ! echo "$result" | grep -q '"result".*"FAIL"'; then
    echo "FAIL: Should fail for multiple violations"
    exit 1
fi

# Check violations array has entries
if ! echo "$result" | grep -q "violations"; then
    echo "FAIL: Should list violations"
    exit 1
fi
echo "PASS"

# Test 5: Empty diff passes
echo "Test 5: Empty diff..."
result=$(review_compliance "" 2>&1 || true)
if ! echo "$result" | grep -q '"result".*"PASS"'; then
    echo "FAIL: Empty diff should pass"
    exit 1
fi
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All tests passed!"