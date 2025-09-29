#!/bin/bash
set -euo pipefail
# Test runner for sanitization tests (TDD verification)
# This should FAIL until lib/security/sanitize.sh is implemented

set -e

echo "🧪 Running Input Sanitization Tests (TDD - should FAIL)"
echo "======================================================="

# Check if sanitize.sh exists
if [ ! -f "lib/security/sanitize.sh" ]; then
    echo "❌ EXPECTED FAILURE: lib/security/sanitize.sh does not exist"
    echo "   This is correct for TDD - implement the module to make tests pass"
    exit 1
fi

# Check if functions exist
source "lib/security/sanitize.sh" 2>/dev/null || {
    echo "❌ EXPECTED FAILURE: Cannot source lib/security/sanitize.sh"
    echo "   This is correct for TDD - implement the module to make tests pass"
    exit 1
}

# Test if required functions exist
functions_to_test=("sanitize_input" "sanitize_framework_name" "sanitize_path")

for func in "${functions_to_test[@]}"; do
    if ! type "$func" >/dev/null 2>&1; then
        echo "❌ EXPECTED FAILURE: Function $func does not exist"
        echo "   This is correct for TDD - implement the function to make tests pass"
        exit 1
    fi
done

echo "✅ All sanitization functions exist - ready for full test suite"
echo "   Run: bats tests/bats/test_sanitization.bats"