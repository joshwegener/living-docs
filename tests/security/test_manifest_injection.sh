#!/bin/bash
# Test for manifest JSON injection vulnerability in manifest.sh
# This test MUST fail initially (TDD red phase)

set -e

# Source the manifest functions
source lib/adapter/manifest.sh

echo "Testing manifest.sh for injection vulnerabilities..."

# Create test environment
TEST_DIR=$(mktemp -d)
PROJECT_ROOT="$TEST_DIR"
export PROJECT_ROOT

# Test 1: File path injection in read_manifest
echo "Test 1: Testing file path injection in read_manifest..."

# Create malicious adapter name with path traversal
MALICIOUS_NAME='../../etc/passwd"]; echo "INJECTED'
mkdir -p "$TEST_DIR/adapters/test-adapter"

# Try to create manifest with malicious name - should be sanitized
if create_manifest "$MALICIOUS_NAME" "1.0.0" "test" 2>/dev/null; then
    echo "✗ FAIL: Malicious adapter name was accepted in create_manifest"
    FAILED=1
else
    echo "✓ create_manifest rejected malicious name"
fi

# Test 2: Command injection via field parameter
echo "Test 2: Testing command injection via field parameter..."

# Create a legitimate manifest first
create_manifest "test-adapter" "1.0.0" "test" >/dev/null 2>&1

# Try to inject command via field parameter
MALICIOUS_FIELD='version"; cat /etc/passwd; echo "'
OUTPUT=$(read_manifest "test-adapter" "$MALICIOUS_FIELD" 2>&1 || true)

if echo "$OUTPUT" | grep -q "root:" 2>/dev/null; then
    echo "✗ FAIL: Command injection successful via field parameter"
    FAILED=1
else
    echo "✓ Field parameter injection prevented"
fi

# Test 3: AWK injection in update_manifest
echo "Test 3: Testing AWK injection in update_manifest..."

# Try to inject via file path parameter
MALICIOUS_PATH='test.sh" } { system("echo INJECTED") } { "'
if update_manifest "test-adapter" "$MALICIOUS_PATH" "checksum123" "original.sh" 2>&1 | grep -q "INJECTED"; then
    echo "✗ FAIL: AWK injection successful in update_manifest"
    FAILED=1
else
    echo "✓ AWK injection prevented in update_manifest"
fi

# Test 4: Path traversal in get_manifest_path
echo "Test 4: Testing path traversal in get_manifest_path..."

TRAVERSAL_NAME="../../../tmp/evil"
MANIFEST_PATH=$(get_manifest_path "$TRAVERSAL_NAME")

if [[ "$MANIFEST_PATH" == *"../"* ]]; then
    echo "✗ FAIL: Path traversal not sanitized in get_manifest_path"
    FAILED=1
else
    echo "✓ Path traversal sanitized"
fi

# Clean up
rm -rf "$TEST_DIR"

# Exit with failure if any test failed
if [[ "$FAILED" == "1" ]]; then
    echo ""
    echo "✗ SECURITY TESTS FAILED - Injection vulnerabilities found!"
    exit 1
else
    echo ""
    echo "✓ All security tests passed"
    exit 0
fi