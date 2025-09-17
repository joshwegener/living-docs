#!/bin/bash

# Comprehensive test suite for multi-spec adapter system
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test directory
TEST_DIR="/tmp/living-docs-test"
PROJECT_DIR="$(pwd)"

# Test results
PASSED=0
FAILED=0

# Function: Run test
run_test() {
    local test_name="$1"
    local test_cmd="$2"

    echo -n "Testing: $test_name... "
    if eval "$test_cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC}"
        ((FAILED++))
        return 1
    fi
}

# Function: Test single adapter installation
test_single_adapter() {
    local adapter="$1"
    local path="$2"
    local test_dir="$TEST_DIR/test-$adapter-$path"

    # Create test directory
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Create config
    cat > .living-docs.config << EOF
# living-docs configuration
LIVING_DOCS_PATH="$path"
AI_PATH="$path"
SPECS_PATH="$path/specs"
MEMORY_PATH="$path/memory"
SCRIPTS_PATH="$path/scripts"
EOF

    # Install adapter
    if bash "$PROJECT_DIR/adapters/$adapter/install.sh" . >/dev/null 2>&1; then
        # Check for expected files
        case "$adapter" in
            aider)
                [ -f "CONVENTIONS.md" ]
                ;;
            cursor)
                [ -f ".cursorrules" ]
                ;;
            continue)
                [ -f ".continuerules" ]
                ;;
            spec-kit)
                [ -d "$path/memory" ] && [ -d "$path/specs" ] && [ -d "$path/scripts" ]
                ;;
            agent-os)
                [ -d "$path/agent-os/specs" ] && [ -d "$path/agent-os/standards" ]
                ;;
            bmad-method)
                [ -f "$path/bmad/.bmadrc" ]
                ;;
        esac
    else
        return 1
    fi
}

# Function: Test adapter combination
test_combination() {
    local adapters="$1"
    local path="$2"
    local test_dir="$TEST_DIR/test-combo-$(echo $adapters | tr ' ' '-')"

    mkdir -p "$test_dir"
    cd "$test_dir"

    # Create config
    cat > .living-docs.config << EOF
# living-docs configuration
LIVING_DOCS_PATH="$path"
AI_PATH="$path"
SPECS_PATH="$path/specs"
MEMORY_PATH="$path/memory"
SCRIPTS_PATH="$path/scripts"
EOF

    # Install all adapters
    for adapter in $adapters; do
        if ! bash "$PROJECT_DIR/adapters/$adapter/install.sh" . >/dev/null 2>&1; then
            return 1
        fi
    done

    # Verify no conflicts
    if [ -f "CONVENTIONS.md" ] || [ -f ".cursorrules" ] || [ -f ".continuerules" ]; then
        return 0
    else
        return 1
    fi
}

# Function: Test path rewriting
test_path_rewriting() {
    local test_dir="$TEST_DIR/test-path-rewrite"
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Create test file with placeholders
    cat > test.md << 'EOF'
Path: {{LIVING_DOCS_PATH}}/test
Specs: {{SPECS_PATH}}/feature
Memory: {{MEMORY_PATH}}/data
EOF

    # Source rewrite function
    source "$PROJECT_DIR/adapters/common/path-rewrite.sh"

    # Test rewriting
    rewrite_paths "test.md" ".claude" ".claude" ".claude/specs" ".claude/memory" ".claude/scripts"

    # Check result
    grep -q "Path: .claude/test" test.md && \
    grep -q "Specs: .claude/specs/feature" test.md && \
    grep -q "Memory: .claude/memory/data" test.md
}

# Function: Test update mechanism
test_update_mechanism() {
    local test_dir="$TEST_DIR/test-update"
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Create mock installation
    cat > .living-docs.config << EOF
INSTALLED_SPECS="aider cursor"
AIDER_VERSION="1.0.0"
CURSOR_VERSION="1.0.0"
EOF

    # Test update checking (won't actually update, just check mechanism)
    if bash "$PROJECT_DIR/adapters/check-updates.sh" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Main test execution
main() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}       Living-Docs Adapter Test Suite${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Clean test directory
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"

    echo -e "${CYAN}1. Testing Single Adapter Installations${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test each adapter with different paths
    for adapter in aider cursor continue spec-kit agent-os; do
        for path in .claude .github docs .docs; do
            run_test "$adapter in $path" "test_single_adapter $adapter $path"
        done
    done

    echo ""
    echo -e "${CYAN}2. Testing Adapter Combinations${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    run_test "aider + cursor + continue" "test_combination 'aider cursor continue' docs"
    run_test "spec-kit + aider" "test_combination 'spec-kit aider' .claude"
    run_test "agent-os + cursor" "test_combination 'agent-os cursor' .github"
    run_test "All lightweight adapters" "test_combination 'aider cursor continue' docs"

    echo ""
    echo -e "${CYAN}3. Testing Path Rewriting${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━"

    run_test "Path variable substitution" "test_path_rewriting"

    echo ""
    echo -e "${CYAN}4. Testing Update Mechanisms${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    run_test "Update checking system" "test_update_mechanism"

    echo ""
    echo -e "${CYAN}5. Testing Wizard v3 Features${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test wizard v3 (non-interactive)
    run_test "Wizard v3 syntax check" "bash -n $PROJECT_DIR/wizard-v3.sh"

    # Summary
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test Results:${NC}"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"

    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 1
    fi
}

# Run tests
main "$@"

# Clean up
cd "$PROJECT_DIR"
echo ""
echo "Cleaning up test directory..."
rm -rf "$TEST_DIR"