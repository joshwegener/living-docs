#!/bin/bash
# Integration Test: Wizard creates bootstrap with framework rules
set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR=$(mktemp -d)
WIZARD_PATH="${SCRIPT_DIR}/../../wizard.sh"
RULE_LOADING="${SCRIPT_DIR}/../../scripts/rules/rule-loading.sh"

echo "Integration Test: Wizard bootstrap with rules"

# Test 1: Fresh install with framework creates bootstrap with rules
echo "Test 1: Fresh install includes framework rules..."

cd "$TEST_DIR"

# Create minimal wizard environment
mkdir -p templates/docs adapters/spec-kit scripts/rules

# Copy bootstrap template
cp "${SCRIPT_DIR}/../../templates/docs/bootstrap.md.template" templates/docs/

# Copy rule loading script
cp "${SCRIPT_DIR}/../../scripts/rules/rule-loading.sh" scripts/rules/

# Create mock adapter
cat > adapters/spec-kit/install.sh << 'EOF'
#!/bin/bash
echo "Mock spec-kit installation"
exit 0
EOF
chmod +x adapters/spec-kit/install.sh

# Create rule file
mkdir -p docs/rules
cat > docs/rules/spec-kit-rules.md << 'EOF'
# spec-kit Rules

## Gate: TEST_GATE
Test gate content
EOF

# Simulate wizard installation
DOCS_PATH="docs"
mkdir -p "$DOCS_PATH/active" "$DOCS_PATH/completed"

# Create bootstrap with markers
cat > "$DOCS_PATH/bootstrap.md" << 'EOF'
# Bootstrap

## 🛠️ Active Framework Rules
<!-- RULES_START -->
<!-- RULES_END -->
EOF

# Create config
cat > .living-docs.config << EOF
docs_path="$DOCS_PATH"
INSTALLED_SPECS="spec-kit"
EOF

# Run rule loading
source scripts/rules/rule-loading.sh
specs=$(get_installed_specs)
rule_files=$(discover_rule_files "$specs")
result=$(include_rules_in_bootstrap "$DOCS_PATH/bootstrap.md" "$rule_files")

if [ "$result" != "SUCCESS" ]; then
    echo "FAIL: Rule loading failed"
    exit 1
fi

# Verify rules were included
if ! grep -q "spec-kit-rules.md" "$DOCS_PATH/bootstrap.md"; then
    echo "FAIL: Rules not included in bootstrap"
    cat "$DOCS_PATH/bootstrap.md"
    exit 1
fi

echo "PASS"

# Test 2: Multiple frameworks
echo "Test 2: Multiple framework rules..."

# Add another rule file
cat > docs/rules/aider-rules.md << 'EOF'
# aider Rules

## Gate: AIDER_GATE
Aider gate content
EOF

# Update config
echo 'INSTALLED_SPECS="spec-kit aider"' > .living-docs.config

# Clear and re-run
cat > "$DOCS_PATH/bootstrap.md" << 'EOF'
# Bootstrap

## 🛠️ Active Framework Rules
<!-- RULES_START -->
<!-- RULES_END -->
EOF

specs=$(get_installed_specs)
rule_files=$(discover_rule_files "$specs")
include_rules_in_bootstrap "$DOCS_PATH/bootstrap.md" "$rule_files" >/dev/null

# Verify both included
if ! grep -q "spec-kit-rules.md" "$DOCS_PATH/bootstrap.md"; then
    echo "FAIL: spec-kit rules missing"
    exit 1
fi

if ! grep -q "aider-rules.md" "$DOCS_PATH/bootstrap.md"; then
    echo "FAIL: aider rules missing"
    exit 1
fi

echo "PASS"

# Cleanup
rm -rf "$TEST_DIR"
echo "All integration tests passed!"