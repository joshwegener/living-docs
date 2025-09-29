#!/bin/bash
set -euo pipefail
# Test: Update adapter while preserving user customizations (T007)
# Should update adapter files but preserve user customizations

set -e

# Setup test environment
export TEST_MODE=true
TEST_DIR=$(mktemp -d)
export PROJECT_ROOT="$TEST_DIR"

# Source the libraries (will be implemented)
source "$(dirname "$0")/../../lib/adapter/update.sh" 2>/dev/null || true
source "$(dirname "$0")/../../lib/adapter/manifest.sh" 2>/dev/null || true

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test function
test_update_adapter_customizations() {
    echo "Testing: Update adapter while preserving customizations"

    # Setup initial adapter installation
    mkdir -p ""$PROJECT_ROOT"/adapters/spec-kit"
    mkdir -p ""$PROJECT_ROOT"/.claude/commands"
    mkdir -p ""$PROJECT_ROOT"/tmp/spec-kit-v2/commands"

    # Create initial installed file
    cat > ""$PROJECT_ROOT"/.claude/commands/speckit_plan.md" <<'EOF'
# Plan Command v1.0
Default content from adapter.

# User Customization Section
This is my custom modification.
Custom rules and preferences.

More default content.
EOF

    # Create manifest for existing installation
    cat > ""$PROJECT_ROOT"/adapters/spec-kit/.living-docs-manifest.json" <<'EOF'
{
  "adapter": "spec-kit",
  "version": "1.0.0",
  "installed_at": "2024-01-01T00:00:00Z",
  "files": [
    {
      "source_path": "commands/plan.md",
      "target_path": ".claude/commands/speckit_plan.md",
      "original_path": "commands/plan.md"
    }
  ],
  "customizations": [
    {
      "file": ".claude/commands/speckit_plan.md",
      "sections": [
        {
          "marker": "# User Customization Section",
          "content": "This is my custom modification.\nCustom rules and preferences."
        }
      ]
    }
  ]
}
EOF

    # Create new version of adapter with updates
    cat > ""$PROJECT_ROOT"/tmp/spec-kit-v2/commands/plan.md" <<'EOF'
# Plan Command v2.0
Updated default content from adapter.
New feature added here.

More updated default content.
Additional functionality.
EOF

    # Verify customization exists before update
    if ! grep -q "This is my custom modification" ""$PROJECT_ROOT"/.claude/commands/speckit_plan.md"; then
        echo "✗ Setup failed: User customization not found"
        return 1
    fi

    # Run update
    local result
    if result=$(update_adapter "spec-kit" "2.0.0" 2>&1); then
        echo "✓ Adapter update completed successfully"
    else
        echo "✗ Adapter update failed: $result"
        return 1
    fi

    # Check that new content is present
    if ! grep -q "Plan Command v2.0" ""$PROJECT_ROOT"/.claude/commands/speckit_plan.md"; then
        echo "✗ New adapter content not found after update"
        return 1
    fi

    if ! grep -q "New feature added here" ""$PROJECT_ROOT"/.claude/commands/speckit_plan.md"; then
        echo "✗ New adapter features not found after update"
        return 1
    fi

    echo "✓ New adapter content successfully applied"

    # Check that user customizations are preserved
    if ! grep -q "This is my custom modification" ""$PROJECT_ROOT"/.claude/commands/speckit_plan.md"; then
        echo "✗ User customization lost during update"
        return 1
    fi

    if ! grep -q "Custom rules and preferences" ""$PROJECT_ROOT"/.claude/commands/speckit_plan.md"; then
        echo "✗ User customization details lost during update"
        return 1
    fi

    echo "✓ User customizations preserved during update"

    # Check manifest updated with new version
    if ! grep -q '"version": "2.0.0"' ""$PROJECT_ROOT"/adapters/spec-kit/.living-docs-manifest.json"; then
        echo "✗ Manifest version not updated"
        return 1
    fi

    echo "✓ Manifest updated with new version"

    # Check backup of previous version created
    if [[ ! -f ""$PROJECT_ROOT"/adapters/spec-kit/.living-docs-backup-1.0.0.json" ]]; then
        echo "✗ Backup of previous version not created"
        return 1
    fi

    echo "✓ Backup of previous version created"

    echo "✓ Test passed: Update with customization preservation"
    return 0
}

# Run the test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_update_adapter_customizations
    exit $?
fi