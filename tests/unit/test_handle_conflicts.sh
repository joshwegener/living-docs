#!/bin/bash
# Test: Detection and resolution of command conflicts (T010)
# Should handle various conflict scenarios and resolution strategies

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
test_handle_conflicts() {
    echo "Testing: Detection and resolution of command conflicts"

    # Setup existing project with commands from multiple sources
    mkdir -p "$PROJECT_ROOT/.claude/commands"
    mkdir -p "$PROJECT_ROOT/adapters/existing-adapter"

    # Create existing commands
    echo "# Original plan command" > "$PROJECT_ROOT/.claude/commands/plan.md"
    echo "# Original tasks command" > "$PROJECT_ROOT/.claude/commands/tasks.md"
    echo "# Aider plan command" > "$PROJECT_ROOT/.claude/commands/aider_plan.md"
    echo "# Custom command" > "$PROJECT_ROOT/.claude/commands/deploy.md"

    # Create manifest for existing adapter
    cat > "$PROJECT_ROOT/adapters/existing-adapter/.living-docs-manifest.json" <<'EOF'
{
  "adapter": "existing-adapter",
  "version": "1.0.0",
  "files": [
    {
      "target_path": ".claude/commands/plan.md"
    },
    {
      "target_path": ".claude/commands/tasks.md"
    }
  ]
}
EOF

    # Setup new adapter with conflicting commands
    mkdir -p "$TEST_DIR/tmp/new-adapter/commands"
    echo "# New plan command" > "$TEST_DIR/tmp/new-adapter/commands/plan.md"
    echo "# New tasks command" > "$TEST_DIR/tmp/new-adapter/commands/tasks.md"
    echo "# New unique command" > "$TEST_DIR/tmp/new-adapter/commands/review.md"

    # Test comprehensive conflict detection
    local conflicts
    if conflicts=$(analyze_conflicts "new-adapter" 2>&1); then
        echo "✓ Conflict analysis completed"
    else
        echo "✗ Conflict analysis failed: $conflicts"
        return 1
    fi

    # Check detection of adapter-managed conflicts
    if echo "$conflicts" | grep -q "ADAPTER_CONFLICT.*plan.md.*existing-adapter"; then
        echo "✓ Detected adapter-managed conflict for plan.md"
    else
        echo "✗ Failed to detect adapter-managed conflict"
        return 1
    fi

    # Check detection of user-created conflicts
    if echo "$conflicts" | grep -q "USER_CONFLICT.*deploy.md"; then
        echo "✓ Detected user-created conflict for deploy.md"
    else
        echo "✗ Failed to detect user-created conflict"
        return 1
    fi

    # Check detection of prefixed commands (should not conflict)
    if echo "$conflicts" | grep -q "aider_plan.md"; then
        echo "✗ Incorrectly flagged prefixed command as conflict"
        return 1
    else
        echo "✓ Correctly ignored prefixed commands"
    fi

    # Test conflict resolution: skip conflicting files
    export CONFLICT_RESOLUTION="skip"
    local result
    if result=$(install_adapter "new-adapter" 2>&1); then
        echo "✓ Installation with skip resolution completed"
    else
        echo "✗ Skip resolution installation failed: $result"
        return 1
    fi

    # Check that conflicting files were skipped
    if grep -q "Original plan command" "$PROJECT_ROOT/.claude/commands/plan.md"; then
        echo "✓ Conflicting plan.md was skipped (original preserved)"
    else
        echo "✗ Conflicting plan.md was not skipped"
        return 1
    fi

    # Check that non-conflicting files were installed
    if [[ -f "$PROJECT_ROOT/.claude/commands/review.md" ]]; then
        echo "✓ Non-conflicting review.md was installed"
    else
        echo "✗ Non-conflicting file was not installed"
        return 1
    fi

    # Test conflict resolution: force overwrite
    export CONFLICT_RESOLUTION="overwrite"
    mkdir -p "$TEST_DIR/tmp/force-adapter/commands"
    echo "# Force plan command" > "$TEST_DIR/tmp/force-adapter/commands/plan.md"
    echo "# Force deploy command" > "$TEST_DIR/tmp/force-adapter/commands/deploy.md"

    if result=$(install_adapter "force-adapter" 2>&1); then
        echo "✓ Installation with overwrite resolution completed"
    else
        echo "✗ Overwrite resolution installation failed: $result"
        return 1
    fi

    # Check that files were overwritten
    if grep -q "Force plan command" "$PROJECT_ROOT/.claude/commands/plan.md"; then
        echo "✓ Conflicting plan.md was overwritten"
    else
        echo "✗ File was not overwritten"
        return 1
    fi

    if grep -q "Force deploy command" "$PROJECT_ROOT/.claude/commands/deploy.md"; then
        echo "✓ User-created file was overwritten"
    else
        echo "✗ User-created file was not overwritten"
        return 1
    fi

    # Test conflict resolution: automatic prefixing
    export CONFLICT_RESOLUTION="prefix"
    mkdir -p "$TEST_DIR/tmp/prefix-adapter/commands"
    echo "# Prefix plan command" > "$TEST_DIR/tmp/prefix-adapter/commands/plan.md"
    echo "# Prefix tasks command" > "$TEST_DIR/tmp/prefix-adapter/commands/tasks.md"

    if result=$(install_adapter "prefix-adapter" 2>&1); then
        echo "✓ Installation with prefix resolution completed"
    else
        echo "✗ Prefix resolution installation failed: $result"
        return 1
    fi

    # Check that files were installed with prefix
    local prefix_files
    prefix_files=$(find "$PROJECT_ROOT/.claude/commands" -name "*prefix*plan.md" 2>/dev/null || true)
    if [[ -n "$prefix_files" ]]; then
        echo "✓ Conflicting files installed with prefix"
    else
        echo "✗ Prefixed files not found"
        return 1
    fi

    # Check original files preserved
    if grep -q "Force plan command" "$PROJECT_ROOT/.claude/commands/plan.md"; then
        echo "✓ Original files preserved during prefix resolution"
    else
        echo "✗ Original files were modified during prefix resolution"
        return 1
    fi

    # Test interactive conflict resolution (mock user input)
    export CONFLICT_RESOLUTION="interactive"
    export MOCK_USER_INPUT="s\no\np\n"  # skip, overwrite, prefix for three conflicts
    mkdir -p "$TEST_DIR/tmp/interactive-adapter/commands"
    echo "# Interactive plan" > "$TEST_DIR/tmp/interactive-adapter/commands/plan.md"
    echo "# Interactive tasks" > "$TEST_DIR/tmp/interactive-adapter/commands/tasks.md"
    echo "# Interactive deploy" > "$TEST_DIR/tmp/interactive-adapter/commands/deploy.md"

    if result=$(install_adapter "interactive-adapter" 2>&1); then
        echo "✓ Interactive resolution completed"
    else
        echo "✗ Interactive resolution failed: $result"
        return 1
    fi

    echo "✓ Test passed: Conflict detection and resolution"
    return 0
}

# Run the test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_handle_conflicts
    exit $?
fi