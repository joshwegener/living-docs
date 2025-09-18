#!/bin/bash
# Integration Test: End-to-end rule loading through wizard
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR=$(mktemp -d)
RULE_LOADING="${SCRIPT_DIR}/../../scripts/rules/rule-loading.sh"

# Source implementation
if [ -f "$RULE_LOADING" ]; then
    source "$RULE_LOADING"
fi

echo "Integration Test: Complete rule loading workflow"

# Test 1: Full workflow - config to bootstrap
echo "Test 1: Config → Discovery → Bootstrap update..."

# Setup test environment
mkdir -p "$TEST_DIR/docs/rules"
cd "$TEST_DIR"

# Create test config
cat > ".living-docs.config" << 'EOF'
DOCS_DIR="docs"
INSTALLED_SPECS="spec-kit aider"
BOOTSTRAP_FILE="bootstrap.md"
EOF

# Create rule files
cat > "docs/rules/spec-kit-rules.md" << 'EOF'
# spec-kit Rules

## Gate: TDD_TESTS_FIRST
Tests must be written before implementation.

## Gate: UPDATE_TASKS_MD
Update tasks.md after each task completion.
EOF

cat > "docs/rules/aider-rules.md" << 'EOF'
# aider Rules

## Gate: UPDATE_CONVENTIONS
Keep CONVENTIONS.md updated.
EOF

# Create bootstrap with markers
cat > "docs/bootstrap.md" << 'EOF'
# Bootstrap

## Project Setup

## 🛠️ Active Framework Rules
<!-- RULES_START -->
<!-- RULES_END -->

## Other Content
EOF

# Run the full workflow
export LIVING_DOCS_CONFIG=".living-docs.config"
specs=$(get_installed_specs)
if [ "$specs" != "spec-kit aider" ]; then
    echo "FAIL: get_installed_specs failed"
    exit 1
fi

rule_files=$(discover_rule_files "$specs")
if [ -z "$rule_files" ]; then
    echo "FAIL: No rule files discovered"
    exit 1
fi

result=$(include_rules_in_bootstrap "docs/bootstrap.md" "$rule_files")
if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Bootstrap update failed"
    exit 1
fi

# Verify both rules are included
if ! grep -q "spec-kit-rules.md" "docs/bootstrap.md"; then
    echo "FAIL: spec-kit rules not included"
    exit 1
fi

if ! grep -q "aider-rules.md" "docs/bootstrap.md"; then
    echo "FAIL: aider rules not included"
    exit 1
fi
echo "PASS"

# Test 2: Handle missing framework gracefully
echo "Test 2: Missing framework handling..."

# Add a framework without a rule file
sed -i.bak 's/INSTALLED_SPECS=.*/INSTALLED_SPECS="spec-kit aider cursor"/' ".living-docs.config"

specs=$(get_installed_specs)
rule_files=$(discover_rule_files "$specs")

# Should still find the two that exist
line_count=$(echo "$rule_files" | grep -c ".md" || true)
if [ "$line_count" -ne 2 ]; then
    echo "FAIL: Should find 2 rule files even with missing cursor-rules.md"
    exit 1
fi
echo "PASS"

# Test 3: Empty INSTALLED_SPECS
echo "Test 3: No frameworks installed..."

sed -i.bak 's/INSTALLED_SPECS=.*/INSTALLED_SPECS=""/' ".living-docs.config"
specs=$(get_installed_specs)
rule_files=$(discover_rule_files "$specs")

if [ -n "$rule_files" ]; then
    echo "FAIL: Should return empty for no frameworks"
    exit 1
fi

# Bootstrap should be cleared
result=$(include_rules_in_bootstrap "docs/bootstrap.md" "$rule_files")
if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Should handle empty rule list"
    exit 1
fi

# Check content between markers is empty/minimal
content=$(sed -n '/<!-- RULES_START -->/,/<!-- RULES_END -->/p' "docs/bootstrap.md" | grep -v "<!--" || true)
if [ -n "$content" ]; then
    echo "FAIL: Rules section should be empty"
    exit 1
fi
echo "PASS"

# Test 4: Validate all discovered files
echo "Test 4: Validation of discovered files..."

sed -i.bak 's/INSTALLED_SPECS=.*/INSTALLED_SPECS="spec-kit aider"/' ".living-docs.config"
specs=$(get_installed_specs)
rule_files=$(discover_rule_files "$specs")

while IFS= read -r file; do
    if [ -z "$file" ]; then continue; fi
    result=$(validate_rule_file "$file")
    if [ "$result" != "VALID" ]; then
        echo "FAIL: File $file validation failed: $result"
        exit 1
    fi
done <<< "$rule_files"
echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All integration tests passed!"