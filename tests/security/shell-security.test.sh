#!/bin/bash

# Security test suite for shell scripts
# Tests MUST fail initially (TDD compliance)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd ""$SCRIPT_DIR"/../.." && pwd)"
FAILED_TESTS=0
PASSED_TESTS=0

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_fail() {
    echo -e "${RED}✗ $1${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

test_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

echo "Running security tests for shell scripts..."
echo "==========================================="

# Get all shell scripts to test
SCRIPTS=()
while IFS= read -r script; do
    SCRIPTS+=("$script")
done < <(find "$PROJECT_ROOT" -name "*.sh" -type f | grep -v "/templates/" | grep -v "/node_modules/" | grep -v "/.git/")

echo "Found ${#SCRIPTS[@]} shell scripts to test"
echo

# Test 1: Check for 'set -euo pipefail' in all scripts
echo "Test 1: Strict error handling enforcement"
for script in "${SCRIPTS[@]}"; do
    if ! grep -q '^set -euo pipefail' "$script"; then
        test_fail "Missing 'set -euo pipefail' in: $script"
    else
        test_pass "Has strict error handling: $script"
    fi
done

# Test 2: Check for unquoted variable expansions
echo -e "\nTest 2: Variable quoting enforcement"
for script in "${SCRIPTS[@]}"; do
    # Look for unquoted "$var" patterns (basic check for now)
    if grep -E '\$[A-Za-z_][A-Za-z0-9_]*[^}"]' "$script" | grep -v '^\s*#' | grep -q .; then
        test_fail "Potentially unquoted variables found in: $script"
    else
        test_pass "Variables appear properly quoted: $script"
    fi
done

# Test 3: ShellCheck compliance
echo -e "\nTest 3: ShellCheck compliance"
if command -v shellcheck &>/dev/null; then
    for script in "${SCRIPTS[@]}"; do
        if shellcheck -S error "$script" &>/dev/null; then
            test_pass "ShellCheck clean: $script"
        else
            test_fail "ShellCheck errors in: $script"
        fi
    done
else
    test_fail "ShellCheck not installed"
fi

# Test 4: Check for hardcoded credentials
echo -e "\nTest 4: No hardcoded credentials"
for script in "${SCRIPTS[@]}"; do
    if grep -E '(password|token|secret|key|api_key)=["'\'']' "$script" | grep -v '^\s*#'; then
        test_fail "Potential hardcoded credentials in: $script"
    else
        test_pass "No hardcoded credentials: $script"
    fi
done

# Test 5: Check for unsafe eval usage
echo -e "\nTest 5: No unsafe eval usage"
for script in "${SCRIPTS[@]}"; do
    if grep -E '^\s*eval\s+' "$script" | grep -v '^\s*#'; then
        test_fail "Unsafe eval usage in: $script"
    else
        test_pass "No unsafe eval: $script"
    fi
done

# Test 6: Check for proper temp file handling
echo -e "\nTest 6: Secure temp file handling"
for script in "${SCRIPTS[@]}"; do
    if grep -E 'mktemp[^d]' "$script" | grep -v '^\s*#' | grep -v 'mktemp -d'; then
        test_fail "Insecure temp file creation in: $script"
    else
        test_pass "Secure temp handling: $script"
    fi
done

# Test 7: Check for dead code patterns
echo -e "\nTest 7: No dead/unused code"
for script in "${SCRIPTS[@]}"; do
    # Check for commented-out code blocks (multiple consecutive comment lines with code)
    if awk '/^#.*[a-z].*\(/ && prev ~ /^#/ { found=1; exit } { prev=$0 } END { exit found ? 0 : 1 }' "$script"; then
        test_fail "Dead code detected in: $script"
    else
        test_pass "No obvious dead code: $script"
    fi
done

# Summary
echo -e "\n==========================================="
echo "Test Results:"
echo "  Passed: $PASSED_TESTS"
echo "  Failed: $FAILED_TESTS"
echo "==========================================="

# Exit with failure if any tests failed (expected for TDD)
if [[ "$FAILED_TESTS" -gt 0 ]]; then
    echo -e "${RED}Security tests failed (expected for TDD - fix implementations next)${NC}"
    exit 1
else
    echo -e "${GREEN}All security tests passed!${NC}"
    exit 0
fi