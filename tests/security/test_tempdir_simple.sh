#!/bin/bash
# Test for temp directory vulnerability in install.sh
# This test MUST fail initially (TDD red phase)

echo "Testing temp directory security in install.sh..."

# Test 1: Check if using predictable pattern
echo "Test 1: Checking temp directory predictability..."

if grep -q 'mkdir -p.*living-docs-install-\$\$-\$RANDOM' lib/adapter/install.sh; then
    echo "✗ FAIL: Using predictable temp directory pattern (PID + RANDOM is guessable)"
    FAILED=1
else
    echo "✓ Not using predictable pattern"
fi

# Test 2: Check if using mktemp -d (secure)
echo "Test 2: Checking for secure mktemp usage..."

if ! grep -q 'mktemp -d' lib/adapter/install.sh; then
    echo "✗ FAIL: Not using 'mktemp -d' for secure temp directory creation"
    echo "  Current uses mkdir -p which is vulnerable to race conditions"
    FAILED=1
else
    echo "✓ Using secure mktemp -d"
fi

# Test 3: Check directory permissions
echo "Test 3: Checking if permissions are set..."

if ! grep -q 'chmod 700\|umask 077' lib/adapter/install.sh; then
    echo "✗ FAIL: No explicit permission setting for temp directories"
    echo "  Temp directories could be world-readable"
    FAILED=1
else
    echo "✓ Permissions explicitly set"
fi

# Test 4: Check for symlink following
echo "Test 4: Checking symlink protection..."

if ! grep -q '\-L\|readlink\|realpath' lib/adapter/install.sh; then
    echo "✗ FAIL: No symlink checking before directory operations"
    echo "  Vulnerable to symlink attacks"
    FAILED=1
else
    echo "✓ Symlink protection in place"
fi

if [[ "$FAILED" == "1" ]]; then
    echo ""
    echo "✗ TEMP DIRECTORY SECURITY TEST FAILED!"
    exit 1
else
    echo ""
    echo "✓ All temp directory security checks passed"
    exit 0
fi