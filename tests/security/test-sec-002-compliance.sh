#!/bin/bash
set -euo pipefail

# SEC-002 Secrets & Credential Exposure Compliance Test
# Tests manifest integrity, credential scanning, and vulnerability alerts

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd ""$SCRIPT_DIR"/../.." && pwd)"
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

echo "SEC-002 Secrets & Credential Exposure Compliance Tests"
echo "===================================================="
echo

# Test 1: Check for hardcoded secrets patterns
echo "Test 1: Hardcoded secrets detection"
SECRET_PATTERNS=(
    "password="
    "secret="
    "token="
    "api_key="
    "private_key="
    "sk-[a-zA-Z0-9]{32,}"
)

secrets_found=false
for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -r -E "$pattern" "$PROJECT_ROOT" --include="*.sh" --include="*.md" --include="*.json" \
       --exclude-dir=.git --exclude-dir=tests --exclude="*.test.*" | grep -v "^\s*#" | grep -q .; then
        echo "Potential secret pattern found: $pattern"
        secrets_found=true
    fi
done

if [[ "$secrets_found" == "true" ]]; then
    test_fail "Potential hardcoded secrets detected"
else
    test_pass "No hardcoded secrets patterns found"
fi

# Test 2: Gitleaks configuration and functionality
echo -e "\nTest 2: Gitleaks configuration"
if [[ -f ""$PROJECT_ROOT"/.gitleaks.toml" ]]; then
    test_pass "Gitleaks configuration exists"

    # Test if gitleaks can run successfully
    if command -v gitleaks &>/dev/null; then
        if gitleaks detect --source="$PROJECT_ROOT" --no-git &>/dev/null; then
            test_pass "Gitleaks scan passes"
        else
            test_fail "Gitleaks detected issues"
        fi
    else
        test_warn "Gitleaks not installed - install for full compliance"
    fi
else
    test_fail "Gitleaks configuration missing"
fi

# Test 3: Manifest integrity checks
echo -e "\nTest 3: Manifest integrity validation"
manifest_integrity=true

# Check if manifest integrity library exists
if [[ -f ""$PROJECT_ROOT"/lib/security/manifest-integrity.sh" ]]; then
    test_pass "Manifest integrity library exists"

    # Check for manifest validation functions
    if grep -q "validate_manifest\|verify_manifest\|check_integrity" ""$PROJECT_ROOT"/lib/security/manifest-integrity.sh"; then
        test_pass "Manifest validation functions present"
    else
        test_fail "Manifest validation functions missing"
        manifest_integrity=false
    fi
else
    test_fail "Manifest integrity library missing"
    manifest_integrity=false
fi

# Test 4: Configuration file security
echo -e "\nTest 4: Configuration file security"
config_secure=true

# Check .living-docs.config for sensitive patterns
if [[ -f ""$PROJECT_ROOT"/.living-docs.config" ]]; then
    if grep -E "(password|secret|token|key)=" ""$PROJECT_ROOT"/.living-docs.config" | grep -v "^\s*#"; then
        test_fail "Potential secrets in .living-docs.config"
        config_secure=false
    else
        test_pass ".living-docs.config appears secure"
    fi
fi

# Check for .env files (should be gitignored)
if find "$PROJECT_ROOT" -name ".env*" -type f | grep -q .; then
    test_warn "Found .env files - ensure they are gitignored"
else
    test_pass "No .env files found in repository"
fi

# Test 5: GitHub security features
echo -e "\nTest 5: GitHub security configuration"
if [[ -f ""$PROJECT_ROOT"/.github/dependabot.yml" ]]; then
    test_pass "Dependabot configuration exists"
else
    test_fail "Dependabot configuration missing"
fi

# Check for security workflows
if [[ -f ""$PROJECT_ROOT"/.github/workflows/security.yml" ]] || \
   [[ -f ""$PROJECT_ROOT"/.github/workflows/codeql.yml" ]]; then
    test_pass "Security workflows configured"
else
    test_warn "Consider adding security workflows"
fi

# Summary
echo -e "\n===================================================="
echo "SEC-002 Compliance Results:"
echo "  Passed: $PASSED_TESTS"
echo "  Failed: $FAILED_TESTS"
echo "===================================================="

# Return non-zero if any tests failed
if [[ "$FAILED_TESTS" -gt 0 ]]; then
    echo -e "${RED}SEC-002 compliance check FAILED${NC}"
    echo "Implement missing security controls for credential protection"
    exit 1
else
    echo -e "${GREEN}SEC-002 compliance check PASSED${NC}"
    exit 0
fi