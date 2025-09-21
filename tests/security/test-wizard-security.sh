#!/bin/bash
# Security tests specifically for wizard.sh
# Tests the main installation script for security vulnerabilities

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WIZARD_SCRIPT="$PROJECT_ROOT/wizard.sh"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

test_results=()
tests_run=0
tests_passed=0

run_test() {
    local test_name="$1"
    local test_function="$2"

    echo "Running: $test_name"
    ((tests_run++))

    if $test_function; then
        echo -e "${GREEN}✅ PASS:${NC} $test_name"
        test_results+=("PASS: $test_name")
        ((tests_passed++))
    else
        echo -e "${RED}❌ FAIL:${NC} $test_name"
        test_results+=("FAIL: $test_name")
    fi
    echo
}

test_wizard_exists() {
    [[ -f "$WIZARD_SCRIPT" ]]
}

test_wizard_permissions() {
    local perms
    perms=$(stat -c "%a" "$WIZARD_SCRIPT" 2>/dev/null || stat -f "%A" "$WIZARD_SCRIPT" 2>/dev/null)

    # Should be executable but not world-writable
    [[ "$perms" =~ ^[0-9]*[0-9][0-9][0-57]$ ]]
}

test_no_hardcoded_urls() {
    # Check for hardcoded URLs that could be security risks
    ! grep -E "http://[^[:space:]]+" "$WIZARD_SCRIPT" || {
        echo "Found hardcoded HTTP URLs (should use HTTPS)"
        return 1
    }
}

test_input_validation() {
    # Check that wizard.sh validates user input
    grep -q "validate\|check\|sanitize" "$WIZARD_SCRIPT" || {
        echo "No obvious input validation found"
        return 1
    }
}

test_temp_file_security() {
    # Check for secure temp file creation
    if grep -q "/tmp/" "$WIZARD_SCRIPT"; then
        if ! grep -q "mktemp" "$WIZARD_SCRIPT"; then
            echo "Uses /tmp without mktemp"
            return 1
        fi
    fi
    return 0
}

test_download_security() {
    # If script downloads files, check for security measures
    if grep -qE "(curl|wget|download)" "$WIZARD_SCRIPT"; then
        # Should use HTTPS
        if grep -qE "(curl|wget).*http://" "$WIZARD_SCRIPT"; then
            echo "Downloads over HTTP detected"
            return 1
        fi

        # Should verify downloads
        if ! grep -qE "(checksum|hash|verify|gpg)" "$WIZARD_SCRIPT"; then
            echo "Downloads without verification detected"
            return 1
        fi
    fi
    return 0
}

test_privilege_escalation() {
    # Check for unnecessary privilege escalation
    if grep -q "sudo" "$WIZARD_SCRIPT"; then
        # Should have clear justification
        if ! grep -qE "(# SECURITY:|# SUDO:|# ADMIN:)" "$WIZARD_SCRIPT"; then
            echo "sudo usage without security comment"
            return 1
        fi
    fi
    return 0
}

test_error_handling() {
    # Check for proper error handling
    if ! grep -q "set -e" "$WIZARD_SCRIPT" && ! grep -q "trap" "$WIZARD_SCRIPT"; then
        echo "No error handling detected"
        return 1
    fi
    return 0
}

test_path_traversal() {
    # Check for potential path traversal issues
    if grep -qE "\.\./|\.\.\\\\" "$WIZARD_SCRIPT"; then
        echo "Potential path traversal patterns found"
        return 1
    fi
    return 0
}

test_command_injection() {
    # Look for potential command injection vulnerabilities
    # This is a basic check - real analysis would be more complex
    if grep -qE "eval.*\$|system.*\$|\`.*\$.*\`" "$WIZARD_SCRIPT"; then
        echo "Potential command injection patterns found"
        return 1
    fi
    return 0
}

test_file_permissions_set() {
    # Check if script sets secure file permissions
    if grep -qE "(chmod|chown)" "$WIZARD_SCRIPT"; then
        # Should not set overly permissive permissions
        if grep -qE "chmod.*[0-9]*7[7-9][7-9]" "$WIZARD_SCRIPT"; then
            echo "Overly permissive file permissions detected"
            return 1
        fi
    fi
    return 0
}

test_secrets_handling() {
    # Check that no secrets are hardcoded
    if grep -qiE "(password|secret|key|token|credential)[[:space:]]*=" "$WIZARD_SCRIPT"; then
        echo "Potential hardcoded secrets found"
        return 1
    fi
    return 0
}

test_user_input_sanitization() {
    # Check for user input sanitization
    if grep -qE "read.*-p|read.*-r" "$WIZARD_SCRIPT"; then
        # Should sanitize input
        if ! grep -qE "(sanitize|clean|validate|escape)" "$WIZARD_SCRIPT"; then
            echo "User input handling without obvious sanitization"
            return 1
        fi
    fi
    return 0
}

main() {
    echo "Wizard.sh Security Test Suite"
    echo "============================="
    echo "Testing: $WIZARD_SCRIPT"
    echo

    # Run all security tests
    run_test "Wizard script exists" test_wizard_exists
    run_test "File permissions are secure" test_wizard_permissions
    run_test "No hardcoded HTTP URLs" test_no_hardcoded_urls
    run_test "Input validation present" test_input_validation
    run_test "Temp file security" test_temp_file_security
    run_test "Download security" test_download_security
    run_test "Privilege escalation security" test_privilege_escalation
    run_test "Error handling present" test_error_handling
    run_test "No path traversal vulnerabilities" test_path_traversal
    run_test "No command injection patterns" test_command_injection
    run_test "File permissions set securely" test_file_permissions_set
    run_test "No hardcoded secrets" test_secrets_handling
    run_test "User input sanitization" test_user_input_sanitization

    echo
    echo "Test Results Summary"
    echo "==================="
    echo "Tests run: $tests_run"
    echo "Tests passed: $tests_passed"
    echo "Tests failed: $((tests_run - tests_passed))"
    echo

    if [[ $tests_passed -eq $tests_run ]]; then
        echo -e "${GREEN}✅ All security tests passed${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some security tests failed${NC}"
        echo
        echo "Failed tests:"
        for result in "${test_results[@]}"; do
            if [[ "$result" =~ ^FAIL: ]]; then
                echo "  - ${result#FAIL: }"
            fi
        done
        exit 1
    fi
}

main "$@"