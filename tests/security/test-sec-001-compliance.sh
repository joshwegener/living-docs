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

# Test 2: Check for proper file existence validation before sourcing (critical files only)
echo -e "\nTest 2: File existence validation before sourcing"
unsafe_sourcing=false
for script in "${CRITICAL_SCRIPTS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        # Look for source statements without proper validation
        if grep "source.*\.sh" "$PROJECT_ROOT/$script" | grep -v "^\s*#" | grep -v "if.*-f" | grep -v "2>/dev/null.*true"; then
            echo "Unsafe sourcing in critical script: $script"
            unsafe_sourcing=true
        fi
    fi
done

if [[ "$unsafe_sourcing" == "true" ]]; then
    test_fail "Found unsafe sourcing in critical scripts"
else
    test_pass "All critical scripts have proper sourcing validation"
fi

# Test 3: Check for cross-platform compatibility in sed usage
echo -e "\nTest 3: Cross-platform sed compatibility"
unsafe_sed_found=false
while IFS= read -r line; do
    # Skip lines that have proper macOS compatibility (sed -i '' or sed -i "")
    if [[ "$line" =~ sed\ -i\ \'\'|sed\ -i\ \"\" ]]; then
        continue
    fi
    # Skip test files and documentation examples
    if [[ "$line" =~ /tests/|/docs/|\.md: ]]; then
        continue
    fi
    # If we get here, it's potentially unsafe
    unsafe_sed_found=true
    echo "Unsafe sed -i usage: $line"
done < <(grep -r "sed -i " "$PROJECT_ROOT" --include="*.sh" | grep -v "^\s*#")

if [[ "$unsafe_sed_found" == "true" ]]; then
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

    # Check for command substitution security (focus on user input)
    unsafe_cmd_subst=false
    while IFS= read -r line; do
        # Skip safe patterns with trusted utilities
        if [[ "$line" =~ sha256sum.*\||shasum.*\||awk.*\||grep.*\||cut.*\||tr.*\||sed.*\| ]]; then
            continue
        fi
        # Check for potentially unsafe patterns
        if [[ "$line" =~ '\$\([^)]*\|' ]]; then
            echo "Potentially unsafe command substitution: $line"
            unsafe_cmd_subst=true
        fi
    done < <(grep -E '\$\([^)]*\|' "$PROJECT_ROOT/wizard.sh")

    if [[ "$unsafe_cmd_subst" == "true" ]]; then
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