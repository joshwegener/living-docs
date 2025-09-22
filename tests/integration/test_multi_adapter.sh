#!/bin/bash
# Integration Test T029: Multi-Adapter Installation
# Tests installing multiple adapters without conflicts

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
TEST_NAME="Multi-Adapter Installation (T029)"
TEST_DIR=$(mktemp -d)

# Source libraries with original project root
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/install.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/manifest.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/remove.sh"
source "$ORIGINAL_PROJECT_ROOT/lib/adapter/prefix.sh"

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

# Setup test environment with mock adapters
setup_test_environment() {
    echo -e "${BLUE}Setting up test environment for multi-adapter testing...${NC}"

    # Create project structure
    mkdir -p "$TEST_DIR/.claude/commands"
    mkdir -p "$TEST_DIR/scripts"
    mkdir -p "$TEST_DIR/specs"
    mkdir -p "$TEST_DIR/memory"

    # Create mock spec-kit adapter
    mkdir -p "$TEST_DIR/tmp/spec-kit-adapter/commands"
    mkdir -p "$TEST_DIR/tmp/spec-kit-adapter/templates"
    mkdir -p "$TEST_DIR/tmp/spec-kit-adapter/scripts"

    cat > "$TEST_DIR/tmp/spec-kit-adapter/commands/plan.md" <<'EOF'
# Spec-Kit Plan Command
Execute planning at scripts/bash/plan.sh
Check specs at .spec/current
EOF

    cat > "$TEST_DIR/tmp/spec-kit-adapter/commands/implement.md" <<'EOF'
# Spec-Kit Implementation
Run implementation scripts
EOF

    cat > "$TEST_DIR/tmp/spec-kit-adapter/scripts/plan.sh" <<'EOF'
#!/bin/bash
echo "Spec-Kit planning script"
EOF

    cat > "$TEST_DIR/tmp/spec-kit-adapter/templates/spec-template.md" <<'EOF'
# Spec Template
Specs directory: .spec/
Memory location: memory/context.md
EOF

    # Create mock aider adapter
    mkdir -p "$TEST_DIR/tmp/aider-adapter/commands"
    mkdir -p "$TEST_DIR/tmp/aider-adapter/templates"

    cat > "$TEST_DIR/tmp/aider-adapter/commands/plan.md" <<'EOF'
# Aider Plan Command
Use aider for planning
Check memory at memory/context.md
EOF

    cat > "$TEST_DIR/tmp/aider-adapter/commands/code.md" <<'EOF'
# Aider Coding
Automated coding with aider
EOF

    cat > "$TEST_DIR/tmp/aider-adapter/templates/aider-config.yml" <<'EOF'
# Aider Configuration
memory_path: memory/context.md
scripts_path: scripts/bash/
EOF

    # Create mock bmad adapter
    mkdir -p "$TEST_DIR/tmp/bmad-adapter/commands"
    mkdir -p "$TEST_DIR/tmp/bmad-adapter/templates"

    cat > "$TEST_DIR/tmp/bmad-adapter/commands/plan.md" <<'EOF'
# BMAD Plan Command
Execute BMAD methodology
Scripts at scripts/bash/
EOF

    cat > "$TEST_DIR/tmp/bmad-adapter/commands/analyze.md" <<'EOF'
# BMAD Analysis
Run analysis workflows
EOF

    cat > "$TEST_DIR/tmp/bmad-adapter/templates/method-config.yml" <<'EOF'
# BMAD Method Configuration
specs_path: .spec/
memory_path: memory/
EOF
}

# Test 1: Install multiple adapters
test_install_multiple_adapters() {
    echo -e "${BLUE}Test 1: Installing multiple adapters...${NC}"

    # Install spec-kit adapter
    ADAPTER_PATH="$TEST_DIR/tmp/spec-kit-adapter" install_adapter "spec-kit"
    assert_test "Spec-kit adapter installed successfully" "[ -f '$TEST_DIR/.living-docs-spec-kit-manifest.json' ]"

    # Install aider adapter
    ADAPTER_PATH="$TEST_DIR/tmp/aider-adapter" install_adapter "aider"
    assert_test "Aider adapter installed successfully" "[ -f '$TEST_DIR/.living-docs-aider-manifest.json' ]"

    # Install bmad adapter
    ADAPTER_PATH="$TEST_DIR/tmp/bmad-adapter" install_adapter "bmad"
    assert_test "BMAD adapter installed successfully" "[ -f '$TEST_DIR/.living-docs-bmad-manifest.json' ]"
}

# Test 2: Verify automatic prefixing prevents conflicts
test_automatic_prefixing() {
    echo -e "${BLUE}Test 2: Verifying automatic prefixing...${NC}"

    # Check that plan.md files are prefixed
    assert_test "Spec-kit plan.md is prefixed" "[ -f '$TEST_DIR/.claude/commands/speckit_plan.md' ]"
    assert_test "Aider plan.md is prefixed" "[ -f '$TEST_DIR/.claude/commands/aider_plan.md' ]"
    assert_test "BMAD plan.md is prefixed" "[ -f '$TEST_DIR/.claude/commands/bmad_plan.md' ]"

    # Check that unique commands are not prefixed
    assert_test "Spec-kit implement.md is not prefixed" "[ -f '$TEST_DIR/.claude/commands/implement.md' ]"
    assert_test "Aider code.md is not prefixed" "[ -f '$TEST_DIR/.claude/commands/code.md' ]"
    assert_test "BMAD analyze.md is not prefixed" "[ -f '$TEST_DIR/.claude/commands/analyze.md' ]"

    # Verify no original plan.md exists (should be prefixed)
    assert_test "No unprefixed plan.md exists" "[ ! -f '$TEST_DIR/.claude/commands/plan.md' ]"
}

# Test 3: Check each adapter has its own manifest
test_separate_manifests() {
    echo -e "${BLUE}Test 3: Checking separate manifests...${NC}"

    # Verify manifests exist
    assert_test "Spec-kit manifest exists" "[ -f '$TEST_DIR/.living-docs-spec-kit-manifest.json' ]"
    assert_test "Aider manifest exists" "[ -f '$TEST_DIR/.living-docs-aider-manifest.json' ]"
    assert_test "BMAD manifest exists" "[ -f '$TEST_DIR/.living-docs-bmad-manifest.json' ]"

    # Check manifest contents have different adapter names
    local speckit_adapter=$(jq -r '.adapter_name' "$TEST_DIR/.living-docs-spec-kit-manifest.json" 2>/dev/null || echo "")
    local aider_adapter=$(jq -r '.adapter_name' "$TEST_DIR/.living-docs-aider-manifest.json" 2>/dev/null || echo "")
    local bmad_adapter=$(jq -r '.adapter_name' "$TEST_DIR/.living-docs-bmad-manifest.json" 2>/dev/null || echo "")

    assert_test "Spec-kit manifest has correct adapter name" "[ '$speckit_adapter' = 'spec-kit' ]"
    assert_test "Aider manifest has correct adapter name" "[ '$aider_adapter' = 'aider' ]"
    assert_test "BMAD manifest has correct adapter name" "[ '$bmad_adapter' = 'bmad' ]"
}

# Test 4: Verify all adapters can coexist
test_adapters_coexist() {
    echo -e "${BLUE}Test 4: Verifying adapters can coexist...${NC}"

    # Count total installed files
    local total_commands=$(find "$TEST_DIR/.claude/commands" -name "*.md" | wc -l)
    local total_templates=$(find "$TEST_DIR" -name "*-template.md" -o -name "*-config.yml" | wc -l)
    local total_scripts=$(find "$TEST_DIR/scripts" -name "*.sh" | wc -l)

    assert_test "Multiple command files exist" "[ $total_commands -ge 6 ]"
    assert_test "Multiple template files exist" "[ $total_templates -ge 3 ]"
    assert_test "Script files exist" "[ $total_scripts -ge 1 ]"

    # Verify no file conflicts by checking unique filenames
    local command_files=$(find "$TEST_DIR/.claude/commands" -name "*.md" -exec basename {} \; | sort | uniq | wc -l)
    local actual_command_files=$(find "$TEST_DIR/.claude/commands" -name "*.md" | wc -l)

    assert_test "No duplicate command filenames" "[ $command_files -eq $actual_command_files ]"

    # Test that path rewriting worked for all adapters
    if [ -f "$TEST_DIR/.claude/commands/speckit_plan.md" ]; then
        assert_test "Spec-kit paths rewritten" "grep -q 'scripts/bash/plan.sh' '$TEST_DIR/.claude/commands/speckit_plan.md'"
    fi

    if [ -f "$TEST_DIR/templates/aider-config.yml" ]; then
        assert_test "Aider paths rewritten" "grep -q 'memory/context.md' '$TEST_DIR/templates/aider-config.yml'"
    fi
}

# Test 5: Verify removal doesn't affect other adapters
test_selective_removal() {
    echo -e "${BLUE}Test 5: Testing selective adapter removal...${NC}"

    # Remove aider adapter
    remove_adapter "aider"

    # Verify aider files are gone
    assert_test "Aider manifest removed" "[ ! -f '$TEST_DIR/.living-docs-aider-manifest.json' ]"
    assert_test "Aider plan.md removed" "[ ! -f '$TEST_DIR/.claude/commands/aider_plan.md' ]"
    assert_test "Aider code.md removed" "[ ! -f '$TEST_DIR/.claude/commands/code.md' ]"

    # Verify other adapters remain
    assert_test "Spec-kit manifest still exists" "[ -f '$TEST_DIR/.living-docs-spec-kit-manifest.json' ]"
    assert_test "BMAD manifest still exists" "[ -f '$TEST_DIR/.living-docs-bmad-manifest.json' ]"
    assert_test "Spec-kit plan.md still exists" "[ -f '$TEST_DIR/.claude/commands/speckit_plan.md' ]"
    assert_test "BMAD plan.md still exists" "[ -f '$TEST_DIR/.claude/commands/bmad_plan.md' ]"
}

# Main test execution
main() {
    echo -e "${BLUE}Starting $TEST_NAME${NC}"
    echo "Test directory: $TEST_DIR"
    echo ""

    setup_test_environment
    test_install_multiple_adapters
    test_automatic_prefixing
    test_separate_manifests
    test_adapters_coexist
    test_selective_removal

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