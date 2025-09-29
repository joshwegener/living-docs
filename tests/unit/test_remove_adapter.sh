#!/bin/bash
set -euo pipefail
# Test: Complete adapter removal using manifest (T006)
# Should remove all files tracked in manifest and clean up directories

set -e

# Setup test environment
export TEST_MODE=true
TEST_DIR=$(mktemp -d)
export PROJECT_ROOT="$TEST_DIR"

# Source the libraries (will be implemented)
source "$(dirname "$0")/../../lib/adapter/remove.sh" 2>/dev/null || true
source "$(dirname "$0")/../../lib/adapter/manifest.sh" 2>/dev/null || true

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test function
test_remove_adapter() {
    echo "Testing: Complete adapter removal using manifest"

    # Setup mock installed adapter with manifest
    mkdir -p "$PROJECT_ROOT/adapters/spec-kit"
    mkdir -p "$PROJECT_ROOT/.claude/commands"
    mkdir -p "$PROJECT_ROOT/scripts"
    mkdir -p "$PROJECT_ROOT/templates"

    # Create installed files
    echo "# Plan command" > "$PROJECT_ROOT/.claude/commands/speckit_plan.md"
    echo "# Tasks command" > "$PROJECT_ROOT/.claude/commands/speckit_tasks.md"
    echo "#!/bin/bash" > "$PROJECT_ROOT/scripts/speckit_setup.sh"
    echo "# Template" > "$PROJECT_ROOT/templates/speckit_template.md"

    # Create manifest tracking these files
    cat > "$PROJECT_ROOT/adapters/spec-kit/.living-docs-manifest.json" <<'EOF'
{
  "adapter": "spec-kit",
  "version": "1.0.0",
  "installed_at": "2024-01-01T00:00:00Z",
  "files": [
    {
      "source_path": "commands/plan.md",
      "target_path": ".claude/commands/speckit_plan.md",
      "original_path": "commands/plan.md"
    },
    {
      "source_path": "commands/tasks.md",
      "target_path": ".claude/commands/speckit_tasks.md",
      "original_path": "commands/tasks.md"
    },
    {
      "source_path": "scripts/setup.sh",
      "target_path": "scripts/speckit_setup.sh",
      "original_path": "scripts/setup.sh"
    },
    {
      "source_path": "templates/template.md",
      "target_path": "templates/speckit_template.md",
      "original_path": "templates/template.md"
    }
  ]
}
EOF

    # Verify files exist before removal
    if [[ ! -f "$PROJECT_ROOT/.claude/commands/speckit_plan.md" ]]; then
        echo "✗ Setup failed: Test files not created"
        return 1
    fi

    # Run removal
    local result
    if result=$(remove_adapter "spec-kit" 2>&1); then
        echo "✓ Adapter removal completed successfully"
    else
        echo "✗ Adapter removal failed: $result"
        return 1
    fi

    # Check all tracked files are removed
    if [[ -f "$PROJECT_ROOT/.claude/commands/speckit_plan.md" ]]; then
        echo "✗ Command file still exists after removal"
        return 1
    fi

    if [[ -f "$PROJECT_ROOT/.claude/commands/speckit_tasks.md" ]]; then
        echo "✗ Tasks file still exists after removal"
        return 1
    fi

    if [[ -f "$PROJECT_ROOT/scripts/speckit_setup.sh" ]]; then
        echo "✗ Script file still exists after removal"
        return 1
    fi

    if [[ -f "$PROJECT_ROOT/templates/speckit_template.md" ]]; then
        echo "✗ Template file still exists after removal"
        return 1
    fi

    echo "✓ All tracked files removed successfully"

    # Check manifest and adapter directory removed
    if [[ -f "$PROJECT_ROOT/adapters/spec-kit/.living-docs-manifest.json" ]]; then
        echo "✗ Manifest file still exists after removal"
        return 1
    fi

    if [[ -d "$PROJECT_ROOT/adapters/spec-kit" ]]; then
        echo "✗ Adapter directory still exists after removal"
        return 1
    fi

    echo "✓ Manifest and adapter directory removed"

    # Check empty directories are cleaned up
    if [[ -d "$PROJECT_ROOT/.claude/commands" ]] && [[ -z "$(ls -A "$PROJECT_ROOT/.claude/commands")" ]]; then
        echo "✓ Empty command directory preserved (expected)"
    fi

    echo "✓ Test passed: Complete adapter removal"
    return 0
}

# Run the test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_remove_adapter
    exit $?
fi