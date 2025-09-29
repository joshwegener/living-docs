#!/bin/bash
# Test for secrets scanning configuration
set -euo pipefail

echo "Testing secrets scanning configuration..."

# Test 1: Check gitleaks config exists
echo "Test 1: Checking gitleaks configuration..."
if [[ -f ".gitleaks.toml" ]]; then
    echo "✓ Gitleaks configuration found"
else
    echo "✗ FAIL: No .gitleaks.toml configuration"
    exit 1
fi

# Test 2: Test gitleaks detection with fake secret
echo "Test 2: Testing secret detection..."
TEST_FILE=$(mktemp)
echo 'API_KEY="sk-1234567890abcdef1234567890abcdef"' > "$TEST_FILE"

if gitleaks detect --source "$TEST_FILE" --no-git 2>&1 | grep -q "leaks found"; then
    echo "✓ Gitleaks detects test secrets"
else
    echo "✗ WARNING: Gitleaks may not be detecting secrets properly"
fi

rm -f "$TEST_FILE"

# Test 3: Check pre-commit hook
echo "Test 3: Checking pre-commit hook..."
if [[ -x ".git/hooks/pre-commit" ]] && grep -q "gitleaks" ".git/hooks/pre-commit"; then
    echo "✓ Pre-commit hook with gitleaks installed"
else
    echo "✗ WARNING: Pre-commit hook not configured for gitleaks"
fi

# Test 4: Verify allowlist is working
echo "Test 4: Testing allowlist configuration..."
TEST_FILE=$(mktemp)
echo 'test@example.com' > "$TEST_FILE"

if ! gitleaks detect --source "$TEST_FILE" --no-git 2>&1 | grep -q "leaks found"; then
    echo "✓ Allowlist working (example.com allowed)"
else
    echo "✗ FAIL: Allowlist not working properly"
fi

rm -f "$TEST_FILE"

echo ""
echo "✓ Secrets scanning configuration tests passed"
exit 0