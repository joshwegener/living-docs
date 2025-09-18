#!/bin/bash
# Test: include_rules_in_bootstrap() function
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/../../scripts/rules/rule-loading.sh"
TEST_DIR=$(mktemp -d)

# Source the implementation (will fail initially - TDD)
if [ -f "$SOURCE_FILE" ]; then
    source "$SOURCE_FILE"
fi

# Test 1: Update bootstrap with single rule file
echo "Test 1: Single rule file inclusion..."
cat > "$TEST_DIR/bootstrap.md" << 'EOF'
# Bootstrap

## Some content

## 🛠️ Active Framework Rules
<!-- RULES_START -->
<!-- RULES_END -->

## More content
EOF

rule_files="docs/rules/spec-kit-rules.md"
result=$(include_rules_in_bootstrap "$TEST_DIR/bootstrap.md" "$rule_files")
if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Expected 'SUCCESS', got '$result'"
    exit 1
fi

# Verify the file was updated
if ! grep -q "spec-kit-rules.md" "$TEST_DIR/bootstrap.md"; then
    echo "FAIL: Rule file not included in bootstrap"
    exit 1
fi
echo "PASS"

# Test 2: Update with multiple rule files
echo "Test 2: Multiple rule files..."
cat > "$TEST_DIR/bootstrap.md" << 'EOF'
# Bootstrap

## 🛠️ Active Framework Rules
<!-- RULES_START -->
<!-- RULES_END -->
EOF

rule_files=$(echo -e "docs/rules/spec-kit-rules.md\ndocs/rules/aider-rules.md\ndocs/rules/cursor-rules.md")
result=$(include_rules_in_bootstrap "$TEST_DIR/bootstrap.md" "$rule_files")
if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Expected 'SUCCESS', got '$result'"
    exit 1
fi

# Verify all files were included
for framework in spec-kit aider cursor; do
    if ! grep -q "${framework}-rules.md" "$TEST_DIR/bootstrap.md"; then
        echo "FAIL: ${framework}-rules.md not included"
        exit 1
    fi
done
echo "PASS"

# Test 3: Handle missing markers
echo "Test 3: Missing RULES markers..."
cat > "$TEST_DIR/bootstrap-no-markers.md" << 'EOF'
# Bootstrap

## Some content without markers
EOF

rule_files="docs/rules/spec-kit-rules.md"
result=$(include_rules_in_bootstrap "$TEST_DIR/bootstrap-no-markers.md" "$rule_files" 2>&1 || true)
if [[ "$result" == "SUCCESS" ]]; then
    echo "FAIL: Should fail when markers are missing"
    exit 1
fi
if [[ "$result" != *"marker"* ]] && [[ "$result" != *"RULES_START"* ]]; then
    echo "FAIL: Expected marker-related error, got '$result'"
    exit 1
fi
echo "PASS"

# Test 4: Preserve existing content outside markers
echo "Test 4: Preserve surrounding content..."
cat > "$TEST_DIR/bootstrap.md" << 'EOF'
# Bootstrap

## Important content before

## 🛠️ Active Framework Rules
<!-- RULES_START -->
<!-- RULES_END -->

## Important content after
This should not be modified
EOF

original_after=$(grep -A2 "Important content after" "$TEST_DIR/bootstrap.md")
rule_files="docs/rules/spec-kit-rules.md"
include_rules_in_bootstrap "$TEST_DIR/bootstrap.md" "$rule_files" >/dev/null 2>&1
new_after=$(grep -A2 "Important content after" "$TEST_DIR/bootstrap.md")

if [ "$original_after" != "$new_after" ]; then
    echo "FAIL: Content outside markers was modified"
    exit 1
fi
echo "PASS"

# Test 5: Handle empty rule list
echo "Test 5: Empty rule list..."
cat > "$TEST_DIR/bootstrap.md" << 'EOF'
## 🛠️ Active Framework Rules
<!-- RULES_START -->
Old content to be removed
<!-- RULES_END -->
EOF

result=$(include_rules_in_bootstrap "$TEST_DIR/bootstrap.md" "")
if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Should handle empty rule list"
    exit 1
fi

# Verify old content was removed
if grep -q "Old content" "$TEST_DIR/bootstrap.md"; then
    echo "FAIL: Old content not removed"
    exit 1
fi
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All tests passed!"