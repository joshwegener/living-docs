#!/bin/bash
# Test: Install adapter with default settings
# Should create manifest, install commands, and return success

set -e

# Setup test environment
export TEST_MODE=true
TEST_DIR=$(mktemp -d)
export PROJECT_ROOT="$TEST_DIR"

# Source the libraries (will be implemented)
source "$(dirname "$0")/../../lib/adapter/install.sh" 2>/dev/null || true
source "$(dirname "$0")/../../lib/adapter/manifest.sh" 2>/dev/null || true

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test function
test_install_adapter_default() {
    echo "Testing: Install adapter with default settings"

    # Setup mock adapter
    mkdir -p "$TEST_DIR/tmp/spec-kit/commands"
    echo "# Plan command" > "$TEST_DIR/tmp/spec-kit/commands/plan.md"
    echo "# Tasks command" > "$TEST_DIR/tmp/spec-kit/commands/tasks.md"

    # Run installation
    local result
    if result=$(install_adapter "spec-kit" 2>&1); then
        echo "✓ Installation completed successfully"
    else
        echo "✗ Installation failed: $result"
        return 1
    fi

    # Check manifest created
    if [[ -f "$PROJECT_ROOT/adapters/spec-kit/.living-docs-manifest.json" ]]; then
        echo "✓ Manifest file created"
    else
        echo "✗ Manifest file not found"
        return 1
    fi

    # Check commands installed
    if [[ -f "$PROJECT_ROOT/.claude/commands/speckit_plan.md" ]]; then
        echo "✓ Commands installed with prefix"
    elif [[ -f "$PROJECT_ROOT/.claude/commands/plan.md" ]]; then
        echo "✓ Commands installed without prefix"
    else
        echo "✗ Commands not installed"
        return 1
    fi

    echo "✓ Test passed: Install adapter default"
    return 0
}

# Run the test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_install_adapter_default
    exit $?
fi