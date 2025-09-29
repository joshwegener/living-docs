#!/bin/bash
set -euo pipefail
# Integration Test T031: Update Workflow with Customizations
# Tests full update cycle preserving customizations

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
TEST_NAME="Update Workflow with Customizations (T031)"
TEST_DIR=$(mktemp -d)

# Source libraries with original project root
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/install.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/manifest.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/remove.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/update.sh"

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

# Setup test environment
setup_test_environment() {
    echo -e "${BLUE}Setting up test environment for update workflow...${NC}"

    # Create project structure
    mkdir -p "$TEST_DIR/.claude/commands"
    mkdir -p "$TEST_DIR/scripts"
    mkdir -p "$TEST_DIR/specs"
    mkdir -p "$TEST_DIR/memory"
    mkdir -p "$TEST_DIR/templates"

    # Create initial adapter version (v1.0)
    mkdir -p "$TEST_DIR/tmp/update-adapter-v1/commands"
    mkdir -p "$TEST_DIR/tmp/update-adapter-v1/templates"
    mkdir -p "$TEST_DIR/tmp/update-adapter-v1/scripts"

    cat > "$TEST_DIR/tmp/update-adapter-v1/commands/plan.md" <<'EOF'
# Plan Command v1.0
Execute planning at scripts/bash/plan.sh
Check specs at .spec/current
This is the original plan command.
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v1/commands/implement.md" <<'EOF'
# Implementation Command v1.0
Run implementation scripts
Original implementation workflow.
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v1/templates/config.yml" <<'EOF'
# Configuration Template v1.0
version: "1.0"
scripts_path: scripts/bash/
specs_path: .spec/
memory_path: memory/
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v1/templates/readme.md" <<'EOF'
# Project README v1.0
This is the original README template.
Scripts: scripts/bash/
Specs: .spec/
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v1/scripts/setup.sh" <<'EOF'
#!/bin/bash
# Setup script v1.0
echo "Original setup script"
echo "Version 1.0"
EOF

    # Create updated adapter version (v2.0)
    mkdir -p "$TEST_DIR/tmp/update-adapter-v2/commands"
    mkdir -p "$TEST_DIR/tmp/update-adapter-v2/templates"
    mkdir -p "$TEST_DIR/tmp/update-adapter-v2/scripts"

    cat > "$TEST_DIR/tmp/update-adapter-v2/commands/plan.md" <<'EOF'
# Plan Command v2.0
Execute planning at scripts/bash/plan.sh
Check specs at .spec/current
This is the UPDATED plan command with new features.
Added: Enhanced planning workflow.
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v2/commands/implement.md" <<'EOF'
# Implementation Command v2.0
Run implementation scripts
UPDATED implementation workflow with improvements.
Added: Better error handling.
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v2/commands/deploy.md" <<'EOF'
# Deploy Command v2.0 (NEW)
Handle deployment workflows
This is a brand new command in v2.0.
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v2/templates/config.yml" <<'EOF'
# Configuration Template v2.0
version: "2.0"
scripts_path: scripts/bash/
specs_path: .spec/
memory_path: memory/
# New configuration options
deploy_path: deploy/
new_feature: enabled
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v2/templates/readme.md" <<'EOF'
# Project README v2.0
This is the UPDATED README template with new content.
Scripts: scripts/bash/
Specs: .spec/
Deploy: deploy/
NEW: Added deployment instructions.
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v2/scripts/setup.sh" <<'EOF'
#!/bin/bash
# Setup script v2.0
echo "UPDATED setup script"
echo "Version 2.0"
echo "New features added"
EOF

    cat > "$TEST_DIR/tmp/update-adapter-v2/scripts/deploy.sh" <<'EOF'
#!/bin/bash
# Deploy script v2.0 (NEW)
echo "New deployment script"
echo "Added in version 2.0"
EOF
}

# Test 1: Install initial adapter version
test_install_initial_version() {
    echo -e "${BLUE}Test 1: Installing initial adapter version...${NC}"

    # Install v1.0
    ADAPTER_PATH="$TEST_DIR/tmp/update-adapter-v1" install_adapter "update-test"
    assert_test "Initial adapter installed" "[ -f '$TEST_DIR/.living-docs-update-test-manifest.json' ]"

    # Verify initial files
    assert_test "Initial plan.md exists" "[ -f '$TEST_DIR/.claude/commands/plan.md' ]"
    assert_test "Initial implement.md exists" "[ -f '$TEST_DIR/.claude/commands/implement.md' ]"
    assert_test "Initial config.yml exists" "[ -f '$TEST_DIR/templates/config.yml' ]"
    assert_test "Initial setup.sh exists" "[ -f '$TEST_DIR/scripts/setup.sh' ]"

    # Verify content
    assert_test "Plan contains v1.0 content" "grep -q 'original plan command' '$TEST_DIR/.claude/commands/plan.md'"
    assert_test "Config contains v1.0 version" "grep -q 'version: \"1.0\"' '$TEST_DIR/templates/config.yml'"
}

# Test 2: Customize some files
test_customize_files() {
    echo -e "${BLUE}Test 2: Customizing installed files...${NC}"

    # Customize plan.md
    cat >> "$TEST_DIR/.claude/commands/plan.md" <<'EOF'

# CUSTOM ADDITION
This is my custom addition to the plan command.
Custom workflow: my-custom-workflow.sh
EOF

    # Customize config.yml
    cat >> "$TEST_DIR/templates/config.yml" <<'EOF'

# CUSTOM CONFIGURATION
my_custom_setting: true
custom_path: custom/path/
EOF

    # Leave implement.md and setup.sh unchanged (these should be updated)

    # Create a completely custom file that shouldn't be touched
    cat > "$TEST_DIR/.claude/commands/my-custom-command.md" <<'EOF'
# My Custom Command
This is completely custom and should never be touched by updates.
EOF

    # Verify customizations were added
    assert_test "Plan.md customized" "grep -q 'CUSTOM ADDITION' '$TEST_DIR/.claude/commands/plan.md'"
    assert_test "Config.yml customized" "grep -q 'CUSTOM CONFIGURATION' '$TEST_DIR/templates/config.yml'"
    assert_test "Custom command created" "[ -f '$TEST_DIR/.claude/commands/my-custom-command.md' ]"
}

# Test 3: Simulate upstream changes and run update
test_run_update() {
    echo -e "${BLUE}Test 3: Running update to v2.0...${NC}"

    # Update to v2.0
    ADAPTER_PATH="$TEST_DIR/tmp/update-adapter-v2" update_adapter "update-test"

    # Verify update completed
    assert_test "Adapter updated successfully" "[ -f '$TEST_DIR/.living-docs-update-test-manifest.json' ]"

    # Check that new files were added
    assert_test "New deploy.md command added" "[ -f '$TEST_DIR/.claude/commands/deploy.md' ]"
    assert_test "New deploy.sh script added" "[ -f '$TEST_DIR/scripts/deploy.sh' ]"

    # Verify new content
    assert_test "Deploy command has correct content" "grep -q 'Handle deployment workflows' '$TEST_DIR/.claude/commands/deploy.md'"
    assert_test "Deploy script has correct content" "grep -q 'New deployment script' '$TEST_DIR/scripts/deploy.sh'"
}

# Test 4: Verify customizations were preserved
test_customizations_preserved() {
    echo -e "${BLUE}Test 4: Verifying customizations were preserved...${NC}"

    # Check that customized files retained custom content
    assert_test "Plan.md custom content preserved" "grep -q 'CUSTOM ADDITION' '$TEST_DIR/.claude/commands/plan.md'"
    assert_test "Plan.md custom workflow preserved" "grep -q 'my-custom-workflow.sh' '$TEST_DIR/.claude/commands/plan.md'"

    assert_test "Config.yml custom settings preserved" "grep -q 'CUSTOM CONFIGURATION' '$TEST_DIR/templates/config.yml'"
    assert_test "Config.yml custom path preserved" "grep -q 'custom_path: custom/path/' '$TEST_DIR/templates/config.yml'"

    # Check that completely custom files are untouched
    assert_test "Custom command file preserved" "[ -f '$TEST_DIR/.claude/commands/my-custom-command.md' ]"
    assert_test "Custom command content unchanged" "grep -q 'completely custom and should never be touched' '$TEST_DIR/.claude/commands/my-custom-command.md'"

    # Verify that customized files also got upstream updates (merged)
    assert_test "Plan.md has upstream v2.0 updates" "grep -q 'Enhanced planning workflow' '$TEST_DIR/.claude/commands/plan.md'"
    assert_test "Config.yml has upstream v2.0 updates" "grep -q 'version: \"2.0\"' '$TEST_DIR/templates/config.yml'"
    assert_test "Config.yml has new v2.0 features" "grep -q 'new_feature: enabled' '$TEST_DIR/templates/config.yml'"
}

# Test 5: Check that non-customized files were updated
test_non_customized_files_updated() {
    echo -e "${BLUE}Test 5: Verifying non-customized files were updated...${NC}"

    # implement.md was not customized, so should be completely replaced
    assert_test "Implement.md updated to v2.0" "grep -q 'Implementation Command v2.0' '$TEST_DIR/.claude/commands/implement.md'"
    assert_test "Implement.md has new features" "grep -q 'Better error handling' '$TEST_DIR/.claude/commands/implement.md'"
    assert_test "Implement.md old content replaced" "! grep -q 'Original implementation workflow' '$TEST_DIR/.claude/commands/implement.md'"

    # setup.sh was not customized, so should be completely replaced
    assert_test "Setup.sh updated to v2.0" "grep -q 'UPDATED setup script' '$TEST_DIR/scripts/setup.sh'"
    assert_test "Setup.sh shows v2.0" "grep -q 'Version 2.0' '$TEST_DIR/scripts/setup.sh'"
    assert_test "Setup.sh old content replaced" "! grep -q 'Original setup script' '$TEST_DIR/scripts/setup.sh'"

    # readme.md was not customized, should be updated
    assert_test "README.md updated to v2.0" "grep -q 'Project README v2.0' '$TEST_DIR/templates/readme.md'"
    assert_test "README.md has new content" "grep -q 'Added deployment instructions' '$TEST_DIR/templates/readme.md'"
}

# Test 6: Verify manifest tracks the update
test_manifest_tracking() {
    echo -e "${BLUE}Test 6: Verifying manifest tracks the update...${NC}"

    local manifest_file="$TEST_DIR/.living-docs-update-test-manifest.json"

    if [ -f "$manifest_file" ]; then
        # Check that manifest has update information
        local update_date=$(jq -r '.last_update_date' "$manifest_file" 2>/dev/null || echo "null")
        assert_test "Update date recorded in manifest" "[ '$update_date' != 'null' ]"

        # Check that manifest tracks all current files
        local file_count=$(jq -r '.installed_files | length' "$manifest_file" 2>/dev/null || echo "0")
        assert_test "Manifest tracks installed files" "[ '$file_count' -gt 5 ]"

        # Verify new files are in manifest
        local has_deploy_md=$(jq -r '.installed_files[] | select(.path == ".claude/commands/deploy.md")' "$manifest_file" 2>/dev/null | wc -l)
        local has_deploy_sh=$(jq -r '.installed_files[] | select(.path == "scripts/deploy.sh")' "$manifest_file" 2>/dev/null | wc -l)

        assert_test "Deploy.md tracked in manifest" "[ '$has_deploy_md' -gt 0 ]"
        assert_test "Deploy.sh tracked in manifest" "[ '$has_deploy_sh' -gt 0 ]"
    fi
}

# Test 7: Test rollback capability
test_rollback_capability() {
    echo -e "${BLUE}Test 7: Testing rollback capability...${NC}"

    # Check if backup was created during update
    if [ -d "$TEST_DIR/.living-docs-backups" ]; then
        local backup_count=$(find "$TEST_DIR/.living-docs-backups" -name "*update-test*" | wc -l)
        assert_test "Backup created during update" "[ '$backup_count' -gt 0 ]"

        # Find the most recent backup
        local latest_backup=$(find "$TEST_DIR/.living-docs-backups" -name "*update-test*" -type d | sort | tail -1)
        if [ -n "$latest_backup" ]; then
            assert_test "Backup contains original files" "[ -f '$latest_backup/.claude/commands/plan.md' ]"
            assert_test "Backup contains original version" "grep -q 'original plan command' '$latest_backup/.claude/commands/plan.md'"
        fi
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Starting $TEST_NAME${NC}"
    echo "Test directory: $TEST_DIR"
    echo ""

    setup_test_environment
    test_install_initial_version
    test_customize_files
    test_run_update
    test_customizations_preserved
    test_non_customized_files_updated
    test_manifest_tracking
    test_rollback_capability

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