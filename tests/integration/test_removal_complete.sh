#!/bin/bash
set -euo pipefail
# Integration Test T032: Complete Removal Verification
# Verifies complete cleanup after adapter removal

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
TEST_NAME="Complete Removal Verification (T032)"
TEST_DIR=$(mktemp -d)

# Source libraries with original project root
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/install.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/manifest.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/remove.sh"

# Now set test environment
export PROJECT_ROOT="$TEST_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up test directory...${NC}"
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Test assertion function
assert_test() {
    local test_description="$1"
    local condition="$2"

    if eval "$condition"; then
        echo -e "${GREEN}✓ PASS:${NC} $test_description"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL:${NC} $test_description"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Setup test environment with comprehensive adapter
setup_test_environment() {
    echo -e "${BLUE}Setting up test environment with comprehensive adapter...${NC}"

    # Create project structure
    mkdir -p "$TEST_DIR/.claude/commands"
    mkdir -p "$TEST_DIR/scripts/automation"
    mkdir -p "$TEST_DIR/scripts/utils"
    mkdir -p "$TEST_DIR/specs"
    mkdir -p "$TEST_DIR/memory"
    mkdir -p "$TEST_DIR/templates/project"
    mkdir -p "$TEST_DIR/templates/config"
    mkdir -p "$TEST_DIR/docs"

    # Create comprehensive adapter with all file types
    mkdir -p "$TEST_DIR/tmp/comprehensive/commands"
    mkdir -p "$TEST_DIR/tmp/comprehensive/templates/project"
    mkdir -p "$TEST_DIR/tmp/comprehensive/templates/config"
    mkdir -p "$TEST_DIR/tmp/comprehensive/scripts/automation"
    mkdir -p "$TEST_DIR/tmp/comprehensive/scripts/utils"
    mkdir -p "$TEST_DIR/tmp/comprehensive/docs"

    # Commands (multiple files)
    cat > "$TEST_DIR/tmp/comprehensive/commands/plan.md" <<'EOF'
# Plan Command
Execute planning workflow
Check specs at .spec/current
EOF

    cat > "$TEST_DIR/tmp/comprehensive/commands/implement.md" <<'EOF'
# Implementation Command
Run implementation scripts
EOF

    cat > "$TEST_DIR/tmp/comprehensive/commands/test.md" <<'EOF'
# Test Command
Execute test suites
EOF

    cat > "$TEST_DIR/tmp/comprehensive/commands/deploy.md" <<'EOF'
# Deploy Command
Handle deployment workflows
EOF

    # Templates (nested structure)
    cat > "$TEST_DIR/tmp/comprehensive/templates/project/readme.md" <<'EOF'
# Project README Template
Scripts: scripts/bash/
Specs: .spec/
EOF

    cat > "$TEST_DIR/tmp/comprehensive/templates/project/gitignore.txt" <<'EOF'
# Gitignore Template
*.log
.tmp/
EOF

    cat > "$TEST_DIR/tmp/comprehensive/templates/config/settings.yml" <<'EOF'
# Settings Template
scripts_path: scripts/bash/
memory_path: memory/
EOF

    cat > "$TEST_DIR/tmp/comprehensive/templates/config/database.yml" <<'EOF'
# Database Template
host: localhost
port: 5432
EOF

    # Scripts (nested structure)
    cat > "$TEST_DIR/tmp/comprehensive/scripts/automation/setup.sh" <<'EOF'
#!/bin/bash
echo "Setup automation script"
EOF

    cat > "$TEST_DIR/tmp/comprehensive/scripts/automation/deploy.sh" <<'EOF'
#!/bin/bash
echo "Deploy automation script"
EOF

    cat > "$TEST_DIR/tmp/comprehensive/scripts/utils/helpers.sh" <<'EOF'
#!/bin/bash
echo "Helper utilities"
EOF

    cat > "$TEST_DIR/tmp/comprehensive/scripts/cleanup.sh" <<'EOF'
#!/bin/bash
echo "Cleanup script"
EOF

    # Documentation
    cat > "$TEST_DIR/tmp/comprehensive/docs/guide.md" <<'EOF'
# User Guide
Complete documentation for the adapter
EOF

    cat > "$TEST_DIR/tmp/comprehensive/docs/api.md" <<'EOF'
# API Documentation
API reference documentation
EOF

    # Mark scripts as executable
    chmod +x "$TEST_DIR/tmp/comprehensive/scripts/automation/setup.sh"
    chmod +x "$TEST_DIR/tmp/comprehensive/scripts/automation/deploy.sh"
    chmod +x "$TEST_DIR/tmp/comprehensive/scripts/utils/helpers.sh"
    chmod +x "$TEST_DIR/tmp/comprehensive/scripts/cleanup.sh"
}

# Track initial state before installation
track_initial_state() {
    echo -e "${BLUE}Tracking initial state...${NC}"

    # Create state tracking files
    find "$TEST_DIR" -type f > "$TEST_DIR/initial_files.txt"
    find "$TEST_DIR" -type d > "$TEST_DIR/initial_dirs.txt"

    # Count initial state
    INITIAL_FILE_COUNT=$(cat "$TEST_DIR/initial_files.txt" | grep -v tmp | wc -l)
    INITIAL_DIR_COUNT=$(cat "$TEST_DIR/initial_dirs.txt" | grep -v tmp | wc -l)

    echo "Initial state: $INITIAL_FILE_COUNT files, $INITIAL_DIR_COUNT directories"
}

# Test 1: Install comprehensive adapter
test_install_comprehensive_adapter() {
    echo -e "${BLUE}Test 1: Installing comprehensive adapter...${NC}"

    # Install the adapter
    ADAPTER_PATH="$TEST_DIR/tmp/comprehensive" install_adapter "comprehensive"
    assert_test "Comprehensive adapter installed" "[ -f '$TEST_DIR/adapters/comprehensive/.living-docs-manifest.json' ]"

    # Count installed files
    local manifest_file="$TEST_DIR/adapters/comprehensive/.living-docs-manifest.json"
    if [ -f "$manifest_file" ]; then
        local installed_count=$(jq -r '.installed_files | length' "$manifest_file" 2>/dev/null || echo "0")
        assert_test "Multiple files installed" "[ '$installed_count' -gt 10 ]"
    fi

    # Verify different file types are installed (commands have prefix)
    assert_test "Commands installed" "[ -f '$TEST_DIR/.claude/commands/comprehensive_plan.md' ]"
    assert_test "Nested templates installed" "[ -f '$TEST_DIR/adapters/comprehensive/templates/project/readme.md' ]"
    assert_test "Nested scripts installed" "[ -f '$TEST_DIR/adapters/comprehensive/scripts/automation/setup.sh' ]"
    assert_test "Documentation installed" "[ -f '$TEST_DIR/adapters/comprehensive/docs/guide.md' ]"

    # Verify nested directory structure
    assert_test "Nested template config dir exists" "[ -d '$TEST_DIR/adapters/comprehensive/templates/config' ]"
    assert_test "Nested script automation dir exists" "[ -d '$TEST_DIR/adapters/comprehensive/scripts/automation' ]"
    assert_test "Nested script utils dir exists" "[ -d '$TEST_DIR/adapters/comprehensive/scripts/utils' ]"
}

# Test 2: Track state after installation
test_track_installation_state() {
    echo -e "${BLUE}Test 2: Tracking post-installation state...${NC}"

    # Create post-installation state
    find "$TEST_DIR" -type f > "$TEST_DIR/post_install_files.txt"
    find "$TEST_DIR" -type d > "$TEST_DIR/post_install_dirs.txt"

    # Count post-installation state
    POST_INSTALL_FILE_COUNT=$(cat "$TEST_DIR/post_install_files.txt" | grep -v tmp | wc -l)
    POST_INSTALL_DIR_COUNT=$(cat "$TEST_DIR/post_install_dirs.txt" | grep -v tmp | wc -l)

    assert_test "Files were added during installation" "[ $POST_INSTALL_FILE_COUNT -gt $INITIAL_FILE_COUNT ]"
    assert_test "Directories were added during installation" "[ $POST_INSTALL_DIR_COUNT -ge $INITIAL_DIR_COUNT ]"

    echo "Post-installation: $POST_INSTALL_FILE_COUNT files, $POST_INSTALL_DIR_COUNT directories"

    # Calculate added files
    ADDED_FILES=$((POST_INSTALL_FILE_COUNT - INITIAL_FILE_COUNT))
    echo "Added $ADDED_FILES files during installation"
}

# Test 3: Add some custom files that should not be removed
test_add_custom_files() {
    echo -e "${BLUE}Test 3: Adding custom files that should not be removed...${NC}"

    # Add custom files in same directories
    cat > "$TEST_DIR/.claude/commands/my-custom-command.md" <<'EOF'
# My Custom Command
This is a custom command that should not be removed
EOF

    cat > "$TEST_DIR/templates/my-custom-template.md" <<'EOF'
# My Custom Template
This is a custom template
EOF

    cat > "$TEST_DIR/scripts/my-custom-script.sh" <<'EOF'
#!/bin/bash
echo "My custom script"
EOF

    chmod +x "$TEST_DIR/scripts/my-custom-script.sh"

    # These custom files should not be removed
    assert_test "Custom command exists" "[ -f '$TEST_DIR/.claude/commands/my-custom-command.md' ]"
    assert_test "Custom template exists" "[ -f '$TEST_DIR/templates/my-custom-template.md' ]"
    assert_test "Custom script exists" "[ -f '$TEST_DIR/scripts/my-custom-script.sh' ]"
}

# Test 4: Remove adapter and verify complete cleanup
test_remove_adapter() {
    echo -e "${BLUE}Test 4: Removing adapter and verifying cleanup...${NC}"

    # Remove the adapter
    remove_adapter "comprehensive"

    # Verify manifest is removed
    assert_test "Manifest removed" "[ ! -f '$TEST_DIR/.living-docs-comprehensive-manifest.json' ]"

    # Verify all adapter files are removed
    assert_test "Plan command removed" "[ ! -f '$TEST_DIR/.claude/commands/plan.md' ]"
    assert_test "Implement command removed" "[ ! -f '$TEST_DIR/.claude/commands/implement.md' ]"
    assert_test "Test command removed" "[ ! -f '$TEST_DIR/.claude/commands/test.md' ]"
    assert_test "Deploy command removed" "[ ! -f '$TEST_DIR/.claude/commands/deploy.md' ]"

    # Verify nested template files are removed
    assert_test "Project readme removed" "[ ! -f '$TEST_DIR/templates/project/readme.md' ]"
    assert_test "Project gitignore removed" "[ ! -f '$TEST_DIR/templates/project/gitignore.txt' ]"
    assert_test "Config settings removed" "[ ! -f '$TEST_DIR/templates/config/settings.yml' ]"
    assert_test "Config database removed" "[ ! -f '$TEST_DIR/templates/config/database.yml' ]"

    # Verify nested script files are removed
    assert_test "Automation setup removed" "[ ! -f '$TEST_DIR/scripts/automation/setup.sh' ]"
    assert_test "Automation deploy removed" "[ ! -f '$TEST_DIR/scripts/automation/deploy.sh' ]"
    assert_test "Utils helpers removed" "[ ! -f '$TEST_DIR/scripts/utils/helpers.sh' ]"
    assert_test "Cleanup script removed" "[ ! -f '$TEST_DIR/scripts/cleanup.sh' ]"

    # Verify documentation files are removed
    assert_test "Guide documentation removed" "[ ! -f '$TEST_DIR/docs/guide.md' ]"
    assert_test "API documentation removed" "[ ! -f '$TEST_DIR/docs/api.md' ]"
}

# Test 5: Verify custom files are preserved
test_custom_files_preserved() {
    echo -e "${BLUE}Test 5: Verifying custom files are preserved...${NC}"

    # Custom files should still exist
    assert_test "Custom command preserved" "[ -f '$TEST_DIR/.claude/commands/my-custom-command.md' ]"
    assert_test "Custom template preserved" "[ -f '$TEST_DIR/templates/my-custom-template.md' ]"
    assert_test "Custom script preserved" "[ -f '$TEST_DIR/scripts/my-custom-script.sh' ]"

    # Verify custom file content is unchanged
    assert_test "Custom command content intact" "grep -q 'should not be removed' '$TEST_DIR/.claude/commands/my-custom-command.md'"
    assert_test "Custom template content intact" "grep -q 'custom template' '$TEST_DIR/templates/my-custom-template.md'"
    assert_test "Custom script content intact" "grep -q 'My custom script' '$TEST_DIR/scripts/my-custom-script.sh'"
}

# Test 6: Verify empty directories are cleaned up
test_empty_directory_cleanup() {
    echo -e "${BLUE}Test 6: Verifying empty directories are cleaned up...${NC}"

    # Check if empty directories created by the adapter are removed
    # Note: This depends on the remove.sh implementation

    # These directories should be removed if they're empty
    # (but preserved if they contain custom files)
    assert_test "Empty automation directory removed or preserved correctly" "[ ! -d '$TEST_DIR/scripts/automation' ] || [ -n \"$(find '$TEST_DIR/scripts/automation' -type f)\" ]"
    assert_test "Empty utils directory removed or preserved correctly" "[ ! -d '$TEST_DIR/scripts/utils' ] || [ -n \"$(find '$TEST_DIR/scripts/utils' -type f)\" ]"
    assert_test "Empty project template directory removed or preserved correctly" "[ ! -d '$TEST_DIR/templates/project' ] || [ -n \"$(find '$TEST_DIR/templates/project' -type f)\" ]"
    assert_test "Empty config template directory removed or preserved correctly" "[ ! -d '$TEST_DIR/templates/config' ] || [ -n \"$(find '$TEST_DIR/templates/config' -type f)\" ]"

    # Main directories should still exist (they contain custom files)
    assert_test "Main commands directory preserved" "[ -d '$TEST_DIR/.claude/commands' ]"
    assert_test "Main templates directory preserved" "[ -d '$TEST_DIR/templates' ]"
    assert_test "Main scripts directory preserved" "[ -d '$TEST_DIR/scripts' ]"
}

# Test 7: Verify no orphan files remain
test_no_orphan_files() {
    echo -e "${BLUE}Test 7: Verifying no orphan files remain...${NC}"

    # Create post-removal state
    find "$TEST_DIR" -type f > "$TEST_DIR/post_removal_files.txt"
    find "$TEST_DIR" -type d > "$TEST_DIR/post_removal_dirs.txt"

    # Count post-removal state
    POST_REMOVAL_FILE_COUNT=$(cat "$TEST_DIR/post_removal_files.txt" | grep -v tmp | wc -l)

    # Should have removed most adapter files, but kept custom files
    # So we should have more than initial but fewer than post-install
    EXPECTED_FILE_COUNT=$((INITIAL_FILE_COUNT + 3))  # 3 custom files added

    assert_test "File count is reasonable after removal" "[ $POST_REMOVAL_FILE_COUNT -le $((EXPECTED_FILE_COUNT + 2)) ]"
    assert_test "File count includes custom files" "[ $POST_REMOVAL_FILE_COUNT -ge $EXPECTED_FILE_COUNT ]"

    echo "Post-removal: $POST_REMOVAL_FILE_COUNT files"
    echo "Expected approximately: $EXPECTED_FILE_COUNT files"

    # Verify no adapter-specific files remain
    local adapter_files=$(find "$TEST_DIR" -name "*comprehensive*" -o -name "*plan.md" -o -name "*implement.md" | grep -v tmp | wc -l)
    assert_test "No adapter-specific files remain" "[ $adapter_files -eq 0 ]"
}

# Test 8: Test multiple install/remove cycles
test_multiple_cycles() {
    echo -e "${BLUE}Test 8: Testing multiple install/remove cycles...${NC}"

    # Install again
    ADAPTER_PATH="$TEST_DIR/tmp/comprehensive" install_adapter "comprehensive-2"
    assert_test "Second installation successful" "[ -f '$TEST_DIR/.living-docs-comprehensive-2-manifest.json' ]"

    # Remove again
    remove_adapter "comprehensive-2"
    assert_test "Second removal successful" "[ ! -f '$TEST_DIR/.living-docs-comprehensive-2-manifest.json' ]"

    # Verify custom files still exist after multiple cycles
    assert_test "Custom files survive multiple cycles" "[ -f '$TEST_DIR/.claude/commands/my-custom-command.md' ]"

    # Final file count should be stable
    find "$TEST_DIR" -type f > "$TEST_DIR/final_files.txt"
    FINAL_FILE_COUNT=$(cat "$TEST_DIR/final_files.txt" | grep -v tmp | wc -l)

    assert_test "File count stable after multiple cycles" "[ $FINAL_FILE_COUNT -eq $POST_REMOVAL_FILE_COUNT ]"
}

# Main test execution
main() {
    echo -e "${BLUE}Starting $TEST_NAME${NC}"
    echo "Test directory: $TEST_DIR"
    echo ""

    setup_test_environment
    track_initial_state
    test_install_comprehensive_adapter
    test_track_installation_state
    test_add_custom_files
    test_remove_adapter
    test_custom_files_preserved
    test_empty_directory_cleanup
    test_no_orphan_files
    test_multiple_cycles

    echo ""
    echo -e "${BLUE}Test Summary:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run main function
main "$@"