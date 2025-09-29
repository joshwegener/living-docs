#!/bin/bash
set -euo pipefail
# Test: Install adapter with custom SCRIPTS_PATH and SPECS_PATH
# Should rewrite paths in installed files

set -e

# Setup test environment
export TEST_MODE=true
TEST_DIR=$(mktemp -d)
export PROJECT_ROOT="$TEST_DIR"

# Source the libraries (will be implemented)
source "$(dirname "$0")/../../lib/adapter/install.sh" 2>/dev/null || true
source "$(dirname "$0")/../../lib/adapter/rewrite.sh" 2>/dev/null || true

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test function
test_install_adapter_custom_paths() {
    echo "Testing: Install adapter with custom paths"

    # Set custom paths
    export SCRIPTS_PATH="/custom/scripts"
    export SPECS_PATH="/custom/specs"
    export MEMORY_PATH="/custom/memory"

    # Setup mock adapter with hardcoded paths
    mkdir -p ""$TEST_DIR"/tmp/spec-kit/commands"
    cat > ""$TEST_DIR"/tmp/spec-kit/commands/plan.md" <<'EOF'
# Plan Command
Execute script at scripts/bash/plan.sh
Check spec at .spec/current
Access memory at memory/context
EOF

    # Run installation with custom paths
    local result
    if result=$(install_adapter "spec-kit" --custom-paths 2>&1); then
        echo "✓ Installation with custom paths completed"
    else
        echo "✗ Installation failed: $result"
        return 1
    fi

    # Check if paths were rewritten
    local installed_file
    if [[ -f ""$PROJECT_ROOT"/.claude/commands/speckit_plan.md" ]]; then
        installed_file=""$PROJECT_ROOT"/.claude/commands/speckit_plan.md"
    elif [[ -f ""$PROJECT_ROOT"/.claude/commands/plan.md" ]]; then
        installed_file=""$PROJECT_ROOT"/.claude/commands/plan.md"
    else
        echo "✗ Command file not found"
        return 1
    fi

    # Verify path rewriting
    if grep -q "/custom/scripts" "$installed_file"; then
        echo "✓ SCRIPTS_PATH rewritten correctly"
    else
        echo "✗ SCRIPTS_PATH not rewritten"
        return 1
    fi

    if grep -q "/custom/specs" "$installed_file"; then
        echo "✓ SPECS_PATH rewritten correctly"
    else
        echo "✗ SPECS_PATH not rewritten"
        return 1
    fi

    if grep -q "/custom/memory" "$installed_file"; then
        echo "✓ MEMORY_PATH rewritten correctly"
    else
        echo "✗ MEMORY_PATH not rewritten"
        return 1
    fi

    # Check manifest tracks original paths
    if [[ -f ""$PROJECT_ROOT"/adapters/spec-kit/.living-docs-manifest.json" ]]; then
        if grep -q "original_path" ""$PROJECT_ROOT"/adapters/spec-kit/.living-docs-manifest.json"; then
            echo "✓ Manifest tracks original paths"
        else
            echo "✗ Manifest missing original paths"
            return 1
        fi
    else
        echo "✗ Manifest not found"
        return 1
    fi

    echo "✓ Test passed: Custom paths installation"
    return 0
}

# Run the test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_install_adapter_custom_paths
    exit $?
fi