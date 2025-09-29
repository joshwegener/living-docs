#!/usr/bin/env bash
# Unified test runner for living-docs
# Runs all test suites with proper reporting and coverage

set -euo pipefail

# Configuration
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR=""$REPO_ROOT"/tests"
COVERAGE_DIR="${COVERAGE_DIR:-"$REPO_ROOT"/coverage}"
TEST_TYPE="${1:-all}"
VERBOSE="${VERBOSE:-false}"
CI_MODE="${CI:-false}"

# Colors for output (disabled in CI)
if [[ "$CI_MODE" == "true" ]] || [[ ! -t 1 ]]; then
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    NC=""
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
fi

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Print colored message
print_msg() {
    local color="$1"
    local msg="$2"
    echo -e "${color}${msg}${NC}"
}

# Print test header
print_header() {
    local suite="$1"
    echo ""
    print_msg "$CYAN" "════════════════════════════════════════════════════════════════"
    print_msg "$CYAN" "  Running: $suite"
    print_msg "$CYAN" "════════════════════════════════════════════════════════════════"
    echo ""
}

# Check dependencies
check_dependencies() {
    local missing=()

    # Check for Bats
    if ! command -v bats &>/dev/null; then
        missing+=("bats")
    fi

    # Check for shellcheck
    if ! command -v shellcheck &>/dev/null; then
        missing+=("shellcheck")
    fi

    # Check for coverage tools
    if [[ "$TEST_TYPE" == "coverage" ]] || [[ "$TEST_TYPE" == "all" ]]; then
        if ! command -v kcov &>/dev/null; then
            print_msg "$YELLOW" "Warning: kcov not installed - coverage reporting disabled"
        fi
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_msg "$RED" "Missing dependencies: ${missing[*]}"
        print_msg "$YELLOW" "Install missing dependencies and try again"
        return 1
    fi

    return 0
}

# Run shellcheck on all shell scripts
run_shellcheck() {
    print_header "ShellCheck - Static Analysis"

    local scripts=()
    local failed=0

    # Find all shell scripts
    while IFS= read -r script; do
        scripts+=("$script")
    done < <(find "$REPO_ROOT" \
        -type f \
        \( -name "*.sh" -o -name "*.bash" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/coverage/*" \
        ! -path "*/.living-docs.backup/*")

    # Add wizard.sh if it exists
    [[ -f ""$REPO_ROOT"/wizard.sh" ]] && scripts+=(""$REPO_ROOT"/wizard.sh")

    local total=${#scripts[@]}
    print_msg "$BLUE" "Checking "$total" shell scripts..."

    for script in "${scripts[@]}"; do
        if [[ "$VERBOSE" == "true" ]]; then
            echo -n "  Checking: $(basename "$script")... "
        fi

        if shellcheck -S warning "$script" 2>&1 | grep -q .; then
            if [[ "$VERBOSE" == "true" ]]; then
                print_msg "$RED" "FAILED"
                shellcheck -S warning "$script"
            else
                print_msg "$RED" "  ✗ $(basename "$script")"
            fi
            ((failed++))
        else
            if [[ "$VERBOSE" == "true" ]]; then
                print_msg "$GREEN" "OK"
            fi
        fi
    done

    if [[ "$failed" -eq 0 ]]; then
        print_msg "$GREEN" "✓ All "$total" scripts passed ShellCheck"
        ((PASSED_TESTS += total))
    else
        print_msg "$RED" "✗ "$failed"/"$total" scripts failed ShellCheck"
        ((FAILED_TESTS += failed))
        ((PASSED_TESTS += total - failed))
    fi

    ((TOTAL_TESTS += total))
    return $([[ "$failed" -eq 0 ]] && echo 0 || echo 1)
}

# Run Bats unit tests
run_bats_tests() {
    print_header "Bats - Unit Tests"

    if [[ ! -d ""$TEST_DIR"/bats" ]]; then
        print_msg "$YELLOW" "No Bats tests found in "$TEST_DIR"/bats"
        return 0
    fi

    local test_files=()
    while IFS= read -r test_file; do
        test_files+=("$test_file")
    done < <(find ""$TEST_DIR"/bats" -name "*.bats" -type f | sort)

    if [[ ${#test_files[@]} -eq 0 ]]; then
        print_msg "$YELLOW" "No Bats test files found"
        return 0
    fi

    print_msg "$BLUE" "Running ${#test_files[@]} Bats test suites..."

    local failed=0
    local passed=0
    local total=0

    for test_file in "${test_files[@]}"; do
        local test_name
        test_name=$(basename "$test_file" .bats)

        if [[ "$VERBOSE" == "true" ]]; then
            print_msg "$BLUE" "Running: $test_name"
            if bats "$test_file"; then
                print_msg "$GREEN" "  ✓ "$test_name" passed"
                ((passed++))
            else
                print_msg "$RED" "  ✗ "$test_name" failed"
                ((failed++))
            fi
        else
            echo -n "  Testing "$test_name"... "
            if bats "$test_file" &>/dev/null; then
                print_msg "$GREEN" "PASSED"
                ((passed++))
            else
                print_msg "$RED" "FAILED"
                ((failed++))
            fi
        fi
        ((total++))
    done

    if [[ "$failed" -eq 0 ]]; then
        print_msg "$GREEN" "✓ All "$total" Bats test suites passed"
    else
        print_msg "$RED" "✗ "$failed"/"$total" Bats test suites failed"
    fi

    ((TOTAL_TESTS += total))
    ((PASSED_TESTS += passed))
    ((FAILED_TESTS += failed))

    return $([[ "$failed" -eq 0 ]] && echo 0 || echo 1)
}

# Run integration tests
run_integration_tests() {
    print_header "Integration Tests"

    if [[ ! -d ""$TEST_DIR"/integration" ]]; then
        print_msg "$YELLOW" "No integration tests found"
        return 0
    fi

    local test_files=()
    while IFS= read -r test_file; do
        test_files+=("$test_file")
    done < <(find ""$TEST_DIR"/integration" -name "*.sh" -type f -executable | sort)

    if [[ ${#test_files[@]} -eq 0 ]]; then
        print_msg "$YELLOW" "No executable integration tests found"
        return 0
    fi

    print_msg "$BLUE" "Running ${#test_files[@]} integration tests..."

    local failed=0
    local passed=0

    for test_file in "${test_files[@]}"; do
        local test_name
        test_name=$(basename "$test_file" .sh)

        echo -n "  Testing "$test_name"... "
        if bash "$test_file" &>/dev/null; then
            print_msg "$GREEN" "PASSED"
            ((passed++))
        else
            print_msg "$RED" "FAILED"
            ((failed++))
            if [[ "$VERBOSE" == "true" ]]; then
                bash "$test_file" 2>&1 | sed 's/^/    /'
            fi
        fi
    done

    if [[ "$failed" -eq 0 ]]; then
        print_msg "$GREEN" "✓ All ${#test_files[@]} integration tests passed"
    else
        print_msg "$RED" "✗ "$failed"/${#test_files[@]} integration tests failed"
    fi

    ((TOTAL_TESTS += ${#test_files[@]}))
    ((PASSED_TESTS += passed))
    ((FAILED_TESTS += failed))

    return $([[ "$failed" -eq 0 ]] && echo 0 || echo 1)
}

# Run tests with coverage
run_coverage_tests() {
    print_header "Test Coverage"

    if ! command -v kcov &>/dev/null; then
        print_msg "$YELLOW" "kcov not installed - skipping coverage"
        ((SKIPPED_TESTS++))
        return 0
    fi

    if [[ -f ""$TEST_DIR"/run-coverage.sh" ]]; then
        print_msg "$BLUE" "Running coverage tests..."
        if bash ""$TEST_DIR"/run-coverage.sh"; then
            print_msg "$GREEN" "✓ Coverage tests completed"
            ((PASSED_TESTS++))
        else
            print_msg "$RED" "✗ Coverage tests failed"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    else
        print_msg "$YELLOW" "Coverage runner not found"
        ((SKIPPED_TESTS++))
    fi
}

# Generate test report
generate_report() {
    echo ""
    print_msg "$CYAN" "════════════════════════════════════════════════════════════════"
    print_msg "$CYAN" "  Test Results Summary"
    print_msg "$CYAN" "════════════════════════════════════════════════════════════════"
    echo ""

    print_msg "$BLUE" "Total Tests:    $TOTAL_TESTS"
    print_msg "$GREEN" "Passed Tests:   $PASSED_TESTS"
    print_msg "$RED" "Failed Tests:   $FAILED_TESTS"
    print_msg "$YELLOW" "Skipped Tests:  $SKIPPED_TESTS"

    if [[ "$TOTAL_TESTS" -gt 0 ]]; then
        local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo ""
        print_msg "$BLUE" "Pass Rate: ${pass_rate}%"
    fi

    echo ""

    # Exit code based on results
    if [[ "$FAILED_TESTS" -eq 0 ]]; then
        print_msg "$GREEN" "✓ All tests passed successfully!"
        return 0
    else
        print_msg "$RED" "✗ Some tests failed. Please review the output above."
        return 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [TEST_TYPE]

TEST_TYPE:
  all         Run all test suites (default)
  lint        Run ShellCheck static analysis only
  unit        Run Bats unit tests only
  integration Run integration tests only
  coverage    Run tests with coverage reporting
  quick       Run lint and unit tests only

Environment Variables:
  VERBOSE=true     Show detailed test output
  CI=true          Enable CI mode (no colors, structured output)
  COVERAGE_DIR=dir Set coverage output directory

Examples:
  $0              # Run all tests
  $0 lint         # Run only ShellCheck
  $0 unit         # Run only Bats tests
  $0 quick        # Quick test run (lint + unit)
  VERBOSE=true $0 # Run all tests with verbose output

EOF
    exit 0
}

# Main execution
main() {
    # Check for help flag
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_usage
    fi

    print_msg "$MAGENTA" "╔════════════════════════════════════════════════════════════════╗"
    print_msg "$MAGENTA" "║           living-docs Unified Test Runner v1.0.0              ║"
    print_msg "$MAGENTA" "╚════════════════════════════════════════════════════════════════╝"

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    local exit_code=0

    case "$TEST_TYPE" in
        all)
            run_shellcheck || exit_code=$?
            run_bats_tests || exit_code=$?
            run_integration_tests || exit_code=$?
            run_coverage_tests || exit_code=$?
            ;;
        lint)
            run_shellcheck || exit_code=$?
            ;;
        unit)
            run_bats_tests || exit_code=$?
            ;;
        integration)
            run_integration_tests || exit_code=$?
            ;;
        coverage)
            run_coverage_tests || exit_code=$?
            ;;
        quick)
            run_shellcheck || exit_code=$?
            run_bats_tests || exit_code=$?
            ;;
        *)
            print_msg "$RED" "Unknown test type: $TEST_TYPE"
            show_usage
            ;;
    esac

    # Generate summary report
    generate_report

    exit $exit_code
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi