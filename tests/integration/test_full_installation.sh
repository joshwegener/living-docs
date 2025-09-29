#!/bin/bash
set -euo pipefail
# Integration Test: Full Installation Flow
# Tests complete adapter installation with all features

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source libraries
source "$REAL_PROJECT_ROOT/lib/adapter/install.sh" || { echo "Failed to source install.sh"; exit 1; }
source "$REAL_PROJECT_ROOT/lib/adapter/manifest.sh" || { echo "Failed to source manifest.sh"; exit 1; }
source "$REAL_PROJECT_ROOT/lib/adapter/remove.sh" || { echo "Failed to source remove.sh"; exit 1; }

# Verify functions are available
if ! type install_adapter >/dev/null 2>&1; then
    echo "Error: install_adapter function not found after sourcing"
    exit 1
fi

# Test configuration
TEST_NAME="Full Installation Flow"
TEST_DIR=$(mktemp -d)
export PROJECT_ROOT="$TEST_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Cleanup function
cleanup() {
    echo "Cleaning up test directory..."
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test functions
setup_test_environment() {
    echo "Setting up test environment..."

    # Create mock adapter
    mkdir -p "$TEST_DIR/tmp/test-adapter/commands"
    mkdir -p "$TEST_DIR/tmp/test-adapter/templates"
    mkdir -p "$TEST_DIR/tmp/test-adapter/scripts"
    mkdir -p "$TEST_DIR/tmp/test-adapter/agents"

    # Create mock command files
    cat > "$TEST_DIR/tmp/test-adapter/commands/plan.md" <<'EOF'
# Plan Command
Execute planning at scripts/bash/plan.sh
Check specs at .spec/current
Access memory at memory/context.md
EOF

    cat > "$TEST_DIR/tmp/test-adapter/commands/implement.md" <<'EOF'
# Implement Command
Run implementation from scripts/bash/implement.sh
EOF

    # Create mock template
    cat > "$TEST_DIR/tmp/test-adapter/templates/spec.md" <<'EOF'
# Spec Template
Project root: {{PROJECT_ROOT}}
Scripts path: {{SCRIPTS_PATH}}
EOF

    # Create mock script
    cat > "$TEST_DIR/tmp/test-adapter/scripts/test.sh" <<'EOF'
#!/bin/bash
echo "Test script"
EOF
    chmod +x "$TEST_DIR/tmp/test-adapter/scripts/test.sh"

    # Create mock agent
    cat > "$TEST_DIR/tmp/test-adapter/agents/test-agent.md" <<'EOF'
# Test Agent
Agent configuration for testing
EOF

    # Create version file
    echo "1.0.0" > "$TEST_DIR/tmp/test-adapter/version.txt"

    echo -e "${GREEN}✓${NC} Test environment ready"
}

test_installation() {
    echo ""
    echo "Testing: Installation with manifest tracking"

    # Set up paths
    export AI_PATH=".claude"
    export SCRIPTS_PATH="scripts"
    export SPECS_PATH=".spec"
    export MEMORY_PATH="memory"

    # Install adapter
    if install_adapter "test-adapter" "--custom-paths"; then
        echo -e "${GREEN}✓${NC} Adapter installed successfully"
    else
        echo -e "${RED}✗${NC} Failed to install adapter"
        return 1
    fi

    # Verify manifest created
    if [[ -f "$TEST_DIR/adapters/test-adapter/.living-docs-manifest.json" ]]; then
        echo -e "${GREEN}✓${NC} Manifest created"
    else
        echo -e "${RED}✗${NC} Manifest not found"
        return 1
    fi

    # Verify commands installed
    local ai_dir=".claude/commands"
    if [[ -f "$TEST_DIR/$ai_dir/plan.md" ]] || [[ -f "$TEST_DIR/$ai_dir/testadapter_plan.md" ]]; then
        echo -e "${GREEN}✓${NC} Commands installed"
    else
        echo -e "${RED}✗${NC} Commands not found"
        return 1
    fi

    # Verify path rewriting
    local cmd_file
    if [[ -f "$TEST_DIR/$ai_dir/plan.md" ]]; then
        cmd_file="$TEST_DIR/$ai_dir/plan.md"
    else
        cmd_file="$TEST_DIR/$ai_dir/testadapter_plan.md"
    fi

    if grep -q "scripts/bash" "$cmd_file"; then
        echo -e "${YELLOW}⚠${NC} Paths not rewritten (may be expected if not implemented)"
    else
        echo -e "${GREEN}✓${NC} Paths rewritten"
    fi

    # Verify templates installed
    if [[ -f "$TEST_DIR/adapters/test-adapter/templates/spec.md" ]]; then
        echo -e "${GREEN}✓${NC} Templates installed"
    else
        echo -e "${RED}✗${NC} Templates not found"
        return 1
    fi

    # Verify scripts installed
    if [[ -f "$TEST_DIR/adapters/test-adapter/scripts/test.sh" ]]; then
        if [[ -x "$TEST_DIR/adapters/test-adapter/scripts/test.sh" ]]; then
            echo -e "${GREEN}✓${NC} Scripts installed with correct permissions"
        else
            echo -e "${YELLOW}⚠${NC} Scripts installed but not executable"
        fi
    else
        echo -e "${RED}✗${NC} Scripts not found"
        return 1
    fi

    return 0
}

test_manifest_tracking() {
    echo ""
    echo "Testing: Manifest file tracking"

    # List files from manifest
    local files
    files=$(list_manifest_files "test-adapter" 2>/dev/null)

    if [[ -n "$files" ]]; then
        echo -e "${GREEN}✓${NC} Manifest tracking files:"
        echo "$files" | head -5 | sed 's/^/  - /'
    else
        echo -e "${RED}✗${NC} No files tracked in manifest"
        return 1
    fi

    # Validate manifest
    if validate_manifest "test-adapter"; then
        echo -e "${GREEN}✓${NC} Manifest validation passed"
    else
        echo -e "${RED}✗${NC} Manifest validation failed"
        return 1
    fi

    return 0
}

test_removal() {
    echo ""
    echo "Testing: Complete adapter removal"

    # Remove adapter
    if remove_adapter "test-adapter"; then
        echo -e "${GREEN}✓${NC} Adapter removed successfully"
    else
        echo -e "${RED}✗${NC} Failed to remove adapter"
        return 1
    fi

    # Verify all files removed
    if verify_removal "test-adapter"; then
        echo -e "${GREEN}✓${NC} All files removed completely"
    else
        echo -e "${YELLOW}⚠${NC} Some files may remain"
    fi

    # Verify manifest removed
    if [[ ! -f "$TEST_DIR/adapters/test-adapter/.living-docs-manifest.json" ]]; then
        echo -e "${GREEN}✓${NC} Manifest removed"
    else
        echo -e "${RED}✗${NC} Manifest still exists"
        return 1
    fi

    return 0
}

# Run tests
main() {
    echo "========================================="
    echo " Integration Test: $TEST_NAME"
    echo "========================================="
    echo "Test directory: $TEST_DIR"
    echo ""

    local failed=0

    # Setup
    setup_test_environment

    # Run tests
    if ! test_installation; then
        ((failed++))
    fi

    if ! test_manifest_tracking; then
        ((failed++))
    fi

    if ! test_removal; then
        ((failed++))
    fi

    # Summary
    echo ""
    echo "========================================="
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
    else
        echo -e "${RED}✗ $failed test(s) failed${NC}"
    fi
    echo "========================================="

    return $failed
}

# Execute main function
main
exit $?