#!/bin/bash
set -euo pipefail
# Test for run-tests.sh script syntax
# This test MUST fail initially (TDD red phase)

set -e

echo "Testing run-tests.sh for syntax errors..."

# Check syntax without executing
if bash -n ./tests/run-tests.sh 2>/dev/null; then
    echo "✓ run-tests.sh has valid syntax"
    exit 0
else
    echo "✗ FAIL: run-tests.sh has syntax errors"
    bash -n ./tests/run-tests.sh 2>&1
    exit 1
fi