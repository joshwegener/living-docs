#!/bin/bash
set -euo pipefail

# SEC-001 Compliance Test Suite
# Tests specific requirements from SEC-001 Shell Hardening spec

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FAILED_TESTS=0
PASSED_TESTS=0

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_fail() {
    echo -e "${RED}✗ $1${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

test_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

test_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

echo "SEC-001 Shell Hardening Compliance Tests"
echo "========================================"
echo

# Test 1: Check for strict error handling in all critical scripts
echo "Test 1: Critical scripts have strict error handling"
CRITICAL_SCRIPTS=(
    "wizard.sh"
    "scripts/build-context.sh"
    "scripts/archive-old-work.sh"
    "lib/adapter/rewrite.sh"
    "lib/adapter/install.sh"
    "lib/security/sanitize.sh"
)

for script in "${CRITICAL_SCRIPTS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        if head -10 "$PROJECT_ROOT/$script" | grep -q '^set -euo pipefail'; then
            test_pass "Strict mode in: $script"
        else
            test_fail "Missing strict mode in: $script"
        fi
    else
        test_warn "Script not found: $script"
    fi
done

# Test 2: Check for proper file existence validation before sourcing
echo -e "\nTest 2: File existence validation before sourcing"
if grep -r "source.*\.sh" "$PROJECT_ROOT" --include="*.sh" | grep -v "^\s*#" | grep -v "if.*-f"; then
    test_fail "Found unsafe sourcing without file existence check"
else
    test_pass "All sourcing operations have proper validation"
fi

# Test 3: Check for cross-platform compatibility in sed usage
echo -e "\nTest 3: Cross-platform sed compatibility"
if grep -r "sed -i " "$PROJECT_ROOT" --include="*.sh" | grep -v "sed -i ''" | grep -v "sed -i \"\""; then
    test_fail "Found sed -i usage without macOS compatibility"
else
    test_pass "All sed -i usage is cross-platform compatible"
fi

# Test 4: Check wizard.sh specific security requirements
echo -e "\nTest 4: Wizard.sh security hardening"
if [[ -f "$PROJECT_ROOT/wizard.sh" ]]; then
    # Check for proper temp file handling
    if grep -q "mktemp" "$PROJECT_ROOT/wizard.sh"; then
        if grep -q "mktemp -d" "$PROJECT_ROOT/wizard.sh" || grep -q "trap.*rm" "$PROJECT_ROOT/wizard.sh"; then
            test_pass "Wizard.sh has secure temp file handling"
        else
            test_fail "Wizard.sh temp file handling needs improvement"
        fi
    else
        test_pass "Wizard.sh does not use temp files"
    fi

    # Check for command substitution security
    if grep -E '\$\([^)]*\|' "$PROJECT_ROOT/wizard.sh"; then
        test_fail "Wizard.sh has potentially unsafe command substitution with pipes"
    else
        test_pass "Wizard.sh command substitution appears safe"
    fi
else
    test_fail "wizard.sh not found"
fi

# Test 5: Check adapter system path injection prevention
echo -e "\nTest 5: Adapter system path injection prevention"
if [[ -f "$PROJECT_ROOT/lib/adapter/rewrite.sh" ]]; then
    if grep -q "sanitize_path" "$PROJECT_ROOT/lib/adapter/rewrite.sh"; then
        test_pass "Adapter rewrite.sh uses path sanitization"
    else
        test_fail "Adapter rewrite.sh missing path sanitization"
    fi

    if grep -q "source.*sanitize" "$PROJECT_ROOT/lib/adapter/rewrite.sh"; then
        test_pass "Adapter rewrite.sh sources sanitization library"
    else
        test_fail "Adapter rewrite.sh not using sanitization library"
    fi
else
    test_fail "lib/adapter/rewrite.sh not found"
fi

# Test 6: ShellCheck error-level compliance
echo -e "\nTest 6: ShellCheck error-level compliance"
if command -v shellcheck &>/dev/null; then
    error_count=0
    for script in "${CRITICAL_SCRIPTS[@]}"; do
        if [[ -f "$PROJECT_ROOT/$script" ]]; then
            if ! shellcheck -S error "$PROJECT_ROOT/$script" &>/dev/null; then
                test_fail "ShellCheck errors in: $script"
                ((error_count++))
            fi
        fi
    done

    if [[ $error_count -eq 0 ]]; then
        test_pass "All critical scripts pass ShellCheck at error level"
    fi
else
    test_warn "ShellCheck not available - install for full compliance"
fi

# Summary
echo -e "\n========================================"
echo "SEC-001 Compliance Results:"
echo "  Passed: $PASSED_TESTS"
echo "  Failed: $FAILED_TESTS"
echo "========================================"

# Return non-zero if any tests failed
if [[ $FAILED_TESTS -gt 0 ]]; then
    echo -e "${RED}SEC-001 compliance check FAILED${NC}"
    echo "Fix the failed tests to meet security requirements"
    exit 1
else
    echo -e "${GREEN}SEC-001 compliance check PASSED${NC}"
    exit 0
fi