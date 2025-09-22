#!/bin/bash
# Integration Test T030: Custom Paths Configuration
# Tests adapter installation with non-standard paths

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
TEST_NAME="Custom Paths Configuration (T030)"
TEST_DIR=$(mktemp -d)

# Source libraries with original project root
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/install.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/manifest.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/remove.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/rewrite.sh"

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

# Setup test environment with custom paths
setup_test_environment() {
    echo -e "${BLUE}Setting up test environment with custom paths...${NC}"

    # Create project structure with custom paths
    mkdir -p "$TEST_DIR/.claude/commands"
    mkdir -p "$TEST_DIR/custom-scripts/automation"
    mkdir -p "$TEST_DIR/project-specs/active"
    mkdir -p "$TEST_DIR/brain/context"

    # Set custom path environment variables
    export SCRIPTS_PATH="custom-scripts/automation"
    export SPECS_PATH="project-specs/active"
    export MEMORY_PATH="brain/context"

    echo "Custom paths configured:"
    echo "  SCRIPTS_PATH=$SCRIPTS_PATH"
    echo "  SPECS_PATH=$SPECS_PATH"
    echo "  MEMORY_PATH=$MEMORY_PATH"

    # Create living-docs config with custom paths
    cat > "$TEST_DIR/.living-docs.config" <<EOF
# Living Docs Configuration
SCRIPTS_PATH=$SCRIPTS_PATH
SPECS_PATH=$SPECS_PATH
MEMORY_PATH=$MEMORY_PATH
EOF

    # Create mock adapter with path references
    mkdir -p "$TEST_DIR/tmp/custom-path/commands"
    mkdir -p "$TEST_DIR/tmp/custom-path/templates"
    mkdir -p "$TEST_DIR/tmp/custom-path/scripts"

    cat > "$TEST_DIR/tmp/custom-path/commands/plan.md" <<'EOF'
# Custom Path Plan Command
Execute planning script at scripts/bash/plan.sh
Check specifications at .spec/current.md
Access project memory at memory/context.md
Review tasks in memory/tasks.md
EOF

    cat > "$TEST_DIR/tmp/custom-path/commands/implement.md" <<'EOF'
# Custom Path Implementation
Run implementation from scripts/bash/implement.sh
Update specs at .spec/implementation.md
Log progress to memory/progress.md
EOF

    cat > "$TEST_DIR/tmp/custom-path/templates/config.yml" <<'EOF'
# Adapter Configuration Template
scripts_directory: scripts/bash/
specifications_path: .spec/
memory_location: memory/context.md
task_tracking: memory/tasks.md
EOF

    cat > "$TEST_DIR/tmp/custom-path/templates/readme.md" <<'EOF'
# Project README
Scripts are located in: scripts/bash/
Specifications: .spec/
Memory and context: memory/
EOF

    cat > "$TEST_DIR/tmp/custom-path/scripts/setup.sh" <<'EOF'
#!/bin/bash
# Setup script
echo "Setting up with custom paths"
echo "Scripts: scripts/bash/"
echo "Specs: .spec/"
echo "Memory: memory/"
EOF
}

# Test 1: Install adapter with custom paths
test_install_with_custom_paths() {
    echo -e "${BLUE}Test 1: Installing adapter with custom paths...${NC}"

    # Install the adapter
    ADAPTER_PATH="$TEST_DIR/tmp/custom-path" install_adapter "custom-path"
    assert_test "Adapter installed successfully" "[ -f '$TEST_DIR/adapters/custom-path/.living-docs-manifest.json' ]"

    # Verify manifest tracks original paths
    local manifest_file="$TEST_DIR/adapters/custom-path/.living-docs-manifest.json"
    if [ -f "$manifest_file" ]; then
        local has_original_paths=$(jq -r '.path_mappings | length' "$manifest_file" 2>/dev/null || echo "0")
        assert_test "Manifest tracks path mappings" "[ '$has_original_paths' -gt 0 ]"
    fi
}

# Test 2: Verify path rewriting in installed files
test_path_rewriting() {
    echo -e "${BLUE}Test 2: Verifying path rewriting in installed files...${NC}"

    # Check command files for rewritten paths (look for prefixed versions)
    local plan_file="$TEST_DIR/.claude/commands/plan.md"
    if [ ! -f "$plan_file" ]; then
        plan_file="$TEST_DIR/.claude/commands/custompath_plan.md"
    fi

    if [ -f "$plan_file" ]; then
        assert_test "Scripts path rewritten in plan.md" "grep -q '$SCRIPTS_PATH/automation/plan.sh' '$plan_file'"
        assert_test "Specs path rewritten in plan.md" "grep -q '$SPECS_PATH/current.md' '$plan_file'"
        assert_test "Memory path rewritten in plan.md" "grep -q '$MEMORY_PATH/context.md' '$plan_file'"
    fi

    local impl_file="$TEST_DIR/.claude/commands/implement.md"
    if [ ! -f "$impl_file" ]; then
        impl_file="$TEST_DIR/.claude/commands/custompath_implement.md"
    fi

    if [ -f "$impl_file" ]; then
        assert_test "Scripts path rewritten in implement.md" "grep -q '$SCRIPTS_PATH/automation/implement.sh' '$impl_file'"
        assert_test "Specs path rewritten in implement.md" "grep -q '$SPECS_PATH/implementation.md' '$impl_file'"
        assert_test "Memory path rewritten in implement.md" "grep -q '$MEMORY_PATH/progress.md' '$impl_file'"
    fi

    # Check template files for rewritten paths
    if [ -f "$TEST_DIR/templates/config.yml" ]; then
        assert_test "Scripts path rewritten in config.yml" "grep -q '$SCRIPTS_PATH/' '$TEST_DIR/templates/config.yml'"
        assert_test "Specs path rewritten in config.yml" "grep -q '$SPECS_PATH/' '$TEST_DIR/templates/config.yml'"
        assert_test "Memory path rewritten in config.yml" "grep -q '$MEMORY_PATH/context.md' '$TEST_DIR/templates/config.yml'"
    fi
}

# Test 3: Check files are placed in custom locations
test_custom_file_placement() {
    echo -e "${BLUE}Test 3: Checking files are placed in custom locations...${NC}"

    # Files should still go to standard locations, but reference custom paths
    assert_test "Commands installed in .claude/commands" "[ -f '$TEST_DIR/.claude/commands/plan.md' ]"
    assert_test "Templates installed in templates/" "[ -f '$TEST_DIR/templates/config.yml' ]"

    # Verify scripts would reference custom paths when executed
    if [ -f "$TEST_DIR/scripts/setup.sh" ]; then
        assert_test "Setup script contains custom path references" "grep -q 'custom-scripts\\|project-specs\\|brain' '$TEST_DIR/scripts/setup.sh' || grep -q '$SCRIPTS_PATH\\|$SPECS_PATH\\|$MEMORY_PATH' '$TEST_DIR/scripts/setup.sh'"
    fi
}

# Test 4: Verify manifest tracks original and new paths
test_manifest_path_tracking() {
    echo -e "${BLUE}Test 4: Verifying manifest path tracking...${NC}"

    local manifest_file="$TEST_DIR/.living-docs-custom-path-manifest.json"

    if [ -f "$manifest_file" ]; then
        # Check that manifest exists and has expected structure
        assert_test "Manifest has path_mappings section" "jq -e '.path_mappings' '$manifest_file' >/dev/null 2>&1"

        # Check for specific path mappings
        local scripts_mapping=$(jq -r '.path_mappings."scripts/bash/"' "$manifest_file" 2>/dev/null || echo "null")
        local specs_mapping=$(jq -r '.path_mappings.".spec/"' "$manifest_file" 2>/dev/null || echo "null")
        local memory_mapping=$(jq -r '.path_mappings."memory/"' "$manifest_file" 2>/dev/null || echo "null")

        if [ "$scripts_mapping" != "null" ]; then
            assert_test "Scripts path mapping recorded" "[ '$scripts_mapping' = '$SCRIPTS_PATH/' ]"
        fi

        if [ "$specs_mapping" != "null" ]; then
            assert_test "Specs path mapping recorded" "[ '$specs_mapping' = '$SPECS_PATH/' ]"
        fi

        if [ "$memory_mapping" != "null" ]; then
            assert_test "Memory path mapping recorded" "[ '$memory_mapping' = '$MEMORY_PATH/' ]"
        fi

        # Verify installation_date exists
        local install_date=$(jq -r '.installation_date' "$manifest_file" 2>/dev/null || echo "null")
        assert_test "Installation date recorded" "[ '$install_date' != 'null' ]"
    fi
}

# Test 5: Test that removal works with custom paths
test_removal_with_custom_paths() {
    echo -e "${BLUE}Test 5: Testing removal with custom paths...${NC}"

    # Count files before removal
    local files_before=$(find "$TEST_DIR" -type f -name "*.md" -o -name "*.yml" -o -name "*.sh" | grep -v tmp | wc -l)

    # Remove the adapter
    remove_adapter "custom-path"

    # Verify manifest is removed
    assert_test "Manifest removed" "[ ! -f '$TEST_DIR/.living-docs-custom-path-manifest.json' ]"

    # Verify installed files are removed
    assert_test "Plan command removed" "[ ! -f '$TEST_DIR/.claude/commands/plan.md' ]"
    assert_test "Implement command removed" "[ ! -f '$TEST_DIR/.claude/commands/implement.md' ]"
    assert_test "Config template removed" "[ ! -f '$TEST_DIR/templates/config.yml' ]"

    # Count files after removal
    local files_after=$(find "$TEST_DIR" -type f -name "*.md" -o -name "*.yml" -o -name "*.sh" | grep -v tmp | wc -l)

    # Should have fewer files now (at least the ones we installed)
    assert_test "Files were actually removed" "[ $files_after -lt $files_before ]"
}

# Test 6: Verify configuration file integration
test_config_file_integration() {
    echo -e "${BLUE}Test 6: Testing configuration file integration...${NC}"

    # Re-install to test config file reading
    ADAPTER_PATH="$TEST_DIR/tmp/custom-path" install_adapter "custom-path-2"

    # Verify that the .living-docs.config file influenced installation
    assert_test "Second adapter installed" "[ -f '$TEST_DIR/.living-docs-custom-path-2-manifest.json' ]"

    # Check if config file paths were used
    if [ -f "$TEST_DIR/.claude/commands/plan.md" ]; then
        assert_test "Config file paths used in installation" "grep -q '$SCRIPTS_PATH\\|$SPECS_PATH\\|$MEMORY_PATH' '$TEST_DIR/.claude/commands/plan.md'"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Starting $TEST_NAME${NC}"
    echo "Test directory: $TEST_DIR"
    echo ""

    setup_test_environment
    test_install_with_custom_paths
    test_path_rewriting
    test_custom_file_placement
    test_manifest_path_tracking
    test_removal_with_custom_paths
    test_config_file_integration

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