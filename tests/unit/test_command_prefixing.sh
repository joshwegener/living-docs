#!/bin/bash
set -euo pipefail
# Test: Automatic command name prefixing (T009)
# Should automatically prefix command names to prevent conflicts

set -e

# Setup test environment
export TEST_MODE=true
TEST_DIR=$(mktemp -d)
export PROJECT_ROOT="$TEST_DIR"

# Source the libraries (will be implemented)
source "$(dirname "$0")/../../lib/adapter/prefix.sh" 2>/dev/null || true
source "$(dirname "$0")/../../lib/adapter/install.sh" 2>/dev/null || true

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test function
test_command_prefixing() {
    echo "Testing: Automatic command name prefixing"

    # Setup existing commands to create conflict scenario
    mkdir -p "$PROJECT_ROOT/.claude/commands"
    echo "# Existing plan command" > "$PROJECT_ROOT/.claude/commands/plan.md"
    echo "# Existing tasks command" > "$PROJECT_ROOT/.claude/commands/tasks.md"

    # Setup mock adapter with conflicting command names
    mkdir -p "$TEST_DIR/tmp/spec-kit/commands"
    echo "# New plan command" > "$TEST_DIR/tmp/spec-kit/commands/plan.md"
    echo "# New tasks command" > "$TEST_DIR/tmp/spec-kit/commands/tasks.md"
    echo "# Unique command" > "$TEST_DIR/tmp/spec-kit/commands/implement.md"

    # Test conflict detection
    local conflicts
    if conflicts=$(detect_command_conflicts "spec-kit" 2>&1); then
        echo "✓ Command conflict detection completed"
    else
        echo "✗ Conflict detection failed: $conflicts"
        return 1
    fi

    # Check that conflicts are properly identified
    if echo "$conflicts" | grep -q "plan.md"; then
        echo "✓ Detected conflict with plan.md"
    else
        echo "✗ Failed to detect plan.md conflict"
        return 1
    fi

    if echo "$conflicts" | grep -q "tasks.md"; then
        echo "✓ Detected conflict with tasks.md"
    else
        echo "✗ Failed to detect tasks.md conflict"
        return 1
    fi

    # Check that non-conflicting commands are not flagged
    if echo "$conflicts" | grep -q "implement.md"; then
        echo "✗ Non-conflicting command incorrectly flagged"
        return 1
    else
        echo "✓ Non-conflicting command correctly ignored"
    fi

    # Test automatic prefix generation
    local prefix
    if prefix=$(generate_adapter_prefix "spec-kit" 2>&1); then
        echo "✓ Adapter prefix generated: $prefix"
    else
        echo "✗ Failed to generate adapter prefix: $prefix"
        return 1
    fi

    # Check prefix format is valid
    if [[ "$prefix" =~ ^[a-z]+_$ ]]; then
        echo "✓ Prefix format is valid: '$prefix'"
    else
        echo "✗ Invalid prefix format: '$prefix'"
        return 1
    fi

    # Test prefixed installation
    export FORCE_PREFIX=true  # Force prefixing even if no conflicts
    local result
    if result=$(install_adapter "spec-kit" 2>&1); then
        echo "✓ Installation with prefixing completed"
    else
        echo "✗ Prefixed installation failed: $result"
        return 1
    fi

    # Check that commands are installed with prefix
    if [[ -f "$PROJECT_ROOT/.claude/commands/${prefix}plan.md" ]]; then
        echo "✓ Plan command installed with prefix: ${prefix}plan.md"
    else
        echo "✗ Plan command not found with prefix"
        return 1
    fi

    if [[ -f "$PROJECT_ROOT/.claude/commands/${prefix}tasks.md" ]]; then
        echo "✓ Tasks command installed with prefix: ${prefix}tasks.md"
    else
        echo "✗ Tasks command not found with prefix"
        return 1
    fi

    if [[ -f "$PROJECT_ROOT/.claude/commands/${prefix}implement.md" ]]; then
        echo "✓ Implement command installed with prefix: ${prefix}implement.md"
    else
        echo "✗ Implement command not found with prefix"
        return 1
    fi

    # Check that original commands remain unchanged
    if grep -q "Existing plan command" "$PROJECT_ROOT/.claude/commands/plan.md"; then
        echo "✓ Original plan command preserved"
    else
        echo "✗ Original plan command was modified"
        return 1
    fi

    if grep -q "Existing tasks command" "$PROJECT_ROOT/.claude/commands/tasks.md"; then
        echo "✓ Original tasks command preserved"
    else
        echo "✗ Original tasks command was modified"
        return 1
    fi

    # Test custom prefix functionality
    export ADAPTER_PREFIX="custom_"
    mkdir -p "$TEST_DIR/tmp/another-adapter/commands"
    echo "# Another command" > "$TEST_DIR/tmp/another-adapter/commands/deploy.md"

    if result=$(install_adapter "another-adapter" 2>&1); then
        echo "✓ Installation with custom prefix completed"
    else
        echo "✗ Custom prefix installation failed: $result"
        return 1
    fi

    # Check custom prefix was used
    if [[ -f "$PROJECT_ROOT/.claude/commands/custom_deploy.md" ]]; then
        echo "✓ Custom prefix applied correctly: custom_deploy.md"
    else
        echo "✗ Custom prefix not applied"
        return 1
    fi

    echo "✓ Test passed: Automatic command prefixing"
    return 0
}

# Run the test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_command_prefixing
    exit $?
fi