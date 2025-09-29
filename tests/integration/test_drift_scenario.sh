#!/bin/bash
set -euo pipefail
# Integration test for drift detection scenario validation
# Tests the complete drift detection workflow from quickstart.md

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_WORKSPACE=""

# Test utilities
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

assert_success() {
    local cmd="$1"
    local desc="$2"

    log_test "$desc"

    local exit_code
    timeout 30 bash -c "$cmd" >/dev/null 2>&1
    exit_code=$?

    if [ $exit_code -eq 124 ]; then
        echo -e "${RED}  ✗ FAIL${NC} - Command timed out after 30 seconds: $cmd"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    elif [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FAIL${NC} - Command failed: $cmd"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_failure() {
    local cmd="$1"
    local desc="$2"

    log_test "$desc"

    local exit_code
    timeout 30 bash -c "$cmd" >/dev/null 2>&1
    exit_code=$?

    if [ $exit_code -eq 124 ]; then
        echo -e "${RED}  ✗ FAIL${NC} - Command timed out after 30 seconds: $cmd"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    elif [ $exit_code -ne 0 ]; then
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FAIL${NC} - Command should have failed: $cmd"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_output_contains() {
    local cmd="$1"
    local expected="$2"
    local desc="$3"

    log_test "$desc"

    local output
    local exit_code
    output=$(timeout 30 bash -c "$cmd" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 124 ]; then
        echo -e "${RED}  ✗ FAIL${NC} - Command timed out after 30 seconds"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    if echo "$output" | grep -q "$expected"; then
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FAIL${NC} - Output should contain '$expected'"
        echo "  Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local desc="$2"

    log_test "$desc"

    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FAIL${NC} - File should exist: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local desc="$2"

    log_test "$desc"

    if [ ! -f "$file" ]; then
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FAIL${NC} - File should not exist: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Setup test environment
setup_test_workspace() {
    TEST_WORKSPACE=$(mktemp -d)
    cd "$TEST_WORKSPACE"

    # Copy drift detection script
    mkdir -p scripts
    cp "$PROJECT_ROOT/scripts/check-drift.sh" scripts/
    chmod +x scripts/check-drift.sh

    # Create basic project structure
    mkdir -p docs/{active,completed,procedures}
    mkdir -p .living-docs

    # Create current.md with initial content
    cat > docs/current.md << 'EOF'
# Living Docs Project Status

## 🔥 Active Development
- [feature-x](active/feature-x.md) - Working on feature X

## ✅ Recently Completed
- [2025-09-19-setup](completed/2025-09-19-setup.md) - Initial setup

## 📚 Documentation
- [bugs.md](bugs.md) - Current count: 0 open bugs
- [ideas.md](ideas.md) - Current count: 0 ideas

### Development History
- [initial-setup](procedures/initial-setup.md) - How we got started

### Specifications
- [core-spec](specs/core-spec.md) - Core specification
EOF

    # Create referenced files
    mkdir -p docs/active docs/completed docs/procedures docs/specs
    echo "# Feature X" > docs/active/feature-x.md
    echo "# Setup Complete" > docs/completed/2025-09-19-setup.md
    echo "# Bugs" > docs/bugs.md
    echo "# Ideas" > docs/ideas.md
    echo "# Initial Setup" > docs/procedures/initial-setup.md
    echo "# Core Spec" > docs/specs/core-spec.md

    # Initialize git
    git init >/dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"
    git add .
    git commit -m "Initial commit" >/dev/null 2>&1

    echo -e "${GREEN}✓ Test workspace created: $TEST_WORKSPACE${NC}"
}

# Cleanup test environment
cleanup_test_workspace() {
    if [ -n "$TEST_WORKSPACE" ] && [ -d "$TEST_WORKSPACE" ]; then
        cd "$PROJECT_ROOT"
        rm -rf "$TEST_WORKSPACE"
        echo -e "${GREEN}✓ Test workspace cleaned up${NC}"
    fi
}

# Test functions

test_initial_baseline_creation() {
    echo -e "\n${YELLOW}=== Testing Initial Baseline Creation ===${NC}"

    # Test that drift detection passes on clean state
    assert_success "./scripts/check-drift.sh --no-fix" "Clean state shows no drift"

    # Test that all files are properly linked
    assert_success "grep -q 'feature-x' docs/current.md" "Active file is linked in current.md"
    assert_success "grep -q '2025-09-19-setup' docs/current.md" "Completed file is linked in current.md"
    assert_success "grep -q 'bugs.md' docs/current.md" "Bugs file is linked in current.md"
    assert_success "grep -q 'ideas.md' docs/current.md" "Ideas file is linked in current.md"
}

test_detection_of_modified_files() {
    echo -e "\n${YELLOW}=== Testing Detection of Modified Files ===${NC}"

    # Modify existing files
    echo "Additional content" >> docs/active/feature-x.md
    echo "More setup details" >> docs/completed/2025-09-19-setup.md

    # Add a bug to test count detection
    echo "- [ ] Fix critical bug" >> docs/bugs.md

    # Run drift detection - should detect count mismatch
    assert_output_contains "./scripts/check-drift.sh --no-fix" "Bug count mismatch" "Detects bug count mismatch"

    # Check that it detects the incorrect count
    assert_output_contains "./scripts/check-drift.sh --no-fix" "says 0 but actually 1" "Shows correct count discrepancy"
}

test_detection_of_added_removed_files() {
    echo -e "\n${YELLOW}=== Testing Detection of Added/Removed Files ===${NC}"

    # Add new files that aren't linked
    echo "# New Feature" > docs/active/new-feature.md
    echo "# Orphaned Document" > docs/orphaned.md
    mkdir -p docs/procedures
    echo "# New Procedure" > docs/procedures/new-procedure.md

    # Remove a referenced file to create broken link
    rm docs/specs/core-spec.md

    # Run drift detection
    local drift_output
    drift_output=$(./scripts/check-drift.sh --no-fix 2>&1 || true)

    # Test individual aspects
    TESTS_RUN=$((TESTS_RUN + 5))  # Account for the 5 tests we're about to run

    if echo "$drift_output" | grep -q "Orphaned"; then
        log_test "Detects orphaned files"
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_test "Detects orphaned files"
        echo -e "${RED}  ✗ FAIL${NC} - Should detect orphaned files"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if echo "$drift_output" | grep -q "new-feature.md"; then
        log_test "Identifies specific orphaned file"
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_test "Identifies specific orphaned file"
        echo -e "${RED}  ✗ FAIL${NC} - Should identify new-feature.md"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if echo "$drift_output" | grep -q "orphaned.md"; then
        log_test "Identifies root-level orphaned file"
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_test "Identifies root-level orphaned file"
        echo -e "${RED}  ✗ FAIL${NC} - Should identify orphaned.md"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if echo "$drift_output" | grep -q "Broken link"; then
        log_test "Detects broken links"
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_test "Detects broken links"
        echo -e "${RED}  ✗ FAIL${NC} - Should detect broken links"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if echo "$drift_output" | grep -q "core-spec.md"; then
        log_test "Identifies specific broken link"
        echo -e "${GREEN}  ✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_test "Identifies specific broken link"
        echo -e "${RED}  ✗ FAIL${NC} - Should identify core-spec.md"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_automatic_drift_fixing() {
    echo -e "\n${YELLOW}=== Testing Automatic Drift Fixing ===${NC}"

    # Create orphaned files and broken links
    echo "# Another New Feature" > docs/active/another-feature.md
    echo "# Random Doc" > docs/random-doc.md
    rm -f docs/procedures/initial-setup.md  # Break a link

    # Add more bugs to test count fixing
    echo "- [ ] Second bug" >> docs/bugs.md
    echo "- [ ] Third bug" >> docs/bugs.md

    # Run auto-fix
    assert_success "./scripts/check-drift.sh" "Auto-fix completes successfully"

    # Verify fixes were applied
    assert_success "grep -q 'another-feature' docs/current.md" "New feature added to current.md"
    assert_success "grep -q 'random-doc' docs/current.md" "Random doc added to current.md"
    assert_success "grep -q 'UNCATEGORIZED' docs/current.md" "Uncategorized section created for orphaned files"
    assert_output_contains "grep 'random-doc' docs/current.md" "NEEDS CATEGORIZATION" "Orphaned file marked for categorization"

    # Check that broken link was commented out
    assert_success "grep -q '<!-- BROKEN:' docs/current.md" "Broken link was commented out"

    # Check that bug count was fixed
    assert_success "grep -q 'Current count: 3 open' docs/current.md" "Bug count was updated correctly"
}

test_drift_reporting() {
    echo -e "\n${YELLOW}=== Testing Drift Reporting ===${NC}"

    # Create various types of drift
    echo "# Temp Feature" > docs/temp-feature.md
    echo "Modified content" >> docs/active/feature-x.md
    rm -f docs/bugs.md  # Remove a file

    # Add an idea to test count reporting
    echo "- [ ] Great idea" >> docs/ideas.md

    # Test detection without auto-fix
    assert_failure "./scripts/check-drift.sh --no-fix" "Drift detection fails when drift exists"

    # Test that it reports specific issues
    assert_output_contains "./scripts/check-drift.sh --no-fix" "Orphaned" "Reports orphaned files"
    assert_output_contains "./scripts/check-drift.sh --no-fix" "temp-feature.md" "Identifies specific orphaned file"
    assert_output_contains "./scripts/check-drift.sh --no-fix" "Broken link" "Reports broken links"
    assert_output_contains "./scripts/check-drift.sh --no-fix" "Ideas count mismatch" "Reports count mismatches"

    # Test dry-run mode
    assert_output_contains "./scripts/check-drift.sh --dry-run" "DRY RUN" "Dry-run mode is indicated"
    assert_output_contains "./scripts/check-drift.sh --dry-run" "Would" "Dry-run shows what would be done"

    # Verify dry-run doesn't make changes
    assert_failure "grep -q 'temp-feature' docs/current.md" "Dry-run doesn't make actual changes"
}

test_edge_cases_and_error_handling() {
    echo -e "\n${YELLOW}=== Testing Edge Cases and Error Handling ===${NC}"

    # Test with missing current.md
    mv docs/current.md docs/current.md.backup
    assert_failure "./scripts/check-drift.sh --no-fix" "Fails gracefully when current.md is missing"
    mv docs/current.md.backup docs/current.md

    # Test with files that should be ignored
    echo "# Template" > docs/template.md
    echo "*template*" > .gitignore

    # Test help option
    assert_output_contains "./scripts/check-drift.sh --help" "Usage:" "Help option works"
    assert_output_contains "./scripts/check-drift.sh --help" "--dry-run" "Help shows dry-run option"
    assert_output_contains "./scripts/check-drift.sh --help" "--no-fix" "Help shows no-fix option"

    # Test verbose option
    assert_success "./scripts/check-drift.sh -v" "Verbose option works"

    # Test invalid option
    assert_failure "./scripts/check-drift.sh --invalid-option" "Rejects invalid options"
}

test_integration_with_git() {
    echo -e "\n${YELLOW}=== Testing Integration with Git ===${NC}"

    # Create files and commit them
    echo "# Git Integration Test" > docs/git-test.md
    git add docs/git-test.md
    git commit -m "Add git test file" >/dev/null 2>&1

    # Update current.md to reference it
    echo "- [git-test](git-test.md) - Git integration test" >> docs/current.md

    # Verify drift detection works with committed files
    assert_success "./scripts/check-drift.sh --no-fix" "Works correctly with git-committed files"

    # Remove from git but keep file (simulating orphaned state)
    git rm docs/git-test.md >/dev/null 2>&1
    git commit -m "Remove git test file" >/dev/null 2>&1
    echo "# Git Integration Test" > docs/git-test.md  # Recreate as untracked

    # Should detect as orphaned since it's not in current.md anymore
    assert_output_contains "./scripts/check-drift.sh --no-fix" "git-test.md" "Detects untracked files as potential orphans"
}

test_complex_scenarios() {
    echo -e "\n${YELLOW}=== Testing Complex Scenarios ===${NC}"

    # Scenario: Multiple issues at once
    echo "# Complex Feature A" > docs/active/complex-a.md
    echo "# Complex Feature B" > docs/active/complex-b.md
    echo "# Standalone Doc" > docs/standalone.md
    echo "# Deep Doc" > docs/procedures/deep/nested-doc.md

    # Create nested directory
    mkdir -p docs/procedures/deep
    echo "# Deep Doc" > docs/procedures/deep/nested-doc.md

    # Break multiple links
    rm -f docs/active/feature-x.md docs/procedures/initial-setup.md

    # Add multiple bugs and ideas for count testing
    echo "- [ ] Bug 1" >> docs/bugs.md
    echo "- [ ] Bug 2" >> docs/bugs.md
    echo "- [x] Completed bug" >> docs/bugs.md  # Should not count
    echo "- [ ] Idea 1" >> docs/ideas.md
    echo "- [ ] Idea 2" >> docs/ideas.md
    echo "- [x] Implemented idea" >> docs/ideas.md  # Should not count

    # Run comprehensive fix
    local output
    output=$(./scripts/check-drift.sh 2>&1)

    # Verify comprehensive fixing
    assert_success "echo '$output' | grep -q 'Fixed.*issues'" "Comprehensive fix reports success"
    assert_success "grep -q 'complex-a' docs/current.md" "Complex feature A was added"
    assert_success "grep -q 'complex-b' docs/current.md" "Complex feature B was added"
    assert_success "grep -q 'standalone' docs/current.md" "Standalone doc was added"
    assert_success "grep -q 'Current count: 2 open' docs/current.md" "Bug count correctly excludes completed items"
    assert_success "grep -q 'Current count: 2 ideas' docs/current.md" "Ideas count correctly excludes implemented items"
    assert_success "grep -q '<!-- BROKEN:' docs/current.md" "Broken links were commented out"
}

# Main test execution
main() {
    echo -e "${BLUE}Starting Drift Detection Integration Tests${NC}"
    echo "Project root: $PROJECT_ROOT"

    # Setup
    setup_test_workspace

    # Run test suites
    test_initial_baseline_creation
    test_detection_of_modified_files
    test_detection_of_added_removed_files
    test_automatic_drift_fixing
    test_drift_reporting
    test_edge_cases_and_error_handling
    test_integration_with_git
    test_complex_scenarios

    # Cleanup
    cleanup_test_workspace

    # Report results
    echo -e "\n${BLUE}=== Test Results ===${NC}"
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✓ All drift detection integration tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}✗ Some tests failed. Check output above for details.${NC}"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo ""
        echo "Runs comprehensive integration tests for drift detection functionality."
        echo "Tests cover baseline creation, drift detection, auto-fixing, and reporting."
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac