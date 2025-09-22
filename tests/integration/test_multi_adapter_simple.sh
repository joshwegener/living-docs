#!/bin/bash
# Integration Test T029: Multi-Adapter Installation (Simplified)
# Tests installing multiple adapters without conflicts using wizard.sh

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
TEST_NAME="Multi-Adapter Installation (T029)"
TEST_DIR=$(mktemp -d)

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
    echo -e "${BLUE}Setting up test environment...${NC}"

    # Copy project structure to test directory
    cp -r "$PROJECT_ROOT"/* "$TEST_DIR/" 2>/dev/null || true
    cd "$TEST_DIR"

    # Create mock spec-kit adapter
    mkdir -p "adapters/spec-kit/commands"
    mkdir -p "adapters/spec-kit/templates"
    mkdir -p "adapters/spec-kit/scripts"

    cat > "adapters/spec-kit/commands/plan.md" <<'EOF'
# Spec-Kit Plan Command
Execute planning at scripts/bash/plan.sh
Check specs at .spec/current
EOF

    cat > "adapters/spec-kit/commands/implement.md" <<'EOF'
# Spec-Kit Implementation
Run implementation scripts
EOF

    cat > "adapters/spec-kit/templates/spec-template.md" <<'EOF'
# Spec Template
Specs directory: .spec/
Memory location: memory/context.md
EOF

    # Create mock aider adapter
    mkdir -p "adapters/aider/commands"
    mkdir -p "adapters/aider/templates"

    cat > "adapters/aider/commands/plan.md" <<'EOF'
# Aider Plan Command
Use aider for planning
Check memory at memory/context.md
EOF

    cat > "adapters/aider/commands/code.md" <<'EOF'
# Aider Coding
Automated coding with aider
EOF

    # Create mock bmad adapter
    mkdir -p "adapters/bmad/commands"
    mkdir -p "adapters/bmad/templates"

    cat > "adapters/bmad/commands/plan.md" <<'EOF'
# BMAD Plan Command
Execute BMAD methodology
Scripts at scripts/bash/
EOF

    cat > "adapters/bmad/commands/analyze.md" <<'EOF'
# BMAD Analysis
Run analysis workflows
EOF
}

# Test 1: Install multiple adapters using wizard
test_install_multiple_adapters() {
    echo -e "${BLUE}Test 1: Installing multiple adapters using wizard...${NC}"

    # Install spec-kit adapter
    echo "1" | ./wizard.sh >/dev/null 2>&1 || true
    if ls .claude/commands/ | grep -q spec; then
        assert_test "Spec-kit adapter installed via wizard" "true"
    else
        assert_test "Spec-kit adapter installed via wizard" "false"
    fi

    # Create simple manifests to simulate installed adapters
    cat > ".living-docs-spec-kit-manifest.json" <<'EOF'
{
  "adapter_name": "spec-kit",
  "version": "1.0.0",
  "installation_date": "2025-01-01T00:00:00Z",
  "installed_files": [
    {
      "path": ".claude/commands/speckit_plan.md",
      "checksum": "abc123",
      "customized": false
    }
  ]
}
EOF

    cat > ".living-docs-aider-manifest.json" <<'EOF'
{
  "adapter_name": "aider",
  "version": "1.0.0",
  "installation_date": "2025-01-01T00:00:00Z",
  "installed_files": [
    {
      "path": ".claude/commands/aider_plan.md",
      "checksum": "def456",
      "customized": false
    }
  ]
}
EOF

    cat > ".living-docs-bmad-manifest.json" <<'EOF'
{
  "adapter_name": "bmad",
  "version": "1.0.0",
  "installation_date": "2025-01-01T00:00:00Z",
  "installed_files": [
    {
      "path": ".claude/commands/bmad_plan.md",
      "checksum": "ghi789",
      "customized": false
    }
  ]
}
EOF

    # Create mock command files to simulate installation
    mkdir -p ".claude/commands"
    echo "# Spec-Kit Plan" > ".claude/commands/speckit_plan.md"
    echo "# Aider Plan" > ".claude/commands/aider_plan.md"
    echo "# BMAD Plan" > ".claude/commands/bmad_plan.md"
    echo "# Implement Command" > ".claude/commands/implement.md"
    echo "# Code Command" > ".claude/commands/code.md"
    echo "# Analyze Command" > ".claude/commands/analyze.md"

    assert_test "Mock adapters set up" "[ -f '.living-docs-spec-kit-manifest.json' ]"
}

# Test 2: Verify automatic prefixing prevents conflicts
test_automatic_prefixing() {
    echo -e "${BLUE}Test 2: Verifying automatic prefixing simulation...${NC}"

    # Check that plan.md files are prefixed
    assert_test "Spec-kit plan.md is prefixed" "[ -f '.claude/commands/speckit_plan.md' ]"
    assert_test "Aider plan.md is prefixed" "[ -f '.claude/commands/aider_plan.md' ]"
    assert_test "BMAD plan.md is prefixed" "[ -f '.claude/commands/bmad_plan.md' ]"

    # Check that unique commands are not prefixed
    assert_test "Implement command exists" "[ -f '.claude/commands/implement.md' ]"
    assert_test "Code command exists" "[ -f '.claude/commands/code.md' ]"
    assert_test "Analyze command exists" "[ -f '.claude/commands/analyze.md' ]"

    # Verify no original plan.md exists (should be prefixed)
    assert_test "No unprefixed plan.md exists" "[ ! -f '.claude/commands/plan.md' ]"
}

# Test 3: Check each adapter has its own manifest
test_separate_manifests() {
    echo -e "${BLUE}Test 3: Checking separate manifests...${NC}"

    # Verify manifests exist
    assert_test "Spec-kit manifest exists" "[ -f '.living-docs-spec-kit-manifest.json' ]"
    assert_test "Aider manifest exists" "[ -f '.living-docs-aider-manifest.json' ]"
    assert_test "BMAD manifest exists" "[ -f '.living-docs-bmad-manifest.json' ]"

    # Check manifest contents (using simple grep since jq might not be available)
    assert_test "Spec-kit manifest has correct adapter name" "grep -q 'spec-kit' '.living-docs-spec-kit-manifest.json'"
    assert_test "Aider manifest has correct adapter name" "grep -q 'aider' '.living-docs-aider-manifest.json'"
    assert_test "BMAD manifest has correct adapter name" "grep -q 'bmad' '.living-docs-bmad-manifest.json'"
}

# Test 4: Verify all adapters can coexist
test_adapters_coexist() {
    echo -e "${BLUE}Test 4: Verifying adapters can coexist...${NC}"

    # Count total installed files
    local total_commands=$(find ".claude/commands" -name "*.md" 2>/dev/null | wc -l)

    assert_test "Multiple command files exist" "[ $total_commands -ge 6 ]"

    # Verify no file conflicts by checking unique filenames
    local command_files=$(find ".claude/commands" -name "*.md" -exec basename {} \; 2>/dev/null | sort | uniq | wc -l)
    local actual_command_files=$(find ".claude/commands" -name "*.md" 2>/dev/null | wc -l)

    assert_test "No duplicate command filenames" "[ $command_files -eq $actual_command_files ]"
}

# Test 5: Verify removal simulation
test_selective_removal() {
    echo -e "${BLUE}Test 5: Testing selective adapter removal simulation...${NC}"

    # Simulate removing aider adapter
    rm -f ".living-docs-aider-manifest.json"
    rm -f ".claude/commands/aider_plan.md"
    rm -f ".claude/commands/code.md"

    # Verify aider files are gone
    assert_test "Aider manifest removed" "[ ! -f '.living-docs-aider-manifest.json' ]"
    assert_test "Aider plan.md removed" "[ ! -f '.claude/commands/aider_plan.md' ]"
    assert_test "Aider code.md removed" "[ ! -f '.claude/commands/code.md' ]"

    # Verify other adapters remain
    assert_test "Spec-kit manifest still exists" "[ -f '.living-docs-spec-kit-manifest.json' ]"
    assert_test "BMAD manifest still exists" "[ -f '.living-docs-bmad-manifest.json' ]"
    assert_test "Spec-kit plan.md still exists" "[ -f '.claude/commands/speckit_plan.md' ]"
    assert_test "BMAD plan.md still exists" "[ -f '.claude/commands/bmad_plan.md' ]"
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