#!/bin/bash
# Test for namespace collision detection in prefix.sh
# This test MUST fail initially (TDD red phase)

echo "Testing namespace collision detection..."

# Source prefix functions
source lib/adapter/prefix.sh

# Test 1: Check if collision detection exists
echo "Test 1: Testing collision detection function..."

if ! declare -f check_prefix_collision >/dev/null 2>&1; then
    echo "✗ FAIL: No check_prefix_collision function found"
    FAILED=1
else
    echo "✓ check_prefix_collision function exists"
fi

# Test 2: Check if prefix uniqueness is enforced
echo "Test 2: Testing prefix uniqueness enforcement..."

# Look for validation in get_adapter_prefix
if ! grep -q "check.*existing.*prefix\|collision\|conflict" lib/adapter/prefix.sh; then
    echo "✗ FAIL: No collision checking in get_adapter_prefix"
    echo "  Multiple adapters could use same prefix, causing command hijacking"
    FAILED=1
else
    echo "✓ Prefix collision checking found"
fi

# Test 3: Check for prefix validation pattern
echo "Test 3: Testing prefix validation..."

if ! grep -q "^[a-z][a-z0-9_]*\$\|\[a-zA-Z\]\[a-zA-Z0-9_\]*" lib/adapter/prefix.sh; then
    echo "✗ FAIL: No prefix format validation"
    echo "  Invalid prefixes could cause shell injection"
    FAILED=1
else
    echo "✓ Prefix format validation exists"
fi

# Test 4: Check if existing prefixes are tracked
echo "Test 4: Testing prefix registry..."

if ! grep -q "manifest.*prefix\|prefix.*registry\|track.*prefix" lib/adapter/prefix.sh; then
    echo "✗ FAIL: No central prefix tracking mechanism"
    echo "  Cannot detect collisions without tracking existing prefixes"
    FAILED=1
else
    echo "✓ Prefix tracking mechanism found"
fi

if [[ "$FAILED" == "1" ]]; then
    echo ""
    echo "✗ NAMESPACE COLLISION TEST FAILED!"
    echo "Risk: Command hijacking between adapters"
    exit 1
else
    echo ""
    echo "✓ All namespace collision tests passed"
    exit 0
fi