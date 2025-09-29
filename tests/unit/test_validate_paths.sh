#!/bin/bash
set -euo pipefail
# Test: Detection of hardcoded paths before installation (T008)
# Should identify and warn about hardcoded paths in adapter files

set -e

# Setup test environment
export TEST_MODE=true
TEST_DIR=$(mktemp -d)
export PROJECT_ROOT="$TEST_DIR"

# Source the libraries (will be implemented)
source "$(dirname "$0")/../../lib/adapter/rewrite.sh" 2>/dev/null || true
source "$(dirname "$0")/../../lib/adapter/install.sh" 2>/dev/null || true

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test function
test_validate_paths() {
    echo "Testing: Detection of hardcoded paths before installation"

    # Setup mock adapter with various hardcoded paths
    mkdir -p "$TEST_DIR/tmp/spec-kit/commands"
    mkdir -p "$TEST_DIR/tmp/spec-kit/scripts"
    mkdir -p "$TEST_DIR/tmp/spec-kit/templates"

    # Create files with hardcoded paths
    cat > "$TEST_DIR/tmp/spec-kit/commands/plan.md" <<'EOF'
# Plan Command
Execute script: scripts/bash/plan.sh
Check specification: .spec/current/plan.md
Access memory: memory/context/plan.txt
Use template: templates/plan-template.md
EOF

    cat > "$TEST_DIR/tmp/spec-kit/scripts/setup.sh" <<'EOF'
#!/bin/bash
# Setup script
source scripts/common/utils.sh
mkdir -p .spec/workspace
cp templates/default.md .spec/workspace/
echo "Setup complete" > memory/logs/setup.log
EOF

    cat > "$TEST_DIR/tmp/spec-kit/templates/spec.md" <<'EOF'
# Spec Template
Include: templates/includes/header.md
Scripts: scripts/validation/
Memory: memory/templates/
EOF

    # Run path validation
    local result
    local validation_output
    if validation_output=$(validate_adapter_paths "spec-kit" 2>&1); then
        echo "✓ Path validation completed"
    else
        echo "✗ Path validation failed: $validation_output"
        return 1
    fi

    # Check detection of scripts/ paths
    if echo "$validation_output" | grep -q "scripts/"; then
        echo "✓ Detected hardcoded scripts/ paths"
    else
        echo "✗ Failed to detect scripts/ paths"
        return 1
    fi

    # Check detection of .spec/ paths
    if echo "$validation_output" | grep -q "\.spec/"; then
        echo "✓ Detected hardcoded .spec/ paths"
    else
        echo "✗ Failed to detect .spec/ paths"
        return 1
    fi

    # Check detection of memory/ paths
    if echo "$validation_output" | grep -q "memory/"; then
        echo "✓ Detected hardcoded memory/ paths"
    else
        echo "✗ Failed to detect memory/ paths"
        return 1
    fi

    # Check detection of templates/ paths
    if echo "$validation_output" | grep -q "templates/"; then
        echo "✓ Detected hardcoded templates/ paths"
    else
        echo "✗ Failed to detect templates/ paths"
        return 1
    fi

    # Test validation with clean adapter (no hardcoded paths)
    mkdir -p "$TEST_DIR/tmp/clean-adapter/commands"
    cat > "$TEST_DIR/tmp/clean-adapter/commands/plan.md" <<'EOF'
# Clean Plan Command
Execute script: \$SCRIPTS_PATH/plan.sh
Check specification: \$SPECS_PATH/current/plan.md
Access memory: \$MEMORY_PATH/context/plan.txt
Use template: \$TEMPLATES_PATH/plan-template.md
EOF

    # Run validation on clean adapter
    local clean_result
    if clean_result=$(validate_adapter_paths "clean-adapter" 2>&1); then
        echo "✓ Clean adapter validation passed"
    else
        echo "✗ Clean adapter validation failed: $clean_result"
        return 1
    fi

    # Check that no hardcoded paths detected in clean adapter
    if echo "$clean_result" | grep -q "No hardcoded paths detected"; then
        echo "✓ Clean adapter correctly identified as path-safe"
    else
        echo "✗ Clean adapter incorrectly flagged for hardcoded paths"
        return 1
    fi

    # Test path suggestion functionality
    local suggestions
    if suggestions=$(suggest_path_rewrites "spec-kit" 2>&1); then
        echo "✓ Path rewrite suggestions generated"
    else
        echo "✗ Failed to generate path suggestions: $suggestions"
        return 1
    fi

    # Check suggestions include variable replacements
    if echo "$suggestions" | grep -q "scripts/.*->.*SCRIPTS_PATH"; then
        echo "✓ Script path suggestions include \$SCRIPTS_PATH"
    else
        echo "✗ Missing script path suggestions"
        return 1
    fi

    if echo "$suggestions" | grep -q "\.spec/.*->.*SPECS_PATH"; then
        echo "✓ Spec path suggestions include \$SPECS_PATH"
    else
        echo "✗ Missing spec path suggestions"
        return 1
    fi

    echo "✓ Test passed: Hardcoded path detection and validation"
    return 0
}

# Run the test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_validate_paths
    exit $?
fi