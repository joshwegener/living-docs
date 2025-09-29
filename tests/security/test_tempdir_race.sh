#!/bin/bash
# Test for temp directory race condition vulnerability in install.sh
# This test MUST fail initially (TDD red phase)

set -e

echo "Testing install.sh for temp directory race conditions..."

# Source functions (but not with set -u which will fail on RANDOM)
set +u
source lib/adapter/install.sh
set -u

# Test 1: Predictable temp directory names
echo "Test 1: Testing predictable temp directory creation..."

# Override RANDOM to be predictable
export RANDOM=42
export TMPDIR="/tmp"

# Get temp dir name from stage_in_temp
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/source"
echo "test" > "$TEST_DIR/source/file.txt"

# Call stage_in_temp multiple times with same PID
TEMP1=$(stage_in_temp "test-adapter" "$TEST_DIR/source")
rm -rf "$TEMP1"

# Simulate attacker creating symlink with predicted name
PREDICTED="/tmp/living-docs-install-$$-42"
if [[ ! -e "$PREDICTED" ]]; then
    # Create malicious symlink to sensitive location
    ln -s /etc "$PREDICTED" 2>/dev/null || true
fi

# Try to use stage_in_temp again - should detect and handle symlink
TEMP2=$(stage_in_temp "test-adapter" "$TEST_DIR/source" 2>/dev/null || echo "FAILED")

if [[ "$TEMP2" == "FAILED" ]] || [[ -L "$TEMP2" ]]; then
    echo "✗ FAIL: Vulnerable to symlink attack on predictable temp names"
    VULNERABLE=1
else
    echo "✓ Protected against predictable temp directory names"
fi

# Clean up
rm -f "$PREDICTED" 2>/dev/null
rm -rf "$TEMP1" "$TEMP2" "$TEST_DIR" 2>/dev/null

# Test 2: Unsafe directory permissions
echo "Test 2: Testing temp directory permissions..."

# Reset RANDOM
unset RANDOM

TEST_DIR2=$(mktemp -d)
mkdir -p "$TEST_DIR2/source"

TEMP_DIR=$(stage_in_temp "test-adapter" "$TEST_DIR2/source")

if [[ -d "$TEMP_DIR" ]]; then
    PERMS=$(stat -c %a "$TEMP_DIR" 2>/dev/null || stat -f %A "$TEMP_DIR" 2>/dev/null)

    # Check if directory has safe permissions (700 or stricter)
    if [[ "$PERMS" != "700" ]] && [[ "$PERMS" != "600" ]]; then
        echo "✗ FAIL: Temp directory has unsafe permissions: $PERMS (should be 700)"
        VULNERABLE=1
    else
        echo "✓ Temp directory has safe permissions: $PERMS"
    fi
else
    echo "✗ FAIL: Could not create temp directory"
    VULNERABLE=1
fi

rm -rf "$TEMP_DIR" "$TEST_DIR2" 2>/dev/null

# Test 3: Check mktemp usage
echo "Test 3: Verifying secure mktemp usage..."

# Check if stage_in_temp uses mktemp -d (secure) vs manual creation
if grep -q 'mkdir.*living-docs-install' lib/adapter/install.sh && ! grep -q 'mktemp.*-d' lib/adapter/install.sh; then
    echo "✗ FAIL: Not using mktemp -d for secure temp directory creation"
    VULNERABLE=1
else
    echo "✓ Using secure temp directory creation method"
fi

# Exit with failure if vulnerable
if [[ "$VULNERABLE" == "1" ]]; then
    echo ""
    echo "✗ SECURITY TEST FAILED - Temp directory race condition vulnerability found!"
    exit 1
else
    echo ""
    echo "✓ All temp directory security tests passed"
    exit 0
fi